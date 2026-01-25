function Stop-PSMidiQueue {
    [CmdletBinding()]
    param ()
    
    begin {}
    
    process {}
    
    end {
        try {
            Get-Job -Name $script:QueuePlayThread -ErrorAction Stop | Stop-Job
            Get-Job -Name $script:QueuePlayThread -ErrorAction Stop | Remove-Job
        }
        catch { 
            Write-Error "Failed to stop PSMidiQueue. Is it started?"
        }
    }

    clean {
        $script:currentBeat = 1
        $script:totalBeat = 1
        $script:bar = 1
    }
}