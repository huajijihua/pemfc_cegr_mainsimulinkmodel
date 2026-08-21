# Route A 活动脚本入口

本目录保持平铺，避免破坏既有 scriptDir/../.. 相对路径。当前活动链包含 P0 平台入口、一个正式研究 runner、通用辅助脚本和一个 MATLAB unittest 入口；不按 Current/Power/Voltage、负载或研究工况复制脚本。

本目录中的脚本不按边界、负载或策略复制。当前工程边界见 `../../04_说明/README.md`；活动运行链为 cold-start-only，历史热启动 bundle 不是 runner 前置。

## 正式核心

| 分类 | 活动入口 | 职责 |
|---|---|---|
| 输入装配 | routeA_build_electrical_boundary_cases.m、routeA_normalize_electrical_profile.m、routeA_prepare_electrical_boundary_input.m | 组装单一电边界、气路、cEGR、热和控制输入；不运行模型计算。 |
| 仿真调度 | run_routeA_electrical_boundary_study.m | 统一 runner；支持 Current、Power、Voltage 分开执行，以及 serial/parsim 调度；长时间正式矩阵仍按 S5 门槛推进。 |
| 结果审计 | routeA_assess_electrical_boundary_outputs.m、routeA_stage1_cathode_gas_closure_from_outputs.m、routeA_stage1_water_ledger_from_outputs.m | 提取电边界、气相闭合、cEGR、设备控制和水账本 KPI。 |
| 初态维护 | 旧仓备份中的历史 helper | 仅审计已退役的 Current/Power/Voltage 热启动资产；活动 panel/runner 固定 cold-start-only。 |
| 共享读回 | routeA_block_paths.m、routeA_simscape_log_mea.m、routeA_stack_electrical_power_timeseries.m、routeA_restore_model_and_folder.m | 提供模型路径、Simscape log、功率时序和环境恢复辅助。 |
| 输入规范 | routeA_simCase_template.m | 返回标准化 simCase 结构体模板（含所有默认值），用于统一研究输入格式。 |

## P0 平台入口与契约

| 分类 | 活动入口 | 职责 |
|---|---|---|
| 路径解析 | routeA_project_paths.m | 根据自身文件位置返回可迁移工程、模型和脚本路径。 |
| 启动与依赖 | launch_routeA_panel.m、routeA_check_dependencies.m | 从外部当前目录启动面板并在运行前检查 MATLAB、Simulink、Simscape、FuelCell_lib 和核心资产。 |
| 参数注册 | routeA_parameter_registry.m | 登记当前 active 参数和 platform_default inventory 参数；未通过开放门槛的参数不进入 UI。 |
| 观测注册 | routeA_observation_registry.m、routeA_validate_observation_output.m | 区分 logsout、SimulationOutput、unresolved 信号并执行结果读回。 |
| 模型契约 | routeA_model_contract.m | 读回模型 block path、Model Workspace、profile schema 和初态状态。 |

历史 v10 bundle 曾支持 Current/Power/Voltage 分支生成和提升，但相关 helper 与 MAT 不在活动仓运行链中。当前输入装配只接受 cold-start-only。

每个 case 进入 `sim`/`parsim` 前必须完成 `routeA_electrical_boundary_preflight`：cold 初态、气路/电堆控制、计算类型、求解器、逻辑起点和统计窗均被记录；稳态默认使用最后 60 s 的时间加权平均并以 0.5% 半窗变化门验收。瞬态默认保留完整 `SimulationOutput` 时序，显式关闭时 runner 拒绝执行。活动 runner 的 `StartTime`、逻辑研究时间和初始化时间均为 0 s，并显式关闭 `LoadInitialState`。

活动 runner 不提供热启动或 operating-point 选择分支。所有 panel/runner case 固定使用 `initializationPolicy="cold_start_only"`，不读取 `RouteA_platform_default_initial_state.mat`；cold Current/Power 由零负载 ramp 建立供气，Voltage 从平台电压启动参考开始建立。正式 v10 bundle 及其 checksum 只用于历史审计和对比。

## 验证与兼容

RouteACegrValveConstitutiveTest.m 是唯一正式 cEGR 阀构成测试入口，使用 MATLAB runtests。run_routeA_platform_demo.m 只是兼容薄 wrapper：复用统一 runner 装配 10 s nominal demo，并保留 routeA_platform_demo_summary base 输出；它不得用于正式矩阵、敏感性分析或参数标定。

S3 Power/Voltage 矩阵、Phase B 回归和 P8 热管理阶段 runner 已移入 `99_历史归档/2026-08-21_项目结构收敛/03_脚本_阶段性runner/`。历史复现时按需读取；新研究统一通过 `run_routeA_electrical_boundary_study` 的 case/profile 配置完成，不再派生阶段 runner。
