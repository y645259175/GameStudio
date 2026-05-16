# bolt-1-1 · art/

> 美术参考目录。**不进交付包**。

## 当前内容

| 文件 | 类型 | 说明 |
|---|---|---|
| `key-visual.png` | Key Visual | 宪章底线 4 要求；通过 design-review skill step 7（key-visual gate）；art-director 视觉锚点。1024×1024，gemini-3-pro-image-preview 出图 |
| `bolty-sprite-reference.png` | Sprite reference | Bolty small 态 8 帧动画参考图。模型给了 4×2 网格而非要求的 4×1 strip——作为美术参考可用，作为可直接接入的 sprite atlas **需要后期处理**（裁切 + 降采样到 16×16） |

## 资产 pipeline 状态（M5.5 进度）

| 阶段 | 状态 | 备注 |
|---|---|---|
| **B.1** key visual 生成 | ✅ done | `key-visual.png` 已落盘 |
| **B.2** Bolty 三态精灵 | partial | small 态参考图已出，需后期处理 + big/fire 态待生成 |
| **B.3** Mossroll / Shellpod 精灵 | TODO | |
| **B.4** 道具精灵 | TODO | |
| **B.5** Tile 集 | TODO | |
| **B.6** 关底元素 | TODO | |
| **B.7** 背景 | TODO | |
| **B.8** HUD 字体 / 图标 | TODO | |
| **C** 接入资产到 game/ | TODO | 需要图像后处理 pipeline（裁切 / 降采样 / 透明背景检测）|

## 已知限制（per autonomous-mode-charter 底线）

- timiai-image 平台 gpt-image-2 限流较重（429）；备用 gemini-3-pro-image-preview 工作但尺寸最小 1024×1024
- AI 生成的 sprite sheet 布局不一定遵循 prompt 指令（需要后期手工裁切）
- 16×16 真像素 sprite 必须**后期处理**（PIL nearest-neighbor 降采样）才能用于游戏
- 每张图生成耗时 60-120s，8 类资产一次性出齐需要 ~15 分钟 + 限流重试时间

## 调用方式

详见 `.codebuddy/skills/timiai-image/SKILL.md`。

```bash
cd d:\AI\GameStudio
python .codebuddy\skills\timiai-image\scripts\text2image.py \
  --prompt "..." \
  --size 1024x1024 \
  --quality medium \
  --out "projects/bolt-1-1/art/<name>.png" \
  --fallback auto
```
