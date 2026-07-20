function Get-PSMidiQueue {
    param (
        [Parameter()]
        [ValidateSet('MessageQueue', 'RecurringQueueRules', 'TempoMap', 'QueueMetadata', 'QueueState', 'All')]
        [string]$Queue = 'All'
    )
    switch ($Queue) {
        'MessageQueue' { $script:MessageQueue }
        'RecurringQueueRules' { $script:RecurringQueueRules }
        'TempoMap' { $script:QueueTempoMap }
        'QueueMetadata' { [PSCustomObject]$script:QueueMetadata }
        'QueueState' { [PSCustomObject]$script:QueueState }
        'All' {
            [PSCustomObject]@{
                'MessageQueue' = $script:MessageQueue
                'RecurringQueueRules' = $script:RecurringQueueRules
                'TempoMap' = $script:QueueTempoMap
                'QueueMetadata' = [PSCustomObject]$script:QueueMetadata
                'QueueState' = [PSCustomObject]$script:QueueState
            }
        }
    }
}