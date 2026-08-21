# Route A 当前工程契约

更新日期：2026-08-21
本文件只保存两条活动主线共同需要的工程边界。项目状态和下一步见根目录 `PROJECT.md`；旧计划、实施记录和专题审计已整体归档到 `99_历史归档/2026-08-21_项目结构收敛/04_说明_旧体系/`，不再作为默认上下文。

## 1. 活动主线

### 完整系统/面板

- 正式模型：`01_模型/RouteA_GasMixture_Derived/PEMFuelCellSystem_GasMixture_cEGR_RouteA_v01.slx`
- 正式 runner：`03_脚本/RouteA_GasMixture_Derived/run_routeA_electrical_boundary_study.m`
- 面板入口：`03_脚本/RouteA_GasMixture_Derived/launch_routeA_panel.m`
- 初始化：活动链使用 `cold_start_only`，不把历史 operating point 作为运行前置。
- 电边界：Current/Power/Voltage 统一映射到同一个内部 `I_cmd`，不复制 plant。
- 当前状态：结构已实现并读回，已有有限烟测；观测单位元数据和液态水闭合未完成，不能称为整机工程验证通过。

### 阴极回路 + 电堆聚焦模型

- 正式 runner：`03_脚本/RouteA_Cathode_cEGR_Focused/run_routeA_focused_study.m`
- V-SH：车载阀门被动/自增湿，是已有行为证据的候选核心参考模型；结构、参数和代表工况重新闭环后才能冻结为派生基准。
- V-MH：车载阀门被动/外部膜加湿，正式模型已存在但工程闭环未完成。
- E-SH：车载引射器被动/自增湿，已有原型、组件库和测试资产，但尚不是完成配置，也不代表引射器性能已验证。
- E-MH、P-SH、P-MH：车载目标配置，尚未建立正式系统模型。
- V-Bench：阀门被动式台架扩展，等待用户提供真实结构；标定等待实验团队数据。
- `PEMFuelCellSystem_Cathode_cEGR_Focused_v01.slx` 是公共接口基线，不计作额外架构成果。

## 2. 物理与参数边界

- 优先复用 MathWorks 官方 Gas Mixture/Fuel Cell/Simscape 组件、求解器和工作区设置。自定义范围限于 cEGR 支路、膜加湿器、引射器适配和必要接口。
- 参数分为 `platform_default`、`scaling_rule`、`external_case`、`bench_case`、`study_command`、`result_audit`。旧标定、10 kW/DQ60、外部 240 kW 和未来台架数据不得覆盖平台默认值。
- cEGR 主指标为分流点
  `r_split = m_return / (m_return + m_exhaust)`；同时报告压缩机入口混合比例、新鲜空气基回流率、入口氧分压、湿度口径和压力链。
- `cegr_ratio_cmd` 是目标/研究命令，不是实际质量流量。实际回流必须服从压力差、阀/引射器/泵、管路和混合边界。
- V-SH 当前结论只覆盖气相、接口和已执行工况；不覆盖液滴、分离效率、排液、压缩机耐液、阀门选型、系统净功率或产品额定。
- V-MH 跨膜水与热传递参数仍属于待标定工程假设；在端点测量、水量和能量账本闭合前，不进行硬件尺寸或 A/B 性能裁决。

## 3. 执行与验证

1. 每个任务先固定系统边界、输入输出与单位、参数来源、工况、KPI、验证数据和停止条件。
2. 首次使用 MATLAB 时按根目录 `AGENTS.md` 完成核心 `matlab` 与项目 `satk` 双通道握手；两通道必须连接同一任务专属 PID，并与其他并行任务的 PID 不同。
3. 按“最小基线 → 一个代表工况 → 单因素诊断 → 必要矩阵”推进。
4. 新工况通过 case/profile/`Simulink.SimulationInput` 表达，不复制模型或 runner。
5. 结构修改必须走 SATK 的 `model_overview/model_read -> model_edit -> model_read -> model_check`，随后完成 update/compile、诊断检查、最小运行，并确认 `Dirty=off`。
6. 分别报告已实现、已读回、已执行、行为验证和工程适用范围；失败工况及第一条真实错误必须保留。

## 4. 证据与结果

- 活动区保留：正式模型、正式 runner、必要输入、紧凑 Markdown/CSV/JSON、当前工作簿和少量必要图片。
- 原始 MAT 时序和批量矩阵若对复现或审计有用，可以保留在受控结果目录，但默认不进入 Git；缓存和完整日志不作为证据真源。
- 当前工作簿与紧凑结果位于 `02_结果/`。runner 可以使用受控运行子目录，但单次研究完成后只提升最终报告和必要摘要，避免按每次异常继续复制层级。
- 新能力、阶段出口或阻塞闭环直接更新根目录 `PROJECT.md` 和本文件相关边界；只有确需审计追溯时，才在归档批次中增加一份记录。
- 查历史时从归档批次的 README 进入，只读取与目标问题直接相关的文件。

## 5. 当前下一门槛

- 聚焦主线优先于完整系统，阶段顺序固定为：V-SH 参考冻结 → V-MH/E-SH 闭环 → E-MH/P-SH → P-MH → 六配置一致性回归 → 台架扩展 → 实验标定。
- V-SH 当前只重跑低/中/高代表工况，先核对结构、参数链及既有氧供、阀饱和、冷凝和质量分数失败，不直接扩大矩阵。
- V-MH 必须补齐端点 `p/T/y_i/m_dot/RH`、跨膜水/热传递、压降以及水量/能量账本；无实验数据时只允许达到适用范围内行为验证。
- E-SH 在组件级压力、流量和效率证据闭合前，不进入系统性能对比。
- E-MH、P-SH、P-MH 只有上游参考架构和接口通过阶段门后才建立；每个架构仍复用同一正式 runner。
- V-Bench 在用户提供结构前保持 `specification_pending`；实验数据到位前不执行参数辨识或宣称标定完成。
- V-MH、E-SH、P-SH 的实际资产、施工阶段和验收门分别见 `聚焦模型执行计划/` 下三份按需读取的执行计划；根目录 `PROJECT.md` 只保存当前状态和路由。
