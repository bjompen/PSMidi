---
external help file: PSMidi-help.xml
Module Name: PSMidi
online version:
schema: 2.0.0
---

# Get-PSNoteIndexFromNoteName

## SYNOPSIS
This command calculates the note index in Midi from a note name.

## SYNTAX

```
Get-PSNoteIndexFromNoteName [[-NoteName] <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This command calculates the note index in Midi from a note name.

The octave / note name is aligned with the Midi class \[Microsoft.Windows.Devices.Midi2.Messages.MidiMessageHelper]::GetNoteOctaveFromNoteIndex(), so third octave is middle C.

The given note must be in the format '\<Note>\<octave>', f.eg 'C3', 'D#4', 'Eb5'.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-PSNoteIndexFromNoteName -NoteName C3
```
This command will output a 'Chprd' type object with the following properties

BaseChord Octave Alt MidiNote
--------- ------ --- --------
C              3           60

## PARAMETERS

### -NoteName
The note to calculate in '\<Note>\<octave>' format, f.eg 'C3', 'D#4', 'Eb5'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
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
