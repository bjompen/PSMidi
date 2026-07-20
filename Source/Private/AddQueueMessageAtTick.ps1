function AddQueueMessageAtTick {
    param(
        [Parameter(Mandatory)]
        [long]$Tick,

        [Parameter(Mandatory)]
        [Microsoft.Windows.Devices.Midi2.MidiMessage64[]]$Message
    )

    AddQueueAllNoteOffMessages -Message $Message

    [System.Threading.Monitor]::Enter($script:QueueSync)
    try {
        if ($script:MessageQueue.ContainsKey($Tick)) {
            $script:MessageQueue[$Tick] += $Message
        }
        else {
            $script:MessageQueue.Add($Tick, $Message)
        }

        $script:QueueMetadata.ScheduledEventCount += $Message.Count
        if ($Tick -gt $script:QueueMetadata.DurationTicks) {
            $script:QueueMetadata.DurationTicks = $Tick
        }
    }
    finally {
        [System.Threading.Monitor]::Exit($script:QueueSync)
    }
}
