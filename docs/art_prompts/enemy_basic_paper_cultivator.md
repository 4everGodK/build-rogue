# Basic：纸傀邪修 — Production Specification

引用：`ART_BIBLE.md` 的 Enemy Style、Sprite Rules、Animation Rules、VFX Rules。

## 资产用途

高数量基础近战敌人；画面中可同时出现数十只，因此轮廓和低视觉噪音优先。

## Technical Specification

- Source size：每帧 128×128。
- World display：30×38 world px。
- 视角：俯视 3/4，朝向玩家时允许水平翻转。
- Silhouette：窄长水滴形身体、略低重心；单侧黄符手臂向外形成唯一负形；头部小而圆。
- 主色：低饱和灰紫 `#403B4B`、墨黑 `#10181B`。
- 危险色：仅攻击前摇的朱红三角 `#D9533F`；黄符为低饱和 `#C8A852`。
- 属性色：基础敌人不绑定属性；禁止用玩家五行色填满身体。
- 线宽：源 5–7 px 深墨轮廓；显示后 1.5–2 px。
- 背景：透明；阴影独立节点或独立 sprite。
- Icon/World 关系：未来图鉴 icon 使用同一水滴身形和单侧黄符手臂，不增加法器或斗笠。
- 动画：idle/move 2–4 帧、hurt 1 帧、defeat 2 帧；死亡为纸片折塌，不做长溶解。
- Godot import：lossless、Linear、fix alpha border；pivot 脚底中心，阴影不进入碰撞轮廓。

## Production Prompt

Create a transparent 2D enemy sprite sheet for a top-down Chinese cultivation roguelite in flat hand-painted ink-and-paper style. A basic corrupted paper-puppet cultivator with a narrow teardrop body, low center of gravity, tiny round head, and one yellow talisman arm creating a distinctive side notch. Muted gray-purple body, thick dark ink outline, very low detail for dozens on screen. Top-down three-quarter view, consistent proportions, short idle/move/hurt/fold-collapse animations.

## 不允许出现

- 高饱和全身红、常驻发光眼、复杂袍纹。
- 与玩家相同的高马尾/宽袖轮廓。
- 巨大武器、飘散粒子、永久血条或 baked shadow。
