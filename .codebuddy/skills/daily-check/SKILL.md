---
name: daily-check
description: End-of-day acceptance flow. Use when user says "今天的总结 / 日报 / daily check / 今日做完了". Runs consistency-check, summarizes progress, produces daily report. Lighter than smoke-check (sprint-end).
allowed-tools: read_file, write_to_file, list_dir, search_content, execute_command
disable: false
---

# daily-check · 每日收工自检

## 何时加载

- 一天工作结束
- 用户说"日报 / 总结一下今天 / daily check"
- 自动化触发（automation 每日定时）

**不加载场景**：sprint 结束 → `smoke-check`；项目里程碑 → `milestone-review`。

## 输入契约

| 输入 | 来源 |
|---|---|
| 当日 commits | `git log --since=midnight` |
| 当日修改文件 | git diff |
| 当前 sprint plan | `projects/<name>/sprints/sprint-<N>-plan.md` |

## 流程

### Step 1 · 收集当日活动

```
git log --since=midnight --pretty=format:'%h %s'
git diff --stat HEAD@{midnight}
```

### Step 2 · 进度核对

读 sprint plan，对比：
- 今天新关闭的 story
- 今天有进展但未关的 story
- 卡住的 story（in-progress 已 ≥ 3 天无 commit）

### Step 3 · 轻量 consistency-check

仅扫今日改动文件：
- 涉及代码 → 是否更新对应 GDD/数值表
- 涉及数值 → 是否同步代码

不跑全量（那是 smoke-check 的活）。

### Step 4 · 输出日报

按模板（暂复用 retro 思路简化版）：

```
# Daily Report - <date>
## 今日完成
- [x] S<id>: <title>

## 进行中
- S<id>: <progress 简述>

## 阻塞
- ...

## 进展
- 当前 sprint x/y pts done
- 距 sprint 结束 N 天

## 风险 / 关注点
```

落盘 `projects/<name>/reports/daily-<date>.md`。

### Step 5 · 卡 story 提醒

如有 story in-progress > 3 天无 commit → 提醒用户：是否需要拆 / 升级 debugger / 调阻塞资源。

## 输出契约

| 字段 | 内容 |
|---|---|
| `verdict` | `OK` / `STALLED:<n>` / `OFF_TRACK:<reason>` |
| `report_path` | `projects/<name>/reports/daily-<date>.md` |
| `done_today` | story ids |
| `stalled` | story ids |

## 调用的 agent

- `pm` (opus)（进度判断 + 风险）
- `qa` (sonnet)（consistency 轻量复核）

## 加载的 rule

- `commit-discipline`

## 失败 / 降级

| 异常 | 策略 |
|---|---|
| 当日无 commit | 输出"无活动" + 提醒（可能漏 commit）|
| sprint plan 缺失 | 仅做 git 总结，不做进度判断 |

## 验收标准

- 日报落盘
- 包含完成 / 进行 / 阻塞三段
- 卡 story 全部识别

## Known Limitations

- "卡 story"判定阈值（3 天）写死，无项目自定义
- 跨人 attribution 缺
