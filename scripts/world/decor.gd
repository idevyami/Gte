## Decor — 16 kinds of gothic-industrial set dressing. The eight hero kinds
## (column, arch, banner, statue, censer, mural, machine, bones — 75 of ~105
## placements) draw from painted, palette-locked art (art/props/decor_*.png);
## the remainder (chains, cages, bells, pipes, vents, cables, candles, glyphs)
## stay procedural micro-detail. If the painted art is missing, or F9 disables
## sprite art, every kind falls back to its fully procedural rendering.
## At stage 2+ some pieces are displaced or duplicated (the environment
## disagreeing with itself); at stage 5 pieces tear outright.
class_name Decor
extends Node2D

var items: Array = []     # {kind, pos, w, h, s(seed), extra}
var _last_stage := 1

const KINDS := [
        "column", "arch", "banner", "statue_kneel", "chain_hang", "cage_hang",
        "censer_swing", "pipe", "vent", "cable", "bell", "mural", "bones",
        "candles", "glyph_row", "machine",
]

const DECOR_TEX_PATHS := {
        "column": "res://art/props/decor_column.png",
        "column_cap": "res://art/props/decor_column_cap.png",
        "column_shaft": "res://art/props/decor_column_shaft.png",
        "column_base": "res://art/props/decor_column_base.png",
        "machine": "res://art/props/decor_machine.png",
        "banner": "res://art/props/decor_banner.png",
        "statue_kneel": "res://art/props/decor_statue.png",
        "arch": "res://art/props/decor_arch.png",
        "mural": "res://art/props/decor_mural.png",
        "censer_swing": "res://art/props/decor_censer.png",
        "bones": "res://art/props/decor_bones.png",
}

static var _tex_cache := {}

static func _tex(key: String) -> Texture2D:
        if not _tex_cache.has(key):
                var t: Texture2D = null
                var path: String = DECOR_TEX_PATHS.get(key, "")
                if path != "" and ResourceLoader.exists(path):
                        t = load(path)
                _tex_cache[key] = t
        return _tex_cache[key]

func setup(p_items: Array) -> void:
        items = p_items
        _last_stage = GameState.stage
        queue_redraw()

func _process(_delta: float) -> void:
        if GameState.stage != _last_stage:
                _last_stage = GameState.stage
                queue_redraw()

func _offset_for(item: Dictionary) -> Vector2:
        ## Environmental inconsistencies: the same decor, slightly wrong.
        var stage: int = GameState.stage
        if stage < 2:
                return Vector2.ZERO
        var j: float = item.get("s", 0.5)
        if stage >= 2 and j > 0.78:
                return Vector2((j - 0.78) * 70.0, 0.0)
        if stage >= 5 and j > 0.9:
                return Vector2(0.0, -14.0)
        return Vector2.ZERO

func _sprites_on() -> bool:
        return not GameState.debug_no_sprites

func _draw() -> void:
        var stage: int = GameState.stage
        for item in items:
                var kind: String = item["kind"]
                var pos: Vector2 = item["pos"] + _offset_for(item)
                var w: float = item.get("w", 40.0)
                var h: float = item.get("h", 100.0)
                var s: float = item.get("s", 0.5)
                # ghost duplicate at S2+ — a copy of the decor that shouldn't be there
                if stage >= 2 and s > 0.88:
                        _ghost(pos + Vector2(12.0, 2.0))
                match kind:
                        "column":
                                if _sprites_on() and _tex("column_cap") != null and _tex("column_shaft") != null and _tex("column_base") != null:
                                        _column_painted(pos, w, h, s)
                                else:
                                        _column(pos, w, h)
                        "arch":
                                if _sprites_on() and _tex("arch") != null:
                                        _arch_painted(pos, w)
                                else:
                                        _arch(pos, w, h)
                        "banner":
                                if _sprites_on() and _tex("banner") != null:
                                        _banner_painted(pos, w, h, s)
                                else:
                                        _banner(pos, w, h, s)
                        "statue_kneel":
                                if _sprites_on() and _tex("statue_kneel") != null:
                                        _statue_painted(pos, s)
                                else:
                                        _statue(pos, s)
                        "chain_hang":
                                _chain(pos, h)
                        "cage_hang":
                                _cage(pos, h)
                        "censer_swing":
                                if _sprites_on() and _tex("censer_swing") != null:
                                        _censer_painted(pos, h)
                                else:
                                        _censer(pos, h)
                        "pipe":
                                _pipe(pos, w, h)
                        "vent":
                                _vent(pos, w)
                        "cable":
                                _cable(pos, w, h, s)
                        "bell":
                                _bell(pos, s)
                        "mural":
                                if _sprites_on() and _tex("mural") != null:
                                        _mural_painted(pos, w, h)
                                else:
                                        _mural(pos, w, h)
                        "bones":
                                if _sprites_on() and _tex("bones") != null:
                                        _bones_painted(pos, w, s)
                                else:
                                        _bones(pos, w, s)
                        "candles":
                                _candles(pos, w, s)
                        "glyph_row":
                                _glyphs(pos, w)
                        "machine":
                                if _sprites_on() and _tex("machine") != null:
                                        _machine_painted(pos, w, h, s)
                                else:
                                        _machine(pos, w, h, s)

