## Decor — gothic-industrial set dressing, ANIMATED. The eight hero kinds
## (column, arch, banner, statue, censer, mural, machine, bones — the
## majority of placements) draw from painted, palette-locked art
## (art/props/decor_*.png); the remainder (chains, cages, bells, pipes,
## vents, cables, candles, glyphs) stay procedural micro-detail — and the
## whole layer redraws every frame: banners ripple in a wind cycle, censers
## swing, candles lean and gutter, machines steam and spark, vents breathe.
## If the painted art is missing, or F9 disables sprite art, every kind falls
## back to its fully procedural rendering.
## At stage 2+ some pieces are displaced or duplicated (the environment
## disagreeing with itself); at stage 5 pieces tear outright.
class_name Decor
extends Node2D

var items: Array = []     # {kind, pos, w, h, s(seed), extra}
var _last_stage := 1
var _t := 0.0             # animation clock (drives every living surface)

const KINDS := [
        "column", "arch", "banner", "statue_kneel", "chain_hang", "cage_hang",
        "censer_swing", "pipe", "vent", "cable", "bell", "mural", "bones",
        "candles", "glyph_row", "machine", "pew", "records", "frieze",
        # — the living-architecture expansion —
        "window", "chandelier", "sconce", "roots", "web", "puddle", "rubble",
        "fan", "lift", "stall", "candelabra",
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
static var _stone_tex: Texture2D

static func _stone() -> Texture2D:
        ## the masonry material tile — the frieze samples it so the beam is
        ## the SAME stone as the floors and walls, not a flat grey strip
        if _stone_tex == null:
                var p := "res://art/environments/tex_stone.png"
                if ResourceLoader.exists(p):
                        _stone_tex = load(p)
        return _stone_tex

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

func _process(delta: float) -> void:
        # the world breathes every frame: banners ripple, flames gutter,
        # machines steam, vents exhale. One canvas item, one redraw — the
        # same budget the midground plane already spends.
        _t += delta
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
                # ghost duplicate at S2+ — a displaced echo of the decor
                # that shouldn't be there (never a flat UI rect)
                if stage >= 2 and s > 0.88:
                        _ghost(pos + Vector2(12.0, 2.0), w, h)
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
                                _vent(pos, w, s)
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
                        "frieze":
                                _frieze(pos, w, h, s)
                        "pew":
                                _pew(pos, w, s)
                        "records":
                                _records(pos, w, s)
                        # ---------------------- living-architecture expansion
                        "window":
                                _window(pos, w, h, s)
                        "chandelier":
                                _chandelier(pos, h, s)
                        "sconce":
                                _sconce(pos, s)
                        "roots":
                                _roots(pos, w, h, s)
                        "web":
                                _web(pos, w, h, s)
                        "puddle":
                                _puddle(pos, w, s)
                        "rubble":
                                _rubble(pos, w, s)
                        "fan":
                                _fan(pos, w, s)
                        "lift":
                                _lift(pos, w, h, s)
                        "stall":
                                _stall(pos, w, s)
                        "candelabra":
                                _candelabra(pos, h, s)

func _ghost(pos: Vector2, w: float, h: float) -> void:
        ## The world disagreeing with itself: a displaced dark echo of the
        ## piece, like a double exposure — never a flat UI-colored rectangle.
        var gw := maxf(w, 36.0)
        var gh := clampf(h, 54.0, 130.0)
        var echo := Color(E0.CYAN.r * 0.4, E0.CYAN.g * 0.4, E0.CYAN.b * 0.5, 0.055)
        draw_rect(Rect2(pos.x - gw * 0.5, pos.y - gh, gw, gh), echo)
        draw_rect(Rect2(pos.x - gw * 0.5 + 2.0, pos.y - gh + 2.0, gw - 4.0, gh - 2.0), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.10))

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
        ## Three-slice column: carved capital + stretched plain shaft + a
        ## TWO-STEP plinth wide enough to carry the visual weight. Per-seed
        ## brightness keeps repeats of the same texture from reading as clones.
        _contact_shadow(pos, w * 1.6, 0.36 + 0.1 * s)
        var mod := Color(0.88 + 0.2 * s, 0.88 + 0.2 * s, 0.88 + 0.2 * s)
        var cap_h := 34.0
        var base_h := 24.0
        var cap_w := w * 1.58
        draw_texture_rect(_tex("column_cap"), Rect2(pos.x - cap_w * 0.5, pos.y - h, cap_w, cap_h), false, mod)
        draw_texture_rect(_tex("column_shaft"), Rect2(pos.x - w * 0.5, pos.y - h + cap_h, w, h - cap_h - base_h), false, mod)
        # carved fluting: dark vertical reeds mask the shaft stretch and read
        # as tooled stone, not a smeared texture
        for i in 3:
                var fx := pos.x - w * 0.5 + w * (0.26 + 0.24 * float(i))
                draw_line(Vector2(fx, pos.y - h + cap_h + 3.0), Vector2(fx, pos.y - base_h - 3.0), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.22), 1.4)
        draw_line(Vector2(pos.x - w * 0.5 + 2.0, pos.y - h + cap_h + 3.0), Vector2(pos.x - w * 0.5 + 2.0, pos.y - base_h - 3.0), Color(0.9, 0.88, 0.82, 0.10), 1.2)
        # two-step plinth: upper step + wider footing
        draw_texture_rect(_tex("column_base"), Rect2(pos.x - w * 0.75, pos.y - base_h, w * 1.5, base_h * 0.6), false, mod)
        draw_texture_rect(_tex("column_base"), Rect2(pos.x - w * 1.0, pos.y - base_h * 0.42, w * 2.0, base_h * 0.42), false, mod.darkened(0.08))

# the arch painting's portal axis and visible span, as fractions of canvas
# width (measured from alpha): the structure is NOT centered in its canvas —
# anchoring the full canvas would shift every arch ~16% left of its mark
const ARCH_AXIS := 0.331
const ARCH_SPAN := 0.681

func _arch_painted(pos: Vector2, w: float) -> void:
        ## Monumental arch, RE-ANCHORED so pos.x marks the real portal center
        ## and w the real visible width; feet on the floor line. The opening is
        ## never a dead void: a cloister breathes beyond it (drawn BEFORE the
        ## texture, so it shows only through the portal's transparent throat).
        var t := _tex("arch")
        var rect_w := w / ARCH_SPAN
        var draw_h := rect_w * float(t.get_height()) / float(t.get_width())
        var x0 := pos.x - ARCH_AXIS * rect_w
        _contact_shadow(pos + Vector2(-w * 0.35, 0.0), w * 0.17, 0.3)
        _contact_shadow(pos + Vector2(w * 0.35, 0.0), w * 0.17, 0.3)
        _arch_interior(pos, w, draw_h * 0.88)
        draw_texture_rect(t, Rect2(x0, pos.y - draw_h, rect_w, draw_h), false)

func _arch_interior(pos: Vector2, w: float, h: float) -> void:
        ## The room beyond the arch: deep shadow with a warm/cold breath
        ## rising from its floor, tiny candle glints, and the faint
        ## suggestion of a farther passage — light leaking from a room
        ## that keeps its own hours. Deterministic per arch position.
        var rng := RandomNumberGenerator.new()
        rng.seed = hash("archfill:" + str(int(pos.x)))
        var warm := rng.randf() < 0.55
        var ix0 := pos.x - w * 0.27
        var iw := w * 0.54
        # the depth itself: near-black, a touch denser than the backdrop
        draw_rect(Rect2(ix0, pos.y - h, iw, h), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.30))
        # a farther passage: vertical slit, faintly lighter
        draw_rect(Rect2(pos.x - w * 0.045, pos.y - h * 0.86, w * 0.09, h * 0.86),
                Color(E0.ASH.r, E0.ASH.g, E0.ASH.b, 0.10))
        # the breath: glow pooled on the room's own floor, fading upward
        var gcol := Color(E0.GOLD.r, E0.GOLD.g * 0.9, E0.GOLD.b * 0.6) if warm \
                else Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b * 0.9)
        for i in 4:
                var t := float(i) / 4.0
                draw_rect(Rect2(ix0, pos.y - 4.0 - t * 26.0, iw, 26.0),
                        Color(gcol.r, gcol.g, gcol.b, 0.075 * (1.0 - t * 0.62)))
        # candle glints beyond — two or three, breathing out of phase
        var n := 2 + (rng.randi() % 2)
        for i in n:
                var gx := ix0 + iw * rng.randf_range(0.18, 0.82)
                var gy := pos.y - h * rng.randf_range(0.18, 0.42)
                var fl := 0.6 + 0.4 * sin(_t * (1.1 + 0.4 * i) + float(i) * 2.4 + rng.randf() * TAU)
                draw_rect(Rect2(gx - 1.0, gy - 2.4, 2.0, 4.8),
                        Color(gcol.r, gcol.g, gcol.b, 0.30 * fl))
                draw_rect(Rect2(gx - 2.6, gy - 4.6, 5.2, 9.2),
                        Color(gcol.r, gcol.g, gcol.b, 0.05 * fl))

