# 工作室反模式速读（session-start hook 注入）

> 完整版：`studio/docs/anti-patterns.md` · 共 11 条反模式
> 用法：每次会话启动扫一眼；user 反馈 / commit 返工 ≥ 2 次时回查完整版

| AP-ID | 一句话症状 | 一句话修法 |
|---|---|---|
| AP-01 | main agent 全程独角戏，session 内 0 spawn | 用 `agent-spawn-contract` 末尾 spawn 模板库 |
| AP-02 | "我自己写更快"心理 → sub-agent 永远闲 | spawn 默认 bypassPermissions，prompt 走模板 |
| AP-03 | 跨 LLM 调用 prompt 写 "same X" = 零效果 | 必须 reference-based：image_edit / chat_image 传图 |
| AP-04 | png 在仓库但 .import 缺失 → 运行时 ColorRect fallback | pre-commit 跑 godot --headless --import |
| AP-05 | API 429 持续硬撞重试浪费数十分钟 | N 次 429 自动切 fallback model + 冷却 cache |
| AP-06 | 用户反馈解决了但没沉淀进 SOP | 修复后必更新 retro + 升级到 anti-patterns + 改 agent prompt |
| AP-07 | hooks / permissions 字段不生效；命令行删除有内置硬保护 | agent 删文件用 delete_file，禁止 Remove-Item / rm / del |
| AP-08 | 复合命令 cmd1;cmd2 整串被审批拦截 | 每条独立 tool call；批量用 Python 脚本 |
| AP-09 | sub-agent 声称 PASS 但文件截断（write 长文件被压缩） | 写完 read_file 验行数；< 80% 用 replace_in_file 追加 |
| **AP-10** | **机制全 PASS（self_rubric / reviewer / shadow / headless）但用户实玩 < 1 分钟崩** | **dev-story 加 playtest_pending 状态；vertical slice 强制 5 项清单（camera/边界/视觉/反馈）；不允许 AI 自宣布 QUALITY_PROVEN（用 _MECHANISM 后缀）** |
| **AP-11** | **Godot 资产在游戏画面看不到/位置错（即使 raw png 完美、.import 齐全）** | **强制 in-context 截图（TPL-05 v2）；常见根因：父节点 Node→Node2D / @export 缺失 / z_index 错；用 `studio/templates/godot-screenshot/`** |

## 自检 6 问（每次 milestone gate / 长 session 中段必跑）

1. 主上下文 token > 80k 但本次 session spawn 次数 < 3？→ 中招 **AP-01 / AP-02**
2. 用户反馈了 ≥ 2 轮才修对？→ 中招 **AP-06**，必须升级到 `anti-patterns.md`
3. 视觉 / 资产看起来"差不多但不一致"？→ 中招 **AP-03**，回查 reference-based pipeline
4. sub-agent 交付后 read_file 行数 < 预期 80%？→ 中招 **AP-09**
5. 所有 review verdict 全 PASS 但 **session 内 0 用户介入**？→ 高度警惕 **AP-10**，verdict 最多给 `*_MECHANISM` 后缀
6. **资产已生成但游戏画面看不到**？→ 中招 **AP-11**，先跑 `studio/templates/godot-screenshot/` 再 spawn art-director

## 触发回查完整版的信号

- 用户反馈"不对/不够好" ≥ 2 轮
- 同一 commit 被 amend / revert ≥ 2 次
- milestone gate self-check
- retro / postmortem 触发时
- **vertical slice / playable build 之前**（必查 AP-10）
- **资产入库前**（必查 AP-11）
