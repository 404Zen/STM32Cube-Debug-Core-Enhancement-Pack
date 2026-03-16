param(
    [Parameter(Mandatory = $true)]
    [string]$AppWorkspace,
    [string]$OutputDir = 'private_snapshot',
    [string]$ExtensionsDir
)

$ErrorActionPreference = 'Stop'

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

if (-not (Test-Path $AppWorkspace -PathType Container)) {
    throw "app workspace does not exist: $AppWorkspace"
}

$appWorkspace = (Resolve-Path $AppWorkspace).Path
$extDir = Resolve-ExtensionsDir -InputDir $ExtensionsDir

$jlink = 'stmicroelectronics.stm32cube-ide-debug-jlink-gdbserver-1.2.0'
$stlink = 'stmicroelectronics.stm32cube-ide-debug-stlink-gdbserver-1.2.0'

$paths = @(
    @{ Src = Join-Path $appWorkspace '.vscode\launch.json'; Dst = Join-Path $OutputDir 'Code_app\.vscode\launch.json' },
    @{ Src = Join-Path $extDir "$jlink\package.json"; Dst = Join-Path $OutputDir "VSCodeExtensions\$jlink\package.json" },
    @{ Src = Join-Path $extDir "$jlink\lib\extension.js"; Dst = Join-Path $OutputDir "VSCodeExtensions\$jlink\lib\extension.js" },
    @{ Src = Join-Path $extDir "$jlink\lib\adapter\JLinkDebugTargetAdapter.js"; Dst = Join-Path $OutputDir "VSCodeExtensions\$jlink\lib\adapter\JLinkDebugTargetAdapter.js" },
    @{ Src = Join-Path $extDir "$stlink\package.json"; Dst = Join-Path $OutputDir "VSCodeExtensions\$stlink\package.json" },
    @{ Src = Join-Path $extDir "$stlink\lib\extension.js"; Dst = Join-Path $OutputDir "VSCodeExtensions\$stlink\lib\extension.js" },
    @{ Src = Join-Path $extDir "$stlink\lib\adapter\STLinkDebugTargetAdapter.js"; Dst = Join-Path $OutputDir "VSCodeExtensions\$stlink\lib\adapter\STLinkDebugTargetAdapter.js" }
)

foreach ($item in $paths) {
    if (-not (Test-Path $item.Src -PathType Leaf)) {
        throw "source file not found: $($item.Src)"
    }

    $parent = Split-Path -Parent $item.Dst
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    Copy-Item $item.Src $item.Dst -Force
}

Write-Host "Export completed to: $OutputDir"
Write-Host 'WARNING: private_snapshot content may include proprietary files. Do NOT publish directly.'
