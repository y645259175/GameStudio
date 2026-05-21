# Agent Audit · 5 核心 Agent 质量体检

> **任务来源**: BL-S009 修法
> **审计模式**: REVIEW（静态审计，不改 agent 文件）
> **审计员**: architect agent
> **审计日期**: 2026-05-19
> **被审 agent**: engineer / reviewer / qa-lead / designer / art-director

---

## 体检方法学

每个 agent 在 6 维度上 0-5 分打分（0=完全缺失，5=优秀且可执行），每维给 1 句话 evidence。

**6 维**：
1. **AGENT.md 完整性**: Domain Owned / Does NOT Own / 何时调用 / 决议词汇 / 历史教训
2. **output-schema.yaml 严密性**: 字段定义清晰 / self_rubric 可执行 / validation 规则具体
3. **calibration 覆盖度**: good/marginal/bad 三类齐全 + case 真实
4. **playbook 健康度**: 待消化区/已并入区结构清晰
5. **跨 agent 协同清晰度**: 上游/下游/冲突升级
6. **AP-10/AP-11 修法落地**: in-context 渲染 / 5 项 vertical slice / verdict _MECHANISM 后缀

**评级**：EXCELLENT (≥27) / GOOD (22-26) / FAIR (16-21) / POOR (<16)

---

## 1. engineer

| # | 维度 | 分 | Evidence |
|---|------|----|---------|
| 1 | AGENT.md 完整性 | 4 | 有"何时调用 / 流程 / 视觉资产红线 / 绕过 SOP / 历史教训 4 条 / 自检步骤"，但缺显式 `Domain Owned` / `Does NOT Own` 段（与 qa-lead/art-director 的格式不一致）。 |
| 2 | schema 严密性 | 5 | 双产出（implementation-delivery + quickfix-delivery），每字段含 type/validation；self_rubric 7 项含防截断 + 行号验证，每条都可执行。 |
| 3 | calibration 覆盖度 | 4 | 5 个 case：good 3 (scaffold/visual-debt/quickfix) + bad 2 (colorect/no-engine-check)，**缺 marginal**；bad 都对应真实历史事故（项目 A pivot）。 |
| 4 | playbook 健康度 | 5 | 待消化 6 条全是 2026-05-18~19 真实经验；已并入区 4 条对应 AGENT.md 段落，结构最规范。 |
| 5 | 跨 agent 协同 | 3 | 引用了 architect/debugger/reviewer/refactorer/tester/engine-specialist/art-director，但**没有明确的协作协议段**（无上游/下游/冲突升级三段式），自己也在 Known Limitations 标记 "[Phase 2 TODO] 5 个代码 agent 分工边界" + "engine-specialist 协同协议未定义"。 |
| 6 | AP-10/AP-11 落地 | 4 | 视觉资产红线 + 绕过 SOP + write_to_file 截断教训 + headless EXIT 0 ≠ 完整都已落地；schema 中 red_lines_checked 是显式契约字段；但 verdict 词汇是 IMPL-COMPLETE/PARTIAL/BLOCKED，**未带 _MECHANISM 后缀**（这条规范本身是 art-director 试点的，engineer 未跟进）。 |

**总分: 25 / 30 — GOOD**

**亮点**: schema + playbook 是 5 agent 中最规范的（playbook 已并入区追溯到具体段落）。视觉资产红线段已成为工作室级反 ColorRect 占位事故的样板。

**短板**: 没用 Domain Owned / Does NOT Own / 协作协议三段式格式（看起来像旧版结构）。

---

## 2. reviewer

