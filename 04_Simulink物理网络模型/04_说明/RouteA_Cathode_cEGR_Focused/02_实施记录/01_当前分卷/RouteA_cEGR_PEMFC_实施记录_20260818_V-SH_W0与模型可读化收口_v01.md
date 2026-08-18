# V-SH W0 与模型可读化收口

## 前置决策

- `04_Simulink物理网络模型/04_说明/RouteA_GasMixture_Derived/01_当前指导/RouteA_cEGR_PEMFC_V-SH工程化建模约束与执行计划_v01.md`
- `04_Simulink物理网络模型/04_说明/RouteA_Cathode_cEGR_Focused/01_当前指导/RouteA_Cathode_cEGR_Focused_模型边界与实施契约_v01.md`
- `04_Simulink物理网络模型/04_说明/RouteA_GasMixture_Derived/01_当前指导/RouteA_cEGR_PEMFC_模型裁决与资产处置_v01.md`
- `04_Simulink物理网络模型/04_说明/RouteA_GasMixture_Derived/01_当前指导/RouteA_cEGR_PEMFC_仿真工具链与协同接口约束_v01.md`

## 实际完成

正式模型：`04_Simulink物理网络模型/01_模型/RouteA_Cathode_cEGR_Focused/PEMFuelCellSystem_Cathode_cEGR_SelfHumidifying_v01.slx`

1. 通过当前 Codex 会话暴露的 MATLAB MCP/SATK 读取和修改正式模型；MATLAB R2025b、Simulink、Simscape 与 Simulink Test 能力可用，未使用 `matlab -batch`、GUI 宏或其他客户端会话替代执行。
2. 将根级散件收敛为 8 个有明确职责的功能容器：
   - `Cathode_Air_Supply_and_cEGR`；
   - `Cathode_Inlet_Instrumentation`；
   - `PEMFC_Stack_Core`；
   - `Cathode_Exhaust_and_Backpressure`；
   - `Simplified_Anode_Boundary`；
   - `Fixed_Stack_Temperature_Boundary`；
   - `Control_and_Result_Observability`；
   - `cEGR_Return_Route_Selector`。
3. 使用 `Simulink.BlockDiagram.createSubsystem` 将阴极入口测量、简化阳极边界和固定电堆温度边界分别归组；保持原有官方物理组件与连接，不复制模型或 runner 表达新结构。
4. 修复 `Cathode_Exhaust_and_Backpressure` 中排气流量、cEGR 回流流量和出口压力经根级输出再反馈到同一子系统的间接自反馈链：传感器转换器现直接连接内部观测器，根级只保留对外结果输出。
5. 早期可读化阶段删除仅用于暴露但无消费者的物理信号边界端口及临时禁用的外部 `MIn/TIn` 边界端口；后续逐端口审计将实际需要的 `MIn/TIn` 统一重建为具名、零侧源的标准 `Constant -> Simulink-PS Converter` 链。全过程未向气体、热或物理信号端口添加 Terminator、临时 Cap 或无依据方程；阴极腔辅助口的官方 Cap 是既有物理边界，审计发现其真实断线后才恢复原连接。
6. 完成根级与主要子系统的端口、信号和模块语义命名。主要结果接口明确为 `cegr_return_mdot_kg_s`、`exhaust_mdot_kg_s`、`ca_out_p_Pa`、`ca_out_T_K`、`ca_out_RH`、`ca_out_y` 和 `gas_phase_water_excess_L2`；其中 `gas_phase_water_excess_L2` 明确限定为气相饱和超额诊断，不代表分离液水存量。
7. 更新根级路线说明和 7 个主要功能子系统的简要注释，说明模块职责、输入输出与被移除的阳极/热管理 BOP 边界；重新布置根级容器并路由连线，形成左至右的空气—入口测量—电堆—排气主气路、排气—选择器—压气机入口 cEGR 回路，以及下方阳极、热边界和控制观测区域。
8. `Control_and_Result_Observability` 内部复用已存在的排气流量输入，删除重复诊断输入。W0 首次编译发现父层与 `Cathode_cEGR_Control` 内层的 3 个诊断 `ToWorkspace` 使用相同变量名；已删除父层冗余记录和冗余控制误差/阀门命令输出。控制器内部保留唯一的控制误差、比值、面积和阀门命令记录；比值输出仅保留给父层 `RouteA_Display_EGR_Ratio`，其连线具有 `Name` 与 `DataLoggingName` 均为 `routeA_egr_ratio_comp_in`、`DataLogging=on` 的正式 logsout 契约。该修改不涉及物理端口终结。
9. 读回并确认 V-SH 主要模型变量各自具有单一、可追踪的模型使用点。正式参数桥新增缺失的 `focused_cathode_inlet_temperature_C`、`cathode_channel_laminar_fraction` 写点，并将 V-SH 模型写点收敛为 24 个；`self_humidifying` 不再写入 15 个仅适用于引射器架构的变量。
10. 更新正式 runner 和共享读回脚本：
    - `run_routeA_focused_study.m` 仅在 `ejector_self_humidifying` 模型中写入引射器变量；
    - `routeA_focused_parameter_bridge.m` 按架构生成实际 `modelWritePoints`；
    - `routeA_block_paths.m` 同时支持完整系统旧层级和 V-SH 新语义层级；
    - 压力、水相观察和 MEA Simscape log 读取适配新的功能容器及模块名称。
