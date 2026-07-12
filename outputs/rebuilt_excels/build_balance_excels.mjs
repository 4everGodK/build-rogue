import fs from "node:fs/promises";
import path from "node:path";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const ROOT = path.resolve("../..");
const OUT_DIR = path.resolve(".");

const SYSTEM_TAGS = ["剑修", "法修", "体修", "召唤", "魔修"];
const ATTRIBUTE_TAGS = ["金", "木", "水", "火", "土", "雷", "毒"];
const TIER_ORDER = ["凡器", "法器", "灵器", "灵宝", "仙宝"];
const DEFAULTS = {
  secondary_attribute_tag: "",
  damage: 10,
  max_hp_damage_coefficient: 0,
  cooldown: 1,
  range: 320,
  radius: 32,
  width: 20,
  length: 80,
  projectile_speed: 420,
  projectile_pierce: 0,
  projectile_bounce: 0,
  bounce_count: 0,
  bounce_range: 150,
  duration: 0.16,
  tick_interval: 0.5,
  count: 1,
  max_targets: 0,
  life_cost_percent: 0,
  life_cost_flat: 0,
  life_cost_min_hp_ratio: 0,
  kill_heal_amount: 0,
  rotation_speed: 3,
  hit_interval: 0.4,
  explosion_radius: 0,
  debuff_duration: 0,
  damage_reduction_percent: 0,
  slow_percent: 0,
  attack_speed_bonus: 0,
  poison_dps: 0,
  poison_duration: 0,
  poison_can_stack: true,
  knockback_force: "",
  counter_range: 0,
  counter_speed: 620,
  heal_amount: 0,
  shield_amount: 0,
  shield_max: 0,
  delayed_strike_count: 3,
  delayed_strike_delay: 0.3,
  delayed_strike_interval: 0.15,
  price: 6,
  cost: 0,
  cultivation_requirement: "",
  shop_weight: 1,
  summon_base_count: 0,
  summon_hp: 0,
  summon_attack: 0,
  summon_attack_speed: 1,
  summon_move_speed: 0,
  summon_combat_radius: 0,
  summon_return_radius: 0,
  summon_respawn_time: 0,
  summon_behavior_type: "",
  summon_special_effect: "",
  summon_death_burst: false,
  star2_damage_mult: 0,
  star2_cooldown_mult: 0,
  star3_damage_mult: 0,
  star3_cooldown_mult: 0,
  crit_chance: 0,
  crit_damage_mult: 2,
  extra_melee_wave_damage_mult: 0,
  extra_melee_wave_range: 90,
  extra_melee_wave_width: 22,
  projectile_return_count: 0,
  poison_explosion_radius: 0,
  poison_explosion_damage_mult: 0,
  shield_knockback_force: 0,
  movement_speed_bonus: 0,
  melee_arc_multiplier: 1,
  windup_time: 0,
  trail_length: 0,
  hit_flash_duration: 0.12,
  secondary_damage_mult: 0,
  secondary_radius: 0,
  secondary_delay: 0,
  side_projectile_damage_mult: 0.5,
  return_speed: 0,
  fan_angle: 0,
  converge_speed: 0,
  self_rotation_speed: 0,
  reveal_time: 0,
  pause_time: 0,
  sweep_rotation_speed: 0,
  hit_feedback_profile: "",
  hit_stop_seconds: "",
  screen_shake_strength: "",
  screen_shake_duration: "",
  hit_effect_scale: "",
  hit_sound_id: "",
  damage_number_style: "",
};

function rel(file) {
  return path.join(ROOT, file);
}

async function read(file) {
  return fs.readFile(rel(file), "utf8");
}

function extractLiteral(text, name) {
  const at = text.indexOf(`const ${name}`);
  if (at < 0) throw new Error(`Missing const ${name}`);
  const eq = text.indexOf("=", at);
  const start = text.searchFrom ? -1 : findFirstOf(text, eq, ["[", "{"]);
  if (start < 0) throw new Error(`Missing literal start for ${name}`);
  const open = text[start];
  const close = open === "[" ? "]" : "}";
  let depth = 0;
  let inString = false;
  let escape = false;
  for (let i = start; i < text.length; i++) {
    const ch = text[i];
    if (inString) {
      if (escape) escape = false;
      else if (ch === "\\") escape = true;
      else if (ch === "\"") inString = false;
      continue;
    }
    if (ch === "\"") {
      inString = true;
      continue;
    }
    if (ch === open) depth++;
    if (ch === close) depth--;
    if (depth === 0) return text.slice(start, i + 1);
  }
  throw new Error(`Unclosed literal for ${name}`);
}

function findFirstOf(text, start, chars) {
  let inString = false;
  let escape = false;
  for (let i = start; i < text.length; i++) {
    const ch = text[i];
    if (inString) {
      if (escape) escape = false;
      else if (ch === "\\") escape = true;
      else if (ch === "\"") inString = false;
      continue;
    }
    if (ch === "\"") inString = true;
    else if (chars.includes(ch)) return i;
  }
  return -1;
}

function evalGdLiteral(lit) {
  return Function(`"use strict"; return (${lit});`)();
}

function extractNumber(text, name) {
  const m = text.match(new RegExp(`const\\s+${name}[^=]*=\\s*([-0-9.]+)`));
  return m ? Number(m[1]) : null;
}

function parseTresValue(raw) {
  const value = raw.trim();
  if (value.startsWith("\"") && value.endsWith("\"")) {
    return value.slice(1, -1).replace(/\\"/g, "\"");
  }
  if (value === "true") return true;
  if (value === "false") return false;
  if (/^-?\d+(\.\d+)?$/.test(value)) return Number(value);
  return value;
}

async function parseArtifact(file) {
  const text = await fs.readFile(file, "utf8");
  const item = { ...DEFAULTS, source_file: path.relative(ROOT, file).replaceAll("\\", "/") };
  for (const line of text.split(/\r?\n/)) {
    const m = line.match(/^([A-Za-z0-9_]+)\s*=\s*(.+)$/);
    if (!m) continue;
    const key = m[1];
    if (key === "script" || key === "icon") continue;
    item[key] = parseTresValue(m[2]);
  }
  item.cost = tierCost(item.tier);
  item.price = item.cost;
  return item;
}

function tierCost(tier) {
  return ({ "凡器": 10, "法器": 20, "灵器": 30, "灵宝": 40, "仙宝": 50 })[tier] ?? 10;
}

function starDamageMult(a, star) {
  if (star === 2) return a.star2_damage_mult > 0 ? a.star2_damage_mult : 1.55;
  if (star === 3) return a.star3_damage_mult > 0 ? a.star3_damage_mult : 2.25;
  return 1;
}

function starCooldownMult(a, star) {
  if (star === 2) return a.star2_cooldown_mult > 0 ? a.star2_cooldown_mult : 0.85;
  if (star === 3) return a.star3_cooldown_mult > 0 ? a.star3_cooldown_mult : 0.7;
  return 1;
}

function summonPreview(a, star) {
  const p = { count: Math.max(1, Number(a.summon_base_count || 0)), hp: Number(a.summon_hp || 0), attack: Number(a.summon_attack || 0), attackSpeed: Number(a.summon_attack_speed || 1) };
  if (star < 2) return p;
  switch (a.id) {
    case "sword_puppet":
      p.hp *= 1.5; p.attack *= 1.5; break;
    case "crossbow_puppet":
      p.attack *= 1.5; p.attackSpeed *= 1.3; break;
    case "iron_guard_puppet":
      p.hp *= 1.8; p.attack *= 1.5; break;
    case "turret":
      p.attack *= 1.5; break;
    case "ghost":
      p.attack *= 1.5; break;
    case "poison_bug":
      p.count += 1; p.attack *= 1.5; break;
  }
  if (star < 3) return p;
  if (["sword_puppet", "iron_guard_puppet", "turret", "ghost"].includes(a.id)) p.attack *= 2.0;
  if (["crossbow_puppet", "poison_bug"].includes(a.id)) p.attack *= 1.55;
  if (a.id === "poison_bug") p.count += 2;
  return p;
}

