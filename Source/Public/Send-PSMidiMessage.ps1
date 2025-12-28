Function Send-PSMidiMessage {
    Param(
        [Parameter(Mandatory)]
        [WindowsMidiServices.MidiEndpointConnection]$Connection,

        [Parameter(Mandatory, ValueFromPipeline)]
        [Microsoft.Windows.Devices.Midi2.MidiMessage64]$Message
    )
    
    Send-MidiMessage -Connection $Connection -Words $($Message.Word0, $Message.Word1)
}
