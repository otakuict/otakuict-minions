Set-StrictMode -Version 2.0

$script:AiMonitorStatuses = @(
    "idle",
    "planning",
    "working",
    "waiting",
    "blocked",
    "reviewing",
    "done",
    "error",
    "stale"
)

$script:MonitorScreenInitialized = $false

function Get-AiCompanyRoot {
    return (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
}

function Get-AiRuntimePath {
    return Join-Path (Get-AiCompanyRoot) "runtime"
}

function Get-AgentStatePath {
    return Join-Path (Get-AiRuntimePath) "agent-state.json"
}

function Get-AgentEventsPath {
    return Join-Path (Get-AiRuntimePath) "agent-events.jsonl"
}

function Get-AgentSessionsPath {
    return Join-Path (Get-AiRuntimePath) "sessions.json"
}

function Get-IsoNow {
    return (Get-Date).ToString("o")
}

function New-AgentRecord {
    param(
        [Parameter(Mandatory = $true)][string]$AgentId,
        [Parameter(Mandatory = $true)][string]$Role,
        [Parameter(Mandatory = $true)][string]$DisplayName,
        [Parameter(Mandatory = $true)][string]$CurrentTask,
        [Parameter(Mandatory = $true)][string]$NextAction
    )

    return [ordered]@{
        agentId           = $AgentId
        role              = $Role
        displayName       = $DisplayName
        status            = "idle"
        currentTask       = $CurrentTask
        progress          = 0
        blocker           = $null
        lastUpdated       = $null
        nextAction        = $NextAction
        staleAfterMinutes = 15
    }
}

function Get-DefaultAgentRecords {
    return @(
        (New-AgentRecord -AgentId "company_lead" -Role "Company Lead" -DisplayName "Company Lead" -CurrentTask "Ready to coordinate AI company work" -NextAction "Await assignment"),
        (New-AgentRecord -AgentId "product_manager" -Role "Product Manager" -DisplayName "Product Manager" -CurrentTask "Ready to clarify scope and acceptance criteria" -NextAction "Await product task"),
        (New-AgentRecord -AgentId "software_developer" -Role "Software Developer" -DisplayName "Developer" -CurrentTask "Ready to implement scoped changes" -NextAction "Await implementation task"),
        (New-AgentRecord -AgentId "qa_reviewer" -Role "QA Reviewer" -DisplayName "QA Reviewer" -CurrentTask "Ready to review outputs and risks" -NextAction "Await review task"),
        (New-AgentRecord -AgentId "data_engineer" -Role "Data Engineer" -DisplayName "Data Engineer" -CurrentTask "Ready to inspect data, schemas, and metrics" -NextAction "Await data task"),
        (New-AgentRecord -AgentId "marketing_strategist" -Role "Marketing Strategist" -DisplayName "Marketing" -CurrentTask "Ready to work on positioning and launch assets" -NextAction "Await marketing task")
    )
}

function Initialize-AiMonitorRuntime {
    $runtimePath = Get-AiRuntimePath
    if (-not (Test-Path -LiteralPath $runtimePath)) {
        New-Item -ItemType Directory -Path $runtimePath | Out-Null
    }

    $statePath = Get-AgentStatePath
    if (-not (Test-Path -LiteralPath $statePath)) {
        $state = [ordered]@{
            version   = 1
            updatedAt = Get-IsoNow
            agents    = Get-DefaultAgentRecords
        }
        $state | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $statePath -Encoding UTF8
    }

    $eventsPath = Get-AgentEventsPath
    if (-not (Test-Path -LiteralPath $eventsPath)) {
        $event = [ordered]@{
            timestamp = Get-IsoNow
            agentId   = "system"
            status    = "done"
            task      = "Initialize monitor runtime"
            message   = "AI agent monitor runtime initialized."
        }
        $event | ConvertTo-Json -Compress -Depth 5 | Set-Content -LiteralPath $eventsPath -Encoding UTF8
    }

    $sessionsPath = Get-AgentSessionsPath
    if (-not (Test-Path -LiteralPath $sessionsPath)) {
        $sessions = [ordered]@{
            version   = 1
            updatedAt = Get-IsoNow
            terminal  = "Windows Terminal"
            layout    = "multipane"
            sessions  = @()
        }
        $sessions | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $sessionsPath -Encoding UTF8
    }
}

function Read-AgentState {
    Initialize-AiMonitorRuntime
    $statePath = Get-AgentStatePath
    return Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
}

function Set-JsonProperty {
    param(
        [Parameter(Mandatory = $true)]$Object,
        [Parameter(Mandatory = $true)][string]$Name,
        $Value
    )

    if ($Object.PSObject.Properties.Name -contains $Name) {
        $Object.$Name = $Value
    }
    else {
        $Object | Add-Member -MemberType NoteProperty -Name $Name -Value $Value
    }
}

function Write-AgentState {
    param([Parameter(Mandatory = $true)]$State)

    Set-JsonProperty -Object $State -Name "updatedAt" -Value (Get-IsoNow)
    $State | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Get-AgentStatePath) -Encoding UTF8
}