func _banner_painted(pos: Vector2, w: float, h: float, s: float) -> void:
        ## Hanging cloth in a wind cycle: the whole banner pivots gently at
        ## its rod while a travelling ripple runs down the fabric — drawn as
        ## vertical texture slices, each offset a little further down the
        ## wave, so the cloth READS as cloth (it bends, it does not slide).
        ## The violet variant is a cold modulate of the crimson painting.
        var t := _tex("banner")
        var tw := float(t.get_width())
        var th := float(t.get_height())
        var draw_w := h * tw / th          # aspect-true; w only sizes the rod span
        var sway := sin(_t * 0.9 + s * 6.0) * 0.038
        var mod := Color(1, 1, 1) if s > 0.5 else Color(0.74, 0.70, 1.0)
        # the shadow it casts on the wall behind it (static, grounded)
        draw_set_transform(pos, sway * 0.6, Vector2.ONE)
        draw_texture_rect(t, Rect2(-draw_w * 0.5 + 7.0, 6.0, draw_w, h), false, Color(0.02, 0.02, 0.03, 0.38))
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        # the cloth itself: 5 slices, ripple amplitude growing downward
        var slices := 5
        for i in slices:
                var k := float(i) / float(slices - 1)      # 0 at rod, 1 at hem
                var wave := sin(_t * 2.2 - k * 2.6 + s * 6.0) * (1.5 + k * 4.5)
                var sag := k * k * 3.0                      # cloth relaxes wide at the hem
                var x0 := -draw_w * 0.5 - sag * 0.5 + draw_w * float(i) / float(slices)
                var sw := draw_w / float(slices) + sag / float(slices)
                var src := Rect2(tw * float(i) / float(slices), 0.0, tw / float(slices), th)
                draw_set_transform_matrix(Transform2D(sway, pos + Vector2(wave, 0.0)))
                draw_texture_rect_region(t, Rect2(Vector2(x0, 0.0), Vector2(sw + 0.8, h * (1.0 + k * 0.012))), src, mod)
                draw_set_transform_matrix(Transform2D())
        # the rod it hangs from, with mounting studs at both ends — the cloth
        # is ATTACHED to architecture, not pasted on the air
        draw_line(Vector2(pos.x - w * 0.5 - 4, pos.y), Vector2(pos.x + w * 0.5 + 4, pos.y), E0.GOLD.darkened(0.4), 2.0)
        for sx in [pos.x - w * 0.5 - 5.0, pos.x + w * 0.5 + 5.0]:
                draw_circle(Vector2(sx, pos.y), 2.6, E0.DIRTY_STONE)
                draw_circle(Vector2(sx, pos.y), 1.2, E0.GOLD.darkened(0.25))
        # hang straps from rod to cloth
        for sx in [pos.x - draw_w * 0.34, pos.x + draw_w * 0.34]:
                draw_line(Vector2(sx, pos.y), Vector2(sx, pos.y + 7.0), E0.GOLD.darkened(0.45), 1.5)

func _statue_painted(pos: Vector2, s: float) -> void:
        ## Kneeling penitent on a low plinth; every statue faces slightly the
        ## wrong way (the painting mirrors by seed).
        var t := _tex("statue_kneel")
        var tw := float(t.get_width())
        var th := float(t.get_height())
        var face_dir := 1.0 if s > 0.5 else -1.0
        _contact_shadow(pos, tw * 0.62, 0.4 + 0.08 * s)
        # low stone plinth — the statue sits ON the floor, never sunk into it
        draw_rect(Rect2(pos.x - tw * 0.42, pos.y - 5.0, tw * 0.84, 5.0), E0.DIRTY_STONE.darkened(0.1 + 0.06 * s))
        draw_rect(Rect2(pos.x - tw * 0.36, pos.y - 5.0, tw * 0.72, 1.6), Color(0.9, 0.88, 0.82, 0.12))
        draw_set_transform(pos, 0.0, Vector2(face_dir, 1.0))
        draw_texture_rect(t, Rect2(-tw * 0.5, -th - 4.0, tw, th), false)
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _censer_painted(pos: Vector2, h: float) -> void:
        ## Hanging censer on its chains, rotating around the ceiling pivot.
        ## The chain is drawn as visible links along the swing axis — the
        ## censer must read as SUSPENDED, never as floating.
        var t := _tex("censer_swing")
        var tw := float(t.get_width())
        var th := float(t.get_height())
        var draw_w := h * tw / th
        var swing := sin(_t * 1.2 + pos.x * 0.02) * 0.18
        # chain links from the mount down to the censer crown (visible!
        # each link a small arc, following the swing line)
        var dir := Vector2(sin(swing), cos(swing))
        var links := maxi(3, int(h / 26.0))
        for i in links:
                var lk := (float(i) + 0.5) / float(links)
                draw_arc(pos + dir * (h * lk), 4.6, 0, TAU, 8, E0.ASH.lightened(0.1), 3.4)
        # mount plate at the beam
        draw_rect(Rect2(pos.x - 8.0, pos.y - 4.0, 16.0, 5.0), E0.DIRTY_STONE)
        draw_set_transform(pos, swing, Vector2.ONE)
        draw_texture_rect(t, Rect2(-draw_w * 0.5, 0.0, draw_w, h), false)
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        for i in 3:
                var t2 := fmod(_t * 0.4 + i * 0.33, 1.0)
                var end := pos + Vector2(sin(swing) * h, cos(swing) * h)
                draw_circle(end + Vector2(sin(t2 * TAU) * 5.0, -t2 * 26.0), 2.5 - t2 * 1.5, Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, (1.0 - t2) * 0.2))

func _mural_painted(pos: Vector2, w: float, h: float) -> void:
        ## Wall panel: the eleven saints in procession, plaster and all. A
        ## carved stone frame plus a support LEDGE with brackets — the panel
        ## is raised off the floor and actually held up.
        var frame := 7.0
        draw_rect(Rect2(pos.x - frame, pos.y - h - frame, w + frame * 2.0, h + frame * 2.0), E0.DIRTY_STONE)
        draw_texture_rect(_tex("mural"), Rect2(pos.x, pos.y - h, w, h), false)
        # top and side shading strips to fold the panel into the wall light
        draw_rect(Rect2(pos.x - frame, pos.y - h - frame, w + frame * 2.0, frame + 3.0), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.35))
        draw_rect(Rect2(pos.x - frame, pos.y - h - frame, frame, h + frame * 2.0), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.28))
        draw_rect(Rect2(pos.x + w, pos.y - h - frame, frame, h + frame * 2.0), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.28))
        # support ledge: shelf + pair of brackets under the panel
        draw_rect(Rect2(pos.x - 10.0, pos.y, w + 20.0, 7.0), E0.DIRTY_STONE.darkened(0.06))
        draw_rect(Rect2(pos.x - 10.0, pos.y + 7.0, w + 20.0, 2.0), E0.VOID)
        for bx in [pos.x + 14.0, pos.x + w - 26.0]:
                draw_colored_polygon(PackedVector2Array([
                        Vector2(bx, pos.y + 7.0), Vector2(bx + 12.0, pos.y + 7.0),
                        Vector2(bx + 8.0, pos.y + 22.0), Vector2(bx + 4.0, pos.y + 22.0),
                ]), E0.DIRTY_STONE.darkened(0.16))

func _bones_painted(pos: Vector2, w: float, s: float) -> void:
        ## Scatter of remains along the floor line.
        var t := _tex("bones")
        var draw_h := w * float(t.get_height()) / float(t.get_width())
        var mod := Color(1, 1, 1, 0.82 + 0.14 * s)
        _contact_shadow(pos, w * 0.48, 0.22)
        draw_texture_rect(t, Rect2(pos.x - w * 0.5, pos.y - draw_h, w, draw_h), false, mod)

func _machine_painted(pos: Vector2, w: float, h: float, s: float) -> void:
        ## Painted reliquary-engine body with the live procedural instrumentation
        ## (cycling gauges, blinking fault lights) drawn over it — and a body
        ## that WORKS: a piston bobbing in its side housing, steam breathing
        ## from the stack, sparks spitting when the fault light peaks. CENTERED
        ## on pos.x like every other floor-standing prop, on a two-step plinth.
        var x := pos.x - w * 0.5
        _contact_shadow(pos, w * 0.66, 0.42 + 0.08 * s)
        # plinth: upper slab + wider footing
        draw_rect(Rect2(x - 5.0, pos.y - 7.0, w + 10.0, 7.0), E0.DIRTY_STONE.darkened(0.08))
        draw_rect(Rect2(x - 9.0, pos.y - 3.0, w + 18.0, 3.0), E0.DIRTY_STONE.darkened(0.16))
        draw_texture_rect(_tex("machine"), Rect2(x, pos.y - h, w, h - 7.0), false)
        # piston: a rod bobbing in a side housing — the engine MOVES
        var pist := sin(_t * 2.4 + s * 7.0) * 3.0
        draw_rect(Rect2(x - 3.0, pos.y - h * 0.52 - pist, 6.0, h * 0.34), E0.ASH.lightened(0.06))
        draw_rect(Rect2(x - 4.5, pos.y - h * 0.56, 9.0, 6.0), E0.DIRTY_STONE.darkened(0.1))
        for i in 3:
                var gauge_y := pos.y - h + 14.0 + i * (h - 30.0) / 3.0
                var v := 0.3 + 0.2 * sin(_t * 0.9 + i * 2.0 + s * 7.0)
                draw_rect(Rect2(x + 8, gauge_y, w - 16, 3), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.65))
                draw_rect(Rect2(x + 8, gauge_y, (w - 16) * v, 3), Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.5))
        for i in 2:
                draw_circle(Vector2(x + w - 10.0, pos.y - h + 12.0 + i * 12.0), 2.5, Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.4 + 0.2 * sin(_t * 1.3 + i)))
        # stack steam: a slow breath from the top pipe
        var steam := fmod(_t * 0.22 + s, 1.0)
        if steam < 0.5:
                var sk := steam / 0.5
                var puff := sin(sk * PI)
                for j in 3:
                        var jt := float(j) / 3.0
                        draw_circle(Vector2(x + w * 0.72 + sin(sk * 6.0 + j) * 4.0, pos.y - h + 2.0 - sk * (16.0 + jt * 18.0)),
                                3.0 + sk * (5.0 + jt * 3.0), Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.09 * puff * (1.0 - jt * 0.4)))
        # fault sparks: only when the fault light peaks
        var fault := sin(_t * 1.3 + s * 3.0)
        if fault > 0.86:
                for j in 3:
                        var jt := (float(j) + fmod(_t * 9.0 + s * 5.0, 1.0)) / 4.0
                        draw_circle(Vector2(x + w * 0.2 + jt * 8.0, pos.y - h * 0.2 - jt * 12.0), 1.1 * (1.0 - jt),
                                Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, (1.0 - jt) * 0.7))

