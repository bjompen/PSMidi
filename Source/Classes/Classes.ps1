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

    Chord([string] $Chord) {
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

    Chord([int] $MidiIndexNote) {
        if (($MidiIndexNote % 12) -in @(0, 2, 4, 5, 7, 9,11)) {
            $this.BaseChord = [NoteIndex]($MidiIndexNote % 12)
            $this.Alt = [string]::Empty
            $this.AltMidi = 0
        }
        else {
            $this.BaseChord = [NoteIndex](($MidiIndexNote % 12) - 1)
            $this.Alt = '#'
            $this.AltMidi = 1
        }
        $this.Octave = [math]::Floor(($MidiIndexNote / 12) - 2)
        $this.MidiNote = $MidiIndexNote
    }
}

class BPM {
    [double] $MilliSeconds
    [double] $Ticks
    [int] $BPM
    [int] $TempoMicroseconds
    [int] $TicksPerQuarterNote

    hidden [void] SetTiming([double] $MilliSeconds, [int] $TicksPerQuarterNote) {
        $this.MilliSeconds = $MilliSeconds
        $this.Ticks = [math]::Round($MilliSeconds * 10000)
        $this.BPM = [math]::Round(60000 / $MilliSeconds)
        $this.TempoMicroseconds = [math]::Round($MilliSeconds * 1000)
        $this.TicksPerQuarterNote = $TicksPerQuarterNote
    }

    BPM([double] $MilliSeconds) {
        $this.SetTiming($MilliSeconds, 960)
    }

    BPM([double] $MilliSeconds, [int] $TicksPerQuarterNote) {
        $this.SetTiming($MilliSeconds, $TicksPerQuarterNote)
    }

    BPM([int] $BPM) {
        $this.SetTiming([math]::Round(60000 / $BPM, 3), 960)
        $this.BPM = $BPM
    }

    BPM([int] $BPM, [int] $TicksPerQuarterNote) {
        $this.SetTiming([math]::Round(60000 / $BPM, 3), $TicksPerQuarterNote)
        $this.BPM = $BPM
    }

    [long] BeatNumberToTick([long] $BeatNumber) {
        return [long]($BeatNumber * $this.TicksPerQuarterNote)
    }

    [long] BeatsToTicks([double] $BeatCount) {
        return [long][math]::Round($BeatCount * $this.TicksPerQuarterNote)
    }

    [long] TickDeltaToClockTicks([long] $TickDelta) {
        return $this.TickDeltaToClockTicks($TickDelta, $this.TempoMicroseconds)
    }

    [long] TickDeltaToClockTicks([long] $TickDelta, [double] $TempoMicroseconds) {
        return [long][math]::Round(($TickDelta * $TempoMicroseconds * 10) / $this.TicksPerQuarterNote)
    }
}