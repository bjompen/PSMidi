---
external help file: PSMidi-help.xml
Module Name: PSMidi
online version:
schema: 2.0.0
---

# Clear-PSMidiQueue

## SYNOPSIS
Clears queue data structures and state sections.

## SYNTAX

```powershell
Clear-PSMidiQueue [[-Queue] <String>] [<CommonParameters>]
```

## DESCRIPTION
Clears selected queue surfaces including scheduled messages, recurring rules, tempo map, metadata, and full queue state.

## EXAMPLES

### Example 1
```powershell
PS C:\> Clear-PSMidiQueue
```

Clears all queue surfaces.

### Example 2
```powershell
PS C:\> Clear-PSMidiQueue -Queue MessageQueue
```

Clears only scheduled queued messages.

## PARAMETERS

### -Queue
Selects which queue area to clear.

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: MessageQueue, RecurringQueueRules, TempoMap, QueueMetadata, QueueState, MessageEvery, MidiMessageQueue, MidiQueueMetadata, All

Required: False
Position: 0
Default value: All
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

[Get-PSMidiQueue](Get-PSMidiQueue.md)

