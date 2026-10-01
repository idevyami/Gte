## HUD — custom-drawn: vessel integrity, consistency meter with live stage,
## objective, fragment count, boss bar, interact prompt. Every value is real.
## Presentation pass: ornamental hairline frames with corner notches, serif
## boss name with phase pips, decluttered top-left (the room title moved to
## the Cinema entry card; the objective now fades after room entry).
## UX pass: one soft VESSEL PLATE carries both meters (labels get glyphs, the
## block reads as a unit); the boss bar becomes the clear top focal point with
## a pulsing SHIELD status chip; the HUD itself fades out while a cinema card
## owns the frame (room titles, boss intro, death).
class_name HUD
extends Control

var game  # Game ref
var _prompt := ""
var _prompt_t := 0.0
var _boss: BoundMartyr = null
var _hp_display := 100
var _boss_display := 1.0
var _obj_t := 0.0
var _t := 0.0

func _ready() -> void:
        set_anchors_preset(Control.PRESET_FULL_RECT)
        mouse_filter = Control.MOUSE_FILTER_IGNORE
        EventBus.consistency_stage_changed.connect(func(_s): queue_redraw())
        EventBus.player_health_changed.connect(func(_hp, _m): queue_redraw())

func set_game(p_game) -> void:
        game = p_game

func show_prompt(text: String) -> void:
        _prompt_t = 0.6 if text != _prompt else _prompt_t
        _prompt = text
        queue_redraw()

func flash_objective() -> void:
        _obj_t = 7.0

func set_boss(boss: BoundMartyr) -> void:
        _boss = boss
        _boss_display = 1.0
        queue_redraw()

func _process(delta: float) -> void:
        _t += delta
        if _prompt_t > 0.0:
                _prompt_t -= delta
                if _prompt_t <= 0.0:
                        _prompt = ""
                        queue_redraw()
        _obj_t = maxf(0.0, _obj_t - delta)
        if game and game.player:
                _hp_display = lerpf(_hp_display, game.player.hp, 10.0 * delta)
                if _boss and not _boss.is_dead_state():
                        _boss_display = lerpf(_boss_display, clampf(_boss.hp / float(_boss.max_hp), 0.0, 1.0), 6.0 * delta)
        # cinema owns the frame: the HUD steps back until the card is done
        var dim_target := 1.0
        if game != null and game.cinema != null and game.cinema.is_showing():
                dim_target = 0.0
        modulate.a = lerpf(modulate.a, dim_target, minf(1.0, delta * 6.0))
        queue_redraw()

