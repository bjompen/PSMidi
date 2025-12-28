---
external help file: PSMidi-help.xml
Module Name: PSMidi
online version:
schema: 2.0.0
---

# Send-PSMidiMessage

## SYNOPSIS
This is a wrapper around the built in Send-MidiMessage command, adding functionality to accept pipeline input and accepting full MidiMessage64 objects as output by New-PSMidiMessage.

## SYNTAX

```
Send-PSMidiMessage [-Connection] <MidiEndpointConnection> [-Message] <MidiMessage64>
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This is a wrapper around the built in Send-MidiMessage command, adding functionality to accept pipeline input and accepting full MidiMessage64 objects as output by New-PSMidiMessage.

## EXAMPLES

### Example 1
```powershell
PS C:\> $MidiMessage = New-PSMidiMessage
PS C:\> Send-PSMidiMessage -Connection $connection -Message $MidiMessage
```

This command will first create a message using New-PSMidiMessage, then send this message to output. 

## PARAMETERS

### -Connection
A connection as started by following the guide in [the Midi PowerShell module](https://microsoft.github.io/MIDI/tools/powershell/)

```yaml
Type: MidiEndpointConnection
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Message
A message as output by New-PSMidiMessage

```yaml
Type: MidiMessage64
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```


### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### Microsoft.Windows.Devices.Midi2.MidiMessage64

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
