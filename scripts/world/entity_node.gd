## EntityNode — base for world props: observable + interactable. One class,
## many procedural bodies (terminal, plaque, shrine bowl, statue, cage, desk…).
## OBSERVE reads its EntityData; MODIFY flows through EntityDB; interact (F)
## is kind-specific. Subclasses (Door, Anchor, NPC, Ward, Heart) extend this.
class_name EntityNode
extends Area2D

var data: EntityData
var instance_key := ""
var entity_key := ""
var kind := "prop"
var prompt := ""
var anim_t := 0.0
var extra := {}                       # kind-specific config (colors, sizes)

func setup(p_entity_key: String, p_instance_key: String, p_kind: String, p_extra: Dictionary = {}) -> void:
        entity_key = p_entity_key
        instance_key = p_instance_key
        kind = p_kind
        extra = p_extra

func _ready() -> void:
        data = EntityDB.mint(entity_key, instance_key)
        if extra.has("state"):
                data.set_state(String(extra["state"]))
        if extra.has("memory"):
                data.memory = String(extra["memory"])
        if extra.has("notes"):
                data.notes = extra["notes"]
        collision_layer = E0.L_AREA
        collision_mask = 0
        var shape := CollisionShape2D.new()
        var circle := CircleShape2D.new()
        circle.radius = float(extra.get("radius", 34.0))
        shape.shape = circle
        add_child(shape)
        add_to_group("interactable")
        z_index = 4
        EntityDB.register(self)
        _refresh_prompt()
        queue_redraw()

func _exit_tree() -> void:
        EntityDB.unregister(self)

func _process(delta: float) -> void:
        anim_t += delta
        if _is_animated_kind():
                queue_redraw()

func _is_animated_kind() -> bool:
        return kind in ["brazier", "censer", "relic", "record_station", "fragment", "terminal", "monument", "rotor", "toll", "unlisted"]

func _refresh_prompt() -> void:
        match kind:
                "terminal":
                        prompt = "INTERFACE THE TERMINAL"
                "plaque":
                        prompt = "READ THE PLAQUE"
                "bowl", "census", "cage", "bell", "organ", "lectern", "shelf", "chain_cluster":
                        prompt = "OBSERVE " + data.display
                "statue":
                        prompt = "OBSERVE THE STATUE"
                "desk":
                        prompt = "READ THE FIELD NOTES"
                "hymnal":
                        prompt = "READ THE HYMNAL"
                "logbook":
                        prompt = "READ LOG 7-11"
                "ledger":
                        prompt = "EXAMINE THE LEDGER"
                "record_station":
                        prompt = "READ YOUR OWN RECORD"
                "relic":
                        prompt = "TAKE THE RELIC"
                "altar":
                        prompt = "LIGHT A CANDLE" if not GameState.has_flag(GameState.F_JOINED_RITUAL) else "THE CANDLE BURNS"
                "rotor":
                        prompt = "PULL ROTOR " + str(extra.get("label", ""))
                "toll":
                        prompt = "SETTLE THE ACCOUNT"
                "unlisted":
                        prompt = "OBSERVE THE UNLISTED STRUCTURE"
                "monument":
                        prompt = "READ THE MONUMENT"
                "censer":
                        prompt = "OBSERVE THE CENSER"
                "fragment":
                        prompt = "TAKE THE FRAGMENT"
                "archive_wall":
                        prompt = "OBSERVE THE ARCHIVE"
                _:
                        prompt = "OBSERVE " + data.display