func _draw() -> void:
        if game == null:
                return
        var vp := get_viewport_rect().size
        var mono := E0.mono
        var mono_s := E0.mono
        var mono_b := E0.mono_bold
        var player: Player = game.player
        if player == null:
                return

        # --- bottom-left: the vessel plate (integrity + consistency as one unit) --
        var ox := 26.0
        var oy := vp.y - 96.0
        var plate := Rect2(ox - 18.0, oy - 14.0, 302.0, 104.0)
        # backing card — bright enough to survive the corner vignette
        draw_rect(plate, Color(E0.SHADOW.r, E0.SHADOW.g, E0.SHADOW.b, 0.62))
        draw_rect(plate, Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.14), false, 1.0)
        for i in 3:
                var fk := float(i) / 3.0
                draw_rect(Rect2(plate.position.x - 16.0 + i * 5.5, plate.position.y, 18.0 - i * 5.5, plate.size.y), Color(E0.SHADOW.r, E0.SHADOW.g, E0.SHADOW.b, 0.20 * (1.0 - fk)))
                draw_rect(Rect2(plate.end.x - 2.0 - i * 5.5, plate.position.y, 18.0 - i * 5.5, plate.size.y), Color(E0.SHADOW.r, E0.SHADOW.g, E0.SHADOW.b, 0.20 * (1.0 - fk)))
        draw_rect(Rect2(plate.position.x, plate.position.y, plate.size.x, 1.0), Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.30))
        draw_rect(Rect2(plate.position.x, plate.end.y - 1.0, plate.size.x, 1.0), Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.18))
        _diamond(Vector2(ox - 3.0, oy - 4.0), 2.4, E0.GOLD.darkened(0.08))
        _spaced(mono_s, Vector2(ox + 9.0, oy), "VESSEL INTEGRITY", E0.PARCH, 12, 2.5)
        var hp_frac := clampf(player.hp / float(player.max_hp), 0.0, 1.0)
        var bar_w := 232.0
        var bar_h := 12.0
        var bar_r := Rect2(ox, oy + 16, bar_w, bar_h)
        draw_rect(Rect2(bar_r.position - Vector2(5, 5), bar_r.size + Vector2(10, 10)), Color(E0.SHADOW.r, E0.SHADOW.g, E0.SHADOW.b, 0.62))
        draw_rect(Rect2(bar_r.position - Vector2(3, 3), bar_r.size + Vector2(6, 6)), E0.VOID)
        # damage ghost bar (crimson lag)
        draw_rect(Rect2(bar_r.position, Vector2(bar_w * _hp_display / 100.0, bar_h)), E0.CRIMSON)
        draw_rect(Rect2(bar_r.position, Vector2(bar_w * hp_frac, bar_h)), E0.BONE)
        # segment ticks every 25
        for i in 4:
                var tx := bar_r.position.x + bar_w * (i + 1) / 5.0
                draw_line(Vector2(tx, bar_r.position.y), Vector2(tx, bar_r.position.y + bar_h), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.8), 1.0)
        # gold hairline frame + corner notches
        draw_rect(bar_r, E0.GOLD, false, 1.0)
        _frame_notches(bar_r, E0.GOLD)
        _diamond(Vector2(bar_r.position.x - 12.0, bar_r.position.y + bar_h * 0.5), 3.0, E0.GOLD.darkened(0.15))
        _label(mono_b, Vector2(bar_r.end.x + 19.0, oy + 30), "%d" % player.hp, Color(E0.BONE.r + 0.06, E0.BONE.g + 0.06, E0.BONE.b + 0.06), 17)
        _label(mono_b, Vector2(bar_r.end.x + 18.0, oy + 29), "%d" % player.hp, E0.BONE, 17)
        # low integrity pulse under the number
        if player.hp <= 30:
                var pk := 0.5 + 0.5 * sin(_t * 6.0)
                _label(mono_s, Vector2(bar_r.end.x + 18.0, oy + 46), "!", Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.4 + 0.6 * pk), 12)

        # --- consistency meter (inside the vessel plate) ------------------------
        var cy := oy + 54.0
        _diamond(Vector2(ox - 3.0, cy - 4.0), 2.4, stage_color_for(GameState.stage))
        _spaced(mono_s, Vector2(ox + 9.0, cy), "CONSISTENCY", E0.PARCH, 12, 2.5)
        var cons := GameState.consistency
        var stage := GameState.stage
        var stage_col := stage_color_for(stage)
        # segmented meter: 20 segments of 5% — fills stay bright through the vignette
        var seg_y := cy + 16.0
        draw_rect(Rect2(ox - 4.0, seg_y - 4.0, 20.0 * 11.6 + 3.0, 18.0), Color(E0.SHADOW.r, E0.SHADOW.g, E0.SHADOW.b, 0.65))
        for i in 20:
                var filled := cons > i * 5
                var seg_col: Color
                if filled:
                        seg_col = stage_col if i >= 16 else stage_col.lerp(E0.ASH, 0.25)
                else:
                        seg_col = Color(E0.ASH.r, E0.ASH.g, E0.ASH.b, 0.75)
                draw_rect(Rect2(ox + i * 11.6, seg_y, 9.6, 10), seg_col)
        _label(mono, Vector2(ox, cy + 36), "%03d%% \u00b7 S%d \u2014 %s" % [cons, stage, GameState.stage_name()], stage_col, 13)

        # --- top-left: act + memory (decluttered; room title lives on the entry card)
        if game.room_id.begins_with("act"):
                var act_n := int(game.room_data.get("act", 0))
                var roman: String = ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"][clampi(act_n, 0, 9)]
                _label(mono_s, Vector2(26, 26), "ACT " + roman, E0.DIM)
                draw_line(Vector2(26, 34.0), Vector2(96.0, 34.0), Color(E0.ASH.r, E0.ASH.g, E0.ASH.b, 0.6), 1.0)
        if GameState.stats["fragments"] > 0:
                _label(mono_s, Vector2(26, 56), "MEMORY %d/4" % GameState.stats["fragments"], E0.GOLD.darkened(0.1))
        # objective: shown on room entry, then fades (system messages own the top)
        if _obj_t > 0.0:
                var oa := clampf(_obj_t / 1.2, 0.0, 1.0)
                _label(mono, Vector2(26, 78), "OBJECTIVE: RESTORE THE WORLD", Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, oa))

        # --- boss bar — the top focal point ----------------------------------------
        if _boss and not _boss.is_dead_state():
                var bw := 560.0
                var bx := (vp.x - bw) * 0.5
                var by := 40.0
                # nameplate: serif name centered with its ID tucked after — one block
                if E0.serif:
                        var name := "The Bound Martyr"
                        var nw := E0.serif.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
                        var idw := 0.0
                        if mono_s != null:
                                idw = mono_s.get_string_size(" — ENTITY_000_001", HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
                        var nx := (vp.x - (nw + 14.0 + idw)) * 0.5
                        draw_string(E0.serif, Vector2(nx + 1.5, by + 21.5), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0, 0, 0, 0.55))
                        draw_string(E0.serif, Vector2(nx, by + 20.0), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, 0.95))
                        _label(mono_s, Vector2(nx + nw + 14.0, by + 18.0), "\u2014 ENTITY_000_001", E0.DIM, 12)
                else:
                        _label(mono, Vector2(bx, by), "THE BOUND MARTYR \u2014 ENTITY_000_001", E0.PARCH)
                var b_r := Rect2(bx, by + 26, bw, 14.0)
                draw_rect(Rect2(b_r.position - Vector2(5, 5), b_r.size + Vector2(10, 10)), Color(E0.SHADOW.r, E0.SHADOW.g, E0.SHADOW.b, 0.62))
                draw_rect(b_r, E0.VOID)
                var frac := clampf(_boss.hp / float(_boss.max_hp), 0.0, 1.0)
                # ghost lag then crimson fill with inner highlight
                draw_rect(Rect2(b_r.position, Vector2(bw * _boss_display, 14.0)), Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, 0.28))
                draw_rect(Rect2(b_r.position, Vector2(bw * frac, 14.0)), E0.CRIMSON)
                draw_rect(Rect2(b_r.position + Vector2(0, 2.0), Vector2(bw * frac, 2.0)), Color(E0.BLOOD.r, E0.BLOOD.g, E0.BLOOD.b, 0.9))
                draw_rect(Rect2(b_r.position, Vector2(bw * frac, 2.0)), Color(E0.CRIMSON.r + 0.12, E0.CRIMSON.g + 0.05, E0.CRIMSON.b + 0.05, 0.7))
                # phase pips at 1/3 and 2/3
                for i in 2:
                        var px := b_r.position.x + bw * (i + 1.0) / 3.0
                        draw_line(Vector2(px, b_r.position.y - 3.0), Vector2(px, b_r.end.y + 3.0), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.9), 2.0)
                        var lit := _boss.phase > i + 1
                        _diamond(Vector2(px, b_r.position.y - 7.0), 3.0, E0.GOLD if lit else Color(E0.ASH.r, E0.ASH.g, E0.ASH.b, 0.7))
                draw_rect(b_r, Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.75), false, 1.0)
                _frame_notches(b_r, Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.75))
                var phases := ["PHASE I \u2014 BOUND", "PHASE II \u2014 FERVOR", "PHASE III \u2014 UNCHAINED"]
                var pcol := E0.GOLD
                if _boss.phase == 3:
                        pcol = Color(E0.VIOLET.r + 0.25, E0.VIOLET.g + 0.08, E0.VIOLET.b + 0.35)
                _label(mono_s, Vector2(bx, by + 56), phases[_boss.phase - 1], pcol, 13)
                # shield status — a filed objection, not a whisper: pulsing chip right
                if _boss.shielded() and mono_s != null:
                        var chip_t := "SHIELDED \u2014 BREAK THE CHANT"
                        var ctw := mono_s.get_string_size(chip_t, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
                        var chip := Rect2(bx + bw - ctw - 24.0, by + 45.0, ctw + 22.0, 21.0)
                        var pulse := 0.5 + 0.5 * sin(_t * 5.0)
                        draw_rect(chip, Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.14 + 0.10 * pulse))
                        draw_rect(chip, Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.50 + 0.30 * pulse), false, 1.0)
                        _label(mono_s, Vector2(chip.position.x + 11.0, chip.position.y + 15.0), chip_t, Color(0.94, 0.58, 0.52), 12)

        # --- low-hp vignette --------------------------------------------------------
        if player.hp <= 30:
                var k := 0.25 + 0.1 * sin(_t * 4.0)
                draw_rect(Rect2(Vector2.ZERO, vp), Color(E0.BLOOD.r, E0.BLOOD.g, E0.BLOOD.b, k * (1.0 - player.hp / 30.0)))

        # --- interact prompt ----------------------------------------------------------
        if not _prompt.is_empty():
                var pw := 300.0
                var px := (vp.x - pw) * 0.5
                var py := vp.y - 122.0
                var pr := Rect2(px - 14.0, py - 7.0, pw + 28.0, 29.0)
                draw_rect(pr, Color(E0.SHADOW.r, E0.SHADOW.g, E0.SHADOW.b, 0.80))
                draw_rect(Rect2(pr.position, Vector2(2.0, pr.size.y)), E0.GOLD)
                draw_rect(Rect2(Vector2(pr.end.x - 2.0, pr.position.y), Vector2(2.0, pr.size.y)), E0.GOLD)
                var pd := E0.GOLD if fmod(_t, 1.0) < 0.6 else Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.45)
                _diamond(Vector2(px - 4.0, py + 4.0), 2.8, pd)
                _label(mono, Vector2(px + 8.0, py), "[F]  " + _prompt, E0.PARCH, 14)

