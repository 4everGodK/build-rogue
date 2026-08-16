# Vertical Slice Asset Production Specifications

本目录只覆盖已确认的 Vertical Slice：1 个玩家、3 个敌人、6 件法宝。所有文件从根目录 `ART_BIBLE.md` 派生；发生冲突时以 Art Bible 为准。

生产顺序：

1. 纯黑 core silhouette。
2. 24×24、40×40、64×64 灰阶测试。
3. 确认主轮廓、负形和朝向。
4. 由同一 silhouette 派生 world sprite、UI icon（若需要）和 VFX。
5. 完成 Godot 导入和真实同屏测试。

禁止在 silhouette 未确认前直接制作精修卡面或动画。

文件：

- `player_cloud_wanderer.md`
- `enemy_basic_paper_cultivator.md`
- `enemy_ranged_talisman_crossbow.md`
- `enemy_charger_red_horn.md`
- `artifact_long_spear.md`
- `artifact_giant_sword_art.md`
- `artifact_guardian_flying_sword.md`
- `artifact_divine_thunder.md`
- `artifact_ghost.md`
- `artifact_brush.md`