func _frieze(pos: Vector2, w: float, h: float, s: float) -> void:
        ## The vault beam: a two-course carved cornice spanning the colonnade —
        ## the horizontal architecture everything hangs FROM (banners, censers,
        ## bells, chains) and everything rises TO (column capitals). pos.x is
        ## the LEFT end, pos.y the beam TOP (h unused). Seed > 0.95 selects the
        ## riveted metal gantry variant for the engine sanctum.
        var beam_h := 20.0
        var mold_h := 12.0
        var metal := s > 0.95
        var col := E0.DIRTY_STONE.darkened(0.08) if not metal else E0.ASH.darkened(0.12)
        # under-shadow: the cornice shades the wall beneath it
        for i in 4:
                var t := float(i) / 4.0
                draw_rect(Rect2(pos.x, pos.y + beam_h + mold_h + t * 11.0, w, 5.0), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.17 * (1.0 - t)))
        # main beam course
        draw_rect(Rect2(pos.x, pos.y, w, beam_h), col)
        # lower molding course: a lip wider than the beam, with its own shadow
        var lip := 5.0
        draw_rect(Rect2(pos.x - lip, pos.y + beam_h, w + lip * 2.0, mold_h), col.darkened(0.07))
        draw_rect(Rect2(pos.x - lip, pos.y + beam_h, w + lip * 2.0, 2.5), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.4))
        if not metal:
                # ASHLAR SKIN: the beam samples the masonry stone tile in long
                # varied strips — same material as the world, never flat UI grey
                var st := _stone()
                if st != null:
                        var tw := float(st.get_width())
                        var th := float(st.get_height())
                        var seg := 220.0
                        var x := pos.x
                        var k := 0
                        while x < pos.x + w - 2.0:
                                var ww := minf(seg, pos.x + w - x)
                                var rng := RandomNumberGenerator.new()
                                rng.seed = hash("frieze:" + str(int(pos.x)) + ":" + str(k))
                                var sw := minf(ww * 0.9, tw - 4.0)
                                var src := Rect2(rng.randf() * (tw - sw - 2.0), rng.randf() * (th - 46.0), sw, minf(40.0, th))
                                var shade := 0.72 + rng.randf() * 0.14
                                draw_texture_rect_region(st, Rect2(x, pos.y + 1.0, ww, beam_h - 2.0), src, Color(shade, shade * 0.985, shade * 0.955))
                                var sw2 := minf(ww * 0.9, tw - 4.0)
                                var src2 := Rect2(rng.randf() * (tw - sw2 - 2.0), rng.randf() * (th - 30.0), sw2, minf(26.0, th))
                                draw_texture_rect_region(st, Rect2(x, pos.y + beam_h + 1.0, ww, mold_h - 2.0), src2, Color(shade * 0.8, shade * 0.79, shade * 0.77))
                                x += seg
                                k += 1
        if metal:
                # riveted flanges + rivets on both courses
                draw_rect(Rect2(pos.x, pos.y - 4.0, w, 4.0), col.darkened(0.1))
                var rx := pos.x + 14.0
                while rx < pos.x + w - 8.0:
                        draw_circle(Vector2(rx, pos.y + beam_h * 0.5), 1.7, col.lightened(0.12))
                        draw_circle(Vector2(rx + 17.0, pos.y + beam_h + mold_h * 0.5), 1.4, col.lightened(0.08))
                        rx += 34.0
        else:
                # stone: block joints + top light catch + molding returns
                var jx := pos.x + 20.0 + fmod(s * 47.0, 30.0)
                while jx < pos.x + w - 12.0:
                        draw_rect(Rect2(jx, pos.y + 2.0, 2.0, beam_h - 3.0), E0.VOID)
                        draw_rect(Rect2(jx + 37.0, pos.y + beam_h + 2.0, 2.0, mold_h - 3.0), E0.VOID)
                        jx += 74.0
                draw_rect(Rect2(pos.x, pos.y, w, 3.0), Color(0.9, 0.88, 0.82, 0.14))
        # corbels — the brackets holding it up (stone rooms)
        if not metal:
                var cx := pos.x + 64.0 + fmod(s * 91.0, 40.0)
                while cx < pos.x + w - 40.0:
                        draw_colored_polygon(PackedVector2Array([
                                Vector2(cx - 8.0, pos.y + beam_h + mold_h), Vector2(cx + 8.0, pos.y + beam_h + mold_h),
                                Vector2(cx + 4.5, pos.y + beam_h + mold_h + 17.0), Vector2(cx - 4.5, pos.y + beam_h + mold_h + 17.0),
                        ]), col.darkened(0.13))
                        cx += 148.0
        # end caps where the beam meets a wall or pier
        for ex in [pos.x, pos.x + w - 6.0]:
                draw_rect(Rect2(ex, pos.y - 3.0, 6.0, beam_h + mold_h + 6.0), col.darkened(0.05))

# ------------------------------------------------------- procedural fallback

func _column(pos: Vector2, w: float, h: float) -> void:
        draw_rect(Rect2(pos.x - w * 0.5, pos.y - h, w, h), E0.DIRTY_STONE.darkened(0.05))
        draw_rect(Rect2(pos.x - w * 0.5 - 4, pos.y - h, w + 8, 10), E0.DIRTY_STONE)
        draw_rect(Rect2(pos.x - w * 0.5 - 4, pos.y - 12, w + 8, 12), E0.DIRTY_STONE)
        for i in 3:
                draw_line(Vector2(pos.x - w * 0.5 + 4, pos.y - h + 14 + i * h * 0.3), Vector2(pos.x - w * 0.5 + 4, pos.y - h + 30 + i * h * 0.3), E0.VOID, 1.5)

func _arch(pos: Vector2, w: float, h: float) -> void:
        _arch_interior(pos, w, h * 0.92)
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
        ## Chains breathe: a slow pendulum sway that travels down the links,
        ## anchored by a visible mount ring at the top (never a bare line
        ## out of the void).
        draw_circle(pos, 5.0, E0.DIRTY_STONE)
        draw_circle(pos, 2.6, E0.VOID)
        var links := maxi(3, int(h / 22.0))
        var sway_t := sin(_t * 0.7 + pos.x * 0.013) 
        for i in links:
                var y := pos.y + i * 22.0
                var sway := sway_t * (2.0 + i * 0.55)
                draw_arc(Vector2(pos.x + sway, y), 5.5, 0, TAU, 8, E0.ASH, 3.0)
        # heavy chains double up
        if h > 200.0:
                for i in links:
                        var y := pos.y + i * 22.0 + 11.0
                        var sway := sin(_t * 0.7 + pos.x * 0.013 + 1.5) * (2.0 + i * 0.55)
                        draw_arc(Vector2(pos.x + 12.0 + sway, y), 5.5, 0, TAU, 8, Color(E0.ASH.r, E0.ASH.g, E0.ASH.b, 0.85), 3.0)
        draw_circle(Vector2(pos.x + sway_t * (2.0 + links * 0.55), pos.y + links * 22.0 + 8.0), 7.5, E0.DIRTY_STONE)
        draw_circle(Vector2(pos.x + sway_t * (2.0 + links * 0.55), pos.y + links * 22.0 + 8.0), 3.0, E0.VOID)

func _cage(pos: Vector2, h: float) -> void:
        _chain(pos, h)
        var top := pos.y + h + 12.0
        var c_sway := sin(_t * 0.7 + pos.x * 0.013) * (2.0 + (h / 22.0) * 0.55)
        draw_rect(Rect2(pos.x - 22 + c_sway, top, 44, 4), E0.ASH)
        for i in 5:
                draw_line(Vector2(pos.x - 22 + c_sway + i * 11.0, top), Vector2(pos.x - 22 + c_sway + i * 11.0 + sin(_t * 1.1 + i * 1.3) * 2.0, top + 38), E0.ASH, 2.0)
        draw_rect(Rect2(pos.x - 22 + c_sway, top + 38, 44, 4), E0.ASH)
        # something barely inside
        draw_circle(Vector2(pos.x + c_sway, top + 24.0), 5.0, Color(E0.DIRTY_STONE.r, E0.DIRTY_STONE.g, E0.DIRTY_STONE.b, 0.8))
        draw_line(Vector2(pos.x - 5.0 + c_sway, top + 30.0), Vector2(pos.x + 5.0 + c_sway, top + 36.0), Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.6), 1.5)

func _censer(pos: Vector2, h: float) -> void:
        var swing := sin(_t * 1.2 + pos.x * 0.02) * 0.18
        var pivot := pos + Vector2(0, 0)
        var end := pivot + Vector2(sin(swing) * h, cos(swing) * h)
        draw_line(pivot, end, E0.ASH, 1.5)
        draw_colored_polygon(PackedVector2Array([
                end + Vector2(-8, 0), end + Vector2(8, 0), end + Vector2(5, 10), end + Vector2(-5, 10),
        ]), E0.GOLD.darkened(0.4))
        for i in 3:
                var t := fmod(_t * 0.4 + i * 0.33, 1.0)
                draw_circle(end + Vector2(sin(t * TAU) * 5.0, -t * 26.0), 2.5 - t * 1.5, Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, (1.0 - t) * 0.2))

func _pipe(pos: Vector2, w: float, h: float) -> void:
        draw_rect(Rect2(pos.x, pos.y - h, w, h), E0.ASH.darkened(0.05))
        draw_rect(Rect2(pos.x, pos.y - h, w, 6), E0.ASH.lightened(0.08))
        for i in int(h / 50.0):
                draw_rect(Rect2(pos.x - 3, pos.y - h + 25 + i * 50, w + 6, 8), E0.DIRTY_STONE)
        if h > 80:
                draw_circle(Vector2(pos.x + w * 0.5, pos.y - h * 0.4), 5.0, E0.DIRTY_STONE)

func _vent(pos: Vector2, w: float, s := 0.5) -> void:
        ## Floor/wall vent that EXHALES: every few seconds a breath of steam
        ## pushes up through the grate, mushrooms, and dissolves.
        draw_rect(Rect2(pos.x, pos.y, w, 18), E0.ASH)
        draw_rect(Rect2(pos.x, pos.y, w, 3), E0.ASH.lightened(0.1))
        for i in 4:
                draw_rect(Rect2(pos.x + 3, pos.y + 3 + i * 4, w - 6, 2), E0.VOID)
        # the breath: phase-locked per seed, rises and fades
        var cycle := 4.6 + s * 2.2
        var ph := fmod(_t / cycle + s * 0.37, 1.0)
        if ph < 0.42:
                var k := ph / 0.42
                var puff := sin(k * PI)
                var base := Vector2(pos.x + w * 0.5, pos.y - 2.0)
                for j in 4:
                        var jt := float(j) / 4.0
                        var rr := (4.0 + k * 16.0) * (1.0 - jt * 0.35)
                        var dy := -k * (34.0 + jt * 26.0) - jt * 4.0
                        var dx := sin(jt * 5.0 + k * 4.0) * 5.0 * k
                        var a := 0.11 * puff * (1.0 - jt * 0.55)
                        draw_circle(Vector2(base.x + dx, base.y + dy), rr, Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, a))
                # heat shimmer line at the grate mouth
                draw_rect(Rect2(pos.x + 2, pos.y - 3.0, w - 4, 2.0), Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.10 * puff))

