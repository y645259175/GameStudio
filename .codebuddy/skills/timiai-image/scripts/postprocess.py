# -*- coding: utf-8 -*-
"""TimiAI 后处理 · 把 1024x1024 的"看起来像像素艺术"原图，转成游戏可直接用的真像素 sprite。

核心场景（按 bolt-1-1 / 一般 2D 游戏需求）：
  1. **single sprite 降采样**：1024×1024 → 32×32 / 16×16，nearest-neighbor，保持像素清晰
  2. **sprite atlas 切片**：模型给的 NxM 网格大图（如 4×2 帧）切成单帧 + 拼成水平 strip
  3. **透明背景检测**：去掉模型给的 checkered transparent 背景纹理（如果有）+ 修复 alpha
  4. **palette quantize**（可选）：限制颜色到 N 色，强制像素感

用法（CLI）：

  # 单图降采样到 16x16
  python postprocess.py shrink --src raw.png --out small.png --size 16x16

  # 4×2 网格切片 → 8 帧 16×16 拼成水平 strip 128×16
  python postprocess.py atlas --src raw.png --out strip.png --grid 4x2 --frame 16x16

  # 检测前景 bbox + 切到边缘
  python postprocess.py crop --src raw.png --out cropped.png

  # palette 量化到 16 色
  python postprocess.py quantize --src raw.png --out q.png --colors 16

API（被 pipeline.py / batch_generate.py 调用）：
  shrink(src, out, size) -> Path
  atlas_to_strip(src, out, grid, frame_size) -> Path
  auto_crop(src, out, alpha_threshold=8) -> Path
  quantize(src, out, n_colors=16) -> Path
"""
from __future__ import annotations
import argparse
import sys
from pathlib import Path
from typing import Tuple

try:
    from PIL import Image
except ImportError:
    sys.stderr.write("[postprocess] ERROR: Pillow not installed. Run: pip install Pillow\n")
    sys.exit(1)


def _parse_size(s: str) -> Tuple[int, int]:
    """'16x16' -> (16, 16)"""
    parts = s.lower().replace(" ", "").split("x")
    if len(parts) != 2:
        raise ValueError(f"invalid size: {s}, expect WxH like '16x16'")
    return int(parts[0]), int(parts[1])


def shrink(src: str | Path, out: str | Path, size: str | Tuple[int, int]) -> Path:
    """nearest-neighbor 降采样到目标尺寸。保留 alpha。"""
    if isinstance(size, str):
        size = _parse_size(size)
    src_p = Path(src)
    out_p = Path(out)
    out_p.parent.mkdir(parents=True, exist_ok=True)
    img = Image.open(src_p).convert("RGBA")
    img = img.resize(size, Image.NEAREST)
    img.save(out_p, "PNG", optimize=True)
    return out_p


def auto_crop(src: str | Path, out: str | Path, alpha_threshold: int = 8) -> Path:
    """检测非透明区域 bbox 并裁剪。alpha_threshold：≤ 此值的像素视为透明。"""
    src_p = Path(src)
    out_p = Path(out)
    out_p.parent.mkdir(parents=True, exist_ok=True)
    img = Image.open(src_p).convert("RGBA")
    # 取 alpha 通道，二值化
    alpha = img.split()[3]
    bbox = alpha.point(lambda v: 255 if v > alpha_threshold else 0).getbbox()
    if bbox is None:
        # 整张全透明 → 不裁
        img.save(out_p)
    else:
        img.crop(bbox).save(out_p, "PNG", optimize=True)
    return out_p


def quantize(src: str | Path, out: str | Path, n_colors: int = 16) -> Path:
    """palette quantize，强制像素感。保留 alpha。"""
    src_p = Path(src)
    out_p = Path(out)
    out_p.parent.mkdir(parents=True, exist_ok=True)
    img = Image.open(src_p).convert("RGBA")
    # PIL quantize 不直接支持 RGBA，需要先抠透明再合
    rgb = img.convert("RGB").quantize(colors=n_colors, dither=Image.Dither.NONE).convert("RGBA")
    # 把原 alpha 贴回
    alpha = img.split()[3]
    rgb.putalpha(alpha)
    rgb.save(out_p, "PNG", optimize=True)
    return out_p