func _ghost(pos: Vector2) -> void:
        draw_rect(Rect2(pos.x - 20, pos.y - 60, 40, 60), Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.05))

# ------------------------------------------------------------ painted decor

func _contact_shadow(pos: Vector2, half_w: float, strength := 0.4) -> void:
        ## Soft grounding ellipse under floor-standing props.
        var n := 10
        var pts := PackedVector2Array()
        for i in n:
                var a := PI * i / float(n - 1)
                pts.append(pos + Vector2(cos(a) * half_w, -sin(a) * half_w * 0.22))
        draw_colored_polygon(pts, Color(0.02, 0.02, 0.03, strength))

func _column_painted(pos: Vector2, w: float, h: float, s: float) -> void:
        ## Three-slice column: carved capital + stretched plain shaft + plinth.
        ## Per-seed brightness keeps repeats of the same texture from reading
        ## as clones.
        _contact_shadow(pos, w * 1.35, 0.34 + 0.1 * s)
        var mod := Color(0.88 + 0.2 * s, 0.88 + 0.2 * s, 0.88 + 0.2 * s)
        var cap_h := 34.0
        var base_h := 26.0
        var cap_w := w * 1.44
        draw_texture_rect(_tex("column_cap"), Rect2(pos.x - cap_w * 0.5, pos.y - h, cap_w, cap_h), false, mod)
        draw_texture_rect(_tex("column_shaft"), Rect2(pos.x - w * 0.5, pos.y - h + cap_h, w, h - cap_h - base_h), false, mod)
        var base_w := w * 1.3
        draw_texture_rect(_tex("column_base"), Rect2(pos.x - base_w * 0.5, pos.y - base_h, base_w, base_h), false, mod)

func _arch_painted(pos: Vector2, w: float) -> void:
        ## Monumental arch at the painting's own aspect, feet on the floor line.
        var t := _tex("arch")
        var draw_h := w * float(t.get_height()) / float(t.get_width())
        _contact_shadow(pos + Vector2(-w * 0.36, 0.0), w * 0.16, 0.3)
        _contact_shadow(pos + Vector2(w * 0.36, 0.0), w * 0.16, 0.3)
        draw_texture_rect(t, Rect2(pos.x - w * 0.5, pos.y - draw_h, w, draw_h), false)

func _banner_painted(pos: Vector2, w: float, h: float, s: float) -> void:
        ## Hanging cloth, swinging gently from its hang point; the violet
        ## variant is a cold modulate of the crimson painting. A soft offset
        ## dark copy behind it reads as the shadow it casts on the wall.
        var t := _tex("banner")
        var tw := float(t.get_width())
        var th := float(t.get_height())
        var draw_w := h * tw / th          # aspect-true; w only sizes the rod span
        var sway := sin(Time.get_ticks_msec() * 0.001 + s * 6.0) * 0.045
        var mod := Color(1, 1, 1) if s > 0.5 else Color(0.74, 0.70, 1.0)
        draw_set_transform(pos, sway, Vector2.ONE)
        draw_texture_rect(t, Rect2(-draw_w * 0.5 + 7.0, 6.0, draw_w, h), false, Color(0.02, 0.02, 0.03, 0.38))
        draw_texture_rect(t, Rect2(-draw_w * 0.5, 0.0, draw_w, h), false, mod)
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        draw_line(Vector2(pos.x - w * 0.5 - 4, pos.y), Vector2(pos.x + w * 0.5 + 4, pos.y), E0.GOLD.darkened(0.4), 2.0)

