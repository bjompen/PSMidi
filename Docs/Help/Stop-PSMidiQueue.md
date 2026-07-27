---
external help file: PSMidi-help.xml
Module Name: PSMidi
online version:
schema: 2.0.0
---

# Stop-PSMidiQueue

## SYNOPSIS
Stops queue playback and sends queue-derived all-note-off messages.

## SYNTAX

```powershell
Stop-PSMidiQueue [<CommonParameters>]
```

## DESCRIPTION
Stops the running queue thread job, sends queue all-note-off messages on the active connection, and resets queue transport state.

## EXAMPLES

### Example 1
```powershell
PS C:\> Stop-PSMidiQueue
```

Stops queue playback.

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.

## INPUTS

### None

## OUTPUTS

### System.Object

## NOTES

## RELATED LINKS

[Start-PSMidiQueue](Start-PSMidiQueue.md)
[Send-PSMidiQueueAllNoteOff](Send-PSMidiQueueAllNoteOff.md)

