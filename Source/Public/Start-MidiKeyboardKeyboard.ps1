function Start-MidiKeyboardKeyboard {
    param (
        [Parameter(Mandatory)]
        [WindowsMidiServices.MidiEndpointConnection]$Connection
    )
    
    $null = Get-Job -Name "MidiKeyboardKeyboard*" -ErrorAction Stop | Stop-Job -ErrorAction SilentlyContinue
    $null = Get-Job -Name "MidiKeyboardKeyboard*" -ErrorAction Stop | Remove-Job -ErrorAction SilentlyContinue

    $null = Start-ThreadJob -Name "MidiKeyboardKeyboard$(Get-Random -Minimum 100 -Maximum 999)" -ScriptBlock {
        $eventHandlerAction = {
            Get-MidiMessageInfo $EventArgs.Words
        }

        $job = Register-ObjectEvent -SourceIdentifier "OnMessageReceivedHandler" -InputObject $connection -EventName "MessageReceived" -Action $eventHandlerAction

        do {
            $r = Receive-Job -Job $job
            if ($r.MessageTypeHasChannelField) {
                Write-Host $r.WordsHex
            }
        } until ($script:StopKeyboardKeyboard -eq $true)

        $script:StopKeyboardKeyboard = $false
    }
}