func _statue_painted(pos: Vector2, s: float) -> void:
        ## Kneeling penitent; every statue faces slightly the wrong way (the
        ## painting mirrors by seed).
        var t := _tex("statue_kneel")
        var tw := float(t.get_width())
        var th := float(t.get_height())
        var face_dir := 1.0 if s > 0.5 else -1.0
        _contact_shadow(pos, tw * 0.55, 0.38 + 0.08 * s)
        draw_set_transform(pos, 0.0, Vector2(face_dir, 1.0))
        draw_texture_rect(t, Rect2(-tw * 0.5, -th, tw, th), false)
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _censer_painted(pos: Vector2, h: float) -> void:
        ## Hanging censer on its chains, rotating around the ceiling pivot.
        var t := _tex("censer_swing")
        var tw := float(t.get_width())
        var th := float(t.get_height())
        var draw_w := h * tw / th
        var swing := sin(Time.get_ticks_msec() * 0.0012 + pos.x * 0.02) * 0.18
        draw_set_transform(pos, swing, Vector2.ONE)
        draw_texture_rect(t, Rect2(-draw_w * 0.5, 0.0, draw_w, h), false)
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        for i in 3:
                var t2 := fmod(Time.get_ticks_msec() * 0.0004 + i * 0.33, 1.0)
                var end := pos + Vector2(sin(swing) * h, cos(swing) * h)
                draw_circle(end + Vector2(sin(t2 * TAU) * 5.0, -t2 * 26.0), 2.5 - t2 * 1.5, Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, (1.0 - t2) * 0.2))

func _mural_painted(pos: Vector2, w: float, h: float) -> void:
        ## Wall panel: the eleven saints in procession, plaster and all. A
        ## carved stone frame and a base shadow seat it into the wall.
        _contact_shadow(pos + Vector2(0.0, -2.0), w * 0.52, 0.3)
        var frame := 7.0
        draw_rect(Rect2(pos.x - frame, pos.y - h - frame, w + frame * 2.0, h + frame * 2.0), E0.DIRTY_STONE)
        draw_texture_rect(_tex("mural"), Rect2(pos.x, pos.y - h, w, h), false)
        # top and side shading strips to fold the panel into the wall light
        draw_rect(Rect2(pos.x - frame, pos.y - h - frame, w + frame * 2.0, frame + 3.0), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.35))
        draw_rect(Rect2(pos.x - frame, pos.y - h - frame, frame, h + frame * 2.0), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.28))
        draw_rect(Rect2(pos.x + w, pos.y - h - frame, frame, h + frame * 2.0), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.28))

func _bones_painted(pos: Vector2, w: float, s: float) -> void:
        ## Scatter of remains along the floor line.
        var t := _tex("bones")
        var draw_h := w * float(t.get_height()) / float(t.get_width())
        var mod := Color(1, 1, 1, 0.82 + 0.14 * s)
        _contact_shadow(pos, w * 0.48, 0.22)
        draw_texture_rect(t, Rect2(pos.x - w * 0.5, pos.y - draw_h, w, draw_h), false, mod)

func _machine_painted(pos: Vector2, w: float, h: float, s: float) -> void:
        ## Painted reliquary-engine body with the live procedural instrumentation
        ## (cycling gauges, blinking fault lights) drawn over it.
        _contact_shadow(pos, w * 0.62, 0.42 + 0.08 * s)
        draw_texture_rect(_tex("machine"), Rect2(pos.x, pos.y - h, w, h), false)
        for i in 3:
                var gauge_y := pos.y - h + 14.0 + i * (h - 28.0) / 3.0
                var v := 0.3 + 0.2 * sin(Time.get_ticks_msec() * 0.003 + i * 2.0 + s * 7.0)
                draw_rect(Rect2(pos.x + 8, gauge_y, w - 16, 3), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.65))
                draw_rect(Rect2(pos.x + 8, gauge_y, (w - 16) * v, 3), Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.5))
        for i in 2:
                draw_circle(Vector2(pos.x + w - 10.0, pos.y - h + 12.0 + i * 12.0), 2.5, Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.4 + 0.2 * sin(Time.get_ticks_msec() * 0.004 + i)))
        draw_rect(Rect2(pos.x - 4, pos.y - 6, w + 8, 6), E0.DIRTY_STONE)

