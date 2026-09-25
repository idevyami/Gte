## Masonry — terrain as real material. Painterly stone / riveted-iron tile
## textures (palette-locked, pipeline-processed) sampled per block with
## deterministic offsets, plus the block grid, mortar, cracks, edge lighting
## and (at low consistency) blocks that have slipped out of place. Drawn once
## per build; redraws on stage change. Falls back to flat colored blocks.
class_name Masonry
extends Node2D

var rects: Array[Rect2] = []
var seed_val := 0
var style := "stone"
var _last_stage := 1
var _blocks := []      # cached per-rect generated block data
var _rubble := []     # surface debris: pebbles, bone bits, cracks, stains
var _tex: Texture2D = null

const BLOCK := Vector2(58, 26)

func setup(p_rects: Array[Rect2], p_seed: int, p_style := "stone") -> void:
        rects = p_rects
        seed_val = p_seed
        style = p_style
        var path := "res://art/environments/tex_metal.png" if style == "metal" else "res://art/environments/tex_stone.png"
        if ResourceLoader.exists(path):
                _tex = load(path)
        _generate()

func _generate() -> void:
        _blocks.clear()
        _rubble.clear()
        var rng := RandomNumberGenerator.new()
        rng.seed = hash(str(seed_val))
        for rect in rects:
                var blocks := []
                var cols := int(ceil(rect.size.x / BLOCK.x))
                var rows := int(ceil(rect.size.y / BLOCK.y))
                for row in rows:
                        for col in cols:
                                var jitter := rng.randf()
                                blocks.append({
                                        "pos": rect.position + Vector2(col, row) * BLOCK,
                                        "size": BLOCK - Vector2(3.0 + rng.randf() * 2.0, 2.5 + rng.randf() * 1.5),
                                        "jitter": jitter,
                                        "crack": rng.randf() < 0.16,
                                        "row": row,
                                        "uv": Vector2(rng.randf() * 4096.0, rng.randf() * 4096.0),
                                })
                _blocks.append(blocks)
                _scatter_rubble(rect, rng)
        _last_stage = GameState.stage
        queue_redraw()

func _scatter_rubble(rect: Rect2, rng: RandomNumberGenerator) -> void:
        ## Surface dressing along the TOP edge of load-bearing geometry —
        ## the city is decaying, not freshly mopped. Deterministic per room.
        var n := int(rect.size.x / 26.0)
        for i in n:
                var rx := rect.position.x + 8.0 + rng.randf() * (rect.size.x - 16.0)
                var roll := rng.randf()
                if roll < 0.44:
                        continue          # breathing room between debris
                var item := {
                        "pos": Vector2(rx, rect.position.y),
                        "kind": "pebble",
                        "size": rng.randf_range(1.6, 3.8),
                        "dark": rng.randf() < 0.5,
                        "squash": rng.randf_range(0.4, 0.7),
                }
                if roll > 0.86:
                        item["kind"] = "bit"          # bone shard / debris flake
                        item["size"] = rng.randf_range(3.0, 6.0)
                elif roll > 0.80:
                        item["kind"] = "crack"        # thin surface crack
                        item["size"] = rng.randf_range(10.0, 26.0)
                elif roll > 0.74:
                        item["kind"] = "stain"        # dark wear patch
                        item["size"] = rng.randf_range(9.0, 20.0)
                _rubble.append(item)

func _process(_delta: float) -> void:
        if GameState.stage != _last_stage:
                _generate()

func _draw() -> void:
        var stage: int = GameState.stage
        var tw := 512.0
        var th := 512.0
        if _tex:
                tw = float(_tex.get_width())
                th = float(_tex.get_height())
        for blocks in _blocks:
                for b in blocks:
                        var pos: Vector2 = b["pos"]
                        var size: Vector2 = b["size"]
                        # Stage 2+: the world's small wrongs. Blocks slip out of true.
                        if stage >= 2 and b["jitter"] > 0.86:
                                pos += Vector2((b["jitter"] - 0.86) * 90.0 * (1.0 if int(b["row"]) % 2 == 0 else -1.0), -3.0)
                        if stage >= 5 and b["jitter"] > 0.94:
                                pos += Vector2(0.0, -10.0)
                        # material value jitter within the locked range
                        var k: float = 0.82 + float(b["jitter"]) * 0.4
                        if _tex:
                                # each block samples its own window of the material tile
                                var uv: Vector2 = b["uv"]
                                var src := Rect2(fmod(uv.x, tw - size.x - 2.0), fmod(uv.y, th - size.y - 2.0), size.x, size.y)
                                draw_texture_rect_region(_tex, Rect2(pos, size), src, Color(k, k, k, 1.0))
                        else:
                                var col := Color(E0.DIRTY_STONE.r * k, E0.DIRTY_STONE.g * k, E0.DIRTY_STONE.b * k)
                                draw_rect(Rect2(pos, size), col)
                        # mortar shadow line under each block
                        draw_rect(Rect2(pos + Vector2(0, size.y), Vector2(size.x, 2.0)), E0.VOID)
                        # cracks
                        if b["crack"]:
                                var cx: float = pos.x + size.x * (0.3 + float(b["jitter"]) * 0.4)
                                draw_line(Vector2(cx, pos.y + 2.0), Vector2(cx - 4.0, pos.y + size.y - 2.0), E0.VOID, 1.0)
                        # top edge catches light
                        draw_rect(Rect2(pos, Vector2(size.x, 2.0)), Color(0.9, 0.88, 0.82, 0.16))
        _draw_rubble()

func _draw_rubble() -> void:
        for r in _rubble:
                var pos: Vector2 = r["pos"]
                var s: float = r["size"]
                match String(r["kind"]):
                        "pebble":
                                var col := E0.ASH if bool(r["dark"]) else E0.DIRTY_STONE
                                var pts := PackedVector2Array([
                                        pos + Vector2(-s, -s * float(r["squash"])),
                                        pos + Vector2(-s * 0.4, -s * 1.3),
                                        pos + Vector2(s * 0.5, -s * 1.1),
                                        pos + Vector2(s, -s * float(r["squash"]) * 0.5),
                                ])
                                draw_colored_polygon(pts, Color(col.r, col.g, col.b, 0.85))
                        "bit":
                                draw_line(pos + Vector2(-s * 0.5, -1.0), pos + Vector2(s * 0.5, -s * 0.35), Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.5), 1.6)
                                draw_line(pos + Vector2(s * 0.2, -1.0), pos + Vector2(s * 0.9, -2.0), Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.35), 1.2)
                        "crack":
                                var jag := PackedVector2Array([pos])
                                var cx := 0.0
                                while cx < s:
                                        cx += s * 0.25
                                        jag.append(pos + Vector2(cx, -rng_line_y(cx, s)))
                                var dark := Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.5)
                                for i in range(1, jag.size()):
                                        draw_line(jag[i - 1], jag[i], dark, 1.0)
                        "stain":
                                for k in 3:
                                        var t := float(k) / 3.0
                                        draw_circle(pos + Vector2((t - 0.5) * s * 0.5, -1.0 - t), s * (0.5 - t * 0.12), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.10 - t * 0.02))

func rng_line_y(x: float, s: float) -> float:
        ## deterministic pseudo-jag for surface cracks
        return 1.0 + 1.6 * absf(sin(x * 0.7 + s))
