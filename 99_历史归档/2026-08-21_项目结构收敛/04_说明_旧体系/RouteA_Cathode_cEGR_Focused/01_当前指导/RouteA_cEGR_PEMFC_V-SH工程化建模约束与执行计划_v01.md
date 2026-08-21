# Route A cEGR-PEMFC V-SH 工程化建模约束与执行计划

文件类型：V-SH 专项当前指导、约束冻结与执行计划
日期：2026-08-18
状态：约束已冻结；V-SH-W0 已完成模型可读化及结构/编译/运行/日志 warning 清零。2026-08-19 已完成并保存阀前理想分流重构：`p_split` 同时接排气 V_BP 与回流 V_EGR，根层物理线和混合器编译断言已闭环；`model_check(root,["all"])` 为 healthy，W0 与两项 240 kW 代表性 CEGR smoke 已通过。2026-08-20 V6 zero-crossing 敏感性已完成，结果归类为 solver + control 敏感；pressure eligibility 字段语义已收口。

## 1. 决策范围与主线优先级

1. 当前主动研究对象为 V-SH：阀门被动循环 + 自增湿电堆 + 空压机入口回流。
2. 完整系统 Route A 主线降为维护和接口兼容状态。除共享脚本、契约、依赖和缺陷修复外，暂不扩展完整系统功能。
3. E-SH、P-SH 及其他 2×3 配置在 V-SH 工程化基线完成前不进入主动实施。
4. V-SH 继续使用唯一正式模型：
   `04_Simulink物理网络模型/01_模型/RouteA_Cathode_cEGR_Focused/PEMFuelCellSystem_Cathode_cEGR_SelfHumidifying_v01.slx`
5. V-SH 继续使用唯一正式聚焦 runner：
   `04_Simulink物理网络模型/03_脚本/RouteA_Cathode_cEGR_Focused/run_routeA_focused_study.m`
6. 不复制或按工况复制 `.slx`、runner 或参数脚本。脚本只负责 case 装配、参数写入、观测读回和结果审计；Simulink 模型仍是核心仿真资产。

## 2. 工程结论边界

### 2.1 允许回答的问题

- 阀门被动循环下，CEGR 回流能力与负荷、压力、阀面积和阀前后压差的半定量关系；
- CEGR 对堆电流、电压、堆功率、氧分压、氧过量系数、压力链和气相水蒸气的影响；
- 空压机前新鲜空气与回流气体混合后的气相饱和、露点裕度和冷凝风险；
- 在当前气相模型中，降低回流、提高回流气体/入口温度、降低新鲜空气湿度或调整压力边界所需的风险缓解方向。

### 2.2 明确不声称的内容

- `P_stack=I*V` 以外的系统净功率、空压机轴功率、泵功耗或系统效率；
- 完整阳极控制、吹扫、冷却回路、散热器和热交换器的工程复刻；
- 液水库存、液滴携带、排液、分离效率、空压机进液损伤和耐久性；
- 真实膜加湿器跨膜传质/传热；
- 超出数据支撑区的精确设备选型或产品性能承诺。

简化阳极和固定堆温仍然是聚焦模型边界，但它们是可随研究 case 改变的输入，不是永久固定常数。所有 case 必须通过 `SimulationInput` 写入并在 `parameterBridge` 中记录来源。

## 3. 物理结构与缺陷修复原则

1. 发现模型能力不足时，先复现问题并定位首个真实错误、warning 或不满足的物理关系。
2. 改进方案必须有官方 Simscape/Simulink 模块、MathWorks 示例、成熟案例、文献或可审计工程数据依据。
3. 禁止使用没有依据的自建方程、恒定压降、人工压力源或调参拟合掩盖结构缺陷。
4. 目标气路应逐步收敛为：
   `阴极出口 -> 公共背压边界 -> 气相/水边界 -> 回流/排放分流 -> CEGR 阀/管路 -> 空压机入口混合器`。
5. 在真实分离后分流拓扑尚未读回确认前，`r_split` 必须携带代理状态，不得作为已闭合分离器工程结果。
6. V-SH 不引入主动循环泵。被动的含义是无独立循环做功设备；CEGR 阀和公共背压阀仍可受控调节。