# ------------------------------------------------------- procedural fallback

func _column(pos: Vector2, w: float, h: float) -> void:
        draw_rect(Rect2(pos.x - w * 0.5, pos.y - h, w, h), E0.DIRTY_STONE.darkened(0.05))
        draw_rect(Rect2(pos.x - w * 0.5 - 4, pos.y - h, w + 8, 10), E0.DIRTY_STONE)
        draw_rect(Rect2(pos.x - w * 0.5 - 4, pos.y - 12, w + 8, 12), E0.DIRTY_STONE)
        for i in 3:
                draw_line(Vector2(pos.x - w * 0.5 + 4, pos.y - h + 14 + i * h * 0.3), Vector2(pos.x - w * 0.5 + 4, pos.y - h + 30 + i * h * 0.3), E0.VOID, 1.5)

func _arch(pos: Vector2, w: float, h: float) -> void:
        var pts := PackedVector2Array()
        var steps := 12
        for i in steps:
                var a := PI - PI * i / float(steps - 1)
                pts.append(pos + Vector2(cos(a) * w * 0.5, -h - sin(a) * h * 0.55))
        for i in steps:
                var a := PI - PI * i / float(steps - 1)
                pts.append(pos + Vector2(cos(a) * (w * 0.5 - 10.0), -h - sin(a) * (h * 0.55 - 9.0)))
        draw_colored_polygon(pts, E0.DIRTY_STONE.darkened(0.12))

func _banner(pos: Vector2, w: float, h: float, s: float) -> void:
        var sway := sin(Time.get_ticks_msec() * 0.001 + s * 6.0) * 3.0
        var col := E0.BLOOD if s > 0.5 else E0.VIOLET.darkened(0.2)
        var pts := PackedVector2Array([
                Vector2(pos.x - w * 0.5, pos.y), Vector2(pos.x + w * 0.5, pos.y),
                Vector2(pos.x + w * 0.5 + sway, pos.y + h), Vector2(pos.x - w * 0.5 + sway, pos.y + h - 8.0),
        ])
        draw_colored_polygon(pts, Color(col.r, col.g, col.b, 0.85))
        draw_line(Vector2(pos.x - w * 0.5 - 4, pos.y), Vector2(pos.x + w * 0.5 + 4, pos.y), E0.GOLD.darkened(0.4), 2.0)
        # sigil: the measured eye
        draw_circle(Vector2(pos.x + sway * 0.5, pos.y + h * 0.4), w * 0.16, Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.4))
        draw_rect(Rect2(pos.x - 1.0 + sway * 0.5, pos.y + h * 0.38, 2.0, w * 0.1), E0.VOID)

func _statue(pos: Vector2, s: float) -> void:
        var stone := E0.DIRTY_STONE.lightened(0.03)
        draw_rect(Rect2(pos.x - 26, pos.y - 8, 52, 8), stone.darkened(0.1))
        draw_colored_polygon(PackedVector2Array([
                pos + Vector2(-12, -8), pos + Vector2(12, -8), pos + Vector2(14, -52), pos + Vector2(-14, -52),
        ]), stone)
        draw_circle(pos + Vector2(0, -58), 9.0, stone)
        # every statue faces slightly the wrong way
        var face_dir := 1.0 if s > 0.5 else -1.0
        draw_rect(Rect2(pos.x - 4.0 * face_dir, -60.0 + pos.y, 8, 6), E0.VOID)
        draw_rect(Rect2(pos.x - 20, pos.y - 66, 40, 7), stone.darkened(0.08))

