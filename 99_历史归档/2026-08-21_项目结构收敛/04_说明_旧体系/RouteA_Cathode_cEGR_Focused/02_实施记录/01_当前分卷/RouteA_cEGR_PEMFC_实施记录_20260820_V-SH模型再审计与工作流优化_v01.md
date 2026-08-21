# Route A cEGR-PEMFC V-SH 模型再审计与工作流优化

日期：2026-08-20
类型：live model re-audit、正式 runner 行为复核、参数契约和报告准入审查
状态：`implemented`、`structurally_verified`、`executed`、`behavior_verified_for_focused_scope`；W3 压力字段已补齐，V0-V6 详细验证已执行，V2 高负荷基线仍保留失败边界，V6 已区分 solver/control 敏感性与供气边界证据

## 1. 前置决策与范围

- 当前指导：`01_当前指导/RouteA_cEGR_PEMFC_V-SH工程化建模约束与执行计划_v01.md`
- 正式模型：`04_Simulink物理网络模型/01_模型/RouteA_Cathode_cEGR_Focused/PEMFuelCellSystem_Cathode_cEGR_SelfHumidifying_v01.slx`
- 正式 runner：`04_Simulink物理网络模型/03_脚本/RouteA_Cathode_cEGR_Focused/run_routeA_focused_study.m`
- 本次不复制 `.slx`、runner 或研究矩阵；52-case/V0-V5 新证据放入 `02_结果/RouteA_Cathode_cEGR_Focused/outputs/20260820_vsh_validation/`，按用户选择原地更新 v02 工作簿，并保留一次可恢复备份；既有 20260818 MAT 不被覆盖。

## 2. 实际完成的核查与改进

1. 通过当前 Codex MATLAB MCP/SATK 会话确认 MATLAB/Simulink R2025b、`library.settingsLookup()` gate pass，并完成指定模型的 `model_overview`、分层 `model_read`、`model_check(root,["all"])`、update/compile 和 Diagnostic Viewer 读取。
2. 核对当前活动变体：`cEGR_Return_Valve` 为 `routeA_cegr_valve_mode_id == 1`，对应 `Open`。当前正式物理链为：电堆阴极出口共同节点 → V_BP 环境排气支路 + V_EGR 压缩机入口混合器支路。
3. 修正参数桥元数据：`focused.cathodeGasTemperature_C` 明确记录其真实消费者为 `Compressor_Inlet_Mixer/Cathode_Gas_Temperature_Boundary` 和 `Compressor Volume`；环境压力 canonical name 按实际 case source 记录；V-SH 当前 ideal-split 气相代理状态不再写成“重构进行中”或笼统“未验证”。
4. 修正当前指导中的统计口径：正式 52 case 的 MAT 读回为总流量不变 23/24 个仿真完成、新鲜空气不变 28/28 个仿真完成，即 51/52 个数值完成；“仿真完成”“局部数值通过”“工程筛选通过”分开记录。

## 3. Live 结构、编译和诊断证据

- `model_check(root,["all"])`：`healthy`；无 `unconnected_ports`、无 `unconnected_lines`、无 Stateflow lint。
- update/compile：成功；模型 `Dirty=off`，`SimulationStatus=stopped`。
- Diagnostic Viewer：errors=0、warnings=0、info=0。
- SATK 仍输出 `Simulink:Commands:FindSystemDefaultVariantsOptionWithVariantModel` 兼容性提示；该提示来自 SATK 的 variant 扫描实现，不进入模型诊断项，也不能通过模型改线“清零”。
- `Simulink.findVars` 读回了实际消费者：`focused_cathode_inlet_temperature_C` 进入 Compressor Volume/温度边界；`env_T/env_p/env_yO2/env_yH20` 进入 Air Intake、Compressor Volume、CompressorInletMixer、堆阴极及环境边界；`cegr_inlet_mixer_p0` 进入 CompressorInletMixer。

## 4. 行为复核证据

### 4.1 W0 冷启动

证据：`outputs/20260820_vsh_reaudit/RouteA_VSH_reaudit_W0_120s_20260820.mat`

- Current 5 A、cEGR target/profile 0、120 s、serial、尾窗 `[90,120]`、稳态窗口 30 s。
- `simCompleted=1`、`passed=1`、`studyPassed=1`。
- pressure observations=`collected`；water observations=`collected`；`lambdaTailMin=2.99609468`。

### 4.2 240 kW 代表性 cEGR

