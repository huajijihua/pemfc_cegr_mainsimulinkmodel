# 当前指导文件

本目录是 Route A 当前的设计、裁决、实施和验证指导层。文件是规划性真源，不等同于已通过的仿真结果。

聚焦模型专项的当前指导和实施记录已归位到 `../../RouteA_Cathode_cEGR_Focused/`；本目录保留完整系统、平台共用和活动仓级指导。

阅读顺序：两条主线与活动资产迁移规划 -> 模型裁决与资产处置 -> 收敛实施路线图 -> 外部案例与归档资产索引 -> 仿真工具链与协同接口约束 -> 平台能力建设需求 -> 面板-模型双向迭代规划 -> P0 迁移与接口收口实施计划 -> P1 完整燃料电池系统面板基础版实施计划 -> P2 面板修复和操作性提升实施计划 -> P3 阳极与系统性能参数开放实施计划 -> P5 仿真平台前端输入能力 -> S6 被动 cEGR 研究规格与预检计划 -> P1 面板能力矩阵 -> 控制接口汇总表 -> CR3 三要素 schema -> 系统规格 -> 架构规格 -> 实施计划 -> 测试计划。

| 文件 | 状态 | 用途 |
|---|---|---|
| RouteA_cEGR_PEMFC_两条主线与活动资产迁移规划_v01.md | **当前活动仓总规划** | 两条主线、2×3 架构矩阵、迁移保留/排除边界和证据语义 |
| RouteA_cEGR_PEMFC_模型裁决与资产处置_v01.md | 当前决策真源 | 唯一主模型、v2 归档和历史资产处置 |
| RouteA_cEGR_PEMFC_收敛实施路线图_v01.md | 当前路线真源 | S0-S3 已完成，S4 cold-only 与 Voltage purge 周期门已收口，S5 P0 3600 s 已通过；P1 单工况面板闭环实施中 |
| RouteA_cEGR_PEMFC_外部案例与归档资产索引_v01.md | 当前资产边界 | 外部案例恢复前置、历史台架入口与默认参数隔离 |
| RouteA_cEGR_PEMFC_仿真工具链与协同接口约束_v01.md | 当前工具链约束 | Route A 系统主线、COMSOL server、AMESim 外部协同和接口契约 |
| RouteA_cEGR_PEMFC_平台能力建设需求_v01.md | **新阶段起点** | 平台能力升级需求定义、原则、执行路线图 |
| RouteA_cEGR_PEMFC_面板-模型双向迭代规划_v01.md | **用户确认目标** | 迁移边界、系统优先级、参数开放、cEGR 控制语义、结果分级和后续阶段 |
| RouteA_cEGR_PEMFC_P0_迁移与接口收口实施计划_v01.md | **P0 当前实施计划** | 路径入口、依赖检查、参数/观测量注册、model contract 和 P0 出口门 |
| RouteA_cEGR_PEMFC_P1_完整燃料电池系统面板基础版实施计划_v01.md | **P1 基础实施计划** | 面板直驱主线的系统域、参数白名单、操作语义、结果反馈、工作包和用户联合评审 |
| RouteA_cEGR_PEMFC_P2_面板修复和操作性提升实施计划_v01.md | **P2 当前实施计划** | 两栏布局、四层配置、输入单位/RH 温度语义、高级分组、帮助层和结果图像历史 |
| RouteA_cEGR_PEMFC_P3_阳极与系统性能参数开放实施计划_v01.md | **P3 当前实施计划** | 阳极输入语义与范围、cEGR 控制器、电堆性能参数和首轮双向链路 |
| RouteA_cEGR_PEMFC_P5_仿真平台前端输入能力_v01.md | **当前前端能力** | 五页签职责、设备参数开放规则、草稿工况和输入边界 |
| RouteA_cEGR_PEMFC_S6_被动cEGR研究规格与预检计划_v01.md | **被动基线专题规格** | 被动 cEGR 已执行矩阵和专题门槛；后续架构扩展服从工程化架构总规划 |
| `../RouteA_Cathode_cEGR_Focused/01_当前指导/README.md` | **聚焦模型专项入口** | V-SH、V-MH、引射器架构和聚焦模型实施记录的当前指导入口 |
| RouteA_cEGR_PEMFC_P1_面板能力矩阵_v01.md | **P1 开发追踪矩阵** | active 参数到 UI/simCase/SimulationInput、22 个结果观测、4 个 status-only 项；不作为历史验收包 |
| RouteA_cEGR_PEMFC_控制接口汇总表_v01.md | **Phase A 产出** | 平台能力清单，所有可控制量/可观测量定义 |
| RouteA_cEGR_PEMFC_CR3三要素schema_v01.md | **Phase A 产出** | 标准化 simCase 输入格式定义 |
| RouteA_cEGR_PEMFC_Platform_system_v01.md | 当前规格 | 平台目标、u/w/y/z 和适用范围 |
| RouteA_cEGR_PEMFC_Platform_architecture_v01.md | 当前规格 | 官方组件、cEGR 和参数/状态架构 |
| RouteA_cEGR_PEMFC_Platform_implementation-plan_v01.md | 当前低层计划 | 规格冻结后的实现拆解 |
| RouteA_cEGR_PEMFC_Platform_test-plan_v01.md | 当前平台验证计划 | 保留平台 Gate 和历史证据；P1 只按需使用最小开发期 smoke，不作为面板操作前置包 |

本仓当前按两个主线推进：完整系统/面板主线与阴极回路聚焦模型主线。聚焦模型的最终目标为自增湿/外部膜加湿 × 阀门被动/引射器被动/循环泵主动六配置；已有模型和结果只代表各自证据范围，未实现或未运行的配置保持未验证。当前核心路径仍是“控件 -> `draftSimCase` -> `SimulationInput` -> 当前模型 -> 窗口反馈”；单工况入口、结果契约和控件联动用于支撑系统平台，聚焦研究使用统一 `run_routeA_focused_study.m`。
