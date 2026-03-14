#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <clean_root> <modified_root> <out_dir>"
  echo "Example: $0 /tmp/clean /tmp/modified ./patches"
  exit 1
fi

CLEAN_ROOT="$1"
MOD_ROOT="$2"
OUT_DIR="$3"

FILES=(
  "Code_app/.vscode/launch.json"
  "VSCodeExtensions/stmicroelectronics.stm32cube-ide-debug-jlink-gdbserver-1.2.0/package.json"
  "VSCodeExtensions/stmicroelectronics.stm32cube-ide-debug-jlink-gdbserver-1.2.0/lib/extension.js"
  "VSCodeExtensions/stmicroelectronics.stm32cube-ide-debug-jlink-gdbserver-1.2.0/lib/adapter/JLinkDebugTargetAdapter.js"
  "VSCodeExtensions/stmicroelectronics.stm32cube-ide-debug-stlink-gdbserver-1.2.0/package.json"
  "VSCodeExtensions/stmicroelectronics.stm32cube-ide-debug-stlink-gdbserver-1.2.0/lib/extension.js"
  "VSCodeExtensions/stmicroelectronics.stm32cube-ide-debug-stlink-gdbserver-1.2.0/lib/adapter/STLinkDebugTargetAdapter.js"
)

mkdir -p "$OUT_DIR"

for f in "${FILES[@]}"; do
  CLEAN_FILE="$CLEAN_ROOT/$f"
  MOD_FILE="$MOD_ROOT/$f"
  PATCH_FILE="$OUT_DIR/${f//\//__}.patch"

  if [[ ! -f "$CLEAN_FILE" || ! -f "$MOD_FILE" ]]; then
    echo "[SKIP] missing file: $f"
    continue
  fi

  if diff -u "$CLEAN_FILE" "$MOD_FILE" > "$PATCH_FILE"; then
    rm -f "$PATCH_FILE"
    echo "[SAME] $f"
  else
    echo "[PATCH] $PATCH_FILE"
  fi
done

echo "Done. Patch files are in: $OUT_DIR"
