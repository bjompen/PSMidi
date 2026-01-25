function Start-PSMidiQueue {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [Alias('BPM')]
        [BPM]$Tempo,
        
        [Parameter()]
        [int]$Beat = 4,

        [Parameter(Mandatory)]
        [WindowsMidiServices.MidiEndpointConnection]$Connection
    )

    begin {}

    process {}

    end {
        $BPMSeconds = $Tempo.Ticks
        $nextTick = [datetime]::FromFileTime([Microsoft.Windows.Devices.Midi2.MidiClock]::Now).AddTicks($BPMSeconds)
        $interval = New-TimeSpan -Start $nextTick -End $nextTick.AddTicks($BPMSeconds)

        try {
            $null = Get-Job -Name $script:QueuePlayThread -ErrorAction Stop
            Write-Error 'PSMidiQueue already started'
        }
        catch { 
            $null = Start-ThreadJob -Name $script:QueuePlayThread -ScriptBlock {
                $MQ = $using:MessageQueue
                $ME = $using:MessageEvery

                $BPMS = $using:BPMSeconds
                $NT = $using:nextTick
                $IV = $using:interval

                $CONN = $Using:Connection

                while ($true) {
                    while ([datetime]::FromFileTime([Microsoft.Windows.Devices.Midi2.MidiClock]::Now) -lt $NT) {
                        [System.Threading.Thread]::Sleep($IV / 1000)
                    }
                    $NT = $NT.AddTicks($BPMS)
                    
                    if ($MQ.ContainsKey($script:totalBeat)) {
                        $MQ.Item($script:totalBeat) | ForEach-Object { Send-PSMidiMessage -Connection $CONN -Message $_ }
                    }
                    if ($ME.ContainsKey($script:currentBeat)) {
                        $ME.Item($script:currentBeat) | ForEach-Object { Send-PSMidiMessage -Connection $CONN -Message $_ }
                    }
                    
                    $script:currentBeat++
                    $script:totalBeat++
                    if ($script:currentBeat -gt $using:Beat) {
                        $script:currentBeat = 1
                        $script:bar++
                    }
                }
            }
        }
    }

    clean {
        $script:currentBeat = 1
        $script:totalBeat = 1
        $script:bar = 1
    }
}
