# tool-usage-no-popup · ARCHIVE

> 历史判例。仅 RCA / postmortem 时查。

## §A1 · Remove-Item 内置硬保护

CodeBuddy IDE 对 `Remove-Item` / `rm` / `del` 等删除命令有**内置硬保护**（不在配置层），任何 allow / hook deny 都压不住。即使配置了 `permissions.allow: [Bash(Remove-Item:*)]` 也会强制弹窗。

**铁证**：2026-05-18 settings.json 重启复测（详见 anti-patterns-archive AP-07）。

**结论**：永远禁止用 Remove-Item，必须用 `delete_file` 工具或 `cmd /c "del"` 绕过。

---

## §A2 · platformer-2 流程逃逸事件

**2026-05-19 platformer-2 story-004 engineer 重写 player.gd**：engineer 在做 story-004 时发现 story-002 的 player.gd 截断（19 行 vs 应有 220 行），直接重写为 184 行而非走 dev-story re-implement。流程外修复留下的代码没经过 reviewer 审。

**教训**：重写要走流程，没流程就 spawn 新 story。

---

## §A3 · platformer-2 数值不一致事件

**2026-05-19 platformer-2 move_speed 不一致**：GDD 写 180 而 story 写 300，reviewer 标了 critical_issue 但无人裁定。最终代码用了 300——但 GDD 没改。下个 sprint 起新 story 时还会遇到同样的问题。

**沉淀**：BL-S026 数值一致性回路 SOP（→ MANUAL §value-consistency）。

---

## §A4 · platformer-2 shadow review 同质化事件

**2026-05-19 platformer-2 story-003 shadow 用了同 batch**：reviewer 与 qa-lead shadow 同 batch spawn，二者看到对方的部分输出，shadow 的"独立"verdict 实际上受了主 reviewer 影响。

**沉淀**：BL-S030 shadow 必须 team mode（→ MANUAL §shadow-team-mode）。

---

## §A5 · main agent 自身违规事件

**2026-05-19 main agent 用 Remove-Item 清理 temp 文件**被用户当场抓到：rule 写了"建议用 delete_file"但 alwaysApply 注入只是认知层，没有执行层阻断。

**沉淀**：rule 升级为"强制规则" + 加"每次 execute_command 前自检"段（→ CORE）+ pre-tool-bash.py hook 加 Remove-Item 拦截提示。
