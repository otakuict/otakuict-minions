[CmdletBinding()]
param(
    [switch]$UseCurrentWindow,
    [switch]$PrintCommand,
    [switch]$IncludeTimeline,
    [switch]$SplitPanes,
    [string]$Shell
)

. "$PSScriptRoot\agent-monitor-lib.ps1"
Initialize-AiMonitorRuntime

if ([string]::IsNullOrWhiteSpace($Shell)) {
    if (Get-Command pwsh.exe -ErrorAction SilentlyContinue) {
        $Shell = "pwsh.exe"
    }
    else {
        $Shell = "powershell.exe"
    }
}

function New-ShellArgs {
    param(
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [string[]]$ExtraArgs = @()
    )

    return @(
        $Shell,
        "-NoLogo",
        "-NoProfile",
        "-NoExit",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        $ScriptPath
    ) + $ExtraArgs
}

function Join-DisplayCommand {
    param(
        [Parameter(Mandatory = $true)][string]$Exe,
        [Parameter(Mandatory = $true)][string[]]$Args
    )

    $quoted = foreach ($arg in $Args) {
        if ($arg -eq ";") {
            "``;"
        }
        elseif ($arg -match '[\s"]') {
            '"' + ($arg -replace '"', '\"') + '"'
        }
        else {
            $arg
        }
    }

    return ("{0} {1}" -f $Exe, ($quoted -join " "))
}

$agentScript = Join-Path $PSScriptRoot "monitor-agent.ps1"
$gridScript = Join-Path $PSScriptRoot "monitor-grid.ps1"
$timelineScript = Join-Path $PSScriptRoot "monitor-timeline.ps1"
$windowTarget = if ($UseCurrentWindow) { "0" } else { "new" }

$wtArgs = @(
    "--window", $windowTarget,
    "--size", "185,45",
    "new-tab", "--title", "AI Agents"
) + (New-ShellArgs -ScriptPath $gridScript -ExtraArgs @("-MaxColumns", "5", "-CardWidth", "34"))

if ($IncludeTimeline -and -not $SplitPanes) {
    $wtArgs += @(
        ";",
        "split-pane", "--horizontal", "--size", "0.25", "--title", "Timeline"
    ) + (New-ShellArgs -ScriptPath $timelineScript -ExtraArgs @("-Tail", "20"))
}

if ($SplitPanes) {
$agentPanes = @(
    @{ Title = "Company Lead"; AgentId = "company_lead"; Split = $null; Size = $null },
    @{ Title = "Product Manager"; AgentId = "product_manager"; Split = "--horizontal"; Size = "0.50" },
    @{ Title = "Developer"; AgentId = "software_developer"; Split = "--vertical"; Size = "0.50" },
    @{ Title = "QA Reviewer"; AgentId = "qa_reviewer"; Split = "--vertical"; Size = "0.50" },
    @{ Title = "Data Engineer"; AgentId = "data_engineer"; Split = "--horizontal"; Size = "0.50" },
    @{ Title = "Marketing"; AgentId = "marketing_strategist"; Split = "--vertical"; Size = "0.50" }
)

$firstPane = $agentPanes[0]
$wtArgs = @(
    "--window", $windowTarget,
    "--size", "185,45",
    "new-tab", "--title", $firstPane.Title
) + (New-ShellArgs -ScriptPath $agentScript -ExtraArgs @("-AgentId", $firstPane.AgentId))

foreach ($pane in $agentPanes | Select-Object -Skip 1) {
    $wtArgs += @(
        ";",
        "split-pane", $pane.Split, "--size", $pane.Size, "--title", $pane.Title
    ) + (New-ShellArgs -ScriptPath $agentScript -ExtraArgs @("-AgentId", $pane.AgentId))
}

if ($IncludeTimeline) {
    $wtArgs += @(
        ";",
        "split-pane", "--vertical", "--size", "0.35", "--title", "Timeline"
    ) + (New-ShellArgs -ScriptPath $timelineScript -ExtraArgs @("-Tail", "20"))
}
}

if ($PrintCommand) {
    Write-Host (Join-DisplayCommand -Exe "wt.exe" -Args $wtArgs)
    exit 0
}

if (-not (Get-Command wt.exe -ErrorAction SilentlyContinue)) {
    Write-Error "Windows Terminal CLI 'wt.exe' was not found. Install Windows Terminal or run with -PrintCommand to inspect the generated command."
    exit 1
}

& wt.exe @wtArgs
