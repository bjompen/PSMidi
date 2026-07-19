
Function Get-PSMidiFile {
    <#
    .SYNOPSIS
        Reads a MIDI (.mid) file and outputs all events as a stream of PowerShell objects.

    .DESCRIPTION
        Parses a Standard MIDI File (SMF) and emits one PSCustomObject per MIDI event.
        Each object carries the full file-level metadata (format, track count, timing),
        track-level metadata (track number, track name, instrument name) and all
        event-specific fields (note, velocity, controller, tempo, key/time signature …).
        Unused fields are set to $null so every object has an identical schema.

    .PARAMETER Path
        Path to one or more .mid files. Accepts pipeline input and the FullName
        property from Get-ChildItem.

    .EXAMPLE
        Get-PSMidiFile -Path .\song.mid

    .EXAMPLE
        Get-ChildItem *.mid | Get-PSMidiFile | Where-Object EventType -eq 'NoteOn'

    .EXAMPLE
        Get-PSMidiFile .\song.mid | Where-Object EventType -eq 'SetTempo' | Select-Object -First 1
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        [string]$Path
    )

    Begin {
        # --- helper: read a 4-byte big-endian uint32 from a byte array ---
        $ReadInt32 = {
            param([byte[]]$b, [int]$offset)
            ([uint32]$b[$offset] -shl 24) -bor
            ([uint32]$b[$offset+1] -shl 16) -bor
            ([uint32]$b[$offset+2] -shl 8) -bor
            [uint32]$b[$offset+3]
        }

        # --- helper: read a 2-byte big-endian uint16 from a byte array ---
        $ReadInt16 = {
            param([byte[]]$b, [int]$offset)
            ([uint16]$b[$offset] -shl 8) -bor [uint16]$b[$offset+1]
        }

        # --- helper: read a MIDI variable-length quantity (VLQ) ---
        $ReadVLQ = {
            param([byte[]]$b, [int]$offset)
            $value = 0
            $pos   = $offset
            do {
                $byte  = $b[$pos++]
                $value = ($value -shl 7) -bor ($byte -band 0x7F)
            } while (($byte -band 0x80) -ne 0)
            [PSCustomObject]@{ Value = $value; NextPos = $pos }
        }

        # --- helper: return the standard name for a MIDI CC number ---
        $ControllerName = {
            param([int]$cc)
            switch ($cc) {
                0   { 'Bank Select MSB' }
                1   { 'Modulation Wheel' }
                2   { 'Breath Controller' }
                4   { 'Foot Controller' }
                5   { 'Portamento Time' }
                6   { 'Data Entry MSB' }
                7   { 'Channel Volume' }
                8   { 'Balance' }
                10  { 'Pan' }
                11  { 'Expression Controller' }
                12  { 'Effect Control 1' }
                13  { 'Effect Control 2' }
                16  { 'General Purpose Controller 1' }
                17  { 'General Purpose Controller 2' }
                18  { 'General Purpose Controller 3' }
                19  { 'General Purpose Controller 4' }
                32  { 'Bank Select LSB' }
                38  { 'Data Entry LSB' }
                64  { 'Sustain Pedal' }
                65  { 'Portamento On/Off' }
                66  { 'Sostenuto' }
                67  { 'Soft Pedal' }
                68  { 'Legato Footswitch' }
                69  { 'Hold 2' }
                70  { 'Sound Controller 1 (Variation)' }
                71  { 'Sound Controller 2 (Timbre)' }
                72  { 'Sound Controller 3 (Release)' }
                73  { 'Sound Controller 4 (Attack)' }
                74  { 'Sound Controller 5 (Brightness)' }
                75  { 'Sound Controller 6' }
                76  { 'Sound Controller 7' }
                77  { 'Sound Controller 8' }
                78  { 'Sound Controller 9' }
                79  { 'Sound Controller 10' }
                80  { 'General Purpose Controller 5' }
                81  { 'General Purpose Controller 6' }
                82  { 'General Purpose Controller 7' }
                83  { 'General Purpose Controller 8' }
                84  { 'Portamento Control' }
                91  { 'Effects 1 Depth (Reverb)' }
                92  { 'Effects 2 Depth (Tremolo)' }
                93  { 'Effects 3 Depth (Chorus)' }
                94  { 'Effects 4 Depth (Detune)' }
                95  { 'Effects 5 Depth (Phaser)' }
                96  { 'Data Increment' }
                97  { 'Data Decrement' }
                98  { 'NRPN LSB' }
                99  { 'NRPN MSB' }
                100 { 'RPN LSB' }
                101 { 'RPN MSB' }
                120 { 'All Sound Off' }
                121 { 'Reset All Controllers' }
                122 { 'Local Control On/Off' }
                123 { 'All Notes Off' }
                124 { 'Omni Mode Off' }
                125 { 'Omni Mode On' }
                126 { 'Mono Mode On' }
                127 { 'Poly Mode On' }
                default {
                    if ($cc -ge 33 -and $cc -le 63) { "LSB for Controller $($cc - 32)" }
                    else { "Controller $cc" }
                }
            }
        }

        $noteNames = @('C','C#','D','D#','E','F','F#','G','G#','A','A#','B')

        $minorKeyNames = @{
            0='A'; 1='E'; 2='B'; 3='F#'; 4='C#'; 5='G#'; 6='D#'; 7='A#';
            -1='D'; -2='G'; -3='C'; -4='F'; -5='Bb'; -6='Eb'; -7='Ab'
        }
        $majorKeyNames = @{
            0='C'; 1='G'; 2='D'; 3='A'; 4='E'; 5='B'; 6='F#'; 7='C#';
            -1='F'; -2='Bb'; -3='Eb'; -4='Ab'; -5='Db'; -6='Gb'; -7='Cb'
        }
    }

    Process {
        $resolvedPath = Resolve-Path -Path $Path -ErrorAction Stop
        $filePath = $resolvedPath.ProviderPath
        $fileName  = [System.IO.Path]::GetFileName($filePath)
        $bytes     = [System.IO.File]::ReadAllBytes($filePath)

        if ([System.Text.Encoding]::ASCII.GetString($bytes[0..3]) -ne 'MThd') {
            Write-Error "'$fileName' is not a valid Standard MIDI File (missing MThd header)."
            return
        }

        $headerLen          = & $ReadInt32 $bytes 4
        $format             = & $ReadInt16 $bytes 8
        $numTracks          = & $ReadInt16 $bytes 10
        $divisionRaw        = & $ReadInt16 $bytes 12

        $formatName = switch ($format) {
            0       { 'Single track' }
            1       { 'Multiple tracks (synchronous)' }
            2       { 'Multiple tracks (asynchronous)' }
            default { "Unknown ($format)" }
        }

        # Division: bit 15 selects timecode (SMPTE) vs. ticks-per-quarter-note
        if ($divisionRaw -band 0x8000) {
            $ticksPerQuarterNote = $null
            $smpteFrameRate  = -(([sbyte]($divisionRaw -shr 8)))
            $ticksPerFrame   = $divisionRaw -band 0x00FF
        }
        else {
            $ticksPerQuarterNote = $divisionRaw
            $smpteFrameRate  = $null
            $ticksPerFrame   = $null
        }

        # Cursor starts right after the header chunk
        $pos = 8 + $headerLen   # 8 = 4 (magic) + 4 (length field)

        for ($trackNum = 1; $trackNum -le $numTracks; $trackNum++) {
            if ($pos + 8 -gt $bytes.Length) {
                Write-Warning "Unexpected end of file before track $trackNum."
                break
            }

            if ([System.Text.Encoding]::ASCII.GetString($bytes[$pos..($pos+3)]) -ne 'MTrk') {
                Write-Warning "Expected MTrk at byte $pos (track $trackNum). Skipping rest of file."
                break
            }

            $trackLen   = & $ReadInt32 $bytes ($pos + 4)
            $trackStart = $pos + 8
            $trackEnd   = $trackStart + $trackLen
            $pos        = $trackEnd          # advance file cursor to next track

            $absTime       = 0
            $currentPos    = $trackStart
            $runningStatus = 0
            $trackName     = $null
            $instrumentName = $null

            while ($currentPos -lt $trackEnd) {
                # --- delta time ---
                $vlq        = & $ReadVLQ $bytes $currentPos
                $deltaTime  = $vlq.Value
                $currentPos = $vlq.NextPos
                $absTime   += $deltaTime

                # --- status byte (or running-status data byte) ---
                $nextByte = $bytes[$currentPos]
                if ($nextByte -ge 0x80) {
                    $currentStatus = $nextByte
                    $currentPos++
                    # Channel messages update running status; meta/sysex do not
                    if ($currentStatus -ge 0x80 -and $currentStatus -le 0xEF) {
                        $runningStatus = $currentStatus
                    }
                }
                else {
                    # Data byte — reuse running status, don't advance
                    $currentStatus = $runningStatus
                }

                # --- build the shared metadata frame for this event ---
                $ev = [ordered]@{
                    FileName             = $fileName
                    FilePath             = $filePath
                    Format               = $format
                    FormatName           = $formatName
                    NumTracks            = $numTracks
                    TicksPerQuarterNote  = $ticksPerQuarterNote
                    SMPTEFrameRate       = $smpteFrameRate
                    TicksPerFrame        = $ticksPerFrame
                    TrackNumber          = $trackNum
                    TrackName            = $trackName
                    InstrumentName       = $instrumentName
                    DeltaTick            = $deltaTime
                    AbsoluteTick         = $absTime
                    EventType            = $null
                    Channel              = $null
                    Note                 = $null
                    NoteName             = $null
                    Octave               = $null
                    Velocity             = $null
                    Controller           = $null
                    ControllerName       = $null
                    Value                = $null
                    Program              = $null
                    PitchBend            = $null
                    TempoMicroseconds    = $null
                    BPM                  = $null
                    TimeSignatureNumerator   = $null
                    TimeSignatureDenominator = $null
                    MetronomeClocks          = $null
                    ThirtySecondNotesPerQuarter = $null
                    KeySignatureSharpsFlats  = $null
                    KeySignatureMode         = $null
                    KeySignatureName         = $null
                    SMPTEOffset              = $null
                    Text                     = $null
                    RawData                  = $null
                }

                # -------------------------------------------------------
                # META EVENT  (0xFF)
                # -------------------------------------------------------
                if ($currentStatus -eq 0xFF) {
                    $metaType   = $bytes[$currentPos]; $currentPos++
                    $vlq        = & $ReadVLQ $bytes $currentPos
                    $metaLen    = $vlq.Value
                    $currentPos = $vlq.NextPos
                    $metaData   = if ($metaLen -gt 0) { $bytes[$currentPos..($currentPos + $metaLen - 1)] } else { @() }
                    $currentPos += $metaLen

                    switch ($metaType) {
                        0x00 {
                            $ev.EventType = 'SequenceNumber'
                            $ev.Value     = if ($metaLen -ge 2) { ($metaData[0] -shl 8) -bor $metaData[1] } else { 0 }
                        }
                        0x01 { $ev.EventType = 'TextEvent';      $ev.Text = [System.Text.Encoding]::Latin1.GetString($metaData) }
                        0x02 { $ev.EventType = 'Copyright';      $ev.Text = [System.Text.Encoding]::Latin1.GetString($metaData) }
                        0x03 {
                            $trackName    = [System.Text.Encoding]::Latin1.GetString($metaData)
                            $ev.EventType = 'TrackName'
                            $ev.Text      = $trackName
                            $ev.TrackName = $trackName
                        }
                        0x04 {
                            $instrumentName    = [System.Text.Encoding]::Latin1.GetString($metaData)
                            $ev.EventType      = 'InstrumentName'
                            $ev.Text           = $instrumentName
                            $ev.InstrumentName = $instrumentName
                        }
                        0x05 { $ev.EventType = 'Lyrics';    $ev.Text = [System.Text.Encoding]::Latin1.GetString($metaData) }
                        0x06 { $ev.EventType = 'Marker';    $ev.Text = [System.Text.Encoding]::Latin1.GetString($metaData) }
                        0x07 { $ev.EventType = 'CuePoint';  $ev.Text = [System.Text.Encoding]::Latin1.GetString($metaData) }
                        0x20 { $ev.EventType = 'ChannelPrefix'; $ev.Channel = $metaData[0] }
                        0x21 { $ev.EventType = 'MidiPort';      $ev.Value   = $metaData[0] }
                        0x2F { $ev.EventType = 'EndOfTrack' }
                        0x51 {
                            $tempo            = ([uint32]$metaData[0] -shl 16) -bor ([uint32]$metaData[1] -shl 8) -bor [uint32]$metaData[2]
                            $ev.EventType     = 'SetTempo'
                            $ev.TempoMicroseconds = $tempo
                            $ev.BPM           = [math]::Round(60000000 / $tempo, 3)
                        }
                        0x54 {
                            $ev.EventType   = 'SMPTEOffset'
                            $ev.SMPTEOffset = [PSCustomObject]@{
                                Hours   = $metaData[0] -band 0x1F
                                Minutes = $metaData[1]
                                Seconds = $metaData[2]
                                Frames  = $metaData[3]
                                SubFrames = $metaData[4]
                                FrameRate = switch (($metaData[0] -band 0x60) -shr 5) { 0{24} 1{25} 2{29} 3{30} }
                            }
                        }
                        0x58 {
                            $ev.EventType                    = 'TimeSignature'
                            $ev.TimeSignatureNumerator       = $metaData[0]
                            $ev.TimeSignatureDenominator     = [math]::Pow(2, $metaData[1])
                            $ev.MetronomeClocks              = $metaData[2]
                            $ev.ThirtySecondNotesPerQuarter  = $metaData[3]
                        }
                        0x59 {
                            $sharps        = [int][sbyte]$metaData[0]
                            $mode          = if ($metaData[1] -eq 0) { 'major' } else { 'minor' }
                            $keyNameTable  = if ($mode -eq 'major') { $majorKeyNames } else { $minorKeyNames }
                            $ev.EventType               = 'KeySignature'
                            $ev.KeySignatureSharpsFlats = $sharps
                            $ev.KeySignatureMode        = $mode
                            $ev.KeySignatureName        = $keyNameTable[$sharps]
                        }
                        0x7F {
                            $ev.EventType = 'SequencerSpecific'
                            $ev.RawData   = $metaData
                        }
                        default {
                            $ev.EventType = "MetaEvent_0x$($metaType.ToString('X2'))"
                            $ev.RawData   = $metaData
                        }
                    }
                }
                # -------------------------------------------------------
                # SYSEX  (0xF0 / 0xF7)
                # -------------------------------------------------------
                elseif ($currentStatus -eq 0xF0 -or $currentStatus -eq 0xF7) {
                    $vlq        = & $ReadVLQ $bytes $currentPos
                    $sysexLen   = $vlq.Value
                    $currentPos = $vlq.NextPos
                    $ev.EventType = if ($currentStatus -eq 0xF0) { 'SysEx' } else { 'SysExContinuation' }
                    $ev.RawData   = if ($sysexLen -gt 0) { $bytes[$currentPos..($currentPos + $sysexLen - 1)] } else { @() }
                    $currentPos  += $sysexLen
                    $runningStatus = 0   # SysEx clears running status
                }
                # -------------------------------------------------------
                # MIDI CHANNEL EVENT  (0x80–0xEF)
                # -------------------------------------------------------
                else {
                    $eventType    = $currentStatus -band 0xF0
                    $eventChannel = $currentStatus -band 0x0F
                    $ev.Channel   = $eventChannel

                    switch ($eventType) {
                        0x80 {  # Note Off
                            $note = $bytes[$currentPos]; $currentPos++
                            $vel  = $bytes[$currentPos]; $currentPos++
                            $ev.EventType = 'NoteOff'
                            $ev.Note      = $note
                            $ev.NoteName  = $noteNames[$note % 12]
                            $ev.Octave    = [math]::Floor($note / 12) - 2
                            $ev.Velocity  = $vel
                        }
                        0x90 {  # Note On (velocity 0 = implicit Note Off)
                            $note = $bytes[$currentPos]; $currentPos++
                            $vel  = $bytes[$currentPos]; $currentPos++
                            $ev.EventType = if ($vel -eq 0) { 'NoteOff' } else { 'NoteOn' }
                            $ev.Note      = $note
                            $ev.NoteName  = $noteNames[$note % 12]
                            $ev.Octave    = [math]::Floor($note / 12) - 2
                            $ev.Velocity  = $vel
                        }
                        0xA0 {  # Polyphonic Key Pressure (Aftertouch)
                            $note = $bytes[$currentPos]; $currentPos++
                            $pres = $bytes[$currentPos]; $currentPos++
                            $ev.EventType = 'Aftertouch'
                            $ev.Note      = $note
                            $ev.NoteName  = $noteNames[$note % 12]
                            $ev.Octave    = [math]::Floor($note / 12) - 2
                            $ev.Value     = $pres
                        }
                        0xB0 {  # Control Change
                            $cc  = $bytes[$currentPos]; $currentPos++
                            $val = $bytes[$currentPos]; $currentPos++
                            $ev.EventType      = 'ControlChange'
                            $ev.Controller     = $cc
                            $ev.ControllerName = & $ControllerName $cc
                            $ev.Value          = $val
                        }
                        0xC0 {  # Program Change
                            $prog = $bytes[$currentPos]; $currentPos++
                            $ev.EventType = 'ProgramChange'
                            $ev.Program   = $prog
                            $ev.Value     = $prog
                        }
                        0xD0 {  # Channel Pressure
                            $pres = $bytes[$currentPos]; $currentPos++
                            $ev.EventType = 'ChannelPressure'
                            $ev.Value     = $pres
                        }
                        0xE0 {  # Pitch Bend
                            $lsb = $bytes[$currentPos]; $currentPos++
                            $msb = $bytes[$currentPos]; $currentPos++
                            # 14-bit value; centre = 8192
                            $raw = ($msb -shl 7) -bor $lsb
                            $ev.EventType = 'PitchBend'
                            $ev.PitchBend = $raw - 8192
                            $ev.Value     = $raw
                        }
                        default {
                            $ev.EventType = "Unknown_0x$($currentStatus.ToString('X2'))"
                        }
                    }
                }

                [PSCustomObject]$ev
            }
        }
    }
}
