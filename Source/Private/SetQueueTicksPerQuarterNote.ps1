function SetQueueTicksPerQuarterNote {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Internal queue timing helper.')]
    param(
        [Parameter(Mandatory)]
        [int]$TicksPerQuarterNote
    )

    if ($script:MessageQueue.Count -gt 0 -or $script:QueueTempoMap.Count -gt 0) {
        if ($script:QueueState.TicksPerQuarterNote -ne $TicksPerQuarterNote) {
            Write-Error "Queue already contains scheduled items for $($script:QueueState.TicksPerQuarterNote) ticks per quarter note and cannot switch to $TicksPerQuarterNote."
            return $false
        }
    }

    $script:QueueState.TicksPerQuarterNote = $TicksPerQuarterNote
    $script:QueueMetadata.TicksPerQuarterNote = $TicksPerQuarterNote
    return $true
}
