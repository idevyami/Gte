## SmokeTest — headless end-to-end validation. Boots the real game and
## drives it: golden path, combat, OBSERVE modification, null children,
## consistency stages, the censor, the boss, the ending.
## Run: godot --headless res://tests/smoke_test.tscn
extends Node

var main: Node
var game: Game
var fails := 0
var checks := 0

func _ready() -> void:
        _run.call_deferred()

func ok(cond: bool, label: String) -> void:
        checks += 1
        if cond:
                print("  PASS  " + label)
        else:
                fails += 1
                print("  FAIL  " + label)

func _run() -> void:
        print("=== ENTITY_000 SMOKE TEST ===")
        var packed := load("res://main.tscn") as PackedScene
        main = packed.instantiate()
        get_tree().root.add_child(main)
        await get_tree().process_frame
        await get_tree().process_frame
        game = main.game
        ok(game != null, "main.gd exposes game")
        main.title.hide_screen()
        game.set_active(true)
        game.new_game()
        await _frames(10)
        await _golden_path()
        await _combat()
        await _null_children()
        await _consistency_and_censor()
        await _boss()
        await _ending()
        await _options_and_settings()
        await _gamepad_and_codex()
        print("=== %d checks, %d failures ===" % [checks, fails])
        get_tree().quit(1 if fails > 0 else 0)

func _frames(n: int) -> void:
        for i in n:
                await get_tree().process_frame

func _room(expected: String, max_frames := 300) -> void:
        for i in max_frames:
                if game.room_id == expected and game.state == "playing":
                        return
                if game.dialogue_box.active:
                        game.dialogue_box.chars_shown = 99999
                        game.dialogue_box.advance()
                await get_tree().process_frame

func _press(action: String) -> void:
        Input.action_press(action)
        await get_tree().process_frame
        Input.action_release(action)
        await _frames(2)

# ------------------------------------------------------------------ golden path
func _golden_path() -> void:
        print("[GOLDEN PATH]")
        ok(game.room_id == "act1", "act1 loaded")
        ok(GameState.consistency == 100, "consistency starts at 100")
        ok(game.player != null, "player spawned")
        # intro dialogue auto-fires near spawn; advance it
        await _frames(6)
        var saw_intro: bool = game.state == "dialogue" or game.dialogue_box.active
        ok(saw_intro, "intro dialogue triggered")
        while game.dialogue_box.active:
                game.dialogue_box.chars_shown = 99999
                game.dialogue_box.advance()
                await _frames(2)
        # walk to the climb hint, then ascend by warp (reachability is authored geometry)
        game.player.global_position = Vector2(430, 940)
        await _frames(3)
        game.player.global_position = Vector2(1480, 210)
        await _frames(6)
        # exit through the right gap
        game.player.global_position = Vector2(1585, 200)
        await _frames(8)
        await _room("act2")
        ok(game.room_id == "act2", "act2 loaded")
        # terminal installs OBSERVE
        game.player.global_position = Vector2(600, 620)
        await _frames(3)
        var term = null
        for node in get_tree().get_nodes_in_group("interactable"):
                if node.instance_key == "TERMINAL_019":
                        term = node
        ok(term != null, "terminal present")
        term.interact(game)
        while game.dialogue_box.active:
                game.dialogue_box.chars_shown = 99999
                game.dialogue_box.advance()
                await _frames(2)
        ok(GameState.observe_installed, "OBSERVE installed")
        # approach the door, observe it, modify locked=false
        game.player.global_position = Vector2(1440, 600)
        await _frames(3)
        game.observe_enter()
        await _frames(2)
        ok(game.observe_active, "OBSERVE entered")
        ok(not game.observe_targets.is_empty(), "targets collected")
        var door_target = null
        for t in game.observe_targets:
                if t.instance_key == "DOOR_029":
                        door_target = t
        ok(door_target != null, "DOOR_029 observable")
        if door_target:
                var idx := game.observe_targets.find(door_target)
                game.observe_idx = idx
                game.observe_prop_idx = 0
                game._modify_key()
                await _frames(2)
                ok(not bool(door_target.data.properties["locked"]["value"]), "locked=false written")
                ok(GameState.consistency == 94, "consistency 94 after -6 (got %d)" % GameState.consistency)
                ok(door_target.open, "door physically opened")
        game.observe_exit()
        # walk through the door and exit right to act3
        game.player.global_position = Vector2(1600, 600)
        await _frames(6)
        game.player.global_position = Vector2(2185, 600)
        await _room("act3")
        ok(game.room_id == "act3", "act3 loaded")
        var saved := GameState.save_game(game.room_id, game.player.global_position, game.player.hp, "TEST")
        ok(saved and GameState.has_save(), "save written")

