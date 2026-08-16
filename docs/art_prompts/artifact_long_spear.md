# 长枪 — Core / Icon / World / VFX Specification

引用：`ART_BIBLE.md` 的 Artifact / Weapon Style、Icon Rules、属性视觉语言。

## 资产用途

Vertical Slice 近战法宝；模板 `melee`，体系剑修，属性火。用于验证实体法宝与火焰突刺的一致性。

## Core Silhouette

- 单一长轴，由左下指向右上。
- 菱形枪尖占总长 22%，枪尖中间有一个小燕尾负形。
- 枪杆尾端为短红缨结，不画大飘带。
- 24×24 时必须仍看出“菱形枪尖 + 燕尾缺口 + 长杆”。

## Technical Specification

- Source：core 128×128；icon 128×128；world 128×64。
- Display：icon 64×64；world spear 长 72–92 world px，宽 8–12。
- 视角：侧俯视图，与攻击方向同轴。
- 主色：深木褐 `#6E4A2C`、纸白刃 `#F3E8CE`。
- 属性色：火 `#EF6A3C`，只用于红缨和枪尖命中末段。
- 线宽：icon 6 px；world 显示后 1.5–2 px。
- 背景：完全透明。
- Icon/World/VFX：三者复用相同枪尖 polygon；VFX 是枪尖轮廓延伸出的短橙朱楔形，不替代实体枪。
- 动画：world 无逐帧；Godot 旋转/位移。anticipation 80–120 ms，impact 100–140 ms。
- Import：lossless、Linear、fix alpha border；world pivot 在握持点，碰撞与枪尖方向对齐。

## Production Prompt

Design one shared core silhouette for a Chinese cultivation long spear, then derive a transparent 128px UI icon and a transparent world sprite from it. Flat hand-painted paper-cut style, diagonal lower-left to upper-right, distinctive diamond spearhead with a small swallow-tail negative cut, dark wooden shaft, tiny vermilion tassel. Thick dark ink contour. Fire accent is secondary and must not obscure the physical spear shape.

## 不允许出现

- icon 画人物持枪、world 只剩一道火线。
- 大片火焰、金龙纹、写实金属反射、复杂长缨。

