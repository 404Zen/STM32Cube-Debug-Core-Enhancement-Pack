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

### Project-side example
- Launch config snapshot: [`Code_app/.vscode/launch.json`](./Code_app/.vscode/launch.json)

  

---

## Test Scope Statement

- ✅ Verified and passed MacOS

- ⚠️ Windows/Linux NOT Verified

- ✅ Verified and passed on the JLink debug path.

- ⚠️ STLink code is synchronized, but has not been validated on real hardware yet.

- Version Information:
  - Documentation/patch version: `v1.1.0` (2026-03-14)
  
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
cd "/path/to/STM32CubeMXDebugCore improve"
```

### Step 2: Check version compatibility

```bash
./scripts/check_target_versions.sh
```

Proceed when JLink/STLink/Debug Core versions are `1.2.0`.

### Step 3: Apply patches in one command

```bash
./scripts/apply_patches.sh "/path/to/your/Code/app"
```

The script will automatically:
- validate compatibility and patch applicability
- back up original files to `backups/apply_timestamp/`
- apply patches (already-applied ones are skipped)

### Step 4: Make VS Code reload changes

1. Run `Developer: Reload Window` in VS Code
2. Restart your debug session

### Rollback

**⚠️ It is recommended to uninstall and reinstall the STM32CubeMX Debug extensions for VSCode.**

To revert the patch, run:

```bash
./scripts/rollback_last_apply.sh "/path/to/your/Code/app"
```

It restores from the latest `backups/apply_*` directory by default.

To restore from a specific backup:

```bash
./scripts/rollback_last_apply.sh "/path/to/your/Code/app" "./backups/apply_20260314_123456"
```

After rollback, run `Developer: Reload Window` and restart debug.



---

## Legal Boundary

- MIT license in this repository applies only to repository-authored files
  (docs/scripts/metadata).
- Upstream ST extension files and derivative full copies remain under original terms
  (see upstream `LICENSE.txt` / SLA).
