function Start-PSMidiQueue {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Queue startup should not prompt for confirmation.')]
    param (
        [Parameter(Mandatory)]
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
        if (-not (SetQueueTicksPerQuarterNote -TicksPerQuarterNote $Tempo.TicksPerQuarterNote)) {
            return
        }

        if ($script:MessageQueue.Count -eq 0 -and $script:RecurringQueueRules.Count -eq 0) {
            Write-Error 'No queue events have been added.'
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
        $script:QueueState.DefaultTempoMicroseconds = $Tempo.TempoMicroseconds
        $script:QueueConnection = $Connection
        ResetQueueTransportState

        $effectiveTempoMap = [System.Collections.Generic.SortedDictionary[long, int]]::new()
        $effectiveTempoMap.Add(0, $Tempo.TempoMicroseconds)
        foreach ($tempoTick in $script:QueueTempoMap.Keys) {
            if ($effectiveTempoMap.ContainsKey($tempoTick)) {
                $effectiveTempoMap[$tempoTick] = $script:QueueTempoMap[$tempoTick]
            }
            else {
                $effectiveTempoMap.Add($tempoTick, $script:QueueTempoMap[$tempoTick])
            }
        }

        $null = Start-ThreadJob -Name $script:QueuePlayThread -ScriptBlock {
            $scheduledTicks = @($using:MessageQueue.Keys)
            $scheduledQueue = $using:MessageQueue
            $recurringQueueRules = @($using:RecurringQueueRules)
            $tempoMap = $using:effectiveTempoMap
            $tempoContext = $using:Tempo
            $beatCount = $using:Beat
            $connection = $using:queueConnection
            $queueState = $using:QueueState
            $queueStart = [datetime]::FromFileTime([Microsoft.Windows.Devices.Midi2.MidiClock]::Now)

            [int]$queueTickIndex = 0
            [long]$nextRecurringTick = if ($recurringQueueRules.Count -gt 0) { $tempoContext.BeatNumberToTick(1) } else { [long]::MaxValue }
            [long]$currentTick = 0
            [long]$currentBeatNumber = 1
            $queueState.IsRunning = $true
            $queueState.BeatCount = $beatCount
            $queueState.TicksPerQuarterNote = $tempoContext.TicksPerQuarterNote
            $queueState.DefaultTempoMicroseconds = $tempoContext.TempoMicroseconds

            $tempoTicks = @($tempoMap.Keys)
            [int]$tempoIndex = 0
            [double]$currentTempoMicroseconds = $tempoMap[0]
            [datetime]$dueTime = $queueStart

            while ($queueTickIndex -lt $scheduledTicks.Count -or $nextRecurringTick -ne [long]::MaxValue) {
                [long]$nextQueuedTick = if ($queueTickIndex -lt $scheduledTicks.Count) { $scheduledTicks[$queueTickIndex] } else { [long]::MaxValue }
                [long]$nextScheduledTick = [math]::Min($nextQueuedTick, $nextRecurringTick)

                if ($nextScheduledTick -eq [long]::MaxValue) {
                    break
                }

                [long]$timingCursorTick = $currentTick
                while ($tempoIndex + 1 -lt $tempoTicks.Count -and $tempoTicks[$tempoIndex + 1] -le $nextScheduledTick) {
                    [long]$tempoChangeTick = $tempoTicks[$tempoIndex + 1]
                    [long]$segmentTicks = $tempoChangeTick - $timingCursorTick
                    if ($segmentTicks -gt 0) {
                        $dueTime = $dueTime.AddTicks($tempoContext.TickDeltaToClockTicks($segmentTicks, $currentTempoMicroseconds))
                    }

                    $tempoIndex++
                    $currentTempoMicroseconds = $tempoMap[$tempoTicks[$tempoIndex]]
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
                    $scheduledQueue[$nextQueuedTick] | Sort-Object -Property Word0 | ForEach-Object {
                        Send-MidiMessage -Connection $connection -Words $($_.Word0, $_.Word1)
                    }
                    $queueTickIndex++
                }

                if ($nextRecurringTick -eq $nextScheduledTick) {
                    [int]$currentBeat = (($currentBeatNumber - 1) % $beatCount) + 1
                    $recurringQueueRules | Where-Object Beat -eq $currentBeat | ForEach-Object {
                        $_.Message | Sort-Object -Property Word0 | ForEach-Object {
                            Send-MidiMessage -Connection $connection -Words $($_.Word0, $_.Word1)
                        }
                    }

                    $currentBeatNumber++
                    $nextRecurringTick += $tempoContext.TicksPerQuarterNote
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
