function Stop-PSMidiQueue {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Queue stop should not prompt for confirmation.')]
    param ()
    
    begin {}
    
    process {}
    
    end {
        try {
            $job = Get-Job -Name $script:QueuePlayThread -ErrorAction Stop
            if ($job.State -eq 'Running' -or $job.State -eq 'NotStarted') {
                $job | Stop-Job
            }
            $job | Remove-Job
        }
        catch { 
            Write-Error "Failed to stop PSMidiQueue. Is it started?"
        }

        if ($null -ne $script:QueueConnection) {
            SendQueueAllNoteOffInternal -Connection $script:QueueConnection
            $script:QueueConnection = $null
        }

        ResetQueueTransportState
    }
}
