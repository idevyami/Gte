## UICraft — the shared material workshop for the diegetic interface.
## The census world does not own a single flat rectangle: every panel is a
## THING — brass housings with screws, glass tubes with fluid, parchment with
## grain and torn edges, wax pressed by an iron seal, ink stamped unevenly.
## All drawing is deterministic (seeded) and palette-locked to E0.
## WB-9 law: UI elements are physical artifacts, never floating debug panels.
class_name UICraft
extends RefCounted

## Deterministic paper grain, cached per key. Subtle mottling on parchment.
static var _grain_cache: Dictionary = {}

static func grain(key: String, strength := 0.05, tile := 96) -> ImageTexture:
        ## A seeded noise tile — the paper's tooth. Same seed, same paper, forever.
        if _grain_cache.has(key):
                return _grain_cache[key]
        var rng := RandomNumberGenerator.new()
        rng.seed = hash(key)
        var img := Image.create(tile, tile, false, Image.FORMAT_RGBA8)
        var base := Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.0)
        for y in tile:
                for x in tile:
                        # value noise: two octaves of seeded hash sampling, smoothed
                        var n1 := _vnoise(rng, x * 0.11, y * 0.11)
                        var n2 := _vnoise(rng, x * 0.31, y * 0.31)
                        var v := (n1 * 0.7 + n2 * 0.3 - 0.5) * 2.0
                        var c := base
                        c.a = clampf(absf(v) * strength, 0.0, strength)
                        if v > 0.0:
                                c = Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, c.a * 0.6)
                        else:
                                c = Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, c.a)
                        img.set_pixel(x, y, c)
        var tex := ImageTexture.create_from_image(img)
        _grain_cache[key] = tex
        return tex

static func _vnoise(rng: RandomNumberGenerator, x: float, y: float) -> float:
        ## Smoothed value noise in [0,1]; re-seeded per lattice point so the
        ## paper never shimmers between frames.
        var xi := floori(x)
        var yi := floori(y)
        var xf := x - xi
        var yf := y - yi
        var a := _h01(rng, xi, yi)
        var b := _h01(rng, xi + 1, yi)
        var cc := _h01(rng, xi, yi + 1)
        var d := _h01(rng, xi + 1, yi + 1)
        var ux := xf * xf * (3.0 - 2.0 * xf)
        var uy := yf * yf * (3.0 - 2.0 * yf)
        return lerpf(lerpf(a, b, ux), lerpf(cc, d, ux), uy)

static func _h01(rng: RandomNumberGenerator, x: int, y: int) -> float:
        ## Hash-ish [0,1) — rng state is what makes it deterministic per call order;
        ## we instead re-seed from the coords so tiles never shimmer between frames.
        var r := RandomNumberGenerator.new()
        r.seed = hash(Vector2i(x * 7919, y * 104729)) & 0x7fffffff
        return r.randf()

