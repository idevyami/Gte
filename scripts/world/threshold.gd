## Threshold — THE CROSSING. The space between two acts is not nothing:
## when the vessel steps out of one world and before he steps into the next,
## the record annotates the passage. A first crossing of an edge is a DEEP
## crossing with three beats — THE LEAVING (the screen folds to black, the
## air of the old room dies slowly, but the vessel KEEPS WALKING: his
## footsteps sound on in the dark, on the material of the ground he just
## left), THE BETWEEN (full black holds; one line of the census voice is
## inscribed at the center of the dark; exactly one distant sound of the
## ARRIVING space is heard through it — you hear where you are going before
## you see it), and THE COMING (the fade opens into the new room's wake).
## A crossing the record has already annotated is QUICK — the plain fade of
## a city that does not repeat itself. Everything here is a pure function
## of threshold.t so proofs and smoke laws can pin any instant.
class_name Threshold
extends RefCounted

# --- the three beats of a deep crossing (s) ---
const LEAVE := 0.90             # the leaving: fold to black, walk on in the dark
const BLACK := 0.95             # the between: full black, the rubric, the herald
const COME := 0.65              # the coming: the fade opens into the wake

# --- the quick crossing (a crossing already annotated) ---
const QUICK_OUT := 0.35
const QUICK_IN := 0.40

# --- the walk continues in the dark ---
const FIRST_STEP := 0.18        # his first step past the door
const STEP_GAP := 0.42          # the rhythm he had
const STEP_COUNT := 3

# --- the between's content ---
const HERALD_AT := 0.45        # within the between (the arriving space, heard far)
const RISE := 0.35             # rubric rises
const FALL := 0.30             # rubric falls before the coming
const TRACK_IN := 2.0          # letter-spacing starts tight
const TRACK_OUT := 2.7         # and eases open as the record inscribes

# --- the census voice: one rubric per golden edge (lore-pinned; several
#     echo lines the readables already carry) ---
const RUBRICS := {
        "act1>act2": "THE COUNT BEGINS WHERE THE WOMB ENDS.",
        "act2>act3": "KEEP TO THE COUNT. THE CITY IS MEASURED DAILY.",
        "act3>act4": "EVERY RECORD HOLDS A DOOR THAT DISAGREES WITH ITSELF.",
        "act4>act5": "SHE WAS BELIEVED INTO BEING. THE COUNT NEVER CLOSED.",
        "act5>act6": "TO BE WATCHED IS TO BE KEPT. TO BE KEPT IS TO BE OWED.",
        "act6>act7": "THE ENGINE REQUIRES NOTHING. WE REQUIRE THE ENGINE.",
        "act7>act8": "WHAT THE DESIGN BINDS, THE RECORD INHERITS.",
        "act8>act9": "THE COUNT CONTINUES. THE COUNT ALWAYS CONTINUES.",
}

## The herald: the arriving space heard once, far, through the black.
## Sound placed in TIME before the space is placed in sight.
const HERALDS := {
        "act1>act2": {"id": "drip", "db": -8.0},          # the undercity's damp
        "act2>act3": {"id": "gust", "db": -9.0},          # the city's wind
        "act3>act4": {"id": "page_rustle", "db": -10.0},  # the archive's pages
        "act4>act5": {"id": "bell_far", "db": -8.0},      # the chapel's bell
        "act5>act6": {"id": "chain_creak", "db": -10.0},  # the watching's chains
        "act6>act7": {"id": "clank_far", "db": -9.0},     # the engine's far work
        "act7>act8": {"id": "organ_chord", "db": -10.0},  # the sanctuary's chord
        "act8>act9": {"id": "gust", "db": -8.0},          # the aftermath's wind
}

const FALLBACK_RUBRIC := "THE RECORD FOLLOWS THE VESSEL."
const FALLBACK_HERALD := "gust"

var from_room := ""
var to_room := ""
var deep := true
var rubric := ""
var herald_id := ""
var herald_db := -9.0
var t := 0.0

static func edge(from_id: String, to_id: String) -> String:
        return from_id + ">" + to_id

