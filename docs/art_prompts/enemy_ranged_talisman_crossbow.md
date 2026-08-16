# Ranged：符弩散修 — Production Specification

引用：`ART_BIBLE.md` 的 Enemy Style、Enemy vs Player Telegraph、Sprite Rules。

## 资产用途

远程威胁单位。玩家必须在敌群中先看到其发射方向和攻击前摇。

## Technical Specification

- Source size：每帧 128×128。
- World display：36×40 world px。
- 视角：俯视 3/4，发射器朝向目标旋转或翻转。
- Silhouette：菱形斗笠为上半部，横向弩臂贯穿身体，形成明显 `◇—` 轮廓；下半身窄。
- 主色：低饱和青灰 `#354B50` 与纸褐 `#6E604D`。
- 危险色：朱红符核 `#D9533F` + 三角/斜纹；不得使用玩家水/雷的纯青色作为唯一前摇。
- 属性色：敌方类型不绑定玩家五行；远程危险统一使用朱红预警语言。
- 线宽：源 5–7 px，弩臂至少 8 px 厚。
- 背景：透明；瞄准线、警示三角为独立程序 VFX。
- Icon/World 关系：图鉴 icon 保留菱形斗笠和横弩负形；不改成持法杖人物。
- 动画：idle 2、move 4、windup 2、fire 1、hurt 1、defeat 2；windup 中弩臂方向稳定。
- Godot import：lossless、Linear、pivot 脚底；发射点作为 Marker2D 位于横弩前端。

## Production Prompt

Create a transparent top-down three-quarter enemy sprite sheet for a Chinese cultivation roguelite, flat ink-and-paper style. A ranged rogue cultivator defined by a diamond-shaped straw hat and a wide horizontal talisman crossbow, giving a clear diamond-plus-bar silhouette. Muted blue-gray and paper-brown body, thick ink outline. Include a readable two-step windup where a small vermilion triangular talisman core activates, but keep telegraph graphics separate from the sprite.

## 不允许出现

- 青色全身发光、细小写实弩、与 Basic 相同窄人形。
- 把瞄准线烘焙在 sprite 内、无方向的爆闪前摇。
- 斗笠遮成纯圆形，导致失去菱形行为轮廓。
