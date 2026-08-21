# V-SH W0 与模型可读化收口

## 前置决策

- `04_Simulink物理网络模型/04_说明/RouteA_Cathode_cEGR_Focused/01_当前指导/RouteA_cEGR_PEMFC_V-SH工程化建模约束与执行计划_v01.md`
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

## 2026-08-18 续：V-SH 模块有效性与最小精简审计

1. 审计范围与方法：仅对正式模型 `PEMFuelCellSystem_Cathode_cEGR_SelfHumidifying_v01.slx` 进行只读 SATK/MATLAB 审计，未修改模型、runner、参数桥或日志契约。读取根级 8 个功能容器及其主要子系统、变体控制、`To Workspace` 消费者和正式 runner 的结果提取路径；复查 `model_check(root,["all"])` 返回 `healthy`，无未连接端口、悬空普通信号线或 Stateflow lint。审计结束时模型 `Dirty=off`。
2. 无可删除的物理或边界模块：阴极空气/cEGR、入口测量、电堆核心、排气/背压、简化阳极、固定温度边界和电负载/cEGR 控制均参与当前气体、电气、热或控制闭环。各 Pipe/Chamber 的零侧源 `MIn/TIn`、参考温度和绝热器明确表达“无外部反应/分离侧源”的官方物理边界，不是无意义常数，不能删除。`cEGR_Return_Route_Selector` 在当前 `routeA_cegr_enabled=true` 时选择回流直通支路，并保留关闭 cEGR 的隔离变体；阀门 Open/Closed 以及 Current/Power/Voltage 负载能力同样属于正式 case 范围，不能按当前 W0 单工况裁剪。
3. 观测层判定：入口/出口传感器、组分/物种质量流/能量流记录不改变物理状态，但分别承担正式 runner 的气体闭合、RH/气相饱和诊断，或为 V-SH W3/W4 的支路流量、组分和冷凝判据保留的具名测量消费者；不标记为废模块。`Focused_Zero_HeatFlow -> Q_stack` 保持直流电堆测量 `[P_stack_kW,Q_stack]` 中 `Q_stack=0` 的接口兼容，正式功率提取器使用第一列 `P_stack_kW`，故暂不改变该接口。
4. 最小改动结论：发现 8 个 Scope 与 4 个 Display 仅用于人工界面展示，未进入物理状态、控制律或正式 runner 的结果计算，是未来可精简候选；但其中部分同时承接已命名的 logsout 线或其上游信号消费者。若逐个删除会改变日志/端口契约并可能重引入悬空线，因此本轮按“无必要不改动”原则不删除、不替换，也不新增 Terminator 或其他掩盖性模块。
5. 状态：V-SH-W0 后的模型没有发现结构性废模块；当前保持模型、runner 和参数链不变。后续如需降低长批次的 UI/记录开销，应把该 12 个界面块作为一个完整的观测契约重构切片处理，并在修改后重新执行结构读回、`model_check` 与正式 120 s W0 smoke，不能将本次审计结论外推为新的物理或工程验证结论。

## 2026-08-18 续：外部 240 kW V-SH 参数链、无回流基线与 cEGR 冷启动命令修复

