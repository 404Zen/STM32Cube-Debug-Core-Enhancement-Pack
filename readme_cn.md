# STM32Cube Debug Core Enhancement



**⚠️ 如果官方某一天更新了支持本仓库所实现的功能的新版本，那么本仓库自动作废。**



## 目录索引

### 文档入口
- 中文文档：[`readme_cn.md`](./readme_cn.md)
- English document：[`readme_en.md`](./readme_en.md)
- 补丁工作流：[`docs/PATCH_WORKFLOW.md`](./docs/PATCH_WORKFLOW.md)
- 补丁产物目录：[`patches/`](./patches)

### 脚本入口
- 检查目标扩展版本：[`scripts/check_target_versions.sh`](./scripts/check_target_versions.sh)
- 一键应用补丁（推荐）：[`scripts/apply_patches.sh`](./scripts/apply_patches.sh)
- 一键回滚到备份：[`scripts/rollback_last_apply.sh`](./scripts/rollback_last_apply.sh)
- 导出本地私有快照：[`scripts/private_export.sh`](./scripts/private_export.sh)
- 生成补丁文件：[`scripts/make_patches.sh`](./scripts/make_patches.sh)

### 项目侧配置示例
- 启动配置快照：[`Code_app/.vscode/launch.json`](./Code_app/.vscode/launch.json)

  

---

## 测试范围声明

- ✅ 使用 MacOS 测试通过

- ⚠️ Windows/Linux 未测试

- ✅ 仅在 JLink 调试链路下完成实测并通过。

- ⚠️ STLink 版本仅完成代码同步，尚未进行实机测试验证。

- 版本说明：
  - 改进包文档版本：`v1.1.0`（2026-03-14）
  
  - JLink 扩展版本（已实测）：`stmicroelectronics.stm32cube-ide-debug-jlink-gdbserver-1.2.0`
  
  - STLink 扩展版本（未实测）：`stmicroelectronics.stm32cube-ide-debug-stlink-gdbserver-1.2.0`
  
  - Debug Core 扩展版本：`stmicroelectronics.stm32cube-ide-debug-core-1.2.0`
  
    

---

## 能力概览

- 整数变量支持十进制/十六进制/二进制显示。

- 支持“按变量”切换进制（Variables/Watch 右键）。

- 切换后通过 DAP `InvalidatedEvent(["variables"])` 刷新。

  

---

## 小白一键部署（推荐）

> 你只需要执行下面 3 步，不用手工改文件。

### 第 1 步：打开终端并进入本目录

```bash
cd "/path/to/STM32Cube-Debug-Core-Enhancement-Pack"
```

### 第 2 步：检查扩展版本是否匹配

```bash
./scripts/check_target_versions.sh
```

看到版本为 `1.2.0`（JLink / STLink / Debug Core）即可继续。

### 第 3 步：一键应用补丁

```bash
./scripts/apply_patches.sh "/path/to/your/Code/app"
```

脚本会自动完成：
- 预检查（版本、补丁是否可应用）
- 自动备份原文件到 `backups/apply_时间戳/`
- 自动打补丁（已应用的会自动跳过）

### 第 4 步：让 VS Code 生效

1. 在 VS Code 执行 `Developer: Reload Window`
2. 重新启动调试

### 回滚（恢复）

⚠️此处建议卸载重装 VSCode 的 STM32CubeMX Debug 相关插件即可

如需撤销补丁，可直接执行：

```bash
./scripts/rollback_last_apply.sh "/path/to/your/Code/app"
```

默认会恢复 `backups/` 里最新一次 `apply_*` 备份。

如果想指定某次备份：

```bash
./scripts/rollback_last_apply.sh "/path/to/your/Code/app" "./backups/apply_20260314_123456"
```

回滚完成后，同样执行 `Developer: Reload Window` 并重启调试。



---

## 法务边界说明

- 本仓库 MIT License 仅覆盖仓库内自编写内容（文档/脚本/元数据）。
- 上游 ST 扩展文件及其改动副本应遵守原始许可证（见其 `LICENSE.txt` 与 SLA）。









