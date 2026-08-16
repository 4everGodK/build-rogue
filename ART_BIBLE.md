# BuildRogue Art Bible

> Version 0.1 — Vertical Slice
>  
> Canonical direction: **云笺百宝 / Treasures on Cloud Paper**
>  
> 本文件是项目 UI 与美术资源的唯一视觉规范。若实现与本文冲突，应先更新本文并记录理由，再修改资产。

## Overall Style

轻松、有趣、辨识度高的国风修仙 Build Roguelite。视觉语言由四部分组成：

1. **Q 版俯视角色**：2–2.5 头身，宽轮廓、少细节、强行为剪影。
2. **扁平手绘法宝**：核心轮廓在 24 px 仍可识别；UI 与战场共用同一形状语汇。
3. **宣纸、墨迹、朱印**：作为材质和标记，不作为大面积装饰。
4. **现代 Roguelite UI**：信息优先、卡片化、快速比较、完整控制器导航。

关键词：`chibi`、`flat hand-painted`、`paper cutout`、`ink contour`、`seal marks`、`low-noise battlefield`、`glanceable build UI`。

非目标：传统国产仙侠手游、写实国风、重度像素美术、满屏泛光、复杂卷轴、金色雕花边框、逐帧大动画。

## Visual Principles

### 1. Silhouette Before Detail

任何战斗资产先通过纯黑剪影测试，再加颜色与纹理。玩家、敌人、召唤物、法宝在 100% 灰阶和 50% 缩放下仍须可分辨。

### 2. Information Has a Budget

同一时刻最多允许三层高关注信息：

- 第一层：敌方危险与玩家生存。
- 第二层：法宝攻击与命中反馈。
- 第三层：场景、装饰和非关键 UI。

所有元素不得同时发光、同时抖动或同时使用最高饱和度。

### 3. Shape + Colour + Motion

关键语义至少使用两种编码。属性不能只靠颜色；敌我不能只靠红绿；品阶不能只靠边框色。

### 4. Icon Equals World Object

每件法宝先建立一个 `core silhouette`。UI icon 和 world sprite 必须共享：

- 主轮廓。
- 主要朝向。
- 一个独特负形或缺口。
- 主色位置。

UI icon 可以增加纸卡底、边缘光和属性角印，但不能把法宝画成另一件东西。

### 5. Centre Is Sacred

战斗屏幕中心与玩家周围即时危险区不放永久 UI。静态 HUD 进入 90% title-safe；中心只允许短时预警、伤害数字和交互反馈。

### 6. Build Decisions in Three Seconds

商店卡必须让玩家按以下顺序读取：

`轮廓 → 名称/星级 → 攻击形态 → 体系/属性 → 构筑影响 → 价格/可购买状态`

### 7. Production-Aware

优先使用单朝向 + 水平翻转、2–4 帧循环、程序 Tween、Line2D/Polygon2D 和可复用 VFX。只有 Boss、突破和仙宝获得额外帧数与材质预算。

## Character Style

### Player

- 2.5 头身，俯视 3/4，默认朝右下；左右移动允许水平翻转。
- 核心轮廓：高马尾、宽袖、短袍、腰间朱红印袋。
- 主体 70% 使用墨青/米白；玩家识别色为 `Player Cyan`，只占 10–15%。
- 面部只保留眼、眉和一处肤色面；世界显示尺寸下不画嘴部细节。
- 脚下固定使用椭圆墨影，位置识别优先于脚步动画。
- 玩家受击使用 60–90 ms 暖白闪、轻微 squash，不让 HUD 或相机同步抖动。

### Outfit Language

- 凡俗层：布料、木扣、麻绳。
- 法器层：一块玉、一条符纸或一处金属件。
- 灵器层：第二材质 + 更清晰的内轮廓。
- 灵宝/仙宝层：增加悬浮碎片或短时阵纹，不增加常驻大面积 glow。

### Direction and Animation

- Vertical Slice 不制作八方向角色。
- 默认：idle 2 帧、move 4 帧、hurt 1 帧、defeat 2 帧。
- 移动可用脚步 2 帧 + 身体程序 bob；翻转前确认文字、符箓不被镜像误读。

## Enemy Style

敌人采用“水墨纸偶与妖怪剪影”。行为类别必须先由外轮廓区分：

