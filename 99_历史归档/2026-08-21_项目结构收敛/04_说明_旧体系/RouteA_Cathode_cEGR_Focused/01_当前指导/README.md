# 阴极 cEGR 聚焦模型当前指导索引

先读项目根目录 `PROJECT.md` 和聚焦脚本 `03_脚本/RouteA_Cathode_cEGR_Focused/README.md`。随后按任务只选一个专题指导：

| 任务 | 指导文件 |
|---|---|
| 聚焦模型公共边界、接口与 runner | `RouteA_Cathode_cEGR_Focused_模型边界与实施契约_v01.md` |
| 2×3 架构选择与阶段准入 | `RouteA_cEGR_PEMFC_工程化架构决策与聚焦模型总体规划_v01.md` |
| V-SH | `RouteA_cEGR_PEMFC_V-SH工程化建模约束与执行计划_v01.md` |
| V-MH / 两种阀门被动架构 | `RouteA_cEGR_PEMFC_两种阀门被动架构_聚焦模型改造实施方案_v01.md` |
| 外部 240 kW 压力与流阻 | `RouteA_cEGR_PEMFC_模型A_240kW压力测点核对与流阻标定实施计划_v01.md` |
| E-SH 引射器 | `RouteA_cEGR_PEMFC_官方引射器模块审计与FuelCell域适配裁决_v01.md`；进入结构实施时再读引射器实施计划 |

当前状态摘要：V-SH 为 `behavior_verified_for_focused_scope`；V-MH 为 `behavior_verified_for_focused_scope_not_device_validated`；E-SH 有模型资产但不得称为性能已验证；E-MH、P-SH、P-MH 未实现。详细数值证据只从 `../02_实施记录/01_当前分卷/` 读取目标主题最新记录。

较早指导中的状态若与根目录 `PROJECT.md` 冲突，以 `PROJECT.md` 为当前状态；具体物理方程、参数或验收门仍以目标专题指导和模型读回为准。
