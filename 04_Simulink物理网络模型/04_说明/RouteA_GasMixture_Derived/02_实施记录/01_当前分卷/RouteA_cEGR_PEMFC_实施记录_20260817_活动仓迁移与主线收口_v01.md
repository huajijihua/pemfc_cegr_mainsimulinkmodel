# Route A cEGR-PEMFC 活动仓迁移与两条主线收口

日期：2026-08-17  
类型：活动仓初始化与资产边界实施记录  
状态：迁移完成；后续模型行为验证和六配置矩阵研究未完成

## 1. 前置决策

- 当前规划：[RouteA_cEGR_PEMFC_两条主线与活动资产迁移规划_v01.md](../01_当前指导/RouteA_cEGR_PEMFC_两条主线与活动资产迁移规划_v01.md)
- 项目裁决：[RouteA_cEGR_PEMFC_模型裁决与资产处置_v01.md](../01_当前指导/RouteA_cEGR_PEMFC_模型裁决与资产处置_v01.md)
- 源仓：`E:\agentwork_pemfc_cEGR_0519`
- 活动仓：`E:\agentwork_pemfc_cEGR_main`
- 源仓基线：`d53c200`

## 2. 实际完成

1. 建立活动 Git 仓库 `E:\agentwork_pemfc_cEGR_main`，保留项目级 `AGENTS.md`、`.gitignore`、工具链配置和 `.satk` 复用配置。
2. 迁移完整系统 Route A 模型、聚焦模型、正式 runner/参数/观测/分析脚本、当前指导、当前实施记录、审计材料和与主线直接相关的结果。
3. 保留 `RouteA_GasMixture_Derived` 与 `RouteA_Cathode_cEGR_Focused` 结果目录及顶层 `outputs` 中已有有效结果；未把历史归档、旧交接材料和未参与当前主线的 FCEV 参考示例池纳入活动仓。
4. 在活动仓当前指导中固化 2×3 目标矩阵：V-SH、V-MH、E-SH 已有模型资产；E-MH、P-SH、P-MH 待建立。V-MH 的当前湿化模块明确标记为代理接口，E-SH 开启模式明确标记为 `not_validated`。

## 3. 结构与依赖验证

验证面：MATLAB MCP/SATK，MATLAB/Simulink R2025b。

- `routeA_project_paths()` 返回活动仓根目录及活动模型路径，路径未回指源仓。
- `routeA_check_dependencies(..., false)`：`passed=1`，错误数 0，警告数 0；`FuelCell_lib` 解析到 MATLAB 官方示例库。
- 活动仓完整系统模型和三个当前聚焦模型均可加载，`Dirty=off`。
- SATK `model_overview` 成功读回完整系统、V-MH、V-SH、E-SH 的高层结构；仅保留现有 Variant 相关警告。
- SATK `model_check` 状态均为 `warnings`，未显示错误严重度：完整系统 77 条、V-SH 63 条、E-SH 61 条。这些是既有模型警告，尚未因此宣称行为验证通过。
- 新仓初始提交为 `60d9e45`，随后提交 `1e75432` 移除误纳入 Git 的生成式报告缓存；当前 Git 跟踪文件不含 `slprj`、`.slxc`、`__pycache__` 或 `.pyc`。

## 4. 未完成与风险

- 本记录只证明活动资产边界和结构/依赖可读性，不证明任一模型已完成正式仿真、收敛或工程验证。
- `check_matlab_code` 未能执行：此前 MATLAB 会话中的 `restoredefaultpath` 移除了 MCP 辅助函数路径，导致 `matlab_mcp.mcpEval` 不可用；SATK 和 MATLAB MCP 的模型读取能力已恢复。后续应在不重置路径的干净 MATLAB 会话中补做脚本静态检查。
- 六配置矩阵中真实外部膜加湿器和主动循环泵模型仍缺失；不能用当前代理模块替代设备级结论。
- 源仓保持完整且未删除；活动仓排除项仍可通过源仓基线追溯。

## 5. 下一步

先收口完整系统面板的单工况回归和参数/观测契约，再以 V-SH/V-MH 建立可比基线；随后处理 E-SH 的 FuelCell 域初值问题，再实现主动泵和真实膜加湿器配置，最后统一进入 240 kW 参数匹配与场景研究。
