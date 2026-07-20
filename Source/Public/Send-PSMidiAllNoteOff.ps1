function Send-PSMidiAllNoteOff {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [WindowsMidiServices.MidiEndpointConnection]$Connection,

        [Parameter()]
        [ValidateRange(0, 15)]
        [int[]]$Group = @(0..15)
    )

    SendPSMidiAllNoteOffInternal -Connection $Connection -Group $Group
}