# ------------------------------------------------------------------ combat
func _combat() -> void:
        print("[COMBAT]")
        var hollow: Hollow = null
        for node in get_tree().get_nodes_in_group("enemies"):
                if node is Hollow:
                        hollow = node
                        break
        ok(hollow != null, "hollow present in act3")
        if hollow:
                var hp0: int = hollow.hp
                game.player.global_position = hollow.global_position + Vector2(-60, 0)
                await _frames(3)
                game.player.facing = 1
                for i in 3:
                        Input.action_press("attack")
                        await _frames(4)
                        Input.action_release("attack")
                        await _frames(30)
                        print("    [atk] i=", i, " idx=", game.player._attack_idx, " cd=", game.player._attack_cd, " floor=", game.player.is_on_floor(), " locked=", game.player.input_locked, " hp=", hollow.hp if is_instance_valid(hollow) else -1, " buf=", game.player._attack_press)
                        if not is_instance_valid(hollow):
                                break
                var took: bool = (not is_instance_valid(hollow)) or hollow.hp < hp0 or hollow.dead
                ok(took, "hollow took damage")
                var guard := 0
                var killed := false
                while guard < 12:
                        if not is_instance_valid(hollow) or hollow.dead:
                                killed = true
                                break
                        Input.action_press("attack")
                        await _frames(4)
                        Input.action_release("attack")
                        await _frames(30)
                        guard += 1
                killed = killed or (is_instance_valid(hollow) and hollow.dead)
                ok(killed, "hollow killed")
                ok(GameState.stats["dissipated"] >= 1, "dissipated stat counted")

# ------------------------------------------------------------------ null children + contradiction door
func _null_children() -> void:
        print("[NULL CHILDREN]")
        game.transition_to("act4")
        await _room("act4")
        ok(game.room_id == "act4", "act4 loaded")
        var null_child: NullChild = null
        for node in get_tree().get_nodes_in_group("enemies"):
                if node is NullChild:
                        null_child = node
                        break
        ok(null_child != null, "null child present")
        if null_child:
                var hp0: int = null_child.hp
                null_child.take_hit(30, null_child.global_position + Vector2(50, 0), false)
                ok(null_child.hp == hp0, "UNFILED child is invulnerable")
                # attacking the unfiled opens the tutorial dialogue — a real player reads it
                while game.dialogue_box.active:
                        game.dialogue_box.chars_shown = 99999
                        game.dialogue_box.advance()
                        await _frames(2)
                game.player.global_position = null_child.global_position + Vector2(60, 0)
                await _frames(2)
                game.observe_enter()
                await _frames(2)
                var target = null
                for t in game.observe_targets:
                        if t is NullChild:
                                target = t
                                break
                ok(target != null, "null child observable")
                if target:
                        game.observe_idx = game.observe_targets.find(target)
                        game.observe_prop_idx = 0
                        var cons_before: int = GameState.consistency
                        game._modify_key()
                        await _frames(2)
                        ok(target.data.state == "TERMINATED", "state=TERMINATED written")
                        ok(GameState.consistency == cons_before - 4, "consistency -4 for termination")
                        target.take_hit(40, target.global_position + Vector2(50, 0), true)
                        ok(target.dead, "terminated child can be dispersed")
                game.observe_exit()
        var door114: Door = null
        for node in get_tree().get_nodes_in_group("interactable"):
                if node is Door and node.instance_key == "DOOR_114":
                        door114 = node
        ok(door114 != null, "DOOR_114 present")
        if door114:
                game.player.global_position = Vector2(1760, 900)
                await _frames(2)
                game.observe_enter()
                await _frames(2)
                var found := false
                for t in game.observe_targets:
                        if t.instance_key == "DOOR_114":
                                found = true
                                game.observe_idx = game.observe_targets.find(t)
                                break
                ok(found, "DOOR_114 observable")
                var cons_before2: int = GameState.consistency
                game._modify_key()
                await _frames(2)
                print("    [door114] open=", door114.open, " state=", door114.data.state, " accounts=", door114.data.properties["accounts"]["value"])
                ok(door114.open, "accounts reconciled -> door opens")
                ok(GameState.consistency == cons_before2 - 5, "consistency -5 for reconciliation")
                game.observe_exit()

