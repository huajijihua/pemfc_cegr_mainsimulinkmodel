# Route A cEGR-PEMFC 接口语义化与顶层端口收拢

日期：2026-08-18
类型：正式 Route A 模型结构实施记录
状态：已实现；结构已读回；已执行单工况烟测；工程/物理验证未完成

## 1. 前置决策与目标

- 当前结构指导：[RouteA_cEGR_PEMFC_系统可读化结构图_规划与边界_v01.md](../01_当前指导/RouteA_cEGR_PEMFC_系统可读化结构图_规划与边界_v01.md)
- 模型裁决：[RouteA_cEGR_PEMFC_模型裁决与资产处置_v01.md](../01_当前指导/RouteA_cEGR_PEMFC_模型裁决与资产处置_v01.md)
- 收敛路线：[RouteA_cEGR_PEMFC_收敛实施路线图_v01.md](../01_当前指导/RouteA_cEGR_PEMFC_收敛实施路线图_v01.md)
- 正式模型：`E:\agentwork_pemfc_cEGR_main\04_Simulink物理网络模型\01_模型\RouteA_GasMixture_Derived\PEMFuelCellSystem_GasMixture_cEGR_RouteA_v01.slx`

本切片针对顶层截图中 `Cathode_Air_cEGR_BOP`、`Stack_Core`、`Cathode_Exhaust_Backpressure_Water` 和 cEGR 路由选择器的 `ConnN`/`inputN`/`A/B` 语义不清问题，同时收拢简化后的阳极与热管理接口。

## 2. 实际修改

1. `Cathode_Air_cEGR_BOP`：将阀门命令、回流入口、堆入口和三个控制/观测输出改为语义名称；删除未参与顶层连接的 `Conn1`–`Conn4` 边界端口。
2. `Cathode_Exhaust_Backpressure_Water`：将排气来源、压力/温度/组分输入、流量测点和 cEGR 输出改为语义名称；删除原 `egr_mdot`、`exhaust_mdot`、`routeA_p_outlet` 自反馈边界输入，并在子系统内部把传感器/压力换算结果接入分离器计算；删除未被顶层使用的 `Conn` 辅助测量边界端口。
3. `Stack_Core`：将电端、阴极气体入口/出口、cEGR 测点、阳极供氢/排气和热节点端口由 `ConnN`、`B/B1/C` 改为介质、测点和能量语义名称。
4. cEGR 选择器：将 `cEGR_Mode_Selector` 重命名为 `cEGR_Gas_Route_Selector`，并将父级和 `cEGR_PassThrough_Route` 变体的 `A/B` 端口改为气体来源/去向语义。
5. `Anode_Hydrogen_BOP`、`Thermal_Management_BOP`：将简化后的阳极供氢/排气/吹扫和热管理节点分别封装、命名；同步改名 `System_Control_Observability` 的控制/观测端口，避免顶层出现 `In2`、`In3`、`In5` 或 `+/-` 等语义不明端口。

所有 `.slx` 结构修改通过 MATLAB MCP/SATK `model_edit` 完成，未按原始 XML/文本修改模型文件。

## 3. 结构读回与检查

验证面：MATLAB/Simulink R2025b，MATLAB MCP/SATK。

- `model_overview`/`model_read` 已读回四个目标子系统及阳极、热管理、控制观测子系统；目标边界不再显示原截图中的 `Conn3`、`Conn4` 或 `inputN`。
- 关键公共接口已可按空气、排气、cEGR、压力、温度、组分、阳极和热节点解释；`Stack_Core/cathode_chamber_temp_input` 保留为明确但当前顶层未接入的模型边界，未将其伪装成已闭合热边界。
- 根模型 `unconnected_lines`：`healthy`；根模型 `stateflow_lint`：`healthy`。
- 根模型 `model_check(all)`：74 条 warning、无 error；改动前基线为 77 条 warning。目标子系统仍有内部传感器辅助端口的既有未连接 warning，但没有新增悬空信号线错误。
- 模型保存后 `Dirty=off`。当前正式模型 SHA-256：`C67F54C6F4B9E1A48DBB9E059B2DA904DCF3B6FC63BEA21A615F45051FBA77E0`。

## 4. 单工况烟测

按正式 `simCase -> SimulationInput -> sim -> routeA_panel_extract_results` 链执行一次冷启动、`Current=100 A`、`stopTime=10 s`、`cegrEnabled=false`、`cegrRatio=0` 的结构烟测：

- `simCompleted=1`，模型运行完成；`voltage=402.858985 V`、`current=100 A`、`power=40.2858985 kW`。
- `steadyPassed=1`、`boundaryPassed=1`、`cegrPassed=1`、`saturationPassed=1`、`gasClosurePassed=1`。
- 正式 runner 返回 `completed_acceptance_failed` / `passed=0`，原因是观测注册量缺少单位元数据，以及液态水闭合仍不可用；这不是模型运行错误，也不能解释为全系统物理验证通过。

## 5. 未决风险与适用范围

- 本记录证明接口结构已实现、读回并完成有限烟测，不证明 cEGR 性能、冷凝路径、液态水守恒、耐久性、成本或控制策略已经验证。
- `Cathode_Exhaust_Backpressure_Water` 内部仍存在未对外暴露的传感器辅助端口 warning；后续若要清零 warning，必须先定义这些诊断量的观测契约，不能用无意义 Terminator 掩盖问题。
- `cathode_chamber_temp_input` 的热边界是否应接入 `Thermal_Management_BOP` 仍需基于官方组件语义和行为证据裁决。
- 面板输入/输出逐项行为审计仍为 `audit_pending`；本次没有把端口改名当作面板可信性证明。
