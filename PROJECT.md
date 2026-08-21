# PEMFC-cEGR 当前项目真源

更新日期：2026-08-21
用途：给人和 agent 提供最小、当前、可路由的项目状态。公共工程边界见 `04_Simulink物理网络模型/04_说明/README.md`；历史实施和专题审计只在追溯时从 `99_历史归档/` 读取。

## 1. 当前决策

本仓有两条活动主线：

1. 完整系统/面板：维护官方 Gas Mixture PEMFC 派生系统、统一输入与结果契约、参数开放和可信性闭环。
2. 聚焦模型：优先推进工程性更强的阴极回路 + 电堆模型，包括车载 `湿化方式 × 回流驱动方式` 2×3 架构矩阵，以及一个待用户提供结构定义的阀门被动式台架扩展模型。

车载六配置与台架扩展共七个目标配置，不代表全部实现。V-SH 是当前候选核心参考模型，但必须完成新一轮结构、参数和代表工况闭环后才能冻结为架构派生基准。`platform_default`、`scaling_rule`、`external_case`、`bench_case`、`study_command` 和 `result_audit` 必须分层；外部 240 kW 数据属于 `external_case`。

## 2. 活动资产与当前状态

| 主线/配置 | 正式资产 | 正式入口 | 当前证据状态 |
|---|---|---|---|
| 完整系统/面板 | `04_Simulink物理网络模型/01_模型/RouteA_GasMixture_Derived/PEMFuelCellSystem_GasMixture_cEGR_RouteA_v01.slx` | `04_Simulink物理网络模型/03_脚本/RouteA_GasMixture_Derived/run_routeA_electrical_boundary_study.m`；面板入口 `launch_routeA_panel.m` | 结构已实现并读回；2026-08-18 完成 10 s 单工况烟测；观测单位元数据和液态水闭合未完成，因此不是整机工程验证通过 |
| V-SH 车载阀门被动/自增湿 | `.../RouteA_Cathode_cEGR_Focused/PEMFuelCellSystem_Cathode_cEGR_SelfHumidifying_v01.slx` | `.../RouteA_Cathode_cEGR_Focused/run_routeA_focused_study.m` | `candidate_reference_behavior_verified_for_focused_scope`；已有 V0-V6、矩阵和审计报告，但冻结前仍需重新核对结构、参数链、代表工况和失败边界 |
| V-MH 车载阀门被动/外部膜加湿 | `.../RouteA_Cathode_cEGR_Focused/PEMFuelCellSystem_Cathode_cEGR_ExternalMembraneHumidifier_v01.slx` | 同一聚焦 runner | `implemented_incomplete`；正式模型已存在，但双侧传质/传热、测点、水量/能量账本和参数来源尚未闭环，不得标为完成或设备验证 |
| E-SH 车载引射器被动/自增湿 | `.../RouteA_Cathode_cEGR_Focused/PEMFuelCellSystem_Cathode_cEGR_Ejector_SelfHumidifying_v01.slx` | 同一聚焦 runner | `prototype_incomplete`；模型、组件库和测试资产存在，仍需完成引射器构成、压力/流量/效率证据和系统级代表工况闭环 |
| E-MH 车载引射器被动/外部膜加湿 | 尚无正式活动模型 | 同一聚焦 runner | `not_implemented` |
| P-SH 车载循环泵主动/自增湿 | 尚无正式活动模型 | 同一聚焦 runner | `not_implemented` |
| P-MH 车载循环泵主动/外部膜加湿 | 尚无正式活动模型 | 同一聚焦 runner | `not_implemented` |
| V-Bench 阀门被动/台架 | 尚无正式活动模型 | 原则上复用同一聚焦 runner | `specification_pending`；等待用户提供台架结构，实验标定数据由实验团队后续提供 |

表中 `...` 均从 `04_Simulink物理网络模型/01_模型` 或 `03_脚本` 续接。`PEMFuelCellSystem_Cathode_cEGR_Focused_v01.slx` 是聚焦接口基线，不作为额外架构成果计数；组件测试模型和库同样不计作目标配置。

## 3. 每类任务只读哪些文件

| 任务 | 默认读取 |
|---|---|
| 项目状态、下一步或资产定位 | `AGENTS.md` + 本文件 |
| 任一模型结构、保真度或工程边界 | 再读 `04_Simulink物理网络模型/04_说明/README.md` |
| 完整系统代码、参数、runner 或面板 | 再读系统脚本 `README.md` 和目标文件 |
| 聚焦模型代码、参数或研究 | 再读聚焦脚本 `README.md` 和目标文件 |
| V-MH 车载阀门被动膜加湿模型实施 | 再读 `04_Simulink物理网络模型/04_说明/聚焦模型执行计划/RouteA_V-MH_车载阀门被动膜加湿模型执行计划_v01.md` |
| E-SH 车载引射器自增湿模型实施 | 再读 `04_Simulink物理网络模型/04_说明/聚焦模型执行计划/RouteA_E-SH_车载引射器自增湿模型执行计划_v01.md` |
| P-SH 车载循环泵自增湿模型实施 | 再读 `04_Simulink物理网络模型/04_说明/聚焦模型执行计划/RouteA_P-SH_车载循环泵自增湿模型执行计划_v01.md` |
| 历史结论、数值来源或决策演变 | 从 `99_历史归档/2026-08-21_项目结构收敛/` 只读目标主题原文件 |
| 文献或外部案例 | 读取目标一手来源；必要时再查归档的外部案例索引 |