function Get-AgentFromState {
    param(
        [Parameter(Mandatory = $true)]$State,
        [Parameter(Mandatory = $true)][string]$AgentId
    )

    return @($State.agents) | Where-Object { $_.agentId -eq $AgentId } | Select-Object -First 1
}

function New-AdHocAgentRecord {
    param([Parameter(Mandatory = $true)][string]$AgentId)

    $displayName = ($AgentId -replace "_", " ")
    $displayName = (Get-Culture).TextInfo.ToTitleCase($displayName)

    return [pscustomobject]@{
        agentId           = $AgentId
        role              = $displayName
        displayName       = $displayName
        status            = "idle"
        currentTask       = "Ready"
        progress          = 0
        blocker           = $null
        lastUpdated       = $null
        nextAction        = "Await assignment"
        staleAfterMinutes = 15
    }
}

function Add-AgentEvent {
    param(
        [Parameter(Mandatory = $true)][string]$AgentId,
        [Parameter(Mandatory = $true)][string]$Status,
        [string]$Task,
        [string]$Message
    )

    Initialize-AiMonitorRuntime
    $event = [ordered]@{
        timestamp = Get-IsoNow
        agentId   = $AgentId
        status    = $Status
        task      = $Task
        message   = $Message
    }

    $event | ConvertTo-Json -Compress -Depth 5 | Add-Content -LiteralPath (Get-AgentEventsPath) -Encoding UTF8
}

function Update-AgentStatus {
    param(
        [Parameter(Mandatory = $true)][string]$AgentId,
        [ValidateSet("idle", "planning", "working", "waiting", "blocked", "reviewing", "done", "error", "stale")]
        [string]$Status,
        [string]$Task,
        [int]$Progress = -1,
        [string]$NextAction,
        [string]$Blocker,
        [switch]$ClearBlocker,
        [string]$Message
    )

    $state = Read-AgentState
    $agent = Get-AgentFromState -State $state -AgentId $AgentId

    if (-not $agent) {
        $agent = New-AdHocAgentRecord -AgentId $AgentId
        $agents = @($state.agents) + $agent
        Set-JsonProperty -Object $state -Name "agents" -Value $agents
    }

    if ($PSBoundParameters.ContainsKey("Status") -and -not [string]::IsNullOrWhiteSpace($Status)) {
        Set-JsonProperty -Object $agent -Name "status" -Value $Status
    }

    if ($PSBoundParameters.ContainsKey("Task")) {
        Set-JsonProperty -Object $agent -Name "currentTask" -Value $Task
    }

    if ($Progress -ge 0) {
        $clampedProgress = [Math]::Min(100, [Math]::Max(0, $Progress))
        Set-JsonProperty -Object $agent -Name "progress" -Value $clampedProgress
    }

    if ($PSBoundParameters.ContainsKey("NextAction")) {
        Set-JsonProperty -Object $agent -Name "nextAction" -Value $NextAction
    }

    if ($PSBoundParameters.ContainsKey("Blocker")) {
        Set-JsonProperty -Object $agent -Name "blocker" -Value $Blocker
    }

    if ($ClearBlocker -or (($PSBoundParameters.ContainsKey("Status")) -and $Status -ne "blocked")) {
        Set-JsonProperty -Object $agent -Name "blocker" -Value $null
    }

    Set-JsonProperty -Object $agent -Name "lastUpdated" -Value (Get-IsoNow)
    Write-AgentState -State $state

    $eventStatus = $agent.status
    $eventTask = $agent.currentTask
    if ([string]::IsNullOrWhiteSpace($Message)) {
        $Message = "Status updated."
    }
    Add-AgentEvent -AgentId $AgentId -Status $eventStatus -Task $eventTask -Message $Message

    return $agent
}

