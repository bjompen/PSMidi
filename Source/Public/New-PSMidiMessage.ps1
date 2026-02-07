

Function New-PSMidiMessage {
    [CmdletBinding(DefaultParameterSetName = 'Note')]
    Param(
        [Parameter(ParameterSetName = 'Note')]
        [Parameter(ParameterSetName = 'Pitch')]
        [ValidateSet('C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B')]
        [String]$Note = 'C',

        [Parameter(ParameterSetName = 'Note')]
        [Parameter(ParameterSetName = 'Pitch')]
        [ValidateRange(-2, 9)]
        [int]$Octave = 3, 

        [Parameter(ParameterSetName = 'Note')]
        [Parameter(ParameterSetName = 'Pitch')]
        [ValidateRange(0, 15)]
        [int]$Group = 0,

        [Parameter(ParameterSetName = 'Note')]
        [Parameter(ParameterSetName = 'Pitch')]
        [Microsoft.Windows.Devices.Midi2.Messages.Midi2ChannelVoiceMessageStatus]$MessageStatus = 'NoteOn',

        [Parameter(ParameterSetName = 'Note')]
        [Parameter(ParameterSetName = 'Pitch')]
        [ValidateRange(0, 15)]
        [int]$MidiChannel = 0,

        [Parameter(ParameterSetName = 'Note')]
        [Parameter(ParameterSetName = 'Pitch')]
        [ValidateRange(0, 65535)]
        [uint]$Velocity = 65535,

        [Parameter(ParameterSetName = 'Pitch')]
        [switch]$Pitch,

        [Parameter(ParameterSetName = 'Pitch')]
        [ValidateRange(0, 65535)]
        [int]$AttributeData
    )

    if ($PSBoundParameters.Keys.Contains('Pitch')) {
        $attributeType = 3
    }
    else {
        $attributeType = 0
        $AttributeData = 0
    }

    $Chord = [Chord]::new("${Note}${Octave}")
    $playNote = ($Chord.MidiNote -shl 8) -bor $attributeType

    [uint]$messageData = ($Velocity -shl 16) -bor $AttributeData

    [Microsoft.Windows.Devices.Midi2.Messages.MidiMessageBuilder]::BuildMidi2ChannelVoiceMessage(
        0,
        [Microsoft.Windows.Devices.Midi2.MidiGroup]::new($Group),
        $MessageStatus,
        [Microsoft.Windows.Devices.Midi2.MidiChannel]::new($MidiChannel),
        $playNote,
        $messageData
    )
}
