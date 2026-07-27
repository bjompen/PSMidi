---
external help file: PSMidi-help.xml
Module Name: PSMidi
online version:
schema: 2.0.0
---

# Add-PSMidiQueueMessage

## SYNOPSIS
Adds MIDI messages to the queue using beat-based scheduling.

## SYNTAX

### SendNow (Default)
```powershell
Add-PSMidiQueueMessage [-Message] <MidiMessage64[]> [-Tempo <BPM>] [-SendNow]
 [<CommonParameters>]
```

### Next
```powershell
Add-PSMidiQueueMessage [-Message] <MidiMessage64[]> [-Tempo <BPM>] [-Next] <Int32>
 [-Beat] <Int32> [<CommonParameters>]
```

### OnTotal
```powershell
Add-PSMidiQueueMessage [-Message] <MidiMessage64[]> [-Tempo <BPM>] [-OnTotalBeat] <Int32>
 [<CommonParameters>]
```

### Every
```powershell
Add-PSMidiQueueMessage [-Message] <MidiMessage64[]> [-Tempo <BPM>] [-Every] <Int32>
 [<CommonParameters>]
```

## DESCRIPTION
Adds one or more `MidiMessage64` values to the queue.  
Supports immediate scheduling, scheduling on a specific beat in the bar, on a total beat index, or recurring beat rules.

## EXAMPLES

### Example 1
```powershell
PS C:\> Add-PSMidiQueueMessage -Message (New-PSMidiMessage -Note C -Octave 2) -OnTotalBeat 1
```

Queues a note message at total beat 1.

### Example 2
```powershell
PS C:\> Add-PSMidiQueueMessage -Message (New-PSMidiMessage -Note C -Octave 2) -Every 1
```

Adds a recurring queue rule to send the message on every beat 1 in the bar.

## PARAMETERS

### -Message
One or more MIDI 2 message objects to queue.

```yaml
Type: MidiMessage64[]
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Tempo
Optional queue tempo context. When provided, it enforces ticks-per-quarter-note compatibility with the active queue.

```yaml
Type: BPM
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SendNow
Schedules message on the next available beat tick.

```yaml
Type: SwitchParameter
Parameter Sets: SendNow
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Next
Schedules message on the next occurrence of beat `<n>` within the bar.

```yaml
Type: Int32
Parameter Sets: Next
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Beat
Beats per bar used with `-Next`.

```yaml
Type: Int32
Parameter Sets: Next
Aliases:

Required: True
Position: Named
Default value: 4
Accept pipeline input: False
Accept wildcard characters: False
```

### -OnTotalBeat
Schedules message on an absolute total beat index.

```yaml
Type: Int32
Parameter Sets: OnTotal
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Every
Adds a recurring beat rule.

```yaml
Type: Int32
Parameter Sets: Every
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

[Add-PSMidiQueueFile](Add-PSMidiQueueFile.md)
[Start-PSMidiQueue](Start-PSMidiQueue.md)

