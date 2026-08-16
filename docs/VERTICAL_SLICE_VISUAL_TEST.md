# Vertical Slice Visual Test

> Design source of truth: [`ART_BIBLE.md`](../ART_BIBLE.md) and [`VISUAL_DESIGN_AUDIT.md`](VISUAL_DESIGN_AUDIT.md)  
> Test date: 2026-08-16  
> Runtime: official Godot 4.6.3, Windows x86_64

## Scope and status

This document records the UI Foundation runtime checks and the placeholder-art crowd slice. It does **not** claim final visual approval for the player, enemies, artifacts, or VFX: their production specifications are ready, but the formal sprites have not been produced or connected yet.

| Area | Status | Evidence |
|---|---|---|
| Logical viewport and stretch | Pass | 1280×720, `canvas_items`, aspect `keep` loaded by Godot |
| Safe area | Pass | HUD and shop remain inside the central 16:9 frame with 5% margins |
| Shared Theme/tokens | Pass | `cloud_paper_theme.tres` loads; modified UI scenes inherit it |
| Shield HUD | Pass | visibility, current value, maximum value tested at runtime |
| Battle synergy limit | Pass | relevance selector never returns more than four entries |
| Tooltip timing | Pass | battle artifact focus tooltip appears after 300 ms |
| Shop controller flow | Pass | buy, select inventory item, sell, and continue work through focus/confirm |
| Focus graph | Pass | every enabled shop control is reachable from the first offer; no focus dead-end |
| 30/50/80 enemies | Pass for runtime stability | real Basic/Ranged/Charger scenes ran for 90 physics frames per case |
| Final art readability | Pending | requires formal Vertical Slice sprites and VFX |
| Icon ↔ world-sprite recognition | Pending | shared core silhouettes are specified, assets are not yet produced |

## Resolution matrix

The automated test changes the physical window size while preserving the 1280×720 logical canvas. `keep` aspect centers the 16:9 game frame; the safe-area component then applies 5% logical margins. This is the intended behavior for ultrawide instead of stretching the HUD into the side gutters.

| Physical window | Layout result | Shop focus flow | HUD center clearance |
|---|---|---|---|
| 1280×720 | Pass; compact 720p shop tier enabled | Pass | Pass |
| 1920×1080 | Pass | Pass | Pass |
| 2560×1440 | Pass | Pass | Pass |
| 3440×1440 | Pass; centered 16:9 frame with side gutters | Pass | Pass |

The first 1280×720 run exposed a real minimum-size overflow: the shop expanded to 1352×775. The fix introduced a compact 720p hierarchy, reduced decorative panel padding, recalculated widths from safe content width, kept interaction targets at least 48 px, and hides only the low-priority short description. Artifact name, system, attribute, synergy impact, and price remain visible.

## Crowd matrix

Each case uses the actual `EnemyBasic`, `EnemyRanged`, and `EnemyCharger` scenes in an even mix around the real player, with the new HUD active.

| Enemy count | Runtime result | Recorded observation |
|---:|---|---|
| 30 | Pass | Node count stable; no script/runtime error |
| 50 | Pass | Node count stable; no script/runtime error |
| 80 | Pass | Node count stable; no script/runtime error |

Each case completed 90 physics frames at the configured 60 Hz tick. This proves scene/UI stability, not GPU performance: headless fixed-tick timings are not a valid render benchmark.

## Readability observations

### Player location

- Pass for layout: none of the four HUD groups covers the logical screen center where the camera tracks the player.
- Pending for final silhouette: the “云游小修士” sprite has not yet replaced the placeholder, so cyan identity accents and formal silhouette recognition still need an in-game visual review.

### Enemy danger recognition

- Basic, Ranged, and Charger behavior scenes all coexist correctly at 80 enemies.
- Pending for final visual recognition: the production specs reserve distinct body shapes, stance cues, and danger accents, but current placeholders cannot validate the final threat-readability target.

### Artifact and VFX noise

- The HUD reserves a bounded bottom-center artifact strip and no longer competes with the player center.
- Pending: the six formal artifact sprites and their restrained VFX have not been connected, so peak-combat color/noise must be retested after asset production.

### Icon ↔ world correspondence

- Pipeline pass: every sample artifact specification starts from one core silhouette and derives UI Icon, World Sprite, and VFX from it.
- Recognition test pending until those derived assets exist in-game.

### Shop purchase judgment

- Each offer exposes name, stars, system/attribute, build consequence, price, and affordability in the primary scan path.
- 720p keeps this decision layer and removes only description copy from the card; full detail remains in the delayed tooltip.
- Keyboard/controller flow emits the correct buy, inventory selection, sell, and continue actions in automated runtime tests.
- A timed human scan test is still recommended after final icons are connected.

### Focus navigation

- No enabled shop control uses `FOCUS_NONE`.
- A runtime graph traversal from the first offer reaches top actions, locks, offers, battle slots, bag slots, sell, and continue.
- `ui_cancel` cancels an armed inventory move instead of trapping focus or unexpectedly closing the shop.

## Automated test scenes

- `tests/UIFoundationTest.tscn`: viewport settings, safe area, Theme, shield, synergy limit, target resolutions, focus reachability, and controller flow.
- `tests/BattleArtifactTooltipTest.tscn`: 300 ms focus tooltip and tooltip content.
- `tests/VerticalSliceCrowdTest.tscn`: 30/50/80 real enemy runtime stability and HUD center clearance.

All existing project regression scenes also passed under Godot 4.6.3. The pre-existing ObjectDB leak warnings in several test teardown paths remain warnings; no test failed because of them.

## Gate before bulk production

Do not expand the remaining 27 artifacts yet. The next approval gate is:

1. Produce and import only the player, three enemies, and six artifacts defined in `docs/art_prompts/`.
2. Connect them through reversible resource overrides or a Vertical Slice asset profile.
3. Repeat this matrix with rendered gameplay and capture stills/video at 1280×720 and 3440×1440.
4. Run a human recognition test for player location, threat class, and Icon ↔ World Sprite matching.
5. Tune VFX opacity/occupancy before approving bulk production.
