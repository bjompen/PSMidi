function ResetQueueTransportState {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Internal queue state reset helper.')]
    param ()

    $script:QueueState.CurrentTick = 0L
    $script:QueueState.CurrentBeat = 1
    $script:QueueState.TotalBeat = 1
    $script:QueueState.Bar = 1
    $script:QueueState.IsRunning = $false
}