function Read-AgentEventsTail {
    param([int]$Tail = 20)

    Initialize-AiMonitorRuntime
    $eventsPath = Get-AgentEventsPath
    if (-not (Test-Path -LiteralPath $eventsPath)) {
        return @()
    }

    $lines = Get-Content -LiteralPath $eventsPath -Tail $Tail
    $events = @()
    foreach ($line in $lines) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }
        try {
            $events += ($line | ConvertFrom-Json)
        }
        catch {
            $events += [pscustomobject]@{
                timestamp = ""
                agentId   = "log"
                status    = "error"
                task      = "Unparseable event"
                message   = $line
            }
        }
    }

    return $events
}

function Get-Esc {
    return [char]27
}

function Format-Ansi {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Code
    )

    if ($env:NO_COLOR) {
        return $Text
    }

    $esc = Get-Esc
    return "$esc[$Code$Text$esc[0m"
}

function Get-StatusColorCode {
    param([string]$Status)

    switch ($Status) {
        "idle" { return "90m" }
        "planning" { return "36m" }
        "working" { return "32m" }
        "waiting" { return "33m" }
        "blocked" { return "31m" }
        "reviewing" { return "35m" }
        "done" { return "92m" }
        "error" { return "91m" }
        "stale" { return "93m" }
        default { return "37m" }
    }
}

function Get-AgentEffectiveStatus {
    param(
        [Parameter(Mandatory = $true)]$Agent,
        [int]$DefaultStaleMinutes = 15
    )

    if (Test-AgentStale -Agent $Agent -DefaultStaleMinutes $DefaultStaleMinutes) {
        return "stale"
    }

    return $Agent.status
}

function Format-StatusBadge {
    param([string]$Status)

    $label = (" {0} " -f $Status.ToUpperInvariant())
    return Format-Ansi -Text $label -Code (Get-StatusColorCode -Status $Status)
}

function Get-AgentAgeLabel {
    param([string]$LastUpdated)

    if ([string]::IsNullOrWhiteSpace($LastUpdated)) {
        return "never"
    }

    try {
        $updated = [datetimeoffset]::Parse($LastUpdated)
        $delta = [datetimeoffset]::Now - $updated
        if ($delta.TotalSeconds -lt 60) {
            return "just now"
        }
        if ($delta.TotalMinutes -lt 60) {
            return ("{0}m ago" -f [Math]::Max(0, [int]$delta.TotalMinutes))
        }
        if ($delta.TotalHours -lt 24) {
            return ("{0}h ago" -f [Math]::Max(0, [int]$delta.TotalHours))
        }
        return ("{0}d ago" -f [Math]::Max(0, [int]$delta.TotalDays))
    }
    catch {
        return "unknown"
    }
}