func _cable(pos: Vector2, w: float, h: float, s: float) -> void:
        ## Cables sway in the draft: a slow travelling wave along the sag.
        var pts := PackedVector2Array()
        var steps := 8
        for i in steps + 1:
                var t := float(i) / steps
                var sag := sin(t * PI) * h
                pts.append(pos + Vector2(w * t, sag + sin(t * 7.0 + s * 6.0 + _t * 0.8) * 2.4))
        for i in steps:
                draw_line(pts[i], pts[i + 1], E0.ASH, 2.0)

func _bell(pos: Vector2, s: float) -> void:
        draw_rect(Rect2(pos.x - 36, pos.y, 72, 8), E0.DIRTY_STONE)
        draw_rect(Rect2(pos.x - 36, pos.y + 8, 72, 2), E0.VOID)
        draw_line(Vector2(pos.x, pos.y + 8), Vector2(pos.x, pos.y + 30), E0.ASH, 2.5)
        # slow breath of the swing + a rare deeper toll (a double sine:
        # gentle forever, with a slow swell that rises and fades)
        var toll := maxf(0.0, sin(_t * 0.11 + s * 9.0))
        var swing := sin(_t * 0.9 + s * 6.0) * (0.035 + 0.11 * pow(toll, 3.0))
        var dir := Vector2(sin(swing), cos(swing))
        var top := Vector2(pos.x, pos.y + 30)
        # bell profile traced around the outline (self-intersecting order
        # breaks triangulation): shoulder -> flare -> lip -> back up
        draw_colored_polygon(PackedVector2Array([
                top + dir * 6.0 + Vector2(-22, 0),
                top + dir * 6.0 + Vector2(22, 0),
                top + dir * 20.0 + Vector2(26, 6),
                top + dir * 52.0 + Vector2(14, 0),
                top + dir * 52.0 + Vector2(-14, 0),
                top + dir * 20.0 + Vector2(-26, 6),
        ]), E0.ASH.lightened(0.06))
        # rim shadow + clapper (lags the swing — it is heavy)
        draw_line(top + dir * 52.0 + Vector2(-14, 0), top + dir * 52.0 + Vector2(14, 0), E0.VOID, 2.0)
        var lag := sin(_t * 0.9 + s * 6.0 - 0.5) * (0.06 + 0.2 * pow(toll, 3.0))
        draw_line(top + dir * 40.0, top + dir * 40.0 + Vector2(sin(lag) * 20.0, cos(lag) * 16.0), E0.ASH, 2.0)
        draw_circle(top + dir * 40.0 + Vector2(sin(lag) * 20.0, cos(lag) * 16.0), 4.5, E0.DIRTY_STONE)

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
        ## Candle row with LIVING flames: each flame leans on its own noise,
        ## gutters (brightness + height flutter), and sits in its own warm
        ## halo that breathes — plus a rare wax tear on some candles.
        var rng := RandomNumberGenerator.new()
        rng.seed = hash(str(int(pos.y)) + str(s))
        var n := maxi(3, int(w / 24.0))
        for i in n:
                var cx := pos.x + 6.0 + (w - 12.0) * i / float(n - 1)
                var ch := 8.0 + rng.randf() * 6.0
                # body
                draw_rect(Rect2(cx - 2.5, pos.y - ch, 5, ch), Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.75))
                draw_rect(Rect2(cx - 2.5, pos.y - ch, 1.4, ch), Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, 0.28))
                if rng.randf() < 0.3:
                        draw_line(Vector2(cx - 2.0, pos.y - ch * 0.4), Vector2(cx - 2.0, pos.y - 1.0), Color(E0.PARCH.r * 0.9, E0.PARCH.g * 0.9, E0.PARCH.b * 0.9, 0.5), 1.0)
                # flame: two coupled oscillators read as wind, not as a blink
                var ph := i * 2.7 + s * 9.0
                var gutter := 0.62 + 0.38 * sin(_t * 6.3 + ph) * sin(_t * 2.1 + ph * 1.7)
                var lean := sin(_t * 2.9 + ph * 1.3) * 1.3
                var fh := 3.2 + 2.2 * gutter
                var fy := pos.y - ch - 1.0
                # halo first (behind the flame core)
                draw_circle(Vector2(cx, fy - 3.0), 7.0, Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.06 + 0.05 * gutter))
                draw_circle(Vector2(cx, fy - 3.0), 3.8, Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.10 + 0.08 * gutter))
                # flame core: outer crimson tongue + inner gold teardrop
                draw_colored_polygon(PackedVector2Array([
                        Vector2(cx - 2.0 + lean * 0.4, fy), Vector2(cx + 2.0 + lean * 0.4, fy),
                        Vector2(cx + lean, fy - fh),
                ]), Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.55 + 0.3 * gutter))
                draw_colored_polygon(PackedVector2Array([
                        Vector2(cx - 1.1 + lean * 0.55, fy), Vector2(cx + 1.1 + lean * 0.55, fy),
                        Vector2(cx + lean * 0.8, fy - fh * 0.62),
                ]), Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.65 + 0.3 * gutter))

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
        var pist := sin(_t * 2.4 + s * 7.0) * 3.0
        draw_rect(Rect2(pos.x - 3.0, pos.y - h * 0.52 - pist, 6.0, h * 0.34), E0.ASH.lightened(0.06))
        for i in 3:
                var gauge_y := pos.y - h + 14.0 + i * (h - 28.0) / 3.0
                var v := 0.3 + 0.2 * sin(_t * 0.9 + i * 2.0 + s * 7.0)
                draw_rect(Rect2(pos.x + 8, gauge_y, w - 16, 3), E0.ASH)
                draw_rect(Rect2(pos.x + 8, gauge_y, (w - 16) * v, 3), Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.5))
        for i in 2:
                draw_circle(Vector2(pos.x + w - 10.0, pos.y - h + 12.0 + i * 12.0), 2.5, Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.4 + 0.2 * sin(_t * 1.3 + i)))
        draw_rect(Rect2(pos.x - 4, pos.y - 6, w + 8, 6), E0.DIRTY_STONE)

func _pew(pos: Vector2, w: float, s: float) -> void:
        ## Chapel bench — dark wood, worn smooth by the counted. w is the
        ## bench length; the back stands on the -x side so the congregation
        ## faces the altar (+x).
        _contact_shadow(pos, w * 0.56, 0.3 + 0.08 * s)
        var wood := Color(0.16, 0.12, 0.1).darkened(0.04 * s)
        var wood_hi := wood.lightened(0.07)
        # legs
        for lx in [pos.x - w * 0.38, pos.x + w * 0.36]:
                draw_rect(Rect2(lx, pos.y - 14, 7, 14), wood)
        # seat
        draw_rect(Rect2(pos.x - w * 0.5, pos.y - 18, w, 6), wood_hi)
        draw_rect(Rect2(pos.x - w * 0.5, pos.y - 13, w, 4), wood)
        # back, slightly tilted
        var back_x := pos.x - w * 0.5 + 3.0
        draw_colored_polygon(PackedVector2Array([
                Vector2(back_x, pos.y - 18), Vector2(back_x + 4, pos.y - 18),
                Vector2(back_x + 9, pos.y - 40), Vector2(back_x + 5, pos.y - 40),
        ]), wood)
        # a worn spot on the seat where the counted sat
        draw_rect(Rect2(pos.x + w * 0.1, pos.y - 19, w * 0.18, 2), Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.1 + 0.08 * s))
        # a dropped hymnal on some benches
        if s > 0.72:
                draw_rect(Rect2(pos.x + w * 0.3, pos.y - 23, 9, 5), Color(E0.PARCH.r * 0.6, E0.PARCH.g * 0.6, E0.PARCH.b * 0.6, 0.9))

func _records(pos: Vector2, w: float, s: float) -> void:
        ## Loose record pages, fallen where they were read. Pale rectangles,
        ## slightly turned — the archive sheds.
        var rng := RandomNumberGenerator.new()
        rng.seed = hash(str(int(pos.x)) + "rec" + str(s))
        var n := maxi(4, int(w / 30.0))
        for i in n:
                var px := pos.x + rng.randf() * w
                var py := pos.y - rng.randf() * 3.0
                var pw := 13.0 + rng.randf() * 7.0
                var ph := 9.0 + rng.randf() * 4.0
                var rot := (rng.randf() - 0.5) * 0.9
                # soft contact shadow so pages sit on the floor
                draw_set_transform(Vector2(px, py), rot, Vector2.ONE)
                draw_rect(Rect2(-pw * 0.5 - 1.5, -ph + 1.5, pw + 3.0, ph + 1.5), Color(0.02, 0.02, 0.03, 0.3))
                draw_rect(Rect2(-pw * 0.5, -ph, pw, ph), Color(E0.PARCH.r * 0.78, E0.PARCH.g * 0.78, E0.PARCH.b * 0.74, 0.85 + 0.15 * rng.randf()))
                # a line or two of record text
                if rng.randf() > 0.3:
                        draw_rect(Rect2(-pw * 0.5 + 2.0, -ph + 2.0, pw * 0.6 * rng.randf() + 3.0, 1.2), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.6))
                if rng.randf() > 0.55:
                        draw_rect(Rect2(-pw * 0.5 + 2.0, -ph + 4.4, pw * 0.45 * rng.randf() + 2.0, 1.2), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.5))
                draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# ------------------------------------------- living-architecture expansion
# Eleven new animated kinds. Placement law (WB-2, upheld): hanging things
# mount to visible architecture (beams, wall anchors), floor things sit on
# plinths/shadows, wall things get frames and brackets. Everything breathes.

