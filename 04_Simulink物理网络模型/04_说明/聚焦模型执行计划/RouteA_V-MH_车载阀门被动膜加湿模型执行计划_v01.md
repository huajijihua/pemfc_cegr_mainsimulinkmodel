# Route A V-MH 车载阀门被动膜加湿模型执行计划 v01

更新日期：2026-08-21
目标模型：`PEMFuelCellSystem_Cathode_cEGR_ExternalMembraneHumidifier_v01.slx`
参考模型：`PEMFuelCellSystem_Cathode_cEGR_SelfHumidifying_v01.slx`
目标结构：车载阀门被动式 cEGR + 外部膜加湿电堆系统
当前状态：`implemented_incomplete`；现有模型继续完善，不新建第二份 V-MH 模型。

本文件是交给低成本执行模型的施工合同。执行者应按阶段逐项完成，不重新设计项目路线，不复制 runner，不在没有读回证据时重构 V-SH。

## 1. 已确认的模型现状

本计划基于 2026-08-21 使用 MATLAB R2025b / Simulink 25.2 对正式模型的实际读回：

- V-SH 与 V-MH 均完成 update/compile，模型 `Dirty=off`。
- 两者共有堆和主要气路参数当前一致：606 片、380 cm²、`iL=2.5 A/cm²`、`io=2e-14 A/cm²`、`alpha=1`、膜厚 125 μm、阴极通道标称压降 0.0368422 MPa、标称流量 0.27182 kg/s。
- V-MH 保留 V-SH 的压缩机入口混合、被动回流阀、公共背压和堆核心，并把空气供应重组为：
  `Fresh_Air_Compression_and_cEGR → 膜加湿器干侧 → 阴极入口测量 → 电堆`。
- 电堆全量阴极出口先通过膜加湿器湿侧，再进入现有回流/排气分流：
  `电堆出口 → 膜加湿器湿侧 → 原 V-SH 分流与背压结构`。
- `Cathode_Membrane_Humidifier` 已包含干、湿两条 `Pipe (FC)`、水蒸气分压力差、线性传质系数、一阶传质状态、等量反向 H2O 质量源、一阶温度状态和壁面导热元件。
- 当前水源符号为：干侧 `[0;0;0;+1]·m_transfer`，湿侧 `[0;0;0;-1]·m_transfer`，因此代数上等量反向，但尚未由独立端点测量验证。
- 当前集总假设为：水传递系数 `1e-8 kg/(s·Pa)`、水传递时间常数 0.5 s、等效导热系数 `5 W/(m·K)`、温度时间常数 0.2 s；干湿侧长度均 1 m、流通面积均 0.01 m²、水力直径均 0.05 m。这些参数不是设备标定值。

## 2. 可直接复用的活动资产

| 资产 | 用途 | 使用边界 |
|---|---|---|
| V-SH 正式模型 | 共有堆、阀门回流、压力链、压缩机入口混合和观测基准 | 只读参考；V-MH 任务不得修改 |
| V-MH 正式模型 | 唯一施工目标 | 直接完善，不另存 `_v02`、`copy` 或阶段副本 |
| `run_routeA_focused_study.m` | 唯一正式执行入口 | 只扩展共用契约，不新建 V-MH runner |
| `routeA_focused_paths.m` | 已注册 `external_membrane_humidifier` | 保留现有 modelId |
| `routeA_focused_parameter_defaults.m` | 已有 `membraneHumidifier` 参数组和架构元数据 | 参数必须继续标为工程假设，不能提升为默认硬件事实 |
| `routeA_focused_case_template.m` | 已暴露 14 个膜加湿器参数 | 保持配置与执行分离 |
| `routeA_focused_parameter_bridge.m` | 已映射膜加湿器变量及单位 | 新参数必须在此登记来源和状态 |
| `routeA_focused_assess_outputs.m` | 已读取干/湿侧状态和水传递量 | 当前仅为管内状态，不是完整端点/账本 |
| `routeA_focused_performance_metrics.m` | 共有电、气、水、压力和控制 KPI | 需增加 V-MH 准入门，不改变 V-SH 指标口径 |
| 现有 V-SH 审计工作簿和紧凑 JSON | 选择共同代表工况和对比口径 | 不把 V-SH 结果当作 V-MH 设备验证数据 |

## 3. 当前缺口与禁止误判

1. 当前所谓干/湿侧“压力”是各自 Pipe 内部状态，不能直接当成入口—出口压降；四端 `p/T/y_i/m_dot` 测点尚未闭合。
2. 水传递等量反向由模型连线构造，不等于独立水量账本通过；缺少干湿侧入口/出口 H2O 质量流率核对。
3. 壁面导热块虽然引用 `membrane_humidifier_heat_conductivity_W_per_m_K`，但面积和厚度仍固定为 1，当前实质是集总等效导热，不是膜组件几何模型。
4. 线性 `Δp_H2O` 传质没有明确的可用水蒸气上限、反向传质策略和质量分数非负保护；必须验证低湿、高湿和接近饱和边界。
5. `routeA_focused_assess_outputs` 已能读内部状态，但 `pressureDrop.status` 仍为 `endpoint_sensor_pending`，能量闭合仍为未独立测量。
6. 当前只证明 update/compile 通过，不能据此声明 V-MH 行为验证或设备性能正确。
7. 无实验标定前禁止输出膜面积选型、额定加湿能力或 V-MH 优于 V-SH 的硬件裁决。

