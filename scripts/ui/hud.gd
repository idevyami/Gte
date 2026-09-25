## HUD — custom-drawn: vessel integrity, consistency meter with live stage,
## objective, fragment count, boss bar, interact prompt. Every value is real.
class_name HUD
extends Control

var game  # Game ref
var _prompt := ""
var _prompt_t := 0.0
var _boss: BoundMartyr = null
var _hp_display := 100

func _ready() -> void:
        set_anchors_preset(Control.PRESET_FULL_RECT)
        mouse_filter = Control.MOUSE_FILTER_IGNORE
        EventBus.consistency_stage_changed.connect(func(_s): queue_redraw())
        EventBus.player_health_changed.connect(func(_hp, _m): queue_redraw())

func set_game(p_game) -> void:
        game = p_game

func show_prompt(text: String) -> void:
        _prompt = text
        _prompt_t = 0.6 if text != _prompt else _prompt_t
        queue_redraw()

func set_boss(boss: BoundMartyr) -> void:
        _boss = boss
        queue_redraw()

func _process(delta: float) -> void:
        if _prompt_t > 0.0:
                _prompt_t -= delta
                if _prompt_t <= 0.0:
                        _prompt = ""
                        queue_redraw()
        if game and game.player:
                _hp_display = lerpf(_hp_display, game.player.hp, 10.0 * delta)
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

        # --- bottom-left: vessel integrity -------------------------------------
        var ox := 26.0
        var oy := vp.y - 96.0
        _label(mono_s, Vector2(ox, oy), "VESSEL INTEGRITY", E0.DIM)
        var hp_frac := clampf(player.hp / float(player.max_hp), 0.0, 1.0)
        var bar_w := 232.0
        draw_rect(Rect2(ox, oy + 16, bar_w, 10), E0.VOID)
        draw_rect(Rect2(ox, oy + 16, bar_w * _hp_display / 100.0, 10), E0.BONE)
        # damage ghost bar
        draw_rect(Rect2(ox + bar_w * _hp_display / 100.0, oy + 16, bar_w * (hp_frac - _hp_display / 100.0), 10), E0.CRIMSON)
        draw_rect(Rect2(ox, oy + 16, bar_w, 10), E0.ASH, false, 1.0)
        _label(mono_b, Vector2(ox + bar_w + 10, oy + 14), "%d" % player.hp, E0.BONE)

        # --- consistency meter ----------------------------------------------------
        var cy := oy + 44.0
        _label(mono_s, Vector2(ox, cy), "CONSISTENCY", E0.DIM)
        var cons := GameState.consistency
        var stage := GameState.stage
        var stage_col := E0.CYAN
        if stage >= 4:
                stage_col = E0.CRIMSON
        elif stage >= 3:
                stage_col = E0.GOLD
        # segmented meter: 20 segments of 5%
        for i in 20:
                var filled := cons > i * 5
                var seg_col: Color
                if filled:
                        seg_col = stage_col if i >= 16 else stage_col.lerp(E0.ASH, 0.45)
                else:
                        seg_col = Color(E0.ASH.r, E0.ASH.g, E0.ASH.b, 0.5)
                draw_rect(Rect2(ox + i * 11.6, cy + 16, 9.6, 10), seg_col)
        _label(mono, Vector2(ox, cy + 34), "%03d%% · S%d — %s" % [cons, stage, GameState.stage_name()], stage_col)

        # --- top-left: act + objective --------------------------------------------
        _label(mono_s, Vector2(26, 24), game.room_title, E0.DIM)
        _label(mono, Vector2(26, 42), "OBJECTIVE: RESTORE THE WORLD", E0.PARCH)
        if GameState.stats["fragments"] > 0:
                _label(mono_s, Vector2(26, 62), "MEMORY %d/4" % GameState.stats["fragments"], E0.GOLD.darkened(0.1))

        # --- boss bar ---------------------------------------------------------------
        if _boss and not _boss.is_dead_state():
                var bw := 520.0
                var bx := (vp.x - bw) * 0.5
                var by := 30.0
                _label(mono, Vector2(bx, by), "THE BOUND MARTYR — ENTITY_000_001", E0.PARCH)
                var frac := clampf(_boss.hp / float(_boss.max_hp), 0.0, 1.0)
                draw_rect(Rect2(bx, by + 16, bw, 12), E0.VOID)
                draw_rect(Rect2(bx, by + 16, bw * frac, 12), E0.CRIMSON)
                draw_rect(Rect2(bx, by + 16, bw, 12), E0.ASH, false, 1.0)
                var phases := ["PHASE I — BOUND", "PHASE II — FERVOR", "PHASE III — UNCHAINED"]
                _label(mono_s, Vector2(bx, by + 34), phases[_boss.phase - 1] + (" · SHIELDED" if _boss.shielded() else ""), E0.GOLD)

        # --- low-hp vignette --------------------------------------------------------
        if player.hp <= 30:
                var k := 0.25 + 0.1 * sin(Time.get_ticks_msec() * 0.004)
                draw_rect(Rect2(Vector2.ZERO, vp), Color(E0.BLOOD.r, E0.BLOOD.g, E0.BLOOD.b, k * (1.0 - player.hp / 30.0)))

        # --- interact prompt ----------------------------------------------------------
        if not _prompt.is_empty():
                var pw := 300.0
                var px := (vp.x - pw) * 0.5
                var py := vp.y - 118.0
                draw_rect(Rect2(px - 8, py - 4, pw + 16, 24), Color(E0.SHADOW.r, E0.SHADOW.g, E0.SHADOW.b, 0.72))
                _label(mono, Vector2(px, py), "[F]  " + _prompt, E0.PARCH)

func _label(font: FontFile, pos: Vector2, text: String, col: Color, size := 13) -> void:
        if font == null:
                return
        draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
