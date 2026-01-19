function Add-PSMidiQueueMessage {
    [CmdletBinding(DefaultParameterSetName = 'SendNow')]
    param (
        [Parameter(Mandatory)]
        [Microsoft.Windows.Devices.Midi2.MidiMessage64[]]$Message,

        [Parameter(ParameterSetName = 'SendNow')]
        [switch]$SendNow,

        # Add this chord on next <n> beat
        [Parameter(ParameterSetName = 'Next')]
        [int]$Next,

        [Parameter(Mandatory, ParameterSetName = 'Next')]
        [int]$Beat = 4,

        # Add this chord on total beat number <n>
        [Parameter(ParameterSetName = 'OnTotal')]
        [int]$OnTotalBeat,

        # Add this beat on every <n> (ever '1' f.eg)
        [Parameter(ParameterSetName = 'Every')]
        [int]$Every
    )

    function AddToQueue($key) {
        if ($script:MessageQueue.ContainsKey($key)) {
            $script:MessageQueue[$key] += $Message
        }
        else {
            $script:MessageQueue.Add($key, $Message)
        }
    }

    if ($PSCmdlet.ParameterSetName -eq 'SendNow') {
        $key = $script:totalBeat + 1
        AddToQueue $key
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'Next') {
        $key = $script:totalBeat + ($Beat - $script:currentBeat) 
        AddToQueue $key
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'OnTotal') {
        $key = $OnTotalBeat
        AddToQueue $key
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'Every') {
        if ($script:MessageEvery.ContainsKey($Every)) {
            $script:MessageEvery[$Every] += $Message
        }
        else {
            $script:MessageEvery.Add($Every, $Message)
        }
    }
}