# Route A cEGR-PEMFC V-SH 技术分析报告重构

日期：2026-08-19  
类型：W3 研究结果交付与工程分析工作簿重构  
状态：已实现；工作簿已读回、公式扫描通过、Excel 直开验证通过；阀前分流拓扑尚未实施

## 1. 前置决策

- 当前指导：[RouteA_cEGR_PEMFC_V-SH工程化建模约束与执行计划_v01.md](../../01_当前指导/RouteA_cEGR_PEMFC_V-SH工程化建模约束与执行计划_v01.md)
- 正式模型：`04_Simulink物理网络模型/01_模型/RouteA_Cathode_cEGR_Focused/PEMFuelCellSystem_Cathode_cEGR_SelfHumidifying_v01.slx`
- 正式研究结果：52 个外部 240 kW V-SH cEGR 工况，分别覆盖总流量不变和新鲜空气不变两种进气控制策略。

## 2. 实际完成的工作

交付文件：

`04_Simulink物理网络模型/02_结果/RouteA_Cathode_cEGR_Focused/outputs/20260818_vsh_cegr_audit/RouteA_External240kW_VSH_cEGR_技术审计结果_v02.xlsx`

本次重构完成：

1. 将研究结论前置，正文改为实验装置设计和 CEGR 技术理解服务；原始 52 case 明细降为附录。
2. 增加 V-SH 模型结构说明，明确空压机入口混合器、公共背压阀、三通/分流节点、cEGR 二通比例阀、排气支路和压力泄放边界的角色。
3. 明确公共背压控制环、cEGR 回流环、监督限幅和启停/抗积分饱和要求。
4. 将 `R_EGR`、`x_EGR`、`OER_ref`、实际 OER、压力、温度、湿度、饱和度和露点裕度等变量补充英文名称、定义、单位、测量位置和工程用途。
5. 将阀门、三通管、压力泄放阀、止回阀、隔离阀和分离/排液部件整理为半定量装置选型建议，并明确模型有效面积不能直接替代实际阀 DN/Cv/Kv。
6. 修正附录压力字段：阀压差、空压机入口/出口、中冷器后、阴极通道、公共背压目标和阴极出口压力均使用独立标题并以 kPa abs 或 kPa 标注；压缩机入口 `pO₂` 改为 kPa abs。
7. 保留 52 个正式 case 的原始审计字段和派生公式，正文不再承担原始审计表的阅读负担。
8. 在正文登记阀前分流作为后续 W3A 架构变体，并明确其“两个阀共同影响电堆出口压力”的耦合控制风险。
9. 在 `02_V-SH模型与控制` 页右侧补充三张工程结构图：当前阀后分流基线气路、两个主闭环与监督限幅层、计划中的 W3A 阀前分流变体；图内同步标出主要压力测点、质量流量变量和两阀职责边界。
10. 重写 `01_研究结论` 页的工况矩阵摘要：删除“完成 case”“候选数”等内部审计统计字段，增加 24+28=52 个 case 的矩阵构成、两种进气策略的扫描定义、直接筛选通过的实际 `R_EGR` 点、主要边界和实验工况建议。

## 2A. V-SH 入口拓扑图纠错（2026-08-19）

用户复核指出原结构图把“中冷器/混合器”合并显示，可能造成入口顺序误读。本次未修改 `.slx`，而是基于正式模型做只读结构核对并纠正图示：

1. 目标模型：`04_Simulink物理网络模型/01_模型/RouteA_Cathode_cEGR_Focused/PEMFuelCellSystem_Cathode_cEGR_SelfHumidifying_v01.slx`。
2. 官方 MATLAB MCP/SATK `model_overview` 与 `model_read(scope=blk_720, depth=inf)` 读回：
   - `CompressorInletMixer` 的 A/B/C 端分别连接 `Air Intake`、`Compressor` 和 cEGR 回流；因此混合器位于空压机入口之前。
   - `Compressor` 由 `Mass Flow Rate Source (FC)` 与 `Compressor Volume` 构成；其下游连接 `Intercooler_L2_Interface`，再连接 `IntercoolerOutletHumiditySensor`/入口测点；因此中冷器段位于空压机之后。
   - 阴极出口链路仍为 `PEMFC_Stack_Core -> Common_Backpressure_Valve_FC -> Post_Backpressure_Gas_Boundary_FC -> cEGR/exhaust split`，即当前是阀后分流基线。
3. 已重绘并视觉检查独立图：`04_Simulink物理网络模型/02_结果/RouteA_Cathode_cEGR_Focused/outputs/20260818_vsh_cegr_audit/V-SH_当前基线系统拓扑_阀后分流.png`。图中明确显示“压缩机入口混合器 -> 空压机 -> 中冷器 L2 接口 -> 自增湿电堆”，不再使用“中冷器/混合器”合并标签。

## 2B. 本次验证状态

- 状态：`structurally_verified`（模型结构读回确认）；图示：已实现并视觉检查。
- 未做：本次未改动正式 `.slx`、控制参数或研究结果，未执行新的仿真；因此不新增行为或物理验证结论。

## 2C. cEGR 阀压差与压力链诊断（2026-08-19）

用户指出 v02 中高负荷 `Δp_valve` 只有几 kPa，与 `p_stack,out` 超过 200 kPa 的直觉不一致。本次从正式 `.mat` 和正式模型双向核对，确认问题是压力口径/解释不完整，不是该 case 的局部阀压差数值计算错误。

### 目标 case

