---
name: <skill-name>
description: <一句话说明能力 + 触发关键词 + 与其他 skill 的边界>
allowed-tools:
disable: false
---

# <skill-name> · <一句话能力>

## 何时触发

- <场景 A 关键词>
- <场景 B 关键词>
- <场景 C 关键词>

## 一键入口

```bash
python .codebuddy/skills/<skill-name>/run.py --action <action> --<arg> <value>
```

（如无 run.py：写"暂无 run.py 入口，按 PLAYBOOK.md 手动走"）

## 红线（不可绕过）

- **[1]** <核心约束>
- **[2]** <核心约束>

## 详细 SOP

见 `PLAYBOOK.md`：
- §1 完整流程
- §2 字段细则 / 命令参数
- §3 错误处理 / 降级路径

## 历史 / 罕见 case

见 `ARCHIVE.md`

<!-- 写作要点：
- CORE 不放完整 SOP（→ PLAYBOOK）
- CORE 不放历史触发事件（→ ARCHIVE）
- run.py 是首选入口，markdown SOP 是 fallback
-->