11. 正式模型已通过 MATLAB `save_system` 写盘，保存后 `Dirty=off`。

## 验证证据

- `model_read(root)`：根级只剩上述 8 个功能容器；主气路、cEGR 回路、阳极边界、热边界、电气边界和观测信号的连接清单均已读回。
- `model_read` 子系统读回：
  - `Cathode_Inlet_Humidity_Sensor_FC.W -> inlet_relative_humidity`；
  - `Cathode_Inlet_Mass_Flow_Sensor_FC.M_i -> inlet_species_mdot`；
  - cEGR 与排气质量流量转换器直接进入 `CathodeOutlet_Observability`；
  - 出口压力 Pa 信号经 `1e-6` 增益后以 MPa 进入 L2 气相超额观察器，输出端仍保持 Pa。
- `model_check(root, ["unconnected_lines"])`：healthy，无悬空信号线。
- `model_check(root, ["all"])`：当前返回 55 条 `unconnected_port` warning，较修改前 59 条减少 4 条。`model_read` 显示其中相关 A/H/B、传感器和 Connection Port 存在连接，但这不足以证明每个端口的物理契约正确；55 条均改列为待逐项裁决的 V-SH 结构问题。本轮未通过改变物理拓扑掩盖这些工具告警。
- MATLAB `set_param(model,'SimulationCommand','update')`：成功，模型编译更新约 18 s；`LASTWARN_ID` 和 `LASTWARN_MSG` 均为空。
- 共享路径与参数桥读回：新层级 12 个关键路径均可由 `getSimulinkBlockHandle` 解析；V-SH `modelWritePoints=24`、`ejector_*` 写点数为 0、`focused_cathode_inlet_temperature_C` 写点数为 1。
- MATLAB Code Analyzer：`run_routeA_focused_study.m` 和 `routeA_block_paths.m` 无问题；参数桥仅保留 1 条循环中扩展 mapping 的性能提示，不是运行 warning 或模型 warning。
- MATLAB `save_system`：`SAVE_OK=1`，正式文件路径正确，保存后 `Dirty=off`，`LASTWARN_ID` 和 `LASTWARN_MSG` 均为空。
- 首次当前版本 W0 调用的范围为 `self_humidifying`、Current 5 A、cEGR 目标/profile 0、模型时间 120 s、尾窗 `[90,120]`。正式 runner 正常返回，但在生成 `SimulationInput` 时由 `validateStudy` 阻止，错误为 `RouteA:ElectricalBoundarySteadyWindow`：默认 `steadyWindowDuration_s=60` 大于 30 s 尾窗。因此该次调用**没有进入 `sim`**，不能作为当前保存模型的行为验证或 warning-zero 运行证据。
- W0 后续根因—修复—读回：
  - 显式设置 `steadyWindowDuration_s=30` 后，`sim` 可执行，但遇到 `Simulink:Logging:DupDataLogVarName2`；根因是父层与控制器内层的同名诊断 `ToWorkspace`。删除父层冗余 3 条记录和不再被外部消费的 2 个输出后，`model_read` 确认内层仍有唯一记录，`model_check(blk_910,["all"])` 为 healthy。
  - 随后正式仿真完成但评估器报 `RouteA:ElectricalBoundaryMissingSignal`；根因是重新建立的 `routeA_egr_ratio_comp_in` Display 连线未携带原有 DataLogging 属性。对照已工作的 `routeA_egr_valve_area_cmd` 连线后，恢复 `Name=routeA_egr_ratio_comp_in`、`DataLogging=on`、`DataLoggingName=routeA_egr_ratio_comp_in`；参数读回正确，控制子系统再次为 healthy。