func _chain(pos: Vector2, h: float) -> void:
        var links := maxi(3, int(h / 18.0))
        for i in links:
                var y := pos.y + i * 18.0
                var sway := sin(i * 0.7 + pos.x * 0.01) * 2.0
                draw_arc(Vector2(pos.x + sway, y), 4.0, 0, TAU, 8, E0.ASH, 2.0)
        draw_circle(Vector2(pos.x, pos.y + links * 18.0 + 6.0), 6.0, E0.DIRTY_STONE)

func _cage(pos: Vector2, h: float) -> void:
        _chain(pos, h)
        var top := pos.y + h + 10.0
        draw_rect(Rect2(pos.x - 14, top, 28, 3), E0.ASH)
        for i in 4:
                draw_line(Vector2(pos.x - 14 + i * 9.3, top), Vector2(pos.x - 14 + i * 9.3, top + 26), E0.ASH, 1.5)
        draw_rect(Rect2(pos.x - 14, top + 26, 28, 3), E0.ASH)

func _censer(pos: Vector2, h: float) -> void:
        var swing := sin(Time.get_ticks_msec() * 0.0012 + pos.x * 0.02) * 0.18
        var pivot := pos + Vector2(0, 0)
        var end := pivot + Vector2(sin(swing) * h, cos(swing) * h)
        draw_line(pivot, end, E0.ASH, 1.5)
        draw_colored_polygon(PackedVector2Array([
                end + Vector2(-8, 0), end + Vector2(8, 0), end + Vector2(5, 10), end + Vector2(-5, 10),
        ]), E0.GOLD.darkened(0.4))
        for i in 3:
                var t := fmod(Time.get_ticks_msec() * 0.0004 + i * 0.33, 1.0)
                draw_circle(end + Vector2(sin(t * TAU) * 5.0, -t * 26.0), 2.5 - t * 1.5, Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, (1.0 - t) * 0.2))

func _pipe(pos: Vector2, w: float, h: float) -> void:
        draw_rect(Rect2(pos.x, pos.y - h, w, h), E0.ASH.darkened(0.05))
        draw_rect(Rect2(pos.x, pos.y - h, w, 6), E0.ASH.lightened(0.08))
        for i in int(h / 50.0):
                draw_rect(Rect2(pos.x - 3, pos.y - h + 25 + i * 50, w + 6, 8), E0.DIRTY_STONE)
        if h > 80:
                draw_circle(Vector2(pos.x + w * 0.5, pos.y - h * 0.4), 5.0, E0.DIRTY_STONE)

func _vent(pos: Vector2, w: float) -> void:
        draw_rect(Rect2(pos.x, pos.y, w, 18), E0.ASH)
        for i in 4:
                draw_rect(Rect2(pos.x + 3, pos.y + 3 + i * 4, w - 6, 2), E0.VOID)

func _cable(pos: Vector2, w: float, h: float, s: float) -> void:
        var pts := PackedVector2Array()
        var steps := 8
        for i in steps + 1:
                var t := float(i) / steps
                var sag := sin(t * PI) * h
                pts.append(pos + Vector2(w * t, sag + sin(t * 7.0 + s * 6.0) * 2.0))
        for i in steps:
                draw_line(pts[i], pts[i + 1], E0.ASH, 2.0)

func _bell(pos: Vector2, s: float) -> void:
        draw_rect(Rect2(pos.x - 26, pos.y, 52, 6), E0.DIRTY_STONE)
        draw_line(Vector2(pos.x, pos.y), Vector2(pos.x, pos.y + 16), E0.ASH, 2.0)
        var swing := sin(Time.get_ticks_msec() * 0.001 + s * 6.0) * 0.06
        var dir := Vector2(sin(swing), cos(swing))
        var top := Vector2(pos.x, pos.y + 16)
        draw_colored_polygon(PackedVector2Array([
                top + dir * 4.0 + Vector2(-14, 0), top + dir * 4.0 + Vector2(14, 0),
                top + dir * 26.0 + Vector2(9, 0), top + dir * 26.0 + Vector2(-9, 0),
        ]), E0.ASH.lightened(0.05))

