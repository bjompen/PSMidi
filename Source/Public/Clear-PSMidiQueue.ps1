function Clear-PSMidiQueue {
    param (
        [Parameter()]
        [ValidateSet('MessageQueue', 'RecurringQueueRules', 'TempoMap', 'QueueMetadata', 'QueueState', 'MessageEvery', 'MidiMessageQueue', 'MidiQueueMetadata', 'All')]
        [string]$Queue = 'All'
    )


    switch ($Queue) {
        'MessageQueue' {
            $script:MessageQueue.Clear()
            $script:QueueMetadata.ScheduledEventCount = 0
            $script:QueueMetadata.DurationTicks = 0
        }
        'RecurringQueueRules' {
            $script:RecurringQueueRules.Clear()
        }
        'TempoMap' {
            $script:QueueTempoMap.Clear()
            $script:QueueMetadata.TempoEventCount = 0
        }
        'QueueMetadata' {
            $script:QueueMetadata.LastSourcePath = $null
            $script:QueueMetadata.TicksPerQuarterNote = $null
            $script:QueueMetadata.TempoEventCount = 0
            $script:QueueMetadata.ScheduledEventCount = 0
            $script:QueueMetadata.DurationTicks = 0
        }
        'QueueState' { ResetQueueTransportState }
        'MessageEvery' {
            $script:RecurringQueueRules.Clear()
        }
        'MidiMessageQueue' {
            $script:MessageQueue.Clear()
            $script:QueueMetadata.ScheduledEventCount = 0
            $script:QueueMetadata.DurationTicks = 0
        }
        'MidiQueueMetadata' {
            $script:QueueMetadata.LastSourcePath = $null
            $script:QueueMetadata.TicksPerQuarterNote = $null
            $script:QueueMetadata.TempoEventCount = 0
            $script:QueueMetadata.ScheduledEventCount = 0
            $script:QueueMetadata.DurationTicks = 0
        }
        'All' {
            $script:QueueAllNoteOffMessages.Clear()
            $script:MessageQueue.Clear()
            $script:RecurringQueueRules.Clear()
            $script:QueueTempoMap.Clear()
            $script:QueueMetadata.LastSourcePath = $null
            $script:QueueMetadata.TicksPerQuarterNote = $null
            $script:QueueMetadata.TempoEventCount = 0
            $script:QueueMetadata.ScheduledEventCount = 0
            $script:QueueMetadata.DurationTicks = 0
            $script:QueueState.TicksPerQuarterNote = 960
            $script:QueueState.DefaultTempoMicroseconds = 500000
            $script:QueueState.BeatCount = 4
            ResetQueueTransportState
        }
    }
}