1. 参数链实际更新：仅修改既有 `routeA_focused_external240kw_case_factory.m`、`routeA_focused_external240kw_calibration_assessment.m` 和 `routeA_focused_parameter_defaults.m`，未新增 runner、诊断脚本或模型副本。外部案例仍显式标记为 `external_case`。热边界改为使用 `00_支撑材料/01_项目系统实验数据/电堆信息及推荐测试工况.xlsx` 的冷却液入口温度与温差均值设定固定电堆温度，并用 `240kw电堆数据.txt` 的 dry-out 五点直接锚定阴极入口气温。wet-in 温度仅保留为近似阴极出口温度诊断；表内阴极 RH 属于外部膜加湿目标，未写入自增湿 V-SH 输入；水迁移量与当前气相水蒸气流量的边界定义不同，未直接作标定目标。
2. 无回流基线与最小修复：新温度源下五锚点 600 s 结果保存为 `04_Simulink物理网络模型/02_结果/RouteA_Cathode_cEGR_Focused/RouteA_Focused_External240kW_SelfHumidifying_ThermalSourceUpdated_5Anchors_600s_20260818.mat`。首次 19 点运行在两个零流量分母过零点中断；新鲜空气冷启动改为 `0 -> measured fresh-air mdot` 的 60 s 渐变后，仅余 j=1.7 A/cm^2 失败。正式模型 `Control_and_Result_Observability/Cathode_cEGR_Control/Mdot Denominator Guard` 的 `LowerLimit=1e-6` 和比值方程保持不变，只将 `ZeroCross` 由 `on` 改为 `off`，避免非物理分母钳位在冷态触发求解器过零搜索。参数读回正确，根级 `model_check(root,["all"])` healthy，模型已经 `save_system` 且 `Dirty=off`。
3. 定向回归与汇总：不重跑原先完成的 18 个工况；仅运行 j=1.7 A/cm^2、600 s 回归，结果保存为 `RouteA_Focused_External240kW_SelfHumidifying_ZCGuardRecovery_j1p7_600s_20260818.mat`，`STUDY_PASSED=1`、`SIM_COMPLETED=1`、模型 Diagnostic Viewer 为 0 error / 0 warning。j=1.7 的单电池电压为 0.667694845 V，对应参考 0.648 V，误差 19.694845 mV；新鲜空气质量流为 0.24424 kg/s，与目标相同。将此前同一参数链的 18 个成功结果和该定向回归在内存中汇总，得到 19/19 数值完成：11 个独立电压验证点 RMSE=14.728138 mV、最大绝对误差=22.214509 mV、极化曲线单调递减；五个压力锚点入口 RMSE=5.921663 kPa、出口 RMSE=0 kPa、通道压降随新鲜空气流量单调增加；入口气温 RMSE=0.923775 C。出口气温相对 wet-in 的 RMSE=4.127184 C、最大偏差=6.389098 C，仍为近似诊断，不能当作热管理标定通过项。此 19 点评估是“18 个既有成功 case + 1 个定向回归”的汇总，不是新的 19 点一键重跑文件。
4. cEGR 初始化阻塞定位：先前 0.1/0.4 A/cm^2、5%/10% 的四点批次在 MATLAB 初始化阶段停滞，用户强制退出，未产生可用结果。重启后确认 `routeA_focused_external240kw_case_factory` 在 cEGR 明确启用时把 `caseCfg.cegr.profile` 直接设为标量目标；命令矩阵读回为 t=0 即 0.05，而同一 case 的新鲜空气是 0 -> 目标的 60 s 渐变。真实物理回路已读回为官方 `Local Restriction (FC)`、回流 Pipe 与压缩机入口混合器，不应通过断开或 Terminator 处理。保持回路启用而目标为零的 90 s smoke 在 43.8 s 数值完成，排除“回路一启用即无法初始化”。将 cEGR profile 改为同一 60 s 的 `0 -> targetRatio` 渐变后，0.1 A/cm^2、5% 目标的 90 s smoke 在 36.8 s 数值完成；通过正式 case factory 再回归，37.2 s 数值完成，二者短尾窗均仅因 `cegr_tracking;not_steady` 未通过稳态判据。Diagnostic Viewer 均为 0 error / 0 warning，`routeA_focused_external240kw_case_factory.m` 的 MATLAB Code Analyzer 为 0 问题。
5. 当前边界与未决项：本轮确认冷启动输入合同并解除初始化阻塞，但尚未得到 600 s cEGR 稳态屏选结果，故不能据此声称回流比例、阀门面积、露点裕度或压缩机湿气风险已通过。零回流 19 点基线保持有效；后续只需先跑一个 0.1 A/cm^2、5% 的 600 s cEGR 工况，再按该实际结果决定是否增加工况，不得重跑已完成的零回流基线。

