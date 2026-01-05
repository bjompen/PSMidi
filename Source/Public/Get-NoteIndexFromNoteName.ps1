Function Get-NoteIndexFromNoteName {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [ValidatePattern('^[a-gA-G][#b]?(-?[1-2]|[0-8])$', ErrorMessage = 'Input must match pattern <note><octave>')]
        [string]$NoteName
    )

    [chord]::new($NoteName)
}