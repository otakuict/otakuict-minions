[CmdletBinding()]
param(
    [string]$AgentId = "company_lead",
    [int]$RefreshSeconds = 2,
    [int]$StaleMinutes = 15,
    [int]$Events = 8,
    [switch]$Once
)

. "$PSScriptRoot\agent-monitor-lib.ps1"
Initialize-AiMonitorRuntime

$lastFrame = $null

try {
    do {
        $state = Read-AgentState
        $agent = Get-AgentFromState -State $state -AgentId $AgentId
        $lines = @()

        $lines += Get-MonitorHeaderLines -Title ("AI Agent - {0}" -f $AgentId)

        if (-not $agent) {
            $lines += ("Agent '{0}' was not found." -f $AgentId)
            $lines += ""
            $lines += "Available agents:"
            foreach ($candidate in @($state.agents)) {
                $lines += ("- {0}" -f $candidate.agentId)
            }
        }
        else {
            $lines += Get-AgentBlockLines -Agent $agent -StaleMinutes $StaleMinutes
            $lines += (Format-Ansi -Text "Recent events" -Code "1;37m")
            $lines += (Format-Ansi -Text ("-" * 72) -Code "90m")

            $recentEvents = Read-AgentEventsTail -Tail 100 |
                Where-Object { $_.agentId -eq $AgentId } |
                Select-Object -Last $Events

            if (-not $recentEvents) {
                $lines += "No recent events for this agent."
            }
            else {
                foreach ($event in $recentEvents) {
                    $lines += (Format-AgentEventLine -Event $event)
                }
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
