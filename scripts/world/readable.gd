## Readable — a piece of the city that can be READ: carved stelae, posted
## law, boundary stones, scripture panels, maintenance stencils, pilgrim
## graffiti. Interact opens the reading surface; OBSERVE reads the record's
## cold opinion of the same object. The two readings never fully agree —
## that is the world. Built from data/readables.json.
class_name Readable
extends EntityNode

var entry: Dictionary = {}

func setup_readable(p_entry: Dictionary) -> void:
        entry = p_entry
        var id := String(entry.get("id", "readable"))
        setup("READABLE", id, "readable", {
                "radius": 34.0,
                "anchor_y": 30.0,
                "br_w": 52.0,
                "br_h": 46.0,
        })

func _ready() -> void:
        super()
        # the record's own view of this object — OBSERVE reads this
        var d := EntityData.new()
        d.key = instance_key
        d.display = String(entry.get("title", "INSCRIPTION"))
        d.id_number = "ENTITY_0" + str(900 + (hash(instance_key) % 90))
        d.type = "RECORD/INSCRIPTION"
        d.state = "READ" if GameState.texts_read.has(instance_key) else "UNREAD"
        d.purpose = "TO BE READ"
        d.memory = String(entry.get("obs", ""))
        d.properties = {
                "inscription": {
                        "value": "PRESENT",
                        "type": "text",
                        "modifiable": false,
                        "cost": 0,
                },
        }
        data = d
        _refresh_prompt()
        queue_redraw()

func _refresh_prompt() -> void:
        if not entry.is_empty():
                prompt = String(entry.get("prompt", "READ"))
        else:
                super()

func interact(game) -> void:
        game.open_reading(self)

# ------------------------------------------------------------------ drawing
func _draw() -> void:
        var kind := String(entry.get("kind", "stele"))
        match kind:
                "stele":
                        _draw_stele()
                "posted":
                        _draw_posted()
                "boundary":
                        _draw_boundary()
                "stencil":
                        _draw_stencil()
                "graffiti":
                        _draw_graffiti()
                "scripture":
                        _draw_scripture()
                "record_page":
                        _draw_page()
                "wall_sheet":
                        _draw_wall_sheet()
                _:
                        _draw_stele()
        # an unread inscription carries a faint reader's mark — the city
        # wants to be read
        if not GameState.texts_read.has(instance_key):
                var pulse := 0.35 + 0.25 * sin(anim_t * 2.2)
                draw_circle(Vector2(0, -64.0), 2.2, Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, pulse))
                draw_arc(Vector2(0, -64.0), 5.5, 0, TAU, 10, Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, pulse * 0.5), 1.0)

func _seed() -> float:
        return fmod(float(abs(hash(instance_key)) % 1000), 97.0) / 97.0

func _draw_stele() -> void:
        ## Standing stone slab with a rounded top; deep-cut lines.
        var s := _seed()
        _contact_shadow(16.0, 0.3)
        var w := 34.0
        var h := 62.0 + 10.0 * s
        var pts := PackedVector2Array([
                Vector2(-w * 0.5, 0), Vector2(-w * 0.5, -h + 10), Vector2(-w * 0.5 + 6, -h),
                Vector2(w * 0.5 - 6, -h), Vector2(w * 0.5, -h + 10), Vector2(w * 0.5, 0),
        ])
        draw_colored_polygon(pts, E0.DIRTY_STONE.darkened(0.06 * s))
        # edge light
        draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[4], pts[5]]), E0.ASH, 1.5)
        # carved lines, worn at top
        for i in 6:
                var lw := (10.0 + 14.0 * _seeded(i)) * (1.0 - 0.35 * s * float(i) / 6.0)
                draw_rect(Rect2(-11 + 22.0 * _seeded(i + 3), -h + 14.0 + i * 7.5, lw, 2), Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.30 - 0.02 * i))

func _contact_shadow(half_w: float, strength: float) -> void:
        var n := 8
        var pts := PackedVector2Array()
        for i in n:
                var a := PI * i / float(n - 1)
                pts.append(Vector2(cos(a) * half_w, -sin(a) * half_w * 0.22))
        draw_colored_polygon(pts, Color(0.02, 0.02, 0.03, strength))

func _draw_posted() -> void:
        ## Posted law: a heavy framed board — civic scripture.
        var s := _seed()
        _contact_shadow(24.0, 0.34)
        draw_rect(Rect2(-24, -66, 48, 66), E0.CHARCOAL)
        draw_rect(Rect2(-21, -63, 42, 60), E0.DIRTY_STONE.darkened(0.22 + 0.08 * s))
        # frame studs
        for corner in [Vector2(-18, -60), Vector2(15, -60), Vector2(-18, -3), Vector2(15, -3)]:
                draw_circle(corner, 1.8, E0.ASH)
        # the carved commandment — two heavy lines
        draw_rect(Rect2(-15, -50, 30, 3), Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, 0.5))
        draw_rect(Rect2(-12, -42, 24, 3), Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, 0.4))
        # stamped law line beneath
        for i in 2:
                draw_rect(Rect2(-13, -30 + i * 5, 20.0 - 6.0 * i, 2), Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.30))
        # hand margin scrawl
        draw_rect(Rect2(-10, -18, 17, 1.5), Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.35))
        draw_rect(Rect2(-8, -15, 12, 1.5), Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.28))

