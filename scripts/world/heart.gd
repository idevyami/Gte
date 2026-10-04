## TheHeart — THE HEART OF THE DESIGN. Grown, not built. It beats; the
## rotors must be aligned to its rhythm. Observable; its fuel is sealed.
class_name TheHeart
extends EntityNode

var beat_t := 0.0
var aligned_cache := false

func setup_heart() -> void:
        setup("HEART_OF_THE_DESIGN", "HEART_OF_THE_DESIGN", "heart")
        extra["anchor_y"] = 70.0
        extra["br_w"] = 180.0
        extra["br_h"] = 150.0

func _refresh_prompt() -> void:
        prompt = "OBSERVE THE HEART"

func interact(game) -> void:
        if GameState.has_flag(GameState.F_HEART_ALIGNED):
                game.system_message("IT BEATS IN SEQUENCE NOW. YOU DID THAT. IT HAS NOT STOPPED SINCE.")
        else:
                game.system_message("THE ROTORS ARE DE-SYNCED FROM THE RHYTHM. READ THEM WITH [TAB] — THE SEQUENCE IS IN THEIR MEMORY.")

func _process(delta: float) -> void:
        anim_t += delta
        var bpm := 60.0
        if GameState.has_flag(GameState.F_HEART_ALIGNED):
                bpm = 78.0
        beat_t += delta * bpm / 60.0
        queue_redraw()

func _draw() -> void:
        # the machine-heart: a great dark chamber in a cage of pipes and tracery
        var beat := pow(maxf(0.0, sin(beat_t * TAU)), 3.0)
        var scale_k := 1.0 + beat * 0.04
        # grounding: the mount's weight on the floor — contact shadow first
        for i in 3:
                var t := float(i) / 3.0
                _shadow_ellipse(Vector2(0, -1.0 - t * 1.5), 42.0 * (1.0 - t * 0.2), 8.0 * (1.0 - t * 0.25), 0.18 * (1.0 - t * 0.4))
        # pipe cage
        for i in 6:
                var a := PI * (0.1 + 0.8 * i / 5.0)
                var dir := Vector2(cos(a), sin(a) * -0.8)
                draw_line(dir * 60.0, dir * 96.0, E0.ASH, 7.0)
                draw_circle(dir * 96.0, 5.0, E0.DIRTY_STONE)
        # the chamber — DRIED blood, not fresh paint: desaturated crimson
        # with an inner VIOLET-cold pulse (the machine-heart is wrong inside,
        # and the wrongness reads as cold light, not saturation)
        var col := E0.BLOOD.lerp(E0.CRIMSON.darkened(0.16), beat)
        var r := 52.0 * scale_k
        draw_circle(Vector2(0, -70.0), r, E0.CHARCOAL)
        draw_circle(Vector2(0, -70.0), r - 7.0, col)
        draw_circle(Vector2(0, -70.0), r - 18.0, col.darkened(0.35))
        # the cold core: violet light guttering inside the chamber on the beat
        var cold := Color(E0.VIOLET.r + 0.10 * beat, E0.VIOLET.g + 0.06 * beat, E0.VIOLET.b + 0.14 * beat,
                0.55 + 0.30 * beat)
        draw_circle(Vector2(0, -70.0), (r - 26.0) * (0.9 + 0.14 * beat), cold)
        draw_circle(Vector2(0, -70.0), (r - 34.0) * (0.9 + 0.10 * beat), Color(cold.r, cold.g, cold.b, cold.a * 0.5))
        # veins of gold when aligned
        if GameState.has_flag(GameState.F_HEART_ALIGNED):
                for i in 5:
                        var a := TAU * i / 5.0 + anim_t * 0.3
                        draw_line(Vector2(0, -70.0) + Vector2(cos(a), sin(a)) * (r - 6.0),
                                Vector2(0, -70.0) + Vector2(cos(a), sin(a)) * (r + 14.0 + beat * 6.0),
                                Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.5), 2.0)
        # heat bloom: the heart is the room's light source — layered DRIED
        # crimson halo breathing with the beat, spilling onto the floor below
        # (kept dry: blood-colored light, never neon)
        for i in 4:
                var t := float(i) / 4.0
                draw_circle(Vector2(0, -70.0), r + 26.0 + t * 46.0,
                        Color(E0.BLOOD.r, E0.BLOOD.g, E0.BLOOD.b, (0.045 + 0.030 * beat) * (1.0 - t)))
        _shadow_ellipse(Vector2(0, -2.0), 76.0, 15.0, 0.04 + 0.02 * beat, true)
        # the cradle: a heavy mounting plate with bolts, angled struts
        # holding the chamber from below like a carried reliquary
        draw_rect(Rect2(-46, -18, 92, 18), E0.DIRTY_STONE.darkened(0.12))
        draw_rect(Rect2(-54, -8, 108, 8), E0.DIRTY_STONE.darkened(0.2))
        for bx in [-44.0, -14.0, 16.0, 44.0]:
                draw_circle(Vector2(bx, -13.0), 2.4, E0.ASH)
                draw_circle(Vector2(bx, -13.0), 1.0, E0.VOID)
        for sgn in [-1.0, 1.0]:
                draw_colored_polygon(PackedVector2Array([
                        Vector2(sgn * 40.0, -18.0), Vector2(sgn * 52.0, -18.0),
                        Vector2(sgn * 62.0, -84.0), Vector2(sgn * 48.0, -84.0),
                ]), E0.ASH.darkened(0.05))
                draw_line(Vector2(sgn * 46.0, -18.0), Vector2(sgn * 55.0, -84.0), E0.DIRTY_STONE, 4.0)
        for i in 3:
                draw_rect(Rect2(-24 + i * 18, -26, 10, 8), E0.ASH)
        # cable-tracery rising into the dark — thick enough to carry weight
        draw_line(Vector2(-52, -96), Vector2(-78, -170), E0.ASH, 4.0)
        draw_line(Vector2(52, -96), Vector2(80, -168), E0.ASH, 4.0)
        draw_line(Vector2(0, -122), Vector2(0, -176), E0.ASH, 4.0)
        for y in [-120.0, -142.0, -164.0]:
                draw_circle(Vector2(-y * 0.42, y), 2.2, E0.DIRTY_STONE)
                draw_circle(Vector2(y * 0.42, y), 2.2, E0.DIRTY_STONE)

func _shadow_ellipse(c: Vector2, rx: float, ry: float, a: float, warm := false) -> void:
        var pts := PackedVector2Array()
        for i in 14:
                var ang := TAU * i / 14.0
                pts.append(c + Vector2(cos(ang) * rx, sin(ang) * ry))
        if warm:
                draw_colored_polygon(pts, Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, a))
        else:
                draw_colored_polygon(pts, Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, a))