## 4. Warning 清理门

V-SH 完成标准要求以下三类 warning 均为零：

1. SATK `model_check` 结构 warning；
2. Simulink/Simscape update、compile 和 simulation runtime warning；
3. `To Workspace`、Simscape logging 和结果链 warning。

清理允许删除不进入 V-SH 结果契约的观测块、变体端口和不适用完整系统接口；需要的测点必须接入合法物理或信号观测链。不得用 Terminator 伪装物理端口闭合。

每个缺陷必须完成：

`现象复现 -> 首个真实错误/警告 -> 根因定位 -> 依据审查 -> 最小修复 -> 结构读回 -> warning/compile/smoke 验证 -> 实施记录`

在 warning 清零基线完成前，不进行新的 BOP 标定和 CEGR 工程结论研究。

## 5. 数据来源、口径和参数优先级

### 5.1 数据资产角色

| 文件 | 角色 | 使用边界 |
|---|---|---|
| `00_支撑材料/01_项目系统实验数据/240kw电堆数据.txt` | 实测参考 | 19 点电流/电压/堆功率/空压机入口流量；5 个压力、温度、湿度锚点 |
| `00_支撑材料/01_项目系统实验数据/电堆信息及推荐测试工况.xlsx` | 推荐工况 | 23 个电流、计量比、压力、温度、湿度和冷却水温差组合，不自动视为实测 |
| 官方 Gas/Moist Air/FuelCell 示例 | 结构和组件依据 | 只读参考，不直接覆盖当前默认值 |
| 成熟案例、文献和经验值 | 外部/假设参数 | 必须标记 `external_case` 或 `engineering_assumption`、单位和适用范围 |

`240kw电堆数据.txt` 同时包含系统功率和电堆功率。V-SH 只用 `P_stack=I*V` 作为电性能目标；没有设备显示和功耗数据时，不用系统功率拟合 MEA 或宣称系统效率。

### 5.2 Case 输入优先级

参数来源按以下顺序生效，且写入 `parameterBridge`：

1. 用户明确的 case 值；
2. `measured_reference`；
3. `recommended_test_condition`；
4. 按电流、计量比、温度或压力派生的 `scaling_rule`；
5. `engineering_assumption`。

同一物理量不得存在两个未裁决的竞争写入点。阳极可采用“电流 + 阳极计量比派生流量”或“外部案例直接流量”模式，但模式必须显式标记。

## 6. 240 kW 电堆与研究范围

- 电堆尺寸：606 片、活性面积 380 cm²。
- 额定基线：`j=1.6 A/cm²`，堆功率约 240 kW。
- 正式研究范围：`0.01 <= j <= 2.2 A/cm²`。
- 有数据支撑的主结论区：`0.1 <= j <= 1.9 A/cm²`。

负荷分区采用不重叠边界：

| 分区 | 电流密度 |
|---|---:|
| 极低 | `0.01 <= j < 0.1 A/cm²` |
| 低 | `0.1 <= j < 0.4 A/cm²` |
| 中 | `0.4 <= j < 1.2 A/cm²` |
| 高 | `1.2 <= j <= 1.9 A/cm²` |
| 极高 | `1.9 < j <= 2.2 A/cm²` |

主结论优先使用代表点 `0.1、0.4、0.9、1.2、1.5、1.9 A/cm²`；极低和极高区只做扩展趋势与边界分析，不得写成 240 kW 标定验证。

固定堆温默认以 `80°C` 为额定基线，温度扰动使用 `60/70/80/90°C`。温度直接写入聚焦固定温度边界，不解释为完整冷却系统动态响应。

## 7. BOP 半定量标定门

标定顺序固定为：

1. MEA 电流-电压-堆功率；
2. 阴极/阳极边界和压力链；
3. 空气流量/OER 和阀门压降；
4. 温度和气相水蒸气边界；
5. 在冻结后的 BOP 上进行 CEGR 研究。

初版验收门：

