function Start-PSMidiQueue {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Queue startup should not prompt for confirmation.')]
    param (
        [Parameter()]
        [Alias('BPM')]
        [BPM]$Tempo,

        [Parameter()]
        [ValidateRange(1, 64)]
        [int]$Beat = 4,

        [Parameter(Mandatory)]
        [WindowsMidiServices.MidiEndpointConnection]$Connection
    )

    begin {}

    process {}

    end {
        if ($script:MessageQueue.Count -eq 0 -and $script:RecurringQueueRules.Count -eq 0) {
            Write-Error 'No queue events have been added.'
            return
        }

        [int]$effectiveTicksPerQuarterNote = if ($script:QueueMetadata.TicksPerQuarterNote) {
            [int]$script:QueueMetadata.TicksPerQuarterNote
        }
        elseif ($PSBoundParameters.ContainsKey('Tempo')) {
            [int]$Tempo.TicksPerQuarterNote
        }
        else {
            [int]$script:QueueState.TicksPerQuarterNote
        }

        [BPM]$effectiveTempo = $null
        if ($script:QueueTempoMap.Count -gt 0) {
            [long]$firstTempoTick = ($script:QueueTempoMap.Keys | Sort-Object | Select-Object -First 1)
            [int]$tempoMicroseconds = [int]$script:QueueTempoMap[$firstTempoTick]
            [double]$tempoMilliseconds = [math]::Round($tempoMicroseconds / 1000.0, 3)
            $effectiveTempo = [BPM]::new($tempoMilliseconds, $effectiveTicksPerQuarterNote)
        }
        elseif ($PSBoundParameters.ContainsKey('Tempo')) {
            $effectiveTempo = $Tempo
        }
        else {
            Write-Warning 'No tempo parameter and no queue tempo map found. Defaulting to 120 BPM.'
            $effectiveTempo = [BPM]::new(120, $effectiveTicksPerQuarterNote)
        }

        if (-not (SetQueueTicksPerQuarterNote -TicksPerQuarterNote $effectiveTempo.TicksPerQuarterNote)) {
            return
        }

        $queueConnection = $Connection
        $existingJob = Get-Job -Name $script:QueuePlayThread -ErrorAction SilentlyContinue
        if ($existingJob) {
            if ($existingJob.State -eq 'Running' -or $existingJob.State -eq 'NotStarted') {
                Write-Error 'PSMidiQueue already started'
                return
            }

            $existingJob | Remove-Job
        }

        $script:QueueState.BeatCount = $Beat
        $script:QueueState.DefaultTempoMicroseconds = $effectiveTempo.TempoMicroseconds
        $script:QueueConnection = $Connection
        ResetQueueTransportState

        $null = Start-ThreadJob -Name $script:QueuePlayThread -ScriptBlock {
            $scheduledQueue = $using:MessageQueue
            $recurringQueueRules = $using:RecurringQueueRules
            $tempoMap = $using:QueueTempoMap
            $tempoContext = $using:effectiveTempo
            $beatCount = $using:Beat
            $connection = $using:queueConnection
            $queueState = $using:QueueState
            $queueSync = $using:QueueSync
            $queueStart = [datetime]::FromFileTime([Microsoft.Windows.Devices.Midi2.MidiClock]::Now)
            [long]$currentTick = 0
            $queueState.IsRunning = $true
            $queueState.BeatCount = $beatCount
            $queueState.TicksPerQuarterNote = $tempoContext.TicksPerQuarterNote
            $queueState.DefaultTempoMicroseconds = $tempoContext.TempoMicroseconds

            [double]$currentTempoMicroseconds = if ($tempoMap.ContainsKey(0L)) { $tempoMap[0L] } else { $tempoContext.TempoMicroseconds }
            [long]$lastAppliedTempoTick = -1L
            [datetime]$dueTime = $queueStart

            while ($true) {
                [long]$nextQueuedTick = [long]::MaxValue
                [bool]$hasRecurringRules = $false
                [System.Threading.Monitor]::Enter($queueSync)
                try {
                    foreach ($queuedTickKey in ($scheduledQueue.Keys | Sort-Object)) {
                        [long]$queuedTick = $queuedTickKey
                        if ($queuedTick -ge $currentTick) {
                            $nextQueuedTick = $queuedTick
                            break
                        }
                    }

                    $hasRecurringRules = $recurringQueueRules.Count -gt 0
                }
                finally {
                    [System.Threading.Monitor]::Exit($queueSync)
                }

                [long]$nextRecurringTick = if ($hasRecurringRules) { ([math]::Floor($currentTick / $tempoContext.TicksPerQuarterNote) + 1) * $tempoContext.TicksPerQuarterNote } else { [long]::MaxValue }
                [long]$nextScheduledTick = [math]::Min($nextQueuedTick, $nextRecurringTick)

                if ($nextScheduledTick -eq [long]::MaxValue) {
                    [System.Threading.Thread]::Sleep(5)
                    continue
                }

                [long]$timingCursorTick = $currentTick
                [long[]]$tempoChangeTicks = @()
                [System.Threading.Monitor]::Enter($queueSync)
                try {
                    $tempoChangeTicks = @($tempoMap.Keys | Where-Object { ([long]$_ -gt $lastAppliedTempoTick) -and ([long]$_ -le $nextScheduledTick) } | Sort-Object)
                }
                finally {
                    [System.Threading.Monitor]::Exit($queueSync)
                }

                foreach ($tempoChangeTick in $tempoChangeTicks) {
                    [long]$segmentTicks = $tempoChangeTick - $timingCursorTick
                    if ($segmentTicks -gt 0) {
                        $dueTime = $dueTime.AddTicks($tempoContext.TickDeltaToClockTicks($segmentTicks, $currentTempoMicroseconds))
                    }

                    $currentTempoMicroseconds = $tempoMap[$tempoChangeTick]
                    $lastAppliedTempoTick = $tempoChangeTick
                    $timingCursorTick = $tempoChangeTick
                }

                [long]$remainingTicks = $nextScheduledTick - $timingCursorTick
                if ($remainingTicks -gt 0) {
                    $dueTime = $dueTime.AddTicks($tempoContext.TickDeltaToClockTicks($remainingTicks, $currentTempoMicroseconds))
                }

                while ($true) {
                    $now = [datetime]::FromFileTime([Microsoft.Windows.Devices.Midi2.MidiClock]::Now)
                    if ($now -ge $dueTime) {
                        break
                    }

                    $remainingMilliseconds = ($dueTime - $now).TotalMilliseconds
                    [System.Threading.Thread]::Sleep([math]::Max([int][math]::Min($remainingMilliseconds, 5), 1))
                }

                if ($nextQueuedTick -eq $nextScheduledTick) {
                    [Microsoft.Windows.Devices.Midi2.MidiMessage64[]]$queuedMessages = @()
                    [System.Threading.Monitor]::Enter($queueSync)
                    try {
                        if ($scheduledQueue.ContainsKey($nextQueuedTick)) {
                            $queuedMessages = @($scheduledQueue[$nextQueuedTick])
                            $scheduledQueue.Remove($nextQueuedTick)
                        }
                    }
                    finally {
                        [System.Threading.Monitor]::Exit($queueSync)
                    }

                    $queuedMessages | Sort-Object -Property Word0 | ForEach-Object {
                        Send-MidiMessage -Connection $connection -Words $($_.Word0, $_.Word1)
                    }
                }

                if ($nextRecurringTick -eq $nextScheduledTick) {
                    [int]$currentBeat = (([math]::Floor($nextScheduledTick / $tempoContext.TicksPerQuarterNote)) % $beatCount) + 1
                    [object[]]$recurringRulesForBeat = @()
                    [System.Threading.Monitor]::Enter($queueSync)
                    try {
                        $recurringRulesForBeat = @($recurringQueueRules | Where-Object Beat -eq $currentBeat)
                    }
                    finally {
                        [System.Threading.Monitor]::Exit($queueSync)
                    }

                    $recurringRulesForBeat | ForEach-Object {
                        $_.Message | Sort-Object -Property Word0 | ForEach-Object {
                            Send-MidiMessage -Connection $connection -Words $($_.Word0, $_.Word1)
                        }
                    }
                }

                $currentTick = $nextScheduledTick
                $queueState.CurrentTick = $currentTick
                $queueState.TotalBeat = [math]::Floor($currentTick / $tempoContext.TicksPerQuarterNote) + 1
                $queueState.CurrentBeat = (($queueState.TotalBeat - 1) % $beatCount) + 1
                $queueState.Bar = [math]::Floor(($queueState.TotalBeat - 1) / $beatCount) + 1
            }

            $queueState.CurrentTick = 0L
            $queueState.CurrentBeat = 1
            $queueState.TotalBeat = 1
            $queueState.Bar = 1
            $queueState.IsRunning = $false
        }
    }
}
