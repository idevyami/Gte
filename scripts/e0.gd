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
# WB-19 THE THREE BEATS: each hit of the chain carries its own cadence —
# the impact lands later and the swing lives longer as the sentence gathers
# weight (the audit called hits 1-2 "one held button"; the arcs differ but
# the clock was uniform). Windup = ms into the swing before the blade meets;
# total = the swing's full life; cd = recovery before the next press answers.
const P_CHAIN_WINDUP := [0.055, 0.095, 0.115]
const P_CHAIN_TOTAL := [0.16, 0.25, 0.30]
const P_CHAIN_CD := [0.26, 0.35, 0.44]
# WB-19 THE GATHER: the body compresses for a breath before it leaves the
# floor — the jump reads as a decision, not a twitch (the ascent's jump
# scored 5/7 with "no anticipation frames" as the named lack)
const P_JUMP_GATHER := 0.045
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
# WB-20 THE FLOCK WALKS WITH WEIGHT: the ride the painted walk was missing —
# the audit's chess-piece read. The painted cycle plants its feet at frames
# 0 and 3 (verified: hem contact + the leg-swing structure); the body now
# DIPS as each footfall's weight is accepted, RISES through the swing, and
# SWAYS a quarter-cycle past the plant (the mass settles over the new foot)
# — additive to the 2px the paint itself rises at frames 1/4. Cloth-subtle
# by design: the congregation shuffles, it does not march. The censer is a
# pendulum — it trails the sway, it does not ride with the body.
const BELIEVER_RIDE_DIP := 1.3           # px, settled at each footfall
const BELIEVER_RIDE_SWAY := 1.35         # px, a quarter-cycle behind the plant
const BELIEVER_CENSER_SWING := 2.6       # px, the hanging lamp's lag
# WB-21 THE CENSER'S EDGE: the readability pass — the honest audit's
# value-collapse finding (facing 2/10, stride 1/10, silhouette separation
# 3/10 at full res: the robes at median lum 42 sink into the carpet's 67).
# The fix follows the vessel's own WB-17 law — the EDGE carries the read,
# not the body. Three amplitudes, no new systems:
const BELIEVER_LEAN := 1.8               # deg, the body's axis tilts toward its walk
const BELIEVER_RIM_A := 0.42             # the between-bodies edge — the many lamps burn brighter together (WB-22)
const BELIEVER_POOL_BASE := 0.10         # the censer ALWAYS pools its light (alive)
const BELIEVER_POOL_SEP := 0.30          # the many censers burn brighter together (WB-22: the press is a row of lamps)
const BELIEVER_SELF_LIFT := Color(1.15, 1.10, 0.98)  # warm — the robe answers the censer
# WB-22 THE PRESS KEEPS ITS COUNT: the honest audit's cluster finding — at
# full convergence the logged smallest gap between living bodies was 0.0 px
# for seven straight seconds, and the auditor read the stacked column as
# empty space ("no other figures present in the scene, let alone five").
# The press is the fiction; the merge is the bug. The flock still presses —
# but each body holds its own ground: a soft jostle keeps ~a robe's width
# between the living, so the crowd traces as N threats, not one beast. The
# STRIKE is exempt (the lunge carries through the crowd — the flock parts
# for the strike); the WINDUP is planted but not rooted — a wound body
# yields a little to the press (it can be shifted, so bodies that planted
# together still part) without being shoved into the vessel; the kneel is
# a station (fully planted); the dead are ground.
const BELIEVER_JOSTLE_MIN := 34.0        # px of center spacing the press keeps (a robe's width + shoulder room)
const BELIEVER_JOSTLE_K := 20.0          # px/s of shove per px of overlap
const BELIEVER_JOSTLE_CAP := 320.0       # px/s — a shove, never a teleport
const BELIEVER_WINDUP_MOBILITY := 0.25   # planted, not rooted — the press shifts a wound body a little
# WB-23 THE FURNITURE YIELDS: the figure-vs-architecture grammar finding —
# at the reliquary's busiest wall the audit traced 1 of 5 bodies (clarity
# 2/10, "reads primarily as an empty ornate interior"; the mass parsed as
# "twisted brass ornament", a body-sized candelabra as "a pile of gears and
# pipes"). Pixel truth: the crowd's field sat at med 66 against the quiet
# wall's 41, and the brass furniture's highlights (231) outshone the robes'
# own censer-gold edges (~139) — so the eye parsed FURNITURE as the figure
# candidates and the dark bodies as ornament holes. The grammar law (the
# vessel's own law, extended to the crowd): at the body band, the strongest
# warm presences must belong to BODIES — their rims, their pools, their
# lift. The flame-holders keep their flames (the light of the counted stays
# lit) but their halos and brass sit down; the wall's washes lift off the
# band; the chapel's own air thickens. All amplitude of living systems.
const FURNITURE_GLOW := 0.68             # the flame-holders' halos sit down (WB-23)
const CANDELABRA_METAL_DARK := 0.38      # the standing brass reads as furniture, not a body-sized rival

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
