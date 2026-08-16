# 幽魂 — Core / Icon / World / VFX Specification

引用：`ART_BIBLE.md` 的 Summon Style、水属性语言、Artifact Icon/World 规则。

## 资产用途

Vertical Slice 召唤法宝；模板 `summon`，体系召唤，属性水。必须与敌人同时保持归属可读性。

## Core Silhouette

- 圆顶小灵体，下摆分成三个向外圆弧齿，中间有水滴形负空间。
- 两侧短袖/鳍向外，整体没有尖角。
- 24×24 下呈“圆顶 + 三圆齿 + 水滴孔”。

## Technical Specification

- Source：core/icon 128×128；world animation cell 128×128。
- Display：icon 64×64；world 28×36。
- 视角：俯视 3/4，面向目标允许水平翻转。
- 主色：淡纸灰 `#D7DDD7`、墨青 `#24343A`。
- 属性色/归属：水 `#5FA8D3` + 脚下 Player Cyan 圆印；不是仅靠蓝色区分。
- 线宽：icon 6 px；world 显示 1.5–2 px。
- 背景：透明；友方圆印独立程序节点。
- Icon/World/VFX：icon 和 world 使用相同灵体外形与水滴孔；召唤/重生 VFX 使用该水滴孔扩成圆印。
- 动画：idle 2、move 4、attack 2、hurt 1、defeat 2、respawn 2；允许轻微程序漂浮，Reduce Motion 时关闭。
- Godot import：lossless、Linear；pivot 在下摆中心，图集 padding 4 px。

## Production Prompt

Create a friendly ghost summon for a top-down Chinese cultivation roguelite in flat ink-and-paper style. Shared icon and world silhouette: rounded dome head, three outward rounded scallops at the lower edge, short fin-like sleeves, and a distinctive water-drop negative hole in the torso. No sharp hostile corners. Muted paper-gray and ink-navy with a restrained water-blue accent, thick outline, transparent background, consistent small animation sheet.

## 不允许出现

- 恐怖写实鬼脸、尖牙红眼、敌方尖角轮廓。
- 蓝色 glow 作为唯一友方标记、长尾烟雾、透明度过低。
