#Requires -Modules @{ ModuleName = 'WindowsMidiServices'; ModuleVersion = '0.0.1' }

$script:currentBeat = 1
$script:totalBeat = 1
$script:bar = 1

$script:MessageQueue = [System.Collections.Generic.SortedDictionary[long, Microsoft.Windows.Devices.Midi2.MidiMessage64[]]]::new()
$script:RecurringQueueRules = [System.Collections.Generic.List[object]]::new()
$script:QueueTempoMap = [System.Collections.Generic.SortedDictionary[long, int]]::new()
$script:QueueAllNoteOffMessages = [System.Collections.Generic.Dictionary[string, Microsoft.Windows.Devices.Midi2.MidiMessage64]]::new()
$script:QueueMetadata = [ordered]@{
    LastSourcePath      = $null
    TicksPerQuarterNote = $null
    TempoEventCount     = 0
    ScheduledEventCount = 0
    DurationTicks       = 0
}
$script:QueueState = [hashtable]::Synchronized(@{
    CurrentTick             = 0L
    CurrentBeat             = 1
    TotalBeat               = 1
    Bar                     = 1
    BeatCount               = 4
    TicksPerQuarterNote     = 960
    DefaultTempoMicroseconds = 500000
    IsRunning               = $false
})

$script:QueuePlayThread = (New-Guid).Guid
$script:QueueConnection = $null
$script:QueueSync = [System.Object]::new()

# WindowsInput borrowed and compiled from https://github.com/michaelnoonan/inputsimulator
$null = Add-Type -Path "$PSScriptRoot\Resources\WindowsInput.dll"
$script:AlphabetKeys = Get-Content $PSScriptRoot\Resources\KeyMap_sv-SE.csv | ConvertFrom-Csv -Delimiter ';'

# import classes
foreach ($file in (Get-ChildItem "$PSScriptRoot\Classes\*.ps1")) {
    try {
        Write-Verbose "Importing $($file.FullName)"
        . $file.FullName
    }
    catch {
        Write-Error "Failed to import '$($file.FullName)'. $_"
    }
}

# import private functions
foreach ($file in (Get-ChildItem "$PSScriptRoot\Private\*.ps1")) {
    try {
        Write-Verbose "Importing $($file.FullName)"
        . $file.FullName
    }
    catch {
        Write-Error "Failed to import '$($file.FullName)'. $_"
    }
}

# import public functions
foreach ($file in (Get-ChildItem "$PSScriptRoot\Public\*.ps1")) {
    try {
        Write-Verbose "Importing $($file.FullName)"
        . $file.FullName
    }
    catch {
        Write-Error "Failed to import '$($file.FullName)'. $_"
    }
}