func _flame_at(cx: float, fy: float, ph: float, k := 1.0) -> void:
        ## Shared living flame: two coupled oscillators read as wind, an outer
        ## crimson tongue wrapped around an inner gold teardrop, halo behind.
        var gutter := 0.62 + 0.38 * sin(_t * 6.3 + ph) * sin(_t * 2.1 + ph * 1.7)
        var lean := sin(_t * 2.9 + ph * 1.3) * 1.3 * k
        var fh := (3.2 + 2.2 * gutter) * k
        draw_circle(Vector2(cx, fy - 3.0 * k), 7.0 * k, Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.06 + 0.05 * gutter))
        draw_circle(Vector2(cx, fy - 3.0 * k), 3.8 * k, Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.10 + 0.08 * gutter))
        draw_colored_polygon(PackedVector2Array([
                Vector2(cx - 2.0 * k + lean * 0.4, fy), Vector2(cx + 2.0 * k + lean * 0.4, fy),
                Vector2(cx + lean, fy - fh),
        ]), Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.55 + 0.3 * gutter))
        draw_colored_polygon(PackedVector2Array([
                Vector2(cx - 1.1 * k + lean * 0.55, fy), Vector2(cx + 1.1 * k + lean * 0.55, fy),
                Vector2(cx + lean * 0.8, fy - fh * 0.62),
        ]), Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.65 + 0.3 * gutter))

func _window(pos: Vector2, w: float, h: float, s: float) -> void:
        ## Gothic pointed window set into the wall plane: stone frame, leaded
        ## lights, and a breath of colour behind the glass — cold moonlight
        ## or chapel-warm amber (seed decides). pos = sill centre, grows up h.
        var rng := RandomNumberGenerator.new()
        rng.seed = hash(str(int(pos.x)) + "win" + str(s))
        var frame := E0.DIRTY_STONE.darkened(0.06 + 0.06 * rng.randf())
        var warm := s > 0.5
        var glow := 0.55 + 0.18 * sin(_t * 0.45 + s * 7.0)
        # a rare far-lightning pulse behind the glass
        var flash := pow(maxf(0.0, sin(_t * 0.13 + s * 3.0)), 24.0) * 0.35
        var glass_col := Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.13 + 0.10 * glow + flash) if warm \
                        else Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.10 + 0.07 * glow + flash)
        # sill
        draw_rect(Rect2(pos.x - w * 0.5 - 5.0, pos.y - 5.0, w + 10.0, 6.0), frame)
        draw_rect(Rect2(pos.x - w * 0.5 - 5.0, pos.y - 5.0, w + 10.0, 2.0), frame.lightened(0.08))
        # glass body: rectangle up to the spring line, then the pointed arch
        var spring := pos.y - h * 0.52
        var apex := pos.y - h
        draw_rect(Rect2(pos.x - w * 0.5, spring, w, h * 0.52 - 5.0), glass_col)
        var arch_pts := PackedVector2Array()
        var steps := 10
        for i in steps + 1:
                var k := float(i) / steps
                # symmetric pointed arch: zero lift at both springs, peak mid-span
                var lift := pow(maxf(0.0, cos((k - 0.5) * PI)), 1.35) * (h * 0.52)
                var bx := -w * 0.5 + w * k
                arch_pts.append(Vector2(pos.x + bx, spring - lift))
        draw_colored_polygon(arch_pts, glass_col)
        # leaded lights: central mullion + two transoms + arch ribs
        var lead := E0.ASH.darkened(0.15)
        draw_line(Vector2(pos.x, spring - h * 0.46), Vector2(pos.x, pos.y - 5.0), lead, 2.5)
        for ty in [pos.y - h * 0.30, pos.y - h * 0.14]:
                draw_line(Vector2(pos.x - w * 0.5, ty), Vector2(pos.x + w * 0.5, ty), lead, 1.8)
        draw_line(Vector2(pos.x - w * 0.25, spring - h * 0.10), Vector2(pos.x - w * 0.06, apex + h * 0.10), lead, 1.4)
        draw_line(Vector2(pos.x + w * 0.25, spring - h * 0.10), Vector2(pos.x + w * 0.06, apex + h * 0.10), lead, 1.4)
        # stone frame around the whole opening
        draw_line(Vector2(pos.x - w * 0.5 - 3.0, pos.y - 5.0), Vector2(pos.x - w * 0.5 - 3.0, spring), frame.lightened(0.05), 3.0)
        draw_line(Vector2(pos.x + w * 0.5 + 3.0, pos.y - 5.0), Vector2(pos.x + w * 0.5 + 3.0, spring), frame.lightened(0.05), 3.0)
        for i in steps:
                draw_line(arch_pts[i], arch_pts[i + 1], frame.lightened(0.05), 3.0)
        # dust motes drifting in the light shaft
        for j in 3:
                var mt := fmod(_t * 0.05 + s + j * 0.37, 1.0)
                var mote_x := pos.x - w * 0.3 + w * 0.6 * fmod(j * 0.31 + s, 1.0)
                draw_circle(Vector2(mote_x, pos.y - 5.0 - mt * h * 0.8), 1.0,
                        Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.14 * sin(mt * PI)))

func _chandelier(pos: Vector2, h: float, s: float) -> void:
        ## Wheel chandelier on its chain: everything pivots at the ceiling
        ## mount (WB-2 law — it hangs FROM architecture), two rings of arms,
        ## candles with living flames, and a slow pendulum breath.
        var sway := sin(_t * 0.5 + s * 8.0) * 0.045
        # mount plate at the beam
        draw_rect(Rect2(pos.x - 10.0, pos.y - 4.0, 20.0, 5.0), E0.DIRTY_STONE)
        for sx in [pos.x - 7.0, pos.x + 7.0]:
                draw_circle(Vector2(sx, pos.y - 1.5), 1.5, E0.GOLD.darkened(0.35))
        draw_set_transform_matrix(Transform2D(sway, pos))
        # warm bloom around the whole fixture (the chapel reads lit)
        draw_circle(Vector2(0.0, h * 0.42), 58.0, Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.045 + 0.02 * sin(_t * 1.3 + s * 4.0)))
        draw_circle(Vector2(0.0, h * 0.42 + 12.0), 34.0, Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.06))
        # suspension chain: three visible links
        for i in 3:
                draw_arc(Vector2(0.0, 6.0 + i * 9.0), 4.5, 0, TAU, 8, E0.ASH, 2.5)
        var hub := Vector2(0.0, h * 0.42)
        # central column + crown sphere
        draw_line(Vector2(0.0, 28.0), hub + Vector2(0.0, -6.0), E0.ASH.lightened(0.06), 3.5)
        draw_circle(hub + Vector2(0.0, -8.0), 5.0, E0.GOLD.darkened(0.3))
        # two wheel rings of arms — upper small, lower wide
        for ring in 2:
                var ry := hub.y + ring * 16.0
                var rr := 22.0 + ring * 20.0
                draw_arc(Vector2(0.0, ry), rr, 0, TAU, 24, E0.ASH.lightened(0.05), 2.2)
                var n := 4 + ring * 2
                for i in n:
                        var a := TAU * i / n + ring * 0.5
                        var tip := Vector2(0.0, ry) + Vector2(cos(a) * rr, sin(a) * rr * 0.35)
                        # curved arm up to the candle cup
                        var mid := Vector2(0.0, ry) + Vector2(cos(a) * rr * 0.55, -6.0 - ring * 3.0)
                        draw_line(Vector2(0.0, ry), mid, E0.ASH.lightened(0.04), 2.0)
                        draw_line(mid, tip, E0.ASH.lightened(0.04), 2.0)
                        # candle cup + wax column + living flame (fat enough
                        # to read as candles at gameplay distance)
                        draw_circle(tip, 3.4, E0.GOLD.darkened(0.25))
                        var ch := 6.0 + ring * 2.5
                        draw_rect(Rect2(tip.x - 2.2, tip.y - ch, 4.4, ch), Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.85))
                        draw_rect(Rect2(tip.x - 2.2, tip.y - ch, 1.4, ch), Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, 0.3))
                        _flame_at(tip.x, tip.y - ch - 1.0, i * 2.7 + ring * 4.0 + s * 9.0, 1.0)
        draw_set_transform_matrix(Transform2D())
        # wax tear on the column
        draw_line(Vector2(pos.x + 2.0, pos.y + h * 0.5), Vector2(pos.x + 2.0, pos.y + h * 0.5 + 9.0), Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.4), 1.2)

func _sconce(pos: Vector2, s: float) -> void:
        ## Wall sconce: backplate bolted to the masonry, a curled arm, a
        ## single candle with a living flame, warm halo pressed to the wall.
        var back := E0.DIRTY_STONE.darkened(0.12)
        draw_rect(Rect2(pos.x - 5.0, pos.y - 22.0, 10.0, 26.0), back)
        for by in [pos.y - 18.0, pos.y + 1.0]:
                draw_circle(Vector2(pos.x, by), 1.4, E0.ASH)
        # curled arm out of the wall
        var arm_dir := 1.0 if s > 0.5 else -1.0
        var elbow := pos + Vector2(14.0 * arm_dir, -6.0)
        var cup := pos + Vector2(20.0 * arm_dir, -14.0)
        draw_line(pos + Vector2(3.0 * arm_dir, -8.0), elbow, E0.ASH.lightened(0.05), 3.0)
        draw_line(elbow, cup, E0.ASH.lightened(0.05), 3.0)
        var curl_from := PI * 0.2 if arm_dir > 0 else PI * 1.9
        draw_arc(elbow, 5.0, curl_from, curl_from + PI * 0.9, 8, E0.ASH, 1.6)
        # wall glow behind the flame (pressed onto the wall plane)
        var glow := 0.5 + 0.2 * sin(_t * 2.1 + s * 9.0)
        draw_circle(cup, 16.0, Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.05 + 0.04 * glow))
        draw_circle(cup, 9.0, Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.07 + 0.05 * glow))
        # candle + flame
        draw_rect(Rect2(cup.x - 2.2, cup.y - 9.0, 4.4, 9.0), Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.8))
        draw_circle(cup, 3.4, E0.GOLD.darkened(0.2))
        _flame_at(cup.x, cup.y - 10.0, s * 9.0, 0.9)