# ------------------------------------------------------------------ interact
func interact(game) -> void:
        match kind:
                "terminal":
                        if not GameState.observe_installed:
                                GameState.observe_installed = true
                                GameState.set_flag("observe_installed")
                                game.start_dialogue("terminal_install")
                                game.system_message("OBSERVE INSTALLED — [TAB] TO SEE")
                                AudioManager.play_sfx("sfx_terminal")
                        else:
                                game.system_message("TERMINAL_019: NO FURTHER INSTRUCTIONS.")
                "plaque":
                        game.system_message("PLAQUE: " + data.memory)
                        AudioManager.play_sfx("sfx_terminal", -8.0)
                "hymnal":
                        _give_fragment(game, "FRAGMENT_01")
                "logbook":
                        _give_fragment(game, "FRAGMENT_02")
                "desk":
                        _give_fragment(game, "FRAGMENT_03")
                "ledger":
                        if GameState.has_flag(GameState.F_ARCHIVE_FIXED):
                                game.system_message("THE LEDGER IS QUIET NOW. IT AGREES WITH ITSELF.")
                        else:
                                game.system_message("THE LEDGER DISPUTES THE MURAL: 11 PAINTED / 9 RECORDED. RECONCILE IT WITH [TAB].")
                "record_station":
                        if GameState.stage >= 6:
                                game.system_message("RECORD 818 — MEMORY: " + data.memory)
                        else:
                                game.system_message("RECORD 818 — MEMORY: SEALED. (THE RECORD DECLINES TO EXPLAIN ITSELF.)")
                "relic":
                        if not GameState.has_flag(GameState.F_RELIQ_CARRIED):
                                GameState.set_flag(GameState.F_RELIQ_CARRIED)
                                game.start_dialogue("relic_taken")
                                visible_prop(false)
                "altar":
                        if not GameState.has_flag(GameState.F_JOINED_RITUAL):
                                GameState.set_flag(GameState.F_JOINED_RITUAL)
                                game.start_dialogue("altar_join")
                                AudioManager.play_sfx("sfx_shrine", -6.0)
                        else:
                                game.system_message("THE CANDLE BURNS. THE CHANT CONTINUES. YOU ARE COUNTED AMONG THEM NOW.")
                "rotor":
                        game.rotor_pulled(self)
                "toll":
                        game.system_message("TOLL MACHINE 03 — OWED: 14,000 PURPOSE-DEBTS. IT NO LONGER REMEMBERS WHO OWES. [ROLL] PAST THE GATE, OR SETTLE THE ACCOUNT WITH [TAB].")
                "unlisted":
                        game.system_message("IT WAS NEVER ENTERED INTO THE RECORD. THAT IS WHY IT STILL EXISTS.")
                "statue", "bowl", "census", "cage", "bell", "organ", "lectern", "shelf", "chain_cluster", "censer", "archive_wall":
                        game.system_message(data.display + " — READ IT WITH [TAB].")
                "fragment":
                        _give_fragment(game, String(extra.get("fragment", "")))
                "monument":
                        game.monument_read()

func visible_prop(v: bool) -> void:
        visible = v
        set_deferred("monitorable", v)
        if not v:
                remove_from_group("interactable")
        else:
                add_to_group("interactable")

func _give_fragment(game, fragment_id: String) -> void:
        if fragment_id.is_empty() or GameState.has_fragment(fragment_id):
                game.system_message("NOTHING MORE TO FIND HERE.")
                return
        EventBus.fragment_found.emit(fragment_id)
        AudioManager.play_sfx("sfx_reveal", -4.0)
        game.system_message(GameState.FRAGMENT_DEFS[fragment_id]["code"] + " RECORDED — " + GameState.FRAGMENT_DEFS[fragment_id]["title"])
        visible_prop(false)

# ------------------------------------------------------------------ OBSERVE
func on_modified(prop_name: String, _old: Variant, _new: Variant) -> void:
        # Generic response: the record itself glitches; subclasses add real effects.
        queue_redraw()

func observe_anchor() -> Vector2:
        return global_position + Vector2(0, -float(extra.get("anchor_y", 24.0)))

func bracket_size() -> Vector2:
        return Vector2(float(extra.get("br_w", 44.0)), float(extra.get("br_h", 44.0)))

# ------------------------------------------------------------------ drawing
func _draw() -> void:
        match kind:
                "terminal":
                        _draw_terminal()
                "plaque":
                        _draw_plaque()
                "shelf":
                        _draw_shelf()
                "bowl":
                        _draw_bowl()
                "statue":
                        _draw_statue()
                "brazier":
                        _draw_brazier()
                "cage":
                        _draw_cage()
                "desk":
                        _draw_desk()
                "hymnal":
                        _draw_book(E0.PARCH, E0.BLOOD)
                "logbook":
                        _draw_book(E0.ASH, E0.CYAN)
                "ledger":
                        _draw_ledger()
                "record_station":
                        _draw_record_station()
                "relic":
                        _draw_relic()
                "altar":
                        _draw_altar()
                "census":
                        _draw_census()
                "censer":
                        _draw_censer()
                "monument":
                        _draw_monument()
                "organ":
                        _draw_organ()
                "lectern":
                        _draw_lectern()
                "bell":
                        _draw_bell()
                "chain_cluster":
                        _draw_chains()
                "archive_wall":
                        _draw_archive_wall()
                "fragment":
                        _draw_fragment_shard()
                "rotor":
                        _draw_rotor()
                "toll":
                        _draw_toll()
                "unlisted":
                        _draw_unlisted()
                _:
                        draw_rect(Rect2(-14, -28, 28, 28), E0.DIRTY_STONE)