function pct(n) {
  return typeof n === "number" ? n : Number(n || 0);
}

function flattenEffect(obj) {
  const entries = Object.entries(obj).filter(([k]) => !["id", "name", "category", "description"].includes(k));
  return entries.map(([k, v]) => `${k}=${v}`).join("; ");
}

async function collectData() {
  const artifactDir = rel("data/artifacts");
  const artifactFiles = (await fs.readdir(artifactDir)).filter((f) => f.endsWith(".tres")).sort();
  const artifacts = [];
  for (const f of artifactFiles) artifacts.push(await parseArtifact(path.join(artifactDir, f)));

  const cultivationText = await read("scripts/cultivation_manager.gd");
  const gameText = await read("scripts/game_manager.gd");
  const shopText = await read("scripts/shop_manager.gd");
  const waveText = await read("scripts/wave_manager.gd");
  const enemyBalanceText = await read("scripts/enemy_balance_config.gd");
  const synergyText = await read("scripts/synergy_manager.gd");
  const destinyText = await read("scripts/destiny_manager.gd");
  const encounterText = await read("scripts/encounter_manager.gd");

  return {
    artifacts,
    destinies: evalGdLiteral(extractLiteral(destinyText, "DESTINIES")),
    encounters: evalGdLiteral(extractLiteral(encounterText, "ENCOUNTERS")),
    tierCosts: evalGdLiteral(extractLiteral(cultivationText, "TIER_COSTS")),
    shopTierWeights: evalGdLiteral(extractLiteral(cultivationText, "SHOP_TIER_WEIGHTS")),
    breakthroughRequirements: evalGdLiteral(extractLiteral(cultivationText, "BREAKTHROUGH_REQUIREMENTS")),
    realms: evalGdLiteral(extractLiteral(cultivationText, "REALMS")),
    tierNames: evalGdLiteral(extractLiteral(cultivationText, "TIER_NAMES")),
    roomRewards: evalGdLiteral(extractLiteral(gameText, "ROOM_CLEAR_SPIRIT_STONES_BY_RANGE")),
    bossWaves: evalGdLiteral(extractLiteral(waveText, "BOSS_WAVES")),
    enemies: evalGdLiteral(extractLiteral(enemyBalanceText, "ENEMIES")),
    elite: evalGdLiteral(extractLiteral(enemyBalanceText, "ELITE")),
    cultivationClickCost: extractNumber(cultivationText, "CULTIVATION_CLICK_COST"),
    cultivationGainPerClick: extractNumber(cultivationText, "CULTIVATION_GAIN_PER_CLICK"),
    baseBattleSlots: extractNumber(cultivationText, "BASE_BATTLE_SLOT_COUNT"),
    rerollBaseCost: extractNumber(shopText, "REROLL_COST"),
    rerollGrowth: extractNumber(shopText, "REROLL_COST_GROWTH"),
    offerCount: extractNumber(shopText, "OFFER_COUNT"),
    startingStones: Number((gameText.match(/starting_spirit_stones:\s*int\s*=\s*(\d+)/) || [])[1] || 0),
    roomCultivation: extractNumber(gameText, "ROOM_CLEAR_CULTIVATION"),
    spiritGatherCost: extractNumber(gameText, "SPIRIT_GATHERING_COST"),
    spiritGatherReturn: extractNumber(gameText, "SPIRIT_GATHERING_RETURN"),
    spiritGatherMax: extractNumber(gameText, "SPIRIT_GATHERING_MAX_LAYERS"),
    enemyDropMultiplier: extractNumber(gameText, "ENEMY_SPIRIT_STONE_DROP_MULTIPLIER"),
    roomDurations: {
      wave1: extractNumber(gameText, "WAVE_1_ROOM_DURATION"),
      wave2: extractNumber(gameText, "WAVE_2_ROOM_DURATION"),
      wave3: extractNumber(gameText, "WAVE_3_ROOM_DURATION"),
      late: extractNumber(gameText, "LATE_ROOM_DURATION"),
    },
    waveScaling: {
      normalHpGrowth: extractNumber(waveText, "NORMAL_HP_GROWTH_PER_WAVE"),
      bossHpGrowth: extractNumber(waveText, "BOSS_HP_GROWTH_PER_WAVE"),
      globalEnemyHpMultiplier: extractNumber(waveText, "GLOBAL_ENEMY_HP_MULTIPLIER"),
      hpPowerStart: extractNumber(waveText, "HP_POWER_GROWTH_START_WAVE"),
      hpPowerGrowth: extractNumber(waveText, "HP_POWER_GROWTH_PER_WAVE"),
      hpPowerExponent: extractNumber(waveText, "HP_POWER_GROWTH_EXPONENT"),
      spawnCountGrowth: extractNumber(waveText, "SPAWN_COUNT_GROWTH_PER_WAVE"),
      spawnIntervals: evalGdLiteral(extractLiteral(waveText, "SURVIVAL_SPAWN_INTERVALS")),
      packSizes: evalGdLiteral(extractLiteral(waveText, "SURVIVAL_PACK_SIZES")),
    },
    synergies: buildSynergies(synergyText),
  };
}

function buildSynergies(text) {
  const rows = [];
  const named = [
    ["剑修", "流派", "SWORD_ATTACK_SPEED_TIERS", "命中后叠加攻速，每层降低冷却，离场/重置战斗清空层数。"],
    ["体修", "流派", "BODY_GROWTH_TIERS", "提高玩家最大生命和体型，并按体型倍率放大体修法宝范围。"],
    ["金", "属性", "METAL_LOW_HP_TIERS", "命中低血敌人时追加一次基于本次基础伤害的伤害。"],
    ["木", "属性", "WOOD_ROOT_TIERS", "命中触发缠绕；高层额外提高目标受到伤害。"],
    ["水", "属性", "WATER_HEAL_TIERS", "命中治疗玩家；6件时满血溢出为护盾。"],
    ["火", "属性", "FIRE_EXPLOSION_TIERS", "命中产生范围爆炸伤害。"],
    ["土", "属性", "EARTH_SHOCKWAVE_TIERS", "命中产生震波伤害；6件中心目标眩晕。"],
    ["雷", "属性", "LIGHTNING_CHAIN_TIERS", "命中触发连锁闪电，后续目标按衰减倍率递减。"],
    ["毒", "属性", "POISON_TIERS", "命中施加中毒；6件时中毒爆发。"],
  ];
  for (const [tag, type, constName, desc] of named) {
    const tiers = evalGdLiteral(extractLiteral(text, constName));
    for (const t of tiers) rows.push({ tag, type, required: t.required, description: desc, effects: flattenEffect(t) });
  }
  rows.push({ tag: "法修", type: "流派", required: 2, description: "法修 projectile 法宝额外发射物。", effects: "projectile_extra_count=1; projectile_extra_damage_multiplier=0.5" });
  rows.push({ tag: "法修", type: "流派", required: 4, description: "法修 projectile 法宝额外发射物。", effects: "projectile_extra_count=1; projectile_extra_damage_multiplier=0.75" });
  rows.push({ tag: "法修", type: "流派", required: 6, description: "法修 projectile 法宝额外发射物。", effects: "projectile_extra_count=2; projectile_extra_damage_multiplier=0.75" });
  rows.push({ tag: "召唤", type: "流派", required: 2, description: "召唤物数量提高。", effects: "summon_extra_count=1; respawn_time_multiplier=1.0; death_burst=false" });
  rows.push({ tag: "召唤", type: "流派", required: 4, description: "召唤物数量提高并缩短重生。", effects: "summon_extra_count=2; respawn_time_multiplier=0.5; death_burst=false" });
  rows.push({ tag: "召唤", type: "流派", required: 6, description: "召唤物数量提高、缩短重生并启用死亡灵力冲击。", effects: "summon_extra_count=4; respawn_time_multiplier=0.5; death_burst=true" });
  rows.push({ tag: "魔修", type: "流派", required: 2, description: "低血时魔修法宝额外增伤。", effects: "hp_ratio<50%; demon_low_hp_magic_damage_multiplier=1.3" });
  rows.push({ tag: "魔修", type: "流派", required: 4, description: "低血时所有法宝额外增伤，魔修法宝再吃2件效果。", effects: "hp_ratio<50%; demon_low_hp_all_damage_multiplier=1.2; magic=1.3" });
  return rows.sort((a, b) => (a.type + a.tag).localeCompare(b.type + b.tag, "zh-Hans") || a.required - b.required);
}