## ---------------------------------------------------------------- brass ----
## The instrument housing: beveled plate, brushed strokes, corner screws.
## tone shifts the metal between warm brass (HUD) and pale bone-brass (prompt).
static func brass(c: CanvasItem, r: Rect2, tone := 0.0, screws := true) -> void:
        var top := Color(E0.GOLD.r + 0.10 + tone * 0.06, E0.GOLD.g + 0.08, E0.GOLD.b + 0.05, 0.30)
        var bot := Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.55)
        var face := Color(E0.GOLD.r * (0.24 + tone * 0.06), E0.GOLD.g * 0.24, E0.GOLD.b * 0.22, 0.88)
        # face fill (translucent metal over the scene — the scene lives in it)
        c.draw_rect(r, face)
        # brushed metal: faint horizontal strokes, deterministic
        var rng := RandomNumberGenerator.new()
        rng.seed = hash(Vector2i(int(r.position.x), int(r.size.x)))
        for i in int(r.size.y / 7.0):
                var yy := r.position.y + 3.5 + i * 7.0 + rng.randf() * 2.0
                var xx := r.position.x + 2.0 + rng.randf() * r.size.x * 0.5
                var w := r.size.x * (0.18 + rng.randf() * 0.4)
                c.draw_line(Vector2(xx, yy), Vector2(xx + w, yy), Color(1, 1, 1, 0.016 + rng.randf() * 0.02), 1.0)
        # bevel: light catches the top edge, shadow pools at the bottom
        c.draw_rect(Rect2(r.position, Vector2(r.size.x, 2.0)), top)
        c.draw_rect(Rect2(r.position, Vector2(2.0, r.size.y)), top * 0.7)
        c.draw_rect(Rect2(Vector2(r.position.x, r.end.y - 2.0), Vector2(r.size.x, 2.0)), bot)
        c.draw_rect(Rect2(Vector2(r.end.x - 2.0, r.position.y), Vector2(2.0, r.size.y)), bot * 0.8)
        c.draw_rect(r, Color(E0.GOLD.r + 0.14, E0.GOLD.g + 0.10, E0.GOLD.b + 0.06, 0.55), false, 1.0)
        if screws:
                for corner in [r.position + Vector2(8, 8), Vector2(r.end.x - 8, r.position.y + 8),
                                r.position + Vector2(8, r.end.y - 8), Vector2(r.end.x - 8, r.end.y - 8)]:
                        screw(c, corner, 2.6)

## A slotted screw — the thing that holds the census world together.
static func screw(c: CanvasItem, pos: Vector2, rad := 2.6, slot_ang := 0.7) -> void:
        c.draw_circle(pos, rad, Color(0.10, 0.09, 0.08, 0.92))
        c.draw_circle(pos - Vector2(0.5, 0.5), rad * 0.8, Color(E0.GOLD.r * 0.42, E0.GOLD.g * 0.40, E0.GOLD.b * 0.38, 0.95))
        c.draw_circle(pos - Vector2(0.6, 0.6), rad * 0.45, Color(E0.GOLD.r * 0.55, E0.GOLD.g * 0.5, E0.GOLD.b * 0.45, 0.5))
        var dir := Vector2(cos(slot_ang), sin(slot_ang)) * rad * 0.78
        c.draw_line(pos - dir, pos + dir, Color(0.05, 0.05, 0.05, 0.9), 1.0)

