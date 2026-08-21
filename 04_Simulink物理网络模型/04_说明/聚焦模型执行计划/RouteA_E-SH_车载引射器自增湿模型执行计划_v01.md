# Route A E-SH 车载引射器自增湿模型执行计划 v01

更新日期：2026-08-21
目标模型：`PEMFuelCellSystem_Cathode_cEGR_Ejector_SelfHumidifying_v01.slx`
参考模型：`PEMFuelCellSystem_Cathode_cEGR_SelfHumidifying_v01.slx`
目标结构：车载引射器被动式 cEGR + 自增湿电堆系统
当前状态：`prototype_incomplete`；保留现有原型和组件资产，先完成构成与接口闭环，再进入系统比较。

本文件是交给低成本执行模型的施工合同。现有 E-SH 不是可直接调参的完成模型；执行者不得绕过组件证据直接打开引射器跑性能矩阵。

## 1. 已确认的模型与组件现状

本计划基于 2026-08-21 使用 MATLAB R2025b / Simulink 25.2 的实际读回：

- E-SH 正式模型在把模型目录加入 MATLAB path 后可解析 `RouteAEjector_lib`，update/compile 通过且 `Dirty=off`。
- 顶层三端连接已经存在：引射器 A 口连接压缩机/中冷器后的主流，S 口连接阴极尾气回流支路，B 口连接阴极入口测量和堆入口。
- 三端均已有压力/温度传感器；阴极入口已有质量流量、组分/RH 观测，尾气侧已有回流/排气流量、出口湿度和公共背压结构。
- 现有 `+RouteAEjector/EjectorFC.ssc` 是 FuelCell 四组分域的三端准稳态自定义组件，包含总质量、四组分质量和能量守恒方程；不含液滴、激波、阻塞流或真实几何流场。
- `RouteAEjector_lib.slx` 提供 `Ejector (FC)`，系统模型引用链接已解析。
- `RouteA_Ejector_Gas_Benchmark_v01.slx` 使用 MathWorks 官方 `Ejector (G)`，只能作为 Gas 域压力窗参考，不能直接连接 FuelCell 四组分网络。
- `RouteA_Ejector_FuelCell_ComponentTest_v01.slx` 是自定义 FuelCell 域组件测试台；两个组件测试模型均 update/compile 通过。
- `run_routeA_ejector_g_pressure_window_scan.m` 已能扫描官方 Gas 域主流/吸入/出口压力窗并报告引射比和质量闭合。
- 当前系统模型工作区 `ejector_enabled=false`。关闭状态下组件约束为 A/B 等压且 S 口零流量，因此现状不是已启用引射器系统。
- 当前几何与效率值均为工程假设：喉部面积 4.2e-4 m²、喷嘴面积比 3、混合面积比 8、主/次效率 0.90/0.82、膨胀/混合效率 0.80/0.78、压力恢复系数 1.05。
- E-SH 持久化堆参数 `stack_io=1e-4 A/cm²`、`stack_alpha=0.7`，与 V-SH 的 `2e-14 A/cm²`、`1.0` 不一致；runner 可以覆盖，但正式默认值仍需裁决和归一。
- E-SH 顶层组织来自另一条系统结构，与 V-SH 的六个模块化顶层子系统不同。不能仅凭同名参数认定两个模型可比较。

## 2. 可直接复用的活动资产

