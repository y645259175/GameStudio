# platformer-2 · qa/tests

## 测试入口约定（M1）

每个测试文件 `test_*.gd` 自包含运行：`extends SceneTree`，在 `_init()` 中跑断言并 `quit(0/1)`。

## 跑法

单个测试：

```powershell
d:\AI\GameStudio\engine\Godot\Godot_v4.6.2-stable_win64.exe `
  --headless `
  --path d:\AI\GameStudio\projects\platformer-2\game `
  --script d:\AI\GameStudio\projects\platformer-2\qa\tests\test_scaffold.gd `
  --quit
```

EXIT 0 + stdout 含 `PASS: N/N` 即通过。

跑全部（含 godot 语法检查）：

```powershell
pwsh -NoProfile -File d:\AI\GameStudio\projects\platformer-2\qa\run-tests.ps1
```

## 当前测试

- `test_scaffold.gd` — story-001 脚手架 smoke（场景加载 / Label 文本 / _ready 不抛错）

## 后续考虑（M2+）

测试文件 ≥ 3 个时考虑引入 [GUT](https://github.com/bitwes/Gut) 框架（提供 fixture / 断言 DSL / 报告聚合）。当前一个测试，自包含 SceneTree 入口足够。