证据：`outputs/20260820_vsh_reaudit/RouteA_VSH_reaudit_240kW_rep_j0p4_j1p0_R0p1_600s_20260820.mat`

| case | sim/passed | actual R_EGR | r_split | valve area fraction | Δp_EGR (kPa) | λ_min | observations |
|---|---:|---:|---:|---:|---:|---:|---|
| j=0.4, R=0.1 | 1/1 | 0.100000 | 0.090936 | 0.036303 | 41.2013 | 2.22015 | pressure/water collected |
| j=1.0, R=0.1 | 1/1 | 0.100000 | 0.090196 | 0.058055 | 82.3066 | 1.98620 | pressure/water collected |

两项 case 的尾窗均读回 `p_stack,out≈p_split≈p_EGR,up`、`p_EGR,down≈p_comp,in`，并通过气相闭合；这只证明当前模型范围内的行为，不证明硬件阀门、三通、液水或压缩机耐液。

### 4.3 温度参数扰动

证据：`outputs/20260820_vsh_reaudit/RouteA_VSH_reaudit_temperature_perturbation_j0p4_120s_20260820.mat`

- 同一 j=0.4、无 cEGR、120 s、serial，`focused.cathodeGasTemperature_C=60/90°C` 两 case 均通过。
- 60→90°C 时 Compressor Volume 尾窗温度由 `333.150000 K` 变为 `363.150000 K`，中冷器后由 `333.453115 K` 变为 `363.508715 K`，堆阴极气体由 `336.147430 K` 变为 `358.502534 K`；说明 focused 温度写点有真实响应。
- 压缩机入口混合器温度仍约 `292.658 K`，因为该节点由 `env_T` 环境边界控制；两者不得合并解释为同一个“入口温度”。

## 5. 工况矩阵和 Excel 报告核查

- 总流量不变 MAT：24 case，23 个完成；`j=0.1/R_EGR=4` 在约 267 s 触发阴极气体质量分数非负断言并中止。
- 新鲜空气不变 MAT：28 case 均完成仿真；6 个 case 的局部结果因阀面积饱和或 cEGR 跟踪失败，不应被归为工程筛选通过。
- 独立放宽 OER 补算 MAT：1/1 完成并通过，实际 `λ_min≈1.1159`，仍是 OER 风险边界，不替换正式矩阵结论。
- 当前工作簿 `240kW尺寸-自增湿电堆-阀门被动式-阴极尾气循环技术审计_v02.xlsx`：5 个工作表、公式错误扫描 0、`02_V-SH模型与控制` 嵌入图对象存在并锚定读回；附录 AY:BM 已独立记录 `p_split`、`p_EGR,up`、`p_EGR,down`、`Δp_BP`、`Δp_path`、等式偏差、来源、单位、测点和失败分类。

## 6. 当前结论和未决项

- 当前 V-SH 模型：`structurally_verified + executed + behavior_verified_for_focused_scope`。
- 当前工作流：MATLAB MCP/SATK 门禁、官方模型读回、SimulationInput、统一 runner、结果评估和诊断读取已形成可复用闭环；应继续保留“先 W0、再代表 case、再批量矩阵”的执行顺序。
- 不得升级的结论：液水库存、液滴携带、分离效率、排液、压缩机湿气耐受、阀门 DN/Cv/Kv、系统净功率和产品额定。
- 后续入口：V6 已完成 high-load `zero_crossing_chatter` 的小范围 solver/control 敏感性；pressure tap mapping eligibility 字段已清理。后续如扩大研究，应先定义更细的控制参数/初始化边界或独立供气能力证据；不要把当前气相+接口证据扩展为 E-SH/P-SH、液水或硬件额定结论。

## 7. 2026-08-20 V0-V6 详细验证与报告收口

### 7.1 正式产物

- 新增正式 runner preflight：`routeA_focused_preflight.m`。每次正式运行前记录模型文件、checksum、活动 Open 变体、关键变量消费者、23 个 focused bridge 写点、SimulationInput 的 StopTime/solver/LoadInitialState/logging 设置和结果目录。
- 压力观测链新增规范化字段：`p_stack_out`、`p_split`、`p_EGR_up/down`、`p_comp_in`、`p_ambient`、`deltaP_EGR`、`deltaP_BP`、`deltaP_path` 以及三项等式偏差。
- 新增 JSON 报告数据适配器：`routeA_focused_export_validation_json.m`；它只从两批当前拓扑 MAT 导出 workbook 数据，不绕过正式 runner。
- v02 工作簿已原地更新；修改前备份为 `240kW尺寸-自增湿电堆-阀门被动式-阴极尾气循环技术审计_v02_pre_20260820_validation_backup.xlsx`。附录 AY:BM 新增压力、单位、测点、来源、失败类别和失败原因，公式错误扫描 0，5 个 sheet 和 V-SH 图已渲染复核。