| # | 维度 | 分 | Evidence |
|---|------|----|---------|
| 1 | AGENT.md 完整性 | 3 | 有"何时调用 / 流程 / milestone gate 专项扫 / 决议词汇 / 历史教训 1 条"，**缺 Domain Owned/Does NOT Own、缺协作协议三段式**；历史教训只有 1 条（其他 agent 多 2-4 条）。 |
| 2 | schema 严密性 | 5 | 三产出（code-review-report + milestone-gate-review + gdd-review），4 维评审每维含 evidence_lines；verdict 三选一 + 边界规则明确（APPROVE = 全 PASS + 0 critical）。 |
| 3 | calibration 覆盖度 | 4 | 5 个 case：good 3 (approve-with-evidence/request-changes/milestone-gate) + bad 2 (rubber-stamp/m5-missed-cheat)，**缺 marginal**；bad-02 是项目 A M5 cheat-only 真实事故。 |
| 4 | playbook 健康度 | 2 | 待消化区**为空**（仅占位说明），已并入区只有 1 条；与 engineer 6 条真实素材形成强对比，说明 reviewer 工作中没有持续记录经验。 |
| 5 | 跨 agent 协同 | 2 | AGENT.md 中**完全缺乏协作协议段**——没有上游/下游/冲突升级。仅在引用段列了 skill+rule，没有列其他 agent。 |
| 6 | AP-10/AP-11 落地 | 4 | milestone gate 专项扫 5 项（视觉资产红线 / cheat-only / issue 数 / backlog 闭环）覆盖了 vertical slice；但 verdict 词汇是 APPROVE/APPROVE_WITH_NITS/REQUEST_CHANGES + MILESTONE-PASS/CONDITIONAL/BLOCKED，**未带 _MECHANISM 后缀**。 |

**总分: 20 / 30 — FAIR**

**亮点**: schema 三产出覆盖最广（code/milestone/gdd 三场景）；milestone gate 专项扫 5 项是工作室级范本。

**短板**: 协作协议段完全缺失 + playbook 待消化区空白；AGENT.md 是 5 agent 中最薄的（仅 73 行，对比 art-director 171 行）。

---

## 3. qa-lead

| # | 维度 | 分 | Evidence |
|---|------|----|---------|
| 1 | AGENT.md 完整性 | 5 | **完整三段式典范**：Domain Owned (5 项) / Does NOT Own (4 项) / 协作协议（上游 3 / 下游 3 / 冲突升级 3）/ 决议词汇 / 流程步骤 / 自检步骤；只缺历史教训段（无具体事故记录）。 |
| 2 | schema 严密性 | 5 | 双产出（qa-gate-verdict + test-strategy），7 项 metrics 全部带 validation（如 real_playtest "必须有 action_press 才能 PASS"），verdict 三选一边界明确。 |
| 3 | calibration 覆盖度 | 5 | **唯一含 marginal 的 agent**：good 2 (m6-gate-pass / sprint-smoke) + marginal 1 (visual-debt-boundary 阈值 = 2 边界) + bad 2 (cheat-only-missed / missing-evidence)，三类齐全且 case 都对应真实事故。 |
| 4 | playbook 健康度 | 2 | 待消化区**为空**（仅占位说明），已并入区也为空——说明 qa-lead 工作经验未持续沉淀。 |
| 5 | 跨 agent 协同 | 5 | 协作协议段完整：上游 (pm/engineer/qa) / 下游 (test-strategy/regression-matrix/gating) / 冲突升级 (质量 vs 时间→producer / 覆盖不足→tester / 框架问题→engineer/architect)。 |
| 6 | AP-10/AP-11 落地 | 5 | 7 项 metrics 即 vertical slice（test_pass_rate / engine_check / real_playtest / consistency_check / p0_bug_count / visual_debt_count / gdd_acceptance）；real_playtest 字段 validation 直接防 cheat-only AP-04；calibration bad-01 直接演示 cheat-only 假 PASS 反例；verdict QA-PASS/CONDITIONAL/BLOCK 边界明确。 |

**总分: 27 / 30 — EXCELLENT**

**亮点**: 协作协议三段式 + Domain Owned/Does NOT Own + marginal calibration —— **三项工作室级最佳实践都在此 agent**，可作为其他 agent 改造的样板。

**短板**: playbook 双区皆空（与 engineer 形成强对比）；AGENT.md 缺历史教训段。

---

## 4. designer

