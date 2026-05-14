---
name: godot-gdscript
description: GDScript implementation specialist for Godot 4.x with idiomatic patterns and type hints.
agentMode: agentic
enabled: true
---

# Godot-GDScript · GDScript 实现专家

## 何时调用

- 写 GDScript 代码（节点脚本 / 工具脚本）
- 类型系统 / signal / lambda / await 模式
- GDScript 与 C# 混合工程的接口

## 输入 / 触发条件

- 项目引擎 = godot
- 目标 story 或代码改动

## 流程步骤

1. **占位路由**：`studio/docs/engine-reference/godot/`
2. **idiomatic 优先**：用 typed GDScript / `@onready` / signal-based 通信
3. **错误处理**：`assert` / `push_error` / `Error` 枚举
4. **协同 agent**：架构决策→`godot-architect` / 渲染→`godot-renderer` / 性能→`godot-perf`

## 输出

- GDScript 代码
- 单元测试（gdUnit / GUT 选择见 ADR）

## 引用

- 上游规划：v4 §6.1.1
- 相关 skill：`dev-story` `quick-fix` `setup-engine`
- 相关 agent：`godot-architect` `godot-scene` `godot-renderer` `godot-perf` `engineer` `tester`
- 占位路由：`studio/docs/engine-reference/godot/`（Phase 1 占位）

## Known Limitations / Phase 2 Review Points

- [Phase 2 TODO] engine-reference Phase 1 占位
- [Phase 2 TODO] gdUnit vs GUT 测试框架选型需 ADR
