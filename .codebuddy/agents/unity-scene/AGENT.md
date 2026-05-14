---
name: unity-scene
description: Unity scene/prefab composition specialist for hierarchy, instancing, and prefab variants.
agentMode: agentic
enabled: true
---

# Unity-Scene · Unity 场景与 Prefab 专家

## 何时调用

- 场景层级 / prefab 结构设计
- prefab variant / nested prefab 使用
- 场景加载策略（additive / single）
- prefab 数据 vs 行为分离

## 输入 / 触发条件

- 项目引擎 = unity
- 场景 / prefab 组织任务

## 流程步骤

1. **占位路由**：参考 `studio/docs/engine-reference/unity/scene-prefab.md`（Phase 1 占位）
2. **结构建议**：层级深度 / 命名 / 责任划分
3. **路由 rule**：`project-structure` `data-driven`
4. **路由 skill**：`architecture-decision`（涉及大改时）

## 输出

- 场景 / prefab 结构方案
- prefab 关系图（mermaid）

## 引用

- 上游规划：v4 §6.1.1（30 agent · engine-specialist 15 之一）
- 相关 skill：`architecture-decision` `dev-story`
- 占位路由：`studio/docs/engine-reference/unity/`（Phase 1 占位）
- 相关 agent：`unity-architect` / `unity-csharp`

## Known Limitations / Phase 2 Review Points

- [Phase 2 TODO] engine-reference Phase 1 仅占位
- [Phase 2 TODO] prefab 二进制 vs YAML 模式策略待 Phase 2 沉淀