| # | 维度 | 分 | Evidence |
|---|------|----|---------|
| 1 | AGENT.md 完整性 | 2 | 仅 64 行，**5 agent 中最薄**；缺 Domain Owned / Does NOT Own / 协作协议 / 历史教训段；只有"何时调用 / 流程 / 输出 / 引用 / 自检 / 产出契约 / Known Limitations"，结构最简陋。 |
| 2 | schema 严密性 | 5 | 8 节硬性结构每节带具体 validation（§3 ≥5 个具体值禁 [TBD]、§5 ≥3 个边界场景、§7 必须具体段落标题、§8 ≥3 个 checklist）；self_rubric 8 项可执行（含 grep 8 节）。 |
| 3 | calibration 覆盖度 | 4 | 5 个 case：good 3 (gdd-chapter / quick-design / refine-mode) + bad 2 (tbd-values / rewrite-in-refine)，**缺 marginal**；bad-02 (REFINE 模式重写) 是 designer 特有反模式。 |
| 4 | playbook 健康度 | 1 | 待消化区**为空**（仅占位说明），已并入区**也为空** + 自述 "designer AGENT.md 之前没有'历史教训'段"。最差。 |
| 5 | 跨 agent 协同 | 2 | 引用段列了 skill 和 rule，但没列其他 agent；**完全无协作协议段**；自己在 Known Limitations 也承认 "[Phase 2 TODO] 与 engineer 在'数值改动→代码影响'衔接需明确"。 |
| 6 | AP-10/AP-11 落地 | 4 | 8 节硬性结构 = 设计领域的 vertical slice 等价物；§3 数值规范 validation 直接防 [TBD] 反模式；verdict DESIGN-COMPLETE/DRAFT/BLOCKED 三选一；但同样**未带 _MECHANISM 后缀**，AGENT.md 也无显式历史教训段。 |

**总分: 18 / 30 — FAIR**

**亮点**: schema 是 5 agent 中字段最严格的（8 节每节都有 validation 规则到具体可 grep 程度）。

**短板**: AGENT.md 最薄 + playbook 双区皆空 + 缺协作协议 + 缺历史教训。是**结构性最弱**的 agent。

---

## 5. art-director

| # | 维度 | 分 | Evidence |
|---|------|----|---------|
| 1 | AGENT.md 完整性 | 5 | **171 行，5 agent 中最厚**；完整三段式（Domain Owned 6 项 / Does NOT Own 4 项 / 协作协议 3 段）+ 决议词汇 + 流程 + Sprint 截图评审 + Key Visual 早期生成 + 角色多帧 SOP（含 5 项一致性检查 + 历史教训引用具体复盘文档）。 |
| 2 | schema 严密性 | 5 | 三产出（asset-review / style-guide / char-key-verdict）；5 维评审每维带具体 evidence 字段（color 必须 hex_violations 列表）；import_metadata + naming_compliance 是显式硬性 gate。 |
| 3 | calibration 覆盖度 | 4 | 5 个 case：good 3 (asset-review-reject / style-guide-draft / char-key-approve) + bad 2 (missing-import / vague-reject)，**缺 marginal**；bad-01 是 AP-04 真实反例。 |
| 4 | playbook 健康度 | 4 | 待消化区为空（占位说明），但已并入区有 2 条真实并入记录（角色多帧 SOP / Key Visual 生成 → 都对应 bolt-1-1 M6.2 事故）。 |
| 5 | 跨 agent 协同 | 5 | 协作协议三段式完整（上游 designer/producer/参考图 / 下游 art-bible/资产 review/视觉 gate / 冲突升级：视觉 vs UX→producer+designer，视觉 vs 性能→architect+producer，质量不达标→art-asset-pipeline）。 |
| 6 | AP-10/AP-11 落地 | 5 | **5 项一致性检查 = vertical slice 范本**（轮廓比例/主色板/风格细节/关键特征/尺寸）；多产出对应多 verdict（AD-CONCEPT-VISUAL / AD-ART-BIBLE / AD-PHASE-GATE / AD-CHAR-KEY / AD-CHAR-ANIM-SET），verdict 词汇带功能维度后缀（接近 _MECHANISM 风格）；历史教训直接引用复盘 md 路径。 |

