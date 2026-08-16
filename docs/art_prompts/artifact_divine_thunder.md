# 神雷术 — Core / Icon / World / VFX Specification

引用：`ART_BIBLE.md` 的 target_aoe、雷属性、VFX Three-Stage Structure。

## 资产用途

Vertical Slice 范围攻击；模板 `target_aoe`，体系法修，属性雷。主要验证预警与玩家法术不会被误认成敌方危险。

## Core Silhouette

- 法宝不是普通闪电图标，而是一枚断开的六边雷印。
- 六边印右上断口伸出一条短折线；中心保留菱形负空间。
- 24×24 下仍可识别“断六边 + 中央菱形”。

## Technical Specification

- Source：core/icon 128×128；world marker 64×64；VFX mask 256×256。
- Display：icon 64×64；world 雷印 32–48；落雷范围由数据驱动。
- 视角：正视符印；战场落点为俯视圆域。
- 主色：墨青印体 `#24343A`、纸白 `#E8F6FF`。
- 属性色：雷 `#8CCEF0`；玩家 AOE 使用向外扩散折线，不使用敌方朱红三角。
- 线宽：icon 6 px；world/VFX 3–5 world px。
- 背景：透明。
- Icon/World/VFX：icon 的断六边雷印直接作为 world 落点中心；VFX 从断口延伸同形折线。
- 动画：anticipation 180–240 ms 低 alpha；action 80–120 ms；impact 120–180 ms。Reduce Motion 时不旋转。
- Godot import：icon lossless Linear；VFX mask lossless、无 mipmap、可由 Line2D 优先实现。

## Production Prompt

Design a distinctive divine-thunder seal for a Chinese cultivation roguelite, not a generic lightning-bolt icon. Shared core silhouette: broken hexagonal talisman ring, a short angular bolt emerging from the upper-right break, diamond-shaped negative space in the center. Derive transparent UI icon, small world marker, and VFX mask from the same geometry. Ink-navy, icy paper-white and restrained pale-cyan lightning, flat hand-painted style, thick clean contour.

## 不允许出现

- 复用天眼 icon、单独一根闪电、紫色霓虹魔法阵。
- 敌方朱红预警纹、长时间电网、全屏白闪。
