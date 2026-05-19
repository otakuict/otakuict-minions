param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("list-devices", "scan-device", "stage-device")]
    [string]$Operation,

    [string]$DeviceId,

    [string]$Destination
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$SupportedExtensions = @(".aae", ".gif", ".heic", ".heif", ".jpeg", ".jpg", ".mov", ".mp4", ".png")
$CopyFlags = 4 + 16 + 512 + 1024
$Script:Shell = New-Object -ComObject Shell.Application

function Get-ComputerFolder {
    return $Script:Shell.NameSpace("shell:MyComputerFolder")
}

function Get-DeviceCandidates {
    $folder = Get-ComputerFolder
    $devices = @()

    foreach ($item in @($folder.Items())) {
        if ($item.IsFileSystem) {
            continue
        }

        $deviceId = if ($item.Path) { [string]$item.Path } else { [string]$item.Name }
        $devices += [pscustomobject]@{
            id            = $deviceId
            name          = [string]$item.Name
            path          = [string]$item.Path
            type          = [string]$item.Type
            is_file_system = [bool]$item.IsFileSystem
            is_folder     = [bool]$item.IsFolder
        }
    }

    return $devices
}

function Resolve-DeviceItem {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RequestedId
    )

    $folder = Get-ComputerFolder

    foreach ($item in @($folder.Items())) {
        $deviceId = if ($item.Path) { [string]$item.Path } else { [string]$item.Name }
        if ($deviceId -eq $RequestedId -or [string]$item.Name -eq $RequestedId) {
            return $item
        }
    }

    throw "USB device not found in Windows shell namespace: $RequestedId"
}

function Get-ItemSize {
    param($Item)

    try {
        return [long]$Item.Size
    } catch {
        return 0
    }
}

function Get-ItemModifiedAt {
    param($Item)

    try {
        if ($null -ne $Item.ModifyDate) {
            return ([datetime]$Item.ModifyDate).ToString("o")
        }
    } catch {
    }

    return $null
}

function Wait-ForFileReady {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [long]$ExpectedSize = 0
    )

    $timeoutAt = (Get-Date).AddMinutes(15)
    $stableCount = 0
    $lastSize = -1

    while ((Get-Date) -lt $timeoutAt) {
        if (Test-Path -LiteralPath $Path) {
            $currentSize = (Get-Item -LiteralPath $Path).Length

            if ($ExpectedSize -gt 0 -and $currentSize -lt $ExpectedSize) {
                $stableCount = 0
                $lastSize = $currentSize
                Start-Sleep -Milliseconds 400
                continue
            }

            if ($currentSize -eq $lastSize) {
                $stableCount += 1
            } else {
                $stableCount = 0
                $lastSize = $currentSize
            }

            if ($stableCount -ge 2) {
                return
            }
        }

        Start-Sleep -Milliseconds 400
    }

    throw "Timed out waiting for copied file: $Path"
}

