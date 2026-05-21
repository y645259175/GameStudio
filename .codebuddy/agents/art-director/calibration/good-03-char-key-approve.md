# Calibration · art-director · GOOD-03

## 前置场景
- art-asset-pipeline 产出 1 张 canonical key sprite（主角正面站立）
- style-guide 已锁定色板 + 尺寸规格

## 条件
- 需要评审 key sprite 是否可作为后续派生的参考基准
- 角色一致性 5 项检查

## 产出摘要
- verdict: AD-CHAR-KEY-APPROVE
- consistency_5_check:
  - 轮廓比例: PASS（"头身比 1:2.5 符合 style-guide §4"）
  - 主色板: PASS（"主体 #5C7A6E ± Δ3，金属配件 #8B7355"）
  - 风格细节: PASS（"2px 描边 + 像素紧密度一致"）
  - 关键特征: PASS（"护目镜位置 + 背包形态 + 铜质手套 标志性元素到位"）
  - 尺寸: PASS（"32x48px 符合规格"）

## 为什么是 GOOD
1. 5 项全有具体数值支撑（hex / px / 比例）
2. 关键特征列到了具体物件（不是"看起来对"）
3. APPROVE 后明确路径：可用此 key 作为 image_edit 参考，进入 Step B 派生

## 通用教训
- char-key 评审是多帧一致性的第一道门——APPROVE 质量直接决定后续派生质量
- 5 项每项都要有可量化证据（hex / px / 比例数字）
