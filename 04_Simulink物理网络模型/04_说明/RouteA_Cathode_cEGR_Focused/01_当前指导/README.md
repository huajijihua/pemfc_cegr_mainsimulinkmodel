# Route A 阴极 cEGR 聚焦模型当前指导

本目录是 `RouteA_Cathode_cEGR_Focused` 聚焦模型主线的当前规划、架构裁决、实施方案和验证门真源；完整系统/平台共用指导仍保留在 `../../RouteA_GasMixture_Derived/01_当前指导/`。

## 当前入口

| 文件 | 用途 |
|---|---|
| `RouteA_Cathode_cEGR_Focused_模型边界与实施契约_v01.md` | 聚焦模型边界、接口、证据等级和统一 runner 契约 |
| `RouteA_cEGR_PEMFC_工程化架构决策与聚焦模型总体规划_v01.md` | 2×3 架构矩阵、官方模块原则和阶段准入 |
| `RouteA_cEGR_PEMFC_两种阀门被动式架构与控制边界裁决_v01.md` | 自增湿/外部膜加湿的气路与控制边界 |
| `RouteA_cEGR_PEMFC_两种阀门被动架构_聚焦模型改造实施方案_v01.md` | 阀门被动式聚焦模型的实施方案、验收门和 V-MH 当前收口 |
| `RouteA_cEGR_PEMFC_V-SH工程化建模约束与执行计划_v01.md` | V-SH 专项约束、验证和研究准入 |
| `RouteA_cEGR_PEMFC_模型A_240kW压力测点核对与流阻标定实施计划_v01.md` | 外部 240 kW 模型 A 的压力测点合同和流阻筛选边界 |
| `RouteA_cEGR_PEMFC_官方引射器模块审计与FuelCell域适配裁决_v01.md` | 引射器官方模块能力和 FuelCell 域适配边界 |
| `RouteA_cEGR_PEMFC_官方引射器被动式结构系统实施计划_v01.md` | 引射器聚焦配置的实施计划和验证门 |

## 实施记录

聚焦模型实施记录统一位于：

`../02_实施记录/01_当前分卷/`

其中包含 V-SH、V-MH、引射器配置和对应的参数/结果验证证据。当前 V-MH 正式模型为 `PEMFuelCellSystem_Cathode_cEGR_ExternalMembraneHumidifier_v01.slx`；其结论边界仍为 `behavior_verified_for_focused_scope_not_device_validated`。