## Only the GOLDEN crossings — the nine acts in their authored sequence —
## are annotated by the record. A teleport (debug, proof, correction) is
## not a passage; it never wakes the between.
static func is_golden(from_id: String, to_id: String) -> bool:
        return RUBRICS.has(edge(from_id, to_id))

static func make(from_id: String, to_id: String, p_deep: bool) -> Threshold:
        var th := Threshold.new()
        th.from_room = from_id
        th.to_room = to_id
        th.deep = p_deep
        var key := edge(from_id, to_id)
        th.rubric = String(RUBRICS.get(key, FALLBACK_RUBRIC))
        var h: Dictionary = HERALDS.get(key, {"id": FALLBACK_HERALD, "db": -9.0})
        th.herald_id = String(h.get("id", FALLBACK_HERALD))
        th.herald_db = float(h.get("db", -9.0))
        if th.rubric.is_empty():
                th.rubric = FALLBACK_RUBRIC
        return th

# ------------------------------------------------------------------ spans

func leave_end() -> float:
        return LEAVE

func black_end() -> float:
        return LEAVE + BLACK

func span() -> float:
        ## Total dark choreography of a deep crossing (through the coming).
        return LEAVE + BLACK + COME

func done() -> bool:
        return t >= span()

# ------------------------------------------------------------------ the walk

func step_times() -> Array:
        ## The vessel's footsteps past the door — the SAME rhythm his walk
        ## had, continued into (and a little through) the black.
        var times: Array = []
        for i in STEP_COUNT:
                times.append(FIRST_STEP + i * STEP_GAP)
        return times

func herald_time() -> float:
        return LEAVE + HERALD_AT

static func step_sample(room_data: Dictionary) -> String:
        ## The sample the dark steps speak with — the DEPARTING district's
        ## material (the ground he is still on). Mirrors the player's law;
        ## stone uses the soft voice (the alternation lives in the player).
        match String(room_data.get("step_material", "stone")):
                "metal":
                        return "sfx_foot_metal"
                "carpet":
                        return "sfx_foot_carpet"
                "wet":
                        return "sfx_foot_wet"
                _:
                        return "sfx_step"

# ------------------------------------------------------------------ envelope

func fade_k() -> float:
        ## The black amount over the whole crossing: rises through the
        ## leaving, holds one full beat through the between, opens through
        ## the coming. A quick crossing uses the plain short fades.
        if not deep:
                # the plain city fade: out QUICK_OUT, in QUICK_IN (the load
                # happens at the seam) — expressed on the same 0..1 envelope
                if t < QUICK_OUT:
                        return smoothstep(0.0, QUICK_OUT, t)
                return 1.0 - smoothstep(QUICK_OUT, QUICK_OUT + QUICK_IN, t)
        if t < LEAVE:
                return smoothstep(0.0, LEAVE, t)
        if t < black_end():
                return 1.0
        return 1.0 - smoothstep(black_end(), span(), t)

func rubric_alpha() -> float:
        ## The census line: rises inside the between, falls before the
        ## coming — it never touches the arriving world's light.
        if not deep:
                return 0.0
        var a := LEAVE + 0.18
        var b := black_end() - FALL
        if t <= a:
                return 0.0
        if t < a + RISE:
                return smoothstep(a, a + RISE, t)
        if t < b:
                return 1.0
        return clampf(1.0 - (t - b) / FALL, 0.0, 1.0)

func rubric_track() -> float:
        ## Letter-spacing eases open as the line inscribes — the record's
        ## hand widening into certainty.
        var k := clampf((t - (LEAVE + 0.18)) / RISE, 0.0, 1.0)
        return lerpf(TRACK_IN, TRACK_OUT, k)

func letter_alpha(i: int, count: int) -> float:
        ## Per-letter reveal: the inscription travels left to right, each
        ## glyph arriving a breath after the last (seeded, never uniform).
        var u := clampf((t - (LEAVE + 0.18)) / RISE, 0.0, 1.0)
        var lag := 0.55 * float(i) / maxf(1.0, float(count - 1))
        return clampf((u - lag) / 0.42, 0.0, 1.0)