- 单片电压标定区 RMSE `<=15 mV`，留出点最大绝对误差 `<=25 mV`；
- 入口/出口压力 RMSE `<=10 kPa`，压降随流量保持物理单调；
- 空气质量流量相对误差 `<=5%`；
- 水蒸气质量流率先要求物料闭合和趋势正确，不以 RH 作为质量守恒主判据；
- 扩展区只做趋势判断，不进入参数拟合门。

## 8. CEGR 控制和能力包络

控制优先级：

1. 正向回流、压力、空压机有效工作区和 O2 供应等可行性约束；
2. 公共背压控制；
3. `R_EGR=m_return/m_fresh` 目标跟踪；
4. 在可行域内降低冷凝风险并评估气路代价。

统一研究量为压缩机入口 `R_EGR=m_return/m_fresh`，阀控制器的混合基输入必须显式换算为 `x_EGR=m_return/m_total=R_EGR/(1+R_EGR)`；`r_split` 仅作出口分支的独立观测。先按两条互斥流量策略扫描：总流量不变时每负载从 `0` 到 `OER_ref-1` 的归一化边界；新鲜空气不变时扫 `R_EGR=[0,0.1,0.5,1,2,4,8]`。随后再按阀面积饱和、回流方向失效、实际入堆 O2/压力约束失败、冷凝风险超限或数值无法稳定识别多约束运行包络。

首轮固定为推荐工况的 `j=[0.1,0.2,0.4,1.0] A/cm²`，对应 `OER_ref=[5.0,3.6,2.4,1.8]`；阴极背压按推荐表的表压加环境绝压，气路/固定堆温按同表写入既有边界。温度、湿度、压力和空气流量扰动只对出现约束边界的 case 扩展。

必须输出：

1. `r_split` 与阀面积、阀压差、负荷的能力图；
2. `r_split` 与 O2 分压、压力裕度、堆电压的约束图；
3. `r_split` 与饱和度、露点裕度、冷凝率、所需升温的风险图。

## 9. 气相冷凝风险判据

V-SH 只采用现有饱和蒸汽压、组分和质量守恒气相相变功能，不升级液水库存、排液、分离效率或液滴携带模型。

| 等级 | 判据 |
|---|---|
| 低风险 | 饱和度 `S <= 0.95` 且露点裕度 `>=2°C` |
| 临界 | `0.95<S<=1.0` 或露点裕度 `0–2°C` |
| 有风险 | `S>1.0`、`m_cond>0` 或露点裕度 `<0°C` |

防冷凝只研究已有边界或有来源的等效输入：新鲜空气 RH、回流比例、回流/入口温度、背压、空气流量和 CEGR 限制/旁通。输出风险等级、冷凝率、积分气相冷凝量、露点裕度和达到目标裕度所需的等效升温或降回流量。

## 10. 执行计划与出口门

### V-SH-W0：warning 清零基线

- 冻结模型 hash、当前参数和观测契约；
- 建立当前 SATK warning 的 owner、根因和处置表，并在计数变化后更新；
- 删除无用观测/端口，补齐必要连接；
- 通过 `model_read`、`model_check`、update/compile 和代表性 cold smoke；
- 出口：结构、编译、运行和日志 warning 全部为零。

当前实施状态（2026-08-20 live re-audit）：

