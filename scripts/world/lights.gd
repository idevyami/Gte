## Lights — additive glow pools: candle warmth, cyan veins, machine heat.
## Every source renders through filtered gradient textures (built once):
##   — a radial falloff quad (soft glow, no concentric-ring quantization)
##   — a hot bright core (the wick / vein itself)
##   — a squashed radial pool where the light lands on the floor plane
##   — an optional downward cone (chapel candles, the martyr's arena)
## Flicker handled by low-frequency redraw.
## THE ARRIVAL (WB-11): with a Wake, no source is born lit — each waits as
## an ember, catches with a flare when its distance-order moment arrives
## (near-first from where the vessel stands), and settles. Redraw runs
## every frame while the wake lives, then returns to its thrift cadence.
## THE WORLD THINS (WB-12): as the HUNTED stages drain consistency, every
## source loses CONVICTION — a shared pure multiplier (thin_at) so flame
## and floor-pool fail in the same breath (one thinning per position, the
## WB-11 law applied to decay); living flames grow AGITATED, and past the
## halfway thin a flame sometimes MISSES A BEAT — guttering low for a
## moment as it forgets itself. The floor never drops below legibility.
class_name Lights
extends Node2D

var lights: Array = []
var floor_y := -1.0
var _wake: Wake = null

# ------------------------------------------------------------------ thinning
# (THE WORLD THINS — the shared law of decay; smoke-pinned)

const THIN_CONVICT := 0.32        # max conviction loss (floor 0.68 — readable)
const THIN_MISS_GATE := 0.55      # no flame misses a beat before this
const THIN_MISS_FLOOR := 0.20     # a miss gutters low but never dies

static func _beat_hash(pos: Vector2, win: int) -> float:
        ## Deterministic per-source, per-window hash ∈ [0,1). A REAL mix —
        ## GDScript's String hash (djb2) has almost no avalanche in the last
        ## characters, so a win-suffixed string barely changes across wins
        ## (the beat would freeze position-constant; smoke caught it).
        var s := int(round(pos.x)) * 374761393 + int(round(pos.y)) * 668265263 \
                        + win * 2246822519
        s = (s ^ (s >> 13)) * 1274126177
        s = s ^ (s >> 16)
        return float(absi(s) % 10000) / 10000.0

static func thin_at(pos: Vector2, flicker: float, th: float, t: float) -> float:
        ## THE WORLD THINS: the per-source thinning multiplier — a PURE
        ## FUNCTION of position, flicker, thinning and time, so Lights and
        ## FloorLights derive the SAME decay (one thinning per position).
        ## th=0 → 1.0 (the world is itself). Conviction loss is universal;
        ## MISSED BEATS belong to living flame only (flicker > 0.15) and
        ## only past the gate — the district machines just dim, the fires
        ## gutter. Deterministic: same args, same value, every caller.
        if th <= 0.001:
                return 1.0
        var f := 1.0 - THIN_CONVICT * th
        if flicker > 0.15 and th > THIN_MISS_GATE:
                # ~0.31s windows: a miss holds long enough to READ as a beat;
                # coverage rises past half-thin so several flames stagger
                # at once at the thinnest — the decay must READ as uneven
                var win := int(floor(t * 3.2))
                var coverage := (th - THIN_MISS_GATE) * 1.05
                if _beat_hash(pos, win) < coverage:
                        f = minf(f, THIN_MISS_FLOOR + 0.18 * (1.0 - th))
        return f

static func agitation(flicker: float, th: float) -> float:
        ## Living flames grow nervous as reality thins — the flicker's
        ## inner amplitude rises (bounded; k stays clamped at draw time).
        if flicker <= 0.0:
                return 1.0
        return 1.0 + 0.90 * clampf(th, 0.0, 1.0)

static var _glow_tex: ImageTexture

static func get_glow_texture() -> ImageTexture:
        ## White radial gradient: smooth falloff from centre. Bilinear
        ## filtering keeps it band-free at any scale.
        if _glow_tex == null:
                var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
                for y in 128:
                        for x in 128:
                                var d := Vector2(float(x) - 63.5, float(y) - 63.5).length() / 64.0
                                var a := pow(clampf(1.0 - d, 0.0, 1.0), 1.7)
                                img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
                _glow_tex = ImageTexture.create_from_image(img)
        return _glow_tex

