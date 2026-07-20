function SendQueueAllNoteOffInternal {
    param(
        [Parameter(Mandatory)]
        [WindowsMidiServices.MidiEndpointConnection]$Connection
    )

    [Microsoft.Windows.Devices.Midi2.MidiMessage64[]]$allNoteOffMessages = @()

    [System.Threading.Monitor]::Enter($script:QueueSync)
    try {
        $allNoteOffMessages = @($script:QueueAllNoteOffMessages.Values)
    }
    finally {
        [System.Threading.Monitor]::Exit($script:QueueSync)
    }

    foreach ($message in $allNoteOffMessages | Sort-Object -Property Word0) {
        Send-PSMidiMessage -Connection $Connection -Message $message
    }
}