## ------------------------------------------------------------- glass tube ----
## The integrity vessel: a glass tube of bone-bright fluid. The fluid keeps
## its own lag (damage ghost = draining), a meniscus caps the fill, bubbles
## rise when hurt, cracks web across the glass at low integrity.
static func glass_tube(c: CanvasItem, r: Rect2, fill: float, ghost: float,
                t: float, cracked: bool) -> void:
        # housing recess
        c.draw_rect(Rect2(r.position - Vector2(3, 3), r.size + Vector2(6, 6)), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.85))
        # metal end caps: the tube is clamped in brass collars with a rivet each
        for cap in [Rect2(r.position - Vector2(6, 4.5), Vector2(6.0, r.size.y + 9.0)),
                        Rect2(Vector2(r.end.x, r.position.y - 4.5), Vector2(6.0, r.size.y + 9.0))]:
                c.draw_rect(cap, Color(E0.GOLD.r * 0.40, E0.GOLD.g * 0.38, E0.GOLD.b * 0.34, 0.95))
                c.draw_rect(Rect2(cap.position, Vector2(cap.size.x, 1.5)), Color(E0.GOLD.r + 0.12, E0.GOLD.g + 0.09, E0.GOLD.b + 0.05, 0.6))
                c.draw_rect(Rect2(Vector2(cap.position.x, cap.end.y - 1.5), Vector2(cap.size.x, 1.5)), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.7))
                screw(c, cap.get_center(), 1.5)
        # interior void
        c.draw_rect(r, Color(0.03, 0.03, 0.035, 0.96))
        # ghost fluid (crimson lag draining behind the real level)
        c.draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(ghost, 0.0, 1.0), r.size.y)), Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.55))
        # real fluid: bone-bright with a hot core
        var fw := r.size.x * clampf(fill, 0.0, 1.0)
        if fw > 0.5:
                c.draw_rect(Rect2(r.position, Vector2(fw, r.size.y)), Color(E0.BONE.r * 0.9, E0.BONE.g * 0.86, E0.BONE.b * 0.78, 0.96))
                c.draw_rect(Rect2(r.position + Vector2(0, r.size.y * 0.18), Vector2(fw, r.size.y * 0.5)), Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, 0.35))
                # meniscus — the fluid's edge curls
                c.draw_rect(Rect2(Vector2(r.position.x + fw - 1.5, r.position.y), Vector2(1.5, r.size.y)), Color(1.0, 0.98, 0.92, 0.5))
        # etched segment ticks — cut INTO the glass, they read as scored lines
        for i in 4:
                var tx := r.position.x + r.size.x * (i + 1) / 5.0
                c.draw_line(Vector2(tx, r.position.y), Vector2(tx, r.end.y), Color(0.02, 0.02, 0.02, 0.75), 1.0)
                c.draw_line(Vector2(tx + 1.0, r.position.y), Vector2(tx + 1.0, r.end.y), Color(1, 1, 1, 0.10), 1.0)
        # glass sheen — two vertical highlights, the tube rounds toward us
        c.draw_rect(Rect2(r.position + Vector2(1.5, 1.0), Vector2(2.0, r.size.y - 2.0)), Color(1, 1, 1, 0.10))
        c.draw_rect(Rect2(Vector2(r.end.x - 3.5, r.position.y + 1.0), Vector2(2.0, r.size.y - 2.0)), Color(1, 1, 1, 0.05))
        # bubbles — slow rising motes in the fluid column (alive, not a static bar)
        var rng := RandomNumberGenerator.new()
        rng.seed = 991
        for i in 3:
                var ph := fposmod(t * (0.14 + 0.05 * i) + rng.randf(), 1.0)
                var bx := r.position.x + 3.0 + rng.randf() * maxf(2.0, fw - 6.0)
                var by := r.end.y - 3.0 - ph * (r.size.y - 6.0)
                if bx < r.position.x + fw - 2.0:
                        c.draw_circle(Vector2(bx, by), 1.1, Color(1, 1, 1, 0.35 * (1.0 - ph)))
        # cracks — only when the vessel itself is failing
        if cracked:
                var cr := RandomNumberGenerator.new()
                cr.seed = 4177
                var cc := r.get_center()
                for i in 5:
                        var ang := cr.randf() * TAU
                        var from := cc + Vector2(cos(ang), sin(ang)) * 2.0
                        var to := cc + Vector2(cos(ang + cr.randfn(0.0, 0.35)), sin(ang + cr.randfn(0.0, 0.35))) * (r.size.y * 0.42)
                        c.draw_line(from, to, Color(1, 1, 1, 0.30), 1.0)
                        c.draw_line(from + Vector2(0.5, 0.5), to + Vector2(0.5, 0.5), Color(0.05, 0.05, 0.05, 0.4), 1.0)
        # frame
        c.draw_rect(r, Color(E0.GOLD.r + 0.08, E0.GOLD.g + 0.06, E0.GOLD.b + 0.04, 0.7), false, 1.0)

