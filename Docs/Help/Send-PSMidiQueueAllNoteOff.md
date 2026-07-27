---
external help file: PSMidi-help.xml
Module Name: PSMidi
online version:
schema: 2.0.0
---

# Send-PSMidiQueueAllNoteOff

## SYNOPSIS
Sends the queue’s internal all-note-off message list.

## SYNTAX

```powershell
Send-PSMidiQueueAllNoteOff [-Connection] <MidiEndpointConnection> [<CommonParameters>]
```

## DESCRIPTION
Sends NoteOff messages currently tracked by queue state.  
The list is built from queued NoteOn message identities.

## EXAMPLES

### Example 1
```powershell
PS C:\> Send-PSMidiQueueAllNoteOff -Connection $connection
```

Sends queue-derived NoteOff messages immediately.

## PARAMETERS

### -Connection
Open `WindowsMidiServices` endpoint connection used for output.

```yaml
Type: MidiEndpointConnection
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.

## INPUTS

### None

## OUTPUTS

### System.Object

## NOTES

## RELATED LINKS

[Stop-PSMidiQueue](Stop-PSMidiQueue.md)

