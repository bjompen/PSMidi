---
external help file: PSMidi-help.xml
Module Name: PSMidi
online version:
schema: 2.0.0
---

# Start-PSMidiQueue

## SYNOPSIS
Starts queue playback in a background thread job.

## SYNTAX

```powershell
Start-PSMidiQueue [[-Tempo] <BPM>] [[-Beat] <Int32>] [-Connection] <MidiEndpointConnection>
 [<CommonParameters>]
```

## DESCRIPTION
Starts queue playback using current queue data, tempo map, and recurring rules.
Playback sends queued messages over the provided MIDI endpoint connection.

Tempo selection rules:
- If queue tempo-map entries exist, queue playback uses that tempo map.
- If no queue tempo-map exists and `-Tempo` is provided, it uses `-Tempo`.
- If no queue tempo-map exists and `-Tempo` is not provided, it defaults to 120 BPM and writes a warning.

## EXAMPLES

### Example 1
```powershell
PS C:\> Start-PSMidiQueue -Tempo 120 -Connection $connection
```

Starts playback at 120 BPM.

### Example 2
```powershell
PS C:\> Start-PSMidiQueue -Connection $connection
```

Starts playback using queue tempo-map values when present; otherwise defaults to 120 BPM with a warning.

## PARAMETERS

### -Tempo
Optional tempo context used when queue tempo-map values are not present.

```yaml
Type: BPM
Parameter Sets: (All)
Aliases: BPM

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Beat
Beats per bar for recurring rule matching.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 4
Accept pipeline input: False
Accept wildcard characters: False
```

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
[Add-PSMidiQueueMessage](Add-PSMidiQueueMessage.md)
[Add-PSMidiQueueFile](Add-PSMidiQueueFile.md)
