function SendVirtualKeyboard {
    param(
        [Parameter(Mandatory)]
        [ValidateRange(1, 127)]
        $IntIndex
    )
    [array]$keyList = $script:AlphabetKeys.Where({$_.IntIndex -eq $IntIndex}).VKEYList -split ','

    if ($keyList.Count -gt 1) {
        $null = [WindowsInput.InputSimulator]::new().Keyboard.KeyDown($keyList[0])
        1..($keyList.Count - 1) | ForEach-Object {
            $null = [WindowsInput.InputSimulator]::new().Keyboard.KeyPress($keyList[$_])
        }
        $null = [WindowsInput.InputSimulator]::new().Keyboard.KeyUp($keyList[0])
    }
    else {
        $null = [WindowsInput.InputSimulator]::new().Keyboard.KeyPress($keyList[0])
    }
}