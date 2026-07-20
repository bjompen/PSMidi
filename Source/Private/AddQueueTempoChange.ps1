function AddQueueTempoChange {
    param(
        [Parameter(Mandatory)]
        [long]$Tick,

        [Parameter(Mandatory)]
        [int]$TempoMicroseconds
    )

    [System.Threading.Monitor]::Enter($script:QueueSync)
    try {
        if ($script:QueueTempoMap.ContainsKey($Tick)) {
            $script:QueueTempoMap[$Tick] = $TempoMicroseconds
        }
        else {
            $script:QueueTempoMap.Add($Tick, $TempoMicroseconds)
        }

        $script:QueueMetadata.TempoEventCount = $script:QueueTempoMap.Count
    }
    finally {
        [System.Threading.Monitor]::Exit($script:QueueSync)
    }
}
