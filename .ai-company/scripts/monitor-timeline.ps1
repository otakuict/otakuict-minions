[CmdletBinding()]
param(
    [int]$Tail = 20,
    [int]$RefreshSeconds = 2,
    [switch]$Once
)

. "$PSScriptRoot\agent-monitor-lib.ps1"
Initialize-AiMonitorRuntime

$lastFrame = $null

try {
    do {
        $lines = @()
        $lines += Get-MonitorHeaderLines -Title "AI Company Monitor - Timeline"
        $lines += ("Events file: {0}" -f (Get-AgentEventsPath))
        $lines += ("Tail: {0} | Refresh: {1}s | Ctrl+C to stop" -f $Tail, $RefreshSeconds)
        $lines += ""

        $events = Read-AgentEventsTail -Tail $Tail
        if (-not $events) {
            $lines += "No events yet."
        }
        else {
            foreach ($event in $events) {
                $line = Format-AgentEventLine -Event $event
                $status = if ([string]::IsNullOrWhiteSpace($event.status)) { "idle" } else { $event.status }
                $lines += (Format-Ansi -Text $line -Code (Get-StatusColorCode -Status $status))
            }
        }

        $lastFrame = Write-MonitorFrame -Lines $lines -PreviousFrame $lastFrame -Force:$Once

        if ($Once) {
            break
        }

        Start-Sleep -Seconds $RefreshSeconds
    } while ($true)
}
finally {
    Restore-MonitorTerminal
}
