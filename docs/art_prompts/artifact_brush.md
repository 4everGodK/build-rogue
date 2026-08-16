# 毛笔 — Core / Icon / World / VFX Specification

引用：`ART_BIBLE.md` 的 line_delayed、木/毒双属性、Core Silhouette Workflow。

## 资产用途

Vertical Slice 特殊延迟攻击；模板 `line_delayed`，体系法修，双属性木 + 毒。验证“预写 → 落墨”的时间信息。

## Core Silhouette

- 斜向毛笔，竹节笔杆有两个矩形节点。
- 笔毫呈单侧弯钩，尖端留一滴形缺口；这是与普通法杖区分的关键。
- 24×24 下看出“竹节杆 + 弯钩笔毫”。

## Technical Specification

- Source：core/icon 128×128；world brush 96×48；VFX line mask 256×64。
- Display：icon 64×64；world 笔长 54–72；墨线宽 5–10。
- 视角：侧俯视，左下到右上；world 可沿书写方向旋转。
- 主色：竹褐 `#8A653D`、墨黑 `#10181B`。
- 属性色（双属性）：木 `#66B878` 位于竹节；毒 `#7952A8`/`#8FBF4C` 只在落墨末端点簇，占 20–30%。
- 线宽：icon 6 px；world 2 px；预写线 2–3 px，落墨 5–8 px。
- 背景：透明。
- Icon/World/VFX：相同笔毫弯钩必须出现在 icon 和 world；VFX 起笔形状复制笔毫轮廓，先淡墨预写，再实墨落笔。
- 动画：笔体由 Godot Tween 移动；anticipation 200–280 ms，impact 100–160 ms；不做逐帧墨龙。
- Import：icon/world lossless Linear；VFX mask lossless、无 mipmap；pivot 在笔杆握持端。

## Production Prompt

Design one shared core silhouette for a cultivation magic brush, then derive transparent UI icon, world brush sprite and delayed ink-line VFX. Diagonal bamboo brush with two clear rectangular bamboo joints, a one-sided hooked bristle tip, and a tiny droplet-shaped negative notch at the tip. Flat hand-painted rice-paper style, bamboo brown and deep ink, restrained wood-green at the joints and small poison purple-green dots only at the final ink impact.

## 不允许出现

- icon 是书法插画而 world 只有墨线、毛笔变成长法杖。
- 墨龙、整屏书法字、大面积毒雾、木毒平均渐变。
