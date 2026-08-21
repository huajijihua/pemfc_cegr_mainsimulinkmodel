# Route A P-SH 车载循环泵自增湿模型执行计划 v01

更新日期：2026-08-21
目标模型：`PEMFuelCellSystem_Cathode_cEGR_RecirculationPump_SelfHumidifying_v01.slx`
参考模型：`PEMFuelCellSystem_Cathode_cEGR_SelfHumidifying_v01.slx`
目标结构：车载循环泵主动式 cEGR + 自增湿电堆系统
当前状态：`not_implemented`；只有 V-SH 参考冻结后才创建这一份正式新架构模型。

本文件是交给低成本执行模型的施工合同。P-SH 不应从 E-SH 派生；它应以冻结 V-SH 为共有基准，只替换回流驱动层并增加主动泵功耗与控制合同。

## 1. 已确认的可用资产

本计划基于 2026-08-21 使用 MATLAB R2025b / Simulink 25.2 对项目和 MathWorks 库的实际读回：

- V-SH 正式模型 update/compile 通过且 `Dirty=off`，已有堆出口分流、回流/排气流量测量、被动回流阀、阀前后 p/T 测量、压缩机入口混合和统一结果合同。
- V-SH 的 `cEGR_Return_Valve` 内部使用 `Local Restriction (FC)`；P-SH 可以保留分流、测量、混合和公共背压结构，只替换回流驱动组件。
- `FuelCell_lib` 没有专用循环泵块，但提供可控 `Mass Flow Rate Source (FC)`、`Pressure Source (FC)`、Constant Volume Chamber、Flow Resistance、Local Restriction 和必要传感器。
- V-SH 压缩机已经使用可控 `Mass Flow Rate Source (FC)`、容积、控制和测量模式，可复用接口与观测方法，不能复制其新鲜空气压缩机地图作为尾气泵地图。
- 完整系统的阳极 `Recirculation` 子系统提供直接模板：可控 `Mass Flow Rate Source (FC)`、Constant Volume Chamber、热绝缘、命令饱和 0–1 和一阶执行器 `1/(2s+1)`。
- 统一 runner、case、parameter bridge、preflight、performance metrics 已有 ejector/membrane 的架构扩展模式，可按同样方式注册 `pump_self_humidifying`。
- 当前没有阴极循环泵硬件地图、效率曲线或实验数据，因此第一版只能是受限的 L2 主动流量源模型，必须显式报告能力包络和寄生功率假设。

## 2. 目标物理边界

冻结后的 P-SH 拓扑定义为：

`阴极出口腔 → 与 V-SH 相同的理想分流点 → 回流质量流量传感器 → 主动循环泵 → 泵出口容积/必要流阻 → 压缩机入口混合器`

排气支路继续经过 V-SH 公共背压阀和环境边界。共有堆、阴极通道、压缩机/中冷器、新鲜空气边界、热边界和测量口径与 V-SH 保持一致。

第一版主动泵采用 `Mass Flow Rate Source (FC)` 控制回流质量流率。该组件只代表受控输运，不自动证明真实泵压升、温升、效率和功耗；必须另建能力限制和功耗账本，且在结果中标记为 `map_pending_calibration`。

## 3. 可直接复用和禁止复用

| 资产 | 处理 |
|---|---|
| V-SH 正式模型 | F0 冻结后作为唯一派生源；共有部分保持不变 |
| V-SH 回流分流、流量传感器、阀前后 p/T、混合器 | 直接复用接口与测点 |
| V-SH `cEGR_Return_Valve` | 用主动泵子系统替换；不保留阀面积作为驱动命令 |
| 完整系统阳极 Recirculation | 复用可控质量流量源、容积、绝热和执行器模式 |
| V-SH 新鲜空气 Compressor Control/Map | 仅复用编码和观测模式；禁止把空气压缩机地图当尾气循环泵地图 |
| E-SH 引射器组件和压力窗 | 不参与 P-SH 物理实现，只共享结果口径 |
| 统一 runner/case/bridge | 必须扩展并复用，不新增 P-SH runner |

## 4. 参数与控制合同

在 `params.pump` 和 `caseCfg.pump` 中至少定义：

| 参数 | 单位 | 初始角色 |
|---|---|---|
| `enabled` | boolean | 运行命令 |
| `controlMode` | enum/string | `direct_mdot` 或 `split_ratio_feedback` |
| `targetMdot_kg_s` | kg/s | 直接模式命令 |
| `targetSplitRatio` | 1 | 闭环模式目标，仅为控制设定 |
| `maxMdot_kg_s` | kg/s | 工程假设，待硬件标定 |
| `maxPressureRise_Pa` | Pa | 能力包络，不允许理想源无限增压 |
| `maxPressureRatio` | 1 | 能力包络 |
| `isentropicEfficiency` | 1 | 功耗估算假设，范围必须在 (0,1] |
| `motorEfficiency` | 1 | 电功耗估算假设，范围必须在 (0,1] |
| `actuatorTimeConstant_s` | s | 执行器动态 |
| `controllerKp/Ki` | 按控制口径 | 仅闭环模式使用 |
| `reverseFlowTolerance_kg_s` | kg/s | 反向流判据 |
| `parameterStatus` | string | 固定为 `engineering_assumption_pending_map` |

控制分两步实现：

1. 首先实现 `direct_mdot`，验证物理网络、符号、能力限制和账本。
2. 之后才实现 `split_ratio_feedback`：以实际 `r_split=m_return/(m_return+m_exhaust)` 为反馈，PI 输出泵质量流量命令，并包含 0–max 饱和、anti-windup 和执行器时间常数。