function addSheet(workbook, name, rows, opts = {}) {
  const sheet = workbook.worksheets.add(name);
  sheet.showGridLines = false;
  if (!rows.length) return sheet;
  const headers = Object.keys(rows[0]);
  const matrix = [headers, ...rows.map((r) => headers.map((h) => r[h] ?? ""))];
  sheet.getRangeByIndexes(0, 0, matrix.length, headers.length).values = matrix;
  styleTable(sheet, matrix.length, headers, opts);
  return sheet;
}

function styleTable(sheet, rowCount, headers, opts = {}) {
  const colCount = headers.length;
  const all = sheet.getRangeByIndexes(0, 0, rowCount, colCount);
  all.format.font = { name: "Microsoft YaHei", size: 10, color: "#172033" };
  all.format.wrapText = true;
  const header = sheet.getRangeByIndexes(0, 0, 1, colCount);
  header.format.fill = opts.headerFill || "#245366";
  header.format.font = { name: "Microsoft YaHei", bold: true, color: "#FFFFFF", size: 10 };
  header.format.rowHeightPx = 28;
  all.format.borders = { preset: "inside", style: "thin", color: "#D8DEE8" };
  sheet.getRangeByIndexes(0, 0, rowCount, colCount).format.autofitColumns();
  sheet.getRangeByIndexes(0, 0, rowCount, colCount).format.autofitRows();
  const hasLongText = headers.some((h) => ["描述", "公式或规则", "规则", "备注", "效果键值", "含义", "说明"].includes(h));
  if (hasLongText && rowCount > 1) {
    sheet.getRangeByIndexes(1, 0, rowCount - 1, colCount).format.rowHeightPx = 46;
  }
  for (let c = 0; c < colCount; c++) {
    const header = headers[c];
    let width = opts.widths?.[c] || 115;
    if (["描述", "公式或规则", "规则", "备注", "效果键值", "含义", "说明"].includes(header)) width = 360;
    if (["来源", "source_file", "来源文件"].includes(header)) width = 190;
    if (["id", "字段", "名称", "分类", "模块", "系统", "项目", "环节"].includes(header)) width = 130;
    if (["顺序", "关卡", "星级", "价格", "数值", "伤害", "冷却秒", "DPS估算"].includes(header)) width = 80;
    sheet.getRangeByIndexes(0, c, rowCount, 1).format.columnWidthPx = Math.min(Math.max(75, width), 460);
  }
  sheet.freezePanes.freezeRows(1);
}

function makeOverview(workbook, data, title, notes) {
  const sheet = workbook.worksheets.add("说明");
  sheet.showGridLines = false;
  sheet.getRange("A1:F1").merge();
  sheet.getRange("A1").values = [[title]];
  sheet.getRange("A1").format = { fill: "#1F4E5F", font: { name: "Microsoft YaHei", size: 16, bold: true, color: "#FFFFFF" } };
  const rows = [
    ["生成时间", new Date().toISOString()],
    ["项目路径", ROOT],
    ["法宝数量", data.artifacts.length],
    ["天命数量", data.destinies.length],
    ["奇遇数量", data.encounters.length],
    ["说明", notes],
  ];
  sheet.getRangeByIndexes(2, 0, rows.length, 2).values = rows;
  sheet.getRange("A3:A8").format = { fill: "#E8F1F4", font: { bold: true, color: "#1F4E5F" } };
  sheet.getRange("B3:B8").format.wrapText = true;
  sheet.getRange("A:A").format.columnWidthPx = 120;
  sheet.getRange("B:B").format.columnWidthPx = 560;
  return sheet;
}