- 最终 V-SH-W0 正式 smoke：`run_routeA_focused_study`，`self_humidifying`、Current 5 A、cEGR target/profile 0、`researchDuration_s=120`、尾窗 `[90,120]`、`steadyWindowDuration_s=30`、冷启动、前台 serial、`SimulationInput -> sim -> routeA_focused_assess_outputs`。结果：`MATRIX_COMPLETE=1`、`SIM_COMPLETED=1`、`CASE_PASSED=1`、`STUDY_PASSED=1`、`STOP_EVENT=ReachedStopTime`；`LASTWARN_ID`/`LASTWARN_MSG` 为空，`SimulationMetadata.ExecutionInfo.WarningDiagnostics=0`。该证据表明正式 runner 的该单工况执行与既有行为判据通过，不构成物理机理或工程性能验证。
- 最后根级复查：`model_check(root,["all"])` 初始仍为 55 条 SATK `unconnected_port` warning；该计数没有被解释为工具误报，正式模型 `save_system` 成功，`Dirty=off`，保存无 MATLAB warning。

### SATK 55 条结构告警 owner ledger

| Owner scope | 块与端口类别 | 条数 | 读回与处置 |
|---|---|---:|---|
| `Cathode_Air_Supply_and_cEGR` | `cEGR_Return_Pipe_FC` A/H/B/MIn/TIn；上、下游 PT 传感器各 A/P/T/B | 13 → 0 | 已闭环。官方源码表明 `Pipe (FC)` 的 `MIn/TIn` 用于外部反应/分离侧源；V-SH 回流管无此物理过程，故用标准 Simulink-PS 物理信号链显式输入零物种质量流及 `env_T + 273.15` K 的零侧源参考温度。官方 PT 传感器的 `T` 为相对绝对参考的气体温度，已接入 K 温度观测/记录链。`model_check(blk_667)` healthy，W0 回归记录有效。 |
| `Cathode_Exhaust_and_Backpressure` | 出口湿度传感器、排气/回流质量流量传感器、排气边界管路；阴极腔辅助 Cap | 19 + 2 → 0 | 已闭环。官方 `CompHumSensor` 的 `x_i/y_i/W` 和 `MassEnergyFlowSensor` 的 `M/Phi_out/M_i` 均为有效测量输出，现由 `Exhaust_Flow_and_Composition_Diagnostics` 具名消费和记录；排气管 `MIn/TIn` 已按无外部反应/分离边界显式化。审计额外发现既有 `Cap (FC)` 到辅助跨层端口的物理线真实缺失；官方 Cap 是无质量/能量流的 chamber B 端部边界，已恢复连接。`model_check(blk_810)` healthy，W0 回归记录有效。 |
| `Cathode_Inlet_Instrumentation` | 入口湿度传感器、入口质量流量传感器 | 9 → 0 | 已闭环。官方传感器契约已确认 A/B 为不改变气体状态的理想测量网络；原有 RH/物种流量记录有效，新增质量/摩尔组分、总质量流和能量流均纳入现有 `Inlet_Result_Observability` 的具名消费者。`model_check(blk_1184)` healthy，W0 回归记录有效。 |
| `PEMFC_Stack_Core` | `Cathode_Outlet_Chamber_FC` MIn/TIn/A/B/C/pC/TC/yC_i/H | 9 → 0 | 已闭环。官方三端 `Chamber` 源码确认 A/B/C 是气体端口、pC/TC/yC_i/H 已有跨层观测/热消费者；`MIn/TIn` 是外部反应/分离侧源。V-SH 不含该侧源，已显式接入零四组分质量流和 `env_T + 273.15` K 参考温度。`model_check(blk_869)` healthy。 |
| `Simplified_Anode_Boundary` | `Anode_Outlet_Pipe_FC` A/H/B/MIn/TIn | 5 → 0 | 已闭环。官方 Pipe 契约确认 A/H/B 为气体/热网络、`MIn/TIn` 为外部反应/分离侧源。简化阳极不含该过程，已显式接入零四组分质量流和 `focused_anode_boundary_T_C + 273.15` K 参考温度。`model_check(blk_1176)` healthy。 |
| **当前合计** |  | **0** | 原 55 条与审计额外发现的 2 条真实 Cap 断线均完成逐端口官方依据、最小物理修复、结构读回与 W0 回归；根级无 SATK error、无结构 warning、无悬空普通信号线。 |