function Invoke-ScanFolder {
    param(
        [Parameter(Mandatory = $true)]
        $FolderItem,

        [Parameter(Mandatory = $true)]
        [string[]]$Segments,

        [Parameter(Mandatory = $true)]
        [ref]$Results
    )

    $folder = $FolderItem.GetFolder()

    foreach ($child in @($folder.Items())) {
        if ($child.IsFolder) {
            Invoke-ScanFolder -FolderItem $child -Segments ($Segments + @([string]$child.Name)) -Results $Results
            continue
        }

        $fileName = [string]$child.Name
        $extension = [System.IO.Path]::GetExtension($fileName).ToLowerInvariant()
        $supported = $SupportedExtensions -contains $extension
        $relativePath = (($Segments + @($fileName)) -join "\")
        $devicePath = "$($FolderItem.Path)\$fileName"

        $Results.Value += [pscustomobject]@{
            action        = if ($supported) { "stage" } else { "unsupported" }
            device_path   = $devicePath
            relative_path = $relativePath
            media_type    = if ($extension) { $extension.TrimStart(".") } else { "unknown" }
            size          = Get-ItemSize -Item $child
            modified_at   = Get-ItemModifiedAt -Item $child
            reason        = if ($supported) { $null } else { "unsupported_extension" }
        }
    }
}

function Invoke-StageFolder {
    param(
        [Parameter(Mandatory = $true)]
        $FolderItem,

        [Parameter(Mandatory = $true)]
        [string[]]$Segments,

        [Parameter(Mandatory = $true)]
        [string]$DestinationRoot,

        [Parameter(Mandatory = $true)]
        [ref]$Results
    )

    $folder = $FolderItem.GetFolder()

    foreach ($child in @($folder.Items())) {
        if ($child.IsFolder) {
            Invoke-StageFolder -FolderItem $child -Segments ($Segments + @([string]$child.Name)) -DestinationRoot $DestinationRoot -Results $Results
            continue
        }

        $fileName = [string]$child.Name
        $extension = [System.IO.Path]::GetExtension($fileName).ToLowerInvariant()
        $supported = $SupportedExtensions -contains $extension
        $relativePath = (($Segments + @($fileName)) -join "\")
        $devicePath = "$($FolderItem.Path)\$fileName"
        $size = Get-ItemSize -Item $child
        $modifiedAt = Get-ItemModifiedAt -Item $child

        if (-not $supported) {
            $Results.Value += [pscustomobject]@{
                action        = "unsupported"
                device_path   = $devicePath
                relative_path = $relativePath
                staged_path   = $null
                media_type    = if ($extension) { $extension.TrimStart(".") } else { "unknown" }
                size          = $size
                modified_at   = $modifiedAt
                reason        = "unsupported_extension"
            }
            continue
        }

        $targetDirectory = Join-Path $DestinationRoot (($Segments) -join "\")
        New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null

        $targetFolder = $Script:Shell.NameSpace($targetDirectory)
        $targetPath = Join-Path $targetDirectory $fileName

        try {
            $targetFolder.CopyHere($child, $CopyFlags)
            Wait-ForFileReady -Path $targetPath -ExpectedSize $size

            $Results.Value += [pscustomobject]@{
                action        = "staged"
                device_path   = $devicePath
                relative_path = $relativePath
                staged_path   = $targetPath
                media_type    = if ($extension) { $extension.TrimStart(".") } else { "unknown" }
                size          = $size
                modified_at   = $modifiedAt
                reason        = $null
            }
        } catch {
            $Results.Value += [pscustomobject]@{
                action        = "failed"
                device_path   = $devicePath
                relative_path = $relativePath
                staged_path   = $targetPath
                media_type    = if ($extension) { $extension.TrimStart(".") } else { "unknown" }
                size          = $size
                modified_at   = $modifiedAt
                reason        = $_.Exception.Message
            }
        }
    }
}

switch ($Operation) {
    "list-devices" {
        $devices = Get-DeviceCandidates
        [pscustomobject]@{
            command     = "list-devices"
            devices     = $devices
            diagnostics = if ($devices.Count -eq 0) {
                @(
                    "No portable devices are visible in Windows shell right now.",
                    "Install Apple Devices if needed, unlock the iPhone, tap Trust, and reconnect the USB cable."
                )
            } else {
                @()
            }
        } | ConvertTo-Json -Depth 6
        break
    }

    "scan-device" {
        if (-not $DeviceId) {
            throw "DeviceId is required for scan-device."
        }

        $device = Resolve-DeviceItem -RequestedId $DeviceId
        $results = @()
        Invoke-ScanFolder -FolderItem $device -Segments @([string]$device.Name) -Results ([ref]$results)

        [pscustomobject]@{
            command = "scan-device"
            device  = [pscustomobject]@{
                id   = if ($device.Path) { [string]$device.Path } else { [string]$device.Name }
                name = [string]$device.Name
                path = [string]$device.Path
                type = [string]$device.Type
            }
            items   = $results
        } | ConvertTo-Json -Depth 6
        break
    }

    "stage-device" {
        if (-not $DeviceId) {
            throw "DeviceId is required for stage-device."
        }
        if (-not $Destination) {
            throw "Destination is required for stage-device."
        }

        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
        $device = Resolve-DeviceItem -RequestedId $DeviceId
        $results = @()
        Invoke-StageFolder -FolderItem $device -Segments @([string]$device.Name) -DestinationRoot $Destination -Results ([ref]$results)

        [pscustomobject]@{
            command     = "stage-device"
            device      = [pscustomobject]@{
                id   = if ($device.Path) { [string]$device.Path } else { [string]$device.Name }
                name = [string]$device.Name
                path = [string]$device.Path
                type = [string]$device.Type
            }
            destination = $Destination
            items       = $results
        } | ConvertTo-Json -Depth 6
        break
    }
}