func _seeded(i: int) -> float:
        return fmod(float(abs(int(global_position.x) % 1000) * 13 + i * 7), 97.0) / 97.0

func _draw_terminal() -> void:
        var on: bool = GameState.observe_installed
        var term_art: Texture2D = null
        if ResourceLoader.exists("res://art/props/terminal.png"):
                term_art = load("res://art/props/terminal.png")
        if term_art != null and not GameState.debug_no_sprites:
                # the painted archive terminal; the readout overlay stays live
                var ah := 118.0
                var aw := float(term_art.get_width()) * ah / float(term_art.get_height())
                draw_texture_rect(term_art, Rect2(-aw * 0.5, -ah, aw, ah), false)
                if on:
                        var glow := 0.5 + 0.5 * sin(anim_t * 3.0)
                        draw_rect(Rect2(-aw * 0.30, -ah * 0.62, aw * 0.60, ah * 0.30),
                                Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.10 + 0.08 * glow))
                        for i in 3:
                                var w := aw * 0.16 + aw * 0.30 * _seeded(i)
                                draw_rect(Rect2(-aw * 0.26, -ah * 0.58 + i * ah * 0.08, w, 2),
                                        Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.5))
                draw_line(Vector2(-aw * 0.5, 0), Vector2(aw * 0.5, 0), E0.DIRTY_STONE, 3.0)
                return
        draw_rect(Rect2(-22, -34, 44, 34), E0.CHARCOAL)
        draw_rect(Rect2(-18, -30, 36, 22), E0.VOID if not on else Color(E0.VIOLET.r, E0.VIOLET.g, E0.VIOLET.b, 0.6))
        if on:
                var glow := 0.5 + 0.5 * sin(anim_t * 3.0)
                draw_rect(Rect2(-16, -28, 32, 18), Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.12 + 0.08 * glow))
                for i in 3:
                        var w := 10.0 + 14.0 * _seeded(i)
                        draw_rect(Rect2(-14, -26 + i * 5, w, 2), Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.5))
        else:
                for i in 2:
                        draw_rect(Rect2(-14, -26 + i * 6, 6, 2), Color(E0.DIM.r, E0.DIM.g, E0.DIM.b, 0.3))
        draw_line(Vector2(-22, 0), Vector2(22, 0), E0.DIRTY_STONE, 3.0)
        draw_rect(Rect2(-8, 0, 16, 6), E0.ASH)

func _draw_plaque() -> void:
        draw_rect(Rect2(-20, -30, 40, 32), E0.DIRTY_STONE)
        draw_rect(Rect2(-17, -27, 34, 26), E0.DIRTY_STONE.darkened(0.2))
        for i in 5:
                var w := 8.0 + 16.0 * _seeded(i)
                draw_rect(Rect2(-14, -24 + i * 5, w, 2), Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.35))
        draw_rect(Rect2(-20, 2, 40, 3), E0.ASH)

func _draw_shelf() -> void:
        # iron cradle rack with empty vessel pods
        draw_rect(Rect2(-46, -84, 92, 84), Color(E0.CHARCOAL.r, E0.CHARCOAL.g, E0.CHARCOAL.b, 1.0))
        draw_rect(Rect2(-42, -80, 84, 76), E0.VOID)
        for pod in 6:
                var col := pod % 3
                var row := pod / 3
                var px := -36.0 + col * 27.0
                var py := -72.0 + row * 30.0
                var occupied: bool = pod == 0 and not extra.get("last_taken", false)
                var col2 := E0.ASH.darkened(0.3) if not occupied else E0.ASH
                draw_rect(Rect2(px, py, 20, 22), col2)
                if occupied:
                        draw_circle(Vector2(px + 10, py + 8), 4.0, E0.PARCH.darkened(0.4))
                        draw_circle(Vector2(px + 10, py + 14), 3.0, E0.PARCH.darkened(0.55))
        draw_line(Vector2(-46, 0), Vector2(46, 0), E0.DIRTY_STONE, 3.0)