| 资产 | 用途 | 使用边界 |
|---|---|---|
| V-SH 正式模型 | 共有堆、边界、求解器、KPI 和参数真源 | 只读；作为共性契约，不复制其被动阀驱动机制 |
| E-SH 正式模型 | 唯一系统施工目标 | 不创建第二份 E-SH 模型 |
| `+RouteAEjector/EjectorFC.ssc` | FuelCell 四组分域引射器构成 | 允许修改，但每次先在组件测试台验证 |
| `RouteAEjector_lib.slx` | 正式组件库 | 必须保持链接可解析，不能断链后在系统内私改副本 |
| 两个引射器组件测试模型 | 官方 Gas 域参考和 FuelCell 域单元验证 | 先组件、后系统 |
| `run_routeA_ejector_g_pressure_window_scan.m` | 官方 Gas 域压力窗参考 runner | 不是 E-SH 系统性能 runner |
| `run_routeA_focused_study.m` | 唯一系统 runner | 已支持 ejector modelId 和参数覆盖；不得新建 E-SH runner |
| paths/defaults/case/bridge | 已注册 `ejector_self_humidifying` 和 15 个引射器参数 | 需修正默认状态和参数来源，不扩散新入口 |
| pressure/water/performance assessment | 可复用 V-SH KPI 口径 | 需增加引射器三端和引射比专属结果 |

## 3. 当前缺口与禁止误判

1. `ejector_enabled=false` 是当前第一阻塞，不能把零吸入冷基线称为引射器回流。
2. 现有构成以平滑压差—流量关系近似引射器，不包含临界流、激波和详细喷嘴/混合室机理；只有组件级压力窗证据通过后才能进入系统。
3. 官方 `Ejector (G)` 与自定义 FuelCell 域组件的参数定义不完全相同，不能直接把官方参数复制过来。
4. E-SH 共有堆参数存在持久化漂移，必须先与冻结 V-SH 对齐；不能依赖 runner 临时覆盖掩盖模型默认错误。
5. E-SH 顶层接口和观测命名与 V-SH 有差异，必须建立显式映射；不要求为了视觉一致而大规模重构，但比较所需信号必须语义等价。
6. 引射器是被动器件，目标回流率是结果而不是可任意跟踪的控制命令。不能继续用 V-SH 阀面积控制逻辑假装引射器能跟踪 `cegr_ratio_cmd`。
7. 无实验或可信构成数据时，不能宣称引射器尺寸、效率或车载工况性能已经验证。

## 4. 施工阶段

### E0 路径、共性参数与接口归一

1. 开始任务时把正式模型目录加入 MATLAB path，加载 `RouteAEjector_lib`，确认系统引用 `LinkStatus=resolved`。
2. 对 V-SH 与 E-SH 的共有堆、环境、阴极通道、压缩机、热边界和 solver 参数逐项比对。
3. 裁决并修正持久化 `stack_io/stack_alpha` 等共有参数；任何保留差异必须有独立来源，不能只写“历史值”。
4. 建立 V-SH KPI 到 E-SH 实际信号的映射：堆 I/V/P、阴极入口/出口、主流/吸入/混合出口 p/T/y_i/m_dot、排气流量、氧计量比和气相水指标。
5. 禁用 V-SH 专属阀面积跟踪验收；E-SH 将几何、主流压力和背压作为决定回流能力的变量。

出口：共有参数无未解释差异；组件库链接稳定；专属 KPI 合同固定。

### E1 官方 Gas 域参考压力窗

1. 使用 `run_routeA_ejector_g_pressure_window_scan.m`，从 V-SH/E-SH 预期压力链选择少量边界点，不扩大 DOE。
2. 至少覆盖：正常吸入、接近零吸入、反向流风险、出口背压偏高四类压力关系。
3. 保存官方 `Ejector (G)` 的主流量、吸入流量、出口流量、引射比、方向和质量闭合摘要。
4. 明确官方 Gas 域只提供趋势/压力窗，不作为四组分系统定量标定真值。

出口：得到自定义 FuelCell 组件必须覆盖的压力窗和方向判据。

### E2 FuelCell 域组件构成验证

只修改 `EjectorFC.ssc`、组件库及 FuelCell 组件测试台，不先修改系统模型。