def atlas_to_strip(src: str | Path, out: str | Path,
                   grid: str | Tuple[int, int],
                   frame_size: str | Tuple[int, int],
                   crop_each: bool = True,
                   alpha_threshold: int = 8) -> Path:
    """模型常给 NxM 网格的 sprite sheet。把它切成单帧 → 降采样 → 拼成水平 strip。

    grid: (cols, rows) 比如 4x2 = 4 列 2 行 = 8 帧
    frame_size: 目标单帧尺寸（降采样后）比如 16x16

    流程：
      1. 切原图为 cols*rows 个 cell（每个 cell 大小 = src_w/cols × src_h/rows）
      2. 每个 cell 内 auto_crop（去 cell 留白）
      3. 对每个 crop 后的 cell 降采样到 frame_size
      4. 横向拼接成 strip
      5. 保存（宽度 = frame_w * cols * rows，高度 = frame_h）
    """
    if isinstance(grid, str):
        grid = _parse_size(grid)
    if isinstance(frame_size, str):
        frame_size = _parse_size(frame_size)
    cols, rows = grid
    fw, fh = frame_size

    src_p = Path(src)
    out_p = Path(out)
    out_p.parent.mkdir(parents=True, exist_ok=True)

    img = Image.open(src_p).convert("RGBA")
    src_w, src_h = img.size
    cell_w = src_w // cols
    cell_h = src_h // rows

    frames = []
    for r in range(rows):
        for c in range(cols):
            cell = img.crop((c * cell_w, r * cell_h, (c + 1) * cell_w, (r + 1) * cell_h))
            if crop_each:
                alpha = cell.split()[3]
                bbox = alpha.point(lambda v: 255 if v > alpha_threshold else 0).getbbox()
                if bbox:
                    cell = cell.crop(bbox)
                # 居中放回 cell（用 cell_w x cell_h 的画布）以保持位置一致
                canvas = Image.new("RGBA", (cell_w, cell_h), (0, 0, 0, 0))
                ox = (cell_w - cell.width) // 2
                oy = (cell_h - cell.height) // 2
                canvas.paste(cell, (ox, oy), cell)
                cell = canvas
            cell = cell.resize((fw, fh), Image.NEAREST)
            frames.append(cell)

    n = len(frames)
    strip = Image.new("RGBA", (fw * n, fh), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        strip.paste(f, (i * fw, 0), f)
    strip.save(out_p, "PNG", optimize=True)
    return out_p


def remove_checkered_bg(src: str | Path, out: str | Path,
                        threshold: int = 200) -> Path:
    """有些模型给的"透明背景"实际是浅灰白格子图。检测并强制透明化。

    策略：检测 src 四角 16×16 区域，如果整体接近白/浅灰 + alpha=255，
    则用 RGB 距离阈值把整张图中接近"格子色"的像素 alpha 置 0。
    """
    src_p = Path(src)
    out_p = Path(out)
    out_p.parent.mkdir(parents=True, exist_ok=True)
    img = Image.open(src_p).convert("RGBA")
    w, h = img.size
    # 取四角 corner 做样本
    sample_size = min(16, w // 8, h // 8)
    samples = []
    for cx, cy in [(0, 0), (w - sample_size, 0), (0, h - sample_size), (w - sample_size, h - sample_size)]:
        region = img.crop((cx, cy, cx + sample_size, cy + sample_size))
        # 平均 RGB
        pixels = list(region.getdata())
        if not pixels:
            continue
        avg_r = sum(p[0] for p in pixels) / len(pixels)
        avg_g = sum(p[1] for p in pixels) / len(pixels)
        avg_b = sum(p[2] for p in pixels) / len(pixels)
        samples.append((avg_r, avg_g, avg_b))

    if not samples or any(s[0] < threshold for s in samples):
        # 没看到一致的浅色背景，直接复制
        img.save(out_p, "PNG", optimize=True)
        return out_p

    # 用平均背景色作为参考
    bg_r = sum(s[0] for s in samples) / len(samples)
    bg_g = sum(s[1] for s in samples) / len(samples)
    bg_b = sum(s[2] for s in samples) / len(samples)

    # 距离阈值（RGB 空间欧氏距离）
    dist_threshold = 30

    pixels = img.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            d = ((r - bg_r) ** 2 + (g - bg_g) ** 2 + (b - bg_b) ** 2) ** 0.5
            if d < dist_threshold:
                pixels[x, y] = (r, g, b, 0)
    img.save(out_p, "PNG", optimize=True)
    return out_p


# ─── CLI ─────────────────────────────────────────────────────

def _cli_shrink(args):
    p = shrink(args.src, args.out, args.size)
    print(f"OK {p}")


def _cli_atlas(args):
    p = atlas_to_strip(args.src, args.out, args.grid, args.frame,
                       crop_each=not args.no_crop)
    print(f"OK {p}")


def _cli_crop(args):
    p = auto_crop(args.src, args.out, args.alpha_threshold)
    print(f"OK {p}")


def _cli_quantize(args):
    p = quantize(args.src, args.out, args.colors)
    print(f"OK {p}")


def _cli_remove_bg(args):
    p = remove_checkered_bg(args.src, args.out, args.threshold)
    print(f"OK {p}")


def main():
    parser = argparse.ArgumentParser(description="TimiAI 出图后处理")
    sub = parser.add_subparsers(dest="cmd", required=True)

    s1 = sub.add_parser("shrink", help="nearest-neighbor 降采样")
    s1.add_argument("--src", required=True)
    s1.add_argument("--out", required=True)
    s1.add_argument("--size", required=True, help="目标尺寸如 16x16")
    s1.set_defaults(func=_cli_shrink)

    s2 = sub.add_parser("atlas", help="N×M 网格切片 → 水平 strip")
    s2.add_argument("--src", required=True)
    s2.add_argument("--out", required=True)
    s2.add_argument("--grid", required=True, help="网格如 4x2")
    s2.add_argument("--frame", required=True, help="目标单帧如 16x16")
    s2.add_argument("--no-crop", action="store_true", help="不在每个 cell 内 auto-crop")
    s2.set_defaults(func=_cli_atlas)

    s3 = sub.add_parser("crop", help="auto-crop 透明边")
    s3.add_argument("--src", required=True)
    s3.add_argument("--out", required=True)
    s3.add_argument("--alpha-threshold", type=int, default=8)
    s3.set_defaults(func=_cli_crop)

    s4 = sub.add_parser("quantize", help="palette quantize")
    s4.add_argument("--src", required=True)
    s4.add_argument("--out", required=True)
    s4.add_argument("--colors", type=int, default=16)
    s4.set_defaults(func=_cli_quantize)

    s5 = sub.add_parser("remove-bg", help="去掉浅色 checkered 假透明背景")
    s5.add_argument("--src", required=True)
    s5.add_argument("--out", required=True)
    s5.add_argument("--threshold", type=int, default=200)
    s5.set_defaults(func=_cli_remove_bg)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
