## HUD — the VESSEL INSTRUMENT: a brass gauge cluster mounted into the frame,
## not a panel floating over the world. Integrity lives in a glass tube of
## bone-bright fluid (crimson drain lag, meniscus, bubbles, cracks when the
## vessel fails); consistency reads off a needle dial that trembles as
## reality thins; the whole cluster carries the camera's inertia — it is
## BOLTED somewhere behind the eye, and it sways.
## WB-9 law: the interface is a physical artifact of the census world.
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

# instrument physics: the cluster has mass, the camera moves, the mount lags
var _last_cam := Vector2.ZERO
var _sway := Vector2.ZERO
var _sway_ready := false
# draw-state accessors (smoke pins the laws; pixels are for proofs)
var last_tube := {}          # {fill, ghost, cracked}
var last_dial := {}          # {value, tremble, angle}
var last_sway := Vector2.ZERO
var last_prompt_keycap := false

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

## The dial trembles only when reality is genuinely thin — S4+.
static func dial_tremble_for(stage: int) -> float:
        if stage >= 5:
                return 1.0
        if stage == 4:
                return 0.5
        return 0.0

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
        # --- the mount's inertia: camera motion drags the cluster, it eases home --
        if game != null and game.camera != null:
                var cam: Vector2 = game.camera.global_position
                if not _sway_ready:
                        _last_cam = cam
                        _sway_ready = true
                var cam_vel := (cam - _last_cam) / maxf(delta, 0.001)
                _last_cam = cam
                var target := Vector2(
                        clampf(-cam_vel.x * 0.012, -3.2, 3.2),
                        clampf(-cam_vel.y * 0.008, -2.0, 2.0))
                _sway = _sway.lerp(target, 1.0 - exp(-7.0 * delta))
        # idle breath: the mount is never a frozen photograph (a DISPLAY
        # offset — never accumulated into state, or the instrument drifts)
        var breath := Vector2(sin(_t * 0.7) * 0.35, cos(_t * 0.53) * 0.22) * 0.25
        last_sway = _sway + breath
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

        # ======================= THE VESSEL INSTRUMENT (bottom-left) =============
        # brass housing: beveled, brushed, screwed — and it sways with the camera
        var inst := _sway
        var ox := 26.0 + inst.x
        var oy := vp.y - 132.0 + inst.y
        var plate := Rect2(ox, oy, 348.0, 118.0)
        UICraft.brass(self, plate, 0.0, true)
        # engraved maker's line — the instrument was manufactured by someone
        if mono:
                draw_string(mono, Vector2(ox + 14.0, oy + 110.0), "CENSUS DIVISION — FIELD ISSUE No. 818", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(E0.GOLD.r + 0.10, E0.GOLD.g + 0.07, E0.GOLD.b + 0.04, 0.5))

        # --- the consistency dial: a needle gauge bolted to the left of the plate --
        var dial_c := Vector2(ox + 62.0, oy + 58.0)
        var stage := GameState.stage
        var tremble := dial_tremble_for(stage)
        var cons := GameState.consistency
        var stage_col := stage_color_for(stage)
        var n_ang := UICraft.dial_gauge(self, dial_c, 40.0, cons, stage_col, tremble, _t)
        last_dial = {"value": float(cons), "tremble": tremble, "angle": n_ang}
        # the numeral under the dial — engraved, stage-colored, kept legible
        # even in the crimson stages (the census still reads its own gauge)
        if mono_b:
                var cons_txt := "%03d" % cons
                var num_col := stage_col
                if stage >= 4:
                        num_col = Color(stage_col.r * 0.6 + 0.45, stage_col.g * 0.6 + 0.28, stage_col.b * 0.6 + 0.24)
                var cw := mono_b.get_string_size(cons_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
                draw_string(mono_b, Vector2(dial_c.x - cw * 0.5 + 0.8, oy + 108.8), cons_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.02, 0.02, 0.02, 0.6))
                draw_string(mono_b, Vector2(dial_c.x - cw * 0.5, oy + 108.0), cons_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, num_col)
        UICraft.stamp_text(self, mono_s, Vector2(ox + 26.0, oy + 24.0), "CONSISTENCY", Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, 0.75), 10, 0.0, 3)

        # --- the integrity tube: glass, fluid, meniscus, damage ghost -------------
        var tube_r := Rect2(ox + 124.0, oy + 30.0, 196.0, 13.0)
        var hp_frac := clampf(player.hp / float(player.max_hp), 0.0, 1.0)
        var ghost_frac := clampf(_hp_display / float(player.max_hp), 0.0, 1.0)
        var cracked := player.hp <= 30
        UICraft.glass_tube(self, tube_r, hp_frac, ghost_frac, _t, cracked)
        last_tube = {"fill": hp_frac, "ghost": ghost_frac, "cracked": cracked}
        UICraft.stamp_text(self, mono_s, Vector2(ox + 124.0, oy + 24.0), "VESSEL INTEGRITY", Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, 0.75), 10, 0.0, 7)
        # numeral: on its own brass sub-plate — a counter window, not a floating digit
        if mono_b:
                var hp_txt := "%d" % player.hp
                var hpw := mono_bold_size(hp_txt, 17) + 16.0
                var sub := Rect2(tube_r.end.x + 9.0, oy + 28.0, hpw, 24.0)
                UICraft.brass(self, sub, 0.06, false)
                draw_string(mono_b, Vector2(sub.position.x + 8.8, sub.end.y - 6.4), hp_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.02, 0.02, 0.02, 0.65))
                draw_string(mono_b, Vector2(sub.position.x + 8.0, sub.end.y - 7.0), hp_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(E0.BONE.r + 0.06, E0.BONE.g + 0.06, E0.BONE.b + 0.06))
        # the failure mark: a crimson verdict stamped when the vessel is failing
        if cracked and mono_b:
                var pk := 0.5 + 0.5 * sin(_t * 6.0)
                UICraft.stamp_text(self, mono_b, Vector2(tube_r.end.x + 10.0, oy + 64.0), "!", Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.4 + 0.6 * pk), 13, 0.0, 11)

        # --- stage strip: an inlaid brass ribbon under the tube -------------------
        var strip_y := oy + 58.0
        var seg_w := 8.6
        for i in 20:
                var filled := cons > i * 5
                var seg_col: Color
                if filled:
                        seg_col = stage_col if i >= 16 else stage_col.lerp(E0.ASH, 0.25)
                else:
                        seg_col = Color(E0.ASH.r, E0.ASH.g, E0.ASH.b, 0.75)
                draw_rect(Rect2(ox + 124.0 + i * seg_w, strip_y, seg_w - 2.0, 5.0), seg_col)
        # the stage's name, engraved bright enough to survive the corner light —
        # and LIT at the hunting stages (a diegetic instrument never fails to
        # inform; when the world darkens, the verdict brightens)
        if mono:
                var stage_txt := "S%d \u2014 %s" % [stage, GameState.stage_name()]
                var stage_txt_col := Color(E0.BONE.r * 0.82, E0.BONE.g * 0.78, E0.BONE.b * 0.7, 0.95)
                if stage >= 4:
                        stage_txt_col = Color(minf(stage_col.r * 0.5 + 0.55, 1.0), minf(stage_col.g * 0.5 + 0.34, 1.0), minf(stage_col.b * 0.5 + 0.3, 1.0), 1.0)
                        var stw := mono.get_string_size(stage_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
                        draw_rect(Rect2(ox + 118.0, strip_y + 11.0, stw + 12.0, 17.0), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.55))
                draw_string(mono, Vector2(ox + 124.0, strip_y + 22.0), stage_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, stage_txt_col)
        # the ledger of memory fragments: gold-stamped tallies
        if GameState.stats["fragments"] > 0 and mono:
                var frag := ""
                for i in 4:
                        frag += "\u25c6 " if i < GameState.stats["fragments"] else "\u25c7 "
                draw_string(mono, Vector2(ox + 292.0, strip_y + 22.0), frag, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, E0.GOLD)

        # ======================= top-left: the stamped filing header ==============
        if game.room_id.begins_with("act"):
                var act_n := int(game.room_data.get("act", 0))
                var roman: String = ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"][clampi(act_n, 0, 9)]
                UICraft.stamp_text(self, mono_s, Vector2(26, 26), "ACT " + roman, E0.DIM, 13, -0.012, act_n)
                draw_line(Vector2(26, 34.0), Vector2(96.0, 34.0), Color(E0.ASH.r, E0.ASH.g, E0.ASH.b, 0.6), 1.0)
                UICraft.serial_tag(self, Vector2(26, 42.0), "REC-" + game.room_id.to_upper())
        if _obj_t > 0.0:
                var oa := clampf(_obj_t / 1.2, 0.0, 1.0)
                UICraft.stamp_text(self, mono, Vector2(26, 84), "OBJECTIVE: RESTORE THE WORLD", Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, oa), 13, 0.008, 17)

        # ======================= boss bar — the cartouche ==========================
        if _boss and not _boss.is_dead_state():
                _draw_boss_cartouche(vp, mono, mono_s)

        # ======================= low-hp vignette ===================================
        if player.hp <= 30:
                var k := 0.25 + 0.1 * sin(_t * 4.0)
                draw_rect(Rect2(Vector2.ZERO, vp), Color(E0.BLOOD.r, E0.BLOOD.g, E0.BLOOD.b, k * (1.0 - player.hp / 30.0)))

        # ======================= the interact plaque ================================
        if not _prompt.is_empty():
                _draw_prompt_plaque(vp, mono)