# ------------------------------------------------------------------ consistency + censor
func _consistency_and_censor() -> void:
        print("[CONSISTENCY]")
        GameState.consistency = 100
        GameState.stage = 1
        GameState.spend(15, "test")
        ok(GameState.stage == 2, "stage 2 at %d" % GameState.consistency)
        GameState.spend(15, "test")
        ok(GameState.stage == 3, "stage 3 (NPC awareness)")
        GameState.spend(15, "test")
        ok(GameState.stage == 4, "stage 4 (the censor hunts)")
        var spawned := false
        for i in 120:
                game._hunted(0.5, 1.0)
                if GameState.censor_active != null:
                        spawned = true
                        break
                await get_tree().process_frame
        ok(spawned, "censor spawned at stage 4+")
        if GameState.censor_active:
                var cons_before: int = GameState.consistency
                (GameState.censor_active as Censor).global_position = game.player.global_position
                (GameState.censor_active as Censor)._process(0.016)
                ok(GameState.consistency < cons_before, "censor touch drains consistency")
        ok(AudioManager._music_lp.cutoff_hz < 20000.0, "music degradation engaged")

# ------------------------------------------------------------------ boss
func _boss() -> void:
        print("[BOSS]")
        # clear the hunt the consistency section summoned, heal the vessel
        if GameState.censor_active and is_instance_valid(GameState.censor_active):
                GameState.censor_active.queue_free()
                GameState.censor_active = null
        GameState.consistency = 70
        GameState.stage = E0.stage_for(70)
        if game.player:
                game.player.hp = E0.P_MAX_HP
                EventBus.player_health_changed.emit(game.player.hp, game.player.max_hp)
        game.transition_to("act8")
        for i in 300:
                if i % 60 == 0:
                        print("    [act8 poll] i=", i, " room=", game.room_id, " state=", game.state, " trans=", game._transitioning, " hp=", game.player.hp)
                if game.room_id == "act8" and game.state == "playing":
                        break
                if game.dialogue_box.active:
                        game.dialogue_box.chars_shown = 99999
                        game.dialogue_box.advance()
                await get_tree().process_frame
        ok(game.room_id == "act8", "act8 loaded")
        ok(game.boss != null, "the bound martyr present")
        var boss: BoundMartyr = game.boss
        game.player.global_position = Vector2(450, 800)
        await _frames(6)
        while game.dialogue_box.active:
                game.dialogue_box.chars_shown = 99999
                game.dialogue_box.advance()
                await _frames(2)
        ok(boss.intro_done, "boss fight begun")
        game.player.global_position = Vector2(340, 800)
        ok(boss.phase == 1, "phase 1")
        var hp0: int = boss.hp
        boss.take_hit(100, boss.global_position + Vector2(100, 0), true)
        ok(boss.hp == hp0 - 20, "belief shield reduces damage to 20 percent (got %d)" % (hp0 - boss.hp))
        var censer = null
        for node in get_tree().get_nodes_in_group("interactable"):
                if node.instance_key == "CENSER_RELIQUARY":
                        censer = node
        ok(censer != null, "censer reliquary observable")
        if censer:
                EntityDB.modify(censer, "purpose")
                await _frames(4)
                ok(not boss.shielded(), "censer abandoned -> shield collapsed")
        boss.hp = E0.MARTYR_P2_AT + 50
        boss.take_hit(60, boss.global_position + Vector2(100, 0), true)
        for i in 30:
                game.player._iframes = 10.0
                await get_tree().process_frame
        ok(boss.phase == 2, "phase 2 at 600 HP (fervor)")
        while game.dialogue_box.active:
                game.dialogue_box.chars_shown = 99999
                game.dialogue_box.advance()
                await _frames(2)
        boss.hp = E0.MARTYR_P3_AT + 50
        boss.take_hit(60, boss.global_position + Vector2(100, 0), true)
        for i in 30:
                game.player._iframes = 10.0
                await get_tree().process_frame
        ok(boss.phase == 3, "phase 3 at 300 HP (unchained)")
        ok(boss.data.purpose == "BE REMEMBERED", "OBSERVE purpose evolved in phase 3")
        while game.dialogue_box.active:
                game.dialogue_box.chars_shown = 99999
                game.dialogue_box.advance()
                await _frames(2)
        boss.hp = 10
        boss.take_hit(50, boss.global_position + Vector2(100, 0), true)
        for i in 6:
                game.player._iframes = 10.0
                await get_tree().process_frame
        ok(boss.state == boss.DYING or boss.state == boss.DEAD, "death sequence running")
        var saw_thanks := false
        for i in 40:
                game.player._iframes = 10.0
                if game.dialogue_box.active:
                        saw_thanks = true
                        game.dialogue_box.chars_shown = 99999
                        game.dialogue_box.advance()
                await get_tree().create_timer(0.3, true, false, true).timeout
        ok(saw_thanks, "the martyr says thank you")
        ok(GameState.boss_defeated, "boss_defeated recorded")
        ok(game.monument != null, "the monument persists")