1. 分别验证 `enabled=false` 和 `enabled=true`；关闭时 S 口近零流量，开启时在合适压力窗出现正吸入。
2. 检查三端总质量、四组分质量和能量闭合；检查所有组分非负、压力/温度域断言和反向流行为。
3. 对喉部面积、面积比、效率和背压做单因素扰动，要求流量方向和引射比趋势物理一致。
4. 与 E1 官方 Gas 域对比压力窗和单调趋势；明显冲突时先修构成，不进入系统。
5. 若当前平滑压差关系无法覆盖基本趋势，允许重构 `EjectorFC.ssc`；但不在同一轮同时改系统控制和共有参数。

出口：组件测试台 update/compile、最小仿真和守恒检查通过；参数仍标记为工程假设或拟合候选。

### E3 系统集成与启用

1. 在现有 E-SH 正式模型中启用经过 E2 验证的组件；不复制模型。
2. 核对 A=后中冷器主流、S=阴极尾气回流、B=堆入口混合流的端口语义和流量符号。
3. 保留三端 p/T 测量，并补齐三端组分、总质量流率、H2O 质量流率和能量流率。
4. 明确回流分流点、排气背压位置和可选气相分离边界；当前不模拟真实液滴分离时保持 `gas_phase_only`。
5. 为不可行压力关系设置可观测的隔离/旁通策略，不通过负面积或伪造阀命令强制回流。

出口：E-SH 在 `ejector_enabled=true` 下完成 update/compile 和一个最小稳态运行。

### E4 runner 与结果合同

1. 继续使用 `ejector_self_humidifying` modelId 和统一 runner。
2. preflight 检查：库链接、enabled 状态、正几何、面积比关系、效率范围、压力窗和端口测量可用性。
3. 新增结果字段：三端 p/T/y_i/m_dot/能量流、引射比 `m_secondary/m_primary`、回流分流比 `r_split`、压力恢复、反向流状态和构成参数状态。
4. 对 E-SH，`cegr_ratio_cmd` 只能作为研究目标/参考；验收报告实际回流及偏差，但不把偏差自动归为控制失败。
5. 保留共有 V-SH 电、氧、水、压力和稳态 KPI，增加 `ejectorConstitutivePassed` 与 `ejectorFlowDirectionPassed`。

出口：配置—参数桥—组件—结果字段可全链回溯。

### E5 系统代表工况

按以下顺序执行，每次只改变一类因素：

1. 引射器关闭的同边界冷基线，用于确认系统其余部分与共有合同一致。
2. 中负荷、可行压力窗、引射器开启，验证正吸入和三端守恒。
3. 低负荷/小主流边界，识别失去吸入能力的下限。
4. 高负荷或高背压边界，识别构成、氧供和数值上限。

不先运行全工况矩阵。只有四个代表性类别可解释后，才扩大面积比或压力窗扫描。

### E6 收口

1. 独立读回系统、库和 `.ssc` 参数；重新 update/compile。
2. 保存正式模型和库并确认 `Dirty=off`；运行必要组件测试。
3. 更新现有 README、`PROJECT.md` 状态和紧凑结果，不新增 runner 或过程报告。
4. 无实验数据时最高状态为 `behavior_verified_for_focused_scope_not_ejector_device_validated`。

## 5. 验收门

- `ejector_enabled=true` 的有效工况真实产生正吸入流。
- 三端总质量、四组分和能量闭合满足运行前固定的阈值。
- 共有 V-SH 参数无未解释漂移，特别是 `stack_io/stack_alpha`。
- 官方 Gas 域与自定义 FuelCell 域在压力窗和趋势上无未解释冲突。
- 反向流、零吸入和高背压边界被显式分类。
- V-SH 阀控制指标未被误用于 E-SH。
- 系统、组件库和测试模型 update/compile 通过，正式资产 `Dirty=off`。

## 6. Luna 执行约束

- 第一轮只执行 E0–E1；第二轮只处理 E2；组件门通过后才进入 E3。
- 不同时修改 `.ssc` 构成、系统控制和堆参数。
- 不断开库链接后私改系统内组件副本，不创建 E-SH `_v02`。
- 如果组件趋势不能与官方 Gas 域形成合理解释，停止在 E2，不靠调系统参数掩盖。