该 ledger 已完成。每一条均先完成官方接口、跨层连接、物理语义和消费者审计，再按证据修复；没有使用 Terminator、临时 Cap 或无依据自建方程掩盖物理端口。

## 未决风险与范围

- 当前保存版本的 W0 cold-start smoke 已在每一轮 owner 修复后回归，最终范围仍仅限 Current 5 A、cEGR=0、120 s；不能外推为其他负荷、cEGR 比例、稳态充分性、耐久性或工程性能结论。
- 原 55 条 SATK 结构 warning 以及审计中新增发现的 2 条实际 Cap 断线均已清零。`model_check(root,["all"])` healthy；正式 runner 的编译/运行/日志 warning 为零。
- 官方 `Pipe (FC)`/Chamber 的 `MIn/TIn` 是外部反应或分离侧源端口。cEGR、排气、阴极腔和简化阳极出口均已使用有物理依据的零侧源链条显式化；温度支路均采用 °C→K 的明确转换。
- SATK 调用内部仍打印 `find_system` 的 future-compatibility 提示；这是 SATK 实现的控制台提示而非本模型诊断，未计入 `model_check` 结果。若目标包含该工具提示亦为零，下一步是单独修补 SATK 的 variants 过滤调用。
- 本轮完成的是 V-SH 架构可读性、接口语义和执行链修复，不构成物理机理、工程可行性或性能指标验证。

## 状态

模型可读化、功能分组、主要回路语义和 V-SH 参数写入链已经实现、读回、编译并保存。V-SH-W0 的正式 120 s smoke 已五次执行并通过；最终 `model_check(root,["all"])` healthy，结构/编译/运行/日志 warning 均为零。原 55 条和额外 2 条实际 Cap 断线均已按物理语义闭环，V-SH-W0 完全收口；不构成物理机理、工程可行性或性能指标验证。

## 2026-08-18 续：供气/阀门 owner 的根因、修复与回归

