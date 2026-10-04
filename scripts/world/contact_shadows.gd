## ContactShadows — the ground holds every body. Soft layered ellipses
## under the player, every enemy, the npcs, the boss and the censor; each is
## projected onto the actual floor via a physics ray, so a jump reads as
## HEIGHT (the shadow stays on the ground and shrinks) and a floater reads
## as AIR. Drawn at the z=0 plane AFTER every other z=0 renderer (added last
## in the room build) — above the crafted floor, below every actor (z>=1).
## The null children's shadows glitch with them; the censor's breathes.
class_name ContactShadows
extends Node2D

var game: Game = null
var _actors: Array = []
var _refresh_t := 0.0
var _t := 0.0

# cached per-actor shadow state, refreshed by ray in _physics_process
var _shadows: Array = []

func setup(p_game: Game) -> void:
        game = p_game
        z_index = 0
        set_physics_process(true)

func _refresh_actors() -> void:
        ## World membership changes (censor arrives, enemies die) — rescan
        ## on a slow tick. Class-typed: props and doors never get shadows
        ## (they ground themselves with their own contact pads).
        _actors.clear()
        if game == null or not is_instance_valid(game.world):
                return
        if game.player != null and is_instance_valid(game.player):
                _actors.append(game.player)
        for ch in game.world.get_children():
                if ch is EnemyBase or ch is NPC or ch is Censor:
                        _actors.append(ch)

func _physics_process(delta: float) -> void:
        _t += delta
        _refresh_t -= delta
        if _refresh_t <= 0.0:
                _refresh_t = 0.4
                _refresh_actors()
        var space := get_world_2d().direct_space_state
        _shadows.clear()
        for a in _actors:
                if not is_instance_valid(a) or not (a as CanvasItem).visible:
                        continue
                var node2d: Node2D = a
                var origin := node2d.global_position + Vector2(0, -4.0)
                var params := PhysicsRayQueryParameters2D.create(
                        origin, origin + Vector2(0, 560.0), E0.L_WORLD)
                params.collide_with_areas = false
                params.collide_with_bodies = true
                var hit := space.intersect_ray(params)
                if hit.is_empty():
                        continue
                var gy: float = hit["position"].y
                var gap := gy - origin.y
                if gap < -8.0 or gap > 560.0:
                        continue
                var rx: float = node2d.get_meta("shadow_rx", _default_rx(a))
                # height law: the further the body from its shadow, the
                # smaller and fainter it reads — depth you can FEEL in a jump
                var shrink := clampf(1.0 - gap / 420.0, 0.42, 1.0)
                var alpha_k := clampf(1.0 - gap / 500.0, 0.30, 1.0)
                _shadows.append({
                        "pos": Vector2(origin.x, gy),
                        "rx": rx * (0.6 + 0.4 * shrink),
                        "k": alpha_k,
                        "glitch": node2d.has_meta("shadow_glitch") and bool(node2d.get_meta("shadow_glitch")),
                        "ph": float(hash(str(node2d.get_instance_id())) % 1000) * 0.01,
                })
        queue_redraw()

func _default_rx(a: Node) -> float:
        if a is BoundMartyr:
                return 30.0
        if a is Censor:
                return 17.0
        if a is NullChild:
                return 8.0
        return 13.0

func _draw() -> void:
        for s in _shadows:
                var pos: Vector2 = s["pos"]
                var rx: float = s["rx"]
                var k: float = s["k"]
                if s["glitch"]:
                        # null children: the shadow stutters out of phase
                        k *= 0.4 + 0.6 * (1.0 if fmod(_t * 9.0 + float(s["ph"]), 2.0) < 1.3 else 0.15)
                # three stacked layers = a soft-edged contact, not a sticker
                for i in 3:
                        var t := float(i) / 3.0
                        var a := 0.16 * k * (1.0 - t * 0.55)
                        _ellipse(pos, rx * (1.0 - t * 0.34), rx * (1.0 - t * 0.34) * 0.26,
                                Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, a))

func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
        var pts := PackedVector2Array()
        for i in 12:
                var ang := TAU * i / 12.0
                pts.append(c + Vector2(cos(ang) * rx, sin(ang) * ry))
        draw_colored_polygon(pts, col)

func shadow_count() -> int:
        return _shadows.size()