| 行为 | 主形状 | 重心 | 固有标记 |
|---|---|---|---|
| Basic | 窄圆/水滴 | 中低 | 单张黄符 |
| Fast | 长梭/四足 | 前低 | 尾部拖墨 |
| Tank | 方/梯形 | 低且宽 | 双肩石甲 |
| Ranged | 菱形/横杆 | 中高 | 横向弩臂或法杖 |
| Charger | 前宽后窄箭头 | 前低 | 赤角 + 三角纹 |
| Boss | 双层不对称轮廓 | 居中 | 独立头冠/核心 |

规则：

- 普通敌人世界显示高度 28–42；Tank 44–54；Boss 72–104。
- 所有敌人使用统一的 1.5–2 px 深墨外轮廓和地面阴影。
- 敌人主体保持低饱和，危险行为才使用 `Enemy Vermilion`。
- 远程前摇必须显示“发射器方向 + 敌方三角纹”；冲锋必须显示有方向的警示线。
- 精英不是简单放大或全身变色：增加断裂双边框、额头印和单个悬浮符片。
- 同屏 30+ 时禁用普通敌人的常驻血条；受伤时短暂出现，Boss/精英例外。

## Summon Style

召唤物必须与敌人同时满足“形状”和“归属”区分：

- 召唤物轮廓以圆、盾、友方朝外弧线为主；敌人危险轮廓以尖角、内收三角为主。
- 脚下使用青蓝圆环 + 小型印记；敌方使用朱红断线三角。
- 召唤物主体饱和度低于玩家法宝特效，避免抢夺技能阅读。
- 召唤物重生用纸片聚合/印章复位，不使用长时间传送光柱。
- 召唤物死亡冲击只显示一次外扩墨环，不生成大量碎片。

## Artifact / Weapon Style

法宝是项目的最高优先级资产。

### Core Silhouette Workflow

每件法宝必须按顺序产出：

1. 16 个纯黑缩略轮廓草案。
2. 选出 3 个，在 24×24、40×40、64×64 测试。
3. 确认一个 `core silhouette`。
4. 同时制作 UI icon 和 world sprite。
5. 再制作攻击前摇、攻击体、命中三阶段 VFX。

禁止先画一张复杂商店插画，再另行设计战场图形。

### UI Icon

- 画布：128×128，透明背景；内容安全区 12 px。
- 法宝主体占画布 68–82%，默认由左下指向右上；环、球、阵等径向物例外。
- 轮廓线在 128 图源中为 5–7 px，缩小至 40 px 后仍保留至少 1.5 px 视觉重量。
- 只使用 1 个主体材质色、1 个边缘色、1 个属性强调色。
- Icon 文件本身不包含品阶边框、星级、价格、锁、体系或属性文字；这些由 UI 组件叠加。

### World Sprite

- 使用相同 core silhouette，允许简化内纹理，不允许改变主轮廓。
- 常驻实体占 24–64 世界像素；巨型法宝/仙宝可到 96–160，但持续时间必须短。
- 世界 Sprite 不自带深色圆角方底。
- 射弹前端必须明确，尾迹不得比实体更亮、更粗。
- 近战攻击应在前摇阶段短暂显示实体法宝轮廓，斩击只是第二层反馈。

### Attack Template Language

| Template | 视觉结构 | 读取重点 |
|---|---|---|
| melee | 实体法宝 + 短弧 | 方向、范围、重量 |
| projectile | 实体轮廓 + 细尾迹 | 前端、速度、敌我 |
| orbit | 重复实体 + 极淡轨道 | 数量、旋转范围 |
| beam | 起点核心 + 直线/锥 | 前摇、宽度、持续 |
| formation | 断续圆环 + 4–6 个节点 | 范围、持续效果 |
| line_delayed | 淡墨预写线 → 实墨落笔 | 延迟、命中时刻 |
| summon | 印记落地 → 单位实体 | 归属、职责、重生 |
| target_aoe | 敌我编码的落点纹 → 爆发 | 危险时间、半径 |
| soul_banner | 固定幡体 + 灵体流向 | 控场中心、吸附方向 |

## UI Style

UI 采用“深墨框架 + 暖纸内容 + 印章标签”。装饰不应超过组件面积的 12%。

### Layers

