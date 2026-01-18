function Start-Metronome {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [Alias('BPM')]
        [BPM]$Tempo,

        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [Parameter()]
        [int]$Beat = 4
    )

    begin {}

    process {}

    end {
        $powerShell = [powershell]::Create()
        [void] $powershell.AddScript($ScriptBlock)

        $BPMSeconds = $Tempo.Ticks
        $nextTick = [datetime]::FromFileTime([Microsoft.Windows.Devices.Midi2.MidiClock]::Now).AddTicks($BPMSeconds)
        $interval = New-TimeSpan -Start $nextTick -End $nextTick.AddTicks($BPMSeconds)

        while ($true) {
            while ([datetime]::FromFileTime([Microsoft.Windows.Devices.Midi2.MidiClock]::Now) -lt $nextTick) {
                [System.Threading.Thread]::Sleep($interval)
            }
            $nextTick = $nextTick.AddTicks($BPMSeconds)

            $powershell.Invoke()
            
            Write-Verbose "Current Beat: $script:currentBeat"
            Write-Verbose "Total Beat: $script:totalBeat"
            Write-Verbose "Bar: $script:bar"
            $script:currentBeat++
            $script:totalBeat++
            if ($script:currentBeat -gt $Beat) {
                $script:currentBeat = 1
                $script:bar++
            }
        }
    }

    clean {
        $powerShell.Stop()
        $powerShell.Dispose()
        
        $script:currentBeat = 1
        $script:totalBeat = 1
        $script:bar = 1
    }
}