function swordDesignNote(a, kind) {
  const notes = {
    fist: {
      performance: "角色前方快速凝出左右交替拳影，短距离冲出命中最近敌人，命中有短促冲击闪光。",
      star3: "每delayed_strike_count次攻击触发三连拳，第三拳更大并按secondary_radius产生小范围冲击波。",
      role: "1费快速近身单体输出，高频稳定打最近目标。",
      fields: "count, delayed_strike_count, delayed_strike_interval, secondary_damage_mult, secondary_radius, side_projectile_damage_mult",
    },
    palm: {
      performance: "半透明大掌印短暂凝聚后向前推进，视觉扇形和伤害/击退判定保持一致。",
      star3: "主掌后按secondary_delay追加较淡余劲掌风，按secondary_damage_mult造成低伤并轻击退。",
      role: "1费前方扇形控场，伤害中等，主打击退正面敌群。",
      fields: "windup_time, length, width, knockback_force, secondary_delay, secondary_damage_mult, side_projectile_damage_mult",
    },
    kick: {
      performance: "角色周围生成旋转腿罡横扫一圈，环形半径随体修范围加成同步放大。",
      star3: "第一圈后按secondary_delay反向再扫一圈，第二圈按secondary_damage_mult并用secondary_radius扩大范围。",
      role: "2费贴身环形解围，高伤并轻微击退周围敌人。",
      fields: "radius, knockback_force, secondary_damage_mult, secondary_radius, secondary_delay, sweep_rotation_speed",
    },
    roar: {
      performance: "短蓄气后向目标方向释放多层锥形声浪，扫过敌人时造成伤害并刷新减速。",
      star3: "主声浪后在角色周围追加环形余吼，范围=secondary_radius，伤害按secondary_damage_mult。",
      role: "2费中距离锥形控制，偏减速和阻止敌群接近。",
      fields: "windup_time, length, width, fan_angle, slow_percent, debuff_duration, secondary_radius, secondary_damage_mult",
    },
    body_barrier: {
      oldName: "罩",
      performance: "角色周围形成气血护罩，先收缩再爆发成厚重震荡波，命中敌人后气血流光回到角色。",
      star3: "第一次爆发后保留余罩，按secondary_delay触发第二次较低伤震荡和较低上限回血。",
      role: "3费周身周期爆发、近身防护与续航。",
      fields: "radius, duration, windup_time, tick_interval, knockback_force, heal_amount, shield_max, shield_amount, secondary_damage_mult, secondary_radius, secondary_delay",
    },
    thorn_armor: {
      oldName: "反甲",
      performance: "主动凝出半透明巨手，锁定前方/附近密集区域，牵引普通敌人到中心后握紧砸击。",
      star3: "第一只巨手后生成第二只手合击中心，按secondary_damage_mult和secondary_radius造成额外范围伤害。",
      role: "4费中距离聚怪与高额控制伤害核心；旧受伤反击机制已取消。",
      fields: "range, radius, max_targets, tick_interval, windup_time, knockback_force, secondary_damage_mult, secondary_radius, secondary_delay",
    },
    golden_body_avatar: {
      performance: "角色背后常驻低透明法相，攻击时增亮抬手，砸向敌人密集区域并生成冲击波和地裂。",
      star3: "法相变大，第一次砸地后按secondary_delay偏移位置进行第二次低伤大范围砸地。",
      role: "5费体修最终大范围高伤、高击退、低频视觉高潮。",
      fields: "range, radius, windup_time, tick_interval, knockback_force, secondary_damage_mult, secondary_radius, secondary_delay, screen_shake_strength",
    },
    one_handed_sword: {
      performance: "左右交替短剑光，命中生成短促十字闪光。",
      star3: "每第三击变为X形双斩，额外剑光按secondary_damage_mult造成伤害。",
      role: "1费基础剑修，正常范围、正常伤害、正常攻速。",
      fields: "trail_length, hit_flash_duration, secondary_damage_mult",
    },
    dagger: {
      performance: "极短距离锁定最近敌人，细闪光线+匕首残影穿刺，目标身后小AOE。",
      star3: "从相反方向追加第二次低伤害刺击，不重复大范围AOE。",
      role: "1费快速近身刺杀，近乎单体，背后极小范围溅射。",
      fields: "range, secondary_radius, secondary_damage_mult, secondary_delay",
    },
    two_handed_sword: {
      performance: "半透明大剑影短蓄力后重劈，落点保留主剑痕和环形冲击痕。",
      star3: "剑痕约0.5秒后亮起并二次爆裂。",
      role: "2费低攻速高单次伤害，带前摇和厚重感。",
      fields: "windup_time, secondary_delay, secondary_radius, secondary_damage_mult, screen_shake_strength",
    },
    flying_sword: {
      performance: "飞剑浮现、短蓄力后穿透飞出，到最大距离后返航，去返分别命中。",
      star3: "三把飞剑扇形出发，副剑按side_projectile_damage_mult造成伤害。",
      role: "2费御剑攻击，主动操控感，非普通直线子弹。",
      fields: "windup_time, return_speed, fan_angle, side_projectile_damage_mult, trail_length",
    },
    long_spear: {
      performance: "枪尖光点蓄力，长枪影快速伸长并延伸枪罡直线贯穿。",
      star3: "枪罡终点必定产生小范围冲击波。",
      role: "3费极长距离窄直线贯穿。",
      fields: "windup_time, length, secondary_radius, secondary_damage_mult, trail_length",
    },
    guardian_flying_sword: {
      performance: "3个小型剑轮均匀环绕角色，高速公转并按显式间隔切割。",
      star3: "剑轮数量增加到4个。",
      role: "4费中近距离持续切割，伤害不依赖帧率。",
      fields: "count, radius, rotation_speed, self_rotation_speed, hit_interval",
    },
    giant_sword_art: {
      performance: "脚下剑阵，选择敌人密集方向，巨剑分段显现后向前贯穿。",
      star3: "改为以角色为中心360度横扫一周。",
      role: "5费超大范围视觉高潮和清场输出。",
      fields: "reveal_time, pause_time, sweep_rotation_speed, trail_length",
    },
    fire_orb: {
      performance: "光点凝聚成法球，短暂停顿后飞行，命中后收缩并爆炸为圆形冲击波。",
      star3: "第一次爆炸后延迟触发更大、更淡、低伤的第二次爆炸。",
      role: "1费标准法修发射物，中速基础AOE。",
      fields: "windup_time, explosion_radius, secondary_delay, secondary_radius, secondary_damage_mult",
    },
    copper_coin: {
      performance: "铜钱旋转发射，命中后按目标搜索范围折线弹射并留下短暂金色轨迹。",
      star3: "最后一次弹射后分裂为多枚小铜钱，优先攻击不同目标。",
      role: "1费高频弹射，连续打击多个目标。",
      fields: "bounce_count, bounce_range, projectile_speed, count, secondary_damage_mult, secondary_radius",
    },
    magic_ring: {
      performance: "法环展开并蓄力，随后轰出短持续超长直线光束。",
      star3: "主光束路径留下光痕，延迟后整条路径二次爆发。",
      role: "2费短前摇、高爆发、贯穿光束。",
      fields: "windup_time, range, width, secondary_delay, secondary_radius, secondary_damage_mult",
    },
    brush: {
      performance: "毛笔飞向目标区域，三笔写出抽象符印，完整形成后统一爆发。",
      star3: "爆发后残留墨阵，按固定脉冲造成低伤并减速。",
      role: "3费延迟AOE、区域布置和控场。",
      fields: "radius, delayed_strike_interval, tick_interval, duration, secondary_damage_mult, slow_percent",
    },
    guqin: {
      performance: "古琴虚影拨弦，按顺序释放三层弧形音波并施加伤害降低。",
      star3: "第三层音波改为以角色为中心的环形音波。",
      role: "3费大范围多段音波辅助，偏生存和削弱。",
      fields: "range, fan_angle, delayed_strike_interval, damage_reduction_percent, debuff_duration",
    },
    fire_gourd: {
      performance: "火葫芦锁定密集方向，短前摇后按固定脉冲喷出多层锥形火浪。",
      star3: "喷火结束后吐出火种，爆炸并留下固定脉冲燃烧区域。",
      role: "4费中近距离持续锥形清群，多段伤害和灼烧。",
      fields: "windup_time, duration, tick_interval, fan_angle, poison_dps, explosion_radius, delayed_strike_interval",
    },
    divine_thunder: {
      performance: "稳定选择敌人密集区域，预警圈后主雷落下，并连锁附近目标。",
      star3: "主雷后生成雷劫区域，按间隔落下多道副雷。",
      role: "5费远程天降爆发，大范围高伤和连锁清场。",
      fields: "windup_time, radius, count, bounce_range, delayed_strike_count, delayed_strike_interval, secondary_radius",
    },
    blood_sword: {
      performance: "抽出血色流光凝成短血剑，近距离厚重血色剑光挥砍，命中留下短血痕，结束后崩成血雾。",
      star3: "命中的敌人留下血痕，按secondary_delay延迟爆裂，按secondary_damage_mult造成小范围低伤。",
      role: "1费近战高伤害，消耗生命换输出，击杀按kill_heal_amount回血。",
      fields: "life_cost_flat, life_cost_min_hp_ratio, kill_heal_amount, windup_time, secondary_damage_mult, secondary_radius, secondary_delay",
    },
    blood_slash: {
      performance: "血流压缩成宽大弯月血刃，蓄力后直线飞出，沿途穿透并留下残月血色轨迹。",
      star3: "到达最大距离后按pause_time停顿，再以return_speed返回；去程和回程分别维护命中记录。",
      role: "2费宽直线清线，消耗生命，击杀回血。",
      fields: "life_cost_flat, life_cost_min_hp_ratio, kill_heal_amount, windup_time, return_speed, pause_time, secondary_damage_mult",
    },
    poison_needle: {
      performance: "身侧浮现数根细毒针，短暂停顿后以极短间隔连续射出，命中附加非无限叠加中毒标记。",
      star3: "每delayed_strike_count次普通攻击追加一轮扇形针雨，数量=bounce_count，伤害按secondary_damage_mult。",
      role: "2费高频低直伤，主要依靠中毒持续输出，不消耗生命。",
      fields: "count, delayed_strike_count, delayed_strike_interval, bounce_count, fan_angle, secondary_damage_mult, poison_can_stack",
    },
    heaven_eye: {
      performance: "天眼睁开并锁定目标，光束按tick_interval固定脉冲造成持续伤害，击杀后自动转火。",
      star3: "主光束外额外分出两条副光束，副光束优先锁定不同目标并按side_projectile_damage_mult造成伤害。",
      role: "3费持续单体压制，对精英和Boss稳定，持续耗血并击杀回血。",
      fields: "duration, tick_interval, range, life_cost_flat, life_cost_min_hp_ratio, kill_heal_amount, side_projectile_damage_mult",
    },
    scythe: {
      performance: "长柄镰刀后拉后大弧挥砍，仅外圈镰刃环带造成伤害，命中抽出生命丝线回血。",
      star3: "第一轮结束后按secondary_delay反向再挥一轮，第二轮伤害按secondary_damage_mult。",
      role: "4费中近距离外圈收割和续航，回血按实际伤害比例并受shield_max单轮上限限制。",
      fields: "fan_angle, length, width, heal_amount, shield_max, secondary_damage_mult, secondary_delay",
    },
    soul_banner: {
      performance: "招魂幡连接多名敌人，魂线按tick_interval固定脉冲压制和伤害；被本轮连接/伤害过的敌人死亡生成幽魂冲击。",
      star3: "连接数提升到count，幽魂体积和爆炸范围按secondary_radius放大；累计delayed_strike_count只幽魂释放魂波。",
      role: "5费多目标持续压制和拘魂清场，幽魂数量、寿命和搜索范围均有限制。",
      fields: "max_targets, count, summon_base_count, summon_respawn_time, summon_combat_radius, secondary_damage_mult, secondary_radius, delayed_strike_count, poison_explosion_damage_mult",
    },
    sword_puppet: {
      performance: "玩家身旁召唤阵显形，木质几何人形落地后追击近敌，近战挥砍产生短刀光和命中闪光。",
      star3: "普通挥砍后按secondary_delay独立冷却触发短距离跃斩，落点按explosion_radius造成范围伤害。",
      role: "1费基础前排近战输出，可被攻击，死亡后按summon_respawn_time重生。",
      fields: "summon_base_count, summon_hp, summon_attack, summon_attack_speed, summon_return_radius, secondary_damage_mult, secondary_radius, secondary_delay, explosion_radius",
      ai: "主动追击近敌；超过summon_return_radius优先返回玩家附近；轻量软分离。",
      aggro: "有仇恨，可被敌人主动选择。",
      vulnerable: "可受伤。",
      death: "死亡隐藏并禁用碰撞，显示重生印记，summon_respawn_time后在玩家附近满状态重生。",
    },
    crossbow_puppet: {
      performance: "侧后方召唤阵显形，保持secondary_radius理想距离，蓄能后发射带拖尾灵能箭；多单位有短蓄能窗口形成齐射感。",
      star3: "每delayed_strike_count次攻击蓄力齐射三支扇形箭，侧箭按side_projectile_damage_mult造成伤害。",
      role: "1费基础后排持续输出，可被攻击，死亡后重生。",
      fields: "summon_attack_speed, projectile_speed, secondary_radius, delayed_strike_delay, delayed_strike_count, fan_angle, side_projectile_damage_mult",
      ai: "保持secondary_radius理想距离；过近后退，过远靠近；超过活动范围返回。",
      aggro: "有仇恨，可被敌人主动选择。",
      vulnerable: "可受伤。",
      death: "死亡后按summon_respawn_time在玩家附近重生，清理旧目标和状态。",
    },
    iron_guard_puppet: {
      performance: "厚重召唤阵落地，移动到玩家与目标之间，慢速重击并周期性释放嘲讽波纹和敌人标记。",
      star3: "嘲讽时展开短时护盾领域，自身按secondary_damage_mult获得减伤，持续duration。",
      role: "2费核心坦克，可被攻击，高生命，死亡后重生。",
      fields: "summon_hp, radius, summon_return_radius, duration, secondary_damage_mult, secondary_delay, secondary_radius",
      ai: "优先站在玩家与目标之间；周期嘲讽radius内敌人；过远返回。",
      aggro: "有仇恨，且嘲讽期间强制附近敌人攻击它。",
      vulnerable: "可受伤，三星嘲讽期间自身减伤。",
      death: "死亡碎裂并显示重生印记，summon_respawn_time后重新部署到玩家附近。",
    },
    turret: {
      performance: "地面部署阵后固定升起，炮管锁敌蓄能发射爆炸炮弹；离玩家超过summon_return_radius后按secondary_delay重新部署。",
      star3: "增加副炮口，每次攻击极短间隔追加第二枚炮弹，副炮按secondary_damage_mult造成伤害并优先不同目标。",
      role: "3费固定远程范围火力，默认可受伤，重新部署期间不攻击。",
      fields: "summon_return_radius, secondary_delay, explosion_radius, delayed_strike_interval, secondary_damage_mult",
      ai: "固定不移动；自动索敌；玩家离开过远后收起并延迟重新部署。",
      aggro: "有仇恨，保持当前项目默认可被敌人选择。",
      vulnerable: "可受伤。",
      death: "沿用召唤物死亡/重生；另有过远重新部署逻辑。",
    },
    ghost: {
      performance: "水波召唤印记中浮现，无实体阻挡、无仇恨、普通伤害无效；锁敌后拉长并穿过目标，留下半透明拖尾。",
      star3: "第一次穿过后在secondary_radius内寻找第二目标，立即二段转向冲刺，伤害按secondary_damage_mult。",
      role: "4费无敌无仇恨高速穿透输出，不承担坦克职责，无死亡重生。",
      fields: "summon_base_count, summon_move_speed, length, width, secondary_damage_mult, secondary_radius, secondary_delay",
      ai: "玩家附近漂浮；锁敌后直线冲刺穿过并在目标后方停顿；过远返回。",
      aggro: "无仇恨，敌人不会主动锁定。",
      vulnerable: "普通伤害无效。",
      death: "无死亡和重生。",
    },
    poison_bug: {
      performance: "毒色召唤纹路中爬出虫群，低频批量索敌并按槽位分配目标，软分离围攻撕咬并附加不无限叠加中毒。",
      star3: "数量额外增加；中毒敌人死亡触发小型毒爆，范围=poison_explosion_radius，伤害=poison_explosion_damage_mult，并受delayed_strike_count连锁上限约束。",
      role: "5费虫潮数量压制，无仇恨但可被范围伤害波及，沿用现有补充规则。",
      fields: "summon_base_count, summon_combat_radius, poison_can_stack, poison_explosion_radius, poison_explosion_damage_mult, delayed_strike_count",
      ai: "低频分批索敌；按槽位分配最近目标；软分离围攻，避免全员完全重叠。",
      aggro: "无仇恨，敌人不会主动锁定。",
      vulnerable: "可被范围伤害或非锁定伤害波及。",
      death: "沿用现有毒虫补充逻辑；不为每只虫单独无限重生。",
    },
  };
  return notes[a.id]?.[kind] ?? "";
}

