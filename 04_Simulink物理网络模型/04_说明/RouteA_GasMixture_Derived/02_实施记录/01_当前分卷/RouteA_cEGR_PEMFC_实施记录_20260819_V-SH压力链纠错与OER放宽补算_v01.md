# Route A cEGR-PEMFC V-SH 压力链纠错、协同控制与 OER 放宽补算

日期：2026-08-19  
类型：W3 结构解释纠错、工作簿交付与独立边界补算  
状态：已实现；正式模型结构已读回；补算已执行并完成聚焦范围行为验证；未扩大为液水或阀件工程验证

## 1. 目标与正式资产

- 正式聚焦模型：`04_Simulink物理网络模型/01_模型/RouteA_Cathode_cEGR_Focused/PEMFuelCellSystem_Cathode_cEGR_SelfHumidifying_v01.slx`
- 正式 runner：`04_Simulink物理网络模型/03_脚本/RouteA_Cathode_cEGR_Focused/run_routeA_focused_study.m`
- 补算结果：`04_Simulink物理网络模型/02_结果/RouteA_Cathode_cEGR_Focused/RouteA_Focused_External240kW_VSH_total_flow_fixed_j0p1_R4p000_OER1p1_600s_20260819.mat`
- 交付工作簿：`04_Simulink物理网络模型/02_结果/RouteA_Cathode_cEGR_Focused/outputs/20260818_vsh_cegr_audit/RouteA_External240kW_VSH_cEGR_技术审计结果_v02.xlsx`

本次处理针对用户提出的三个问题：把结构图改为“阴极出口后分流、两阀并联”；解释 `p_stack,out`、`p_bp,target`、cEGR 阀前/后压力和两个阀压差；对原 `external240_total_flow_fixed_j0p1_R4p000` 进行放宽 OER 的独立补算。

## 2. 正式模型结构读回

官方 MATLAB MCP/SATK 读回结果：

1. `Cathode_Exhaust_and_Backpressure` 中，`Exhaust_Backpressure_Valve_FC` 的 A 端接阴极出口/分流节点，B 端经排气流量测点接环境 `Reservoir (FC)`。
2. cEGR 回流质量流量测点的 A 端接同一个阴极出口/分流节点；cEGR 阀的 A 端接该节点，B 端接 `CompressorInletMixer.cEGR`。
3. 因此当前正式模型是：

   `电堆阴极出口 → 理想分流节点 →（V_BP → 环境排气；V_EGR → 压缩机入口混合器）`

   两阀上游为同一共同节点；两阀下游是两个独立边界，不存在隐藏的公共背压阀后气相边界。

## 3. 压力口径与两个阀的协同关系

工作簿现已统一为以下定义：

| 量 | 当前含义 |
|---|---|
| `p_stack,out` | 电堆阴极出口/理想分流节点共同上游压力 |
| `p_split` | 阴极出口后的理想分流节点压力；当前理想连接下 `p_stack,out≈p_split` |
| `p_EGR,up` | cEGR 阀上游压力；当前与分流节点近似相等 |
| `p_bp,target` | 公共背压环设定值，不是额外气相节点；稳态时跟踪 `p_stack,out` |
| `p_EGR,down` | cEGR 阀下游/压缩机入口混合器侧压力 |
| `p_comp,in` | 压缩机入口混合器压力 |
| `Δp_BP` | `p_split − p_env`，V_BP 排气支路压差 |
| `Δp_EGR` | `p_EGR,up − p_EGR,down`，V_EGR 回流支路压差 |

补算 case 尾窗 540–600 s 的压力链为：

- `p_stack,out≈p_split≈p_EGR,up≈141.325 kPa abs`
- `p_bp,target=141.325 kPa abs`
- `p_EGR,down≈p_comp,in≈p_env≈101.325 kPa abs`
- `Δp_BP≈40.0000005 kPa`
- `Δp_EGR≈40.0000005 kPa`