1. 根因定位与依据：`PortConnectivity` 读回确认回流管 `MIn/TIn`、阀前/阀后 PT 传感器 `T` 均没有实际连接；另 9 个端口已有真实网络或测量消费者。读取 R2025b 官方 `FuelCell.elements.Pipe.ssc` 证实：`MIn [kg/s]` 是供外部化学/分离过程使用的物种侧源，`TIn [K]` 是该侧源温度，默认分别为零和 293.15 K。读取官方 `PressureTemperatureSensor.ssc` 证实：`P/T` 是 A 相对 B 的压力/温度差；本模型 B 已连接 `Absolute Reference (FC)`，故其为阀前/阀后绝对气体状态测量。
2. 最小物理修复：不增加 Terminator、Cap 或自建方程。回流管新增标准 `Constant -> Simulink-PS Converter` 链，将无外部反应/分离的 V-SH 边界明确为四组分零侧源质量流和 `env_T + 273.15` 的 K 参考温度；将两路 `T` 通过 `PS-Simulink Converter`、语义 Outport、`Control_and_Result_Observability` 的具名 `ToWorkspace` 链记录为 `routeA_T_egr_valve_up_K_ts`、`routeA_T_egr_valve_down_K_ts`。
3. 结构读回与复查：`model_read(blk_667)` 显示 `MIn=blk_1206.RConn1`、`TIn=blk_1208.RConn1`、上下游 `T` 分别有转换器与具名输出；`model_check(blk_667,["unconnected_ports","unconnected_lines"])` 和 `model_check(blk_910,[...])` 均为 healthy。根级计数由 55 降至 42，未产生悬空普通信号线。
4. W0 回归：正式 `run_routeA_focused_study` 在 `self_humidifying`、Current 5 A、cEGR target/profile 0、120 s、尾窗 `[90,120]`、`steadyWindowDuration_s=30`、cold/serial 下通过：`MATRIX_COMPLETE=1`、`SIM_COMPLETED=1`、`CASE_PASSED=1`、`STUDY_PASSED=1`、`STOP_EVENT=ReachedStopTime`、runtime warning diagnostics 0、`LASTWARN` 为空。新增记录均存在，末值为阀前 353.291148 K、阀后 314.973415 K。正式模型保存后 `Dirty=off`，文件路径读回正确。

## 2026-08-18 续：排气/背压 owner 的根因、修复与回归

1. 根因定位与依据：官方 `CompHumSensor.ssc` 证实 `x_i/y_i/W` 分别为出口质量分数、摩尔分数和相对湿度；官方 `MassEnergyFlowSensor.ssc` 证实 `M/Phi_out/M_i` 分别为总质量流、能量流和物种质量流，正方向 A→B。读回确认湿度传感器的 `x_i/y_i`、两只流量传感器的 `Phi_out/M_i` 及排气边界管 `MIn/TIn` 缺少消费者或显式边界。随后 `PortConnectivity` 还证实阴极腔辅助端口和其既有官方 `Cap (FC)` 实际断开；`Cap.ssc` 规定它是无质量/能量流的气体网络端部，而不是本轮临时消警构件。
2. 最小物理修复：新建 `Exhaust_Flow_and_Composition_Diagnostics` 作为单一功能消费者；`x_i/y_i`、回流/排气 `Phi_out/M_i` 分别经标准 PS-Simulink 转换器记录为 6 个具名诊断。排气背压管按无外部反应/分离边界使用标准 `Constant -> Simulink-PS Converter` 显式输入零四组分侧源和 `env_T + 273.15` K 无效侧源参考温度。恢复原有 Cap 到辅助跨层端口的物理连线；未新建 Cap、Terminator 或自建方程。

## 2026-08-18 续：入口、电堆/阳极 owner 与最终 W0