6. 首个外部 240 kW cEGR 稳态点：按修复后的正式 case factory 执行 `0.1 A/cm^2 / target m_cegr/m_comp_inlet=0.05 / 600 s / [540,600] s`，结果保存为 `04_Simulink物理网络模型/02_结果/RouteA_Cathode_cEGR_Focused/RouteA_Focused_External240kW_VSH_ValvePassive_cEGRScreen_j0p1_r05_600s_20260818.mat`。正式 runner 返回 `STUDY_PASSED=1`、`SIM_COMPLETED=1`、`CASE_PASSED=1`，Diagnostic Viewer 为 0 error / 0 warning。实际 `r_split=0.050561`，`m_cegr=0.001698 kg/s`，新鲜空气基 `m_cegr/m_fresh=0.052632`、混合基 `m_cegr/m_mix=0.050000`，阀面积分数 0.039197，阀前至阀后压差 2.262134 kPa。相对同一 0.1 A/cm^2 零回流基线，压缩机入口压力未变，阴极入口 RH 从 0.047957 升至 0.065715，空压机入口 O2 分压从 21.278250 kPa 降至 20.978531 kPa，混合点饱和度从 0.500619 升至 0.586986、露点裕度从 10.709077 C 降至 8.485403 C，均仍在当前气相筛选的非饱和范围。该结果仅为一个低负荷 5% 点的聚焦模型行为验证；未完成 W3 能力包络，且不证明液滴/液水库存、压缩机含液耐受或阀件工程选型。

7. 外部 240 kW W3 矩阵与审计交付：新增 case factory `routeA_focused_external240kw_cegr_matrix_case_factory.m`，但未新增 runner。它生成 10 个 `self_humidifying`、Current、cold-start、600 s case：`j=[0.1,0.4] A/cm^2` × 目标压缩机入口混合基回流比 `[0,0.10,0.20,0.30,0.40]`；全部采用空气控制模式 2、目标 OER=5。0 回流 case 因空气边界由实测固定流量改为 OER=5 闭环，不是对现有无回流基线的重复运行。正式 `run_routeA_focused_study` 新增可选 `cegrScreenContract`，执行后将审计结果随 study 保存为 `cegrScreenAudit.auditTable`；既有 `routeA_focused_cegr_screen_assessment.m` 升级为 v03。审计使用尾窗最小阴极入口 `lambdaCaIn` 判定 OER（`<1` 不可取、`1–1.2` 风险、`>1.2` 可行），以混合基 `m_cegr/m_comp_inlet` 计算目标/实际控制误差并独立报告 `r_split`，并审计混合器、阴极气体和回流管的气相饱和/冷凝状态。MATLAB Code Analyzer 对 runner、factory、assessment 均为 0 问题；工厂读回 10 个唯一 case，10% case 的 cEGR command profile 在 0–60 s 由 0 到 0.10，空气 OER command 为 5。用既有 5% 成功结果读回审计表，返回 OER `feasible_above_1p2`、控制 `within_control_tolerance`、三个节点均 `gas_phase_noncondensing`。这些均为脚本/接口读回证据，矩阵本身尚未执行。

## 2026-08-18 续：240 kW 双流量策略矩阵、mode 4 反馈与并行 runner