func _draw_boundary() -> void:
        ## Short ward stone — squat, immovable, administrative.
        var s := _seed()
        _contact_shadow(14.0, 0.3)
        draw_rect(Rect2(-14, -40, 28, 40), E0.DIRTY_STONE)
        draw_rect(Rect2(-17, -46, 34, 8), E0.DIRTY_STONE.darkened(0.12))
        draw_rect(Rect2(-17, -4, 34, 4), E0.DIRTY_STONE.darkened(0.2))
        for i in 3:
                var lw := 12.0 + 8.0 * _seeded(i)
                draw_rect(Rect2(-11, -34 + i * 8, lw, 2), Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.3 - 0.04 * i))
        # ward glyph
        draw_arc(Vector2(0, -22), 4.0, 0, TAU, 8, Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.35), 1.0)

func _draw_stencil() -> void:
        ## Industrial spray-stencil on the wall behind — no frame, no honor.
        var s := _seed()
        # rough paint rect
        draw_rect(Rect2(-26, -70, 52, 54), Color(E0.ASH.r, E0.ASH.g, E0.ASH.b, 0.16))
        draw_rect(Rect2(-26, -70, 52, 2), Color(E0.BLOOD.r, E0.BLOOD.g, E0.BLOOD.b, 0.55))
        draw_rect(Rect2(-26, -20, 52, 2), Color(E0.BLOOD.r, E0.BLOOD.g, E0.BLOOD.b, 0.5))
        # spray letters: heavy block strokes
        var spray := Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.5 + 0.15 * s)
        for i in 2:
                draw_rect(Rect2(-19, -56 + i * 16, 38, 8), spray)
        # hazard ticks
        for i in 4:
                draw_rect(Rect2(-19 + i * 10, -34, 6, 2), Color(E0.BLOOD.r, E0.BLOOD.g, E0.BLOOD.b, 0.4))

func _draw_graffiti() -> void:
        ## Scratched low — no frame, no official surface, just the wall.
        var s := _seed()
        var col := Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.4)
        var n := 3
        for i in n:
                var y := -14.0 - i * 7.0 * (0.6 + 0.4 * s)
                var x0 := -12.0 + 4.0 * _seeded(i)
                var x1 := x0 + 12.0 + 10.0 * _seeded(i + 4)
                draw_line(Vector2(x0, y), Vector2(x1, y + 1.5 * s), col, 1.2)
        # a small strike or underline
        draw_line(Vector2(-10, -4), Vector2(8, -5), Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.25), 1.0)

func _draw_scripture() -> void:
        ## Vellum scripture panel — warm parchment on a carved seat.
        _contact_shadow(20.0, 0.28)
        draw_rect(Rect2(-20, -58, 40, 50), E0.DIRTY_STONE.darkened(0.1))
        draw_rect(Rect2(-16, -54, 32, 42), Color(E0.PARCH.r * 0.55, E0.PARCH.g * 0.55, E0.PARCH.b * 0.55, 0.9))
        # versicle lines, uneven like handwriting
        for i in 4:
                var lw := 18.0 - 3.0 * float(i % 2) - 2.0 * _seeded(i)
                draw_rect(Rect2(-12, -48 + i * 9, lw, 1.8), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.55))
        # a gold leaf corner — chapel grade
        draw_rect(Rect2(-20, -58, 40, 3), Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.4))

func _draw_page() -> void:
        ## A loose record page, slightly rotated where it fell.
        var s := _seed()
        _contact_shadow(13.0, 0.22)
        draw_set_transform(Vector2.ZERO, (s - 0.5) * 0.5, Vector2.ONE)
        draw_rect(Rect2(-13, -9, 26, 9), Color(E0.PARCH.r * 0.6, E0.PARCH.g * 0.6, E0.PARCH.b * 0.6, 0.85))       # fold below the floor line
        draw_rect(Rect2(-13, -30, 26, 22), Color(E0.PARCH.r * 0.75, E0.PARCH.g * 0.75, E0.PARCH.b * 0.75, 0.92))  # page body
        for i in 4:
                draw_rect(Rect2(-10, -26 + i * 5, 18.0 - 4.0 * (i % 2), 1.4), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.5))
        # stamp corner
        draw_rect(Rect2(2, -13, 8, 5), Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.35))
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_wall_sheet() -> void:
        ## A metal sheet bolted flat to the wall — the cradle roster.
        var s := _seed()
        draw_rect(Rect2(-19, -58, 38, 50), E0.ASH.darkened(0.05))
        draw_rect(Rect2(-16, -55, 32, 44), E0.CHARCOAL)
        for corner in [Vector2(-16, -55), Vector2(13, -55), Vector2(-16, -12), Vector2(13, -12)]:
                draw_circle(corner + Vector2(1.5, 1.5), 1.5, E0.DIRTY_STONE)
        # roster rows
        for i in 4:
                var y := -48.0 + i * 9
                draw_rect(Rect2(-12, y, 20, 2), Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.32 - 0.05 * i))
                draw_rect(Rect2(9, y, 3, 2), Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, 0.35))