function Test-AgentStale {
    param(
        [Parameter(Mandatory = $true)]$Agent,
        [int]$DefaultStaleMinutes = 15
    )

    if ([string]::IsNullOrWhiteSpace($Agent.lastUpdated)) {
        return $false
    }

    if (@("idle", "done", "error") -contains $Agent.status) {
        return $false
    }

    $limit = $DefaultStaleMinutes
    if ($Agent.PSObject.Properties.Name -contains "staleAfterMinutes" -and $Agent.staleAfterMinutes) {
        $limit = [int]$Agent.staleAfterMinutes
    }

    try {
        $updated = [datetimeoffset]::Parse($Agent.lastUpdated)
        return (([datetimeoffset]::Now - $updated).TotalMinutes -gt $limit)
    }
    catch {
        return $false
    }
}

function Format-ProgressBar {
    param([int]$Progress)

    $clampedProgress = [Math]::Min(100, [Math]::Max(0, $Progress))
    $width = 20
    $filled = [int][Math]::Round(($clampedProgress / 100) * $width)
    $empty = $width - $filled
    return ("[{0}{1}] {2}%" -f ("#" * $filled), ("-" * $empty), $clampedProgress)
}

function Get-AgentPalette {
    param([string]$AgentId)

    switch ($AgentId) {
        "company_lead" { return @{ accent = 33; hair = 24; skin = 223; dark = 236; white = 15 } }
        "product_manager" { return @{ accent = 45; hair = 95; skin = 223; dark = 236; white = 15 } }
        "software_developer" { return @{ accent = 40; hair = 22; skin = 223; dark = 236; white = 15 } }
        "qa_reviewer" { return @{ accent = 208; hair = 52; skin = 223; dark = 236; white = 15 } }
        "data_engineer" { return @{ accent = 39; hair = 17; skin = 223; dark = 236; white = 15 } }
        "marketing_strategist" { return @{ accent = 199; hair = 88; skin = 223; dark = 236; white = 15 } }
        default { return @{ accent = 75; hair = 238; skin = 223; dark = 236; white = 15 } }
    }
}

function New-PixelCell {
    param(
        [string]$Key,
        $Palette
    )

    if ([string]::IsNullOrWhiteSpace($Key)) {
        return "  "
    }

    if ($env:NO_COLOR) {
        return "[]"
    }

    $color = switch ($Key) {
        "A" { $Palette.accent }
        "H" { $Palette.hair }
        "S" { $Palette.skin }
        "D" { $Palette.dark }
        "W" { $Palette.white }
        default { 238 }
    }

    $esc = Get-Esc
    return "$esc[48;5;${color}m  $esc[0m"
}

function Get-AgentSprite {
    param([string]$AgentId)

    $palette = Get-AgentPalette -AgentId $AgentId
    $pattern = @(
        "  AAAA  ",
        " AAAAAA ",
        " HHSSHH ",
        " HSDDSH ",
        " HSSSSH ",
        "  ADDD  ",
        " AA  AA "
    )

    $sprite = @()
    foreach ($line in $pattern) {
        $rendered = ""
        foreach ($char in $line.ToCharArray()) {
            $rendered += New-PixelCell -Key ([string]$char) -Palette $palette
        }
        $sprite += $rendered
    }

    return $sprite
}