### 7.2 运行证据

- W3 total-flow：`RouteA_Focused_External240kW_VSH_PassiveCEGR_total_flow_fixed_4J_600s_20260820.mat`，24 case 中 23 完成/局部通过；j=0.1、R_EGR=4 在约 267.20 s 分类为 `oxygen_supply_mass_fraction_nonnegative`。失稳前预失败诊断的 cathode `xC_i` O2 质量分数约 -2.84e-5、lambda_min≈0.9994；没有截断负值或放宽断言。
- W3 fresh-air：`RouteA_Focused_External240kW_VSH_PassiveCEGR_fresh_air_fixed_4J_600s_20260820.mat`，28/28 完成，22 局部通过，6 个阀面积饱和/跟踪失败。
- V1：`RouteA_VSH_V1_parameter_consumers_120s_20260820.mat`，22/22 完成并通过，11/11 参数 pair 有同义观测响应；阀面积/Ki 的响应弱，未升级为宽范围标定。
- V2：`RouteA_VSH_V2_external240_baseline_600s_20260820.mat`，19 点中 17 完成/通过；j=1.1、1.5 的错误分类为 `zero_crossing_chatter`。电气留出 RMSE=14.3739 mV、最大误差=19.6948 mV，压力入口 RMSE=5.9217 kPa 且单调性/10 kPa 门通过；V6 后处理后 pressure `comparisonEligible=1`、`blockedReason=""`、`pressure.passed=1`，整体 assessment 仍因数值完成率和温度相关门保持未通过。
- V4：`RouteA_VSH_V4_boundary_temperature_120s_20260820.mat`，8/8 完成；OER 风险边界和冷凝边界均按风险状态保留，未写成通过。
- V5：`RouteA_VSH_V5_dynamic_control_600s_20260820.mat`，低/中负荷 2/2 完成/通过；logsout 21 signals/case，180/360 s 的 R_EGR=0.1/0.2 目标响应已从时间序列读回。

### 7.3 收口判定

- 模型：`model_check(root,["all"])`=healthy；update/compile 成功；Dirty=off；Diagnostic Viewer 0 error/0 warning/0 info。SATK 的 Variant `find_system` 提示仍是工具层问题。
- V-SH 当前状态：`structurally_verified + executed + behavior_verified_for_focused_scope`。V0/V1/V4/V5 在气相+接口边界内行为已验证；W3 是气相筛选并保留失败；V2 只部分通过。
- 未验证边界：液水库存/液滴输运/分离效率/排液、压缩机耐液、阀门 DN/Cv/Kv、系统净功率、产品额定和外部压力 tap 映射的工程结论。

### 7.4 V6 zero-crossing 敏感性与 pressure 语义收口

- 正式入口：`run_routeA_focused_vsh_v6_zero_crossing_sensitivity.m`；复用 `run_routeA_focused_study.m`，按 B/S1/S2/C1/C2/F1/F2 七组分别执行，每组 j=1.1、1.5 A/cm²，600 s、cold-start、4-worker `parsim`。
- 结果：`RouteA_VSH_zero_crossing_sensitivity_600s_20260820.mat`，14/14 case 已执行；B/S1/C1/F1/F2 的 10 case 均在约 `3.1554436e-30 s` 连续过零处失败；S2 2/2、C2 2/2 完成并局部通过。
- S2 的 RelTol/AbsTol=1e-4、MaxStep=5 s；C2 的 Kp=10、Ki=1。两组均保持原 fresh-air target，实际流量与 target 一致，O2 最小质量分数约 `0.2338517`，lambda_min 约 `1.9991/1.7573`。F1/F2 增加 5%/10% fresh-air target 后仍失败。
- V6 自动分类为 `solver_and_control_sensitive`；当前没有真实空气供给能力边界的充分证据。失败工况、首个过零区间、错误链和未收集的物理量均保留，不做断言放宽、负值截断或硬件能力外推。
- pressure 合同测试已通过：eligible 场景 `blockedReason=""`；ineligible 场景保留 `external_pressure_tap_mapping_not_confirmed`；eligible 但无锚点场景保持 `blockedReason=""` 且 pressure gate 未通过。V2 MAT 已重算 assessment，旧字段语义备份已保留。