| Layer | Godot 建议 | 内容 |
|---|---:|---|
| World | z -50–79 | 地面、角色、法宝、VFX |
| World Feedback | z 80–119 | 命中、伤害数字、预警 |
| HUD | CanvasLayer 5 / z 0–99 | 固定战斗信息 |
| Overlay | z 100–199 | 展开羁绊、通知、暂停遮罩 |
| Modal | z 200–299 | 商店确认、突破、结算 |
| Tooltip | z 300–349 | Tooltip/比较卡 |
| System | z 400–449 | 输入提示、错误、重要通知 |

### Material Language

- 深墨框架：接近不透明的青黑，不使用纯黑。
- 暖纸内容：仅用于商店、Tooltip、设置和结算；战斗 HUD 不使用大面积亮纸。
- 玉片：用于选中、可升级和修为进度，不用于所有按钮。
- 木材：只在商店区域标题/分隔中少量出现。
- 朱印：用于确认、关键状态和世界观签名；危险仍需三角/斜纹冗余。

## Colour Palette

### Foundation

| Token | Hex | 用途 |
|---|---|---|
| `ink-950` | `#10181B` | 最深面板、文字描边 |
| `ink-900` | `#172328` | 主 HUD/商店背景 |
| `ink-800` | `#24343A` | 次级面板、禁用轮廓 |
| `paper-100` | `#F3E8CE` | 主纸色 |
| `paper-200` | `#E2D2B4` | 次级纸色、分隔 |
| `paper-700` | `#6E604D` | 纸面次级文字 |
| `text-light` | `#F7F3E8` | 深底主文字 |
| `text-dark` | `#252923` | 纸底主文字 |
| `jade-500` | `#4FAF98` | 选中、修为、友方状态 |
| `player-cyan` | `#71D6D1` | 玩家定位、友方归属 |
| `vermilion-500` | `#D9533F` | 敌方危险、关键确认 |
| `amber-500` | `#D89C3D` | 灵石、价格、接近达成 |

背景饱和度通常 ≤ 30%；角色主体 ≤ 55%；属性/VFX 可到 80–100%，但只占小面积。

### Rarity / Tier

品阶同时使用颜色和边框结构：

| 品阶 | 色 | 结构 |
|---|---|---|
| 凡器 | `#8B9696` | 单细边 |
| 法器 | `#5FAE78` | 单粗边 + 1 个角点 |
| 灵器 | `#5E8FD1` | 双线边 + 2 个角点 |
| 灵宝 | `#9A6CC2` | 双线边 + 对角印纹 |
| 仙宝 | `#D89C3D` | 三段边 + 顶部小印，不常驻发光 |

## 属性视觉语言

属性必须由色彩、符号、边缘和运动共同构成：

| 属性 | 主色 | 符号/负形 | 运动与 VFX | 禁止 |
|---|---|---|---|---|
| 金 | `#E5C86A` | 菱角/切面 `◇` | 直、硬、短闪、碎片少 | 纯黄大 glow |
| 木 | `#66B878` | 芽/分叉 `Y` | 生长、缠绕、弧线 | 与治疗完全等同 |
| 水 | `#5FA8D3` | 双波 `≈` | 回流、柔波、圆润 | 与玩家归属只靠蓝色 |
| 火 | `#EF6A3C` | 三角火苗 `△` | 外扩、上扬、短促 | 与敌方危险只靠红橙 |
| 土 | `#B58A55` | 方印/层岩 `▰` | 下压、震环、块状 | 细长高速线 |
| 雷 | `#8CCEF0` + `#E8F6FF` | 折线 `ϟ` | 断续、跳点、瞬时 | 长时间发光电网 |
| 毒 | `#8FBF4C` + `#7952A8` | 三点/滴 `∴` | 点簇、扩散、残留短 | 全屏绿色雾 |

双属性：主体使用主属性，副属性只占 20–30%，位于第二个角印、尾迹节点或命中末段。禁止把两色平均渐变成不明颜色。

## Typography

### Font Families

- UI 正文与数字：`Noto Sans CJK SC / 思源黑体`，Medium/Semibold。
- 标题与世界观短句：`Noto Serif CJK SC / 思源宋体`，Semibold；只用于 1–2 行。
- 拉丁与数字优先使用同一字体家族，保证 tabular numbers 可用。
- 发布前将字体许可证与需要的字形子集记录在 `third_party/NOTICE`。

### Sizes at 1280×720 Logical Viewport