## ------------------------------------------------------------ dial gauge ----
## The consistency dial: an engraved arc, a needle that trembles as reality
## thins. The needle sweeps from 100 (left-up) through 0 (right-up).
static func dial_gauge(c: CanvasItem, center: Vector2, radius: float, value: float,
                stage_col: Color, tremble: float, t: float) -> float:
        ## Returns the needle angle used (radians) — smoke pins the math.
        # housing recess
        c.draw_circle(center, radius + 7.0, Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.9))
        c.draw_circle(center, radius + 5.0, Color(E0.GOLD.r * 0.26, E0.GOLD.g * 0.24, E0.GOLD.b * 0.2, 0.9))
        c.draw_circle(center, radius + 3.0, Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.95))
        # the dial face — a bone-pale disc so the needle reads
        c.draw_circle(center, radius + 2.0, Color(E0.PARCH.r * 0.30, E0.PARCH.g * 0.30, E0.PARCH.b * 0.30, 0.24))
        # engraved arc scale: from 225° (100) to -45° (0) — the wide sweep
        var a_from := deg_to_rad(210.0)
        var a_to := deg_to_rad(-30.0)
        # bezel: the dial is RECESSED — light catches the upper-left rim, shadow
        # pools on the lower-right (the physicality law: light from above-left)
        c.draw_arc(center, radius + 6.0, deg_to_rad(120.0), deg_to_rad(300.0), 28, Color(E0.GOLD.r + 0.22, E0.GOLD.g + 0.17, E0.GOLD.b + 0.10, 0.55), 2.5, true)
        c.draw_arc(center, radius + 6.0, deg_to_rad(-60.0), deg_to_rad(120.0), 28, Color(E0.VOID.r + 0.02, E0.VOID.g + 0.02, E0.VOID.b + 0.02, 0.8), 2.5, true)
        c.draw_arc(center, radius, a_from, a_to, 42, Color(E0.GOLD.r + 0.06, E0.GOLD.g + 0.04, E0.GOLD.b, 0.6), 2.0, true)
        # end stops: a gold dot marks 100, a crimson dot marks the floor
        var d100 := Vector2(cos(a_from), sin(a_from))
        var d0 := Vector2(cos(a_to), sin(a_to))
        c.draw_circle(center + d100 * (radius - 1.0), 2.4, Color(E0.GOLD.r + 0.15, E0.GOLD.g + 0.1, E0.GOLD.b, 0.9))
        c.draw_circle(center + d0 * (radius - 1.0), 2.2, Color(E0.CRIMSON.r + 0.08, E0.CRIMSON.g + 0.04, E0.CRIMSON.b + 0.03, 0.95))
        # major ticks at 0/25/50/75/100 with engraved double-line look
        for v in [0, 25, 50, 75, 100]:
                var ang := dial_angle(value_scale(v))
                var d1 := Vector2(cos(ang), sin(ang))
                c.draw_line(center + d1 * (radius - 6.0), center + d1 * radius, Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, 0.85), 2.0)
        # minor ticks
        for v in range(5, 100, 5):
                if v % 25 != 0:
                        var ang := dial_angle(value_scale(v))
                        var d1 := Vector2(cos(ang), sin(ang))
                        c.draw_line(center + d1 * (radius - 3.0), center + d1 * (radius - 1.0), Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, 0.35), 1.0)
        # the working arc: lit from 100 down to the current value
        var v_ang := dial_angle(value_scale(clampf(value, 0.0, 100.0)))
        c.draw_arc(center, radius - 2.0, a_from, v_ang, 30, Color(stage_col.r, stage_col.g, stage_col.b, 0.85), 2.5, true)
        # danger zone etched (0..25) — crimson hatched arc
        c.draw_arc(center, radius + 2.5, deg_to_rad(-30.0), deg_to_rad(30.0), 10, Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.5), 2.0, true)
        # needle: gold with a crimson tip, hub screw, tremble at high stages
        var trem := sin(t * 22.0) * 0.02 + sin(t * 31.7) * 0.012
        var n_ang := v_ang + trem * tremble
        var nd := Vector2(cos(n_ang), sin(n_ang))
        var tip := center + nd * (radius - 4.0)
        var tail := center - nd * (radius * 0.22)
        var side := Vector2(-nd.y, nd.x)
        var poly := PackedVector2Array([
                tip, center + side * 1.9 + nd * radius * 0.1,
                tail + side * 3.1, tail - side * 3.1,
                center - side * 1.9 + nd * radius * 0.1])
        c.draw_colored_polygon(poly, Color(E0.GOLD.r + 0.12, E0.GOLD.g + 0.08, E0.GOLD.b + 0.04, 0.96))
        # needle shadow on the dial face — it floats a hair above the enamel
        c.draw_line(tip + Vector2(1.6, 2.2), center + Vector2(1.6, 2.2), Color(0.0, 0.0, 0.0, 0.35), 2.0)
        c.draw_line(tip, tip - nd * 7.0, Color(E0.CRIMSON.r + 0.1, E0.CRIMSON.g + 0.05, E0.CRIMSON.b + 0.05, 0.95), 2.0)
        screw(c, center, 3.2, t * 0.2)
        return n_ang