func _roots(pos: Vector2, w: float, h: float, s: float) -> void:
        ## Roots that broke through the vaulting and hang down into the room:
        ## each strand sways on a travelling wave (stiff at the stone, loose
        ## at the tip), with root hairs and dust wisps caught in them.
        var rng := RandomNumberGenerator.new()
        rng.seed = hash(str(int(pos.x)) + "root" + str(s))
        # the crack they came through
        draw_rect(Rect2(pos.x - w * 0.5, pos.y - 3.0, w, 4.0), E0.VOID)
        draw_rect(Rect2(pos.x - w * 0.5, pos.y - 1.0, w, 1.5), E0.DIRTY_STONE.darkened(0.2))
        var n := maxi(3, int(w / 26.0))
        for i in n:
                var bx := pos.x - w * 0.5 + w * (i + 0.3 + rng.randf() * 0.4) / n
                var len := h * (0.6 + rng.randf() * 0.4)
                var phase := s * 7.0 + i * 1.9
                var segs := 7
                var prev := Vector2(bx, pos.y + 2.0)
                for j in segs:
                        var k := float(j) / segs
                        var sw := sin(k * 2.2 + phase + _t * 0.85) * (0.5 + k * 5.5)
                        var pt := Vector2(bx + sw + sin(phase * 3.0 + k * 5.0) * 4.0, pos.y + 2.0 + len * k)
                        # dark mass + a pale rim thread on top: roots READ
                        # against dark walls instead of vanishing into them
                        draw_line(prev, pt, E0.DIRTY_STONE.darkened(0.05 + 0.1 * (1.0 - k)), maxf(1.6, 5.0 * (1.0 - k * 0.85)))
                        draw_line(prev, pt, E0.PARCH.darkened(0.35 + 0.2 * k), maxf(1.0, 1.8 * (1.0 - k * 0.8)))
                        prev = pt
                # root hairs near the tip
                for hj in 2:
                        var hk := 0.72 + rng.randf() * 0.24
                        var hp := Vector2(bx, pos.y + 2.0 + len * hk)
                        draw_line(hp, hp + Vector2((rng.randf() - 0.5) * 8.0, 6.0 + rng.randf() * 5.0), E0.DIRTY_STONE.darkened(0.15), 1.0)
                # a dust wisp caught mid-strand on some roots
                if rng.randf() < 0.4:
                        var wk := 0.55 + rng.randf() * 0.3
                        var wp := Vector2(bx + sin(wk * 2.2 + phase + _t * 0.85) * (0.5 + wk * 5.5), pos.y + 2.0 + len * wk)
                        draw_line(wp, wp + Vector2(sin(_t * 0.7 + i) * 3.0, 10.0 + rng.randf() * 8.0), Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.22), 1.2)

func _web(pos: Vector2, w: float, h: float, s: float) -> void:
        ## Corner web: radial spokes off the anchor point with sagging
        ## concentric threads, a few broken strands, and a travelling
        ## glint as the light moves across it.
        var rng := RandomNumberGenerator.new()
        rng.seed = hash(str(int(pos.x)) + "web" + str(s))
        var spokes := 7
        var ends := PackedVector2Array()
        for i in spokes:
                var a := -PI * 0.5 + PI * float(i) / (spokes - 1)  # quarter fan down-right
                a *= (1.0 if s > 0.5 else -1.0)
                var len := (w + h) * 0.5 * (0.7 + 0.3 * rng.randf())
                ends.append(pos + Vector2(cos(a) * len * (w / maxf(w, h)), sin(a) * len * (h / maxf(w, h))))
        var thread := Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.34)
        # spokes (some broken — abandoned, like everything here)
        for i in spokes:
                if rng.randf() < 0.2:
                        draw_line(pos, pos + (ends[i] - pos) * 0.55, thread, 1.6)
                else:
                        draw_line(pos, ends[i], thread, 1.6)
        # concentric sagging rings
        for ring in 4:
                var rk := (ring + 1.0) / 4.5
                var pts := PackedVector2Array()
                for i in spokes:
                        var p := pos + (ends[i] - pos) * rk
                        p.y += sin(rk * PI) * 4.0  # the sag
                        pts.append(p)
                draw_polyline(pts, thread.darkened(0.02), 1.4)
        # the glint: a bright segment sweeping the web as _t passes
        var ga := fmod(_t * 0.35 + s, 1.0) * PI - PI * 0.5
        var glint := pow(maxf(0.0, cos(ga)), 4.0) * 0.7
        if glint > 0.02:
                var gi := int(clampf((ga + PI * 0.5) / PI * (spokes - 1), 0, spokes - 1))
                draw_line(pos, ends[gi], Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, glint * 0.6), 1.8)
                draw_line(pos, ends[maxi(0, gi - 1)], Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, glint * 0.35), 1.5)
        # whatever waits at the hub
        draw_circle(pos, 2.4, E0.VOID)

func _puddle(pos: Vector2, w: float, s: float) -> void:
        ## Standing water on the stone: dark lens, a slow sky sheen drifting
        ## across it, and a ring of ripples that breathes outward.
        var rng := RandomNumberGenerator.new()
        rng.seed = hash(str(int(pos.x)) + "pud" + str(s))
        var hw := w * 0.5
        var hh := w * 0.16
        # dark water body (violet depth, but bright enough to READ as water)
        var water := Color(E0.VIOLET.r * 0.5 + 0.06, E0.VIOLET.g * 0.5 + 0.06, E0.VIOLET.b * 0.6 + 0.09, 0.72)
        var n := 12
        var body := PackedVector2Array()
        for i in n:
                var a := TAU * i / n
                var jitter := 0.85 + 0.15 * rng.randf()
                body.append(pos + Vector2(cos(a) * hw * jitter, sin(a) * hh * jitter))
        draw_colored_polygon(body, water)
        # dark base rim under the bright edge line
        for i in n:
                draw_line(body[i], body[(i + 1) % n], E0.VOID, 2.6)
        # wet rim: a cyan light line around the whole edge (the readability fix)
        for i in n:
                draw_line(body[i], body[(i + 1) % n], Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.22), 1.3)
        # sky sheen: a bright drifting reflection band across the surface
        var sx := pos.x + sin(_t * 0.3 + s * 5.0) * hw * 0.4
        draw_circle(Vector2(sx, pos.y - 1.0), hw * 0.34, Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.09))
        draw_circle(Vector2(sx, pos.y - 1.0), hw * 0.15, Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.12))
        draw_line(Vector2(sx - hw * 0.22, pos.y - 1.0), Vector2(sx + hw * 0.22, pos.y - 1.0), Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.14), 1.4)
        # ripple rings breathing outward
        for ring in 2:
                var rk := fmod(_t * 0.22 + s + ring * 0.5, 1.0)
                var rr := hw * (0.15 + rk * 0.8)
                var pts := PackedVector2Array()
                for i in 10:
                        var a := TAU * i / 10
                        pts.append(pos + Vector2(cos(a) * rr, sin(a) * rr * hh / hw))
                pts.append(pts[0])
                draw_polyline(pts, Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.10 * (1.0 - rk)), 1.0)
        # glints of light on the surface
        for j in 3:
                var gx := pos.x + (rng.randf() - 0.5) * hw
                var gl := maxf(0.0, sin(_t * 1.7 + j * 2.4 + s * 9.0)) * 0.2
                draw_line(Vector2(gx - 4.0, pos.y - 1.5), Vector2(gx + 4.0, pos.y - 1.5), Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, gl), 1.0)

func _rubble(pos: Vector2, w: float, s: float) -> void:
        ## Collapse: seeded polygon blocks in a heap, some split, some
        ## half-buried, a bone or two where someone didn't leave.
        var rng := RandomNumberGenerator.new()
        rng.seed = hash(str(int(pos.x)) + "rub" + str(s))
        _contact_shadow(pos, w * 0.52, 0.4 + 0.1 * s)
        var n := maxi(4, int(w / 22.0))
        for i in n:
                var bx := pos.x + (rng.randf() - 0.5) * w * 0.9
                var by := pos.y - rng.randf() * 3.0 - i * 1.5
                var bw := 10.0 + rng.randf() * (w / n)
                var bh := 6.0 + rng.randf() * (w / n) * 0.7
                var stone := E0.DIRTY_STONE.darkened(0.02 + rng.randf() * 0.08)
                var pts := PackedVector2Array([
                        Vector2(bx - bw * 0.5, by), Vector2(bx - bw * 0.34, by - bh),
                        Vector2(bx + bw * 0.2, by - bh * (0.8 + rng.randf() * 0.4)),
                        Vector2(bx + bw * 0.5, by - bh * 0.3), Vector2(bx + bw * 0.3, by),
                ])
                draw_colored_polygon(pts, stone)
                # top catch-light edge so blocks separate from the floor
                draw_line(pts[1], pts[2], stone.lightened(0.14), 1.4)
                draw_line(pts[0], pts[1], stone.lightened(0.08), 1.0)
                draw_line(pts[1], Vector2(bx + bw * 0.05, by - bh * 0.35), stone.darkened(0.15), 1.0)
        # a bone showing in the heap
        if rng.randf() < 0.35:
                var ox := pos.x + (rng.randf() - 0.5) * w * 0.5
                draw_line(Vector2(ox, pos.y - 6.0), Vector2(ox + 9.0, pos.y - 4.0), Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, 0.6), 2.2)
                draw_circle(Vector2(ox, pos.y - 6.0), 1.6, Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, 0.6))
        # dust of the collapse still settling
        var dust := fmod(_t * 0.05 + s, 1.0)
        draw_circle(Vector2(pos.x + sin(dust * 9.0) * w * 0.3, pos.y - 26.0 * dust - 6.0), 1.1, Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.08 * sin(dust * PI)))