| Token | Size | 用途 |
|---|---:|---|
| `caption` | 14 | 最小辅助信息；禁止更小 |
| `body-sm` | 16 | 标签、卡片次级信息 |
| `body` | 18 | 正文、Tooltip |
| `heading-sm` | 20 | 面板标题、价格 |
| `heading` | 24 | 商店分区、关键 HUD |
| `display` | 32 | 页面标题、倒计时 |
| `display-lg` | 44 | 结算/突破主标题 |

动态背景文字必须拥有以下之一：1–2 px 对比描边、2 px 硬阴影、alpha ≥ 0.82 的底板。正文对比度目标 ≥ 4.5:1。

## Icon Rules

### Families

- 法宝：实体轮廓图，128×128。
- 体系：印章徽记，64×64。
- 属性：几何符号，48×48。
- 攻击形态：线性图标，48×48。
- 通用操作：现代 UI 线性图标，32×32。
- 输入提示：按设备动态替换 Xbox/PlayStation/Nintendo/Keyboard glyph。

### System Emblems

| 体系 | 形状 |
|---|---|
| 剑修 | 竖长六边印 + 剑缺口 |
| 法修 | 圆印 + 三点轨道 |
| 体修 | 方印 + 拳/山形 |
| 召唤 | 双圆印 + 小单位点 |
| 魔修 | 破角印 + 反向月缺 |

不可把文字缩进小图标作为唯一信息。体系名在 Tooltip 和商店卡首次出现时保留文本。

### Stroke and Grid

- 24 px icon：2 px stroke。
- 32–48 px icon：2.5–3 px stroke。
- 64–128 px icon：4–7 px stroke。
- 端点以圆头为主；敌方危险图标允许尖角。
- Icon 在灰阶、色盲模拟和 75% UI scale 下都必须可辨认。

## Sprite Rules

- 角色、敌人、召唤物均使用透明 PNG 或 lossless WebP；不保留大面积透明边距。
- 所有 sprite 使用统一基线：脚底/接地点位于 cell 高度的 78–84%。
- 世界显示轮廓不得小于 1.5 px；内部细节不得小于 2 px。
- 角色本体、阴影、法宝/VFX 分层，避免把所有效果烘焙进一张图。
- 2D 排序以脚底 y 为准；高马尾、武器等不改变排序原点。
- 不混用“硬像素边缘”和“平滑矢量边缘”。本项目采用平滑扁平手绘，Texture Filter 默认 Linear。

### Recommended Source / Display Sizes

| Asset | Source | 典型显示 |
|---|---:|---:|
| Player cell | 192×192 | 36×48 world px |
| Normal enemy cell | 128×128 | 28–44 world px |
| Tank enemy cell | 160×160 | 44–56 world px |
| Boss cell | 256×256 | 72–104 world px |
| Summon cell | 128×128 | 24–42 world px |
| Artifact UI icon | 128×128 | 40–72 UI px |
| Artifact world sprite | 64×64 / 128×128 | 24–96 world px |
| Attribute icon | 48×48 | 18–28 UI px |
| System icon | 64×64 | 24–36 UI px |
| Terrain tile | 256×256 | 256 world px |
| UI 9-slice | 96×96 or 128×128 | responsive |

## Animation Rules

- Animation is communication, not decoration.
- UI 标准：120–180 ms；Modal：180–240 ms；禁止超过 300 ms 的常规 UI 动画。
- Ease：`CUBIC/QUAD ease-out`；禁止弹簧式长回弹、连续漂浮和大范围滑入。
- 选择：scale 1.00 → 1.03，边框变化 + Focus Ring；不能只改变颜色。
- 购买：卡片压下 80 ms，货币扣除，物品轮廓飞向库存可选；总时长 ≤ 260 ms。
- 受击：60–120 ms；死亡 160–260 ms。普通敌人不播放长溶解。
- 同屏 30+ 时，普通敌人的 idle 动画相位随机，且最大只用 2–4 帧。
- `Reduce Motion` 开启后：UI 改为 fade/instant；禁用镜头震动、菜单缩放、连续旋转装饰和大位移。
- 世界震动绝不影响 CanvasLayer HUD。

## VFX Rules

### Three-Stage Structure

1. **Anticipation**：范围/方向/时机，低 alpha。
2. **Action**：法宝实体或攻击主体，最高识别度。
3. **Impact**：短闪、墨点、属性符号，持续最短。

### Budgets

