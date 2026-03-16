# STM32Cube Debug Core Enhancement



**⚠️ If the official version is updated to support the features implemented in this repository, this repository will be automatically deprecated.**



## Index

### Document Entry
- English document: [`readme.md`](./readme.md)
- 中文文档: [`readme_cn.md`](./readme_cn.md)
- Patch workflow guide: [`docs/PATCH_WORKFLOW.md`](./docs/PATCH_WORKFLOW.md)
- Patch artifacts folder: [`patches/`](./patches)

### Script Entry
- Check target extension versions: [`scripts/check_target_versions.sh`](./scripts/check_target_versions.sh)
- One-click patch apply (recommended): [`scripts/apply_patches.sh`](./scripts/apply_patches.sh)
- One-click rollback from backup: [`scripts/rollback_last_apply.sh`](./scripts/rollback_last_apply.sh)
- Export private local snapshot: [`scripts/private_export.sh`](./scripts/private_export.sh)
- Generate patch files: [`scripts/make_patches.sh`](./scripts/make_patches.sh)

### Native Windows Script Entry (PowerShell / bat)
- Check target extension versions: [`scripts/check_target_versions.ps1`](./scripts/check_target_versions.ps1) / [`scripts/check_target_versions.bat`](./scripts/check_target_versions.bat)
- One-click patch apply: [`scripts/apply_patches.ps1`](./scripts/apply_patches.ps1) / [`scripts/apply_patches.bat`](./scripts/apply_patches.bat)
- One-click rollback from backup: [`scripts/rollback_last_apply.ps1`](./scripts/rollback_last_apply.ps1) / [`scripts/rollback_last_apply.bat`](./scripts/rollback_last_apply.bat)
- Export private local snapshot: [`scripts/private_export.ps1`](./scripts/private_export.ps1) / [`scripts/private_export.bat`](./scripts/private_export.bat)

### Project-side example
- Launch config snapshot: [`Code_app/.vscode/launch.json`](./Code_app/.vscode/launch.json)

  

---

## Test Scope Statement

- ✅ Verified and passed MacOS

- ✅ Verified on Windows on my PC (2026-03-16)

- ⚠️ Pure Linux environment has not been fully regression-tested

- ✅ Verified and passed on the JLink debug path.

- ⚠️ STLink code is synchronized, but has not been validated on real hardware yet.

- Version Information:
  - Documentation/patch version: `v1.1.1` (2026-03-16)
  
  - JLink extension version (validated): `stmicroelectronics.stm32cube-ide-debug-jlink-gdbserver-1.2.0`
  
  - STLink extension version (not validated): `stmicroelectronics.stm32cube-ide-debug-stlink-gdbserver-1.2.0`
  
  - Debug Core extension version: `stmicroelectronics.stm32cube-ide-debug-core-1.2.0`
  
    

---

## Capability Overview

- Integer radix display: decimal / hexadecimal / binary.

- Per-variable radix switching (Variables/Watch context menu).

- UI refresh via DAP `InvalidatedEvent(["variables"])` after switching.

  

---

## Beginner One-Click Deployment (Recommended)

> You can deploy with only 3 commands, no manual file editing required.

### Step 1: Open terminal and enter this folder

```bash
cd "/path/to/STM32Cube-Debug-Core-Enhancement-Pack"
```

If you are using Windows, use native PowerShell:

```powershell
.\scripts\check_target_versions.ps1
.\scripts\apply_patches.ps1 -AppWorkspace "D:\path\to\Code"
```

Or run the bat wrappers directly:

```bat
scripts\check_target_versions.bat
scripts\apply_patches.bat -AppWorkspace "D:\path\to\Code"
```

### Step 2: Check version compatibility

```bash
./scripts/check_target_versions.sh
```

If extension directory auto-detection fails, set it explicitly:

```bash
export VSCODE_EXTENSIONS_DIR="/mnt/c/Users/<YourName>/.vscode/extensions"
./scripts/check_target_versions.sh
```

Proceed when JLink/STLink/Debug Core versions are `1.2.0`.

### Step 3: Apply patches in one command

```bash
./scripts/apply_patches.sh "/path/to/your/Code"
```

The script will automatically:
- validate compatibility and patch applicability
- back up original files to `backups/apply_timestamp/`
- apply patches (already-applied ones are skipped)

Notes:
- If your project `launch.json` has custom edits and patch context does not match, the script will skip `Code_app/.vscode/launch.json` and continue applying extension patches.
- During rollback, if that `launch.json` backup does not exist, it is skipped as well while extension files are restored.

### Step 4: Make VS Code reload changes

1. Run `Developer: Reload Window` in VS Code
2. Restart your debug session

### Rollback

**⚠️ It is recommended to uninstall and reinstall the STM32CubeMX Debug extensions for VSCode.**

To revert the patch, run:

```bash
./scripts/rollback_last_apply.sh "/path/to/your/Code"
```

It restores from the latest `backups/apply_*` directory by default.

To restore from a specific backup:

```bash
./scripts/rollback_last_apply.sh "/path/to/your/Code" "./backups/apply_YYYYMMDD_HHMMSS"
```

After rollback, run `Developer: Reload Window` and restart debug.



---

## Legal Boundary

- MIT license in this repository applies only to repository-authored files
  (docs/scripts/metadata).
- Upstream ST extension files and derivative full copies remain under original terms
  (see upstream `LICENSE.txt` / SLA).
