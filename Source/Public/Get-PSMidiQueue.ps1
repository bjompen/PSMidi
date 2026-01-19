function Get-PSMidiQueue {
    param (
        [Parameter()]
        [ValidateSet('MessageQueue', 'MessageEvery')]
        [string]$Queue = 'MessageQueue'
    )
    switch ($Queue) {
        'MessageQueue' { $script:MessageQueue }
        'MessageEvery' { $script:MessageEvery }
    }
}