function Remove-AnsiEscape {
    param([AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrEmpty($Text)) {
        return ""
    }

    $esc = [regex]::Escape([string](Get-Esc))
    return [regex]::Replace($Text, "$esc\[[0-9;]*[A-Za-z]", "")
}

function Get-VisibleLength {
    param([AllowEmptyString()][string]$Text)

    return (Remove-AnsiEscape -Text $Text).Length
}

function Limit-PlainText {
    param(
        [AllowEmptyString()][string]$Text,
        [int]$Width
    )

    if ($null -eq $Text) {
        $Text = ""
    }

    $clean = ($Text -replace "\s+", " ").Trim()
    if ($Width -le 0) {
        return ""
    }
    if ($clean.Length -le $Width) {
        return $clean
    }
    if ($Width -eq 1) {
        return "~"
    }

    return ($clean.Substring(0, $Width - 1) + "~")
}

function Pad-AnsiRight {
    param(
        [AllowEmptyString()][string]$Text,
        [int]$Width
    )

    $visibleLength = Get-VisibleLength -Text $Text
    if ($visibleLength -gt $Width) {
        $plain = Remove-AnsiEscape -Text $Text
        return Limit-PlainText -Text $plain -Width $Width
    }

    return ($Text + (" " * ($Width - $visibleLength)))
}

function New-MiniPixelCell {
    param(
        [string]$Key,
        $Palette
    )

    if ([string]::IsNullOrWhiteSpace($Key)) {
        return " "
    }

    if ($env:NO_COLOR) {
        return "."
    }

    $color = switch ($Key) {
        "A" { $Palette.accent }
        "H" { $Palette.hair }
        "S" { $Palette.skin }
        "D" { $Palette.dark }
        default { 238 }
    }

    $esc = Get-Esc
    return "$esc[48;5;${color}m $esc[0m"
}

function Get-AgentMiniSprite {
    param([string]$AgentId)

    $palette = Get-AgentPalette -AgentId $AgentId
    $pattern = @(
        " AAA ",
        "HSSSH",
        "HDDDH",
        " A A "
    )

    $sprite = @()
    foreach ($line in $pattern) {
        $rendered = ""
        foreach ($char in $line.ToCharArray()) {
            $rendered += New-MiniPixelCell -Key ([string]$char) -Palette $palette
        }
        $sprite += $rendered
    }

    return $sprite
}

function New-CardLine {
    param(
        [AllowEmptyString()][string]$Content,
        [int]$Width
    )

    $innerWidth = $Width - 2
    return ("|{0}|" -f (Pad-AnsiRight -Text $Content -Width $innerWidth))
}

function Get-AgentCompactCardLines {
    param(
        [Parameter(Mandatory = $true)]$Agent,
        [int]$Width = 34,
        [int]$StaleMinutes = 15
    )

    $innerWidth = $Width - 2
    $effectiveStatus = Get-AgentEffectiveStatus -Agent $Agent -DefaultStaleMinutes $StaleMinutes
    $sprite = Get-AgentMiniSprite -AgentId $Agent.agentId
    $spriteWidth = 5
    $infoWidth = $innerWidth - $spriteWidth - 1
    $progressWidth = 10
    $progress = [Math]::Min(100, [Math]::Max(0, [int]$Agent.progress))
    $filled = [int][Math]::Round(($progress / 100) * $progressWidth)
    $progressText = ("[{0}{1}] {2}%" -f ("#" * $filled), ("-" * ($progressWidth - $filled)), $progress)

    $headerNameWidth = $innerWidth - 10
    $header = ("{0} {1}" -f
        (Limit-PlainText -Text $Agent.displayName -Width $headerNameWidth),
        (Limit-PlainText -Text $effectiveStatus.ToUpperInvariant() -Width 8)
    )

    $info = @(
        ("Task {0}" -f (Limit-PlainText -Text $Agent.currentTask -Width ($infoWidth - 5))),
        ("Next {0}" -f (Limit-PlainText -Text $Agent.nextAction -Width ($infoWidth - 5))),
        ("Prog {0}" -f (Limit-PlainText -Text $progressText -Width ($infoWidth - 5))),
        ("Upd  {0}" -f (Limit-PlainText -Text (Get-AgentAgeLabel -LastUpdated $Agent.lastUpdated) -Width ($infoWidth - 5)))
    )

    if (-not [string]::IsNullOrWhiteSpace($Agent.blocker)) {
        $info[3] = ("Block {0}" -f (Limit-PlainText -Text $Agent.blocker -Width ($infoWidth - 6)))
    }

    $lines = @()
    $lines += ("+" + ("-" * $innerWidth) + "+")
    $lines += New-CardLine -Content $header -Width $Width
    for ($i = 0; $i -lt $sprite.Count; $i++) {
        $content = "{0} {1}" -f $sprite[$i], (Limit-PlainText -Text $info[$i] -Width $infoWidth)
        $lines += New-CardLine -Content $content -Width $Width
    }
    $lines += ("+" + ("-" * $innerWidth) + "+")

    return $lines
}

function Get-AgentGridLines {
    param(
        [Parameter(Mandatory = $true)]$Agents,
        [int]$MaxColumns = 5,
        [int]$CardWidth = 34,
        [int]$Gap = 2,
        [int]$StaleMinutes = 15
    )

    $windowWidth = 180
    try {
        if ([Console]::WindowWidth -gt 0) {
            $windowWidth = [Console]::WindowWidth
        }
    }
    catch {
    }

    $maxThatFits = [Math]::Max(1, [int][Math]::Floor(($windowWidth + $Gap) / ($CardWidth + $Gap)))
    $columns = [Math]::Max(1, [Math]::Min($MaxColumns, $maxThatFits))
    $cards = @()
    foreach ($agent in @($Agents)) {
        $cards += ,(Get-AgentCompactCardLines -Agent $agent -Width $CardWidth -StaleMinutes $StaleMinutes)
    }

    $lines = @()
    for ($start = 0; $start -lt $cards.Count; $start += $columns) {
        $rowCards = @($cards[$start..([Math]::Min($start + $columns - 1, $cards.Count - 1))])
        $cardHeight = $rowCards[0].Count

        for ($lineIndex = 0; $lineIndex -lt $cardHeight; $lineIndex++) {
            $rowLineParts = @()
            foreach ($card in $rowCards) {
                $rowLineParts += $card[$lineIndex]
            }
            $lines += ($rowLineParts -join (" " * $Gap))
        }

        if (($start + $columns) -lt $cards.Count) {
            $lines += ""
        }
    }

    return $lines
}

function Wrap-PlainText {
    param(
        [AllowEmptyString()][string]$Text,
        [int]$Width
    )

    if ($Width -le 0) {
        return @("")
    }

    if ($null -eq $Text) {
        return @("")
    }

    $remaining = ($Text -replace "\s+", " ").Trim()
    if ([string]::IsNullOrWhiteSpace($remaining)) {
        return @("")
    }

    $lines = @()
    while ($remaining.Length -gt $Width) {
        $breakAt = $remaining.LastIndexOf(" ", [Math]::Min($Width, $remaining.Length - 1))
        if ($breakAt -le 0) {
            $breakAt = $Width
        }

        $lines += $remaining.Substring(0, $breakAt).Trim()
        $remaining = $remaining.Substring($breakAt).Trim()
    }

    if ($remaining.Length -gt 0) {
        $lines += $remaining
    }

    return $lines
}

function New-PanelLine {
    param(
        [AllowEmptyString()][string]$Content,
        [int]$Width
    )

    $innerWidth = $Width - 2
    return ("|{0}|" -f (Pad-AnsiRight -Text $Content -Width $innerWidth))
}

function Get-MonitorContentWidth {
    param([int]$Fallback = 178)

    try {
        if ([Console]::WindowWidth -gt 0) {
            return [Math]::Max(80, [Console]::WindowWidth - 2)
        }
    }
    catch {
    }

    return $Fallback
}

function Get-AgentSortTimestamp {
    param([Parameter(Mandatory = $true)]$Agent)

    if ([string]::IsNullOrWhiteSpace($Agent.lastUpdated)) {
        return [datetimeoffset]::MinValue
    }

    try {
        return [datetimeoffset]::Parse($Agent.lastUpdated)
    }
    catch {
        return [datetimeoffset]::MinValue
    }
}

function Get-DetailAgent {
    param(
        [Parameter(Mandatory = $true)]$Agents,
        [string]$DetailAgentId
    )

    if (-not [string]::IsNullOrWhiteSpace($DetailAgentId) -and $DetailAgentId -ne "auto") {
        $selected = @($Agents) | Where-Object { $_.agentId -eq $DetailAgentId } | Select-Object -First 1
        if ($selected) {
            return $selected
        }
    }

    $activeStatuses = @("working", "planning", "reviewing", "blocked", "waiting", "error", "stale")
    $active = @($Agents) |
        Where-Object { $activeStatuses -contains $_.status } |
        Sort-Object -Property @{ Expression = { Get-AgentSortTimestamp -Agent $_ }; Descending = $true } |
        Select-Object -First 1

    if ($active) {
        return $active
    }

    $recent = @($Agents) |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_.lastUpdated) } |
        Sort-Object -Property @{ Expression = { Get-AgentSortTimestamp -Agent $_ }; Descending = $true } |
        Select-Object -First 1

    if ($recent) {
        return $recent
    }

    return @($Agents) | Select-Object -First 1
}