function buildConfigWorkbook(data) {
  const wb = Workbook.create();
  makeOverview(wb, data, "Build Rogue 配置总表", "面向数值配置检查：包含所有法宝、星级预览、天命、奇遇、羁绊阈值、经济与修为基础配置。");

  const artifactRows = data.artifacts.map((a) => ({
    id: a.id,
    原名称: swordDesignNote(a, "oldName"),
    名称: a.display_name,
    描述: a.description,
    攻击表现: swordDesignNote(a, "performance"),
    AI行为: swordDesignNote(a, "ai"),
    是否有仇恨值: swordDesignNote(a, "aggro"),
    是否可受伤: swordDesignNote(a, "vulnerable"),
    死亡与重生规则: swordDesignNote(a, "death"),
    三星机制: swordDesignNote(a, "star3"),
    战斗定位: swordDesignNote(a, "role"),
    新增关键字段: swordDesignNote(a, "fields"),
    流派: a.system_tag,
    主属性: a.attribute_tag,
    副属性: a.secondary_attribute_tag || "",
    属性组合: a.secondary_attribute_tag ? `${a.attribute_tag}＋${a.secondary_attribute_tag}` : a.attribute_tag,
    品阶: a.tier,
    价格: a.cost,
    修为要求: a.cultivation_requirement,
    商店权重: a.shop_weight,
    模板: a.attack_template,
    形状: a.attack_shape,
    效果类型: a.effect_type,
    伤害: a.damage,
    冷却秒: a.cooldown,
    DPS估算: a.cooldown ? Number((a.damage / a.cooldown).toFixed(2)) : "",
    范围: a.range,
    半径: a.radius,
    宽度: a.width,
    长度: a.length,
    数量: a.count,
    最大目标: a.max_targets,
    穿透: a.projectile_pierce,
    弹射: a.projectile_bounce || a.bounce_count,
    击退: a.knockback_force,
    减速: a.slow_percent,
    治疗: a.heal_amount,
    护盾: a.shield_amount,
    中毒DPS: a.poison_dps,
    中毒持续: a.poison_duration,
    生命消耗百分比: a.life_cost_percent,
    生命消耗固定: a.life_cost_flat,
    召唤数量: a.summon_base_count,
    召唤生命: a.summon_hp,
    召唤攻击: a.summon_attack,
    召唤攻速: a.summon_attack_speed,
    "2星伤害倍率": a.star2_damage_mult || 1.55,
    "2星冷却倍率": a.star2_cooldown_mult || 0.85,
    "3星伤害倍率": a.star3_damage_mult || 2.25,
    "3星冷却倍率": a.star3_cooldown_mult || 0.7,
    windup_time: a.windup_time,
    trail_length: a.trail_length,
    hit_flash_duration: a.hit_flash_duration,
    secondary_damage_mult: a.secondary_damage_mult,
    secondary_radius: a.secondary_radius,
    secondary_delay: a.secondary_delay,
    side_projectile_damage_mult: a.side_projectile_damage_mult,
    return_speed: a.return_speed,
    fan_angle: a.fan_angle,
    converge_speed: a.converge_speed,
    self_rotation_speed: a.self_rotation_speed,
    reveal_time: a.reveal_time,
    pause_time: a.pause_time,
    sweep_rotation_speed: a.sweep_rotation_speed,
    screen_shake_strength: a.screen_shake_strength,
    hit_feedback_profile: a.hit_feedback_profile,
    hit_stop_seconds: a.hit_stop_seconds,
    screen_shake_duration: a.screen_shake_duration,
    hit_effect_scale: a.hit_effect_scale,
    hit_sound_id: a.hit_sound_id,
    damage_number_style: a.damage_number_style,
    来源: a.source_file,
  }));
  addSheet(wb, "法宝总表", artifactRows, { widths: Array(64).fill(120) });

  const starRows = [];
  for (const a of data.artifacts) {
    for (const star of [1, 2, 3]) {
      const summon = summonPreview(a, star);
      const isSummon = a.attack_template === "summon" || Number(a.summon_base_count || 0) > 0;
      const damageMult = starDamageMult(a, star);
      const cooldownMult = starCooldownMult(a, star);
      const dmg = isSummon ? summon.attack : Number(a.damage || 0) * damageMult;
      const cd = isSummon ? (1 / Math.max(0.1, summon.attackSpeed)) : Math.max(0.05, Number(a.cooldown || 1) * cooldownMult);
      starRows.push({
        id: a.id,
        名称: a.display_name,
        星级: star,
        是否召唤: isSummon ? "是" : "否",
        伤害倍率: isSummon ? "" : damageMult,
        冷却倍率: isSummon ? "" : cooldownMult,
        有效伤害或召唤攻击: Number(dmg.toFixed(2)),
        有效冷却或攻击间隔: Number(cd.toFixed(3)),
        DPS估算: cd ? Number((dmg / cd).toFixed(2)) : "",
        召唤数量: isSummon ? summon.count : "",
        召唤生命: isSummon ? Number(summon.hp.toFixed(2)) : "",
        召唤攻速: isSummon ? Number(summon.attackSpeed.toFixed(3)) : "",
      });
    }
  }
  addSheet(wb, "法宝星级预览", starRows);

  addSheet(wb, "天命", data.destinies.map((d) => ({
    id: d.id,
    名称: d.name,
    描述: d.description,
    起始灵石: d.starting_stones,
    价格倍率: d.shop_price_multiplier,
    前期价格倍率: d.early_shop_price_multiplier,
    前期关卡数: d.early_shop_wave_limit,
    刷新倍率: d.reroll_cost_multiplier,
    首刷免费: d.first_reroll_free,
    首刷后刷新倍率: d.after_first_reroll_cost_multiplier,
    额外商品: d.extra_offer_count,
    禁止刷新: d.reroll_disabled,
    伤害倍率: d.damage_multiplier,
    每关伤害增量: d.damage_per_cleared_wave,
    最大生命倍率: d.max_hp_multiplier,
    出战格变化: d.battle_slot_delta,
    低阶伤害倍率: d.low_tier_damage_multiplier,
    高阶伤害倍率: d.high_tier_damage_multiplier,
    高阶价格倍率: d.high_tier_price_multiplier,
    每关掉血: d.post_wave_current_hp_loss,
    购买修为生命消耗: d.cultivation_life_cost,
    修为获取倍率: d.cultivation_gain_multiplier,
    Boss开局掉血: d.boss_start_current_hp_loss,
    Boss额外奇遇: d.boss_extra_encounter_options,
    敌人倍率: d.enemy_stat_multiplier,
    灵石奖励倍率: d.spirit_stone_reward_multiplier,
  })));

  addSheet(wb, "奇遇", data.encounters.map((e) => ({
    id: e.id,
    名称: e.name,
    分类: e.category,
    描述: e.description,
    羁绊加成: e.synergy_tag,
    灵石: e.spirit_stones,
    免费刷新商店次数: e.free_reroll_shops,
    半价商店次数: e.half_price_shops,
    禁用聚灵: e.disable_spirit_gathering,
    每关额外灵石: e.extra_room_clear_stones,
    全押获得其他奇遇: e.all_in_all_encounters,
    下次1费购买星级: e.next_one_cost_star,
    随机升星: e.random_star_up,
    高一品阶重掷: e.reroll_higher_tier,
    每激活羁绊伤害: e.damage_per_active_synergy,
    "1星伤害倍率": e.star1_damage_multiplier,
    "3星伤害倍率": e.star3_damage_multiplier,
    恰好双同名倍率: e.exact_pair_damage_multiplier,
    复活血量比例: e.revive_once_ratio,
    复活后最大生命倍率: e.revive_max_hp_multiplier,
    复活后伤害倍率: e.revive_damage_multiplier,
    最大生命倍率: e.max_hp_multiplier,
    移速倍率: e.move_speed_multiplier,
    低血保命: e.low_hp_rescue,
    低血伤害倍率: e.low_hp_damage_multiplier,
    高血伤害倍率: e.high_hp_damage_multiplier,
    "每3星最大生命惩罚": e.max_hp_penalty_per_star3,
    效果键值: flattenEffect(e),
  })));

  addSheet(wb, "羁绊阈值", data.synergies);

  const econRows = [
    { 系统: "初始", 项目: "初始灵石", 数值: data.startingStones, 备注: "GameManager.starting_spirit_stones" },
    { 系统: "商店", 项目: "基础商品数", 数值: data.offerCount, 备注: "天命可修改商品数" },
    { 系统: "商店", 项目: "刷新价格", 数值: `${data.rerollBaseCost}, ${data.rerollBaseCost + data.rerollGrowth}, ${data.rerollBaseCost + data.rerollGrowth * 2}...`, 备注: "REROLL_COST + reroll_count * REROLL_COST_GROWTH" },
    { 系统: "聚灵", 项目: "花费", 数值: data.spiritGatherCost, 备注: "本次商店花费，下一回合返还" },
    { 系统: "聚灵", 项目: "返还", 数值: data.spiritGatherReturn, 备注: "每层返还" },
    { 系统: "聚灵", 项目: "最大层数", 数值: data.spiritGatherMax, 备注: "可被奇遇禁用" },
    { 系统: "修为", 项目: "购买花费", 数值: data.cultivationClickCost, 备注: "固定花费灵石" },
    { 系统: "修为", 项目: "购买获得", 数值: data.cultivationGainPerClick, 备注: "可被天命燃烧精血提高" },
    { 系统: "修为", 项目: "每关固定修为", 数值: data.roomCultivation, 备注: "通关后获得，满了直接突破" },
    { 系统: "出战", 项目: "基础出战格", 数值: data.baseBattleSlots, 备注: "实际格子=基础+境界索引+天命修正" },
  ];
  for (const r of data.roomRewards) econRows.push({ 系统: "固定奖励", 项目: `${r.min}-${r.max}关`, 数值: r.reward, 备注: "通关固定灵石奖励" });
  for (const tier of data.tierNames) econRows.push({ 系统: "法宝价格", 项目: tier, 数值: data.tierCosts[tier], 备注: `${TIER_ORDER.indexOf(tier) + 1}费` });
  data.realms.forEach((realm, i) => econRows.push({ 系统: "突破需求", 项目: `${realm} -> ${data.realms[i + 1] || "最高"}`, 数值: data.breakthroughRequirements[i] ?? "", 备注: i < data.breakthroughRequirements.length ? "修为满直接突破" : "最高境界" }));
  for (const [realm, weights] of Object.entries(data.shopTierWeights)) {
    for (const tier of data.tierNames) econRows.push({ 系统: "商店品阶权重", 项目: `${realm}/${tier}`, 数值: weights[tier], 备注: "按当前境界抽取商品品阶" });
  }
  addSheet(wb, "经济与修为", econRows);
  return wb;
}

