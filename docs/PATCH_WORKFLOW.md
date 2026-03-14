# Patch Workflow (Public-safe)

This folder provides a workflow to publish only patch artifacts, instead of redistributing full proprietary extension files.

## Recommended release strategy

1. Keep full modified extension files only in a private local folder (`private_snapshot/`, gitignored).
2. Generate `.patch` files from a clean baseline and your modified files.
3. Publish only:
   - `patches/*.patch`
   - docs/scripts/metadata in this repository
4. Do not publish full ST extension bundle files.

## Steps

## Quick Apply (Beginner)

If you already have this repository and just want to deploy patches locally:

```bash
./scripts/check_target_versions.sh
./scripts/apply_patches.sh /path/to/your/app/workspace
```

Then run `Developer: Reload Window` in VS Code and restart debug.

If you want to rollback quickly:

```bash
./scripts/rollback_last_apply.sh /path/to/your/app/workspace
```

Or rollback from a specific backup directory:

```bash
./scripts/rollback_last_apply.sh /path/to/your/app/workspace ./backups/apply_YYYYMMDD_HHMMSS
```

### A) Export your modified local files (private)

```bash
./scripts/private_export.sh /path/to/your/app/workspace
```

### B) Prepare clean baseline locally

Create another local folder with unmodified files (same extension versions).

### C) Generate patch files

```bash
./scripts/make_patches.sh /path/to/clean /path/to/modified ./patches
```

### D) Verify target versions before applying patch

```bash
./scripts/check_target_versions.sh
```

## Version scope

- Targeted extension versions:
  - `stmicroelectronics.stm32cube-ide-debug-jlink-gdbserver-1.2.0`
  - `stmicroelectronics.stm32cube-ide-debug-stlink-gdbserver-1.2.0`
  - `stmicroelectronics.stm32cube-ide-debug-core-1.2.0`

## Notes

- If upstream extension versions change, patch offsets may fail and must be regenerated.
- Keep legal notices of upstream projects intact when using generated patches.