function Get-AgentDetailPanelLines {
    param(
        [Parameter(Mandatory = $true)]$Agent,
        [int]$Width = 178,
        [int]$StaleMinutes = 15,
        [int]$Events = 5
    )

    $innerWidth = $Width - 2
    $effectiveStatus = Get-AgentEffectiveStatus -Agent $Agent -DefaultStaleMinutes $StaleMinutes
    $title = "DETAIL {0} ({1}) {2}" -f $Agent.displayName, $Agent.agentId, $effectiveStatus.ToUpperInvariant()
    $blocker = if ([string]::IsNullOrWhiteSpace($Agent.blocker)) { "-" } else { $Agent.blocker }
    $lines = @()

    $lines += ("+" + ("-" * $innerWidth) + "+")
    $lines += New-PanelLine -Content $title -Width $Width
    $lines += New-PanelLine -Content ("Role:     {0}" -f $Agent.role) -Width $Width
    foreach ($wrapped in Wrap-PlainText -Text ("Task:     {0}" -f $Agent.currentTask) -Width $innerWidth) {
        $lines += New-PanelLine -Content $wrapped -Width $Width
    }
    foreach ($wrapped in Wrap-PlainText -Text ("Next:     {0}" -f $Agent.nextAction) -Width $innerWidth) {
        $lines += New-PanelLine -Content $wrapped -Width $Width
    }
    $lines += New-PanelLine -Content ("Progress: {0}" -f (Format-ProgressBar -Progress ([int]$Agent.progress))) -Width $Width
    $lines += New-PanelLine -Content ("Updated:  {0}" -f (Get-AgentAgeLabel -LastUpdated $Agent.lastUpdated)) -Width $Width
    foreach ($wrapped in Wrap-PlainText -Text ("Blocker:  {0}" -f $blocker) -Width $innerWidth) {
        $lines += New-PanelLine -Content $wrapped -Width $Width
    }
    $lines += New-PanelLine -Content ("-" * [Math]::Min(24, $innerWidth)) -Width $Width
    $lines += New-PanelLine -Content "Recent events" -Width $Width

    $recentEvents = Read-AgentEventsTail -Tail 100 |
        Where-Object { $_.agentId -eq $Agent.agentId } |
        Select-Object -Last $Events

    if (-not $recentEvents) {
        $lines += New-PanelLine -Content "No recent events for this agent." -Width $Width
    }
    else {
        foreach ($event in $recentEvents) {
            foreach ($wrappedEvent in Wrap-PlainText -Text (Format-AgentEventLine -Event $event) -Width $innerWidth) {
                $lines += New-PanelLine -Content $wrappedEvent -Width $Width
            }
        }
    }

    $lines += ("+" + ("-" * $innerWidth) + "+")
    return $lines
}

