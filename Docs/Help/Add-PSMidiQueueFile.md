---
external help file: PSMidi-help.xml
Module Name: PSMidi
online version:
schema: 2.0.0
---

# Add-PSMidiQueueFile

## SYNOPSIS
Adds MIDI file events to the queue from a path or parsed file objects.

## SYNTAX

### Path (Default)
```powershell
Add-PSMidiQueueFile [-Path] <String> [-Group <Int32>] [<CommonParameters>]
```

### FileObject
```powershell
Add-PSMidiQueueFile [-FileObject] <PSObject[]> [-Group <Int32>] [<CommonParameters>]
```

## DESCRIPTION
Adds MIDI events to the queue by reading a `.mid` file directly or by using objects emitted by `Get-PSMidiFile`.
Tempo events and note events are translated into queue timing and queued messages.

## EXAMPLES

### Example 1
```powershell
PS C:\> Add-PSMidiQueueFile -Path .\Tests\AdvancedMidi.mid
```

Reads and queues events from file.

### Example 2
```powershell
PS C:\> Get-PSMidiFile -Path .\Tests\AdvancedMidi.mid | Add-PSMidiQueueFile
```

Queues events from pipeline input.

### Example 3
```powershell
PS C:\> $f = Get-PSMidiFile -Path .\Tests\AdvancedMidi.mid
PS C:\> Add-PSMidiQueueFile -FileObject $f
```

Queues events from a variable.

## PARAMETERS

### -Path
Path to a MIDI file.

```yaml
Type: String
Parameter Sets: Path
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FileObject
Objects from `Get-PSMidiFile` containing event metadata and values.

```yaml
Type: PSObject[]
Parameter Sets: FileObject
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Group
MIDI group (0..15) used for generated queue messages.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.

## INPUTS

### System.Management.Automation.PSObject

## OUTPUTS

### System.Management.Automation.PSCustomObject

## NOTES

## RELATED LINKS

[Get-PSMidiFile](Get-PSMidiFile.md)
[Start-PSMidiQueue](Start-PSMidiQueue.md)

