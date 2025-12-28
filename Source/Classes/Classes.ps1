enum NoteIndex {
    C = 0
    D = 2
    E = 4
    F = 5
    G = 7
    A = 9
    B = 11
    H = 11
}

Class Chord {
    [string] $BaseChord
    [int] $Octave
    [string] $Alt
    hidden [int] $AltMidi
    [int] $MidiNote

    Chord($Chord) {
        $null = $Chord -match '^(?<BaseNote>[a-gA-G])(?<Alt>[#b]?)(?<Octave>(-?[1-2]|[0-8])$)'

        $this.BaseChord = $Matches['BaseNote'].ToUpper()
        $this.Alt = $Matches['Alt'] ?? [string]::Empty
        $this.AltMidi = $Matches['Alt'] -eq 'b' ? [int]-1 : $Matches['Alt'] -eq '#' ? 1 : 0
        $this.Octave = $Matches['Octave']
        $this.MidiNote = (
                ([NoteIndex]$Matches['BaseNote'].ToUpper()).value__ + $this.AltMidi
            ) + (
                ([int]$Matches['Octave'] + 2) * 12)
    }
}