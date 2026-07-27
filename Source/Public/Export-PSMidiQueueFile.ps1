function Export-PSMidiQueueFile {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter()]
        [switch]$Force
    )

    $writeUInt16BigEndian = {
        param(
            [Parameter(Mandatory)]
            [System.IO.BinaryWriter]$Writer,

            [Parameter(Mandatory)]
            [uint16]$Value
        )

        $Writer.Write([byte](($Value -shr 8) -band 0xFF))
        $Writer.Write([byte]($Value -band 0xFF))
    }

    $writeUInt32BigEndian = {
        param(
            [Parameter(Mandatory)]
            [System.IO.BinaryWriter]$Writer,

            [Parameter(Mandatory)]
            [uint32]$Value
        )

        $Writer.Write([byte](($Value -shr 24) -band 0xFF))
        $Writer.Write([byte](($Value -shr 16) -band 0xFF))
        $Writer.Write([byte](($Value -shr 8) -band 0xFF))
        $Writer.Write([byte]($Value -band 0xFF))
    }

    $writeVlq = {
        param(
            [Parameter(Mandatory)]
            [System.IO.BinaryWriter]$Writer,

            [Parameter(Mandatory)]
            [long]$Value
        )

        if ($Value -lt 0) {
            throw "VLQ value must be >= 0. Got $Value."
        }

        $stack = [System.Collections.Generic.List[byte]]::new()
        $stack.Add([byte]($Value -band 0x7F))
        $temp = [long]($Value -shr 7)
        while ($temp -gt 0) {
            $stack.Add([byte](($temp -band 0x7F) -bor 0x80))
            $temp = [long]($temp -shr 7)
        }

        for ($i = $stack.Count - 1; $i -ge 0; $i--) {
            $Writer.Write($stack[$i])
        }
    }

    $newTempoMetaEvent = {
        param(
            [Parameter(Mandatory)]
            [long]$Tick,

            [Parameter(Mandatory)]
            [int]$TempoMicroseconds
        )

        [PSCustomObject]@{
            Tick = $Tick
            Kind = 'Tempo'
            Bytes = [byte[]]@(
                0xFF, 0x51, 0x03,
                [byte](($TempoMicroseconds -shr 16) -band 0xFF),
                [byte](($TempoMicroseconds -shr 8) -band 0xFF),
                [byte]($TempoMicroseconds -band 0xFF)
            )
        }
    }

    $convertQueueMessage = {
        param(
            [Parameter(Mandatory)]
            [long]$Tick,

            [Parameter(Mandatory)]
            [Microsoft.Windows.Devices.Midi2.MidiMessage64]$QueueMessage
        )

        [uint32]$word0 = $QueueMessage.Word0
        [uint32]$word1 = $QueueMessage.Word1

        [int]$messageType = ($word0 -shr 28) -band 0x0F
        if ($messageType -ne 0x4) {
            return $null
        }

        [int]$status = ($word0 -shr 20) -band 0x0F
        [int]$channel = ($word0 -shr 16) -band 0x0F
        [int]$index = $word0 -band 0xFFFF

        if ($status -notin @(0x8, 0x9, 0xE)) {
            return [PSCustomObject]@{
                Tick = $Tick
                Kind = 'Unsupported'
                Channel = $channel
                Status = $status
                Bytes = $null
            }
        }

        if ($status -eq 0xE) {
            [uint32]$pitchBend32 = $word1
            [int]$pitchBend14 = [Math]::Min(16383, [Math]::Max(0, [Math]::Round(($pitchBend32 / 4294967295.0) * 16383)))
            [int]$pitchBendLsb = $pitchBend14 -band 0x7F
            [int]$pitchBendMsb = ($pitchBend14 -shr 7) -band 0x7F

            return [PSCustomObject]@{
                Tick = $Tick
                Kind = 'Midi'
                Channel = $channel
                IsNoteEvent = $false
                IsPitchBendEvent = $true
                Bytes = [byte[]]@([byte](0xE0 + $channel), [byte]$pitchBendLsb, [byte]$pitchBendMsb)
            }
        }

        [int]$midiStatus = if ($status -eq 0x8) { 0x80 + $channel } else { 0x90 + $channel }
        [int]$midiNote = [Math]::Min(127, [Math]::Max(0, (($index -shr 8) -band 0x7F)))
        [int]$velocity16 = ($word1 -shr 16) -band 0xFFFF
        [int]$midiVelocity = [Math]::Min(127, [Math]::Max(0, [Math]::Round(($velocity16 / 65535.0) * 127)))

        [PSCustomObject]@{
            Tick = $Tick
            Kind = 'Midi'
            Channel = $channel
            IsNoteEvent = $true
            IsPitchBendEvent = $false
            Bytes = [byte[]]@([byte]$midiStatus, [byte]$midiNote, [byte]$midiVelocity)
        }
    }

    $writeTrackChunk = {
        param(
            [Parameter(Mandatory)]
            [System.IO.BinaryWriter]$Writer,

            [Parameter(Mandatory)]
            [object[]]$Events
        )

        $trackStream = [System.IO.MemoryStream]::new()
        $trackWriter = [System.IO.BinaryWriter]::new($trackStream)

        [long]$lastTick = 0
        foreach ($trackEvent in $Events) {
            [long]$delta = $trackEvent.Tick - $lastTick
            & $writeVlq $trackWriter $delta
            $trackWriter.Write([byte[]]$trackEvent.Bytes)
            $lastTick = $trackEvent.Tick
        }

        & $writeVlq $trackWriter 0
        $trackWriter.Write([byte[]]@(0xFF, 0x2F, 0x00))
        $trackWriter.Flush()

        $Writer.Write([System.Text.Encoding]::ASCII.GetBytes('MTrk'))
        & $writeUInt32BigEndian $Writer ([uint32]$trackStream.Length)
        $Writer.Write($trackStream.ToArray())
        $trackWriter.Dispose()
        $trackStream.Dispose()
    }

    [object[]]$queueEntries = @()
    [object[]]$tempoEntries = @()
    [bool]$hasRecurringQueueItems = $false
    [int]$ticksPerQuarterNote = 960
    [int]$defaultTempoMicroseconds = 500000

    [System.Threading.Monitor]::Enter($script:QueueSync)
    try {
        $queueEntries = @($script:MessageQueue.Keys | ForEach-Object {
            [PSCustomObject]@{ Tick = [long]$_; Messages = @($script:MessageQueue[[long]$_]) }
        })
        $tempoEntries = @($script:QueueTempoMap.Keys | ForEach-Object {
            [PSCustomObject]@{ Tick = [long]$_; TempoMicroseconds = [int]$script:QueueTempoMap[[long]$_] }
        })
        $hasRecurringQueueItems = $script:RecurringQueueRules.Count -gt 0
        $ticksPerQuarterNote = [int]$script:QueueState.TicksPerQuarterNote
        $defaultTempoMicroseconds = [int]$script:QueueState.DefaultTempoMicroseconds
    }
    finally {
        [System.Threading.Monitor]::Exit($script:QueueSync)
    }

    if ($hasRecurringQueueItems) {
        Write-Warning 'Recurring queue messages are ignored by Export-PSMidiQueueFile.'
    }

    $midiEvents = [System.Collections.Generic.List[object]]::new()
    $unsupportedMessageCount = 0
    foreach ($queueEntry in $queueEntries | Sort-Object Tick) {
        foreach ($queueMessage in $queueEntry.Messages) {
            $convertedEvent = & $convertQueueMessage $queueEntry.Tick $queueMessage
            if ($null -eq $convertedEvent) {
                continue
            }

            if ($convertedEvent.Kind -eq 'Unsupported') {
                $unsupportedMessageCount++
                continue
            }

            $null = $midiEvents.Add($convertedEvent)
        }
    }

    if ($unsupportedMessageCount -gt 0) {
        Write-Warning "$unsupportedMessageCount queued message(s) were not exportable to Standard MIDI and were skipped."
    }

    $tempoMap = [System.Collections.Generic.SortedDictionary[long, int]]::new()
    $tempoMap[0L] = $defaultTempoMicroseconds
    foreach ($tempoEntry in $tempoEntries | Sort-Object Tick) {
        $tempoMap[[long]$tempoEntry.Tick] = [int]$tempoEntry.TempoMicroseconds
    }

    $tempoEvents = @($tempoMap.Keys | Sort-Object | ForEach-Object {
        & $newTempoMetaEvent ([long]$_) ([int]$tempoMap[[long]$_])
    })
    $noteEventCount = @($midiEvents | Where-Object IsNoteEvent).Count
    $noteChannels = @($midiEvents | Where-Object IsNoteEvent | Select-Object -ExpandProperty Channel -Unique)
    $pitchBendEventCount = @($midiEvents | Where-Object IsPitchBendEvent).Count
    [int]$midiFormat = if ($noteChannels.Count -gt 1) { 1 } else { 0 }

    $tracks = [System.Collections.Generic.List[object[]]]::new()
    if ($midiFormat -eq 0) {
        $trackEvents = @($tempoEvents + $midiEvents)
        $sortedTrackEvents = @($trackEvents | Sort-Object Tick, @{Expression = { if ($_.Kind -eq 'Tempo') { 0 } else { 1 } } })
        $null = $tracks.Add($sortedTrackEvents)
    }
    else {
        $null = $tracks.Add(@($tempoEvents | Sort-Object Tick))
        foreach ($channel in ($noteChannels | Sort-Object)) {
            $channelEvents = @($midiEvents | Where-Object Channel -eq $channel | Sort-Object Tick)
            $null = $tracks.Add($channelEvents)
        }
    }

    if (-not $PSCmdlet.ShouldProcess($Path, 'Export current MIDI queue to Standard MIDI file')) {
        return
    }

    $resolvedOutputPath = [System.IO.Path]::GetFullPath($Path)
    if ([System.IO.File]::Exists($resolvedOutputPath) -and -not $Force.IsPresent) {
        Write-Error "File '$resolvedOutputPath' already exists. Use -Force to overwrite it."
        return
    }

    $outputDirectory = [System.IO.Path]::GetDirectoryName($resolvedOutputPath)
    if ($outputDirectory -and -not [System.IO.Directory]::Exists($outputDirectory)) {
        [System.IO.Directory]::CreateDirectory($outputDirectory) | Out-Null
    }

    $fileStream = [System.IO.File]::Open($resolvedOutputPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::Read)
    $writer = [System.IO.BinaryWriter]::new($fileStream)
    try {
        $writer.Write([System.Text.Encoding]::ASCII.GetBytes('MThd'))
        & $writeUInt32BigEndian $writer 6
        & $writeUInt16BigEndian $writer ([uint16]$midiFormat)
        & $writeUInt16BigEndian $writer ([uint16]$tracks.Count)
        & $writeUInt16BigEndian $writer ([uint16]$ticksPerQuarterNote)

        foreach ($trackEvents in $tracks) {
            & $writeTrackChunk $writer $trackEvents
        }
    }
    finally {
        $writer.Dispose()
        $fileStream.Dispose()
    }

    [PSCustomObject]@{
        Path = $resolvedOutputPath
        Format = $midiFormat
        TrackCount = $tracks.Count
        TicksPerQuarterNote = $ticksPerQuarterNote
        NoteEventCount = $noteEventCount
        PitchBendEventCount = $pitchBendEventCount
        IgnoredRecurringQueueRules = $hasRecurringQueueItems
    }
}
