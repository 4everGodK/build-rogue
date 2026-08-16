# 护体剑轮 — Core / Icon / World / VFX Specification

引用：`ART_BIBLE.md` 的 Artifact / Weapon Style、orbit 语言、木属性语言。

## 资产用途

Vertical Slice 环绕法宝；模板 `orbit`，体系剑修，属性木。验证多实体环绕不会形成高噪音光圈。

## Core Silhouette

- 单枚护体短剑：叶片形剑身，中央细长叶脉负形，短圆柄。
- 组合轮廓：三枚短剑首尾错开围成不闭合圆，留一个明显 60° 缺口。
- icon 使用组合轮廓；world 使用同一单枚短剑重复实例。

## Technical Specification

- Source：单剑 core/world 64×64；组合 icon 128×128。
- Display：icon 64×64；单剑 world 26–34，环绕半径按数据。
- 视角：单剑侧俯视；剑尖沿轨道切线方向。
- 主色：纸白刃、低饱和青木 `#587A5D`。
- 属性色：木 `#66B878`，仅叶脉与命中弧。
- 线宽：icon 6 px；单剑显示轮廓 1.5–2 px。
- 背景：透明；轨道环由低 alpha Line2D 生成。
- Icon/World/VFX：icon 的每枚剑必须与 world 单剑完全同形；VFX 只在命中时出现短叶形弧。
- 动画：Godot 轨道旋转；不制作逐帧。ready/命中各一次 ≤140 ms。
- Import：lossless、Linear；单剑 pivot 在质心，图标安全区 12 px。

## Production Prompt

Design a shared leaf-blade short sword silhouette for an orbiting guardian sword artifact. The blade has a leaf shape, a narrow leaf-vein negative cut, and a short round handle. Create a transparent UI icon using three identical swords around an incomplete circle with a clear sixty-degree gap, and a transparent single-sword world sprite using exactly the same shape. Warm paper blade, muted green wood, restrained green accent, thick ink outline.

## 不允许出现

- icon 和 world 使用不同剑型、完整高亮圆环、六把剑挤成花纹。
- 大面积绿色雾、树枝取代剑、轨道常驻高亮。

