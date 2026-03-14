#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKUPS_DIR="$ROOT_DIR/backups"

JLINK_ID="stmicroelectronics.stm32cube-ide-debug-jlink-gdbserver-1.2.0"
STLINK_ID="stmicroelectronics.stm32cube-ide-debug-stlink-gdbserver-1.2.0"

usage() {
  cat <<EOF
Usage:
  $(basename "$0") <app_workspace_path> [backup_dir]

Examples:
  $(basename "$0") /path/to/Code/app
  $(basename "$0") /path/to/Code/app "$BACKUPS_DIR/apply_20260314_123456"

Description:
  - Restore patched files from backup to original locations.
  - If [backup_dir] is not provided, the latest backups/apply_* directory is used.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
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

resolve_backup_dir() {
  local input="${1:-}"
  if [[ -n "$input" ]]; then
    if [[ -d "$input" ]]; then
      echo "$input"
      return 0
    fi
    if [[ -d "$ROOT_DIR/$input" ]]; then
      echo "$ROOT_DIR/$input"
      return 0
    fi
    echo "[ERROR] backup directory not found: $input" >&2
    exit 1
  fi

  if [[ ! -d "$BACKUPS_DIR" ]]; then
    echo "[ERROR] backups directory not found: $BACKUPS_DIR" >&2
    echo "        Run apply script first to generate backups." >&2
    exit 1
  fi

  local latest
  latest="$(find "$BACKUPS_DIR" -mindepth 1 -maxdepth 1 -type d -name 'apply_*' | sort | tail -n 1)"
  if [[ -z "$latest" ]]; then
    echo "[ERROR] no apply backup found in: $BACKUPS_DIR" >&2
    echo "        Run apply script first to generate backups." >&2
    exit 1
  fi

  echo "$latest"
}

REL_FILES=(
  "Code_app/.vscode/launch.json"
  "VSCodeExtensions/$JLINK_ID/package.json"
  "VSCodeExtensions/$JLINK_ID/lib/extension.js"
  "VSCodeExtensions/$JLINK_ID/lib/adapter/JLinkDebugTargetAdapter.js"
  "VSCodeExtensions/$STLINK_ID/package.json"
  "VSCodeExtensions/$STLINK_ID/lib/extension.js"
  "VSCodeExtensions/$STLINK_ID/lib/adapter/STLinkDebugTargetAdapter.js"
)

BACKUP_DIR="$(resolve_backup_dir "${2:-}")"

if [[ ! -d "$BACKUP_DIR" ]]; then
  echo "[ERROR] backup directory does not exist: $BACKUP_DIR"
  exit 1
fi

echo "[INFO] Restoring files from backup: $BACKUP_DIR"

for rel in "${REL_FILES[@]}"; do
  src="$BACKUP_DIR/$rel"
  if [[ ! -f "$src" ]]; then
    echo "[ERROR] backup file not found: $src"
    echo "        Backup may be incomplete or from a different workflow."
    exit 1
  fi

done

for rel in "${REL_FILES[@]}"; do
  src="$BACKUP_DIR/$rel"
  target="$(resolve_target "$rel")"
  mkdir -p "$(dirname "$target")"
  cp "$src" "$target"
  echo "[OK]   restored: $rel"
done

echo
echo "[DONE] Rollback finished."
echo "       Source backup: $BACKUP_DIR"
echo "       Next step: reload VS Code window and restart debug session."