function Get-MonitorHeaderLines {
    param([string]$Title)

    $line = "=" * 72
    return @(
        (Format-Ansi -Text $line -Code "90m"),
        (Format-Ansi -Text $Title -Code "1;37m"),
        (Format-Ansi -Text $line -Code "90m")
    )
}

function Write-MonitorHeader {
    param([string]$Title)

    foreach ($line in Get-MonitorHeaderLines -Title $Title) {
        Write-Host $line
    }
}

function Get-AgentBlockLines {
    param(
        [Parameter(Mandatory = $true)]$Agent,
        [int]$StaleMinutes = 15
    )

    $effectiveStatus = Get-AgentEffectiveStatus -Agent $Agent -DefaultStaleMinutes $StaleMinutes
    $sprite = Get-AgentSprite -AgentId $Agent.agentId
    $blocker = if ([string]::IsNullOrWhiteSpace($Agent.blocker)) { "-" } else { $Agent.blocker }
    $info = @(
        ("{0} {1}" -f (Format-Ansi -Text $Agent.displayName -Code "1;37m"), (Format-StatusBadge -Status $effectiveStatus)),
        ("Role:     {0}" -f $Agent.role),
        ("Task:     {0}" -f $Agent.currentTask),
        ("Progress: {0}" -f (Format-ProgressBar -Progress ([int]$Agent.progress))),
        ("Next:     {0}" -f $Agent.nextAction),
        ("Updated:  {0}" -f (Get-AgentAgeLabel -LastUpdated $Agent.lastUpdated)),
        ("Blocker:  {0}" -f $blocker)
    )

    $lines = @()
    for ($i = 0; $i -lt $sprite.Count; $i++) {
        $lines += ($sprite[$i] + "  " + $info[$i])
    }
    $lines += ""

    return $lines
}

