# Team Mode SOP · 何时用 Subagent 并行

## 能力确认

CodeBuddy 的 task 工具支持两种模式：

| 模式 | 触发条件 | 行为 |
|---|---|---|
| **Synchronous Subagent**（同步） | 不传 `name` 参数 | 主 agent 阻塞等待，子 agent 完成后返回结果 |
| **Team Mode**（异步并行） | 传 `name` 参数 | 子 agent 异步在后台运行，主 agent 立即继续；通过 `send_message` 通信 |

已通过实测验证（2026-05-15）：可同时 spawn 多个 agent，每个有独立 inbox，支持 shutdown 协议。

## 何时用 Team Mode（适用场景）

| 场景 | 例子 | 为什么 |
|---|---|---|
| **多领域独立分析** | 同时让 designer 写 GDD + architect 出技术方案 + art-director 出风格方向 | 三个领域无依赖，并行省时间 |
| **批量出图/出文档** | 同时让 timiai-image 出 5 张不同道具图标 | I/O 密集，异步明显加速 |
| **多 agent code review** | reviewer 看代码风格 + qa 看测试覆盖 + architect 看架构合规 | 同样的 diff 多视角并审 |
| **跨项目操作** | 同时给 3 个项目各跑一次 consistency-check | 项目间独立，互不影响 |
| **长任务后台化** | 让 timiai-image 慢慢出 high quality 图（30-60s），主 agent 继续做别的 | 不浪费等待时间 |

## 何时不用 Team Mode（坚持串行）

| 场景 | 为什么 |
|---|---|
| **强依赖链** | designer 的 GDD 是 pm 拆 epic 的输入 → 必须串行 |
| **单一逻辑流程** | 一个 story 的 dev-story 流程（写代码 → 测试 → 审查 → 提交）→ 串行符合直觉 |
| **小任务** | < 5 秒就能跑完的，并行的协调成本反而高 |
| **需要看到中间结果再决策** | 如 architect 给方案后用户要选择，再让 engineer 实现 |

## SOP 改造建议（针对工作室既有 skill）

| Skill | 当前 | Team Mode 后可优化 |
|---|---|---|
| `design-review` | designer 起草 → reviewer 审 → 落盘 | designer + ux-designer + art-director **并行**出三个维度（功能/交互/视觉）→ 主 agent 汇总 |
| `create-stories` | 串行拆 5-10 个 story | 仍串行（story 之间常有依赖）|
| `dev-story` | engineer 写 → tester 写测试 → reviewer 审 | engineer 串行（强依赖），但 tester 和 reviewer 可在 engineer 完成后**并行** |
| `consistency-check` | 4 维度逐个扫 | 4 维度（GDD↔code / 数值↔code / ADR↔code / AC↔code）**并行** |
| `art-asset-pipeline` | 一次出 1 张 | 一次出 N 张时 **并行** spawn N 个 timiai-image 调用 |
| `review-all-gdds` | 逐章扫 | 章节多时 **并行** 扫多章 |
| `smoke-check` | 顺序跑各项 | 测试套件 + consistency + 引擎校验 **并行** |

## 使用语法

### Spawn

```
task(
  subagent_name="reviewer",
  name="my-reviewer",         ← 关键：传 name 进入 Team Mode
  team_name="sprint-2-review", ← 同一 team 名让 agent 互相看见
  prompt="..."
)
```

### 通信

```
send_message(
  type="message",
  recipient="my-reviewer",
  content="...",
  summary="..."
)
```

### 关闭

```
send_message(type="shutdown_request", recipient="my-reviewer", content="done")
# 等待 shutdown_response
team_delete()  # 或者 agent 自然完成 max_turns
```

## 常见陷阱

1. **不要忘了关 team**：team_delete 之前所有成员必须 idle 或 shutdown
2. **不要 over-spawn**：3-5 个并行 agent 是甜区，10+ 个协调成本陡升
3. **agent 间不要有共享文件写**：并行写同一个文件会冲突，让主 agent 汇总后写
4. **`max_turns` 限制每个成员的最大轮数**，避免 runaway

## 集成时机

- ✅ 立即可用：`design-review` / `dev-story` / `consistency-check` / `art-asset-pipeline` 重写时纳入
- ⚪ 视实际项目复杂度：其他 skill 当前规模够小，不需要并行