## 4. 施工阶段

### M0 共有基准锁定

允许修改：无；只读 V-SH、V-MH 和共用脚本。

1. 记录 V-SH 与 V-MH 的模型 checksum、solver、共有模型工作区参数和顶层连接。
2. 形成机器内存中的共有参数差异表；V-MH 除膜加湿器新增参数和拓扑外，共有堆、气路、环境、控制和边界必须与冻结后的 V-SH 一致。
3. 若 V-SH 尚未完成参考冻结，停止永久结构修改，只完成 V-MH 缺口定位。

出口：共有参数无未解释差异；目标模型仍为唯一正式文件。

### M1 四端测量合同

允许修改：V-MH 模型、现有共用观测/评估函数。

1. 在 DIn、DOut、WIn、WOut 四个真实端点设置或复用以下测量：绝对压力、温度、四组分、总质量流率、H2O 质量流率和能量流率。
2. 统一信号名为 `routeA_membrane_{dry|wet}_{in|out}_...`，明确单位和方向；不得继续用 Pipe 内部状态冒充端点。
3. 保留内部 Pipe 状态作为诊断量，但在结果结构中与端点测量分栏。
4. 计算干、湿侧真实压降，并记录是否出现反向流。

出口：四端信号均能从一个最小运行中读出；缺失信号导致 V-MH 验收失败，而不是填 NaN 后继续比较。

### M2 水量、能量与数值保护

1. 水量账本至少计算：
   `Δm_H2O,dry = m_H2O,dry,out - m_H2O,dry,in`，
   `Δm_H2O,wet = m_H2O,wet,out - m_H2O,wet,in`，
   并检查 `Δm_H2O,dry + Δm_H2O,wet` 的闭合误差。
2. 比较端点实测转移量与 `routeA_membrane_water_transfer_kg_s`，不得只检查命令量。
3. 增加可用水蒸气和质量分数非负保护；限制策略必须连续、可读回，并在结果中报告是否触发。
4. 记录导热块热流及干湿侧能量流差；若现有组件无法形成完整能量闭合，明确拆分为“壁面热传递观测”和“未闭合项”，不能伪造守恒通过。
5. 把面积、厚度或等效 UA 的物理含义裁决为一种口径。推荐在缺少设备几何时显式使用 `effective_UA_W_per_K`，避免 `k=5 W/(m·K), A=1, L=1` 被误解为真实膜参数。

出口：水量闭合误差、能量状态、限制器状态均进入 `result.performance.membraneHumidifier`。

### M3 参数与执行接口

1. 在 defaults/case/bridge 中把膜参数分为：几何/流阻、传质、传热、动态、数值保护五组。
2. 每个参数记录单位、来源类别、允许范围和 `pending_calibration` 状态。
3. `run_routeA_focused_study` 继续通过 `SimulationInput` 写入模型工作区；不得永久改写模型来表达工况。
4. 在 preflight 中增加：正几何、正时间常数、传质/传热非负、干湿侧方向和四端观测可用性检查。

出口：一个 case 可以完整回显“配置值 → bridge 写入点 → 模型变量 → 结果字段”。

### M4 最小行为验证

只运行三个代表工况，不先跑全矩阵：

| 工况 | 目的 | 最小检查 |
|---|---|---|
| 低负荷、cEGR=0 | 干侧低水需求和数值基线 | 无负质量分数；水传递方向合理；压降有限 |
| 中负荷、中等 cEGR | 标称传质/传热行为 | 四端账本、阴极入口 RH/O2、压力链、稳态性 |
| 高负荷、低到中等 cEGR | 设备能力与供氧边界 | 不因线性传质源造成非物理水量；氧计量比和控制限制明确 |

优先使用现有 `routeA_focused_external240kw_case_factory` 生成共同基准，再只覆盖 V-MH 专属参数。每次只改变一类因素。

出口：三个工况均有结构化结果；失败必须保留首个真实错误和类别。

### M5 收口

1. 独立读回模型结构和关键参数，重新 update/compile。
2. 保存正式模型并确认 `Dirty=off`。
3. 更新现有 runner README、`PROJECT.md` 状态和紧凑结果；不新增第二份计划、runner 或过程报告。
4. 状态最高只能提升到 `behavior_verified_for_focused_scope_not_device_calibrated`。

## 5. 验收门

- 四端真实测点可用，干湿侧压降口径正确。
- H2O 端点账本和模型传质量可交叉核对；误差阈值在运行前固定。
- 无负质量分数、无未解释反向流、无用内部状态冒充端点。
- 共有 V-SH 参数无未解释漂移。
- 三个代表工况完成，失败边界有分类。
- update/compile 通过、正式文件已保存、`Dirty=off`。
- 未使用实验数据时，报告明确写为未标定工程模型。

## 6. Luna 执行约束

- 开工先连接 MATLAB MCP，报告 PID、版本、工作目录；核心 MCP 不可用就停止模型任务。
- 第一轮只完成 M0–M1；读回通过后再做 M2，禁止一次性大改模型和全部脚本。
- 不修改 V-SH，不创建 V-MH 副本，不新建 runner。
- 遇到结构与本计划不一致时，以模型读回为事实并停止到当前阶段，不自行改变系统边界。
