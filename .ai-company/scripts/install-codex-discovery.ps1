param(
    [switch]$Force,
    [string]$TargetRoot
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root = Resolve-Path (Join-Path $ScriptDir "..\..")

if ([string]::IsNullOrWhiteSpace($TargetRoot)) {
    $InstallRoot = $Root
} else {
    if (-not (Test-Path $TargetRoot)) {
        New-Item -ItemType Directory -Force -Path $TargetRoot | Out-Null
    }
    $InstallRoot = Resolve-Path $TargetRoot
}

$SkillMap = @(
    @{ Source = "company-lead"; Target = "ai-company-lead" },
    @{ Source = "product-manager"; Target = "ai-product-manager" },
    @{ Source = "developer"; Target = "ai-developer" },
    @{ Source = "data-engineer"; Target = "ai-data-engineer" },
    @{ Source = "qa-reviewer"; Target = "ai-qa-reviewer" },
    @{ Source = "marketing-strategist"; Target = "ai-marketing-strategist" }
)

$SkillSourceRoot = Join-Path $Root ".ai-company\skills"
$SkillTargetRoot = Join-Path $InstallRoot ".agents\skills"
$AgentSourceRoot = Join-Path $Root ".ai-company\codex-discovery\agents"
$AgentTargetRoot = Join-Path $InstallRoot ".codex\agents"
$ConfigSource = Join-Path $Root ".ai-company\codex-discovery\config.toml"
$ConfigTarget = Join-Path $InstallRoot ".codex\config.toml"

New-Item -ItemType Directory -Force -Path $SkillTargetRoot | Out-Null
New-Item -ItemType Directory -Force -Path $AgentTargetRoot | Out-Null

foreach ($Item in $SkillMap) {
    $Source = Join-Path $SkillSourceRoot $Item.Source
    $Target = Join-Path $SkillTargetRoot $Item.Target

    if (-not (Test-Path $Source)) {
        throw "Missing skill source: $Source"
    }

    if ((Test-Path $Target) -and -not $Force) {
        Write-Warning "Skill target exists, skipping: $Target. Use -Force to overwrite."
        continue
    }

    New-Item -ItemType Directory -Force -Path $Target | Out-Null
    Copy-Item -Path (Join-Path $Source "*") -Destination $Target -Recurse -Force
    Write-Host "Installed skill: $($Item.Target)"
}

if (Test-Path $AgentSourceRoot) {
    Copy-Item -Path (Join-Path $AgentSourceRoot "*.toml") -Destination $AgentTargetRoot -Force
    Write-Host "Installed custom agent templates."
}

if (Test-Path $ConfigSource) {
    if ((Test-Path $ConfigTarget) -and -not $Force) {
        Write-Warning ".codex\config.toml already exists. Merge [agents] settings manually or rerun with -Force."
    } else {
        Copy-Item -LiteralPath $ConfigSource -Destination $ConfigTarget -Force
        Write-Host "Installed .codex config."
    }
}

Write-Host "Codex discovery install complete."
