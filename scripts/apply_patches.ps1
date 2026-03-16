param(
    [Parameter(Mandatory = $true)]
    [string]$AppWorkspace,
    [string]$ExtensionsDir,
    [switch]$StrictLaunchPatch
)

$ErrorActionPreference = 'Stop'
if (Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
    $PSNativeCommandUseErrorActionPreference = $false
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir
$patchDir = Join-Path $rootDir 'patches'

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

function Get-NormalizedPatch {
    param(
        [string]$PatchFile,
        [string]$PatchTempDir
    )

    $raw = Get-Content $PatchFile -Raw
    $raw = $raw -replace "`r", ''
    $raw = $raw -replace 'private_snapshot/clean/', ''
    $raw = $raw -replace 'private_snapshot/modified/', ''

    $normalized = Join-Path $PatchTempDir (Split-Path $PatchFile -Leaf)
    Set-Content -Path $normalized -Value $raw -NoNewline
    return $normalized
}

function Test-GitApply {
    param(
        [string]$Root,
        [string]$PatchFile,
        [switch]$Reverse
    )

    Push-Location $Root
    try {
        $reverseArg = if ($Reverse) { ' --reverse' } else { '' }
        $quotedPatch = '"' + $PatchFile + '"'
        $cmdLine = "git apply --check -p0 --ignore-whitespace --unsafe-paths$reverseArg $quotedPatch >nul 2>nul"
        & cmd.exe /d /c $cmdLine | Out-Null
        return ($LASTEXITCODE -eq 0)
    }
    finally {
        Pop-Location
    }
}

function Invoke-GitApply {
    param(
        [string]$Root,
        [string]$PatchFile
    )

    Push-Location $Root
    try {
        $quotedPatch = '"' + $PatchFile + '"'
        $cmdLine = "git apply -p0 --ignore-whitespace --unsafe-paths $quotedPatch"
        & cmd.exe /d /c $cmdLine | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "git apply failed: $PatchFile"
        }
    }
    finally {
        Pop-Location
    }
}

function Test-ExpectedMarker {
    param(
        [string]$Rel,
        [string]$Target
    )

    if (-not (Test-Path $Target -PathType Leaf)) {
        return $false
    }

    $text = Get-Content $Target -Raw

    switch ($Rel) {
        'Code_app/.vscode/launch.json' {
            return ($text -match '(?m)^\s*"numberDisplayMode"\s*:')
        }
        "VSCodeExtensions/$jlinkId/package.json" {
            return $text.Contains('st-cube-debug-jlink-gdbserver.number-format.dec')
        }
        "VSCodeExtensions/$jlinkId/lib/extension.js" {
            return $text.Contains('adapter/setVariableNumberDisplayMode')
        }
        "VSCodeExtensions/$jlinkId/lib/adapter/JLinkDebugTargetAdapter.js" {
            return $text.Contains('setVariableNumberDisplayMode')
        }
        "VSCodeExtensions/$stlinkId/package.json" {
            return $text.Contains('st-cube-debug-stlink-gdbserver.number-format.dec')
        }
        "VSCodeExtensions/$stlinkId/lib/extension.js" {
            return $text.Contains('adapter/setVariableNumberDisplayMode')
        }
        "VSCodeExtensions/$stlinkId/lib/adapter/STLinkDebugTargetAdapter.js" {
            return $text.Contains('setVariableNumberDisplayMode')
        }
        default {
            return $false
        }
    }
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "git command not found. Please install Git for Windows."
}