1. 旧 10-case/OER=5 单一矩阵已由本条目覆盖，不作为后续研究输入。正式工况统一改为推荐表的 `j=[0.1,0.2,0.4,1.0] A/cm^2`，`OER_ref=[5.0,3.6,2.4,1.8]`；推荐阴极压力按用户确认的表压转换为 `[0.141325,0.156325,0.171325,0.231325] MPa(abs)`，推荐阴极气温 `[60,62,65,75] degC` 写入既有集总压缩机/中冷器热边界，固定堆温 `[61.5,64,68,80] degC` 写入既有固定温度边界。未将表内外部膜加湿 RH 写入 V-SH。
2. 研究目标明确为压缩机入口 `R_EGR=m_return/m_fresh`；阀 PI 的原有输入仍是 `x_EGR=m_return/m_total`，工厂逐 case 显式写入 `x_EGR=R_EGR/(1+R_EGR)`。`r_split` 继续独立记录，不代替该目标。总流量不变批次为 24 case：每负载 `R_EGR=(OER_ref-1)*[0,0.10,0.25,0.50,0.75,1]`；新鲜空气不变批次为 28 case：每负载 `R_EGR=[0,0.1,0.5,1,2,4,8]`。两批均是 600 s cold-start，非零阀目标保持 0–60 s 渐变，尚未作为正式研究运行。
3. 为实现第二批的物理控制定义，仅在正式 V-SH 模型中增加最小信号反馈链：`Cathode_Exhaust_and_Backpressure.cegr_return_mdot_kg_s -> Cathode_Air_Supply_and_cEGR -> Fresh_Air_Compression_Mixing -> Compressor Control`。空气 mode 4 以 `m_fresh=max(0,abs(m_total)-abs(m_cEGR_return))` 作为 PID 实测量；`m_total` 来自压缩机/中冷器后、入堆前的总质量流传感器，稳态下与压缩机入口混合总流守恒一致。mode 1–3 的原连接和行为未改动；未增加物理端口终结、Cap 或无依据方程。
4. 结构和编译证据：新增 mode-4 Inport、Abs、Sum、Saturation、Mode Switch 和根级回流信号均以 SATK 读回；`model_check(root,["all"])` 为 healthy。`set_param(...,'SimulationCommand','update')` 编译成功，Diagnostic Viewer 读取为 0 error / 0 warning；MATLAB `save_system` 后 `Dirty=off`。
5. 正式 runner 由单一 serial loop 改为“先准备全部 `SimulationInput`，再 serial 或 `parsim` 执行，最后在客户端统一评估”的唯一 runner。并行模式支持配置 pool profile、worker count、进度和 Fast Restart；运行中已存在的并行池会被记录使用，不再产生 runner warning。共享输入适配器只为正式 V-SH 放开 air mode 4；共享评估器在 mode 4 按新鲜空气流量而非总流量判定跟踪。`routeA_focused_cegr_screen_assessment` 升级为 v04，审计表同时给出目标/实际 `R_EGR`、控制混合基比、`r_split`、OER、压力链和三个气相冷凝节点。
6. 执行验证：先以 `j=0.1 A/cm^2, R_EGR=0.1`、mode 4、serial、90 s（尾窗 60–90 s）完成 `SimulationInput -> sim -> assess`，结果 `MODE4_SMOKE_OK`，无结果文件保存。随后以新鲜空气不变 batch 的前两个 case、parallel/`parsim`、2 workers、90 s 完成验证；第一次仅因正式模型未保存被 `ParsimUnsavedChanges` 阻止，未启动 case。`save_system` 后按同一输入重跑，返回 `PARSIM_SMOKE_RERUN_OK`；Diagnostic Viewer 为 0 error / 0 warning。该验证证明 mode 4 和并行执行链可用，不构成 600 s 稳态、52 case 矩阵、性能标定或工程可行性结论。

## 2026-08-18 续：外部 240 kW W3 矩阵收口、两例零交叉修复与可读审计交付