## Consistency value [0..100] -> gauge angle. 100 sits at 210°, 0 at -30°.
static func dial_angle(v: float) -> float:
        return deg_to_rad(210.0) + (1.0 - clampf(v, 0.0, 1.0)) * deg_to_rad(-240.0)

static func value_scale(v: float) -> float:
        return clampf(v / 100.0, 0.0, 1.0)

## -------------------------------------------------------------- wax seal ----
## Pressed wax: an irregular-rim disc with a sigil struck into it. The iron
## hits at press (see seal_press), then the wax cools.
static func wax_seal(c: CanvasItem, pos: Vector2, rad: float, col: Color, sigil := 0, press := 1.0) -> void:
        var p := clampf(press, 0.2, 1.0)
        var rng := RandomNumberGenerator.new()
        rng.seed = 700 + sigil
        # irregular rim — wax pools where it wants to
        var pts := PackedVector2Array()
        for i in 14:
                var ang := TAU * i / 14.0
                var rr := rad * (0.86 + rng.randf() * 0.22) * p
                pts.append(pos + Vector2(cos(ang), sin(ang)) * rr)
        c.draw_colored_polygon(pts, Color(col.r * 0.5, col.g * 0.5, col.b * 0.5, 0.97))
        # pressed face — slightly smaller, brighter
        var pts2 := PackedVector2Array()
        for i in 14:
                var ang := TAU * i / 14.0
                var rr := rad * (0.74 + rng.randf() * 0.10) * p
                pts2.append(pos + Vector2(cos(ang), sin(ang)) * rr)
        c.draw_colored_polygon(pts2, Color(col.r * 0.78, col.g * 0.78, col.b * 0.78, 0.98))
        # the sigil struck in — dark inset, light lip (engraved law)
        var s := rad * 0.42 * p
        var inset := Color(col.r * 0.28, col.g * 0.28, col.b * 0.28, 0.95)
        var lip := Color(col.r * 1.35 + 0.08, col.g * 1.35 + 0.08, col.b * 1.35 + 0.08, 0.55)
        match sigil:
                0:  # SYSTEM — the double slash struck through
                        c.draw_line(pos + Vector2(-s * 0.7, -s) + Vector2(0.5, 0.5), pos + Vector2(s * 0.5, s) + Vector2(0.5, 0.5), inset, 2.5)
                        c.draw_line(pos + Vector2(-s * 0.3, -s) + Vector2(0.5, 0.5), pos + Vector2(s * 0.9, s) + Vector2(0.5, 0.5), inset, 2.5)
                        c.draw_line(pos + Vector2(-s * 0.7, -s), pos + Vector2(s * 0.5, s), lip, 1.2)
                        c.draw_line(pos + Vector2(-s * 0.3, -s), pos + Vector2(s * 0.9, s), lip, 1.2)
                1:  # MARTYR — the X bound
                        c.draw_line(pos + Vector2(-s, -s) + Vector2(0.5, 0.5), pos + Vector2(s, s) + Vector2(0.5, 0.5), inset, 2.5)
                        c.draw_line(pos + Vector2(s, -s) + Vector2(0.5, 0.5), pos + Vector2(-s, s) + Vector2(0.5, 0.5), inset, 2.5)
                        c.draw_line(pos + Vector2(-s, -s), pos + Vector2(s, s), lip, 1.2)
                        c.draw_line(pos + Vector2(s, -s), pos + Vector2(-s, s), lip, 1.2)
                2:  # PENITENT — the standing stroke
                        c.draw_line(pos + Vector2(0, -s) + Vector2(0.5, 0.5), pos + Vector2(0, s) + Vector2(0.5, 0.5), inset, 3.0)
                        c.draw_line(pos + Vector2(0, -s), pos + Vector2(0, s), lip, 1.2)
                3:  # MEASURER — the I with serif feet
                        c.draw_line(pos + Vector2(0, -s) + Vector2(0.5, 0.5), pos + Vector2(0, s) + Vector2(0.5, 0.5), inset, 2.5)
                        c.draw_line(pos + Vector2(-s * 0.6, -s) + Vector2(0.5, 0.5), pos + Vector2(s * 0.6, -s) + Vector2(0.5, 0.5), inset, 2.0)
                        c.draw_line(pos + Vector2(0, -s), pos + Vector2(0, s), lip, 1.2)
                _:  # default — the census diamond
                        var d := PackedVector2Array([pos + Vector2(0, -s) + Vector2(0.5, 0.5), pos + Vector2(s, 0) + Vector2(0.5, 0.5),
                                pos + Vector2(0, s) + Vector2(0.5, 0.5), pos + Vector2(-s, 0) + Vector2(0.5, 0.5)])
                        c.draw_colored_polygon(d, inset)
                        c.draw_polyline(PackedVector2Array([pos + Vector2(0, -s), pos + Vector2(s, 0), pos + Vector2(0, s), pos + Vector2(-s, 0), pos + Vector2(0, -s)]), lip, 1.2)
        # one glossy highlight — the wax caught the light as it set
        c.draw_circle(pos + Vector2(-rad * 0.3, -rad * 0.34), rad * 0.16 * p, Color(1, 1, 1, 0.10))

