#Requires -Modules @{ ModuleName = 'WindowsMidiServices'; ModuleVersion = '0.0.1' }

$script:currentBeat = 1
$script:totalBeat = 1
$script:bar = 1

$script:MessageQueue = [System.Collections.Generic.Dictionary[int, Microsoft.Windows.Devices.Midi2.MidiMessage64[]]]::new(10000)
$script:MessageEvery = [System.Collections.Generic.Dictionary[int, Microsoft.Windows.Devices.Midi2.MidiMessage64[]]]::new(10)

$script:QueuePlayThread = (New-Guid).Guid

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

# # import private functions
# foreach ($file in (Get-ChildItem "$PSScriptRoot\Private\*.ps1")) {
#     try {
#         Write-Verbose "Importing $($file.FullName)"
#         . $file.FullName
#     }
#     catch {
#         Write-Error "Failed to import '$($file.FullName)'. $_"
#     }
# }

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
