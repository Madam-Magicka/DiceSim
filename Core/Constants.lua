-- General constants for DiceSim

local DiceSim = _G.DiceSim

DiceSim.EditIcon = "Interface\\Buttons\\UI-GuildButton-PublicNote-Up"

-- UI constants
DiceSim.MAIN_WIDTH = 960
DiceSim.MAIN_HEIGHT = 640
DiceSim.MINIMIZED_WIDTH = 360
DiceSim.MINIMIZED_HEIGHT = 54

-- Character constants
DiceSim.CHARACTER_STAT_MIN = 0
DiceSim.CHARACTER_STAT_MAX = 999
DiceSim.CHARACTER_DEFAULT_STAT = 0
DiceSim.CHARACTER_POINT_BUDGET = 0
DiceSim.DEFAULT_SHEET_VERSION = 4
DiceSim.CHARACTER_STATS = { "STR", "DEX", "CON", "INT", "WIS", "CHA" }
DiceSim.DEFAULT_SHEET_METRICS = {
    hp = { value = 0, max = 0 },
    energy = { value = 0, max = 0 },
    armor = { value = 0, max = 0 },
}

-- Raid markers
DiceSim.RAID_MARKERS = {
    { label = "Star", icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1" },
    { label = "Circle", icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_2" },
    { label = "Diamond", icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_3" },
    { label = "Triangle", icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_4" },
    { label = "Moon", icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_5" },
    { label = "Square", icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_6" },
    { label = "Cross", icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7" },
    { label = "Skull", icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8" },
}

DiceSim.NUMBER_SYMBOLS = {
    { label = "Number 1", icon = "services-number-1" },
    { label = "Number 2", icon = "services-number-2" },
    { label = "Number 3", icon = "services-number-3" },
    { label = "Number 4", icon = "services-number-4" },
    { label = "Number 5", icon = "services-number-5" },
    { label = "Number 6", icon = "services-number-6" },
    { label = "Number 7", icon = "services-number-7" },
    { label = "Number 8", icon = "services-number-8" },
    { label = "Number 9", icon = "services-number-9" },
}

-- Panel types
DiceSim.PANEL_TYPES = {
    Enemy = { border = { 0.78, 0.16, 0.14, 1 }, portrait = "Interface\\Icons\\Ability_Warrior_OffensiveStance", background = "CreditsScreen-Background-8" },
    Friendly = { border = { 0.18, 0.72, 0.28, 1 }, portrait = "Interface\\Icons\\Ability_Paladin_BeaconOfLight", background = "CreditsScreen-Background-6" },
    Neutral = { border = { 0.86, 0.72, 0.18, 1 }, portrait = "Interface\\Icons\\INV_Misc_QuestionMark", background = "CreditsScreen-Background-7" },
}

-- Dice options
DiceSim.DICE_OPTIONS = { "D20", "D12", "D10", "D8", "D6", "D4", "D100" }
DiceSim.EFFECT_DICE_OPTIONS = { "None", "D4", "D6", "D8", "D10", "D12", "D20", "D100", "2D4", "2D6", "2D8", "2D10" }

-- Attribute action tree
DiceSim.ATTRIBUTE_ACTION_TREE = {
    {
        label = "STRENGTH",
        buffs = { "Melee Damage", "Grapple Strength", "Energy Pool", "Heavy Weapon Accuracy" },
        actions = { "Melee Attack", "Grapple", "Break Armor" },
    },
    {
        label = "DEXTERITY",
        buffs = { "Ranged Damage", "Dodge", "Initiative", "Light Weapon Accuracy" },
        actions = { "Ranged Attack", "Dodge", "Sneak", "Initiative" },
    },
    {
        label = "CONSTITUTION",
        buffs = { "Health Pool", "Poison Resistance", "Endurance", "Regeneration" },
        actions = { "Endure", "Resist Poison", "Survive" },
    },
    {
        label = "INTELLIGENCE",
        buffs = { "Spell Power", "Knowledge", "Arcane Resistance", "Spell Accuracy" },
        actions = { "Cast Spell", "Identify", "Research" },
    },
    {
        label = "WISDOM",
        buffs = { "Spell Power", "Perception", "Divine Resistance", "Spell Accuracy" },
        actions = { "Cast Spell", "Sense Motive", "Heal" },
    },
    {
        label = "CHARISMA",
        buffs = { "Persuasion", "Intimidation", "Deception", "Leadership" },
        actions = { "Persuade", "Intimidate", "Deceive" },
    },
}

-- Fallback affect icon options
DiceSim.FALLBACK_AFFECT_ICON_OPTIONS = {
    { icon = "Interface\\Icons\\Spell_Holy_Renew", label = "Renew" },
    { icon = "Interface\\Icons\\Spell_Shadow_CurseOfTounges", label = "Curse" },
    { icon = "Interface\\Icons\\Ability_Warrior_BattleShout", label = "Battle Shout" },
    { icon = "Interface\\Icons\\Spell_Holy_SealOfMight", label = "Seal of Might" },
    { icon = "Interface\\Icons\\Spell_Fire_Fire", label = "Fire" },
    { icon = "Interface\\Icons\\Spell_Frost_FrostBolt02", label = "Frost" },
    { icon = "Interface\\Icons\\Spell_Nature_Lightning", label = "Lightning" },
    { icon = "Interface\\Icons\\Spell_Shadow_ShadowBolt", label = "Shadow" },
    { icon = "Interface\\Icons\\Spell_Holy_HealingAura", label = "Healing" },
    { icon = "Interface\\Icons\\Spell_Nature_HealingTouch", label = "Nature" },
}

DiceSim.PORTRAIT_RING_OPTIONS = {
    { label = "Default", value = "hud-PlayerFrame-portraitring-large" },
    { label = "Gold", value = "communities-ring-gold" },
    { label = "Blue", value = "communities-ring-blue" },
    { label = "Celebration", value = "majorfaction-celebration-content-ring" },
    { label = "Kyrian", value = "CovenantChoice-Offering-Ability-Ring-Kyrian" },
    { label = "Necrolord", value = "CovenantChoice-Offering-Ability-Ring-Necrolord" },
    { label = "Night Fae", value = "CovenantChoice-Offering-Ability-Ring-NightFae" },
    { label = "Venthyr", value = "CovenantChoice-Offering-Ability-Ring-Venthyr" },
    { label = "Azerite", value = "Azerite-Trait-Ring-Open" },
    { label = "Keystone", value = "ChallengeMode-KeystoneSlotFrame" },
    { label = "Alliance", value = "charactercreate-ring-alliance" },
    { label = "Dark Metal", value = "charactercreate-ring-metaldark-disabled" },
    { label = "Light Metal", value = "charactercreate-ring-metallight" },
    { label = "Horde", value = "charactercreate-ring-horde" },
    { label = "Talent", value = "Talent-RingWithDot" },
    { label = "Pet Active", value = "pet-list_active-ring" },
    { label = "Pet Default", value = "pet-list_default-ring" },
    { label = "Footer Inactive", value = "footer_inactive-ring" },
    { label = "Footer Active", value = "footer_active-ring" },
    { label = "Tower Rare", value = "UI-Frame-jailerstower-Portrait-QualityRare" },
    { label = "Tower Epic", value = "UI-Frame-jailerstower-Portrait-QualityEpic" },
    { label = "Tower Uncommon", value = "UI-Frame-jailerstower-Portrait-QualityUncommon" },
    { label = "Tower", value = "UI-Frame-jailerstower-Portrait" },
    { label = "Holy", value = "Relic-Holy-TraitGlow" },
    { label = "Life", value = "Relic-Life-TraitGlow" },
    { label = "Frost", value = "Relic-Frost-TraitGlow" },
    { label = "Arcane", value = "Relic-Arcane-TraitGlow" },
    { label = "Shadow", value = "Relic-Shadow-TraitGlow" },
    { label = "Water", value = "Relic-Water-TraitGlow" },
    { label = "Fire", value = "Relic-Fire-TraitGlow" },
}

DiceSim.CANVAS_BACKGROUND_OPTIONS = {
    { label = "Default", value = "default" },
    { label = "Burning Crusade", value = "UI-EJ-BurningCrusade" },
    { label = "Classic", value = "UI-EJ-Classic" },
    { label = "Cataclysm", value = "UI-EJ-Cataclysm" },
    { label = "Wrath of the Lich King", value = "UI-EJ-WrathoftheLichKing" },
    { label = "Mists of Pandaria", value = "UI-EJ-MistsofPandaria" },
    { label = "Warlords of Draenor", value = "UI-EJ-WarlordsofDraenor" },
    { label = "Battle for Azeroth", value = "UI-EJ-BattleforAzeroth" },
    { label = "Legion", value = "UI-EJ-Legion" },
    { label = "Dragonflight", value = "UI-EJ-Dragonflight" },
    { label = "Shadowlands", value = "UI-EJ-Shadowlands" },
    { label = "The War Within", value = "UI-EJ-TheWarWithin" },
    { label = "Midnight", value = "ui-ej-midnight" },
    { label = "Grass", value = "shop-bg-environment-grass" },
    { label = "Lava", value = "shop-bg-environment-lava" },
    { label = "Magical", value = "shop-bg-environment-magical" },
    { label = "Snow", value = "shop-bg-environment-snow" },
}

MAIN_WIDTH = DiceSim.MAIN_WIDTH
MAIN_HEIGHT = DiceSim.MAIN_HEIGHT
MAIN_FRAME_WIDTH = DiceSim.MAIN_WIDTH
MAIN_FRAME_HEIGHT = DiceSim.MAIN_HEIGHT
MINIMIZED_WIDTH = DiceSim.MINIMIZED_WIDTH
MINIMIZED_HEIGHT = DiceSim.MINIMIZED_HEIGHT
CHARACTER_STAT_MIN = DiceSim.CHARACTER_STAT_MIN
CHARACTER_STAT_MAX = DiceSim.CHARACTER_STAT_MAX
CHARACTER_DEFAULT_STAT = DiceSim.CHARACTER_DEFAULT_STAT
CHARACTER_POINT_BUDGET = DiceSim.CHARACTER_POINT_BUDGET
DEFAULT_SHEET_VERSION = DiceSim.DEFAULT_SHEET_VERSION
CHARACTER_STATS = DiceSim.CHARACTER_STATS
DEFAULT_SHEET_METRICS = DiceSim.DEFAULT_SHEET_METRICS
RAID_MARKERS = DiceSim.RAID_MARKERS
NUMBER_SYMBOLS = DiceSim.NUMBER_SYMBOLS
PANEL_TYPES = DiceSim.PANEL_TYPES
DICE_OPTIONS = DiceSim.DICE_OPTIONS
EFFECT_DICE_OPTIONS = DiceSim.EFFECT_DICE_OPTIONS
FALLBACK_AFFECT_ICON_OPTIONS = DiceSim.FALLBACK_AFFECT_ICON_OPTIONS
PORTRAIT_RING_OPTIONS = DiceSim.PORTRAIT_RING_OPTIONS
CANVAS_BACKGROUND_OPTIONS = DiceSim.CANVAS_BACKGROUND_OPTIONS