- 顶层已收敛为 8 个语义功能容器；V-SH `focusedParameterBridge.modelWritePoints` 当前读回为 23 个 focused 写点，shared adapter 的 `env_yO2/env_yH20`、command profile 和边界变量另行记录；V-SH 不再写入引射器变量；
- 代表性正式 cold smoke 为 `self_humidifying`、Current 5 A、cEGR target/profile 0、120 s、尾窗 `[90,120]`、`steadyWindowDuration_s=30`；`SimulationInput -> sim -> assess` 返回 `SIM_COMPLETED=1`、`CASE_PASSED=1`、`STUDY_PASSED=1`、runtime warning diagnostics 0；
- 外部 240 kW W1/W2 使用 `240kw电堆数据.txt` 的 19 个电气/流量点与 5 个绝对压力/气温锚点，并用推荐工况表的冷却液均值作为固定堆温边界；无回流 19 点基线由 18 个既有成功 case 和 j=1.7 A/cm² 定向回归汇总，11 点电压验证 RMSE 为 14.728138 mV、五点入口压力 RMSE 为 5.921663 kPa。W3 首个 `0.1 A/cm² / target m_cegr/m_comp_inlet=0.05` 600 s 点通过，实际 `r_split` 仅作独立支路代理指标；cEGR 能力包络尚未完成；
- 对外部 240 kW 的 `cold_start_only` cEGR case，case factory 必须把非零目标设为与新鲜空气相同建立期的 `0 -> targetRatio` 渐变。该规则来自已复现的冷态突跳阻塞修复；它是数值输入合同，不是阀门或回流物理性能结论；
- Simulink/Simscape update、compile、runtime 和正式结果链均无 warning；
- `Cathode_Air_Supply_and_cEGR` 已用官方 `Pipe (FC)` 和 `Pressure and Temperature Sensor (FC)` 源码确认端口语义：回流管 `MIn` 显式固定为无侧源物种流，`TIn` 显式给出零侧源的参考温度；阀前/后 `T` 均接入具名的 K 温度诊断。该 owner 的 13 条警告清零，并经 120 s W0 回归确认新增诊断可记录；
- `Cathode_Exhaust_and_Backpressure` 已用官方 `CompHumSensor` 和 `MassEnergyFlowSensor` 源码确认组分、湿度、能量流与物种质量流端口语义；所有测量输出已接入独立具名诊断消费者，排气边界管的无侧源输入已显式化。审计中还发现阴极腔 B 端的既有官方 `Cap (FC)` 内部实际断线，已恢复其到跨层物理端口的连接。该 scope 现为 structural healthy，并经 120 s W0 回归确认新增 6 组记录可用；
- `Cathode_Inlet_Instrumentation` 已将入口传感器的质量/摩尔组分、总质量流与能量流纳入原有 `Inlet_Result_Observability`；`PEMFC_Stack_Core` 与 `Simplified_Anode_Boundary` 的 `MIn/TIn` 已按官方 Chamber/Pipe 侧源接口，显式固定为零侧源与带单位转换的无效侧源参考温度。四个 owner 子系统均已结构读回为 healthy；
- 终检 `model_check(root,["all"])` 为 healthy，无 `unconnected_port`、无悬空普通信号线、无 Stateflow lint。正式 W0 runner 再次通过，模型结构 warning、编译 warning、运行 warning 与日志 warning 均为零。SATK 接口本身仍打印其 `find_system` 兼容性提示；该提示不产生模型诊断项，也不改变本模型零 warning 结论，工具实现修补另列为工具链维护项。2026-08-18 已用重启后的 SATK `2026.08.12` 与 MATLAB MCP `v0.11.4` 对正式 V-SH 复测：`model_read` 和 `model_check` 均仍复现 `Simulink:Commands:FindSystemDefaultVariantsOptionWithVariantModel`，故该工具层问题未被当前上游版本解决。

### V-SH-W1：case 与边界契约

- 建立 measured/reference/recommended/scaling/assumption 来源字段；
- 使阳极压力、温度、湿度、组分、流量和堆温按 case 写入；
- 建立电流/OER 派生流量与直接流量两种互斥模式；
- 出口：参数唯一写入点、读回值和来源完整。

### V-SH-W2：240 kW 电堆与 BOP 半定量标定

- 按 MEA、压力链、空气流量/OER、温度/水蒸气顺序标定；
- 使用 txt 实测点训练/留出，xlsx 作为推荐矩阵；
- 出口：达到第 7 节门限，扩展区与主结论区分离。

### V-SH-W3：被动 CEGR 静态能力包络

- 分两步执行第一轮负荷 × `R_EGR` 矩阵：先总流量不变，再新鲜空气不变；
- 记录阀面积、阀压差、回流/排放流量、O2、压力和堆功率；
- 出口：能力图、约束边界和失败分类。

