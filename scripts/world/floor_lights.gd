## FloorLights — THE GROUND ANSWERS THE FIRE. The floor's light response,
## drawn ON the walking surface. (The WB-8 production bug: the old floor
## spill in Lights.gd was painted at z=-5 — BURIED under FloorCraft's opaque
## slab courses at z=0 — so the ground never actually received the fire; the
## VLM audit read it as "the floor doesn't interact with the light".)
## Every source now lands a DANCING pool on the flagstones: a wide soft
## spill, a hot core pool, a sheen line catching the dressed course edge,
## a vertical smear under cone lights, and a fixture grounding mark (sconce
## bracket / conduit node) so no glow is ever sourceless.
class_name FloorLights
extends Node2D

var lights: Array = []
var floor_y := -1.0
var _anchors: Array = []       # decor/prop/npc positions (fixtures skip art)
var _t := 0.0

static var _glow_tex: ImageTexture

static func get_glow_texture() -> ImageTexture:
        ## White radial gradient — shared with Lights (soft, band-free).
        if _glow_tex == null:
                var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
                for y in 128:
                        for x in 128:
                                var d := Vector2(float(x) - 63.5, float(y) - 63.5).length() / 64.0
                                var a := pow(clampf(1.0 - d, 0.0, 1.0), 1.7)
                                img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
                _glow_tex = ImageTexture.create_from_image(img)
        return _glow_tex

func setup(p_lights: Array, p_floor_y: float, p_anchors: Array) -> void:
        lights = p_lights
        floor_y = p_floor_y
        _anchors = p_anchors
        z_index = 0               # the ground plane — above floorcraft's
                                  # slabs, under every actor
        set_process(true)
        queue_redraw()

func pool_count() -> int:
        ## How many light pools land on this floor (smoke law: every source
        ## must touch the ground).
        var n := 0
        for l in lights:
                if floor_y > 0.0:
                        n += 1
        return n

func fixture_count() -> int:
        var n := 0
        for l in lights:
                var pos: Vector2 = l["pos"]
                if not _has_fixture_near(pos.x, pos.y):
                        n += 1
        return n

func _has_fixture_near(x: float, y: float) -> bool:
        ## Real art already grounds this glow (brazier, candelabra, machine).
        for a in _anchors:
                if absf(float(a["x"]) - x) < 36.0 and absf(float(a["y"]) - y) < 96.0:
                        return true
        return false

func _process(delta: float) -> void:
        _t += delta
        # ~9 fps: the flame dance reads, the cost stays on the floor
        if fmod(_t, 0.11) < delta:
                queue_redraw()

func _draw() -> void:
        if floor_y < 0.0:
                return
        var glow := get_glow_texture()
        for l in lights:
                var pos: Vector2 = l["pos"]
                var r: float = l["r"]
                var col: Color = l["color"]
                var flicker: float = float(l.get("flicker", 0.0))
                var ph := pos.x * 0.13 + pos.y * 0.07
                var k := 1.0
                if flicker > 0.0:
                        k = 1.0 - flicker * (0.4 + 0.6 * absf(sin(_t * 7.0 + ph)))
                # the flame dances: the pool wobbles beneath its source
                var wob_x := sin(_t * 6.3 + ph) * 2.4 * flicker
                var breathe := 1.0 + 0.06 * sin(_t * 2.3 + ph) * (0.3 + flicker)
                var drop := clampf((floor_y - pos.y) / 500.0, 0.0, 1.0)
                var fx := pos.x + wob_x
                # 1) wide soft spill — the room's floor takes the light
                var rx := r * (0.80 + drop * 0.30) * breathe
                draw_texture_rect(glow, Rect2(Vector2(fx - rx, floor_y - 3.0 - 4.0), Vector2(rx * 2.0, 8.0)), false,
                        Color(col.r, col.g, col.b, 0.11 * k))
                # 2) hot core pool — directly under the source
                var rx2 := r * 0.42 * breathe
                draw_texture_rect(glow, Rect2(Vector2(fx - rx2, floor_y - 3.0 - 2.6), Vector2(rx2 * 2.0, 5.2)), false,
                        Color(col.r, col.g, col.b, 0.10 * k))
                # 3) sheen line — the dressed course edge catches it
                draw_rect(Rect2(fx - rx * 0.8, floor_y + 1.0, rx * 1.6, 1.2),
                        Color(col.r, col.g, col.b, 0.10 * k))
                # 4) cone lights smear their column onto the ground
                if l.has("cone"):
                        var h := floor_y - pos.y
                        if h > 12.0:
                                draw_texture_rect(glow, Rect2(Vector2(fx - r * 0.22, pos.y), Vector2(r * 0.44, h)), false,
                                        Color(col.r, col.g, col.b, 0.045 * k))
                # 5) fixture grounding — no sourceless glows (only where no
                #    painted prop already carries the light)
                if not _has_fixture_near(pos.x, pos.y):
                        if flicker >= 0.25:
                                # an iron sconce: bracket, drip, live wick
                                var by := pos.y + 4.0
                                draw_colored_polygon(PackedVector2Array([
                                        Vector2(pos.x - 3.4, by - 3.0),
                                        Vector2(pos.x + 3.4, by - 3.0),
                                        Vector2(pos.x + 2.2, by + 2.6),
                                        Vector2(pos.x - 2.2, by + 2.6),
                                ]), E0.ASH.darkened(0.32))
                                draw_rect(Rect2(pos.x - 1.2, by + 2.6, 2.4, 2.0),
                                        E0.ASH.darkened(0.42))
                                draw_circle(Vector2(pos.x, pos.y + 1.5), 1.1,
                                        Color(col.r * 1.2 + 0.2, col.g * 1.1 + 0.15, col.b * 0.8, 0.9 * k))
                        else:
                                # a conduit node: plate, core, stubs
                                draw_rect(Rect2(pos.x - 4.0, pos.y - 3.0, 8.0, 6.0),
                                        E0.ASH.darkened(0.38))
                                draw_rect(Rect2(pos.x - 5.4, pos.y - 1.2, 1.6, 2.4),
                                        E0.ASH.darkened(0.30))
                                draw_rect(Rect2(pos.x + 3.8, pos.y - 1.2, 1.6, 2.4),
                                        E0.ASH.darkened(0.30))
                                draw_circle(Vector2(pos.x, pos.y), 1.6,
                                        Color(col.r, col.g, col.b, 0.75 * k))
