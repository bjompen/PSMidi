---
external help file: PSMidi-help.xml
Module Name: PSMidi
online version:
schema: 2.0.0
---

# Get-PSMidiQueue

## SYNOPSIS
Returns queue data structures and state.

## SYNTAX

```powershell
Get-PSMidiQueue [[-Queue] <String>] [<CommonParameters>]
```

## DESCRIPTION
Returns selected queue data including message queue, recurring rules, tempo map, metadata, and runtime state.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-PSMidiQueue
```

Returns all queue surfaces as a single object.

### Example 2
```powershell
PS C:\> Get-PSMidiQueue -Queue MessageQueue
```

Returns only queued scheduled messages.

## PARAMETERS

### -Queue
Selects which queue surface to return.

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: MessageQueue, RecurringQueueRules, TempoMap, QueueMetadata, QueueState, All

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

[Clear-PSMidiQueue](Clear-PSMidiQueue.md)