当前外部 240 kW 的 W3 输入已由 `routeA_focused_external240kw_cegr_matrix_case_factory` 生成并完成正式研究运行：两个 4-worker 并行 600 s cold-start 批次共 52 case。总流量不变批次为 24 case：每一负载扫 `R_EGR=(OER_ref-1)*[0,0.10,0.25,0.50,0.75,1.00]`，保持参考 OER 对应的压缩机总质量流；新鲜空气不变批次为 28 case：每一负载扫 `[0,0.1,0.5,1,2,4,8]`，使用 V-SH mode 4 对 `m_fresh=max(0,|m_total|-|m_cEGR|)` 反馈并随回流提高总流量。正式 MAT 读回为总流量不变 23/24 个仿真完成、新鲜空气不变 28/28 个仿真完成，即 51/52 个数值完成；总流量固定 `j=0.1/R_EGR=4` 在约 267 s 因阴极气体质量分数非负断言中止。新鲜空气固定批次虽 28/28 完成仿真，但 6 个 case 因阀面积饱和或回流跟踪失败，不应写成工程筛选通过。实际入堆 OER 的判据为 `<1` 不可取、`1–1.2` 风险、`>1.2` 可行；目标/实际回流均按 `R_EGR` 比较，同时报告控制器混合基比与 `r_split`；压缩机入口混合器、阴极气体及回流管的气相饱和/冷凝状态进入审计表。W3 本轮结果为模型范围内的气相筛选，而非阀门额定、液水库存、液滴输运或压缩机耐液工程验证；可读交付为 `02_结果/RouteA_Cathode_cEGR_Focused/outputs/20260818_vsh_cegr_audit/240kW尺寸-自增湿电堆-阀门被动式-阴极尾气循环技术审计_v02.xlsx`。v02 将原“OER 命令”明确为无 cEGR 基准 `OER_ref`，单列总流量不变与新鲜空气不变的流量边界；附录现已由当前拓扑 MAT 回填 p_split、p_EGR,up、p_EGR,down、Δp_BP、Δp_path、三项等式偏差、来源、单位和测点；v02 公式错误扫描为 0，5 个工作表和嵌入图已渲染复核，报告压力链准入完成。

### V-SH-W4：温度/湿度/压力扰动和冷凝风险

- 只对 W3 发现边界的 case 扩展 `60/70/80/90°C`、RH、压力和空气流量；
- 输出三档冷凝风险和缓解所需等效输入；
- 出口：冷凝风险图和设计建议，不声称液滴输运已验证。

### V-SH-W5：动态阀门控制

- 在 W3 静态包络稳定后执行阀门 step/ramp；
- 验证目标跟踪、压力/O2 约束和失效旁通；
- 出口：控制跟踪和安全边界证据。

### V-SH-W6：阶段收口

- 保存正式模型并确认 `Dirty=off`；
- 固化唯一 runner、参数/观测/结果契约、标定数据和风险报告；
- 只有 W0-W5 全部通过，才重新评估 E-SH/P-SH 准入。

## 11. 证据语义与剩余风险

所有结果继续区分 `implemented`、`structurally_verified`、`executed`、`behavior_verified`、`validated_for_scope` 和 `not_validated`。V-SH 完成不等于完整系统完成，也不自动证明 E-SH/P-SH。

当前已知剩余风险：模型仍是气相 L2 筛选，不闭合液水库存、真实分离效率、设备额定选型或系统净功率。SATK 接口的 `find_system` 兼容性提示属于工具实现而非模型诊断；在重启会话后的 SATK `2026.08.12` 中仍可复现。若要求工具调用控制台亦无任何提示，需要 MathWorks 在 `MemoryAdapter.findBlockHandles` 的变体筛选逻辑中修补，不能通过模型修改或抑制 warning 解决。MATLAB Code Analyzer 已对本轮 V-SH runner、参数桥、观测和路径脚本完成静态检查。

## 12. 2026-08-19 W3 研究报告重构与后续架构计划补充

### 12.1 面向实验人员的分析工作簿定位

W3 交付工作簿现定位为“V-SH 自增湿电堆阀门被动 cEGR 工程分析报告”，不再把版本差异或历史审计过程作为正文内容。正文顺序固定为：