## ----------------------------------------------------------- parchment ----
## A census sheet: parchment fill, grain, aged darkened edges, torn bottom,
## filing holes punched along the left, ledger ruling under the lines.
## brightness 0..1: how fresh the sheet is (dialogue = bright writing paper,
## ledger = aged archive stock).
static func parchment(c: CanvasItem, r: Rect2, key: String, torn_bottom := true, holes := 3, brightness := 0.9) -> void:
        # aged fill — parchment darkened toward every edge
        var pb := clampf(brightness, 0.35, 1.0)
        c.draw_rect(r, Color(E0.PARCH.r * pb + 0.04, E0.PARCH.g * pb + 0.035, E0.PARCH.b * pb + 0.03, 0.975))
        # vertical fiber grade: slightly uneven bands (hand-laid paper)
        for i in int(r.size.x / 26.0):
                var xx := r.position.x + i * 26.0
                c.draw_rect(Rect2(Vector2(xx, r.position.y), Vector2(13.0, r.size.y)), Color(1, 1, 1, 0.012))
        # the tooth — grain tiled (stronger on aged stock)
        var g := grain(key)
        var src := Rect2(0, 0, 96, 96)
        c.draw_texture_rect_region(g, r.grow(-3), src, Color(1, 1, 1, 0.35 + (1.0 - pb) * 0.5))
        # aged edges — burnt umber creeping in from all sides
        for i in 4:
                var k := float(i) / 4.0
                var e := 3.0 + i * 3.5
                c.draw_rect(Rect2(r.position + Vector2(e, e), r.size - Vector2(e * 2, e * 2)), Color(E0.VOID.r + 0.03, E0.VOID.g + 0.02, E0.VOID.b + 0.01, 0.0), false)
                c.draw_rect(Rect2(r.position, Vector2(r.size.x, e)), Color(E0.BLOOD.r + 0.05, E0.BLOOD.g + 0.03, E0.BLOOD.b + 0.02, 0.10 - k * 0.02))
                c.draw_rect(Rect2(Vector2(r.position.x, r.end.y - e), Vector2(r.size.x, e)), Color(E0.BLOOD.r + 0.05, E0.BLOOD.g + 0.03, E0.BLOOD.b + 0.02, 0.13 - k * 0.02))
                c.draw_rect(Rect2(r.position, Vector2(e, r.size.y)), Color(E0.BLOOD.r + 0.04, E0.BLOOD.g + 0.02, E0.BLOOD.b + 0.02, 0.08 - k * 0.015))
                c.draw_rect(Rect2(Vector2(r.end.x - e, r.position.y), Vector2(e, r.size.y)), Color(E0.BLOOD.r + 0.04, E0.BLOOD.g + 0.02, E0.BLOOD.b + 0.02, 0.08 - k * 0.015))
        # torn bottom edge — deckled strips, the sheet was ripped from a roll.
        # LAW: every strip keeps a real width and stays inside the sheet — an
        # unclamped tooth or a degenerate strip self-intersects and the canvas
        # triangulator rejects the polygon (found by renderer bisection).
        if torn_bottom:
                var rng := RandomNumberGenerator.new()
                rng.seed = hash(key + "torn")
                var y0 := r.end.y - 4.0
                var x := r.position.x
                while x < r.end.x - 1.0:
                        var w := minf(8.0 + rng.randf() * 16.0, r.end.x - x)
                        # the tooth dips UP into the sheet, never past the
                        # bottom edge (a tooth below the edge crosses it)
                        var dy := minf(rng.randf() * 6.0, 3.5)
                        if w >= 2.0:
                                var pts := PackedVector2Array([
                                        Vector2(x, y0 - 3.0),
                                        Vector2(x + w * 0.5, y0 + dy),
                                        Vector2(x + w, y0 - 3.0),
                                        Vector2(x + w, r.end.y),
                                        Vector2(x, r.end.y)])
                                c.draw_colored_polygon(pts, Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.9))
                        x += w
        # punched filing holes — the sheet hangs in a binder of records
        for i in holes:
                var hy := r.position.y + 26.0 + i * (r.size.y - 52.0) / maxf(1.0, holes - 1)
                c.draw_circle(Vector2(r.position.x + 11.0, hy), 4.2, Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.92))
                c.draw_arc(Vector2(r.position.x + 11.0, hy), 4.2, 0, TAU, 12, Color(E0.BLOOD.r + 0.06, E0.BLOOD.g + 0.04, E0.BLOOD.b, 0.25), 1.0, true)

