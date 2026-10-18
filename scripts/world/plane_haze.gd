## PlaneHaze — THE AIR THE CENSERS FILL (WB-22). The honest audit's depth
## finding: at the play plane the chapel's own architecture (the great
## arch, the chandelier, the banners, the pew backs) competes with the dark
## robes — five converged bodies stopped reading as IN FRONT of their room
## at all. The fix is the room's own air: interiors where censers burn
## carry a soft incense band at the height of the bodies that swing them —
## everything behind the actors sits one step deeper in the haze, and the
## walking band's own floor stays clean (the band clears just above the
## floor line, so the crafted surface keeps its full voice).
##
## Drawn at the z=0 plane AFTER every scenery renderer but BEFORE the
## contact shadows (the grounding pools keep their full brightness; the
## actors at z>=1 are above it entirely — the veil never touches a body).
## The texture law banked in the lights pass: one filtered gradient beats
## a stack of primitives.
class_name PlaneHaze
extends Node2D

var fog := Color(0.2, 0.16, 0.12)
var floor_y := -1.0
var width := 2000.0
var peak := 0.13
var _t := 0.0
var _tex: ImageTexture

const TOP_RISE := 330.0   # px above the hold line where the air thins out
const HOLD_TO_FLOOR := 120.0  # the hold line sits this above the floor line
const CLEAR_PAST := 6.0   # the band is fully clear just past the floor line

func setup(p_width: float, p_floor: float, p_fog: Color, p_peak: float) -> void:
        z_index = 0
        width = p_width
        floor_y = p_floor
        fog = p_fog
        peak = p_peak
        var img := Image.create(1, 96, false, Image.FORMAT_RGBA8)
        for y in 96:
                img.set_pixel(0, y, Color(1.0, 1.0, 1.0, _ramp(float(y) / 95.0)))
        _tex = ImageTexture.create_from_image(img)
        set_process(true)

func _ramp(t: float) -> float:
        ## the band's own profile, 0..1 down the texture — thinning in from
        ## above (squared, gentle), holding through the body band, clearing
        ## to nothing just past the floor line. Pure, and lawed.
        var hold := TOP_RISE / (TOP_RISE + HOLD_TO_FLOOR + CLEAR_PAST)
        if t < hold:
                var k := t / hold
                return k * k
        return clampf((1.0 - t) / (1.0 - hold), 0.0, 1.0)

func alpha_at(y: float) -> float:
        ## the veil's strength at a world y — pure, so the smoke laws can
        ## pin the floor line's cleanliness and the body band's presence
        if floor_y < 0.0 or _tex == null:
                return 0.0
        var top := floor_y - TOP_RISE - HOLD_TO_FLOOR
        var h := TOP_RISE + HOLD_TO_FLOOR + CLEAR_PAST
        var t := (y - top) / h
        if t <= 0.0 or t >= 1.0:
                return 0.0
        return _ramp(t) * band_alpha()

func band_alpha() -> float:
        ## the breathing peak — the smoke is living air, never a bar
        return peak * (0.88 + 0.12 * sin(_t * 0.45))

func _process(delta: float) -> void:
        _t += delta
        queue_redraw()

func _draw() -> void:
        if floor_y < 0.0 or _tex == null:
                return
        var top := floor_y - TOP_RISE - HOLD_TO_FLOOR
        var h := TOP_RISE + HOLD_TO_FLOOR + CLEAR_PAST
        # two layered passes, offset and phase-shifted — depth of air, not
        # a mechanical stripe; both breathe on their own slow clocks
        _strip(top, h, band_alpha(), 0.0)
        _strip(top + 52.0, h - 70.0, band_alpha() * 0.65, 2.1)

func _strip(top: float, h: float, a: float, phase: float) -> void:
        var breathe := 1.0 + 0.05 * sin(_t * 0.3 + phase)
        var col := Color(fog.r, fog.g, fog.b, clampf(a * breathe, 0.0, 1.0))
        draw_texture_rect(_tex, Rect2(Vector2(-40.0, top),
                Vector2(width + 80.0, h)), false, col)