1. 研究结论与工程判断；
2. V-SH 模型结构、阀门职责和控制逻辑；
3. 变量英文注释、定义、单位、测量位置和装置选型建议；
4. 气相冷凝/水汽风险及缓解方向；
5. 52 个正式 case 的原始审计明细附录；完成数与筛选通过数必须分开。

工作簿正文必须明确：`R_EGR=m_return/m_fresh`、`x_EGR=m_return/m_total`、`OER_ref` 仅为无 cEGR 基准流量锚点；压力统一以 kPa 报告，并区分 `p_stack,out`、`p_split`、cEGR 阀前后压力和 `p_comp,in`。模型 `Local Restriction` 的有效面积只作为等效流阻/执行器变量，不直接替代真实阀门 DN、Cv/Kv 或厂家质量流量图。

### 12.2 当前基线装置结构

当前 V-SH 基线已改为阴极出口理想分流：

`电堆阴极出口 / p_split -> V_BP -> Exhaust_Environment_Boundary`
`电堆阴极出口 / p_split -> V_EGR -> CompressorInletMixer.cEGR`。

最小受控硬件集只有排气支路 V_BP 和回流支路 V_EGR；三通为同一理想 Simscape 节点，不引入额外管路压降、后置气相流阻、压力泄放阀、止回阀或隔离阀。安全泄放属于未来硬件安全设计，不进入当前正式理想模型。

**入口顺序必须按正式 V-SH 模型保持：** 新鲜空气与 cEGR 回流先在 `CompressorInletMixer`（压缩机入口混合器）汇合，随后进入空压机；空压机出口再经过 `Intercooler_L2_Interface`（中冷器 L2 接口/中冷器出口段），最后进入自增湿电堆。图示不得把“中冷器/混合器”合并成一个串联设备，也不得把混合器画到空压机之后。该顺序已由 `PEMFuelCellSystem_Cathode_cEGR_SelfHumidifying_v01.slx` 的 `blk_720` 结构读回确认：`CompressorInletMixer` 的 A/B/C 端分别接 Air Intake、Compressor 和 cEGR return，`Intercooler_L2_Interface` 的 A/B 端接 Compressor Volume 与 IntercoolerOutletHumiditySensor。

**当前理想分流基线的压力口径必须拆开：** `p_stack,out`、`p_split` 和 `p_cEGR,up` 是同一理想出口节点的语义别名；`p_cEGR,down` 是 V_EGR 下游、压缩机入口混合器侧压力；`p_comp,in` 是压缩机入口混合器压力。因此，`Δp_EGR=p_cEGR,up−p_cEGR,down` 表示 V_EGR 局部压差，`Δp_BP=p_split−p_env` 表示排气 V_BP 局部压差。结果契约必须同时读回这两个压差，不能把 V_EGR 压差解释为整条出口到压缩机入口路径压差。

### 12.3 阀前理想分流重构实施状态

`V-SH-W3A：阀前理想分流拓扑` 已在当前正式模型中实施：

`电堆阴极出口 -> 分流节点 ->（公共背压阀 -> 排气）+（cEGR 阀 -> 回流）`。

当前模型已删除历史 `CommonGasPhaseBoundary_FC`、cEGR `EGRPipe`、根层 `cEGR_Mode_Selector` 以及排气支路 `Pipe (N Gas)1/Pressure Relief Valve`；保留官方质量流量传感器、P/T 测点和环境 Reservoir。正式 runner 复用同一 case/结果契约，已完成结构读回、编译、W0 及两个外部 240 kW 代表性 case 验证。该结果仍只支持本模型范围内的气相行为，不等同于硬件三通、阀门额定或安全泄放验证。

### 12.4 工作簿图示要求补充

面向实验人员的 V-SH 分析工作簿应至少包含三类结构图：

- 当前阴极出口理想分流气路，并标出 `p_stack,out≈p_split≈p_cEGR,up`、`p_cEGR,down`、V_BP、V_EGR、排气支路和回流支路；
- 公共背压环、cEGR 回流环及监督限幅/联锁层的控制关系；
- 历史阀后分流结构仅作为错误拓扑对照，不再用于当前 CEGR 工程结论；两只当前阀的控制职责分别是排气压力和回流比例。

