## PlayerSprite — the painted vessel. Mirrors the rig's state machine onto
## SpriteFrames (idle / walk / jump / fall / 3-hit chain / hurt shimmer /
## death / interact / observe / roll). The procedural PlayerRig is kept as
## the fallback body and can be toggled live with F9.
class_name PlayerSprite
extends SpriteSkin

var player: Player
var _t := 0.0
var _shadow: ContactShadow

class ContactShadow:
        extends Node2D
        var radius := 15.0
        var target: Node2D
        var _pts: PackedVector2Array = []
        func _init() -> void:
                z_index = -2
                for i in 12:
                        var a := TAU * i / 12.0
                        _pts.append(Vector2(0, 2) + Vector2(cos(a) * radius, sin(a) * radius * 0.26))
        func _draw() -> void:
                var owner_alpha := 1.0
                if target:
                        owner_alpha = target.modulate.a
                draw_colored_polygon(_pts, Color(0.03, 0.03, 0.035, 0.38 * owner_alpha))

func attach(p_player: Player) -> void:
        player = p_player
        _shadow = ContactShadow.new()
        _shadow.target = player
        player.add_child(_shadow)

func sync_state(delta: float) -> void:
        if player == null:
                return
        _t += delta
        var sprites_on := not GameState.debug_no_sprites
        visible = sprites_on
        if _shadow:
                _shadow.visible = sprites_on
                var r := 15.0 if player.is_on_floor() else 11.0
                _shadow.radius = lerpf(_shadow.radius, r, delta * 10.0)
                _shadow.queue_redraw()
        if player.rig:
                player.rig.visible = not sprites_on
        flip_h = player.facing < 0

        # damage / iframe shimmer (same rules the rig used)
        var m := Color(1.0, 1.0, 1.0, 1.0)
        if player.hp > 0 and player.has_iframes() and not player.is_rolling():
                m.a = 0.45 if fmod(_t * 24.0, 2.0) < 1.0 else 0.85
        if player._hurt_flash > 0.0:
                m = m.lerp(Color(1.0, 0.36, 0.32), clampf(player._hurt_flash / 0.3, 0.0, 1.0) * 0.6)
        modulate = m

        # pose selection
        var game := get_tree().get_first_node_in_group("game")
        var observing: bool = game != null and game.observe_active
        var want := "idle"
        var speed := 1.0
        if player.hp <= 0:
                want = "death"
        elif player.is_rolling():
                want = "roll"
        elif player._attack_idx >= 0:
                want = "attack%d" % (player._attack_idx + 1)
        elif player.interact_pose_t > 0.0:
                want = "interact"
        elif observing and player.is_on_floor() and absf(player.velocity.x) < 30.0:
                want = "observe"
        elif not player.is_on_floor():
                want = "jump" if player.velocity.y < 0.0 else "fall"
        elif absf(player.velocity.x) > 30.0:
                want = "walk"
                speed = clampf(absf(player.velocity.x) / E0.P_MAX_SPEED, 0.55, 1.5)
        pose(want, speed)
