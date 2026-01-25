function IsPSMidiQueueRunning {
    Write-Output "---$($script:QueuePlayThread)---"
    try {
        Get-Job -Name $script:QueuePlayThread
    }
    catch {
        'No can get job'
    }
}