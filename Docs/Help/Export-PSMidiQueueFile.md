---
external help file: PSMidi-help.xml
Module Name: PSMidi
online version:
schema: 2.0.0
---

# Export-PSMidiQueueFile

## SYNOPSIS
Exports the current queue to a Standard MIDI file.

## SYNTAX

```powershell
Export-PSMidiQueueFile [-Path] <String> [-Force] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Exports queued events to `.mid`:
- Type 0 when note events are on one channel
- Type 1 when note events are on multiple channels

Recurring queue rules are ignored and produce a warning.

## EXAMPLES

### Example 1
```powershell
PS C:\> Export-PSMidiQueueFile -Path .\Tests\exportMidi.mid
```

Exports queue to a new MIDI file.

### Example 2
```powershell
PS C:\> Export-PSMidiQueueFile -Path .\Tests\exportMidi.mid -Force
```

Overwrites an existing file.

## PARAMETERS

### -Path
Target output `.mid` path.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Overwrites target file if it exists.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.

## INPUTS

### None

## OUTPUTS

### System.Management.Automation.PSCustomObject

## NOTES

## RELATED LINKS

[Add-PSMidiQueueFile](Add-PSMidiQueueFile.md)
[Get-PSMidiQueue](Get-PSMidiQueue.md)

