[CmdletBinding()]
param(
    [int]$RefreshSeconds = 2,
    [int]$StaleMinutes = 15,
    [int]$MaxColumns = 5,
    [int]$CardWidth = 34,
    [string]$DetailAgentId = "auto",
    [int]$DetailEvents = 5,
    [switch]$HideDetails,
    [switch]$Once
)

. "$PSScriptRoot\agent-monitor-lib.ps1"
Initialize-AiMonitorRuntime

$lastFrame = $null

try {
    do {
        $state = Read-AgentState
        $agentCount = @($state.agents).Count
        $lines = @()

        $lines += Get-MonitorHeaderLines -Title "AI Company Monitor - Agents"
        $lines += ("Agents: {0} | Max columns: {1} | Card width: {2} | Refresh: {3}s | Ctrl+C to stop" -f $agentCount, $MaxColumns, $CardWidth, $RefreshSeconds)
        $lines += ("Updated: {0}" -f $state.updatedAt)
        $lines += ""
        $lines += Get-AgentGridLines -Agents $state.agents -MaxColumns $MaxColumns -CardWidth $CardWidth -StaleMinutes $StaleMinutes

        if (-not $HideDetails) {
            $detailAgent = Get-DetailAgent -Agents $state.agents -DetailAgentId $DetailAgentId
            if ($detailAgent) {
                $lines += ""
                $detailWidth = Get-MonitorContentWidth
                $lines += Get-AgentDetailPanelLines -Agent $detailAgent -Width $detailWidth -StaleMinutes $StaleMinutes -Events $DetailEvents
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