if (-not (Test-Path $patchDir -PathType Container)) {
    throw "patches directory not found: $patchDir"
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

Write-Host '[INFO] Checking target extension versions...'
& (Join-Path $scriptDir 'check_target_versions.ps1') -ExtensionsDir $extDir

$tmpRoot = Join-Path $env:TEMP ("stm32_patch_apply_{0}" -f ([guid]::NewGuid().ToString('N')))
$patchTmp = Join-Path $env:TEMP ("stm32_patch_lf_{0}" -f ([guid]::NewGuid().ToString('N')))
New-Item -ItemType Directory -Path $tmpRoot | Out-Null
New-Item -ItemType Directory -Path $patchTmp | Out-Null

$patchStatus = @{}

try {
    foreach ($rel in $relFiles) {
        $source = Resolve-TargetPath -Rel $rel -Workspace $appWorkspace -JlinkDir $jlinkDir -StlinkDir $stlinkDir
        if (-not (Test-Path $source -PathType Leaf)) {
            throw "Target file not found: $source"
        }

        $dst = Join-Path $tmpRoot ($rel.Replace('/', '\'))
        $dstDir = Split-Path -Parent $dst
        if (-not (Test-Path $dstDir)) {
            New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
        }
        Copy-Item $source $dst -Force
    }

    Write-Host '[INFO] Validating patch applicability...'
    foreach ($rel in $relFiles) {
        $patchFile = Join-Path $patchDir (($rel -replace '/', '__') + '.patch')
        if (-not (Test-Path $patchFile -PathType Leaf)) {
            throw "Missing patch file: $patchFile"
        }

        $normPatch = Get-NormalizedPatch -PatchFile $patchFile -PatchTempDir $patchTmp
        $target = Resolve-TargetPath -Rel $rel -Workspace $appWorkspace -JlinkDir $jlinkDir -StlinkDir $stlinkDir

        if (Test-GitApply -Root $tmpRoot -PatchFile $normPatch) {
            $patchStatus[$rel] = 'apply'
            continue
        }

        if (Test-GitApply -Root $tmpRoot -PatchFile $normPatch -Reverse) {
            $patchStatus[$rel] = 'already'
            continue
        }

        if (Test-ExpectedMarker -Rel $rel -Target $target) {
            $patchStatus[$rel] = 'already'
            continue
        }

        if (($rel -eq 'Code_app/.vscode/launch.json') -and (-not $StrictLaunchPatch.IsPresent)) {
            $patchStatus[$rel] = 'skip'
            Write-Host '[WARN] launch.json patch not applicable (customized launch config).'
            Write-Host '       Skip app launch patch and continue extension patches.'
            continue
        }

        throw "Patch cannot be applied cleanly: $patchFile"
    }

    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $backupDir = Join-Path $rootDir (Join-Path 'backups' ("apply_$timestamp"))
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

    Write-Host "[INFO] Backing up target files to: $backupDir"
    foreach ($rel in $relFiles) {
        $status = $patchStatus[$rel]
        if ($status -eq 'skip') {
            Write-Host "[SKIP] skip backup (not patching): $rel"
            continue
        }

        $target = Resolve-TargetPath -Rel $rel -Workspace $appWorkspace -JlinkDir $jlinkDir -StlinkDir $stlinkDir
        $backup = Join-Path $backupDir ($rel.Replace('/', '\'))
        $backupParent = Split-Path -Parent $backup
        if (-not (Test-Path $backupParent)) {
            New-Item -ItemType Directory -Path $backupParent -Force | Out-Null
        }
        Copy-Item $target $backup -Force
    }

    Write-Host '[INFO] Applying patches...'
    foreach ($rel in $relFiles) {
        $status = $patchStatus[$rel]
        if ($status -eq 'already') {
            Write-Host "[SKIP] already applied: $rel"
            continue
        }
        if ($status -eq 'skip') {
            Write-Host "[SKIP] not applicable: $rel"
            continue
        }

        $patchFile = Join-Path $patchDir (($rel -replace '/', '__') + '.patch')
        $normPatch = Get-NormalizedPatch -PatchFile $patchFile -PatchTempDir $patchTmp
        Invoke-GitApply -Root $tmpRoot -PatchFile $normPatch

        $patchedFile = Join-Path $tmpRoot ($rel.Replace('/', '\'))
        $target = Resolve-TargetPath -Rel $rel -Workspace $appWorkspace -JlinkDir $jlinkDir -StlinkDir $stlinkDir
        Copy-Item $patchedFile $target -Force
        Write-Host "[OK]   applied: $rel"
    }

    Write-Host ''
    Write-Host '[DONE] Patch apply finished.'
    Write-Host "       Backup location: $backupDir"
    Write-Host '       Next step: reload VS Code window and restart debug session.'
}
finally {
    if (Test-Path $tmpRoot) { Remove-Item $tmpRoot -Recurse -Force }
    if (Test-Path $patchTmp) { Remove-Item $patchTmp -Recurse -Force }
}
