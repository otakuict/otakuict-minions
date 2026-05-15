[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$AgentId,

    [ValidateSet("idle", "planning", "working", "waiting", "blocked", "reviewing", "done", "error", "stale")]
    [string]$Status,

    [string]$Task,
    [int]$Progress = -1,
    [string]$NextAction,
    [string]$Blocker,
    [switch]$ClearBlocker,
    [string]$Message,
    [switch]$PassThru
)

. "$PSScriptRoot\agent-monitor-lib.ps1"

$hasUpdate =
    $PSBoundParameters.ContainsKey("Status") -or
    $PSBoundParameters.ContainsKey("Task") -or
    $PSBoundParameters.ContainsKey("NextAction") -or
    $PSBoundParameters.ContainsKey("Blocker") -or
    $PSBoundParameters.ContainsKey("ClearBlocker") -or
    $Progress -ge 0

if (-not $hasUpdate) {
    Write-Error "Provide at least one update field: -Status, -Task, -Progress, -NextAction, -Blocker, or -ClearBlocker."
    exit 1
}

$updateArgs = @{
    AgentId = $AgentId
}

if ($PSBoundParameters.ContainsKey("Status")) {
    $updateArgs.Status = $Status
}
if ($PSBoundParameters.ContainsKey("Task")) {
    $updateArgs.Task = $Task
}
if ($Progress -ge 0) {
    $updateArgs.Progress = $Progress
}
if ($PSBoundParameters.ContainsKey("NextAction")) {
    $updateArgs.NextAction = $NextAction
}
if ($PSBoundParameters.ContainsKey("Blocker")) {
    $updateArgs.Blocker = $Blocker
}
if ($ClearBlocker) {
    $updateArgs.ClearBlocker = $true
}
if ($PSBoundParameters.ContainsKey("Message")) {
    $updateArgs.Message = $Message
}

$agent = Update-AgentStatus @updateArgs

if ($PassThru) {
    $agent | ConvertTo-Json -Depth 5
}
else {
    $effectiveStatus = Get-AgentEffectiveStatus -Agent $agent
    Write-Host ("Updated {0} -> {1}" -f $agent.agentId, $effectiveStatus)
    Write-Host ("Task: {0}" -f $agent.currentTask)
}
