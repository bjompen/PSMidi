function AddQueueAllNoteOffMessages {
    param(
        [Parameter(Mandatory)]
        [Microsoft.Windows.Devices.Midi2.MidiMessage64[]]$Message
    )

    [System.Threading.Monitor]::Enter($script:QueueSync)
    try {
        foreach ($queuedMessage in $Message) {
            [uint32]$word0 = $queuedMessage.Word0
            [int]$status = ($word0 -shr 20) -band 0x0F
            if ($status -ne 0x9) {
                continue
            }

            [int]$group = ($word0 -shr 24) -band 0x0F
            [int]$channel = ($word0 -shr 16) -band 0x0F
            [uint16]$index = $word0 -band 0xFFFF
            [string]$messageKey = "$group`:$channel`:$index"

            $noteOffMessage = [Microsoft.Windows.Devices.Midi2.Messages.MidiMessageBuilder]::BuildMidi2ChannelVoiceMessage(
                0,
                [Microsoft.Windows.Devices.Midi2.MidiGroup]::new($group),
                [Microsoft.Windows.Devices.Midi2.Messages.Midi2ChannelVoiceMessageStatus]::NoteOff,
                [Microsoft.Windows.Devices.Midi2.MidiChannel]::new($channel),
                $index,
                0
            )

            if ($script:QueueAllNoteOffMessages.ContainsKey($messageKey)) {
                $script:QueueAllNoteOffMessages[$messageKey] = $noteOffMessage
            }
            else {
                $script:QueueAllNoteOffMessages.Add($messageKey, $noteOffMessage)
            }
        }
    }
    finally {
        [System.Threading.Monitor]::Exit($script:QueueSync)
    }
}
