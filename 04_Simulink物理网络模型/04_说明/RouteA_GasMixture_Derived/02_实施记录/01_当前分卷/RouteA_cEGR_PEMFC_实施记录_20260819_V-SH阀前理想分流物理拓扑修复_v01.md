# Route A cEGR-PEMFC V-SH 阀前理想分流物理拓扑修复

日期：2026-08-19  
状态：`implemented`、`structurally_verified`、`executed`、`behavior_verified`（仅限当前 V-SH 气相模型范围）

## 1. 范围

- 正式模型：`04_Simulink物理网络模型/01_模型/RouteA_Cathode_cEGR_Focused/PEMFuelCellSystem_Cathode_cEGR_SelfHumidifying_v01.slx`
- 正式 runner：`04_Simulink物理网络模型/03_脚本/RouteA_Cathode_cEGR_Focused/run_routeA_focused_study.m`
- 本次只修改 `E:\agentwork_pemfc_cEGR_main` 的 V-SH 模型及其配套脚本；`E:\agentwork_pemfc_cEGR_0519` 未写入模型或脚本变更。

## 2. 根因与结构修复

首次读回发现旧物理线的语义连接与底层线句柄不一致。压缩机入口混合器的 `PortConvection` 在编译时出现零分母；根因是下游 P/T 传感器的绝对参考端被错误并入混合器 FuelCell 气相节点。

通过 MATLAB MCP 同一会话使用官方 `simscape.addConnection`，并在重连前按底层线句柄逐条清理，完成以下修复：

1. 根层补齐 `Cathode_Air_Supply_and_cEGR -> Cathode_Inlet_Instrumentation -> PEMFC_Stack_Core` 新鲜空气链。
2. 根层补齐 `PEMFC_Stack_Core -> Cathode_Exhaust_and_Backpressure -> Cathode_Air_Supply_and_cEGR` 回流链。
3. 修复 `Fixed_Stack_Temperature_Boundary` 与电堆热端口/求解配置/温度源的实际物理连接。
4. 在 `Cathode_Exhaust_and_Backpressure` 的同一 `cathode_exhaust_gas_in` 节点分出两支：`V_BP -> Exhaust_Mass_Flow_Sensor -> Exhaust_Environment_Boundary`，以及 `cEGR_Return_Mass_Flow_Sensor -> V_EGR`。
5. 删除历史后置气相边界、cEGR 回流管、根层模式选择残留和排气支路额外压力泄放链；当前 V_BP 后直接连接理想环境 Reservoir。
6. 将 V_EGR 下游直接接入 `Compressor_Inlet_Mixer.cEGR`；下游 P/T 传感器的 A 端取该节点压力，B 端只接 `EGRValveDownPTRef`，不再把绝对参考支路接入混合器气相节点。
7. 配套参数桥和 case 使用 `exhaustBackpressureValve*`，模型写入点统一为 `exhaust_bp_valve_*`；结果压力链分开记录 `p_split`、`p_cEGR,up`、`p_cEGR,down`、`p_comp,in`、`Delta_p_BP` 和 `Delta_p_EGR`。

## 3. 结构与编译证据

- MATLAB 版本：R2025b；Simulink/Simscape/FuelCell 组件通过当前 OpenCode MATLAB MCP 会话执行。
- Simulink checksum：`[1738406315;3293175989;1734734950;1404324871]`。
- Git 工作区文件 hash：`4ae9c3ca43441051da89384bc35a9666fb876ea1`。
- `model_read(root)`：根层 28 条连接，无 cEGR 自连接/重复连接；根层回流和新鲜空气物理端口均有实际线句柄。
- `model_check(root,["all"])`：`healthy`，无 unconnected port、无 unconnected line、无 Stateflow lint 问题。
- Simulink update/compile：通过；此前 `FuelCell.PortConvection` 零分母错误不再出现。
- Diagnostic Viewer：0 error、0 warning、0 info。
- 保存状态：MATLAB `Dirty=off`。

## 4. 行为验证

### W0

冷态 5 A、cEGR=0、120 s、尾窗 60--120 s：

- `passed=1`、`simCompleted=1`。
- pressure observations：`collected`；water observations：`collected`。
- `p_split=0.1613 MPa(abs)`、`p_cEGR,up=0.1613 MPa(abs)`。
- `p_cEGR,down=p_comp,in=0.1013 MPa(abs)`。
- `Delta_p_BP=Delta_p_EGR=0.0600 MPa`。

### 外部 240 kW 代表性 case

均为 cold-start、600 s、尾窗 540--600 s、cEGR 目标 `0 -> 0.1` 的 60 s 渐变，`external_case`：

| case | passed | 实际 `r_split` | `m_return` kg/s | `m_exhaust` kg/s | `p_split` MPa(abs) | `p_cEGR,down` MPa(abs) | `p_comp,in` MPa(abs) | `Delta_p_BP` MPa | `Delta_p_EGR` MPa |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `j=0.4 A/cm2` | 1 | 0.10005388 | 0.007577 | 0.068152197 | 0.1425263 | 0.101325 | 0.101325 | 0.0412013 | 0.0412013 |
| `j=1.0 A/cm2` | 1 | 0.099224109 | 0.017039 | 0.15468338 | 0.1836316 | 0.101325 | 0.101325 | 0.0823066 | 0.0823066 |

两项 case 的 pressure/water observations 均为 `collected`，阀面积分数分别约 `0.0399` 和 `0.0639`，未见持续面积饱和或反向回流。该证据验证当前模型内的分流方向、压力测点一致性、回流目标跟踪和气相结果链，不构成真实阀门、三通、液水分离、压缩机耐液或硬件安全验证。

## 5. 剩余风险

- `r_split` 仍标记为当前理想分流节点的气相支路指标，不代表真实分离效率或液水分离结果。
- 外部 240 kW case 仍属于 `external_case`；模型有效面积和等效流阻不能直接替代阀门 DN/Cv/Kv 或厂家图谱。
- 工作区中其他模型和 0519 旧工作区不属于本次修改范围。
