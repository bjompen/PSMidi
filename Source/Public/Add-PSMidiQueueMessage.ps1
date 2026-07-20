function Add-PSMidiQueueMessage {
    [CmdletBinding(DefaultParameterSetName = 'SendNow')]
    param (
        [Parameter(Mandatory)]
        [Microsoft.Windows.Devices.Midi2.MidiMessage64[]]$Message,

        [Parameter()]
        [BPM]$Tempo,

        [Parameter(ParameterSetName = 'SendNow')]
        [switch]$SendNow,

        # Add this chord on the next occurrence of beat <n> in the bar
        [Parameter(ParameterSetName = 'Next')]
        [ValidateRange(1, 64)]
        [int]$Next,

        [Parameter(Mandatory, ParameterSetName = 'Next')]
        [ValidateRange(1, 64)]
        [int]$Beat = 4,

        # Add this chord on total beat number <n>
        [Parameter(ParameterSetName = 'OnTotal')]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$OnTotalBeat,

        # Add this beat on every <n> (ever '1' f.eg)
        [Parameter(ParameterSetName = 'Every')]
        [ValidateRange(1, 64)]
        [int]$Every
    )

    if ($PSBoundParameters.ContainsKey('Tempo')) {
        if (-not (SetQueueTicksPerQuarterNote -TicksPerQuarterNote $Tempo.TicksPerQuarterNote)) {
            return
        }
    }

    [long]$ticksPerQuarterNote = $script:QueueState.TicksPerQuarterNote
    [long]$currentTick = $script:QueueState.CurrentTick
    [long]$nextTotalBeat = [math]::Floor($currentTick / $ticksPerQuarterNote) + 1
    [int]$beatCount = if ($PSBoundParameters.ContainsKey('Beat')) { $Beat } else { $script:QueueState.BeatCount }

    if ($PSCmdlet.ParameterSetName -eq 'SendNow') {
        AddQueueMessageAtTick -Tick ($nextTotalBeat * $ticksPerQuarterNote) -Message $Message
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'Next') {
        [int]$currentBeat = (($nextTotalBeat - 1) % $beatCount) + 1
        [long]$currentBarStartBeat = $nextTotalBeat - $currentBeat + 1
        [long]$targetTotalBeat = if ($Next -ge $currentBeat) {
            $currentBarStartBeat + $Next - 1
        }
        else {
            $currentBarStartBeat + $beatCount + $Next - 1
        }

        AddQueueMessageAtTick -Tick ($targetTotalBeat * $ticksPerQuarterNote) -Message $Message
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'OnTotal') {
        AddQueueMessageAtTick -Tick ([long]$OnTotalBeat * $ticksPerQuarterNote) -Message $Message
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'Every') {
        AddQueueAllNoteOffMessages -Message $Message

        [System.Threading.Monitor]::Enter($script:QueueSync)
        try {
            $null = $script:RecurringQueueRules.Add([PSCustomObject]@{
                Beat = $Every
                Message = $Message
            })
        }
        finally {
            [System.Threading.Monitor]::Exit($script:QueueSync)
        }
    }
}