1. 正式执行与范围：按既有双流量策略输入合同，以唯一正式 runner `run_routeA_focused_study.m` 分别执行总流量不变 24 case 和新鲜空气不变 28 case，均为 600 s cold-start、4-worker `parsim`。原始结果分别保存在 `RouteA_Focused_External240kW_VSH_PassiveCEGR_total_flow_fixed_4J_600s_v02.mat` 与 `RouteA_Focused_External240kW_VSH_PassiveCEGR_fresh_air_fixed_4J_600s_v02.mat`；不重跑已完成的 50 case。
2. 根因、依据与最小修复：仅 `external240_total_flow_fixed_j1p0_R0p200` 和 `external240_fresh_air_fixed_j1p0_R2p000` 在约 2.7 s 因 `A98_cEGRReturnMdot_Abs` 连续过零达到求解器上限停止。读回表明既有同义块 `Abs egr mdot` 已使用 `ZeroCross=off`，而 mode-4 新增的 `A98_TotalMdot_Abs`、`A98_cEGRReturnMdot_Abs` 为 `on`。仅将这两个测量 Abs 的 `ZeroCross` 改为 `off`；未更改阀门、气路、方程、分母保护或物理端口。
3. 结构读回与回归：SATK 参数读回三块 Abs 的 `ZeroCross=off`；`model_check(root,["all"])` healthy。`save_system` 后正式模型 `Dirty=off`。将两个失败 case 同批并行重算，正式 runner 与 Diagnostic Viewer 均返回 0 error / 0 warning；各自仅替换并保存到原 MAT 的对应 case，之后重新计算 performance 与 `cegrScreenAudit`。最终两份 MAT 均 `complete=true`，总计 52/52 case 数值完成。修复后的总流量不变 case 实际 `R_EGR=0.19997`、最小 OER=1.5986、混合器 `S=1.1652`，筛选为 `not_acceptable_mixer_condensation`；新鲜空气不变 case 实际 `R_EGR=0.5837`、最小 OER=2.2642、阀面积分数=1、混合器 `S=1.0176`，同样筛选为 `not_acceptable_mixer_condensation`。这两个状态是物理筛选结果，不是运行失败。
4. 审计结论与可读交付：52 case 中 21 个为 `candidate_feasible_gas_phase_screen`、13 个为混合器过饱和/冷凝、1 个为实际 OER<1、10 个需审查 cEGR 跟踪、7 个为风险复核。总流量不变下，低负载 `j=0.1` 的高回流首先由净氧量约束（目标 R=4 时实际最小 OER 约 1）；`j>=0.4` 的主约束转为混合器/阴极气相冷凝。新鲜空气不变下 OER 不首先受限，但阀面积饱和，四个负载的最大实际 R 约为 1.48、1.13、0.91、0.58。压缩机入口风险按混合器 `S=p_H2O/p_sat(T)` 判定：回流湿气与环境新鲜空气混合使温度下降而水蒸气分压未同步下降，故可能 `S>1`；相对饱和超额为 `max(0,S-1)*100%`。该 L2 相变需求/冷凝积分不等于液水库存、液滴携带、真实进液量或压缩机耐液能力。结果已整理为 `04_Simulink物理网络模型/02_结果/RouteA_Cathode_cEGR_Focused/outputs/20260818_vsh_cegr_audit/RouteA_External240kW_VSH_cEGR_技术审计结果_v01.xlsx`，含技术结论、52 case 审计明细、冷凝机制及方法/适用边界四页；Excel 公式错误扫描为零且已渲染检查版式。

## 2026-08-18 续：W3 审计口径澄清与 Excel 兼容性收口

1. 术语/单位收口：在不改动两份正式 MAT、唯一 runner 或 V-SH 模型的前提下，审计工作簿由 v01 更新为 `RouteA_External240kW_VSH_cEGR_技术审计结果_v02.xlsx`。原“OER 命令”改为“无 cEGR 基准 `OER_ref`”：它只定义无回流基准的新鲜空气流量。总流量不变（mode 2）保持 `m_total=m_fresh,ref`，新鲜空气与回流气此消彼长；新鲜空气不变（mode 4）保持 `m_fresh=m_fresh,ref`，总流量随回流增加。实际 OER 仍以入堆尾窗观测独立判定，不能由 `OER_ref` 代替。
2. 回流能力口径：表内阀压差与压力链由 MPa 报告副本换为 kPa；阀压差定义为阀前后 PT 传感器的 `Δp_valve=p_up-p_down`。正压差仅说明回流方向条件；当前 case 的可达性须联合实际 `R_EGR`、阀面积分数、实际 OER、混合器/阴极气相饱和度及露点裕度判断。背压提高通常有利于回流只是在压缩机入口压力及其他损失近似不变时的趋势，不构成阀件额定能力或压缩机耐液结论。
3. 兼容性修复与验证：最初的 v02 包被 Microsoft Excel 判定为需要恢复，故以可直接打开的 v01 为 Excel 原生基线重建同一 v02 内容；未触碰源 MAT 和模型。重建后由 Microsoft Excel 只读直接打开成功，读回 5 个工作表、`审计明细!F4=无 cEGR 基准 OER_ref`、`审计明细!T4=阀压差 (kPa, 上游−下游)`，并扫描 `AU5:AU56` 无公式错误。v02 的“控制与回流能力”页保留了 R 与 x 的映射以及压差×有效面积×气路状态的联合解释。该修复是交付文件兼容性验证，不增加任何新的物理或工程验证等级。
