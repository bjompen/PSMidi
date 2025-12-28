---
external help file: PSMidi-help.xml
Module Name: PSMidi
online version:
schema: 2.0.0
---

# New-PSMidiMessage

## SYNOPSIS
This command outputs a single midi2.0 message object, containing metadata and midi words

## SYNTAX

### Note (Default)
```
New-PSMidiMessage [-Note <String>] [-Octave <Int32>] [-Group <Int32>]
 [-MessageStatus <Midi2ChannelVoiceMessageStatus>] [-MidiChannel <Int32>] [-Velocity <UInt32>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Pitch
```
New-PSMidiMessage [-Note <String>] [-Octave <Int32>] [-Group <Int32>]
 [-MessageStatus <Midi2ChannelVoiceMessageStatus>] [-MidiChannel <Int32>] [-Velocity <UInt32>] [-Pitch]
 [-AttributeData <Int32>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This command outputs a single midi2.0 message object, containing metadata and midi words.

If no parameters are given the output words will be a NoteOn (press a button down), with note C3, Channel and Group 0, and velocity at max level.

This object can then be used as a packet to send as midi output.

## EXAMPLES

### Example 1
```powershell
PS C:\> New-PSMidiMessage
```

This command will output a MidiMessage64 type object containing the words for a NoteOn, note C3, Channel and Group 0, and velocity at max level.

### Example 2
```powershell
PS C:\> New-PSMidiMessage -Note F -Octave 5 -MidiChannel 2 -Group 1 -MessageStatus NoteOff -Velocity 32768
```

This command will output a MidiMessage64 type object containing the words for a NoteOff, note F5, Channel 2, Group 1, and velocity at 50 % level.

## PARAMETERS

### -AttributeData
If Pitch is set, this is the value sent as metadata in the attribute field (Implemented, not verified functioning.)

```yaml
Type: Int32
Parameter Sets: Pitch
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Group
Midi group, 0 - 15

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MessageStatus
The message type of the Midi2.0 package. Most common is NoteOn (press key down) and NoteOff (release key)

```yaml
Type: Midi2ChannelVoiceMessageStatus
Parameter Sets: (All)
Aliases:
Accepted values: RegisteredPerNoteController, AssignablePerNoteController, RegisteredController, AssignableController, RelativeRegisteredController, RelativeAssignableController, PerNotePitchBend, NoteOff, NoteOn, PolyPressure, ControlChange, ProgramChange, ChannelPressure, PitchBend, PerNoteManagement

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MidiChannel
Midi channel.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Note
Which base note to set in Word0

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: C, C#, D, D#, E, F, F#, G, G#, A, A#, B

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Octave
Which octave to set in Word0. This octave aligns with the Windows 11 Midi2.0 class and uses 3 as centre key. 

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Pitch
This switch sets the last 8 bits of Word0 to 0x3, which is a pitch change. According to the spec there are no more standard values for this setting yet.

```yaml
Type: SwitchParameter
Parameter Sets: Pitch
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Velocity
Velocity of key strike

```yaml
Type: UInt32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```


### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
