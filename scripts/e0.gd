## ENTITY_000 — shared constants: palette, physics, combat, consistency.
## Static class, not an autoload. All values are locked by the Phase 0 bibles.
class_name E0
extends RefCounted

# --- Palette (locked — matches delivery hub + Art Bible) -------------------
const VOID := Color("070708")
const CHARCOAL := Color("141416")
const ASH := Color("2b2b2e")
const DIRTY_STONE := Color("4a463f")
const BONE := Color("cfc8b8")
const PARCH := Color("a89f8c")
const BLOOD := Color("6d1a22")
const CRIMSON := Color("83322b")
const GOLD := Color("b08d3e")
const VIOLET := Color("3b2f4a")
const CYAN := Color("7fd8d8")
const DIM := Color("857d6c")          # faint labels
const SHADOW := Color("0d0d0f")       # panels

# --- Player kit (locked) ----------------------------------------------------
const P_MAX_SPEED := 260.0
const P_JUMP := -420.0
const P_MAX_HP := 100
const P_CHAIN := [22, 22, 30]
const P_ACCEL := 1500.0
const P_FRICTION := 1900.0
const P_AIR_CONTROL := 0.72
const P_GRAVITY := 1500.0
const P_FALL_GRAVITY := 1800.0
const P_MAX_FALL := 900.0
const P_COYOTE := 0.12
const P_BUFFER := 0.15
const P_ROLL_SPEED := 380.0
const P_ROLL_TIME := 0.35
const P_ROLL_CD := 0.6
const P_ATTACK_CD := 0.42
const P_CHAIN_WINDOW := 0.75
const P_HURT_IFRAMES := 0.65

# --- Consistency (HUNTED model, locked) --------------------------------------
const CONSISTENCY_START := 100
const STAGE_BOUNDS := [86, 71, 56, 41, 21, 0]   # S1..S6 upper bounds
const STAGE_NAMES := [
        "WHISPERS",
        "ENVIRONMENTAL INCONSISTENCIES",
        "NPC AWARENESS",
        "THE CENSOR HUNTS",
        "REALITY ACTIVELY HUNTS",
        "HIDDEN STRUCTURES",
]
const COST_DOOR := 6
const COST_NULL_TERMINATE := 4
const COST_CONTRADICTION := 5
const COST_ABANDON := 8
const COST_TOLL_BREAK := 8
const COST_ARCHIVE_FIX := 5
const CENSOR_TOUCH_DRAIN := 4
const CORRECTION_TOUCH_DRAIN := 2
const BOSS_AURA_DRAIN := 1.0          # per second, phase 2, in radius
const ANCHOR_RESTORE := 12            # first communion per anchor, only at >= 60

# --- Enemies (locked) --------------------------------------------------------
const HOLLOW_HP := 60
const HOLLOW_DMG := 12
const NULL_HP := 40
const NULL_DMG := 8
const BELIEVER_HP := 80
const BELIEVER_DMG := 10
const CENSOR_DMG := 30
const CENSOR_SPEED_S4 := 120.0
const CENSOR_SPEED_S5 := 200.0

# --- Boss (locked) -----------------------------------------------------------
const MARTYR_HP := 900
const MARTYR_P2_AT := 600
const MARTYR_P3_AT := 300
const MARTYR_DMG := [18, 24, 30]      # by phase

# --- Physics layers (single-bit masks) ----------------------------------------
const L_WORLD := 1
const L_PLAYER := 2
const L_ENEMY := 4
const L_AREA := 8                     # triggers / interactables
const L_HURTBOX := 16                 # enemy hurt areas
const L_PLAYER_HURT := 32

# --- Time ---------------------------------------------------------------------
const OBSERVE_TIME_SCALE := 0.35
const HITSTOP_SCALE := 0.05

static func stage_for(consistency: int) -> int:
        ## 1..6 — six escalating stages of the hunted model.
        if consistency > STAGE_BOUNDS[0]:
                return 1
        for i in range(STAGE_BOUNDS.size()):
                if consistency >= STAGE_BOUNDS[i]:
                        return i + 1
        return 6

# --- Fonts (loaded once; headless-safe) ---------------------------------------
static var mono: FontFile
static var mono_bold: FontFile
static var serif: FontFile

static func load_fonts() -> void:
        if mono != null:
                return
        if FileAccess.file_exists("res://art/fonts/plexmono-regular.ttf"):
                mono = load("res://art/fonts/plexmono-regular.ttf")
        if FileAccess.file_exists("res://art/fonts/plexmono-semibold.ttf"):
                mono_bold = load("res://art/fonts/plexmono-semibold.ttf")
        if FileAccess.file_exists("res://art/fonts/cormorant-light.ttf"):
                serif = load("res://art/fonts/cormorant-light.ttf")

static func f(size: int, bold := false) -> FontFile:
        load_fonts()
        return (mono_bold if bold else mono) if (mono_bold if bold else mono) != null else null

static func clamped_col(c: Color, v: float) -> Color:
        ## Utility: darken toward void.
        return c.lerp(VOID, clampf(v, 0.0, 1.0))