图示是正文解释的一部分，不能用结构图替代变量定义、测点位置或模型边界说明。

### 12.5 工况矩阵摘要的阅读口径

面向实验人员的正文不得直接使用“完成 case”“候选数”等内部审计统计字段。工况矩阵摘要应先说明：

- 两种进气控制策略分别固定什么、改变什么；
- 四个负荷点和每个负荷的 `R_EGR` 目标扫描方式；
- “直接筛选通过”的判据：实际 `OER_min>1.2`、`S≤0.95`、露点裕度 `≥2°C`、无混合器冷凝且阀面积未到上限；
- 每个负荷下实际可用的 `R_EGR` 点、主要边界和实验建议。

原始 52 case 仍保留在附录，正文只展示矩阵设计和关键工程结果。

### 12.6 2026-08-20 live re-audit 证据与准入结论

- 当前 Codex MATLAB MCP/SATK 会话实际返回 MATLAB/Simulink R2025b；`library.settingsLookup()` gate pass；指定模型 `model_overview`、`model_read`、`model_check(root,["all"])`、update/compile 均成功，`Dirty=off`，最新 Diagnostic Viewer 为 0 error/0 warning/0 info。SATK 仍打印 `FindSystemDefaultVariantsOptionWithVariantModel` 兼容性提示；它属于工具层提示，不是模型诊断。当前 `cEGR_Return_Valve` 活动变体为 `routeA_cegr_valve_mode_id == 1`（Open）。
- 正式 runner re-audit 证据：`outputs/20260820_vsh_reaudit/RouteA_VSH_reaudit_W0_120s_20260820.mat` 的 W0 5 A/120 s 为 `simCompleted=1, passed=1, studyPassed=1`；`RouteA_VSH_reaudit_240kW_rep_j0p4_j1p0_R0p1_600s_20260820.mat` 的两个 240 kW 代表 case 均通过，pressure/water observations 均 collected。当前拓扑尾窗满足 `p_stack,out≈p_split≈p_EGR,up`、`p_EGR,down≈p_comp,in`，并保持气相闭合。
- 参数扰动证据：`RouteA_VSH_reaudit_temperature_perturbation_j0p4_120s_20260820.mat` 中 `focused.cathodeGasTemperature_C=60/90°C` 真实改变 Compressor Volume/中冷器后/堆阴极气体温度；`env_T` 仍负责 Air Intake/压缩机入口混合器环境边界。该职责已写入 parameter bridge，后续不得把两者合并为一个“入口温度”。
- 结论边界：当前 V-SH 模型达到 `structurally_verified + executed + behavior_verified_for_focused_scope`；不升级为 `validated_for_scope` 的液水库存、液滴输运、分离效率、阀门额定、压缩机耐液或系统净功率结论。V4 边界温度扰动、V5 动态目标验证和 V6 zero-crossing 敏感性已完成；V2 的高负荷 fresh-air 基线仍保留 2 个 `zero_crossing_chatter` 失败，不能把 V2 assessment 标为全通过。

### 12.7 2026-08-20 V0-V5 详细验证收口

