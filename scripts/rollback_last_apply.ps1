param(
    [Parameter(Mandatory = $true)]
    [string]$AppWorkspace,
    [string]$BackupDir,
    [string]$ExtensionsDir
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir
$backupsDir = Join-Path $rootDir 'backups'

$jlinkId = 'stmicroelectronics.stm32cube-ide-debug-jlink-gdbserver-1.2.0'
$stlinkId = 'stmicroelectronics.stm32cube-ide-debug-stlink-gdbserver-1.2.0'

$relFiles = @(
    'Code_app/.vscode/launch.json',
    "VSCodeExtensions/$jlinkId/package.json",
    "VSCodeExtensions/$jlinkId/lib/extension.js",
    "VSCodeExtensions/$jlinkId/lib/adapter/JLinkDebugTargetAdapter.js",
    "VSCodeExtensions/$stlinkId/package.json",
    "VSCodeExtensions/$stlinkId/lib/extension.js",
    "VSCodeExtensions/$stlinkId/lib/adapter/STLinkDebugTargetAdapter.js"
)

function Resolve-ExtensionsDir {
    param([string]$InputDir)

    $candidates = @()
    if ($InputDir) { $candidates += $InputDir }
    if ($env:VSCODE_EXTENSIONS_DIR) { $candidates += $env:VSCODE_EXTENSIONS_DIR }
    if ($HOME) { $candidates += (Join-Path $HOME '.vscode\extensions') }
    if ($env:USERPROFILE) { $candidates += (Join-Path $env:USERPROFILE '.vscode\extensions') }

    foreach ($path in $candidates) {
        if ($path -and (Test-Path $path -PathType Container)) {
            return (Resolve-Path $path).Path
        }
    }

    throw "VS Code extensions directory not found. Set -ExtensionsDir or VSCODE_EXTENSIONS_DIR."
}

function Resolve-TargetPath {
    param(
        [string]$Rel,
        [string]$Workspace,
        [string]$JlinkDir,
        [string]$StlinkDir
    )

    if ($Rel.StartsWith('Code_app/')) {
        $tail = $Rel.Substring('Code_app/'.Length).Replace('/', '\')
        return Join-Path $Workspace $tail
    }

    $jPrefix = "VSCodeExtensions/$jlinkId/"
    if ($Rel.StartsWith($jPrefix)) {
        $tail = $Rel.Substring($jPrefix.Length).Replace('/', '\')
        return Join-Path $JlinkDir $tail
    }

    $sPrefix = "VSCodeExtensions/$stlinkId/"
    if ($Rel.StartsWith($sPrefix)) {
        $tail = $Rel.Substring($sPrefix.Length).Replace('/', '\')
        return Join-Path $StlinkDir $tail
    }

    throw "Unknown relative path mapping: $Rel"
}

function Resolve-BackupDir {
    param(
        [string]$InputBackup,
        [string]$RootDir,
        [string]$BackupsRoot
    )

    if ($InputBackup) {
        if (Test-Path $InputBackup -PathType Container) {
            return (Resolve-Path $InputBackup).Path
        }

        $joined = Join-Path $RootDir $InputBackup
        if (Test-Path $joined -PathType Container) {
            return (Resolve-Path $joined).Path
        }

        throw "backup directory not found: $InputBackup"
    }

    if (-not (Test-Path $BackupsRoot -PathType Container)) {
        throw "backups directory not found: $BackupsRoot"
    }

    $latest = Get-ChildItem $BackupsRoot -Directory | Where-Object { $_.Name -like 'apply_*' } | Sort-Object Name | Select-Object -Last 1
    if (-not $latest) {
        throw "no apply backup found in: $BackupsRoot"
    }

    return $latest.FullName
}

if (-not (Test-Path $AppWorkspace -PathType Container)) {
    throw "app workspace does not exist: $AppWorkspace"
}

$appWorkspace = (Resolve-Path $AppWorkspace).Path
$extDir = Resolve-ExtensionsDir -InputDir $ExtensionsDir
$jlinkDir = Join-Path $extDir $jlinkId
$stlinkDir = Join-Path $extDir $stlinkId

if (-not (Test-Path $jlinkDir -PathType Container)) {
    throw "JLink extension folder not found: $jlinkDir"
}
if (-not (Test-Path $stlinkDir -PathType Container)) {
    throw "STLink extension folder not found: $stlinkDir"
}

$resolvedBackup = Resolve-BackupDir -InputBackup $BackupDir -RootDir $rootDir -BackupsRoot $backupsDir
Write-Host "[INFO] Restoring files from backup: $resolvedBackup"

foreach ($rel in $relFiles) {
    $src = Join-Path $resolvedBackup ($rel.Replace('/', '\'))
    if (-not (Test-Path $src -PathType Leaf)) {
        if ($rel -eq 'Code_app/.vscode/launch.json') {
            Write-Host "[WARN] backup file not found (skipped by apply workflow): $src"
            Write-Host '       Skip restoring launch.json.'
            continue
        }
        throw "backup file not found: $src"
    }
}

foreach ($rel in $relFiles) {
    $src = Join-Path $resolvedBackup ($rel.Replace('/', '\'))
    if (-not (Test-Path $src -PathType Leaf)) {
        continue
    }

    $target = Resolve-TargetPath -Rel $rel -Workspace $appWorkspace -JlinkDir $jlinkDir -StlinkDir $stlinkDir
    $parent = Split-Path -Parent $target
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    Copy-Item $src $target -Force
    Write-Host "[OK]   restored: $rel"
}

Write-Host ''
Write-Host '[DONE] Rollback finished.'
Write-Host "       Source backup: $resolvedBackup"
Write-Host '       Next step: reload VS Code window and restart debug session.'
