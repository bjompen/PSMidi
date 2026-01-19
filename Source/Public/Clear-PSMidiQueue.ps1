function Clear-PSMidiQueue {
    param (
        [Parameter()]
        [ValidateSet('MessageQueue', 'MessageEvery', 'All')]
        [string]$Queue = 'All'
    )
    switch ($Queue) {
        'MessageQueue' { $script:MessageQueue.Clear() }
        'MessageEvery' { $script:MessageEvery.Clear() }
        'All' { $script:MessageQueue.Clear(); $script:MessageEvery.Clear() }
    }
    
}