function buildSystemWorkbook(data) {
  const wb = Workbook.create();
  makeOverview(wb, data, "Build Rogue 系统机制总表", "面向策划和实现对照：记录伤害链路、经济公式、关卡成长、羁绊机制、字段含义和效果索引。");

  addSheet(wb, "伤害系统", [
    { 顺序: 1, 环节: "法宝基础数据", 公式或规则: "基础伤害=data.damage；若 max_hp_damage_coefficient>0，追加 玩家最大生命*系数。", 来源: "Player.get_artifact_damage" },
    { 顺序: 2, 环节: "星级数值成长", 公式或规则: "非召唤：2星默认伤害*1.55、冷却*0.85；3星默认伤害*2.25、冷却*0.7。法宝可单独覆盖。", 来源: "ArtifactStarConfig" },
    { 顺序: 3, 环节: "召唤星级成长", 公式或规则: "召唤物按具体 id 调整生命/攻击/攻速/数量，见配置总表的法宝星级预览。", 来源: "ArtifactStarConfig._apply_summon_growth" },
    { 顺序: 4, 环节: "天命法宝倍率", 公式或规则: "草根逆袭/大器天成等按法宝品阶乘算到单件法宝倍率。", 来源: "DestinyManager.get_artifact_damage_multiplier" },
    { 顺序: 5, 环节: "奇遇法宝倍率", 公式或规则: "炼器宗师、好事成双、天妒英才等按星级/同名数量乘算到单件法宝倍率。", 来源: "EncounterManager.get_artifact_damage_multiplier" },
    { 顺序: 6, 环节: "整局/战斗伤害倍率", 公式或规则: "最终伤害 = 法宝有效伤害 * run_damage_multiplier * artifact_multiplier。run_damage_multiplier 由天命和奇遇共同计算。", 来源: "Player.get_artifact_damage" },
    { 顺序: 7, 环节: "羁绊运行时修正", 公式或规则: "剑修降低冷却；法修追加投射物；体修放大生命和范围；魔修低血增伤；属性羁绊命中后触发额外效果。", 来源: "SynergyManager / ArtifactInstance" },
    { 顺序: 8, 环节: "同名法宝攻击错峰", 公式或规则: "相同 id 的非持续型法宝攻击后写入 0.035 秒间隔，避免完全重合。", 来源: "ArtifactInstance.update" },
  ]);

  const econRows = [
    { 模块: "法宝价格", 规则: "1-5费价格固定为 10/20/30/40/50。最终售价=基础价格*天命价格倍率*奇遇商店价格倍率，向上取整，最低1。", 当前值: "凡器10，法器20，灵器30，灵宝40，仙宝50" },
    { 模块: "刷新价格", 规则: "第n次刷新基础价格=5+n*5，n从0开始；天命和奇遇可把价格变为0或乘倍率。", 当前值: "5,10,15..." },
    { 模块: "关卡固定奖励", 规则: "按通关波数区间给固定灵石，再加奇遇额外灵石，再乘天命灵石奖励倍率。", 当前值: data.roomRewards.map((r) => `${r.min}-${r.max}:${r.reward}`).join("; ") },
    { 模块: "敌人掉落", 规则: "当前 ENEMY_SPIRIT_STONE_DROP_MULTIPLIER=0，因此敌人击杀不额外给灵石。", 当前值: data.enemyDropMultiplier },
    { 模块: "聚灵", 规则: "商店中花费100灵石叠1层，下次进入商店每层返还110，最多3层；奇遇可禁用并清空全押中的未返还层。", 当前值: `cost=${data.spiritGatherCost}; return=${data.spiritGatherReturn}; max=${data.spiritGatherMax}` },
    { 模块: "修为购买", 规则: "花费40灵石获得40修为，燃烧精血会额外损失10生命并获得50%额外修为。", 当前值: `${data.cultivationClickCost} -> ${data.cultivationGainPerClick}` },
    { 模块: "通关修为", 规则: "每关固定+20修为；修为达到当前境界需求时直接突破，不需要突破材料。", 当前值: data.roomCultivation },
    { 模块: "突破需求", 规则: "炼气->筑基120；筑基->金丹160；金丹->元婴240；元婴->化神400。", 当前值: data.breakthroughRequirements.join(", ") },
  ];
  addSheet(wb, "经济系统", econRows);

  const waveRows = [];
  for (let wave = 1; wave <= 20; wave++) {
    const isBoss = data.bossWaves.includes(wave);
    const duration = wave === 1 ? data.roomDurations.wave1 : wave === 2 ? data.roomDurations.wave2 : wave === 3 ? data.roomDurations.wave3 : data.roomDurations.late;
    waveRows.push({
      关卡: wave,
      Boss关: isBoss ? "是" : "否",
      房间时长秒: duration,
      固定灵石奖励: data.roomRewards.find((r) => wave >= r.min && wave <= r.max)?.reward ?? "",
      固定修为: data.roomCultivation,
      生存刷怪间隔: data.waveScaling.spawnIntervals[wave],
      生存每批数量: Math.ceil(data.waveScaling.packSizes[wave] * (wave === 1 ? 1 : 1.5)),
      备注: isBoss ? "击败Boss后触发奇遇选择；最终Boss为20关" : "",
    });
  }
  addSheet(wb, "关卡成长", waveRows);

  const enemyNames = { basic: "基础怪", fast: "快速怪", tank: "坦克怪", ranged: "远程怪", charger: "突进怪" };
  addSheet(wb, "敌人配置", Object.entries(data.enemies).map(([id, cfg]) => ({
    敌人ID: id, 名称: enemyNames[id] ?? id, 基础生命: cfg.hp, 移动速度: cfg.speed,
    主要伤害: cfg.damage, 首次出现关卡: cfg.first_wave,
    理想距离: cfg.ideal_range ?? "", 攻击间隔: cfg.attack_interval ?? "", 前摇秒数: cfg.windup ?? "",
    弹体速度: cfg.projectile_speed ?? "", 突进速度: cfg.dash_speed ?? "", 硬直秒数: cfg.recovery ?? "",
    技能冷却: cfg.cooldown ?? "", 数据来源: "EnemyBalanceConfig.ENEMIES",
  })));

  const waveDesign = [
    [1,"教学","基础100%；18秒后少量快速",0], [2,"速度压力","基础85%/快速15%",0], [3,"速度压力","基础70%/快速20%/坦克10%",0],
    [4,"高血目标","基础63%/快速16%/坦克21%",1], [5,"高血目标+Boss","基础62%/快速16%/坦克22%",1],
    [6,"远程教学","基础57%/快速16%/坦克16%/远程11%",0], [7,"远程压力","基础52%/快速15%/坦克15%/远程18%",1],
    [8,"突进教学","基础51%/快速15%/坦克15%/远程14%/突进5%",1], [9,"机动混合+Boss","基础46%/快速15%/坦克15%/远程14%/突进10%",1],
    [10,"杂兵海","基础67%/快速18%/坦克7%/远程5%/突进3%",1], [11,"重装波","基础49%/快速8%/坦克25%/远程15%/突进3%",1],
    [12,"追猎波","基础50%/快速24%/坦克8%/远程6%/突进12%",1], [13,"火力波+Boss","基础48%/快速8%/坦克17%/远程22%/突进5%",2],
    [14,"精英波","基础50%/快速12%/坦克18%/远程13%/突进7%",2],
    ...Array.from({length:6}, (_,i) => [15+i, "高压组合" + ([17,20].includes(15+i) ? "+Boss" : ""), "基础45%/快速16%/坦克17%/远程13%/突进9%", 15+i < 18 ? 2 : 3]),
  ];
  addSheet(wb, "关卡刷怪", waveDesign.map(([wave, theme, weights, elites]) => ({
    关卡: wave, 主题: theme, 敌人权重: weights,
    数量倍率: wave === 1 ? 1 : 1.5,
    每批数量: Math.ceil(data.waveScaling.packSizes[wave] * (wave === 1 ? 1 : 1.5)),
    生成间隔: data.waveScaling.spawnIntervals[wave], 精英次数: elites, 后半段强度倍率: 1.2,
    安全生成距离: 245, 敌方弹体上限: 18, 远程上限: wave < 6 ? 0 : wave < 7 ? 2 : wave < 13 ? 4 : 6,
    突进上限: wave < 8 ? 0 : wave < 9 ? 2 : wave < 12 ? 3 : 4,
  })));

  addSheet(wb, "精英配置", [{
    体型倍率: data.elite.scale, 生命倍率: data.elite.hp, 伤害倍率: data.elite.damage,
    移速倍率: data.elite.speed, 支持类型: "基础/快速/坦克/远程/突进",
    奖励处理: "elite_reward_requested 接口（暂不大幅增加灵石）",
  }]);

  addSheet(wb, "羁绊说明", data.synergies);

  const fieldRows = [
    ["id", "法宝/天命/奇遇", "唯一标识，用于代码引用和去重。"],
    ["display_name/name", "法宝/天命/奇遇", "显示名称。"],
    ["system_tag", "法宝", "流派羁绊：剑修、法修、体修、召唤、魔修。"],
    ["attribute_tag", "法宝", "主属性羁绊：金、木、水、火、土、雷、毒。"],
    ["secondary_attribute_tag", "法宝", "可选副属性；填写后该法宝同时计入两种属性羁绊，并在命中时执行两种已激活属性效果。"],
    ["tier", "法宝", "品阶，同时决定基础价格。"],
    ["attack_template", "法宝", "攻击模板：melee/projectile/orbit/beam/formation/line_delayed/summon/target_aoe/soul_banner。"],
    ["effect_type", "法宝", "特殊效果类型：damage/slow/attack_speed/heal/shield/damage_reduction/avatar_slam。"],
    ["damage/cooldown", "法宝", "基础伤害和基础冷却，星级与羁绊可修改。"],
    ["shop_weight", "法宝", "同品阶内抽取权重。"],
    ["damage_multiplier", "天命/奇遇", "整局或条件性伤害倍率。"],
    ["shop_price_multiplier", "天命/奇遇", "商店售价倍率。"],
    ["reroll_cost_multiplier", "天命", "刷新价格倍率。"],
    ["extra_offer_count", "天命", "商店额外出现法宝数量。"],
    ["synergy_tag", "奇遇", "让指定羁绊激活数+1。"],
    ["free_reroll_shops / half_price_shops", "奇遇", "影响后续商店刷新或购买价格。"],
    ["disable_spirit_gathering", "奇遇", "禁用聚灵按钮。"],
    ["max_hp_multiplier / move_speed_multiplier", "奇遇", "玩家最大生命和移动速度倍率。"],
    ["max_hp_penalty_per_star3", "奇遇", "每个出战3星法宝扣最大生命。"],
    ["hit_feedback_profile", "法宝", "命中反馈模板：light/medium/heavy/explosion/continuous/summon；留空使用系统映射。"],
    ["hit_stop_seconds", "法宝", "Hit Stop 秒数覆盖；留空使用模板默认值。"],
    ["knockback_force", "法宝", "击退力度覆盖；留空使用模板默认值。"],
    ["screen_shake_strength / screen_shake_duration", "法宝", "震屏强度与持续时间覆盖；留空使用模板默认值。"],
    ["hit_effect_scale", "法宝", "对象池命中特效缩放覆盖；留空使用模板默认值。"],
    ["hit_sound_id", "法宝", "统一命中音效 ID；留空使用模板默认值。"],
    ["damage_number_style", "法宝", "伤害数字样式：normal/critical/continuous/healing；留空使用模板默认值。"],
  ].map(([字段, 来源, 含义]) => ({ 字段, 来源, 含义 }));
  addSheet(wb, "字段字典", fieldRows);

  const effectRows = [
    ...data.destinies.map((d) => ({ 类型: "天命", 分类: "开局选择", id: d.id, 名称: d.name, 描述: d.description, 效果键值: flattenEffect(d) })),
    ...data.encounters.map((e) => ({ 类型: "奇遇", 分类: e.category, id: e.id, 名称: e.name, 描述: e.description, 效果键值: flattenEffect(e) })),
  ];
  addSheet(wb, "天命奇遇效果索引", effectRows);
  return wb;
}

