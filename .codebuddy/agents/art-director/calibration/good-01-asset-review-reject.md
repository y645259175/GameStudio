# Calibration · art-director · GOOD-01

## 前置场景
- art-asset-pipeline 产出一批 4 帧主角动画（idle/run/jump/fall）
- style-guide 定义主色 #8B7355 + 32x48px sprite 尺寸
- 4 帧是分别用 text2image 独立生成的（违反 SOP）

## 条件
- 4 帧风格明显不一致（帧 1 像素风 / 帧 2 半写实 / 帧 3 卡通 / 帧 4 水彩）
- 尺寸也不统一（32x48 / 48x64 / 32x32 / 40x40）

## 产出摘要
- dimensions:
  - composition: MINOR（"帧 3 构图偏左"）
  - color: FAIL（hex_violations: ["帧 2 主色 #FF6347 偏离 #8B7355 Δhue=85°"]）
  - proportion: FAIL（"4 帧尺寸不统一：32x48/48x64/32x32/40x40"）
  - lighting: PASS
  - consistency: FAIL（"4 帧显然不是同一角色——轮廓/描边/渲染风格全部不同"）
- naming_compliance: true
- import_metadata: true
- verdict: AD-REJECT
- reject_remediation: ["必须先走 AD-CHAR-KEY 评审单帧 → APPROVE 后再用 image_edit 派生", "统一到 32x48px", "reference-based 确保角色一致性"]
- self_rubric: 7/7 PASS

## 为什么是 GOOD
1. **3 个 FAIL 直接 REJECT**——不因为"凑合能用"降级为 MINOR
2. hex_violations 具体到 Δhue 数值（可验证）
3. consistency 检查引用了角色一致性 5 项中的 3 项具体违反
4. reject_remediation 给了明确修复路径（不是"重做"一个字）
5. 这就是 bolt-1-1 M6.2 4 帧事故的正确处理方式

## 通用教训
- **多帧资产一致性是 art-director 最核心的红线**——任何"分别生成"的流程 = 必出不一致
- reject 时必须给 remediation（怎么修），否则 pipeline 不知道怎么重做
