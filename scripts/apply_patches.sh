#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PATCH_DIR="$ROOT_DIR/patches"

JLINK_ID="stmicroelectronics.stm32cube-ide-debug-jlink-gdbserver-1.2.0"
STLINK_ID="stmicroelectronics.stm32cube-ide-debug-stlink-gdbserver-1.2.0"

if ! command -v patch >/dev/null 2>&1; then
  echo "[ERROR] 'patch' command not found."
  echo "        macOS usually has it by default."
  exit 1
fi

if [[ ! -d "$PATCH_DIR" ]]; then
  echo "[ERROR] patches directory not found: $PATCH_DIR"
  exit 1
fi

APP_WORKSPACE="${1:-}"
if [[ -z "$APP_WORKSPACE" ]]; then
  read -r -p "Enter your app workspace path (contains .vscode/launch.json): " APP_WORKSPACE
fi

if [[ ! -d "$APP_WORKSPACE" ]]; then
  echo "[ERROR] app workspace does not exist: $APP_WORKSPACE"
  exit 1
fi

JLINK_DIR="$HOME/.vscode/extensions/$JLINK_ID"
STLINK_DIR="$HOME/.vscode/extensions/$STLINK_ID"

if [[ ! -d "$JLINK_DIR" ]]; then
  echo "[ERROR] JLink extension folder not found: $JLINK_DIR"
  exit 1
fi

if [[ ! -d "$STLINK_DIR" ]]; then
  echo "[ERROR] STLink extension folder not found: $STLINK_DIR"
  exit 1
fi

REL_FILES=(
  "Code_app/.vscode/launch.json"
  "VSCodeExtensions/$JLINK_ID/package.json"
  "VSCodeExtensions/$JLINK_ID/lib/extension.js"
  "VSCodeExtensions/$JLINK_ID/lib/adapter/JLinkDebugTargetAdapter.js"
  "VSCodeExtensions/$STLINK_ID/package.json"
  "VSCodeExtensions/$STLINK_ID/lib/extension.js"
  "VSCodeExtensions/$STLINK_ID/lib/adapter/STLinkDebugTargetAdapter.js"
)

resolve_target() {
  local rel="$1"
  case "$rel" in
    Code_app/*)
      echo "$APP_WORKSPACE/${rel#Code_app/}"
      ;;
    VSCodeExtensions/$JLINK_ID/*)
      echo "$JLINK_DIR/${rel#VSCodeExtensions/$JLINK_ID/}"
      ;;
    VSCodeExtensions/$STLINK_ID/*)
      echo "$STLINK_DIR/${rel#VSCodeExtensions/$STLINK_ID/}"
      ;;
    *)
      return 1
      ;;
  esac
}

has_expected_marker() {
  local rel="$1"
  local target="$2"
  if [[ ! -f "$target" ]]; then
    return 1
  fi
  case "$rel" in
    Code_app/.vscode/launch.json)
      grep -q '"numberDisplayMode"' "$target"
      ;;
    VSCodeExtensions/$JLINK_ID/package.json)
      grep -q 'st-cube-debug-jlink-gdbserver.number-format.dec' "$target"
      ;;
    VSCodeExtensions/$JLINK_ID/lib/extension.js)
      grep -q 'adapter/setVariableNumberDisplayMode' "$target"
      ;;
    VSCodeExtensions/$JLINK_ID/lib/adapter/JLinkDebugTargetAdapter.js)
      grep -q 'setVariableNumberDisplayMode' "$target"
      ;;
    VSCodeExtensions/$STLINK_ID/package.json)
      grep -q 'st-cube-debug-stlink-gdbserver.number-format.dec' "$target"
      ;;
    VSCodeExtensions/$STLINK_ID/lib/extension.js)
      grep -q 'adapter/setVariableNumberDisplayMode' "$target"
      ;;
    VSCodeExtensions/$STLINK_ID/lib/adapter/STLinkDebugTargetAdapter.js)
      grep -q 'setVariableNumberDisplayMode' "$target"
      ;;
    *)
      return 1
      ;;
  esac
}

PATCH_STATUS=()

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/stm32_patch_apply.XXXXXX")"
cleanup() {
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

mkdir -p "$TMP_ROOT/VSCodeExtensions"
ln -s "$APP_WORKSPACE" "$TMP_ROOT/Code_app"
ln -s "$JLINK_DIR" "$TMP_ROOT/VSCodeExtensions/$JLINK_ID"
ln -s "$STLINK_DIR" "$TMP_ROOT/VSCodeExtensions/$STLINK_ID"

echo "[INFO] Checking target extension versions..."
"$SCRIPT_DIR/check_target_versions.sh" || true

echo "[INFO] Validating patch applicability..."
for idx in "${!REL_FILES[@]}"; do
  rel="${REL_FILES[$idx]}"
  patch_file="$PATCH_DIR/${rel//\//__}.patch"
  target_file="$(resolve_target "$rel")"
  if [[ ! -f "$patch_file" ]]; then
    echo "[ERROR] Missing patch file: $patch_file"
    exit 1
  fi

  if patch --dry-run --batch --forward -p2 -d "$TMP_ROOT" -i "$patch_file" >/dev/null 2>&1; then
    PATCH_STATUS[$idx]="apply"
    continue
  fi

  if patch --dry-run --batch -R -p2 -d "$TMP_ROOT" -i "$patch_file" >/dev/null 2>&1; then
    PATCH_STATUS[$idx]="already"
    continue
  fi

  if has_expected_marker "$rel" "$target_file"; then
    PATCH_STATUS[$idx]="already"
    continue
  fi

  echo "[ERROR] Patch cannot be applied cleanly: $patch_file"
  echo "        Please ensure target files are correct version (1.2.0)."
  echo "        If you have manually edited this file, patch context may not match."
  exit 1
done

TS="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$ROOT_DIR/backups/apply_$TS"
mkdir -p "$BACKUP_DIR"

echo "[INFO] Backing up target files to: $BACKUP_DIR"
for rel in "${REL_FILES[@]}"; do
  target="$(resolve_target "$rel")"
  if [[ ! -f "$target" ]]; then
    echo "[ERROR] Target file not found: $target"
    exit 1
  fi
  mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
  cp "$target" "$BACKUP_DIR/$rel"
done

echo "[INFO] Applying patches..."
for idx in "${!REL_FILES[@]}"; do
  rel="${REL_FILES[$idx]}"
  patch_file="$PATCH_DIR/${rel//\//__}.patch"
  status="${PATCH_STATUS[$idx]}"
  if [[ "$status" == "already" ]]; then
    echo "[SKIP] already applied: $rel"
    continue
  fi
  patch --batch --forward -p2 -d "$TMP_ROOT" -i "$patch_file" >/dev/null
  echo "[OK]   applied: $rel"
done

echo
echo "[DONE] Patch apply finished."
echo "       Backup location: $BACKUP_DIR"
echo "       Next step: reload VS Code window and restart debug session."