func _fan(pos: Vector2, w: float, s: float) -> void:
        ## Great ventilation fan: shroud ring bolted to a housing plate,
        ## wall-mount brackets so it never reads as a floating decal, safety
        ## grid over slow-turning blades. pos = hub centre.
        var r := w * 0.5
        # wall-mount brackets first (behind everything): two struts reaching
        # out to the shroud from the wall plane
        for side in [-1.0, 1.0]:
                var strut := pos + Vector2(side * (r + 2.0), 0.0)
                draw_rect(Rect2(strut.x - (3.0 if side > 0 else 9.0), strut.y - 4.0, 12.0, 8.0), E0.ASH.darkened(0.1))
                draw_circle(Vector2(strut.x + side * 4.0, strut.y), 1.8, E0.DIRTY_STONE)
        # backing housing (behind the blades)
        draw_circle(pos, r + 5.0, E0.CHARCOAL)
        draw_circle(pos, r, E0.VOID)
        # blades — rotating
        var spin := _t * (0.9 + s * 0.6) + s * 6.0
        draw_set_transform_matrix(Transform2D(spin, pos))
        for i in 4:
                var a := TAU * i / 4
                var pts := PackedVector2Array([
                        Vector2(cos(a) * r * 0.18, sin(a) * r * 0.18),
                        Vector2(cos(a + 0.28) * r * 0.95, sin(a + 0.28) * r * 0.95),
                        Vector2(cos(a + 0.52) * r * 0.95, sin(a + 0.52) * r * 0.95),
                        Vector2(cos(a + 0.16) * r * 0.18, sin(a + 0.16) * r * 0.18),
                ])
                draw_colored_polygon(pts, E0.ASH.lightened(0.03))
        draw_set_transform_matrix(Transform2D())
        # hub
        draw_circle(pos, r * 0.16, E0.ASH)
        draw_circle(pos, r * 0.07, E0.GOLD.darkened(0.3))
        # safety grid over the face (kept inside the shroud)
        var grid := Color(E0.ASH.r, E0.ASH.g, E0.ASH.b, 0.85)
        for gx in [-0.5, 0.0, 0.5]:
                draw_line(pos + Vector2(gx * r * 1.4, -r * 0.62), pos + Vector2(gx * r * 1.4, r * 0.62), grid, 1.4)
        draw_line(pos + Vector2(-r * 0.7, -r * 0.4), pos + Vector2(r * 0.7, -r * 0.4), grid, 1.2)
        draw_line(pos + Vector2(-r * 0.7, r * 0.4), pos + Vector2(r * 0.7, r * 0.4), grid, 1.2)
        # shroud ring + bolts
        draw_arc(pos, r + 3.0, 0, TAU, 28, E0.DIRTY_STONE.darkened(0.08), 5.0)
        for i in 6:
                var a := TAU * i / 6
                draw_circle(pos + Vector2(cos(a) * (r + 3.0), sin(a) * (r + 3.0)), 1.6, E0.ASH)

func _lift(pos: Vector2, w: float, h: float, s: float) -> void:
        ## Freight hoist: twin guide rails, a head beam with sheaves, a
        ## platform that climbs and sinks on a slow cycle, and the
        ## counterweight that moves against it. pos = rail base centre.
        var rw := 12.0
        var rail_x := pos.x - w * 0.5
        # rails
        for rx in [rail_x - rw, rail_x + w]:
                draw_rect(Rect2(rx, pos.y - h, rw, h), E0.ASH.darkened(0.05))
                draw_rect(Rect2(rx, pos.y - h, rw, 3.0), E0.ASH.lightened(0.08))
                for i in int(h / 46.0) + 1:
                        draw_rect(Rect2(rx - 2.0, pos.y - h + i * 46.0, rw + 4.0, 2.5), E0.DIRTY_STONE)
        # head beam + sheaves
        draw_rect(Rect2(rail_x - rw - 4.0, pos.y - h - 9.0, w + rw * 2 + 8.0, 9.0), E0.DIRTY_STONE)
        var sheave_y := pos.y - h - 4.5
        for sx in [rail_x - rw * 0.5, rail_x + w + rw * 0.5]:
                draw_circle(Vector2(sx, sheave_y), 4.0, E0.ASH.lightened(0.06))
        # platform cycle — climbs, holds, sinks
        var cycle := sin(_t * 0.14 + s * 5.0)
        var travel := (cycle * 0.5 + 0.5) * (h - 64.0)
        var plat_y := pos.y - 18.0 - travel
        # cables from sheaves to platform corners
        for cx in [rail_x - rw * 0.5, rail_x + w + rw * 0.5]:
                draw_line(Vector2(cx, sheave_y + 4.0), Vector2(cx, plat_y), E0.ASH, 1.5)
        # platform deck + edge rail + cargo — edge-lit so it reads mid-cycle
        draw_rect(Rect2(rail_x - rw * 0.6, plat_y - 8.0, w + rw * 1.2, 8.0), E0.ASH.lightened(0.06))
        draw_line(Vector2(rail_x - rw * 0.6, plat_y - 8.0), Vector2(rail_x + w + rw * 0.6, plat_y - 8.0), E0.ASH.lightened(0.16), 1.6)
        for rx2 in [rail_x - rw * 0.3, rail_x + w + rw * 0.3]:
                draw_line(Vector2(rx2, plat_y - 8.0), Vector2(rx2, plat_y - 24.0), E0.ASH, 2.0)
        draw_line(Vector2(rail_x - rw * 0.3, plat_y - 24.0), Vector2(rail_x + w + rw * 0.3, plat_y - 24.0), E0.ASH, 2.0)
        # a work lamp on the platform rail (the hoist is alive)
        var lamp_p := Vector2(rail_x + w * 0.5, plat_y - 24.0)
        draw_circle(lamp_p, 2.6, E0.GOLD.darkened(0.1))
        draw_circle(lamp_p, 8.0, Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.07 + 0.03 * (0.5 + 0.5 * sin(_t * 3.1 + s * 8.0))))
        # a crated reliquary riding the platform
        draw_rect(Rect2(pos.x - 9.0, plat_y - 22.0, 18.0, 14.0), E0.DIRTY_STONE.darkened(0.08))
        draw_rect(Rect2(pos.x - 9.0, plat_y - 16.0, 18.0, 2.0), E0.DIRTY_STONE.darkened(0.16))
        # counterweight against the far rail (moves opposite)
        var cw_y := pos.y - 24.0 - (h - 64.0 - travel)
        draw_rect(Rect2(rail_x + w + rw * 0.5 - 6.0, cw_y - 16.0, 12.0, 26.0), E0.DIRTY_STONE)
        draw_line(Vector2(rail_x + w + rw * 0.5, sheave_y + 4.0), Vector2(rail_x + w + rw * 0.5, cw_y - 16.0), E0.ASH, 1.5)
        # shadow under the platform, weaker as it rises
        var lift_k := clampf(travel / maxf(1.0, h - 64.0), 0.0, 1.0)
        _contact_shadow(Vector2(pos.x, pos.y), w * 0.5 * (1.0 - lift_k * 0.4), 0.32 * (1.0 - lift_k * 0.5))