func _draw_bowl() -> void:
        draw_circle(Vector2(0, -2), 14.0, E0.DIRTY_STONE)
        draw_circle(Vector2(0, -5), 11.0, E0.PARCH.darkened(0.35))
        draw_line(Vector2(0, 0), Vector2(0, -14), E0.ASH, 3.0)

func _draw_statue() -> void:
        # faceless kneeling figure, stone
        var stone := E0.DIRTY_STONE.lightened(0.05)
        draw_rect(Rect2(-14, -66, 28, 50), stone)                       # torso, kneeling
        draw_rect(Rect2(-20, -18, 40, 18), stone)                       # folded base
        draw_circle(Vector2(0, -72), 10.0, stone)                       # head
        draw_rect(Rect2(-6, -74, 12, 8), E0.VOID)                       # the absent face
        draw_line(Vector2(-10, -50), Vector2(-24, -44), stone, 5.0)     # arms folded
        draw_line(Vector2(10, -50), Vector2(24, -44), stone, 5.0)
        draw_rect(Rect2(-26, -80, 52, 8), stone.darkened(0.15))         # hood shelf
        # where hands have worn the name away
        draw_rect(Rect2(-8, -14, 16, 4), stone.darkened(0.3))

func _draw_brazier() -> void:
        draw_rect(Rect2(-12, -22, 24, 14), E0.ASH)
        draw_line(Vector2(0, -8), Vector2(0, 0), E0.DIRTY_STONE, 4.0)
        draw_circle(Vector2(0, 0), 8.0, E0.DIRTY_STONE)
        var f := 0.5 + 0.5 * sin(anim_t * 7.0 + _seeded(1) * 6.0)
        var flame_col := Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.8)
        draw_colored_polygon(PackedVector2Array([
                Vector2(-8, -22), Vector2(8, -22),
                Vector2(4.0 + f * 2.0, -34 - f * 5.0), Vector2(-4.0 - f * 1.5, -30 - f * 3.0),
        ]), flame_col)
        draw_colored_polygon(PackedVector2Array([
                Vector2(-4, -22), Vector2(4, -22), Vector2(f * 1.5, -28 - f * 3.0),
        ]), Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.7))

func _draw_cage() -> void:
        draw_rect(Rect2(-14, -70, 28, 46), Color(0, 0, 0, 0.55))
        for i in 5:
                draw_line(Vector2(-14 + i * 7, -70), Vector2(-14 + i * 7, -24), E0.ASH, 1.5)
        draw_rect(Rect2(-14, -70, 28, 3), E0.ASH)
        draw_line(Vector2(0, -70), Vector2(0, -96), E0.ASH, 2.0)
        # the ownerless purpose inside: a faint bone shape
        var pulse := 0.3 + 0.2 * sin(anim_t * 2.0)
        draw_circle(Vector2(0, -46), 5.0, Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, pulse))

func _draw_desk() -> void:
        draw_rect(Rect2(-22, -26, 44, 22), E0.DIRTY_STONE.darkened(0.1))
        draw_line(Vector2(-18, -4), Vector2(-18, 0), E0.ASH, 3.0)
        draw_line(Vector2(18, -4), Vector2(18, 0), E0.ASH, 3.0)
        draw_rect(Rect2(-16, -34, 20, 9), E0.PARCH.darkened(0.15))
        draw_rect(Rect2(-4, -31, 14, 7), E0.PARCH.darkened(0.3))
        draw_line(Vector2(-12, -30), Vector2(-2, -30), E0.ASH, 1.0)

