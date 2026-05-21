# 渐进披露三件套模板

> 用于 rule / skill / agent 的标准分层结构。设计原则见 `studio/docs/progressive-disclosure-architecture.md`。

## 文件分层

| 层 | 文件名 | 长度建议 | 注入时机 |
|---|---|---|---|
| **CORE** | `RULE.mdc` / `SKILL.md` / `AGENT.md` | rule/skill ≤30 行 · agent ≤40 行 | 每次都注入（rule alwaysApply）/ spawn 时必带 |
| **MANUAL** | `MANUAL.md` / `PLAYBOOK.md` / `HANDBOOK.md` | ≤150 行 | 按场景查（CORE 中明确指引时 read_file）|
| **ARCHIVE** | `ARCHIVE.md` | 无上限 | 仅 RCA / postmortem / debug 时查 |

## CORE 写作要点

✅ **包含**：
- 一句话目的 / 身份
- 3-5 条强制约束（红线）
- 何时升级到 MANUAL（具体场景关键词）
- 索引指针：`详细 SOP 见 MANUAL.md § X`

❌ **不包含**：
- 历史触发事件 / retro 触发场景（→ ARCHIVE）
- 完整 SOP 步骤（→ MANUAL）
- 边界条件 / 罕见 case（→ MANUAL 或 ARCHIVE）
- 决议词汇详细说明（→ MANUAL）
- 字段说明 / 数据规范（→ MANUAL）

## OVER_LIMIT_REASON 自审机制

文件超过 review 阈值（rule/skill 50-80 行 · agent 60-100 行）时，必须在文件头部 500 字符内加：

```markdown
<!-- OVER_LIMIT_REASON: 简洁说明为什么这部分内容必须在 CORE 而非 MANUAL，
比如"3 条红线分别引用 3 段 SOP，拆出去注入成本高于阅读成本" -->
```

超过 approval 阈值（rule/skill 80+ · agent 100+）时，commit msg 必须加 `[layer-override]` tag 表示用户已审批。

## 三件套模板

见同目录下：
- `RULE.template.mdc` · rule CORE 范本
- `SKILL.template.md` · skill CORE 范本
- `AGENT.template.md` · agent CORE 范本
- `MANUAL.template.md` · MANUAL 通用骨架
- `ARCHIVE.template.md` · ARCHIVE 通用骨架

## 跑 lint

```bash
python .codebuddy/scripts/check_progressive_disclosure.py        # 全量扫
python .codebuddy/scripts/check_progressive_disclosure.py --strict  # 提醒区也算 fail
```

commit-msg hook 已自动集成此 lint，无需手跑。