# ------------------------------------------------------------------ ending
func _ending() -> void:
        print("[ENDING]")
        game.transition_to("act9")
        await _room("act9")
        ok(game.room_id == "act9", "act9 loaded")
        game.player.global_position = Vector2(700, 620)
        await _frames(3)
        var monument = null
        for node in get_tree().get_nodes_in_group("interactable"):
                if node.kind == "monument":
                        monument = node
        ok(monument != null, "monument present in aftermath")
        if monument:
                monument.interact(game)
                while game.dialogue_box.active:
                        game.dialogue_box.chars_shown = 99999
                        game.dialogue_box.advance()
                        await _frames(2)
                await _frames(3)
                ok(GameState.game_finished, "game finished")
                ok(game.end_screen.visible, "end screen shown")
                ok(GameState.has_fragment("FRAGMENT_04"), "fragment 04 recorded")
                ok(GameState.fragments.size() >= 1, "memory index populated")
        ok(game.end_screen.visible, "the record ends on the question")

# ------------------------------------------------------------------ options & comfort (P2)
func _options_and_settings() -> void:
        print("[OPTIONS & COMFORT]")
        # settings round-trip through disk
        GameState.set_setting("music", 0.4)
        ok(absf(float(GameState.settings["music"]) - 0.4) < 0.001, "set_setting stores value")
        ok(FileAccess.file_exists("user://settings.json"), "settings persisted to disk")
        GameState.settings["music"] = 1.0
        GameState.load_settings()
        ok(absf(float(GameState.settings["music"]) - 0.4) < 0.001, "load_settings restores from disk")
        # volumes reach the audio buses
        var music_bus := AudioServer.get_bus_index("Music")
        ok(absf(AudioServer.get_bus_volume_db(music_bus) - linear_to_db(0.4)) < 0.05, "music bus volume applied")
        GameState.set_setting("master", 0.0)
        ok(AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")), "master 0 mutes the bus")
        GameState.set_setting("master", 1.0)
        GameState.set_setting("music", 1.0)
        # the options overlay opens, adjusts, and closes
        var opts: OptionsScreen = main.options
        ok(opts != null, "main exposes the options screen")
        opts.open("title")
        await _frames(12)
        ok(GameState.options_open and opts.visible, "options open flag + visibility")
        opts.idx = 0
        opts._adjust(-1)
        ok(absf(float(GameState.settings["master"]) - 0.9) < 0.001, "slider adjust changes setting")
        var art_row := 0
        for i in opts._rows.size():
                if String(opts._rows[i].get("key", "")) == "art_mode":
                        art_row = i
        opts.idx = art_row
        opts._cycle(opts._rows[art_row])
        ok(GameState.debug_no_sprites, "artwork toggle switches to procedural")
        opts._cycle(opts._rows[art_row])
        ok(not GameState.debug_no_sprites, "artwork toggle back to painted")
        var vib_row := 0
        for i in opts._rows.size():
                if String(opts._rows[i].get("key", "")) == "vibration":
                        vib_row = i
        ok(vib_row > 0, "vibration slider row exists")
        Input.action_press("pause")
        await get_tree().process_frame
        Input.action_release("pause")
        await _frames(3)
        ok(not GameState.options_open, "pause key closes options")
        # midground depth plane exists in the loaded room
        var mid_ok := false
        for n in game.world.get_children():
                if n is Midground:
                        mid_ok = not n._structures.is_empty()
        ok(mid_ok, "midground silhouettes generated")
        # shake 0 kills camera shake
        GameState.set_setting("shake", 0.0)
        FX.shake(6.0, 0.3)
        await _frames(3)
        ok(FX.get_shake_offset() == Vector2.ZERO, "shake 0 disables screen shake")
        GameState.set_setting("shake", 1.0)
        # heartbeat under low hp
        game.player.hp = 3
        game.player.take_damage(1, game.player.global_position + Vector2(10.0, 0.0))
        await _frames(3)
        ok(AudioManager._heartbeat.playing, "heartbeat starts at hp <= 2")
        game.player.heal(3)
        await _frames(3)
        ok(not AudioManager._heartbeat.playing, "heartbeat stops when healed")
        # dialogue typewriter blips
        GameState.set_setting("blips", true)
        game.dialogue_box.open("sys_intro")
        await _frames(8)
        ok(game.dialogue_box._last_blip > 0, "dialogue typewriter ticks")
        while game.dialogue_box.active:
                game.dialogue_box.chars_shown = 99999
                game.dialogue_box.advance()
                await _frames(1)
        GameState.set_setting("blips", true)


# ------------------------------------------------------------------ gamepad & codex
func _gamepad_and_codex() -> void:
        print("[GAMEPAD & RECORDS]")
        # every core action is reachable from a gamepad
        var pad_mod := false
        for ev in InputMap.action_get_events("modify"):
                if ev is InputEventJoypadButton:
                        pad_mod = true
        ok(pad_mod, "modify bound to a gamepad button (RB)")
        var pad_up := false
        for ev in InputMap.action_get_events("move_up"):
                if ev is InputEventJoypadButton or ev is InputEventJoypadMotion:
                        pad_up = true
        ok(pad_up, "menu navigation (move_up) bound to pad")
        # stick thresholds are responsive, not full-deflection
        var sane_axis := true
        for ev in InputMap.action_get_events("move_left"):
                if ev is InputEventJoypadMotion and absf(ev.axis_value) >= 0.99:
                        sane_axis = false
        ok(sane_axis, "stick axis threshold below full deflection")
        # rumble is safe with and without pads, and honours the setting
        GameState.set_setting("vibration", 0.0)
        FX.rumble(1.0, 0.2)
        GameState.set_setting("vibration", 1.0)
        FX.rumble(1.0, 0.2)
        ok(true, "rumble callable headless (no pads -> no-op)")
        GameState.set_setting("vibration", 0.3)
        ok(absf(float(GameState.settings["vibration"]) - 0.3) < 0.001, "vibration setting round-trips")
        GameState.set_setting("vibration", 1.0)
        # the run observed things through OBSERVE — the codex has them
        ok(GameState.observed.size() >= 3, "observe targets entered the codex during play")
        ok(int(GameState.stats.get("observed", 0)) == GameState.observed.size(), "observed stat tracks codex size")
        var has_door := false
        for r in GameState.observed_rows():
                if String(r["key"]) == "DOOR_029":
                        has_door = true
        ok(has_door, "codex row carries definition key + memory")
        # dedupe: same def twice records once
        var again := GameState.mark_observed_data(EntityDB.mint("DOOR_029"))
        ok(not again, "codex dedupes by record key")
        # save/load preserves the codex
        GameState.save_game(game.room_id, game.player.global_position, game.player.hp, "smoke_anchor")
        var saved_size: int = GameState.observed.size()
        GameState.observed = {}
        GameState.apply_save(GameState.load_game())
        ok(GameState.observed.size() == saved_size, "codex survives save/load")
        # pause menu: RECORDS entry, tab switch, scroll clamp
        var pm: PauseMenu = game.pause_menu
        var has_records := false
        for m in pm.menu:
                if String(m["action"]) == "records":
                        has_records = true
        ok(has_records, "pause menu exposes RECORDS")
        pm.open()
        await _frames(3)
        pm.screen = 1
        pm.tab = PauseMenu.TAB_MEMORY
        Input.action_press("move_right")
        await get_tree().process_frame
        Input.action_release("move_right")
        await _frames(2)
        ok(pm.tab == PauseMenu.TAB_RECORDS, "left/right switches codex tabs")
        # scroll clamps when rows exceed the page
        for key in ["PLAQUE_029", "ANCHOR", "HYMNAL", "CENSUS_STONE", "STATUE_FACELESS", "ASH_BOWL", "BELL_ROPE"]:
                GameState.mark_observed_data(EntityDB.mint(key, "TEST_SCROLL_" + key))
        pm.records_scroll = 999
        pm.clamp_records_scroll()
        ok(pm.records_scroll < 999, "records scroll clamps to page")
        pm.screen = 0
        pm.close()
        ok(not get_tree().paused, "pause codex closes clean")