func setup(p_lights: Array, p_floor_y := -1.0, p_wake: Wake = null) -> void:
        lights = p_lights
        floor_y = p_floor_y
        _wake = p_wake
        var mat := CanvasItemMaterial.new()
        mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
        material = mat
        z_index = -5
        queue_redraw()

var _t := 0.0
func _process(delta: float) -> void:
        _t += delta
        if _wake != null and not _wake.done():
                # the wake lives at frame rate — every catch must read
                queue_redraw()
        elif GameState.thinning() > 0.05 and fmod(_t, 0.10) < delta:
                # THE WORLD THINS: a guttering flame lives at ~10fps — the
                # misses must read as beats, not as strobing
                queue_redraw()
        elif fmod(_t, 0.2) < delta:
                queue_redraw()

func _draw() -> void:
        var glow := get_glow_texture()
        var beam := GodRays.get_beam_texture()
        for l in lights:
                var pos: Vector2 = l["pos"]
                var r: float = l["r"]
                var col: Color = l["color"]
                var flicker: float = l.get("flicker", 0.0)
                var th := GameState.thinning()
                var k := 1.0
                if flicker > 0.0:
                        k = 1.0 - flicker * (0.4 + 0.6 * absf(sin(_t * 7.0 + pos.x * 0.13))) \
                                        * agitation(flicker, th)
                        k = clampf(k, 0.25, 1.0)
                # THE ARRIVAL: the source multiplies by its wake factor —
                # ember, catch-flare, settled presence (same pure function
                # the floor pools use, so ground and flame move as one)
                if _wake != null and not _wake.done():
                        k *= _wake.factor_at(pos)
                # THE WORLD THINS: conviction loss + missed beats (the same
                # pure function the floor pools call — one thinning per
                # position, decay in the same breath as the flame)
                if th > 0.001:
                        k *= thin_at(pos, flicker, th, _t)
                # --- radial falloff: one filtered gradient quad
                draw_texture_rect(glow, Rect2(pos - Vector2(r, r), Vector2(r * 2.0, r * 2.0)), false,
                        Color(col.r, col.g, col.b, 0.34 * k))
                # --- hot core: the source itself reads as a lit wick / vein
                for i in 3:
                        var ct := 1.0 - float(i) / 3.0
                        draw_circle(pos, 1.0 + 2.6 * ct, Color(col.r, col.g, col.b, 0.10 * k * ct + 0.05))
                # --- floor spill REMOVED (WB-8): it was drawn here at z=-5,
                # buried under FloorCraft's opaque slabs (z=0) — the ground
                # never received it. FloorLights (z=0, above the slabs) now
                # owns the floor's dancing response to every source.
                # --- optional cone: a shaft of light falling from the source
                if l.has("cone"):
                        var h: float = float(l["cone"])
                        draw_set_transform(pos, 0.0, Vector2(r * 1.5, h))
                        draw_texture_rect(beam, Rect2(Vector2(-0.5, 0.0), Vector2(1.0, 1.0)), false,
                                Color(col.r, col.g, col.b, 0.16 * k))
                        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# ------------------------------------------------------------------ probes
# (smoke laws: the arrival is pinned, not hoped for)

func ignition_delay(i: int) -> float:
        if _wake == null or i < 0 or i >= lights.size():
                return 0.0
        return _wake.delay_for(lights[i]["pos"])

func current_factor(i: int) -> float:
        ## The wake intensity multiplier this source draws with right now
        ## (pure function of wake.t — no draw dependency).
        if _wake == null or i < 0 or i >= lights.size():
                return 1.0
        return _wake.factor_at(lights[i]["pos"])

func thinning_factor(i: int) -> float:
        ## THE WORLD THINS: the thinning multiplier this source draws with
        ## right now (wake-independent — probes the shared decay law).
        if i < 0 or i >= lights.size():
                return 1.0
        var l: Dictionary = lights[i]
        return thin_at(l["pos"], float(l.get("flicker", 0.0)), GameState.thinning(), _t)

func current_factor_at(p_t: float, i: int) -> float:
        ## The same multiplier at an arbitrary wake moment (probe for the
        ## ember-gutter law — no state is touched).
        if _wake == null or i < 0 or i >= lights.size():
                return 1.0
        var keep := _wake.t
        _wake.t = p_t
        var f := _wake.factor_at(lights[i]["pos"])
        _wake.t = keep
        return f