- 一次普通攻击最多 1 个主体 + 1 条尾迹 + 1 个命中效果。
- 普通命中寿命 80–160 ms；重击 160–240 ms；持续效果使用低 alpha 常驻形，不重复爆闪。
- 粒子/碎片每次普通命中 0–4，重击 4–10；大量敌人时按屏幕数量降级。
- 同屏 additive glow 面积不得超过画面 8%；普通攻击尽量不用 glow。
- 地面范围优先用 Line2D/Polygon2D，而非大尺寸半透明纹理叠加。
- 伤害数字对象池化；连续伤害在 200–350 ms 窗口内聚合，同一区域最多 5–6 组。

### Enemy vs Player Telegraph

- 敌方：`vermilion-500` + 三角/斜纹 + 向内收束。
- 玩家：对应属性色 + 属性符号 + 向外扩散。
- 即使玩家使用火属性，敌方危险仍通过形状和运动区分。

## Background Rules

- 背景低对比、低饱和、低纹理频率；中心战斗区最安静。
- 竞技场地表主明度范围控制在 18–35%；角色主体 30–70%；VFX 峰值可到 90–100%。
- 不可碰撞装饰透明度/对比度低于碰撞物；碰撞物必须有一致底部阴影或边缘线。
- 地表纹理不得形成类似射弹、掉落物或预警圈的小高亮点。
- 装饰密度：中心 65% 每 256×256 区域不超过 1 个中型对象；外围可提升到 2–3 个。
- 场景边界通过地表变暗、稀疏界桩和雾线表达，不使用常驻发光墙。
- 墨纹只作为 5–12% alpha 的大形状；禁止高对比书法字铺满地面。

## UI Component Rules

### Spacing and Radius Tokens

- Spacing：`4, 8, 12, 16, 24, 32, 48`。
- Corner radius：`4` 小标签、`8` 卡片、`12` Modal；不混用大量任意值。
- 最小交互热区：48×48；相邻热区间距 ≥ 8。
- 内容内边距：卡片 12–16；面板 16–24；Modal 24–32。

### Buttons

每个按钮必须有：normal、hover、pressed、focus、disabled、loading/processing（若适用）。

- Primary：朱印或玉色实底，仅每屏 1 个主操作。
- Secondary：墨底 + 纸色描边。
- Tertiary：文本/图标按钮，但热区仍 ≥ 48。
- Destructive：朱色 + 危险图标 + 确认；删除/退出等需 hold 或二次确认。
- Focus Ring：3 px 暖纸外框 + 左上小印，不只换色。

### Panels

- HUD panel alpha 0.78–0.9；商店/Tooltip 0.94–1.0。
- 纸纹对比度 ≤ 5%，不影响正文。
- Nine-slice 边缘只允许细墨线、轻微纸毛边或单个角印。

### Artifact Card

卡片必须支持：normal、hover/focus、locked、affordable、unaffordable、upgrade-ready、synergy-complete、sold。

标准层级：

1. 64×64 core icon。
2. 名称 + 星级。
3. 攻击形态 icon + 体系徽记 + 1–2 个属性印。
4. 一行核心机制，不超过 18 个汉字。
5. 构筑预测条：`激活雷 4` / `飞剑升至 ★★`。
6. 价格 + 灵石 icon。

品阶只改变边框结构与一小处色，不改变整张卡背景。

### Synergy Display

- 战斗：最多显示 4 个“已激活/差 1”徽记；完整列表按住详情键展开。
- 商店：显示与当前商品相关的羁绊置顶，其余折叠。
- 进度节点用实心/空心印点表示，例如 `● ● ○ ○`，并同时显示 `3/4`。
- 状态：未相关、进行中、差 1、已激活、升级层、满层；每态有形状差异。

### Tooltip

- Hover/focus 延迟 300 ms；离开后 100 ms 宽限。
- 默认宽 360–440；最大高不超过 70% safe area，超出时内部滚动。
- 不覆盖当前卡片的 icon、价格和 Focus Ring。
- 第一屏只显示决策信息；Lore 与完整公式进入 Inspect 层。
- 支持 controller focus；显示当前绑定的“详细信息”动作，不硬编码按键名。

### HUD

- 左上：玩家生存与货币。
- 上中：倒计时/波次；倒计时优先于剩余敌人数。
- 右上：上下文羁绊/状态，默认折叠。
- 下中：法宝槽；冷却使用遮罩扫掠 + 数字（仅 > 1 s）+ ready 短闪。
- 中心不放永久信息；低血量警告使用屏幕边缘轻墨晕，不遮挡敌人。