- V0：`RouteA_VSH_V0_5A_120s_20260820.mat`，5 A、无 cEGR、120 s、serial，`simCompleted=1`、`passed=1`、preflight 通过；模型仍 `Dirty=off`，诊断 0/0/0。
- V1：`RouteA_VSH_V1_parameter_consumers_120s_20260820.mat`，22 case、22/22 完成并局部通过；11/11 baseline/perturbation pair 产生了可读的同义观测响应。电流、R_EGR/x_EGR、`env_T`、focused 阴极气体温度、环境 RH/H2O、O2、堆温和阴极等效流阻响应明确；阀最大面积、最小面积和背压 Ki 的响应量级较小，当前仅标记为 behavior response observed，不作为宽范围标定。
- V2：`RouteA_VSH_V2_external240_baseline_600s_20260820.mat`，19 个 240 kW 无 cEGR 基线 case 中 17 个完成/局部通过；j=1.1 与 j=1.5 A/cm² 在 `A98_FreshAirMdot_Nonnegative` 与 PID Saturation 触发 `zero_crossing_chatter`，保留为控制数值边界。电气留出点 9 个，电压 RMSE=14.3739 mV、最大绝对误差=19.6948 mV、极化单调性通过；5 个压力锚点 inlet RMSE=5.9217 kPa、outlet RMSE≈0、通道压降单调且 10 kPa 门通过；V6 后处理后 `comparisonEligible=1`、`blockedReason=""`、`pressure.passed=1`，压力映射不再被误标为阻塞。整体 assessment 仍因 17/19 完成率及温度/气体温度门未通过。气体温度出口比较 RMSE=5.0504°C、最大误差=8.2679°C，继续按近似诊断使用。
- W3：当前拓扑两批正式 600 s cold-start 共 52 case；total-flow 23/24 完成，失败 case 为 j=0.1、R_EGR=4 的 `oxygen_supply_mass_fraction_nonnegative`；fresh-air 28/28 完成，其中 6 个阀面积饱和/回流跟踪失败。压力链字段已由当前 MAT 回填到 v02 附录的 AY:BM 列，公式错误扫描 0，5 个工作表和嵌入图已重新渲染。
- V4：`RouteA_VSH_V4_boundary_temperature_120s_20260820.mat`，8/8 完成；OER 边界 j=0.2、R=2.6 的 `lambda_min` 约 1.044–1.188，仍属 OER 风险包络；冷凝边界 j=0.4、R=0.5 在 60/70°C 出现 S>1 和非零气相冷凝，80/90°C 冷凝消失但稳态/跟踪状态仍需复核。该阶段用于边界定位，不把风险 case 写成通过。
- V5：`RouteA_VSH_V5_dynamic_control_600s_20260820.mat`，低/中负荷 2/2 完成并通过；logsout 各保留 21 个信号。时间序列确认 180 s、360 s 目标变化使 `routeA_egr_ratio_comp_in` 分别达到 0.0909、0.1667（R_EGR=0.1、0.2），EGR 流量和阀面积同步变化，p_stack,out 尾段分别约 141.325、171.325 kPa abs。
- 当前证据级别：V0/V1/V4/V5 为 `executed + behavior_verified`（限于气相+接口范围）；W3 为 `executed + failure_classified + gas_phase_screen`；V2 为 `partially behavior_verified`，不能写成完整基线标定通过；V6 为 `executed + parameter_sensitivity_behavior_verified`，尚不构成硬件供气边界验证。

### 12.8 2026-08-20 V6 zero-crossing 敏感性与 pressure 语义收口

- V6 结果：`RouteA_VSH_zero_crossing_sensitivity_600s_20260820.mat`，7 组 × 2 个目标负荷，共 14 case；B/S1/C1/F1/F2 共 10 case 在约 `3.1554436e-30 s` 的连续过零区间失败，错误链为 `A98_FreshAirMdot_Nonnegative -> PID Controller -> Saturation`，未修改断言或截断负质量分数。
- S2（RelTol=AbsTol=1e-4，MaxStep=5 s）2/2 完成并局部通过；C2（Kp=10，Ki=1）2/2 完成并局部通过。两组实际 fresh-air 流量均跟踪目标，阴极入口 O2 最小质量分数约 `0.2338517`，`lambda_min` 分别约 `1.9991` 和 `1.7573`。
- F1/F2（目标 fresh-air 分别增加 5%/10%）均未恢复，且失败 case 没有可用的尾窗供气上限观测；因此当前只能判定为 `solver_and_control_sensitive`，没有足够证据称为真实空气供给能力边界，也不能升级为硬件额定结论。
- pressure assessment 字段合同已改为：`comparisonEligible` 只表示测点映射是否具备比较资格；`blockedReason` 只表示资格阻塞，eligible 时为空。V2 MAT 已重新后处理并保存，原始语义版本备份为 `RouteA_VSH_V2_external240_baseline_600s_20260820_pre_v6_pressure_semantics.mat`。
