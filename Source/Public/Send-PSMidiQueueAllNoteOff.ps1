function Send-PSMidiQueueAllNoteOff {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [WindowsMidiServices.MidiEndpointConnection]$Connection
    )

    SendQueueAllNoteOffInternal -Connection $Connection
}
