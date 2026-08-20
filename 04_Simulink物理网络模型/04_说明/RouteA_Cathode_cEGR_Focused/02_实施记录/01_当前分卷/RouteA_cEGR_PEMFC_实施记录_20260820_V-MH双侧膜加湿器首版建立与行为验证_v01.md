# Route A cEGR-PEMFC V-MH 双侧膜加湿器首版建立与行为验证

日期：2026-08-20
状态：`behavior_verified_for_focused_scope_not_device_validated`

## 1. 参考依据与建模裁决

本轮检索并参考了气-气膜加湿器的原始模型研究：

- Chen & Peng，2004，双控制容积热力学动态模型，DOI：<https://doi.org/10.1115/1.1978910>；
- Park et al.，2008，shell-and-tube 气-气膜加湿器动态模型，DOI：<https://doi.org/10.1016/j.ijhydene.2008.02.058>；
- 2013 年解析模型，明确考虑传质对传热的影响，DOI：<https://doi.org/10.1016/j.ijheatmasstransfer.2012.11.033>；
- 2017 年外部膜材料与集总传质参数分析，DOI：<https://doi.org/10.1016/j.ijhydene.2017.03.215>。

这些研究共同支持：干侧和湿侧是两个独立气体控制容积；水汽由两侧水汽分压差驱动；跨膜水传递必须在两侧质量账本中等量反向出现；水传递和热交换需要共同考虑。

## 2. 实际实现

正式模型：

`04_Simulink物理网络模型/01_模型/RouteA_Cathode_cEGR_Focused/PEMFuelCellSystem_Cathode_cEGR_ExternalMembraneHumidifier_v01.slx`

根层实际拓扑：

```text
Cathode_Air_Supply_and_cEGR
 -> Cathode_Membrane_Humidifier.DIn
 -> Dry_Side_Pipe_FC
 -> DOut
 -> Cathode_Inlet_Instrumentation
 -> PEMFC cathode inlet

PEMFC cathode outlet
 -> Cathode_Membrane_Humidifier.WIn
 -> Wet_Side_Pipe_FC
 -> WOut
 -> existing Cathode_Exhaust_and_Backpressure split
```

膜加湿器子系统使用：

- 两个官方 `FuelCell_lib/elements/Pipe (FC)`，分别承载干侧和湿侧气体库存、压降、温度和四组分状态；
- 两侧 `MIn` 由同一水通量状态生成 `[0;0;0;+J]` 与 `[0;0;0;-J]`；
- `J` 由湿侧与干侧 `p_H2O` 差驱动，并加入一阶动态状态；
- 两侧 `TIn` 使用膜界面温度一阶状态；
- 两个 Pipe 的热端口通过官方 `Conductive Heat Transfer` 连接；
- 无外部水源、无 N₂/O₂/H₂ 跨膜传递、无旁通、无液水库存和排液模型；
- 旧的四端口全代数自定义 `.ssc` 实验库已从正式模型和活动模型目录清理，不作为正式组件保留。

当前参数状态全部登记为 `engineering_assumption_pending_calibration`，包括水汽传递导纳、热导率、动态时间常数、干湿侧长度、面积、水力直径和粗糙度。

## 3. 验证证据

- 根层 `model_read` 确认没有新增公共背压阀，且湿侧出口接入原 V-SH 分流前的 `Cathode_Exhaust_and_Backpressure`；
- `model_check(root,["all"])`：`healthy`；
- 官方 MATLAB update/compile：通过；
- 10 s VariableStepAuto 冷启动 smoke：通过；
- 600 s 正式 `run_routeA_focused_study` 单工况：串行、5 A、`cEGR=0`、cold-start，`simCompleted=1`、`passed=1`；
- 正式 workflow gate：`passed_workflow_gate`，参数桥接写入点 37 个；
- 结果文件：

`04_Simulink物理网络模型/02_结果/RouteA_Cathode_cEGR_Focused/outputs/20260820_vmh_validation/RouteA_VMH_runner_smoke_600s_20260820.mat`

600 s case 尾窗读回：

- 水传递状态：`wet_to_dry`；
- 过滤后水传递平均值：约 `1.7216e-05 kg/s`；
- 干侧水汽分压平均值：约 `3215 Pa`；
- 湿侧水汽分压平均值：约 `4937 Pa`；
- 干/湿侧温度平均值均约 `353.15 K`。

结果字段已增加：

`performance.membraneHumidifier.drySide`、`wetSide`、`waterTransfer`、`heatTransfer`、`pressureDrop`、`massClosure`、`energyClosure`。

## 4. 供氧子系统封装收口（2026-08-20 续）

为使器件归属与模型层级一致，正式模型根层现只保留一个 `Cathode_Air_Supply_and_cEGR` 外壳，内部包含：

- `Fresh_Air_Compression_and_cEGR`：原 V-SH 供气、压缩机入口混合和被动回流阀核心；
- `Cathode_Membrane_Humidifier`：双侧膜加湿器；
- `Cathode_Inlet_Instrumentation`：膜干侧出口至电堆入口之间的入口测量链。

外壳接口读回为：

```text
PEMFC cathode outlet -> Cathode_Air_Supply_and_cEGR.membrane_wet_in
Cathode_Air_Supply_and_cEGR.membrane_wet_out -> Cathode_Exhaust_and_Backpressure split
Fresh_Air_Compression_and_cEGR -> membrane dry side -> inlet instrumentation -> PEMFC cathode inlet
```

本次只改变封装边界和接口命名，不新增公共背压阀、不改变 `V_EGR`/`V_BP` 两阀分流位置、不改变膜模型方程和参数。`model_read` 确认上述内部连接，`model_check(root,["all"])` 返回 `healthy`；官方 MATLAB update/compile 通过并保存后 `Dirty=off`。封装后的正式 600 s 回归为 Current 5 A、cEGR=0、cold-start、serial，`simCompleted=1`、`passed=1`，水传递方向仍为 `wet_to_dry`，尾窗过滤水传递均值约 `1.7216e-05 kg/s`。结果文件：

`04_Simulink物理网络模型/02_结果/RouteA_Cathode_cEGR_Focused/outputs/20260820_vmh_validation/RouteA_VMH_nested_air_supply_600s_20260820.mat`

## 5. 当前边界与剩余风险

- `drySide`/`wetSide` 当前是 Pipe 管内集总状态观测，不等同于设备四个端点的独立传感器读数；
- `pressureDrop` 当前标记为 `endpoint_sensor_pending`，尚未完成干/湿侧入口到出口的独立压力测点链；
- `massClosure` 当前是等量反向 `MIn` 的结构闭合，尚未用两侧独立质量流量传感器交叉验证；
- `energyClosure` 当前标记为官方 Pipe `MIn/TIn` 与导热墙存在，但尚未加入独立热流传感器或双侧能量账本；
- 传质导纳、热导率、几何和动态时间常数没有设备或试验标定，不能用于 A/B 性能排序、膜面积选型、净功率、耐久或产品额定结论；
- 当前结果仅支持 `behavior_verified_for_focused_scope`，不升级为膜加湿器硬件能力验证。

## 6. 下一步

1. 在干侧/湿侧入口和出口补齐独立 `p/T/y_i/m_dot/RH` 观测；
2. 用传感器读数建立膜两侧水量与能量闭合；
3. 登记膜厂商或试验数据，替换当前工程假设并做导纳、热导和容积时间常数敏感性；
4. 通过同一正式 runner 重跑 `cEGR=0`、小回流和目标回流三类工况；
5. 只有完成上述合同后，才与 V-SH 做湿度、露点、O₂、压力、流量和净功率比较。
