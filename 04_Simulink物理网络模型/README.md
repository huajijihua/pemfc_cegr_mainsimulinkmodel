# Route A MATLAB/Simulink 工作树

项目当前状态、正式资产、证据等级和阅读路由统一见根目录 [`PROJECT.md`](../PROJECT.md)。本文件只说明目录职责，避免复制阶段状态。

| 目录 | 职责 |
|---|---|
| `01_模型/RouteA_GasMixture_Derived/` | 完整系统/面板主线正式模型与默认参数资产 |
| `01_模型/RouteA_Cathode_cEGR_Focused/` | 聚焦主线正式模型、引射器测试资产和库 |
| `02_结果/` | 研究结果与报告；原始时序默认本地保存，紧凑证据优先进入 Git |
| `03_脚本/RouteA_GasMixture_Derived/` | 完整系统统一 runner、面板入口、参数/观测/结果契约和测试 |
| `03_脚本/RouteA_Cathode_cEGR_Focused/` | 聚焦模型统一 runner、case、参数桥和 KPI |
| `04_说明/README.md` | 两条活动主线的当前工程契约 |
| `../99_历史归档/` | 已退出活动链的旧说明、实施记录、审计研究和汇报资产 |

正式运行入口：

- 完整系统：`03_脚本/RouteA_GasMixture_Derived/run_routeA_electrical_boundary_study.m`
- 聚焦模型：`03_脚本/RouteA_Cathode_cEGR_Focused/run_routeA_focused_study.m`
- 完整系统面板：`03_脚本/RouteA_GasMixture_Derived/launch_routeA_panel.m`

新工况使用配置和 `Simulink.SimulationInput`，不复制模型或 runner。缓存、完整日志和临时导出不作为项目状态证据。