- MAT：`04_Simulink物理网络模型/02_结果/RouteA_Cathode_cEGR_Focused/RouteA_Focused_External240kW_VSH_PassiveCEGR_total_flow_fixed_4J_600s_v02.mat`
- Case：`external240_total_flow_fixed_j1p0_R0p600`
- 尾窗：540–600 s

### MAT 原始统计读回

| 量 | 尾窗均值 |
|---|---:|
| `p_stack,out`（电堆出口、公共背压阀上游） | 231.325 kPa abs |
| `p_cEGR,up`（公共背压阀及后置边界之后、分流点） | 105.743 kPa abs |
| `p_cEGR,down`（cEGR 阀下游） | 101.355 kPa abs |
| `p_comp,in`（压缩机入口） | 101.325 kPa abs |
| `Δp_cEGR,valve = p_cEGR,up − p_cEGR,down` | 4.387 kPa |
| `Δp_BP+post = p_stack,out − p_cEGR,up` | 125.582 kPa |
| `Δp_path = p_stack,out − p_comp,in` | 130.000 kPa |

### 模型结构读回

正式模型 `PEMFuelCellSystem_Cathode_cEGR_SelfHumidifying_v01.slx` 的 `blk_810=Cathode_Exhaust_and_Backpressure` 显示：

`PEMFC_Stack_Core -> Common_Backpressure_Valve_FC -> Post_Backpressure_Gas_Boundary_FC -> cEGR/exhaust split`。

`blk_667` 中 `EGRValveUpstream_PT_Sensor` 接在分流点侧，因此 MAT 的 `egrValveUpstreamPressure_Pa` 不是电堆出口压力，而是公共背压阀之后的 cEGR 阀实际入口压力。MAT 的 `pressureObservations.chain` 也明确把 `commonBackpressureAndBoundaryDrop_MPa` 定义为“公共背压阀及后置边界压降”，并把 `cathodeOutletToCompressorInletMargin_MPa` 定义为整条出口到压缩机入口的压力差。

### 工程结论

1. `Δp_cEGR,valve≈4.4 kPa` 的含义是 cEGR 阀本体局部压差，数值与 MAT 和模型测点一致。
2. 从 231.325 kPa abs 到 101.325 kPa abs 的约 130 kPa 总压降并未消失，而是主要落在公共背压阀及后置边界（约 125.6 kPa），剩余约 4.4 kPa 落在 cEGR 阀，回流管/节点约 0.03 kPa。
3. 因而“背压阀前的阴极出口压力≈cEGR 阀上游压力”不适用于当前阀后分流结构；两者分别位于公共背压阀前后。
4. 这暴露出当前阀后分流基线的工程限制：cEGR 阀可用压头很小，回流能力更多依靠阀面积放大；在同一 `j=1.0 A/cm²` 组，目标 `R_EGR=0.6` 时 cEGR 有效面积分数已约 0.811，目标 `R_EGR=0.8` 时约 0.962，说明接近面积上限。
5. v02 表格需要新增/改名三列：`cEGR阀局部压差 Δp_cEGR,valve`、`公共背压阀+后置边界压降 Δp_BP+post`、`整条回流路径压差 Δp_path`；不能只保留一个笼统的“阀压差”。

### 状态

- 正式 MAT：已读回；正式模型：已结构读回；结论：`structurally_verified`。
- 本次未改动 v02 工作簿，未修改 `.slx`，未重新仿真；下一步应先按用户确认更新 v02 压力字段和正文解释，再决定是否进入阀前分流 W3A 重构。

## 3. 验证证据

- 工作簿重新导入后共 5 个工作表，顺序为：`01_研究结论`、`02_V-SH模型与控制`、`03_变量测点与工程建议`、`04_冷凝与水汽风险`、`附录A_审计明细`。
- 公式错误扫描：未发现 `#REF!`、`#DIV/0!`、`#VALUE!`、`#NAME?` 或 `#N/A`。
- 正文与附录未发现版本对比残留文本。
- Microsoft Excel COM 只读直开成功，无恢复提示；工作表计数为 5。
- 附录关键字段读回：`T4=阀压差 Δp_valve (kPa, cEGR阀上游−下游)`、`U4=空压机入口压力 p_comp,in (kPa abs)`、`Z4=阴极出口压力 p_stack,out (kPa abs)`、`AB4=压缩机入口 pO₂ (kPa abs)`；`AB5=21.27825 kPa`。
- 52 个 case 原始明细仍完整保留，正文矩阵摘要包含 `j=0.1、0.2、0.4、1.0 A/cm²` 两种进气策略的 8 个负荷分组。
- 工作簿压缩包内已读回 3 个嵌入式 PNG 图形对象，分别锚定在 `02_V-SH模型与控制` 页的结构图、控制图和 W3A 变体图区域；同时对三张源图做了独立视觉检查。
- 新矩阵摘要重新导入后，旧的“完成 case”“候选数”文本扫描为 0；8 个负荷/策略组合均改为直接显示目标扫描、可用实际 `R_EGR` 点和主导限制。

## 4. 未决风险和后续入口

1. 当前工作簿仍是气相 L2 筛选和工程设计支撑，不是阀门产品额定选型、液水/液滴工程验证或整机效率报告。
2. 当前正式模型仍是阀后分流基线；阀前分流需要新增可切换拓扑并重新执行结构读回、编译、烟测、动态控制和 52-case 矩阵。
3. W3A 的第一步是冻结两个拓扑的接口合同：`p_stack,out`、`p_split`、cEGR 阀前/后压力、`m_return`、`m_exhaust`、`R_EGR`、`x_EGR`、OER 和冷凝风险。
