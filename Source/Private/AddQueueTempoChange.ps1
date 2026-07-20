function AddQueueTempoChange {
    param(
        [Parameter(Mandatory)]
        [long]$Tick,

        [Parameter(Mandatory)]
        [int]$TempoMicroseconds
    )

    if ($script:QueueTempoMap.ContainsKey($Tick)) {
        $script:QueueTempoMap[$Tick] = $TempoMicroseconds
    }
    else {
        $script:QueueTempoMap.Add($Tick, $TempoMicroseconds)
    }

    $script:QueueMetadata.TempoEventCount = $script:QueueTempoMap.Count
}