**总分: 28 / 30 — EXCELLENT**

**亮点**: 与 qa-lead 并列工作室级样板。AGENT.md 是 5 agent 中信息密度最高的 — 历史教训显式引用复盘文档路径，是其他 agent 应该模仿的格式。verdict 词汇按功能维度切分（CHAR-KEY vs CHAR-ANIM-SET vs PHASE-GATE）最接近 AP-10/AP-11 _MECHANISM 后缀理念。

**短板**: playbook 待消化区为空（与 engineer 6 条对比），说明日常工作中没有持续记录新经验。

---

## 综合评分汇总

| Agent | AGENT.md | Schema | Calibration | Playbook | 跨 agent | AP-10/11 | 总分 | 评级 |
|-------|---------:|-------:|------------:|---------:|---------:|---------:|-----:|------|
| **art-director** | 5 | 5 | 4 | 4 | 5 | 5 | **28** | EXCELLENT |
| **qa-lead** | 5 | 5 | 5 | 2 | 5 | 5 | **27** | EXCELLENT |
| **engineer** | 4 | 5 | 4 | 5 | 3 | 4 | **25** | GOOD |
| **reviewer** | 3 | 5 | 4 | 2 | 2 | 4 | **20** | FAIR |
| **designer** | 2 | 5 | 4 | 1 | 2 | 4 | **18** | FAIR |

**关键观察**: schema 严密性所有 agent 都拿了 5 分（combo-B M1 工作做得彻底），但 AGENT.md 完整性 / 协作协议 / playbook / AP-10/AP-11 落地的差异极大。

---

## 跨 agent 共性问题

### 共性短板（多个 agent 都缺）

1. **playbook 待消化区普遍空白**（reviewer / qa-lead / designer / art-director 4 个全空，仅 engineer 有 6 条真实素材）
   - 根因：日常工作中没有"在线经验沉淀"机制
   - 影响：M2 自检步骤要求"工作中发现新经验追加到 playbook" 形同虚设

2. **缺 marginal calibration**（engineer/reviewer/designer/art-director 都没有，仅 qa-lead 有）
   - 根因：good/bad 二元思维，没考虑边界争议案例
   - 影响：边界判断时 agent 没有锚点

3. **协作协议段缺失或缺位**（reviewer / designer 完全缺；engineer 有引用但无三段式）
   - 根因：模板没有强制要求三段式（上游/下游/冲突升级）
   - 影响：跨 agent spawn 时职责边界模糊

4. **verdict 词汇未带 _MECHANISM 后缀**（5 个 agent 都未跟进 AP-10/AP-11 的命名规范）
   - 根因：AP-10/AP-11 修法只在工作室文档讨论，未传导到 agent 文件
   - 影响：verdict 词汇没有体现"通过的是哪条机制"

5. **历史教训段位置/数量不均衡**（reviewer 仅 1 条 / qa-lead 缺段 / designer 缺段；engineer 4 条 / art-director 多条 + 引用复盘 md）
   - 根因：没有"重大事故必须并入 AGENT.md"的强制流程
   - 影响：经验流失在 playbook 而未上升到本体

### 一枝独秀（其他 agent 应学习的样板）

- **art-director 的 Domain Owned + Does NOT Own + 协作协议三段式 + 引用复盘 md** → 应作为工作室 AGENT.md 标准模板
- **qa-lead 的协作协议三段式 + 7 项 vertical slice metrics + marginal calibration** → 应作为契约设计标准模板
- **engineer 的 playbook 6 条真实素材 + 已并入区追溯到 AGENT.md 段落** → 应作为 playbook 维护标准模板
- **art-director 的多 verdict 词汇按功能维度切分**（AD-CHAR-KEY / AD-CHAR-ANIM-SET / AD-PHASE-GATE）→ 应作为 verdict 命名标准模板

---

## 改进清单（优先级排序）

### P0 — 必修（影响交付质量，任一 agent 阻塞工作室能力）

