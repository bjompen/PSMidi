function SendPSMidiAllNoteOffInternal {
    param(
        [Parameter(Mandatory)]
        [WindowsMidiServices.MidiEndpointConnection]$Connection,

        [Parameter()]
        [ValidateRange(0, 15)]
        [int[]]$Group = @(0..15)
    )

    foreach ($midiGroup in $Group) {
        foreach ($midiChannel in 0..15) {
            $message = [Microsoft.Windows.Devices.Midi2.Messages.MidiMessageBuilder]::BuildMidi2ChannelVoiceMessage(
                0,
                [Microsoft.Windows.Devices.Midi2.MidiGroup]::new($midiGroup),
                [Microsoft.Windows.Devices.Midi2.Messages.Midi2ChannelVoiceMessageStatus]::ControlChange,
                [Microsoft.Windows.Devices.Midi2.MidiChannel]::new($midiChannel),
                123,
                0
            )

            Send-PSMidiMessage -Connection $Connection -Message $message
        }
    }
}
