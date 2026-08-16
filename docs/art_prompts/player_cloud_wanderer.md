# 云游小修士 — Production Specification

引用：`ART_BIBLE.md` 的 Character Style、Sprite Rules、Animation Rules、Godot Import Rules。

## 资产用途

玩家战场角色，是 30–80 敌人混战中的首要定位锚点。后续头像/印章必须由相同高马尾与宽袖轮廓衍生。

## Technical Specification

- Source size：每帧 192×192；最终图集按动画横向或网格排列。
- World display：约 36×48 world px；接地点位于 cell 高度 82%。
- 视角：俯视 3/4，默认朝右下；允许水平翻转，不制作八方向。
- Silhouette：2.5 头身；高马尾向后上方伸出，宽袖形成左右体块，短袍下摆是稳定梯形；腰间朱印袋形成一个小方形缺口。
- 主色：墨青 `#172328`、米白 `#F3E8CE`；肤色面积小。
- 识别色：Player Cyan `#71D6D1`，只用于腰带流苏/袖口，占 10–15%。
- 属性色：玩家本体不绑定五行；属性反馈由独立 VFX 表达，不改角色主色。
- 线宽：源文件 6–8 px 深墨外轮廓；显示后约 1.5–2 px。内部线不小于 5 px。
- 背景：完全透明；不烘焙地面、光晕或矩形底。
- Icon/World 关系：若制作 HUD 头像，只裁取同一头部、高马尾和朱印袋符号，不重新设计脸型或发型。
- 动画：idle 2 帧、move 4 帧、hurt 1 帧、defeat 2 帧；动作幅度小，允许 Godot 程序 bob。
- Godot import：lossless、Linear、fix alpha border、premult alpha false；图集格间 4 px padding，pivot 在脚底中心。

## Production Prompt

Create a transparent-background 2D game sprite sheet for a relaxed Chinese cultivation roguelite, flat hand-painted paper-cut style, chibi wandering cultivator at 2.5 heads tall, top-down three-quarter view facing lower-right. Strong readable silhouette: high ponytail, broad sleeves, short trapezoid robe, small square vermilion seal pouch at the waist. Ink-navy and warm rice-paper clothing with a very small cyan player accent. Thick dark-ink contour, minimal facial detail, no pixel-art jaggies, no lighting background. Produce consistent idle, move, hurt and defeat poses without changing proportions or camera angle.

## 不允许出现

- 写实人体、长腿 6–8 头身、复杂盔甲、满身金饰。
- 侧面平台游戏视角、正俯视头顶、八方向差异造型。
- 大面积青色发光、武器抢占轮廓、背景渐变或投影烘焙。
- 细碎发丝、低于显示 2 px 的衣纹、像素画与平滑线混用。
