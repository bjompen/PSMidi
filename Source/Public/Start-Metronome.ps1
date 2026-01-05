function Start-Metronome {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [Alias('BPM')]
        [BPM]$Tempo,

        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock
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
        }
    }

    clean {
        $powerShell.Stop()
        $powerShell.Dispose()
    }
}