func _mural(pos: Vector2, w: float, h: float) -> void:
        draw_rect(Rect2(pos.x, pos.y - h, w, h), E0.VIOLET.darkened(0.45))
        # eleven saints in procession — count them
        var n := 11
        for i in n:
                var sx := pos.x + 8.0 + (w - 16.0) * i / float(n - 1)
                var sy := pos.y - 12.0
                draw_colored_polygon(PackedVector2Array([
                        Vector2(sx - 4, sy), Vector2(sx + 4, sy), Vector2(sx + 5, sy - 20.0), Vector2(sx - 5, sy - 20.0),
                ]), Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, 0.5))
                draw_circle(Vector2(sx, sy - 24.0), 3.0, Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, 0.5))
                draw_line(Vector2(sx, sy - 30.0), Vector2(sx, sy - 36.0), Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.4), 1.0)
        # the halo of the design
        draw_arc(Vector2(pos.x + w * 0.5, pos.y - h * 0.85), 18.0, 0, TAU, 14, Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.35), 2.0)

func _bones(pos: Vector2, w: float, s: float) -> void:
        var rng := RandomNumberGenerator.new()
        rng.seed = hash(str(int(pos.x)) + str(s))
        for i in 7:
                var bx := pos.x + rng.randf() * w
                var by := pos.y - rng.randf() * 4.0
                var bl := 6.0 + rng.randf() * 8.0
                var a := rng.randf() * PI
                draw_line(Vector2(bx, by), Vector2(bx + cos(a) * bl, by + sin(a) * bl * 0.3), Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.5), 2.0)
                draw_circle(Vector2(bx, by), 2.2, Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.5))
                draw_circle(Vector2(bx + cos(a) * bl, by + sin(a) * bl * 0.3), 2.2, Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.5))

func _candles(pos: Vector2, w: float, s: float) -> void:
        var rng := RandomNumberGenerator.new()
        rng.seed = hash(str(int(pos.y)) + str(s))
        var n := maxi(3, int(w / 24.0))
        for i in n:
                var cx := pos.x + 6.0 + (w - 12.0) * i / float(n - 1)
                var ch := 8.0 + rng.randf() * 6.0
                draw_rect(Rect2(cx - 2.5, pos.y - ch, 5, ch), Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.75))
                var flick := 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.006 + i * 2.7 + s * 9.0)
                draw_circle(Vector2(cx, pos.y - ch - 3.0), 2.0, Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, flick))
                draw_circle(Vector2(cx, pos.y - ch - 4.0), 4.5, Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, flick * 0.15))

func _glyphs(pos: Vector2, w: float) -> void:
        var n := int(w / 30.0)
        for i in n:
                var gx := pos.x + i * 30.0 + 8.0
                var gy := pos.y
                var pulse := 0.2 + 0.15 * sin(Time.get_ticks_msec() * 0.002 + i * 1.3)
                match i % 4:
                        0:
                                draw_rect(Rect2(gx - 4, gy - 4, 8, 8), Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, pulse))
                        1:
                                draw_arc(Vector2(gx, gy), 5.0, 0, TAU, 8, Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, pulse), 1.5)
                        2:
                                draw_line(Vector2(gx - 5, gy - 5), Vector2(gx + 5, gy + 5), Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, pulse), 1.5)
                        3:
                                draw_rect(Rect2(gx - 5, gy - 2, 10, 4), Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, pulse))

func _machine(pos: Vector2, w: float, h: float, s: float) -> void:
        draw_rect(Rect2(pos.x, pos.y - h, w, h), E0.CHARCOAL)
        draw_rect(Rect2(pos.x + 4, pos.y - h + 4, w - 8, h - 8), E0.VOID)
        for i in 3:
                var gauge_y := pos.y - h + 14.0 + i * (h - 28.0) / 3.0
                var v := 0.3 + 0.2 * sin(Time.get_ticks_msec() * 0.003 + i * 2.0 + s * 7.0)
                draw_rect(Rect2(pos.x + 8, gauge_y, w - 16, 3), E0.ASH)
                draw_rect(Rect2(pos.x + 8, gauge_y, (w - 16) * v, 3), Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.5))
        for i in 2:
                draw_circle(Vector2(pos.x + w - 10.0, pos.y - h + 12.0 + i * 12.0), 2.5, Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.4 + 0.2 * sin(Time.get_ticks_msec() * 0.004 + i)))
        draw_rect(Rect2(pos.x - 4, pos.y - 6, w + 8, 6), E0.DIRTY_STONE)