1. 入口 owner：官方 `CompHumSensor`/`MassEnergyFlowSensor` 契约和 `PortConnectivity` 读回确认，入口气路 A/B、RH 和物种流已有有效连接；缺项为湿度传感器的 `x_i/y_i`、质量流传感器的 `M/Phi_out`。四路均接入现有 `Inlet_Result_Observability`，并在正式 `SimulationOutput` 中确认 `routeA_xi_ca_in_sensor_ts`、`routeA_yi_ca_in_sensor_ts`、`routeA_mdot_ca_in_ts`、`routeA_energy_flow_ca_in_W_ts` 存在。该 scope 结构 healthy，根级计数从 23 降至 14。
2. 电堆/阳极 owner：官方 `Chamber.ssc` 确认阴极出口腔为三端气体控制容积，A/B/C、pC/TC/yC_i/H 均有真实物理或观测连接；仅 `MIn/TIn` 未连接。官方 Pipe 契约同样适用于简化阳极出口管。两个模块均不包含外部反应或分离过程，故仅以标准零侧源质量流和明确 °C→K 的参考温度连接这两个输入，未改动气体、热或电化学方程。两 scope 均 structural healthy，根级计数从 14 降至 0。
3. 最终结构/运行验收：`model_check(root,["all"])` 返回 healthy；正式 `run_routeA_focused_study` 使用 `self_humidifying`、Current 5 A、cEGR target/profile 0、120 s、尾窗 `[90,120]`、`steadyWindowDuration_s=30`、cold/serial，返回 `MATRIX_COMPLETE=1`、`SIM_COMPLETED=1`、`CASE_PASSED=1`、`STUDY_PASSED=1`、`STOP_EVENT=ReachedStopTime`、runtime warning diagnostics 0，`LASTWARN` 为空。随后 `save_system` 读回正式路径存在且 `Dirty=off`。
3. 结构读回与复查：排气/背压、排气边界和新增诊断子系统均 `model_check(...,["unconnected_ports","unconnected_lines"]) = healthy`；根级计数从 42 降至 23，未产生悬空普通信号线。
4. W0 回归：正式 runner 使用相同 120 s Cold/serial W0 工况通过，`MATRIX_COMPLETE=1`、`SIM_COMPLETED=1`、`CASE_PASSED=1`、`STUDY_PASSED=1`、`STOP_EVENT=ReachedStopTime`、runtime warning diagnostics 0、`LASTWARN` 为空。6 个新增 `ToWorkspace` 变量均出现在 `SimulationOutput`；正式模型保存、文件存在且 `Dirty=off`。

## 2026-08-18 续：SATK 工具链更新与兼容性告警复测

1. 工具链处置：使用本地官方下载资产和新版 `agenticToolkitInstaller.mltbx` 的官方离线安装流程更新；安装根目录为 `C:\Users\ADMIN\.matlab\agentic-toolkits`。重启 Codex MATLAB 会话后，`setupAgenticToolkit("status")` 读回 MATLAB MCP `v0.11.4`、SATK 安装目录 `VERSION=2026.08.12`；Codex 继续使用原有 `matlab-codex` MCP 路由，保留 `--disable-telemetry=true`。安装过程未修改项目模型、runner 或参数脚本。
2. 正式模型读回：重启后加载 `PEMFuelCellSystem_Cathode_cEGR_SelfHumidifying_v01.slx`，读回 `Dirty=off`。`model_read(root, depth=0)` 仍正确返回 8 个 V-SH 功能容器及主气路/cEGR/阳极/热边界连接；`model_check(root,["all"])` 仍返回 `healthy`，无未连接端口、悬空普通信号线或 Stateflow lint。
3. 工具层复现结论：在每次调用前清空 `lastwarn` 后，`model_read` 和 `model_check` 均再次产生 `Simulink:Commands:FindSystemDefaultVariantsOptionWithVariantModel`。首个栈位置保持 `sage.internal.adapter.MemoryAdapter.findBlockHandles`；分别经 `sage.graph_read` 与 `sage.graph_query` 进入工具。该提示在当前上游版本仍未修复，且不属于模型 Diagnostic Viewer 的结构诊断。不得改动 V-SH 拓扑、添加 Terminator 或用 `warning off` 掩盖；若要求 agent 控制台亦零 warning，应转为向 MathWorks 报告/修复 SATK 共享变体检索逻辑。
