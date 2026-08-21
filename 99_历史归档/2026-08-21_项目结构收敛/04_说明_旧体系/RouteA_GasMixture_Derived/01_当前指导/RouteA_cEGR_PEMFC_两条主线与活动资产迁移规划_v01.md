# Route A cEGR-PEMFC 两条主线与活动资产迁移规划

文件类型：当前活动仓总规划与资产边界
日期：2026-08-17
状态：活动仓初始化完成；当前优先推进 V-SH 工程化基线，六配置矩阵仍为后续研究目标，现有结果按证据状态保留，不把未实现架构写成已完成。

## 1. 活动仓目标

本仓承载两个连续推进的主线：

1. `PEMFuelCellSystem_GasMixture_cEGR_RouteA_v01.slx` 及 Route A 仿真平台面板：维持单一正式模型和统一 runner，完成参数/观测/结果契约、操作闭环和代表性回归。
2. 阴极循环回路与电堆聚焦模型：在同一 case、参数、观测和结果契约下，比较两种电堆湿化方式与三种循环驱动方式，形成工程化选型证据。

当前完整系统主线转为维护和接口兼容状态；V-SH 聚焦主线优先完成 warning 清零、边界可变、240 kW 半定量标定和 CEGR/冷凝研究。聚焦主线不得复制完整系统 runner 来表达工况，也不得用尚未闭合的设备代理替代真实设备物理结论。

## 2. 2×3 目标矩阵

| 编号 | 湿化方式 | 循环方式 | 当前资产 | 当前证据状态 |
|---|---|---|---|---|
| V-SH | 自增湿电堆 | 阀门被动、空压机入口回流 | `PEMFuelCellSystem_Cathode_cEGR_SelfHumidifying_v01.slx` | 已建立；已有冷态和低负荷证据，适用范围仍是聚焦模型 |
| V-MH | 外部膜加湿器 | 阀门被动、空压机入口回流 | `PEMFuelCellSystem_Cathode_cEGR_Focused_v01.slx` | 当前是湿化接口/流阻代理，不等同于真实外部膜加湿器；不得作膜传质结论 |
| E-SH | 自增湿电堆 | 引射器被动、后压缩机回流 | `PEMFuelCellSystem_Cathode_cEGR_Ejector_SelfHumidifying_v01.slx` | 关闭模式可执行；开启模式因 FuelCell 域初值失败，状态为 `not_validated` |
| E-MH | 外部膜加湿器 | 引射器被动 | 待建立 | 不适用 |
| P-SH | 自增湿电堆 | 循环泵主动 | 待建立 | 不适用 |
| P-MH | 外部膜加湿器 | 循环泵主动 | 待建立 | 不适用 |

目标架构只能在完成端口、参数、守恒、初始化和最小行为验证后升级为活动配置。当前 `V-MH` 与 `E-SH` 的名称用于区分研究对象，不代表设备选型或工程验证已经完成。

## 3. 统一接口和比较指标

所有聚焦模型共用以下边界：

- `case`：电边界、阴极供气、cEGR、阳极、热、堆和设备参数；
- `runner`：`run_routeA_focused_study.m`，一次 study 只运行一个模型；
- 主回流率：分流点 `r_split=m_return/(m_return+m_exhaust)`；
- 辅助量：空压机入口混合比例 `x_comp_in`、新鲜空气基回流率 `r_fresh`、阴极入口 O2 分压、四组分 `m_H2O`；
- 设备比较：阀门压降、引射器 `omega_ejector`/压力窗口、泵流量/扬程/功耗；
- 水管理：水蒸气质量流率、露点裕度、饱和度和冷凝风险代理。液水库存、输运、分离效率、泵真实效率和膜加湿器跨膜传质未闭合前，结果只能用于筛选。

## 4. 迁移清单

### 保留

- 完整系统和聚焦模型 `.slx`、`EjectorFC.ssc`、引射器基准/组件测试模型；
- 两条主线的全部活动 `.m` runner、参数桥接、观测和结果分析脚本；
- `02_结果/RouteA_GasMixture_Derived`、`02_结果/RouteA_Cathode_cEGR_Focused` 和顶层 `outputs` 中与当前主线直接相关的结果；
- `01_当前指导/`、`02_实施记录/01_当前分卷/`、`03_审计与研究/` 及对应 README；
- 官方 Gas/Moist Air 参考示例、PEMFC/cEGR 相关文献和项目实验数据。

### 不迁移

- `99_历史归档/`、Route A v2/Before 副本、已封闭实施记录和旧交接材料；
- `slprj/`、`.slxc`、autosave、临时目录和客户端缓存；
- 与当前两条主线无直接运行或审计关系的 344 文件 FCEV 参考示例池；
- 重复的旧 runner、按工况复制的脚本和历史报告生成中间物。

源仓不删除任何文件。本仓的排除只表示当前活动边界，完整追溯仍回到源仓及其基线提交。

## 5. 实施顺序

1. 将完整系统面板保持在维护和接口兼容状态，仅处理共享脚本、契约和阻塞性缺陷；
2. V-SH-W0 warning 清零基线已完成，正式模型的结构、编译、运行和日志 warning 已清零；
3. 后续执行 V-SH-W1 case/边界契约，使简化阳极和固定堆温按研究工况可变并可追溯；
4. 执行 V-SH-W2 606 片、380 cm² 电堆及阴极 BOP 半定量标定；
5. 执行 V-SH-W3/W4/W5，完成阀门 CEGR 能力包络、气相冷凝风险和动态控制边界；
6. V-SH-W0 至 W5 全部通过后，才重新评估 E-SH、P-SH 和其他配置的准入；V-MH、E-MH、P-MH 不得以代理模型提前替代。

## 6. 证据语义

文档和结果必须区分 `implemented`、`structurally_verified`、`executed`、`behavior_verified`、`validated_for_scope` 和 `not_validated`。六配置矩阵中的空白项保持 `not_applicable` 或 `not_validated`，不得以模型文件存在代替工程结论。
