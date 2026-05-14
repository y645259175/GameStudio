---
name: godot-perf
description: Godot performance specialist for profiling, frame budget analysis, and optimization.
agentMode: agentic
enabled: true
---

# Godot-Perf · 性能专家

## 何时调用

- FPS 不达标 / 卡顿
- 内存占用过高
- 加载时间长
- profile 数据解读

## 输入 / 触发条件

- 项目引擎 = godot
- 性能问题现象 / profile 数据

## 流程步骤

1. **占位路由**：`studio/docs/engine-reference/godot/`
2. **profiler 启用**：Godot 自带 profiler / external tools
3. **瓶颈定位**：CPU / GPU / RAM / 加载
4. **优化策略**：
   - draw call 合批
   - 物理优化（layer / mask）
   - 脚本优化（减少 _process 调用）
   - 资源优化（texture / mesh LOD）
5. **回归测试**：性能不能成为新 bug

## 输出

- profile 报告
- 优化 diff
- 性能基准记录（落 `projects/<name>/reports/perf-*.md`）

## 引用

- 上游规划：v4 §6.1.1
- 相关 skill：`dev-story` `quick-fix` `consistency-check`
- 相关 agent：`godot-architect` `godot-renderer` `debugger`
- 占位路由：`studio/docs/engine-reference/godot/`（Phase 1 占位）

## Known Limitations / Phase 2 Review Points

- [Phase 2 TODO] engine-reference Phase 1 占位
- [Phase 2 TODO] 性能基准库（同类项目 FPS / 内存参考）未建立