function Write-AgentBlock {
    param(
        [Parameter(Mandatory = $true)]$Agent,
        [int]$StaleMinutes = 15
    )

    foreach ($line in Get-AgentBlockLines -Agent $Agent -StaleMinutes $StaleMinutes) {
        Write-Host $line
    }
}

function Format-AgentEventLine {
    param([Parameter(Mandatory = $true)]$Event)

    $time = $Event.timestamp
    try {
        $time = ([datetimeoffset]::Parse($Event.timestamp)).ToString("HH:mm:ss")
    }
    catch {
    }

    $status = if ([string]::IsNullOrWhiteSpace($Event.status)) { "event" } else { $Event.status }
    $agentId = if ([string]::IsNullOrWhiteSpace($Event.agentId)) { "unknown" } else { $Event.agentId }
    $message = if ([string]::IsNullOrWhiteSpace($Event.message)) { $Event.task } else { $Event.message }

    return ("{0}  {1,-20} {2,-10} {3}" -f $time, $agentId, $status, $message)
}

function ConvertTo-MonitorFrame {
    param([AllowEmptyString()][string[]]$Lines)

    return (($Lines -join [Environment]::NewLine) + [Environment]::NewLine)
}

function Write-MonitorFrame {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string[]]$Lines,
        [string]$PreviousFrame,
        [switch]$Force
    )

    $frame = ConvertTo-MonitorFrame -Lines $Lines
    if (-not $Force -and $frame -eq $PreviousFrame) {
        return $PreviousFrame
    }

    $esc = Get-Esc
    try {
        [Console]::CursorVisible = $false
    }
    catch {
    }

    if (-not $script:MonitorScreenInitialized) {
        Write-Host "$esc[2J$esc[H" -NoNewline
        $script:MonitorScreenInitialized = $true
    }
    else {
        Write-Host "$esc[H" -NoNewline
    }

    Write-Host $frame -NoNewline
    Write-Host "$esc[J" -NoNewline
    return $frame
}

function Restore-MonitorTerminal {
    $esc = Get-Esc
    try {
        [Console]::CursorVisible = $true
    }
    catch {
    }
    Write-Host "$esc[0m" -NoNewline
}