### Main Menu

- 标题在左上/上中，主体插画或场景留在右侧/背景；不使用一个孤立的默认 Panel 居中。
- 主操作顺序：继续（有存档）/开始、图鉴、设置、退出。
- 背景为安静的山门试炼坪，法宝剪影缓慢掠过；Reduce Motion 时静止。
- 首个可用按钮自动获得焦点；返回逻辑不允许直接误退出。

### Settings

必须至少包含：

- UI scale：75/100/125/150/200%。
- Safe area：0–10%。
- 字体大小：Normal/Large/Larger。
- Reduce Motion、Camera Shake 0–100%、Hit Stop 开关/强度。
- Damage Numbers：All/Combined/Critical Only/Off。
- Colorblind：Off/Deuteranopia/Protanopia/Tritanopia；属性符号始终保留。
- 输入重绑定、当前设备 glyph、恢复默认。
- 对比度与背景纹理强度。

### Pause and Results

- Pause：左侧纵向菜单，右侧显示当前构筑摘要；世界暂停且背景降饱和。
- Victory：暖纸底 + 朱印“渡劫成功”；先显示核心战绩，再显示伤害/法宝明细。
- Defeat：墨色更重但不惩罚性羞辱；主操作“再来一局”，次操作“查看构筑/返回”。
- 结算对比使用条形与排序；不把所有数值堆成长文本。

## Godot Import Rules

### Project Display

- 逻辑 viewport：1280×720。
- Stretch mode：`canvas_items`；aspect：`keep`。
- 超宽屏扩展世界画面，但 HUD 默认约束到 16:9 safe frame；允许设置扩展 HUD。
- Static HUD 默认位于 90% title-safe；提供 0–10% safe-area slider。
- UI scale 独立于世界 Camera2D zoom。

### Textures

- 非像素平滑手绘：Texture Filter 使用 Linear；缩小幅度较大时使用 Linear Mipmap。
- UI icon 和角色图使用 lossless compression；禁止对透明边缘使用明显有损压缩。
- `fix_alpha_border = true`，`premult_alpha = false`，普通颜色贴图使用 sRGB。
- 角色/法宝透明边距裁切到安全范围；图源不得依赖 0.03125、0.085 等任意缩放来“碰巧得到”目标尺寸。
- Atlas 图集每格保留 2–4 px padding，避免 Linear 采样串色。
- 导入 preset 需要分为：`sprite_smooth`, `ui_icon`, `background_tile`, `vfx_mask`。

### UI Architecture

- 颜色、字号、间距、StyleBox 进入共享 Theme/resource；禁止继续散落在各脚本的 `_apply_styles()` 中。
- 使用 Anchor、Container、size flags 与 safe-area 容器；避免大固定 minimum size 造成低分辨率溢出。
- 所有交互 Control 保持 `FOCUS_ALL` 或显式可达；Grid 使用 explicit focus neighbors。
- 打开 Modal 时保存原焦点、限制焦点于 Modal、关闭后恢复。
- Tooltip、通知、Modal 使用固定 z layer token，不进行 z-index 竞赛。
- 输入提示从 InputMap action 动态解析，不写死 A/B/Space 等文本。
- 所有 UI 文本使用本地化 key；中文是首发语言，不是硬编码结构。

### Performance

- 普通 VFX、伤害数字、射弹和常见召唤反馈使用对象池。
- 30/50/80 敌人设置三档 VFX density；同屏数量上升时先减少碎片、尾迹和普通伤害数字，不删危险预警。
- 避免每个敌人独立 CanvasLayer、Viewport 或高成本 Shader。
- Line2D 圆环段数按显示半径分档 20/32/48，不默认所有圆都用 56+ 点。

## Asset Naming Rules

所有文件使用小写英文 `snake_case`；ID 与 `ArtifactData.id` 保持一致。

### Folder Proposal

```text
art/
  characters/
    player/
    enemies/{enemy_id}/
    summons/{summon_id}/
  artifacts/{artifact_id}/
    source/
    ui/
    world/
    vfx/
  backgrounds/{biome_id}/
    tiles/
    props/
    decals/
  ui/
    theme/
    panels/
    icons/
      systems/
      attributes/
      attack_types/
      actions/
      input/
    cursors/
  vfx/
    shared/
    attributes/{attribute_id}/
fonts/
themes/
ui/components/
```

