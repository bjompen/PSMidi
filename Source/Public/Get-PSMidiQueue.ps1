function Get-PSMidiQueue {
    param (
        [Parameter()]
        [ValidateSet('MessageQueue', 'RecurringQueueRules', 'TempoMap', 'QueueMetadata', 'QueueState', 'MessageEvery', 'MidiMessageQueue', 'MidiQueueMetadata')]
        [string]$Queue = 'MessageQueue'
    )
    switch ($Queue) {
        'MessageQueue' { $script:MessageQueue }
        'RecurringQueueRules' { $script:RecurringQueueRules }
        'TempoMap' { $script:QueueTempoMap }
        'QueueMetadata' { [PSCustomObject]$script:QueueMetadata }
        'QueueState' { [PSCustomObject]$script:QueueState }
        'MessageEvery' { $script:RecurringQueueRules }
        'MidiMessageQueue' { $script:MessageQueue }
        'MidiQueueMetadata' { [PSCustomObject]$script:QueueMetadata }
    }
}