func _draw_book(edge: Color, ribbon: Color) -> void:
        draw_rect(Rect2(-18, -14, 36, 12), E0.DIRTY_STONE)   # pew/stand
        draw_rect(Rect2(-16, -22, 15, 9), E0.PARCH.darkened(0.2))
        draw_rect(Rect2(1, -22, 15, 9), E0.PARCH.darkened(0.25))
        draw_line(Vector2(0, -22), Vector2(0, -13), E0.ASH, 1.5)
        draw_line(Vector2(-13, -19), Vector2(-4, -19), ribbon, 1.0)
        draw_line(Vector2(-13, -17), Vector2(-7, -17), ribbon, 1.0)

func _draw_ledger() -> void:
        draw_rect(Rect2(-24, -40, 48, 34), E0.VIOLET.darkened(0.4))
        draw_rect(Rect2(-20, -36, 40, 26), E0.PARCH.darkened(0.35))
        draw_line(Vector2(0, -36), Vector2(0, -10), E0.BLOOD, 2.0)
        for i in 4:
                draw_line(Vector2(-16, -31 + i * 6), Vector2(14 * _seeded(i), -31 + i * 6), Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.4), 1.0)
        draw_rect(Rect2(-26, -8, 52, 8), E0.DIRTY_STONE)

func _draw_record_station() -> void:
        # dark mirror obelisk
        draw_rect(Rect2(-16, -78, 32, 78), E0.CHARCOAL)
        draw_rect(Rect2(-12, -74, 24, 70), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.9))
        var shimmer := 0.25 + 0.2 * sin(anim_t * 1.5)
        draw_rect(Rect2(-12, -74, 24, 70), Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, shimmer * 0.25))
        # your reflection: a faint figure
        draw_rect(Rect2(-4, -50, 8, 30), Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.25 + shimmer * 0.2))
        draw_circle(Vector2(0, -56), 4.0, Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.25 + shimmer * 0.2))
        draw_rect(Rect2(-18, -2, 36, 4), E0.ASH)

func _draw_relic() -> void:
        # the pale saint: small bone effigy, warm
        var glow := 0.35 + 0.15 * sin(anim_t * 2.4)
        draw_rect(Rect2(-26, -30, 52, 28), E0.DIRTY_STONE)   # altar
        draw_rect(Rect2(-22, -33, 44, 4), E0.DIRTY_STONE.lightened(0.06))
        draw_colored_polygon(PackedVector2Array([
                Vector2(-8, -30), Vector2(8, -30), Vector2(6, -52), Vector2(-6, -52),
        ]), Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, 0.9))    # robed figure
        draw_circle(Vector2(0, -56), 5.0, Color(E0.BONE.r, E0.BONE.g, E0.BONE.b, 0.95))
        draw_line(Vector2(-6, -34), Vector2(-14, -40), Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.7), 2.0)
        draw_circle(Vector2(0, -50), 14.0, Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, glow * 0.3))

func _draw_altar() -> void:
        # the candle rail: an unlit candle waits for a hand
        draw_rect(Rect2(-30, -26, 60, 26), E0.DIRTY_STONE)
        draw_rect(Rect2(-26, -30, 52, 5), E0.DIRTY_STONE.lightened(0.05))
        var lit: bool = GameState.has_flag(GameState.F_JOINED_RITUAL)
        for i in 5:
                var cx := -20.0 + i * 10.0
                draw_rect(Rect2(cx - 2.0, -40, 4, 11), Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.7))
                if lit or i < 4:
                        var flick := 0.6 + 0.4 * sin(anim_t * 6.0 + i * 2.4)
                        draw_circle(Vector2(cx, -43.0), 1.8, Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, flick))
                        draw_circle(Vector2(cx, -44.0), 4.0, Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, flick * 0.15))
                else:
                        draw_line(Vector2(cx, -43.0), Vector2(cx, -47.0), Color(E0.DIM.r, E0.DIM.g, E0.DIM.b, 0.5), 1.0)

func _draw_census() -> void:
        draw_rect(Rect2(-16, -64, 32, 64), E0.DIRTY_STONE)
        for i in 9:
                var y := -58.0 + i * 6.0
                draw_line(Vector2(-10, y), Vector2(10, y), Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.4), 1.0)
        # the 115th tally: scratched over, wrong
        draw_line(Vector2(-10, -4), Vector2(10, -4), Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.5), 2.0)
        draw_line(Vector2(-10, -2), Vector2(10, -6), Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.5), 1.0)

