# 巨剑术 — Core / Icon / World / VFX Specification

引用：`ART_BIBLE.md` 的 Artifact / Weapon Style、Rarity、金/土属性语言。

## 资产用途

Vertical Slice 重型发射物；模板 `projectile`，体系剑修，双属性金 + 土，仙宝。

## Core Silhouette

- 宽厚巨剑，剑身为压低的长六边形。
- 剑脊右侧有一处方形崩口，这是核心负形。
- 短柄、小护手，避免像普通双手剑。
- 24×24 下呈“宽刃 + 方崩口”，不能只靠尺寸区分。

## Technical Specification

- Source：core/icon 128×128；world 192×96。
- Display：icon 64×64；world 长 120–160 world px，短时出现。
- 视角：侧俯视，左下到右上；发射时剑尖朝运动方向。
- 主色：墨铁 `#3C4848`、纸白刃缘 `#F3E8CE`。
- 属性色：金 `#E5C86A` 为刃缘；土 `#B58A55` 为剑脊方块，占 20–30%。
- 线宽：icon 7 px；world 2 px。
- 背景：透明。
- Icon/World/VFX：同一宽刃 polygon；尾迹是较细的金色直痕，impact 是土色块状震环。
- 动画：短 windup 轮廓显现、直线飞行、重击 160–220 ms；不做常驻旋转 glow。
- Godot import：lossless、Linear Mipmap；pivot 位于质心，world sprite 与碰撞长度一致。

## Production Prompt

Create a single bold core silhouette for a magical giant sword projectile in a lighthearted Chinese cultivation roguelite. Derive both UI icon and world sprite from the same wide low-hexagonal blade, short handle, small guard, and a unique square chip cut from one side of the spine. Flat hand-painted ink-paper style, dark iron body, warm gold metal edge, restrained earth-brown spine block, thick dark contour, transparent background.

## 不允许出现

- 复用普通飞剑细轮廓、独立卡面插画、剑气替代实体。
- 巨量金光、复杂符文填满剑身、平均金土渐变。
