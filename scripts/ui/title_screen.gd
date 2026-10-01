## TitleScreen — the first frame of the game: ash, the city backdrop, and a
## designation instead of a title screen promise.
class_name TitleScreen
extends Control

signal new_game_requested
signal continue_requested
signal options_requested

var menu: Array = []
var idx := 0
var anim_t := 0.0
var _tex: Texture2D
var _flicker := 0.0

func _ready() -> void:
        set_anchors_preset(Control.PRESET_FULL_RECT)
        _tex = load("res://art/backdrops/backdrop_city.png")
        visible = true
        _rebuild_menu()

func _rebuild_menu() -> void:
        menu = [{"label": "RESTORE THE WORLD", "action": "new"}]
        if GameState.has_save():
                menu.append({"label": "CONTINUE", "action": "continue"})
        menu.append({"label": "OPTIONS", "action": "options"})
        menu.append({"label": "QUIT", "action": "quit"})
        idx = 0

func _process(delta: float) -> void:
        anim_t += delta
        _flicker = maxf(0.0, _flicker - delta * 4.0)
        if randf() < 0.003:
                _flicker = 1.0
        if GameState.options_open:
                queue_redraw()
                return
        if Input.is_action_just_pressed("move_up"):
                idx = (idx - 1 + menu.size()) % menu.size()
                AudioManager.play_sfx("sfx_ui_move", -8.0)
        if Input.is_action_just_pressed("move_down"):
                idx = (idx + 1) % menu.size()
                AudioManager.play_sfx("sfx_ui_move", -8.0)
        if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("jump"):
                _confirm()
        if Input.is_action_just_pressed("attack"):
                _confirm()
        queue_redraw()

func _confirm() -> void:
        AudioManager.play_sfx("sfx_ui_confirm", -4.0)
        var action: String = menu[idx]["action"]
        if action == "new":
                new_game_requested.emit()
        elif action == "continue":
                continue_requested.emit()
        elif action == "options":
                options_requested.emit()
        elif action == "quit":
                get_tree().quit()

