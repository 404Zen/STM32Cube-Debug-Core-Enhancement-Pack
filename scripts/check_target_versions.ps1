param(
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

$extDir = Resolve-ExtensionsDir -InputDir $ExtensionsDir

$targets = @(
    'stmicroelectronics.stm32cube-ide-debug-jlink-gdbserver-1.2.0',
    'stmicroelectronics.stm32cube-ide-debug-stlink-gdbserver-1.2.0',
    'stmicroelectronics.stm32cube-ide-debug-core-1.2.0'
)

foreach ($id in $targets) {
    $pkg = Join-Path $extDir "$id\package.json"
    Write-Host "=== $pkg"
    if (-not (Test-Path $pkg -PathType Leaf)) {
        Write-Host 'NOT FOUND'
        continue
    }

    $json = Get-Content $pkg -Raw | ConvertFrom-Json
    Write-Host "name    = $($json.name)"
    Write-Host "version = $($json.version)"
    Write-Host "license = $($json.license)"
    Write-Host ''
}