func _stall(pos: Vector2, w: float, s: float) -> void:
        ## A pilgrims' market stall, abandoned mid-sale: posts, a sagging
        ## awning with torn strips that move in the draft, a counter with
        ## whatever was never sold.
        var rng := RandomNumberGenerator.new()
        rng.seed = hash(str(int(pos.x)) + "stl" + str(s))
        _contact_shadow(pos, w * 0.62, 0.36 + 0.08 * s)
        var wood := Color(0.15, 0.115, 0.095)
        var wood_hi := wood.lightened(0.08)
        # four posts (front pair taller) with visible grain — market-grade
        # sizing: the pilgrim stalls are STRUCTURES, not props
        var post_h := 82.0 + rng.randf() * 10.0
        for px in [pos.x - w * 0.46, pos.x + w * 0.42]:
                draw_rect(Rect2(px, pos.y - post_h, 6.0, post_h), wood)
                draw_rect(Rect2(px, pos.y - post_h, 2.0, post_h), wood_hi)
                draw_line(Vector2(px + 4.0, pos.y - post_h + 3.0), Vector2(px + 4.0, pos.y - 4.0), wood.darkened(0.12), 1.0)
        for px in [pos.x - w * 0.42, pos.x + w * 0.46]:
                draw_rect(Rect2(px, pos.y - post_h * 0.76, 6.0, post_h * 0.76), wood)
                draw_rect(Rect2(px, pos.y - post_h * 0.76, 2.0, post_h * 0.76), wood_hi)
        # sagging cloth awning (FABRIC, not stone): worn violet-brown weave.
        # Two layers — a lit top pitch and a shadowed underside — draping OVER
        # the posts with an overhang, so it reads as a ROOF, not a banner.
        var cloth := Color(0.34, 0.19, 0.17)
        var cloth_hi := Color(0.80, 0.52, 0.34)
        var cloth_lo := Color(0.66, 0.38, 0.26)
        var aw_top := pos.y - post_h - 4.0
        var aw_mid := pos.y - post_h * 0.86
        var aw_low := pos.y - post_h * 0.66
        # shadowed underside — WRONG to leave dark: this is the face the
        # viewer sees, and it is LIT from below by the stall's lanterns.
        # Dark roof above, glowing warm ceiling of cloth below = a lit stall.
        draw_colored_polygon(PackedVector2Array([
                Vector2(pos.x - w * 0.56, aw_mid), Vector2(pos.x + w * 0.56, aw_mid),
                Vector2(pos.x + w * 0.50, aw_low), Vector2(pos.x - w * 0.50, aw_low),
        ]), cloth_lo)
        # the light pooled under the awning (two lanterns + brazier-warm air)
        var pool_b := 0.5 + 0.5 * sin(_t * 1.7 + s * 4.0)
        draw_circle(Vector2(pos.x, aw_mid + 8.0), w * 0.42, Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.10 + 0.04 * pool_b))
        draw_circle(Vector2(pos.x, aw_mid + 8.0), w * 0.26, Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.08 + 0.04 * pool_b))
        # warm stripes on the lit underside (canvas weave over the light)
        for i in 6:
                var us_x := pos.x - w * 0.44 + w * 0.88 * i / 5.0
                draw_line(Vector2(us_x, aw_mid + 1.0), Vector2(us_x + w * 0.03, aw_low - 1.0), Color(cloth_lo.r + 0.12, cloth_lo.g + 0.07, cloth_lo.b + 0.04, 0.8), 1.6)
        # sag scallops along the front edge (dark seams on lit cloth)
        for i in 5:
                var sx0 := pos.x - w * 0.50 + w * 0.99 * i / 5.0
                draw_line(Vector2(sx0, aw_low), Vector2(sx0 + w * 0.19, aw_low - 2.5), cloth.darkened(0.1), 1.6)
        # lit top pitch (narrower, higher — dark roof against the light below)
        draw_colored_polygon(PackedVector2Array([
                Vector2(pos.x - w * 0.52, aw_top), Vector2(pos.x + w * 0.52, aw_top),
                Vector2(pos.x + w * 0.56, aw_mid), Vector2(pos.x - w * 0.56, aw_mid),
        ]), cloth)
        # ridge line (roof edge catches the light from below)
        draw_line(Vector2(pos.x - w * 0.52, aw_top), Vector2(pos.x + w * 0.52, aw_top), cloth_hi, 1.6)
        # sag scallops along the front edge — removed (moved to lit underside above)
        # holes in the roof
        for hx in [pos.x - w * 0.28, pos.x + w * 0.12]:
                draw_circle(Vector2(hx, aw_mid - 3.0), 3.5 + rng.randf() * 2.0, E0.VOID)
        # torn cloth strips hanging off the awning edge, moving in the draft
        for i in 5:
                var cx := pos.x - w * 0.44 + w * 0.88 * i / 4.0
                if rng.randf() < 0.65:
                        var sw := sin(_t * 1.1 + i * 1.7 + s * 5.0) * 0.3
                        var len := 14.0 + rng.randf() * 14.0
                        draw_set_transform_matrix(Transform2D(sw, Vector2(cx, aw_low)))
                        draw_colored_polygon(PackedVector2Array([
                                Vector2(-4.2, 0.0), Vector2(4.2, 0.0), Vector2(2.8, len), Vector2(-3.4, len * 0.9),
                        ]), cloth_hi)
                        draw_set_transform_matrix(Transform2D())
        # counter (wider, market-grade)
        draw_rect(Rect2(pos.x - w * 0.46, pos.y - 24.0, w * 0.92, 6.0), wood_hi)
        draw_rect(Rect2(pos.x - w * 0.44, pos.y - 18.0, w * 0.88, 5.0), wood)
        for lx in [pos.x - w * 0.40, pos.x + w * 0.36]:
                draw_rect(Rect2(lx, pos.y - 18.0, 6.0, 18.0), wood)
        # unsold wares: clay jars, basket, folded cloth, candle stub — LIT
        var jar_x := pos.x - w * 0.30
        draw_colored_polygon(PackedVector2Array([
                Vector2(jar_x - 9.0, pos.y - 22.0), Vector2(jar_x + 9.0, pos.y - 22.0),
                Vector2(jar_x + 6.5, pos.y - 44.0), Vector2(jar_x - 6.5, pos.y - 44.0),
        ]), E0.DIRTY_STONE.lightened(0.12))
        draw_line(Vector2(jar_x - 6.0, pos.y - 41.0), Vector2(jar_x + 6.0, pos.y - 41.0), E0.PARCH.darkened(0.1), 1.6)
        draw_rect(Rect2(jar_x - 7.0, pos.y - 49.0, 14.0, 4.0), E0.DIRTY_STONE.darkened(0.05))
        var jar2_x := pos.x - w * 0.16
        draw_colored_polygon(PackedVector2Array([
                Vector2(jar2_x - 7.0, pos.y - 22.0), Vector2(jar2_x + 7.0, pos.y - 22.0),
                Vector2(jar2_x + 5.0, pos.y - 38.0), Vector2(jar2_x - 5.0, pos.y - 38.0),
        ]), E0.DIRTY_STONE.lightened(0.08))
        draw_rect(Rect2(jar2_x - 5.5, pos.y - 42.0, 11.0, 3.5), E0.DIRTY_STONE.darkened(0.05))
        # a wicker basket with ash-root produce
        draw_colored_polygon(PackedVector2Array([
                Vector2(pos.x + w * 0.02 - 10.0, pos.y - 22.0), Vector2(pos.x + w * 0.02 + 10.0, pos.y - 22.0),
                Vector2(pos.x + w * 0.02 + 7.0, pos.y - 34.0), Vector2(pos.x + w * 0.02 - 7.0, pos.y - 34.0),
        ]), E0.PARCH.darkened(0.25))
        for bump in 3:
                draw_circle(Vector2(pos.x + w * 0.02 - 6.0 + bump * 6.0, pos.y - 35.0), 3.0, E0.PARCH.darkened(0.1))
        draw_rect(Rect2(pos.x - w * 0.05 + w * 0.12, pos.y - 30.0, w * 0.22, 7.0), cloth_hi)
        draw_line(Vector2(pos.x - w * 0.05 + w * 0.12, pos.y - 26.5), Vector2(pos.x + w * 0.31, pos.y - 26.5), cloth.darkened(0.15), 1.2)
        # two hanging lanterns off the front posts (the stall keeps its lights)
        for li in 2:
                var lamp := Vector2(pos.x + w * 0.44 - li * w * 0.88, pos.y - post_h * 0.55)
                draw_line(Vector2(lamp.x, pos.y - post_h + 8.0), lamp, E0.ASH, 1.4)
                var lamp_b := 0.5 + 0.5 * sin(_t * 2.3 + s * 7.0 + li * 2.1)
                draw_circle(lamp, 26.0, Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.055 + 0.03 * lamp_b))
                draw_circle(lamp, 13.0, Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.09 + 0.05 * lamp_b))
                draw_circle(lamp, 3.6, E0.GOLD.darkened(0.12))
                _flame_at(lamp.x, lamp.y - 4.5, s * 11.0 + li * 3.0, 0.85)
        # candle stub on the counter
        draw_rect(Rect2(pos.x + w * 0.24, pos.y - 29.0, 4.4, 7.0), Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.85))
        _flame_at(pos.x + w * 0.262, pos.y - 30.0, 3.0 + s * 7.0, 0.75)
        # a weight scale hanging off one post, swinging
        var scp := Vector2(pos.x + w * 0.45, pos.y - post_h + 4.0)
        var ssw := sin(_t * 0.9 + s * 7.0) * 0.16
        draw_set_transform_matrix(Transform2D(ssw, scp))
        draw_line(Vector2(0.0, 0.0), Vector2(0.0, 12.0), E0.ASH, 1.4)
        draw_line(Vector2(-7.0, 12.0), Vector2(7.0, 12.0), E0.ASH, 1.4)
        draw_line(Vector2(-7.0, 12.0), Vector2(-9.0, 19.0), E0.ASH, 1.0)
        draw_line(Vector2(7.0, 12.0), Vector2(9.0, 19.0), E0.ASH, 1.0)
        draw_circle(Vector2(-9.0, 21.0), 3.0, E0.DIRTY_STONE.darkened(0.1))
        draw_circle(Vector2(9.0, 21.0), 3.0, E0.DIRTY_STONE.darkened(0.1))
        draw_set_transform_matrix(Transform2D())

func _candelabra(pos: Vector2, h: float, s: float) -> void:
        ## Standing candelabra: tripod foot, wound stem, three rising arms,
        ## candles at different stages of burning down — the light of the
        ## counted, still kept. Bright enough to read at gameplay distance.
        _contact_shadow(pos, 16.0, 0.32 + 0.08 * s)
        var metal := E0.GOLD.darkened(0.22)
        var metal_hi := metal.lightened(0.14)
        # warm halo pooled around the whole stand
        var glow := 0.5 + 0.2 * sin(_t * 1.9 + s * 6.0)
        draw_circle(pos + Vector2(0, -h * 0.6), 30.0, Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.075 + 0.035 * glow))
        draw_circle(pos + Vector2(0, -h * 0.6), 17.0, Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.10 + 0.05 * glow))
        # tripod foot
        for i in 3:
                var a := PI * 0.5 + TAU * i / 3 + 0.3
                draw_line(pos + Vector2(0, -4.0), pos + Vector2(cos(a) * 14.0, maxf(0.0, sin(a) * 5.0)), metal, 2.8)
        draw_circle(pos + Vector2(0, -6.0), 4.5, metal_hi)
        # stem with wax runs + a bright edge thread
        draw_rect(Rect2(pos.x - 2.0, pos.y - h * 0.62, 4.0, h * 0.62 - 6.0), metal)
        draw_line(Vector2(pos.x - 2.0, pos.y - h * 0.62 + 2.0), Vector2(pos.x - 2.0, pos.y - 8.0), metal_hi, 1.2)
        for wy in [0.3, 0.55, 0.78]:
                draw_line(Vector2(pos.x + 2.0, pos.y - h * wy), Vector2(pos.x + 2.5, pos.y - h * wy - 6.0), Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.45), 1.3)
        # three arms rising off the stem — centre tall, sides lower
        var arms := [
                {a = -PI * 0.5, r = h * 0.16, y = -h * 0.62, ch = 12.0, ph = 0.0},
                {a = PI * 1.18, r = h * 0.30, y = -h * 0.5, ch = 9.0, ph = 2.7},
                {a = -PI * 0.18, r = h * 0.30, y = -h * 0.5, ch = 10.0, ph = 5.1},
        ]
        for arm in arms:
                var stem_p := Vector2(pos.x, pos.y + arm.y)
                var tip := stem_p + Vector2(cos(arm.a) * arm.r, sin(arm.a) * arm.r * 0.8)
                var ctrl := stem_p + Vector2(cos(arm.a) * arm.r * 0.5, sin(arm.a) * arm.r * 0.1 - 4.0)
                # arc arm as two bent segments (reads as forged iron)
                draw_line(stem_p, ctrl, metal, 2.2)
                draw_line(ctrl, tip, metal, 2.2)
                draw_circle(tip, 3.0, metal)
                # candle at its own stage of burning (fat, readable wax)
                var ch: float = arm.ch * (0.5 + 0.5 * absf(sin(arm.ph + s * 3.0)))
                draw_rect(Rect2(tip.x - 2.4, tip.y - ch, 4.8, ch), Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.88))
                draw_rect(Rect2(tip.x - 2.4, tip.y - ch, 1.6, ch), Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, 0.35))
                _flame_at(tip.x, tip.y - ch - 1.0, arm.ph + s * 9.0, 1.05)
        # crown finial
        draw_circle(Vector2(pos.x, pos.y - h * 0.62 - 6.0), 2.2, metal_hi)