## The boss bar as an engraved cartouche: a brass nameplate over the crimson
## vial — the fight is FILED, and the file is running out.
func _draw_boss_cartouche(vp: Vector2, mono: FontFile, mono_s: FontFile) -> void:
        var bw := 560.0
        var bx := (vp.x - bw) * 0.5
        var by := 34.0
        # nameplate: a small brass strip carrying the serif name
        if E0.serif:
                var name := "The Bound Martyr"
                var nw := E0.serif.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
                var idw := 0.0
                if mono_s != null:
                        idw = mono_s.get_string_size(" \u2014 ENTITY_000_001", HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
                var nx := (vp.x - (nw + 14.0 + idw)) * 0.5
                var plate := Rect2(nx - 18.0, by - 4.0, nw + 36.0 + idw, 34.0)
                UICraft.brass(self, plate, 0.05, true)
                draw_string(E0.serif, Vector2(nx + 1.5, by + 21.5), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0, 0, 0, 0.55))
                draw_string(E0.serif, Vector2(nx, by + 20.0), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, 0.95))
                if mono_s:
                        draw_string(mono_s, Vector2(nx + nw + 14.0, by + 18.0), "\u2014 ENTITY_000_001", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, E0.DIM)
        else:
                _label(mono, Vector2(bx, by), "THE BOUND MARTYR \u2014 ENTITY_000_001", E0.PARCH)
        # the vial: a wide glass tube of the martyr's remaining blood
        var b_r := Rect2(bx, by + 40, bw, 14.0)
        draw_rect(Rect2(b_r.position - Vector2(5, 5), b_r.size + Vector2(10, 10)), Color(E0.SHADOW.r, E0.SHADOW.g, E0.SHADOW.b, 0.62))
        var frac := clampf(_boss.hp / float(_boss.max_hp), 0.0, 1.0)
        UICraft.glass_tube(self, b_r, frac, clampf(_boss_display, 0.0, 1.0), _t, false)
        # phase pips: wax seals at the thirds — lit gold once the phase is entered
        for i in 2:
                var px := b_r.position.x + bw * (i + 1.0) / 3.0
                draw_line(Vector2(px, b_r.position.y - 3.0), Vector2(px, b_r.end.y + 3.0), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.9), 2.0)
                var lit := _boss.phase > i + 1
                UICraft.wax_seal(self, Vector2(px, b_r.position.y - 9.0), 3.4, E0.GOLD if lit else Color(E0.ASH.r * 0.6, E0.ASH.g * 0.6, E0.ASH.b * 0.6), 1 if lit else 4, 1.0)
        var phases := ["PHASE I \u2014 BOUND", "PHASE II \u2014 FERVOR", "PHASE III \u2014 UNCHAINED"]
        var pcol := E0.GOLD
        if _boss.phase == 3:
                pcol = Color(E0.VIOLET.r + 0.25, E0.VIOLET.g + 0.08, E0.VIOLET.b + 0.35)
        _label(mono_s, Vector2(bx, by + 68), phases[_boss.phase - 1], pcol, 13)
        # shield status — a filed objection: stamped crimson chip right
        if _boss.shielded() and mono_s != null:
                var chip_t := "SHIELDED \u2014 BREAK THE CHANT"
                var ctw := mono_s.get_string_size(chip_t, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
                var chip := Rect2(bx + bw - ctw - 24.0, by + 57.0, ctw + 22.0, 21.0)
                var pulse := 0.5 + 0.5 * sin(_t * 5.0)
                draw_rect(chip, Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.14 + 0.10 * pulse))
                draw_rect(chip, Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.50 + 0.30 * pulse), false, 1.0)
                UICraft.stamp_text(self, mono_s, Vector2(chip.position.x + 11.0, chip.position.y + 15.0), chip_t, Color(0.94, 0.58, 0.52), 12, -0.01, 23)

