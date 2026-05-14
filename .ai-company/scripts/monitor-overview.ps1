[CmdletBinding()]
param(
    [int]$RefreshSeconds = 2,
    [int]$StaleMinutes = 15,
    [switch]$Once
)

. "$PSScriptRoot\agent-monitor-lib.ps1"
Initialize-AiMonitorRuntime

$lastFrame = $null

try {
    do {
        $state = Read-AgentState
        $lines = @()

        $lines += Get-MonitorHeaderLines -Title "AI Company Monitor - Overview"
        $lines += ("Runtime: {0}" -f (Get-AiRuntimePath))
        $lines += ("Updated: {0}" -f $state.updatedAt)
        $lines += ("Refresh: {0}s | Stale threshold: {1}m | Ctrl+C to stop" -f $RefreshSeconds, $StaleMinutes)
        $lines += ""

        foreach ($agent in @($state.agents)) {
            $lines += Get-AgentBlockLines -Agent $agent -StaleMinutes $StaleMinutes
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
