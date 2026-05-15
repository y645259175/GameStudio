# Bolt 1-1 Epic 索引

| ID | 标题 | 优先级 | Sprint | 状态 |
|---|---|---|---|---|
| E1 | 工程脚手架 + ConfigLoader | P0 | S1 | done |
| E2 | 角色控制 + 物理 + 状态机（Small/Big/Fire/Dead）| P0 | S1-S2 | done |
| E3 | 关卡 tilemap + 关卡元素（Brick / Cache Box / Conduit / Cog / Signal Tower）| P0 | S2 | done |
| E4 | 敌人系统（Mossroll / Shellpod / Spiker）| P0 | S2 | partial（Spiker 推迟）|
| E5 | 道具系统（Power Berry / Spark Bloom / Pulse Core / Blue Crystal）| P0 | S2-S3 | partial（Pulse Core 推迟）|
| E6 | 摄像机 + 关卡流程状态机 | P0 | S2 | done |
| E7 | HUD（BOLTY 得分 / Cog 数 / SECTOR / TIME）+ 计分系统 | P0 | S2 | done |
| E8 | 主菜单 + 暂停 + 死亡 + 通关界面 | P1 | S3 | done |
| E9 | 美术资产（精灵 / tileset / UI）| P1 | S3 | **in-progress（pivot 后重做）**|
| E10 | VFX 实现（30 个 P0+P1 动画）| P1 | S3 | partial |
| E11 | 音效（占位免版权）| P2 | Phase 2 | deferred |

## Sprint 划分

- **Sprint 1**（M4 核心玩法可玩）：E1 + E2（核心移动+跳跃+物理）—— done
- **Sprint 2**（M5 完整 Sector 1-1）：E3 + E4 + E5 + E6 + E7 —— cheat-only PASS, real PASS pending
- **Sprint 3**（M6 美术+动画+UI）：E8 + E9 + E10 —— 启动中
- **M5.5 pivot**（mario→bolt 原创化）：E9 重做（原 mario 资产删除，全部 bolt 重新生成）
- **Phase 2+**：E11 音效 + 后续 Sector