### File Pattern

```text
chr_player_idle.png
chr_player_move.png
enm_basic_paper_cultivator_move.png
sum_ghost_idle.png
art_long_spear_core.png
art_long_spear_icon.png
art_long_spear_world.png
vfx_long_spear_anticipation.png
vfx_long_spear_impact.png
ico_attr_fire.png
ico_system_sword.png
ico_attack_melee.png
ui_card_artifact_9slice.png
ui_panel_tooltip_9slice.png
bg_trial_courtyard_ground_01.png
prop_trial_talisman_post_01.png
```

后缀：`_idle`, `_move`, `_hurt`, `_defeat`, `_core`, `_icon`, `_world`, `_anticipation`, `_impact`, `_mask`, `_9slice`, `_01`。

禁止使用：`final`, `new`, `copy`, `v2_final`, 中文文件名、空格、未经说明的数字后缀。

## 推荐尺寸

除 Sprite 表中的尺寸外，UI 以 1280×720 逻辑 viewport 为基线：

- Safe margin：64 px 横向、36 px 纵向（5%）。
- Top HUD 高：64–88。
- Bottom artifact bar 高：84–104。
- Artifact slot：72×72，交互区最少 72×72。
- Shop artifact card：176–216 宽、232–288 高；720p 建议 4 张主卡或可滚动 5 张。
- Shop side synergy panel：280–340 宽，可折叠。
- Tooltip：400×auto，最大高 468。
- Primary button：最小 160×52。
- Secondary button：最小 112×48。
- Modal：最大 90% safe width、85% safe height。

## 禁止事项 / Common Mistakes

1. 不得给所有面板加金边、发光、云纹和卷轴角。
2. 不得用颜色作为品阶、属性、敌我、激活状态的唯一编码。
3. 不得让 UI icon 与 world sprite 使用不同主轮廓。
4. 不得把法宝 icon 画成复杂插画或人物持宝场景。
5. 不得在战斗 HUD 常驻显示全部羁绊说明、天命全文和奇遇全文。
6. 不得使用小于 14 px 的文字或小于 48×48 的交互热区。
7. 不得把交互按钮设为 `FOCUS_NONE` 以规避焦点样式问题。
8. 不得把 HUD 放在屏幕 0–3% 边缘；必须经过 safe-area 容器。
9. 不得让镜头震动、hit stop 或世界 modulate 影响 CanvasLayer UI。
10. 不得在动态背景上显示无描边、无阴影、无底板的细字。
11. 不得让玩家火属性与敌方危险只靠相同红橙色区分。
12. 不得在每次命中同时生成大量粒子、数字、闪光、震屏和长 hit stop。
13. 不得在 30+ 敌人时为每个普通敌人常驻血条、状态全文和高亮描边。
14. 不得使用八方向逐帧动画作为 Vertical Slice 的必要条件。
15. 不得用重 Shader 解决本可由轮廓、颜色和 Line2D 解决的问题。
16. 不得把高分辨率 AI 图源任意缩放到世界尺寸而不统一线宽、视角与采样。
17. 不得在脚本中继续新增孤立颜色、圆角、间距 magic number；先添加 Theme token。
18. 不得硬编码输入设备按键提示；必须解析当前绑定与设备 glyph。
19. 不得让 Tooltip 瞬时闪现或覆盖被比较卡片的价格/关键标签。
20. 不得先批量制作剩余资产；Vertical Slice 必须先通过真实混战和商店测试。

## Vertical Slice Definition of Done

- 玩家、3 个敌人、6 件法宝、1 个战斗场景在灰阶与色盲模拟下仍可辨认。
- 6 件法宝的 icon/world silhouette 盲测识别率目标 ≥ 90%。
- 30 个普通敌人 + 3 个远程/冲锋威胁 + 6 件法宝同时运行时，玩家能识别自身和最近危险。
- 商店 3 秒测试能读出法宝、体系、属性、构筑影响、价格和可购买状态。
- 鼠标、键盘、手柄均能完成核心商店流程，无焦点死路。
- 1280×720、1920×1080、4K、21:9 不裁切关键 UI；文本无重叠。
- Reduce Motion、UI scale、safe area、伤害数字密度选项可工作。
- 运行时 Theme 不依赖每个页面各自复制颜色与 StyleBox。
- 视觉评审通过后，才允许批量扩展其余法宝、敌人和页面。