## Stage accent for the consistency glyph — the meter's state at a glance.
func stage_color_for(stage: int) -> Color:
        if stage >= 4:
                return E0.CRIMSON
        elif stage >= 3:
                return E0.GOLD
        return E0.CYAN

func _label(font: FontFile, pos: Vector2, text: String, col: Color, size := 13) -> void:
        if font == null:
                return
        draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

## Letter-spaced caps label (the system record's voice).
func _spaced(font: FontFile, pos: Vector2, text: String, col: Color, size := 12, space := 2.0) -> void:
        if font == null:
                return
        var x := pos.x
        for i in text.length():
                draw_string(font, Vector2(x, pos.y), text[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
                x += font.get_string_size(text[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + space

## Ornamental corner ticks: small L-shaped notches outside each corner.
func _frame_notches(r: Rect2, col: Color) -> void:
        var n := 5.0
        var g := 3.0
        for corner in [Vector2(r.position.x - g, r.position.y - g), Vector2(r.end.x + g, r.position.y - g), Vector2(r.position.x - g, r.end.y + g), Vector2(r.end.x + g, r.end.y + g)]:
                var dx := -1.0 if corner.x < r.position.x + r.size.x * 0.5 else 1.0
                var dy := -1.0 if corner.y < r.position.y + r.size.y * 0.5 else 1.0
                draw_line(corner, corner + Vector2(dx * n, 0.0), col, 1.0)
                draw_line(corner, corner + Vector2(0.0, dy * n), col, 1.0)

func _diamond(c: Vector2, r: float, col: Color) -> void:
        var pts := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
        draw_colored_polygon(pts, col)
