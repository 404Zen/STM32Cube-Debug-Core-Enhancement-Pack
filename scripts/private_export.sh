#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <app_workspace_path> [output_dir]"
   echo "Example: $0 /path/to/your/Code/app"
  exit 1
fi

APP_WORKSPACE="$1"
OUT_DIR="${2:-private_snapshot}"

mkdir -p "$OUT_DIR/Code_app/.vscode"
mkdir -p "$OUT_DIR/VSCodeExtensions/stmicroelectronics.stm32cube-ide-debug-jlink-gdbserver-1.2.0/lib/adapter"
mkdir -p "$OUT_DIR/VSCodeExtensions/stmicroelectronics.stm32cube-ide-debug-stlink-gdbserver-1.2.0/lib/adapter"

cp "$APP_WORKSPACE/.vscode/launch.json" "$OUT_DIR/Code_app/.vscode/launch.json"

cp "$HOME/.vscode/extensions/stmicroelectronics.stm32cube-ide-debug-jlink-gdbserver-1.2.0/package.json" \
   "$OUT_DIR/VSCodeExtensions/stmicroelectronics.stm32cube-ide-debug-jlink-gdbserver-1.2.0/package.json"
cp "$HOME/.vscode/extensions/stmicroelectronics.stm32cube-ide-debug-jlink-gdbserver-1.2.0/lib/extension.js" \
   "$OUT_DIR/VSCodeExtensions/stmicroelectronics.stm32cube-ide-debug-jlink-gdbserver-1.2.0/lib/extension.js"
cp "$HOME/.vscode/extensions/stmicroelectronics.stm32cube-ide-debug-jlink-gdbserver-1.2.0/lib/adapter/JLinkDebugTargetAdapter.js" \
   "$OUT_DIR/VSCodeExtensions/stmicroelectronics.stm32cube-ide-debug-jlink-gdbserver-1.2.0/lib/adapter/JLinkDebugTargetAdapter.js"

cp "$HOME/.vscode/extensions/stmicroelectronics.stm32cube-ide-debug-stlink-gdbserver-1.2.0/package.json" \
   "$OUT_DIR/VSCodeExtensions/stmicroelectronics.stm32cube-ide-debug-stlink-gdbserver-1.2.0/package.json"
cp "$HOME/.vscode/extensions/stmicroelectronics.stm32cube-ide-debug-stlink-gdbserver-1.2.0/lib/extension.js" \
   "$OUT_DIR/VSCodeExtensions/stmicroelectronics.stm32cube-ide-debug-stlink-gdbserver-1.2.0/lib/extension.js"
cp "$HOME/.vscode/extensions/stmicroelectronics.stm32cube-ide-debug-stlink-gdbserver-1.2.0/lib/adapter/STLinkDebugTargetAdapter.js" \
   "$OUT_DIR/VSCodeExtensions/stmicroelectronics.stm32cube-ide-debug-stlink-gdbserver-1.2.0/lib/adapter/STLinkDebugTargetAdapter.js"

echo "Export completed to: $OUT_DIR"
echo "WARNING: private_snapshot content may include proprietary files. Do NOT publish directly."