活动任务不默认读取归档。旧文档与本文件冲突时，本文件定义当前状态；具体物理边界以当前工程契约和模型读回为准。

## 4. 执行合同

- 完整系统工况统一使用 `run_routeA_electrical_boundary_study.m`；聚焦配置统一使用 `run_routeA_focused_study.m`。
- 研究顺序：最小基线 → 一个代表性 case → 单因素诊断 → 必要矩阵。批量运行前固定输入、单位、solver、停止时间、KPI、失败分类和结果目录。
- 新工况使用 case/profile/`SimulationInput`，不新增模型或 runner。只有架构物理边界不同且经过裁决时才新增正式 `.slx`。
- MATLAB 会话首次握手结果应在对话中报告，不为每次小调用重复探测或生成会话报告。
- 正式 `.slx` 结构操作不允许降级到核心 MATLAB MCP。按 `AGENTS.md` 完成 `matlab`/`satk` 同 PID 握手后，使用 SATK 完成结构读写和检查；随后仍需 update/compile、最小运行、诊断检查和 `Dirty=off`。

## 5. 证据与产物保留

Git 默认保留：正式 `.slx`、`.m`、必要输入、紧凑 JSON/CSV/Markdown KPI、关键报告和明确裁决的里程碑证据。

本地临时保留但不新增到 Git：原始 `.mat` 时序、完整日志、预览/检查缓存、`slprj/`、`.slxc` 和可重建的批量输出。里程碑若必须提交原始结果，应在 `PROJECT.md` 中说明唯一用途、模型/runner 版本、case、KPI 和为何紧凑摘要不足。

2026-08-21 用户已删除本次结构收敛中隔离的 77 个历史/原始 MAT 和可重建缓存。活动结果目录保留紧凑证据、当前工作簿和图片；后续原始 MAT 若有复现或审计价值可以继续保存。

## 6. 资产增长门

项目不以磁盘体积作为主要限制，而以活动资产职责和入口数量作为门禁：

通用的新建、读取、收口和归档原则见 `AGENTS.md` 的“可复用工程项目资产治理基线”；本节只记录 PEMFC-cEGR 的项目专属阈值。

| 对象 | 活动区门限 | 处理原则 |
|---|---:|---|
| 根目录 Markdown | 2 | 只允许 `AGENTS.md`、`PROJECT.md` |
| `04_说明` Markdown | ≤5，当前目标 4 | 一个公共工程契约 + 三个独立模型执行计划；普通专题历史进统一归档 |
| 完整系统 `.slx` | 1 | 工况、控制和参数变化不得复制模型 |
| 聚焦模型 `.slx` | ≤12 | 容纳七个目标配置、公共基线及最小组件测试/库；只为已裁决的独立物理架构新增 |
| 活动 `run_*.m` | ≤10 | 两个正式研究入口优先；阶段 runner 收口后归档 |
| 活动结果 MAT | >100 触发审查 | 有复现/审计价值可保留，不自动删除 |
| 单个运行目录 MAT | >50 触发审查 | 检查是否应形成紧凑摘要或合并重复失败产物 |

只读检查命令：

```powershell
& '.\04_Simulink物理网络模型\03_脚本\check_project_hygiene.ps1'
```

输出 `PASS` 表示硬门禁通过；缓存和结果数量属于告警。需要把告警也作为 CI 失败时使用 `-Strict`。

## 7. 已知环境与迁移事项

- 旧说明体系和汇报资产已归档到 `99_历史归档/2026-08-21_项目结构收敛/`。归档默认只读，不是活动运行依赖。
- 2026-08-21 已用 MathWorks 官方安装器重建 Simulink Agentic Toolkit 2026.08.19 和 MATLAB MCP Server v0.12.0；项目 `.codex/config.toml` 采用全局 `matlab=new` + 项目 `satk=existing` 双通道。安装检查、8 个 `model_*` 入口、项目配置和 Codex MCP 注册均已静态验收；本任务启动早于配置生成，重启 Codex 或新建任务后仍须完成一次两通道同 PID 的动态验收。
- 当前最重要的工程缺口仍是：V-SH 参考基准尚未冻结；V-MH 工程闭环未完成；E-SH 仍为原型；E-MH、P-SH、P-MH 尚未实现；台架模型等待结构定义且后续标定依赖实验数据。完整系统主线暂后置。

## 8. 当前聚焦任务

V-SH 作为三个任务的共同参考，执行前必须先核对其结构、共有参数和代表工况；不再维护泛化的七配置总计划。当前核心实施由三份按目标模型读取的独立计划覆盖：

- V-MH：完善现有阀门被动/膜加湿正式模型。
- E-SH：把现有引射器原型和组件资产提升为可执行架构。
- P-SH：从冻结 V-SH 派生唯一的循环泵主动/自增湿正式模型。

普通项目进入和非对应模型任务不读取上述计划。计划路径见第 3 节路由表；阶段状态变化只更新配置状态表和对应计划。