async function verifyAndSave(workbook, name, previewSheets) {
  const errors = await workbook.inspect({
    kind: "match",
    searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A",
    options: { useRegex: true, maxResults: 300 },
    summary: "formula error scan",
  });
  if (errors.ndjson.includes("#REF!") || errors.ndjson.includes("#DIV/0!") || errors.ndjson.includes("#VALUE!") || errors.ndjson.includes("#NAME") || errors.ndjson.includes("#N/A")) {
    throw new Error(`Formula errors found in ${name}:\n${errors.ndjson}`);
  }
  for (const sheetName of previewSheets) {
    const preview = await workbook.render({ sheetName, autoCrop: "all", scale: 1, format: "png" });
    await fs.writeFile(path.join(OUT_DIR, `${name}_${sheetName}.png`), new Uint8Array(await preview.arrayBuffer()));
  }
  const xlsx = await SpreadsheetFile.exportXlsx(workbook);
  const out = path.join(OUT_DIR, `${name}.xlsx`);
  await xlsx.save(out);
  return out;
}

async function main() {
  const data = await collectData();
  const config = buildConfigWorkbook(data);
  const system = buildSystemWorkbook(data);
  const configPath = await verifyAndSave(config, "build_rogue_config_data", ["说明", "法宝总表", "法宝星级预览", "天命", "奇遇", "羁绊阈值", "经济与修为"]);
  const systemPath = await verifyAndSave(system, "build_rogue_system_reference", ["说明", "伤害系统", "经济系统", "关卡成长", "羁绊说明", "字段字典", "天命奇遇效果索引"]);
  await fs.mkdir(rel("docs"), { recursive: true });
  const docsConfigPath = rel("docs/GameBalance.xlsx");
  const docsSystemPath = rel("docs/GameBalance.updated.xlsx");
  await fs.copyFile(configPath, docsConfigPath);
  await fs.copyFile(systemPath, docsSystemPath);
  const summary = await config.inspect({ kind: "sheet", include: "name", maxChars: 4000 });
  console.log(JSON.stringify({ configPath, systemPath, docsConfigPath, docsSystemPath, sheets: summary.ndjson }, null, 2));
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