func _draw() -> void:
        var vp := get_viewport_rect().size
        draw_rect(Rect2(Vector2.ZERO, vp), E0.VOID)
        # backdrop, dark — breathes almost imperceptibly, like the city
        if _tex != null:
                var ts := _tex.get_size()
                var scale_k := maxf(vp.x / ts.x, vp.y / ts.y) * 1.1
                var dst := Rect2(Vector2.ZERO, ts * scale_k)
                var drift := sin(anim_t * 0.05) * 10.0
                dst.position = (vp - dst.size) * 0.5 + Vector2(drift, 30 + sin(anim_t * 0.04) * 5.0)
                draw_texture_rect_region(_tex, dst, Rect2(Vector2.ZERO, ts), Color(0.5, 0.5, 0.52, 0.9))
        # darkening gradient
        for i in 8:
                var t := float(i) / 7.0
                draw_rect(Rect2(0, vp.y * t, vp.x, vp.y / 7.0), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.35 * t))
        # edge framing: side + top curtains pull the eye to centre
        for i in 6:
                var k := float(i) / 6.0
                var a := 0.30 * (1.0 - k)
                draw_rect(Rect2(k * 170.0, 0, 170.0, vp.y), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, a / 6.0))
                draw_rect(Rect2(vp.x - (k + 1.0) * 170.0, 0, 170.0, vp.y), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, a / 6.0))
        for i in 5:
                var k2 := float(i) / 5.0
                draw_rect(Rect2(0, k2 * 120.0, vp.x, 120.0), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.04))
        # falling ash
        for i in 40:
                var seed_a := float(i) * 1.7
                var ay := fmod(anim_t * (18.0 + fmod(seed_a, 20.0)) + seed_a * 91.0, vp.y + 40.0) - 20.0
                var ax := fmod(seed_a * 137.0 + sin(anim_t * 0.7 + seed_a) * 14.0, vp.x)
                draw_circle(Vector2(ax, ay), fmod(seed_a, 1.6) + 0.6, Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.16))
        # title
        var title_y := vp.y * 0.34
        var glitch := _flicker > 0.0
        if E0.mono_bold:
                var big := 74
                var title := "ENTITY_000"
                var tw := E0.mono_bold.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, big).x
                var tx := (vp.x - tw) * 0.5
                # soft halo — the designation glows faintly, like a screen in a dark room
                for i in 8:
                        var ang := TAU * i / 8.0
                        draw_string(E0.mono_bold, Vector2(tx + cos(ang) * 3.0, title_y + sin(ang) * 3.0), title,
                                HORIZONTAL_ALIGNMENT_LEFT, -1, big, Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.035))
                if glitch:
                        draw_string(E0.mono_bold, Vector2(tx + 6.0 * _flicker, title_y), title, HORIZONTAL_ALIGNMENT_LEFT, -1, big, Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.5))
                        draw_string(E0.mono_bold, Vector2(tx - 5.0 * _flicker, title_y + 3.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, big, Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.4))
                draw_string(E0.mono_bold, Vector2(tx, title_y), title, HORIZONTAL_ALIGNMENT_LEFT, -1, big, E0.BONE)
        if E0.mono:
                var sub := "NO NAME · NO HISTORY · NO MEMORY · THESE WERE NOT ISSUED"
                var sw := E0.mono.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
                draw_string(E0.mono, Vector2((vp.x - sw) * 0.5 + 1.0, title_y + 31.0), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0, 0, 0, 0.5))
                draw_string(E0.mono, Vector2((vp.x - sw) * 0.5, title_y + 30.0), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, E0.DIM)
        if E0.serif:
                var tag := "If you were created for a purpose \u2014 do you have the right to reject it?"
                var gw := E0.serif.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x
                draw_string(E0.serif, Vector2((vp.x - gw) * 0.5 + 1.0, title_y + 67.0), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color(0, 0, 0, 0.5))
                draw_string(E0.serif, Vector2((vp.x - gw) * 0.5, title_y + 66.0), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.85))
        # menu — one coherent plate, not loose text over architecture
        var my := vp.y * 0.66
        var plate_w := 460.0
        var plate_h := float(menu.size()) * 40.0 + 34.0
        var plate_x := (vp.x - plate_w) * 0.5
        var plate_y := my - 38.0
        draw_rect(Rect2(plate_x, plate_y, plate_w, plate_h), Color(E0.SHADOW.r, E0.SHADOW.g, E0.SHADOW.b, 0.62))
        draw_rect(Rect2(plate_x, plate_y, plate_w, 1.0), Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.30))
        draw_rect(Rect2(plate_x, plate_y + plate_h - 1.0, plate_w, 1.0), Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.30))
        draw_rect(Rect2(plate_x, plate_y, 1.0, plate_h), Color(E0.ASH.r, E0.ASH.g, E0.ASH.b, 0.5))
        draw_rect(Rect2(plate_x + plate_w - 1.0, plate_y, 1.0, plate_h), Color(E0.ASH.r, E0.ASH.g, E0.ASH.b, 0.5))
        for i in menu.size():
                var m: Dictionary = menu[i]
                var sel: bool = i == idx
                var col := E0.BONE if sel else E0.PARCH
                if E0.mono_bold:
                        var label: String = m["label"]
                        var lw := E0.mono_bold.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
                        var lx := (vp.x - lw) * 0.5
                        if sel:
                                # selection strip + gold diamonds + side rules
                                draw_rect(Rect2(lx - 64.0, my - 19.0, lw + 128.0, 30.0), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.72))
                                draw_rect(Rect2(lx - 64.0, my - 19.0, lw + 128.0, 1.0), Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.35))
                                draw_rect(Rect2(lx - 64.0, my + 10.0, lw + 128.0, 1.0), Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.35))
                                var dc := E0.GOLD if fmod(anim_t, 1.0) < 0.6 else Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.4)
                                _diamond(Vector2(lx - 34.0, my - 6.0), 3.4, dc)
                                _diamond(Vector2(lx + lw + 34.0, my - 6.0), 3.4, dc)
                                draw_line(Vector2(lx - 58.0, my - 6.0), Vector2(lx - 44.0, my - 6.0), Color(E0.ASH.r, E0.ASH.g, E0.ASH.b, 0.8), 1.0)
                                draw_line(Vector2(lx + lw + 44.0, my - 6.0), Vector2(lx + lw + 58.0, my - 6.0), Color(E0.ASH.r, E0.ASH.g, E0.ASH.b, 0.8), 1.0)
                        draw_string(E0.mono_bold, Vector2(lx + 1.0, my + 1.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0, 0, 0, 0.45))
                        draw_string(E0.mono_bold, Vector2(lx, my), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, col)
                my += 40.0
        # footer
        if E0.mono:
                var foot := "NATIVE GODOT 4.4 · GDSCRIPT · VERTICAL SLICE · BUILD 818"
                var fw := E0.mono.get_string_size(foot, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
                draw_string(E0.mono, Vector2((vp.x - fw) * 0.5, vp.y - 28.0), foot, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(E0.DIM.r, E0.DIM.g, E0.DIM.b, 0.62))
                var ctl := "A/D MOVE · SPACE JUMP · SHIFT ROLL · J ATTACK · TAB OBSERVE · E MODIFY · F INTERACT · ESC PAUSE"
                var cw := E0.mono.get_string_size(ctl, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
                draw_string(E0.mono, Vector2((vp.x - cw) * 0.5, vp.y - 46.0), ctl, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(E0.DIM.r, E0.DIM.g, E0.DIM.b, 0.55))
                var pad := "GAMEPAD · STICK OR D-PAD MOVE · A JUMP/INTERACT · X ATTACK · B ROLL · Y OBSERVE · RB MODIFY · START PAUSE"
                var pw := E0.mono.get_string_size(pad, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
                draw_string(E0.mono, Vector2((vp.x - pw) * 0.5, vp.y - 62.0), pad, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(E0.DIM.r, E0.DIM.g, E0.DIM.b, 0.45))

func hide_screen() -> void:
        visible = false
        set_process(false)

func _diamond(c: Vector2, r: float, col: Color) -> void:
        var pts := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
        draw_colored_polygon(pts, col)

func show_screen() -> void:
        visible = true
        set_process(true)
        _rebuild_menu()