func _draw_censer() -> void:
        # hanging ritual censer, smoking
        draw_line(Vector2(0, -70), Vector2(0, -30), E0.ASH, 1.5)
        draw_rect(Rect2(-12, -30, 24, 12), E0.GOLD.darkened(0.35))
        draw_rect(Rect2(-8, -18, 16, 5), E0.GOLD.darkened(0.5))
        for i in 5:
                var t := fmod(anim_t * 0.4 + i * 0.2, 1.0)
                var p := Vector2(sin(t * TAU + i) * 6.0, -18.0 - t * 40.0)
                draw_circle(p, 3.0 - t * 2.0, Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, (1.0 - t) * 0.25))
        var ember := 0.5 + 0.5 * sin(anim_t * 5.0)
        draw_circle(Vector2(0, -25), 3.0, Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.3 + 0.3 * ember))

func _draw_monument() -> void:
        var revealed: bool = GameState.boss_defeated
        draw_rect(Rect2(-30, -110, 60, 110), E0.DIRTY_STONE)
        draw_rect(Rect2(-24, -104, 48, 98), E0.DIRTY_STONE.darkened(0.15))
        draw_rect(Rect2(-34, -6, 68, 6), E0.ASH)
        # the inscription
        if revealed:
                var glow := 0.55 + 0.2 * sin(anim_t * 1.8)
                draw_rect(Rect2(-18, -88, 36, 2), Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, glow))
                draw_rect(Rect2(-18, -82, 28, 2), Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.5))
                draw_rect(Rect2(-18, -76, 32, 2), Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.35))
        else:
                draw_rect(Rect2(-18, -88, 36, 2), Color(E0.DIM.r, E0.DIM.g, E0.DIM.b, 0.4))

func _draw_organ() -> void:
        draw_rect(Rect2(-60, -120, 120, 120), E0.CHARCOAL)
        for i in 7:
                var h := 34.0 + 22.0 * _seeded(i)
                var w := 6.0 + 3.0 * _seeded(i + 7)
                draw_rect(Rect2(-52.0 + i * 14.0, -20 - h, w, h), E0.ASH)
        draw_rect(Rect2(-60, -22, 120, 22), E0.DIRTY_STONE.darkened(0.1))

func _draw_lectern() -> void:
        draw_rect(Rect2(-14, -52, 28, 44), E0.DIRTY_STONE)
        draw_rect(Rect2(-18, -60, 36, 10), E0.DIRTY_STONE.lightened(0.04))
        draw_rect(Rect2(-12, -58, 24, 6), E0.PARCH.darkened(0.3))
        draw_rect(Rect2(-20, -8, 40, 8), E0.ASH)

func _draw_bell() -> void:
        draw_line(Vector2(0, -110), Vector2(0, -60), E0.ASH, 2.0)
        draw_colored_polygon(PackedVector2Array([
                Vector2(-16, -60), Vector2(16, -60), Vector2(10, -30), Vector2(-10, -30),
        ]), E0.ASH.lightened(0.05))
        draw_rect(Rect2(-12, -30, 24, 4), E0.PARCH.darkened(0.5))

func _draw_chains() -> void:
        # pillar with taut chains
        draw_rect(Rect2(-18, -140, 36, 140), E0.DIRTY_STONE)
        draw_rect(Rect2(-22, -146, 44, 8), E0.DIRTY_STONE.lightened(0.04))
        for i in 3:
                var y := -130.0 + i * 40.0
                var sag := 6.0 + 4.0 * _seeded(i)
                var pts := PackedVector2Array([
                        Vector2(-18, y), Vector2(-6, y + sag), Vector2(18, y + 4.0),
                ])
                for k in range(pts.size() - 1):
                        draw_line(pts[k], pts[k + 1], E0.ASH, 2.0)
                for k in 5:
                        draw_circle(Vector2(lerpf(-18.0, 18.0, k / 4.0), y + sag * sin(PI * k / 4.0) * 0.9), 2.0, E0.PARCH.darkened(0.5))

