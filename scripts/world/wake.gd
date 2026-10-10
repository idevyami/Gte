## Wake — THE ARRIVAL. A room is not pre-lit. When the vessel steps through
## the door, the space WAKES: its lights catch one by one, NEAREST FIRST
## (the ignition order is a function of distance from where you stand —
## placement gains temporal meaning), each catch carries a FLARE that
## settles, the air thickens into existence, the sound assembles itself,
## the held-dark world grade exhales to full presence, and the lens leans
## back then settles. A room you have already been to wakes QUICK — the
## city remembers the vessel. Everything here is a pure function of
## wake.t so proofs and smoke laws can pin any instant.
class_name Wake
extends RefCounted

const SPAN_FULL := 1.5           # first visit — the full choreography (s)
const SPAN_QUICK := 0.45         # revisit — the room remembers you (s)
const EMBER := 0.16              # pre-ignition intensity (a dying wick)
const FLARE := 0.5               # the catch overshoot (1.0 + FLARE peak)
const FLARE_LEN := 0.5           # how long the catch takes to settle (s)
const GATHER := 0.12             # the ember gutters just before it catches
const AIR_SPAN_K := 0.85         # the air finishes at span * this
const GRADE_FLOOR := 0.86        # the room begins held-dark at this lift

var origin := Vector2.ZERO       # where the vessel stands when the room begins
var room_size := Vector2(1280, 720)
var span := SPAN_FULL
var full := true
var t := 0.0

static func make(p_origin: Vector2, p_full: bool, p_room_size: Vector2) -> Wake:
        var w := Wake.new()
        w.origin = p_origin
        w.full = p_full
        w.room_size = p_room_size
        w.span = SPAN_FULL if p_full else SPAN_QUICK
        return w

func tick(delta: float) -> void:
        t += delta

func done() -> bool:
        return t >= span + FLARE_LEN

# ------------------------------------------------------------------ ignition

func delay_for(pos: Vector2) -> float:
        ## When this place catches. Distance-ordered from the vessel's entry
        ## (the near-first law) + a seeded per-place jitter so the sweep is
        ## never mechanically even. Pure function of position — Lights and
        ## FloorLights derive the SAME delay for the same source, so the
        ## ground answers the catch in the same breath as the flame.
        var diag := maxf(1.0, room_size.length())
        var dnorm := clampf(origin.distance_to(pos) / diag, 0.0, 1.0)
        var jitter := (float(_pos_seed(pos) % 1000) / 1000.0 - 0.5) * 0.2 * span
        return clampf(dnorm * span * 0.72 + jitter, 0.0, span * 0.85)

func factor_at(pos: Vector2) -> float:
        ## The drawn intensity multiplier for a source at pos, at wake.t:
        ##   before its catch  — a dying ember (guttering in its last moment)
        ##   the catch itself — a flare that overshoots and settles
        ##   after            — full presence (1.0)
        var delay := delay_for(pos)
        var u := t - delay
        if u < 0.0:
                var ember := EMBER
                if u > -GATHER:
                        # the ember gathers itself — a gutter before the catch
                        ember += 0.08 * absf(sin(t * 26.0 + float(_pos_seed(pos) % 7)))
                return ember
        if u < FLARE_LEN:
                return 1.0 + FLARE * pow(1.0 - u / FLARE_LEN, 1.6)
        return 1.0

func _pos_seed(pos: Vector2) -> int:
        return int(round(pos.x)) * 7919 + int(round(pos.y)) * 104729

# ------------------------------------------------------------------ the air

func air_alpha() -> float:
        ## The room's airborne matter (motes, mist, ashfall, its weather)
        ## thickens into existence — never snaps on.
        return smoothstep(0.0, span * AIR_SPAN_K, t)

func sound_fade(pos: Vector2) -> float:
        ## An emitter's gain ramp: silent until its place has caught, then a
        ## soft rise to full voice (the room's sound assembles itself).
        var delay := delay_for(pos)
        return smoothstep(delay, delay + 0.35 + span * 0.25, t)

func grade_k() -> float:
        ## The world grade lift: the room begins held-dark and exhales to
        ## full presence (game._apply_world_grade multiplies this in).
        return GRADE_FLOOR + (1.0 - GRADE_FLOOR) * smoothstep(0.0, span * 0.9, t)
