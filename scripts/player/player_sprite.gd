## PlayerSprite — the painted vessel. Mirrors the rig's state machine onto
## SpriteFrames (idle / walk / jump / fall / 3-hit chain / hurt shimmer /
## death / interact / observe / roll). The procedural PlayerRig is kept as
## the fallback body and can be toggled live with F9.
class_name PlayerSprite
extends SpriteSkin

var player: Player
var _t := 0.0
var _shadow: ContactShadow
var _aura: VesselAura

class ContactShadow:
        extends Node2D
        var radius := 15.0
        var target: Node2D
        var _pts: PackedVector2Array = []
        func _init() -> void:
                z_index = -2
                _rebuild(radius)
        func _rebuild(r: float) -> void:
                _pts = PackedVector2Array()
                for i in 14:
                        var a := TAU * i / 14.0
                        _pts.append(Vector2(0, 2) + Vector2(cos(a) * r, sin(a) * r * 0.3))
        func _draw() -> void:
                var owner_alpha := 1.0
                if target:
                        owner_alpha = target.modulate.a
                # core + halo: reads as real contact, not a smudge
                draw_colored_polygon(_pts, Color(0.02, 0.02, 0.025, 0.5 * owner_alpha))
                var halo := PackedVector2Array()
                for i in 14:
                        var a := TAU * i / 14.0
                        halo.append(Vector2(0, 2) + Vector2(cos(a) * radius * 1.45, sin(a) * radius * 0.42))
                draw_colored_polygon(halo, Color(0.02, 0.02, 0.025, 0.22 * owner_alpha))

## THE VESSEL CARRIES ITS OWN LIGHT — the genre law (Blasphemous, Hollow
## Knight, Eastward): the protagonist is the one body that never sinks into
## the world. A soft warm bone-gold aura breathes BEHIND the painted body
## (additive, z=1: ABOVE every world layer — floors, dressing, fog veils —
## just under the skin at z=2). A candle the record carries through the
## dark; it reads strongest exactly where the world is darkest.
class VesselAura:
        extends Node2D
        var _t := 0.0
        var _k := 0.0
        func _init() -> void:
                z_index = 1
                var mat := CanvasItemMaterial.new()
                mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
                material = mat
        func _process(delta: float) -> void:
                _t += delta
                _k = minf(1.0, _k + delta * 1.6)   # eases in on spawn
                queue_redraw()
        func _draw() -> void:
                var glow := Lights.get_glow_texture()
                var breath := 1.0 + 0.05 * sin(_t * 1.4)
                var w := 118.0 * breath
                var h := 138.0 * breath
                var a := (0.30 + 0.04 * sin(_t * 1.4 + 1.1)) * _k
                draw_set_transform(Vector2(-w * 0.5, -46.0 - h * 0.5), 0.0,
                                Vector2(w / 128.0, h / 128.0))
                draw_texture_rect(glow, Rect2(Vector2.ZERO, Vector2(128, 128)), false,
                                Color(0.85, 0.72, 0.50, a))
                # a hotter heart at the chest — the record's seal
                var hw := 46.0
                draw_set_transform(Vector2(-hw * 0.5, -52.0 - hw * 0.5), 0.0,
                                Vector2(hw / 128.0, hw / 128.0))
                draw_texture_rect(glow, Rect2(Vector2.ZERO, Vector2(128, 128)), false,
                                Color(0.95, 0.85, 0.62, a * 0.55))
                draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func attach(p_player: Player) -> void:
        player = p_player
        _shadow = ContactShadow.new()
        _shadow.target = player
        player.add_child(_shadow)
        _aura = VesselAura.new()
        player.add_child(_aura)

func sync_state(delta: float) -> void:
        if player == null:
                return
        _t += delta
        var sprites_on := not GameState.debug_no_sprites
        visible = sprites_on
        if _aura:
                _aura.visible = sprites_on and player.hp > 0
        if _shadow:
                _shadow.visible = sprites_on
                var r := 16.0 if player.is_on_floor() else 12.0
                _shadow.radius = lerpf(_shadow.radius, r, delta * 10.0)
                _shadow._rebuild(_shadow.radius)
                _shadow.queue_redraw()
        if player.rig:
                player.rig.visible = not sprites_on
        flip_h = player.facing < 0
        # landing squash: scale.x out, scale.y in, spring back
        var sq: float = clampf(player.land_squash, 0.0, 1.0)
        var sk := 1.0 + 0.16 * sq
        var sh := 1.0 - 0.22 * sq
        # AIR STRETCH: rising stretches tall, falling stretches further —
        # the body reads the arc of the jump instead of swapping poses
        if player.hp > 0 and not player.is_on_floor() and sq < 0.2:
                var vy := clampf(player.velocity.y / 900.0, -1.0, 1.0)
                if vy < 0.0:
                        sk *= 1.0 + vy * 0.06
                        sh *= 1.0 - vy * 0.07
                else:
                        sk *= 1.0 - vy * 0.05
                        sh *= 1.0 + vy * 0.09
        scale = Vector2(sk, sh)
        # ATTACK ANTICIPATION: the first 70ms of a swing coils the body down
        # (windup crouch), then the strike overshoots tall — the painted pose
        # reads as effort even between its frames
        if player.hp > 0 and player._attack_idx >= 0:
                var ph: float = player._attack_phase
                if ph < 0.07:
                        var k := 1.0 - ph / 0.07
                        scale = Vector2(sk * (1.0 + 0.05 * k), sh * (1.0 - 0.06 * k))
                elif ph < 0.13:
                        var k2 := (ph - 0.07) / 0.06
                        scale = Vector2(sk * (1.0 - 0.03 * k2), sh * (1.0 + 0.04 * k2))
        # RUN LEAN: the vessel leans into its speed (a few degrees, springy)
        if player.hp > 0 and player.is_on_floor():
                var lean_k := clampf(absf(player.velocity.x) / E0.P_MAX_SPEED, 0.0, 1.0)
                rotation = lerpf(rotation, player.facing * lean_k * 0.085, delta * 9.0)
        else:
                rotation = lerpf(rotation, 0.0, delta * 7.0)

        # damage / iframe shimmer (same rules the rig used) — over a faint
        # constant self-lift: the vessel is the reader's eye anchor and must
        # never sink into the world it walks through (the WB-7 readability law)
        var m := Color(1.10, 1.10, 1.10, 1.0)
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