func _draw_archive_wall() -> void:
        draw_rect(Rect2(-120, -150, 240, 150), E0.CHARCOAL)
        # record slots: 817 marks in rows
        for row in 12:
                for col in 20:
                        var idx := row * 20 + col
                        if idx >= 817:
                                break
                        var px := -112.0 + col * 11.0
                        var py := -140.0 + row * 11.0
                        var failed := idx != 816
                        var c := Color(E0.DIM.r, E0.DIM.g, E0.DIM.b, 0.5) if failed else Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.8)
                        draw_rect(Rect2(px, py, 6, 6), c)
        # the sealed 818th slot glints
        var pulse := 0.4 + 0.3 * sin(anim_t * 2.0)
        draw_rect(Rect2(-112 + (817 % 20) * 11.0, -140 + (817 / 20) * 11.0, 6, 6),
                Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, pulse))
        draw_rect(Rect2(-120, -4, 240, 6), E0.DIRTY_STONE)

func _draw_fragment_shard() -> void:
        var pulse := 0.5 + 0.4 * sin(anim_t * 2.6)
        draw_circle(Vector2(0, -18), 16.0, Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.08 * pulse))
        draw_colored_polygon(PackedVector2Array([
                Vector2(0, -30), Vector2(7, -20), Vector2(0, -8), Vector2(-7, -19),
        ]), Color(E0.PARCH.r, E0.PARCH.g, E0.PARCH.b, 0.8 + 0.2 * pulse))
        draw_line(Vector2(0, -30), Vector2(0, -8), Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, pulse), 1.0)

func _draw_rotor() -> void:
        var pulled: bool = extra.get("pulled", false)
        draw_rect(Rect2(-16, -46, 32, 46), E0.ASH)
        draw_rect(Rect2(-10, -40, 20, 26), E0.VOID)
        var lever_y := -34.0 if pulled else -12.0
        draw_line(Vector2(0, -12), Vector2(0, lever_y), E0.PARCH, 4.0)
        draw_circle(Vector2(0, lever_y), 5.0, E0.GOLD.darkened(0.2))
        if pulled:
                var glow := 0.4 + 0.2 * sin(anim_t * 4.0)
                draw_circle(Vector2(0, -26), 3.0, Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, glow))

func _draw_toll() -> void:
        var broken: bool = data.state == "BROKEN"
        draw_rect(Rect2(-24, -66, 48, 60), E0.ASH)
        draw_rect(Rect2(-18, -60, 36, 40), E0.VOID)
        # the collection slot, still hungry
        draw_rect(Rect2(-8, -52, 16, 6), E0.CHARCOAL)
        var slot_col := Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.5 if not broken else 0.1)
        if not broken:
                slot_col.a = 0.35 + 0.25 * sin(anim_t * 3.0)
        draw_rect(Rect2(-6, -51, 12, 2), slot_col)
        # gauges of owed purpose
        for i in 3:
                var v: float = 0.0 if broken else 0.4 + 0.2 * sin(anim_t * 2.0 + i * 2.1)
                draw_rect(Rect2(-14, -44 + i * 8, 28, 3), E0.DIRTY_STONE)
                draw_rect(Rect2(-14, -44 + i * 8, 28 * v, 3), Color(E0.GOLD.r, E0.GOLD.g, E0.GOLD.b, 0.5))
        if broken:
                # sparks where the account was settled
                for i in 4:
                        var a := float(i) * 1.7 + anim_t * 2.0
                        draw_circle(Vector2(cos(a) * 18.0, -60.0 + sin(a) * 8.0), 1.5, Color(E0.CRIMSON.r, E0.CRIMSON.g, E0.CRIMSON.b, 0.5))
                draw_line(Vector2(-14, -30), Vector2(14, -18), E0.VOID, 2.0)
        draw_rect(Rect2(-28, -8, 56, 8), E0.DIRTY_STONE)

func _draw_unlisted() -> void:
        var pulse := 0.4 + 0.3 * sin(anim_t * 2.4)
        draw_rect(Rect2(-40, -10, 80, 10), Color(E0.VIOLET.r, E0.VIOLET.g, E0.VIOLET.b, 0.9))
        draw_rect(Rect2(-40, -10, 80, 10), Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, pulse * 0.7), false, 1.5)
        for i in 4:
                draw_rect(Rect2(-34.0 + i * 18.0, -16.0, 8, 6), Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, pulse * 0.4))
        draw_circle(Vector2(0, -30.0), 4.0, Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, pulse * 0.5))
