function Add-PSMidiQueueFile {
    [CmdletBinding(DefaultParameterSetName = 'Path')]
    param (
        [Parameter(Mandatory, ParameterSetName = 'Path')]
        [string]$Path,

        [Parameter(Mandatory, ParameterSetName = 'FileObject', ValueFromPipeline)]
        [PSObject[]]$FileObject,

        [Parameter()]
        [ValidateRange(0, 15)]
        [int]$Group = 0
    )

    begin {
        $pipelineFileEvents = [System.Collections.Generic.List[object]]::new()
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'FileObject') {
            foreach ($midiEvent in $FileObject) {
                $null = $pipelineFileEvents.Add($midiEvent)
            }
        }
    }

    end {
        $events = if ($PSCmdlet.ParameterSetName -eq 'Path') { @(Get-PSMidiFile -Path $Path) } else { @($pipelineFileEvents) }
        if (-not $events) {
            $inputDescription = if ($PSCmdlet.ParameterSetName -eq 'Path') { "'$Path'" } else { 'the supplied FileObject input' }
            Write-Error "No MIDI events were read from $inputDescription."
            return
        }

        $fileMetadata = $events | Select-Object -First 1
        if (-not $fileMetadata.TicksPerQuarterNote) {
            $inputDescription = if ($PSCmdlet.ParameterSetName -eq 'Path') { "'$Path'" } else { 'the supplied FileObject input' }
            Write-Error "MIDI files that use SMPTE timing are not supported by the queue. $inputDescription must use ticks per quarter note."
            return
        }

        [int]$ticksPerQuarterNote = $fileMetadata.TicksPerQuarterNote
        if (-not (SetQueueTicksPerQuarterNote -TicksPerQuarterNote $ticksPerQuarterNote)) {
            return
        }

        $tempoEvents = @($events | Where-Object EventType -eq 'SetTempo' | Sort-Object AbsoluteTick, TrackNumber)

        $scheduledEvents = @($events | Where-Object EventType -in @('NoteOn', 'NoteOff') | Sort-Object AbsoluteTick, TrackNumber, Channel, Note, Velocity)

        if (-not $scheduledEvents) {
            Write-Error "No note events were found in '$Path'."
            return
        }

        $script:QueueMetadata.LastSourcePath = if ($PSCmdlet.ParameterSetName -eq 'Path') { (Resolve-Path -Path $Path -ErrorAction Stop).ProviderPath } else { $fileMetadata.FilePath }

        foreach ($scheduledEvent in $scheduledEvents) {
            [uint32]$velocity = if ($scheduledEvent.EventType -eq 'NoteOff') {
                0
            }
            else {
                [uint32][math]::Round(($scheduledEvent.Velocity / 127) * 65535)
            }

            $message = New-PSMidiMessage -Note $scheduledEvent.NoteName -Octave $scheduledEvent.Octave -Group $Group -MessageStatus $scheduledEvent.EventType -MidiChannel $scheduledEvent.Channel -Velocity $velocity
            AddQueueMessageAtTick -Tick ([long]$scheduledEvent.AbsoluteTick) -Message $message
        }

        foreach ($tempoEvent in $tempoEvents) {
            AddQueueTempoChange -Tick ([long]$tempoEvent.AbsoluteTick) -TempoMicroseconds $tempoEvent.TempoMicroseconds
        }

        [PSCustomObject]([ordered]@{
            SourcePath           = $script:QueueMetadata.LastSourcePath
            TicksPerQuarterNote  = $script:QueueMetadata.TicksPerQuarterNote
            TempoEventCount      = $script:QueueMetadata.TempoEventCount
            ScheduledEventCount  = $script:QueueMetadata.ScheduledEventCount
            ScheduledMomentCount = $script:MessageQueue.Count
            DurationTicks        = $script:QueueMetadata.DurationTicks
        })
    }
}