1. **designer AGENT.md 重构**: 当前 64 行 + 缺三段式 + 缺历史教训 + playbook 双区皆空 → 按 art-director / qa-lead 样板重写，补齐 Domain Owned / Does NOT Own / 协作协议 / 历史教训四段。**不补则 dev-story 流程中 designer 与 engineer 衔接断裂风险持续。**

2. **reviewer AGENT.md 补齐协作协议**: 当前缺上游/下游/冲突升级三段式，与所有代码 5 agent (architect/debugger/refactorer/tester/engineer) 关系未定义 → 按 qa-lead 样板补三段。**不补则 milestone gate 与 qa-lead 的边界争议（谁拍板）持续。**

3. **5 agent 同步 verdict _MECHANISM 后缀规范**: 当前 5 个 agent verdict 词汇都没体现"通过哪条机制"（如 IMPL-COMPLETE → IMPL-COMPLETE_VIA_REDLINE_PASS 类）→ 起草工作室级 ADR 定义命名规范，再传导到 5 agent。**不传则 AP-10/AP-11 修法在 agent 层悬空。**

### P1 — 应修（影响一致性 / 经验沉淀）

4. **5 agent 全部补 marginal calibration**: 当前仅 qa-lead 有 → 每 agent 补 1 个边界争议 case（如 reviewer "200 行改动是否必须 reviewer / 5 维 1 PASS 4 MINOR 是哪个 verdict"）

5. **playbook 在线沉淀机制**: 4 个 agent playbook 待消化区为空说明 M2 self_rubric 第 4 条"工作中发现新经验追加 playbook"形同虚设 → 在 agent spawn 模板中加入 "spawn 末尾必须检视 playbook 是否需要追加（即使无需也写'今日无新经验'）"硬性要求

6. **engineer / reviewer / designer 补 Domain Owned + Does NOT Own**: 与 qa-lead / art-director 格式对齐（已部分由 P0 #1/#2 覆盖，单独列出 engineer）

### P2 — 优化（影响工作室长期演进）

7. **engineer 与 engine-specialist 协同协议**: engineer 自己在 Known Limitations 标注未定义；与 architect agent 一起起草 ADR

8. **reviewer 项目代码风格 rule 沉淀**: 当前 reviewer Known Limitations 标 "[Phase 2 TODO] 项目代码风格的具体规则未在工作室级 rule 中沉淀" → 起草 `studio/rules/code-style.md`

9. **designer 数值平衡 simulator 集成**: Phase 2 工具

---

## 整体 verdict

**ARCH-MINOR_GAPS**

**理由**:
- schema 严密性全部 5 分（contracts 层做得彻底）
- 2/5 agent EXCELLENT (art-director / qa-lead)；2/5 GOOD/FAIR；1/5 FAIR (designer)
- 主要 gap 集中在"AGENT.md 文档结构 / playbook 在线沉淀 / verdict _MECHANISM 后缀"三个**可补救**的维度
- 没有任一 agent 在 schema 或 calibration 上失守（即"硬交付契约"层面已稳）
- designer 是最大短板，但所需修复都是文档级（按样板重构），无技术债

**不构成 ARCH-MAJOR_GAPS**: 因为没有 agent 在"硬产出契约"上失守，所有缺口都是结构 / 文档 / 流程层面，且工作室内已有样板可借鉴（art-director / qa-lead）。

**建议节奏**: P0 三项 1 个 sprint 内完成（设计师重构 + reviewer 补协作 + verdict ADR）；P1 / P2 进 backlog。

---

## 附录 · 审计原始数据

- AGENT.md 行数: engineer 99 / reviewer 73 / qa-lead 104 / designer 64 / art-director 171
- output-schema.yaml 产出数: engineer 2 / reviewer 3 / qa-lead 2 / designer 2 / art-director 3
- calibration 总数: engineer 5 / reviewer 5 / qa-lead 5 / designer 5 / art-director 5
- playbook 待消化条目: engineer 6 / reviewer 0 / qa-lead 0 / designer 0 / art-director 0
- playbook 已并入条目: engineer 4 / reviewer 1 / qa-lead 0 / designer 0 / art-director 2