## The interact prompt as a brass plaque: an engraved key-cap, a diamond
## separator, the verb stamped into the metal — census property answers to
## whoever holds the key.
func _draw_prompt_plaque(vp: Vector2, mono: FontFile) -> void:
        if mono == null:
                return
        var verb := _prompt
        var vsize := mono.get_string_size(verb, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
        var kw := 30.0
        var pw := kw + 14.0 + vsize.x + 34.0
        var px := (vp.x - pw) * 0.5
        var py := vp.y - 158.0
        var plaque := Rect2(px, py, pw, 50.0)
        # stamp-in: a fresh verb lands with weight, then it holds (scale about center)
        var age := clampf(0.6 - _prompt_t, 0.0, 0.18) / 0.18
        var pop := 1.0 + (1.0 - age) * 0.18
        var pivot := plaque.get_center()
        draw_set_transform(pivot - Vector2(pop, pop) * pivot, 0.0, Vector2(pop, pop))
        UICraft.brass(self, plaque, 0.1, true)
        # the key cap: a raised square die carrying F
        var cap := Rect2(px + 12.0, py + 9.0, 22.0, 22.0)
        draw_rect(cap, Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.92))
        draw_rect(Rect2(cap.position + Vector2(1.5, 1.5), cap.size - Vector2(3.0, 4.5)), Color(E0.PARCH.r * 0.5, E0.PARCH.g * 0.5, E0.PARCH.b * 0.5, 0.95))
        draw_rect(Rect2(cap.position + Vector2(1.5, 1.5), Vector2(cap.size.x - 3.0, 2.0)), Color(1, 1, 1, 0.14))
        draw_rect(cap, Color(E0.GOLD.r + 0.1, E0.GOLD.g + 0.08, E0.GOLD.b + 0.04, 0.8), false, 1.0)
        draw_string(mono, Vector2(cap.position.x + 8.6, cap.end.y - 6.4), "F", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.03, 0.03, 0.03, 0.8))
        draw_string(mono, Vector2(cap.position.x + 8.0, cap.end.y - 7.0), "F", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, 0.92))
        last_prompt_keycap = true
        # diamond separator then the engraved verb
        var dx := cap.end.x + 9.0
        var dcol := E0.GOLD if fmod(_t, 1.0) < 0.6 else Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.45)
        _diamond(Vector2(dx, py + 20.0), 2.8, dcol)
        var ty := py + 26.0
        draw_string(mono, Vector2(dx + 10.8, ty + 0.7), verb, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.02, 0.02, 0.02, 0.55))
        draw_string(mono, Vector2(dx + 10.0, ty), verb, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, E0.BONE)
        # a small serial tag tucked under the verb's tail — census property
        UICraft.serial_tag(self, Vector2(plaque.end.x - 62.0, py + 31.0), "INQ-%d" % (hash(verb) % 900 + 100))
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## Stage accent for the consistency gauge — the needle's state at a glance.
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

func mono_bold_size(text: String, size: int) -> float:
        ## Measured width of a numeral in bold mono (sub-plate sizing).
        if E0.mono_bold == null:
                return text.length() * 10.0
        return E0.mono_bold.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x

func _diamond(c: Vector2, r: float, col: Color) -> void:
        var pts := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
        draw_colored_polygon(pts, col)