不能用质量流量源强制超出压升/压比包络的工况。触发包络时结果必须标记为 `pump_capacity_limited`，而不是仍判定跟踪通过。

## 5. 施工阶段

### P0 派生前置门

1. 确认 V-SH 已达到参考冻结状态，记录 checksum、solver、共有参数和代表工况摘要。
2. 固定 P-SH 文件名和 modelId：
   - 文件：`PEMFuelCellSystem_Cathode_cEGR_RecirculationPump_SelfHumidifying_v01.slx`
   - modelId：`pump_self_humidifying`
3. 只为这个独立架构创建一次正式模型；不创建 `_draft`、`_v02` 或按阶段副本。

出口：V-SH 参考已冻结，目标文件尚不存在或已被明确裁决为唯一正式 P-SH。

### P1 最小泵组件切片

先在 P-SH 正式模型的回流支路形成最小切片，不同时改 runner：

1. 保留 V-SH 分流点、回流流量传感器和压缩机入口混合器。
2. 将 `cEGR_Return_Valve` 替换为 `Cathode_Recirculation_Pump` 子系统。
3. 子系统至少包含可控 `Mass Flow Rate Source (FC)`、泵出口容积、热边界/绝热、命令转换、上下游 p/T 和组分观测。
4. 默认命令为 0，首先完成关闭状态 update/compile，再给一个小的正回流命令。
5. 明确端口和流量正方向：阴极出口支路 → 压缩机入口混合器。

出口：泵关闭和小正命令均能 update/compile；无反向连接和未连接端口。

### P2 能力限制和功耗账本

1. 计算泵上下游 `Δp`、压力比、回流质量流率和入口状态。
2. 建立两套功耗量并同时报告：
   - 流体侧功率或能量流变化；
   - 基于压力比、入口状态和效率假设的轴功率/电功率估算。
3. 若 `Mass Flow Rate Source (FC)` 的能量传递不能代表真实压缩温升，不得用其出口温度宣称泵热行为正确；把温升标记为模型边界。
4. 增加最大流量、最大压升和最大压比限制；超限时限制命令并输出饱和原因。
5. 反向流只能被检测和分类；没有真实止回阀组件时不要在报告中宣称已建止回阀。

出口：每个运行都能给出实际 m_dot、Δp、压比、功率估算、饱和和反向流状态。

### P3 参数、runner 和评估扩展

1. `routeA_focused_paths.m` 注册 `pump_self_humidifying`。
2. `routeA_focused_parameter_defaults.m` 增加 `params.pump` 和架构元数据：主动驱动、堆出口分流、压缩机入口回流、自增湿。
3. `routeA_focused_case_template.m`、parameter bridge 和 runner 增加泵字段与模型工作区写入。
4. preflight 验证正效率、正时间常数、能力包络、控制模式和测点可用性。
5. assessment/performance 新增 `pump` 结果：命令/实际流量、`r_split`、跟踪误差、Δp、压比、流体功率、轴功率、电功率、饱和、反向流和参数状态。
6. 架构比较使用净功率：`P_net = P_stack - P_fresh_compressor - P_recirc_pump - 已纳入边界的其他寄生功率`；当前新鲜空气压缩机功耗未闭合时必须分别报告，不伪造完整净功率。

出口：一个 case 从配置到结果全链可追溯，且 P-SH 不再引用阀面积作为驱动 KPI。

### P4 直接流量模式验证

只运行三个工况：

1. 泵关闭、cEGR=0：复现同边界 V-SH 无回流基线。
2. 中负荷、小到中等直接回流：验证正流、压力链、混合组分、氧计量比和功耗账本。
3. 接近能力上限：验证最大流量/压升/压比限制和饱和分类。

出口：直接流量模式行为可解释；否则不得进入闭环控制。

### P5 分流比闭环

1. 增加 `r_split` PI 控制、anti-windup、命令饱和和一阶执行器。
2. 在低/中/高三个代表负荷下使用可实现的小到中等目标，检查稳态误差、超调、建立时间和能力限制。
3. 目标不可实现时必须标记容量受限，不能通过提高理想源上限强行跟踪。
4. 与 V-SH 比较时固定共有边界，只比较实际回流能力、阴极入口状态、控制品质和额外寄生功率。

出口：闭环模式在能力包络内行为通过，包络外失败可解释。

### P6 收口

1. 独立读回拓扑、端口、参数和关键信号；重新 update/compile。
2. 保存正式模型并确认 `Dirty=off`。
3. 更新现有 runner README、`PROJECT.md` 状态和紧凑结果；不新增 runner 或过程报告。
4. 无泵地图和实验数据时最高状态为 `behavior_verified_for_focused_scope_not_pump_hardware_validated`。

## 6. 验收门

- P-SH 只相对冻结 V-SH 改变回流驱动和必要泵观测/控制。
- 泵关闭基线与同边界 V-SH 无回流工况在共有 KPI 上一致或差异可解释。
- 正流方向、压力链、组分和质量账本正确。
- 实际流量、Δp、压比、功率和饱和状态均可观测。
- 能力包络外不强制跟踪，不把理想质量流量源当真实硬件。
- direct 模式先通过，闭环模式后通过。
- update/compile、代表工况、读回和 `Dirty=off` 全部完成。

## 7. Luna 执行约束

- 第一轮只执行 P0–P1，不先改所有共用脚本。
- 第二轮只完成 P2 的观测和限制；读回后再扩展 runner。
- 不从 E-SH 派生，不复制空气压缩机地图，不新建 P-SH runner。
- 遇到泵能量语义不清时，明确边界并停止功耗结论，不自行假造效率或硬件曲线。
