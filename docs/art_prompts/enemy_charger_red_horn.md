# Charger：赤角冲阵妖 — Production Specification

引用：`ART_BIBLE.md` 的 Enemy Style、Enemy vs Player Telegraph、VFX Rules。

## 资产用途

冲锋危险单位，负责验证方向性预警在 30–80 敌人下是否清晰。

## Technical Specification

- Source size：每帧 160×128。
- World display：44×36 world px。
- 视角：俯视 3/4；身体朝实际冲锋方向旋转。
- Silhouette：前宽后窄的箭头/楔形身体；两只短赤角构成前端，后部有一个 V 形缺口。
- 主色：低饱和焦褐 `#55443B`、墨青 `#172328`。
- 危险色：角和前摇纹使用 `#D9533F`；同时必须有三角纹和向内收束运动。
- 属性色：敌方类型不绑定玩家五行；冲锋危险统一使用朱红预警语言。
- 线宽：源 6–8 px；前端轮廓最重。
- 背景：透明；冲锋线独立为 Line2D，不烘焙。
- Icon/World 关系：图鉴 icon 使用同一楔形、双角和尾部 V 缺口。
- 动画：idle 2、run 4、windup 2、dash 1–2、recovery 1、hurt 1、defeat 2。
- Godot import：lossless、Linear；pivot 位于身体中心偏后，碰撞半径不包含角尖。

## Production Prompt

Create a transparent 2D charger-demon sprite sheet for a top-down Chinese cultivation roguelite in flat hand-painted ink-paper style. The creature must read as a forward-pointing wedge or arrow: broad horned front, narrow rear, two short vermilion horns, and a V-shaped notch at the tail. Muted burnt-brown and ink-navy body with thick contour. Top-down three-quarter view, very clear directional windup and dash poses, minimal surface detail.

## 不允许出现

- 圆球或四方体轮廓、长鹿角、全身橙红。
- 无法判断前后的对称造型。
- 常驻速度线、baked warning line、重度动态模糊。