所以用户观察到的“两阀压差相等”在该 case 中是成立的，但原因是两个下游边界数值都为 `101.325 kPa abs`，不是因为两个阀是同一个物理流路。控制上必须协同：V_BP 维持 `p_stack,out→p_bp,target`，V_EGR 调节 `R_EGR/x_EGR`；只调一个阀不能完整决定 cEGR 能力。

## 4. 独立放宽 OER 补算

保留原 52 点正式矩阵和原失败记录，单独建立 1 个补算 case：

- case：`external240_total_flow_fixed_j0p1_R4p000_OER1p1`
- `j=0.1 A/cm²`，`R_EGR,target=4`
- total-flow-fixed，controller target OER=`5.1`
- 仿真时长 `600 s`，serial、cold-start、尾窗 `540–600 s`

实际结果：

| 指标 | 尾窗结果 |
|---|---:|
| `simCompleted / passed / studyPassed` | `1 / 1 / 1` |
| 入堆实际 `λ` 均值 / 最小值 | `1.1158857 / 1.1158833` |
| 实际 `R_EGR=m_return/m_fresh` | `4.0000002` |
| 实际 `x_EGR` | `0.8000000` |
| `r_split` | `0.8326182` |
| `m_return` | `0.0332913 kg/s` |
| cEGR 阀面积分数 | `0.1677195` |
| `Δp_EGR` | `40.0000005 kPa` |
| 混合器 `S` | `0.7594230` |
| 混合器冷凝率 | `0 kg/s` |

该补算证明“把目标放宽到实际入堆计量比约 1.1 后，模型可完成 600 s 且控制/稳态行为通过”。但 `λ≈1.116` 仍属于本项目 `1.0–1.2` 的 OER 风险边界，不作为正式矩阵的推荐可行窗口，也不替代液水、液滴携带、排液和压缩机耐液验证。

## 5. 工作簿修改

1. `02_V-SH模型与控制` 页的结构图已替换为 `阴极出口后分流 + V_BP/V_EGR 两阀并联`，外部源图为：
   `04_Simulink物理网络模型/02_结果/RouteA_Cathode_cEGR_Focused/outputs/20260818_vsh_cegr_audit/V-SH_当前基线系统拓扑_阴极出口分流_双阀.png`
2. 删除旧嵌入图后重新嵌入 1 张新图；旧的外部 PNG 文件未删除，作为历史资产保留但不再嵌入当前工作簿。
3. `01_研究分析`、`02_V-SH模型与控制`、`03_变量测点与工程建议`、`04_冷凝与水汽风险` 的结构、压力定义、协同控制和补算边界已同步更新。
4. `附录A_审计明细` 保留原 52 个 case，在第 57 行新增独立补算明细；原失败 case 未覆盖。

## 6. 验证与证据等级

- `model_check(root, all)`：`healthy`；未发现 unconnected ports、unconnected lines 或 Stateflow lint 问题。
- 最新 Diagnostic Viewer：errors=0、warnings=0、info=0。
- 工作簿重新导入成功，5 个工作表均已重新渲染；新图已独立视觉检查；嵌入图数量读回为 1，锚点/尺寸读回为 1400×590 px。
- 工作簿文本扫描：未发现旧的“当前模型是阀后分流”“公共背压阀下游分流节点”或同义残留表述。
- 结论等级：模型拓扑为 `structurally_verified`；补算结果为 `executed + behavior_verified_for_focused_scope`；不升级为产品选型、液水工程或整机性能结论。

## 7. 剩余风险

1. 本次两个阀压差相等依赖当前 case 的环境/压缩机入口边界相同；真实试验台的进气管路损失、滤清器和消声器压降可能使两者分开。
2. `A_fraction` 仍是 Local Restriction 等效面积，不是实际阀门开度、DN 或 Cv/Kv。
3. 当前模型是气相 L2；液水库存、液滴输运、分离效率、排液逻辑和压缩机耐液仍未闭合。
4. 原 52 点正式矩阵统计不变；新增补算只作为用户指定的放宽 OER 边界证据。