## Ledger ruling — a ruled line under a row of a census record.
static func ruling(c: CanvasItem, from: Vector2, to: Vector2, strong := false) -> void:
        var col := Color(E0.BLOOD.r + 0.06, E0.BLOOD.g + 0.05, E0.BLOOD.b + 0.04, 0.22 if strong else 0.13)
        c.draw_line(from, to, col, 1.0)

## --------------------------------------------------------------- stamps ----
## Stamped ink text: uneven pressure, a hair of rotation, the die's edge dry.
static func stamp_text(c: CanvasItem, font: FontFile, pos: Vector2, text: String,
                col: Color, size := 13, rot := 0.0, seed_n := 0) -> void:
        if font == null:
                return
        var rng := RandomNumberGenerator.new()
        rng.seed = hash(text) + seed_n
        # per-character ink density — the die never lands flat
        var x := 0.0
        for i in text.length():
                var ch := text[i]
                var wch := font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
                var ink := 0.84 + rng.randf() * 0.16
                var cc := Color(col.r, col.g, col.b, col.a * ink)
                var dy := (rng.randf() - 0.5) * 1.2
                c.draw_string(font, pos + Vector2(x, dy), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size, cc)
                x += wch

## A stamped serial tag — the small brass plate riveted to census property.
static func serial_tag(c: CanvasItem, pos: Vector2, text: String) -> void:
        if E0.mono == null:
                return
        var w := E0.mono.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 12.0
        var r := Rect2(pos, Vector2(w, 15.0))
        c.draw_rect(r, Color(E0.GOLD.r * 0.30, E0.GOLD.g * 0.28, E0.GOLD.b * 0.24, 0.95))
        c.draw_rect(Rect2(r.position, Vector2(r.size.x, 1.0)), Color(E0.GOLD.r + 0.1, E0.GOLD.g + 0.08, E0.GOLD.b, 0.5))
        c.draw_rect(Rect2(Vector2(r.position.x, r.end.y - 1.0), Vector2(r.size.x, 1.0)), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.7))
        c.draw_string(E0.mono, pos + Vector2(6.0, 11.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, 0.8))
        screw(c, r.position + Vector2(3.5, 3.5), 1.4)
        screw(c, Vector2(r.end.x - 3.5, r.end.y - 3.5), 1.4)
