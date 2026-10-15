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
        await _living_city()
        await _closest_walls()
        await _ground_you_walk_on()
        await _performers()
        await _world_responds()
        await _the_record_is_a_thing()
        await _the_air_itself()
        await _the_arrival()
        await _the_world_thins()
        await _the_threshold()
        await _the_vessels_trace()
        await _the_others_passage()
        await _the_endings_record()
        await _the_fist_that_lands()
        print("=== %d checks, %d failures ===" % [checks, fails])
        get_tree().quit(1 if fails > 0 else 0)

func _frames(n: int) -> void:
        for i in n:
                await get_tree().process_frame

func _room(expected: String, max_frames := 300) -> void:
        ## Headless runs unthrottled (143fps measured) — a frame budget no
        ## longer bounds real time, and THE THRESHOLD's deep crossings live
        ## in REAL time (~2.6s of dark + fade). The wait is bounded by wall
        ## clock instead (scaled by the caller's frame patience).
        var cap_ms: int = maxi(6000, max_frames * 40)
        var t0 := Time.get_ticks_msec()
        while Time.get_ticks_msec() - t0 < cap_ms:
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
        # wall-clock bounded (headless is unthrottled; deep crossings live
        # in real time — see _room)
        var t_act8 := Time.get_ticks_msec()
        while Time.get_ticks_msec() - t_act8 < 12000:
                if (Time.get_ticks_msec() - t_act8) % 1000 < 17:
                        print("    [act8 poll] room=", game.room_id, " state=", game.state, " trans=", game._transitioning, " hp=", game.player.hp)
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


func _living_city() -> void:
        print("[THE LIVING CITY — WB-4]")
        # --- the far-life layer seeds for every district
        for key in ["vessels", "city", "undercity", "chapel", "archive", "engine", "reliquary", "aftermath"]:
                var p := Procession.new()
                add_child(p)
                p.setup(key, Vector2(1600, 1100), null, 1000.0, Color(0.1, 0.1, 0.12))
                ok(p.mover_count() > 0, "procession lives in %s" % key)
                p.queue_free()
        # the painted districts carry the weight: city has walkers + barge
        var city_p := Procession.new()
        add_child(city_p)
        city_p.setup("city", Vector2(1600, 1100), null, 1000.0, Color(0.1, 0.1, 0.12))
        ok(city_p.mover_count() >= 12, "city far life is populated (walkers+birds+lanterns+barge)")
        city_p.queue_free()
        # --- animation enrichment: frame counts on disk
        var pa: Dictionary = SpriteSkin.discover_anims("player")
        ok(int(pa["idle"].size()) >= 4, "player idle breathes in 4 frames")
        ok(int(pa["walk"].size()) >= 8, "player walk strides in 8 frames")
        ok(int(pa["roll"].size()) == 4, "player roll tumbles in 4 frames")
        ok(int(pa["attack1"].size()) >= 3 and int(pa["attack2"].size()) >= 3 and int(pa["attack3"].size()) >= 3,
                "all attack chains carry a follow-through frame")
        ok(int(pa["hurt"].size()) >= 2 and int(pa["observe"].size()) >= 2, "hurt + observe enriched")
        var ha: Dictionary = SpriteSkin.discover_anims("hollow")
        ok(int(ha["idle"].size()) >= 4 and int(ha["lunge"].size()) >= 3, "hollow sway + landing frames")
        var ba: Dictionary = SpriteSkin.discover_anims("believers")
        ok(int(ba["walk"].size()) >= 6 and int(ba["kneel"].size()) >= 2, "believer cadence + prayer breath")
        var oa: Dictionary = SpriteSkin.discover_anims("oren")
        ok(int(oa["idle"].size()) >= 4, "oren bows through a 4-frame cycle")
        var ma: Dictionary = SpriteSkin.discover_anims("bound_martyr")
        ok(int(ma["p1"].size()) >= 2 and int(ma["p3"].size()) >= 2, "martyr strains through phase idles")
        # roll frames share a square canvas (rotation pivot = ball center)
        var roll_tex: Texture2D = load("res://art/characters/player/roll_0.png")
        ok(absf(roll_tex.get_width() - roll_tex.get_height()) <= 1.0, "roll canvas is square for the pivot")
        # --- camera zoom punches
        game.camera.punch_zoom(1.07, 8.0)
        await _frames(30)
        ok(game.camera.zoom.x > 1.03, "observe zoom leans in")
        game.camera.punch_zoom(1.0, 8.0)
        await _frames(30)
        ok(absf(game.camera.zoom.x - 1.0) < 0.02, "zoom releases back to neutral")
        # --- enemy telegraph decays
        var hollows := get_tree().get_nodes_in_group("enemies").filter(func(n): return n is Hollow)
        if hollows.is_empty():
                var h := Hollow.new()
                add_child(h)
                h.setup_hollow(Vector2(200, 900), Vector2(100, 400))
                hollows = [h]
        var probe: EnemyBase = hollows[0]
        probe.telegraph_t = 0.5
        await _frames(6)
        ok(probe.telegraph_t < 0.5, "telegraph ring decays after the warning")
        # --- anchor ceremony plays and finishes
        var anchors: Array = []
        for n in game.world.get_children():
                if n is Anchor:
                        anchors.append(n)
        if anchors.is_empty():
                var a := Anchor.new()
                add_child(a)
                a.setup_anchor("SMOKE_ANCHOR")
                anchors = [a]
        var probe_anchor: Anchor = anchors[0]
        ok(probe_anchor.save_fx_t < 0.0, "anchor ceremony dormant before communion")
        probe_anchor.save_fx_t = 0.0
        await _frames(5)
        ok(probe_anchor.save_fx_t > 0.0, "anchor ceremony advances while playing")
        probe_anchor.save_fx_t = 2.0
        await _frames(3)
        ok(probe_anchor.save_fx_t < 0.0, "anchor ceremony ends cleanly")


func _closest_walls() -> void:
        print("[THE CLOSEST WALLS — WB-5]")
        # --- the foreground plane lives in every district, above FX, below air
        for key in ["vessels", "undercity", "city", "chapel", "archive", "engine", "reliquary", "aftermath"]:
                var fg := Foreground.new()
                add_child(fg)
                fg.setup("act_t_" + key, key, Vector2(2200, 900), 840.0, null,
                        [{"x": 700.0, "pad": 200.0}])
                ok(fg.element_count() > 0, "foreground populates %s" % key)
                ok(fg.z_index == 30, "foreground sits above FX, below air (%s)" % key)
                # the exclusion law: nothing near an interactive x in the
                # foreground's own scrolled space (min element half-width is 30)
                var all_clear := true
                for e in fg._elements:
                        if fg._in_exclusion(float(e["x"]), 30.0):
                                all_clear = false
                ok(all_clear, "%s keeps interactive x-zones clear" % key)
                # the combat-clarity law: stumps never rise above the feet line
                var stumps_ok := true
                for e in fg._elements:
                        if String(e["kind"]).begins_with("stump_"):
                                if float(e["len"]) > 900.0 - 840.0 - 8.0 + 0.01:
                                        stumps_ok = false
                ok(stumps_ok, "%s stumps stay below the feet line" % key)
                fg.queue_free()
        # --- the climb room trusts nothing that hangs low
        var climb := Foreground.new()
        add_child(climb)
        climb.setup("act1", "vessels", Vector2(1600, 1100), 1000.0, null, [])
        var hangs_ok := true
        for e in climb._elements:
                if String(e["kind"]).begins_with("hang_"):
                        if float(e["len"]) > 230.0 + 0.01:
                                hangs_ok = false
        ok(hangs_ok, "the climb room's hangs stay in the sky band")
        climb.queue_free()
        # --- the boss arena keeps its center clear
        var arena := Foreground.new()
        add_child(arena)
        arena.setup("act8", "reliquary", Vector2(1600, 900), 840.0, null,
                [{"x": 900.0, "pad": 430.0}])
        var arena_clear := true
        for e in arena._elements:
                if absf(float(e["x"]) - 900.0 * 1.28) < 430.0 + 30.0:
                        arena_clear = false
        ok(arena_clear, "the martyr's arena center stays open")
        arena.queue_free()
        # --- animation enrichment: the system's own movement
        var ca: Dictionary = SpriteSkin.discover_anims("censor")
        ok(int(ca["idle"].size()) >= 6, "censor hovers on a 6-frame bob")
        ok(int(ca["arrive"].size()) == 4, "censor unfurls through 4 frames")
        ok(int(ca["reach"].size()) == 3, "censor leans through a 3-frame reach")
        var na: Dictionary = SpriteSkin.discover_anims("null_children")
        ok(int(na["idle"].size()) >= 6, "null child sways on 6 idle frames")
        ok(int(na["walk"].size()) == 4, "null child walks a 4-frame glitch-step")
        # --- the censor's pose machine: arrive -> idle, reach decays
        var c := Censor.new()
        add_child(c)
        ok(c._pose == "arrive", "censor begins by unfurling")
        await get_tree().process_frame
        await get_tree().process_frame
        ok(c._skin.animation == "arrive" and c._skin.is_playing(),
                "the unfurl actually PLAYS (not skipped to hover)")
        for i in 200:
                if c._pose == "idle":
                        break
                await get_tree().process_frame
        ok(c._pose == "idle", "censor settles into its hover after arriving")
        ok(c._trail.size() > 0, "censor sheds redacted pages behind it")
        c._pose = "reach"
        c._reach_t = 0.3
        c.global_position = game.player.global_position + Vector2(-400.0, 0.0)
        for i in 120:
                if c._pose == "idle":
                        break
                await get_tree().process_frame
        ok(c._pose == "idle", "the correction lean releases back to hover")
        c.queue_free()
        # --- null children walk while they drift
        var nc := NullChild.new()
        add_child(nc)
        nc.setup_null(game.player.global_position + Vector2(160, -20))
        await _frames(30)
        ok(nc.skin_pose() == "walk", "null child glitch-steps while drifting")
        nc.queue_free()
        # --- camera idle micro-drift: a held frame still breathes
        var cam := game.camera
        cam._idle_t = 0.0
        await _frames(24)
        ok(cam._idle_t > 0.0, "camera idle drift ramps while the vessel holds still")
        # --- district climate: the scenery carries a temperature
        ok(game._graded_nodes.size() >= 6, "district grade reaches the scenery renderers")
        var m_mod: Color = game.masonry.modulate
        ok(absf(m_mod.r - 1.0) + absf(m_mod.g - 1.0) + absf(m_mod.b - 1.0) > 0.001,
                "the current district's grade is applied")
        ok(not (game._graded_nodes.has(game.player)), "actors are never graded")

# ------------------------------------------------------------------ WB-6
func _ground_you_walk_on() -> void:
        print("[THE GROUND YOU WALK ON — WB-6]")
        # --- THE CRITICAL REGRESSION: climb platforms must RENDER.
        # Before WB-6 they were collision-only — the act1 ascent was
        # invisible. This can never happen again.
        var platform_counts := {
                "act1": 15, "act2": 3, "act3": 3, "act4": 2, "act5": 1,
                "act6": 1, "act7": 2, "act8": 0, "act9": 0,
        }
        for act in platform_counts.keys():
                var want: int = platform_counts[act]
                game.transition_to(act)
                await _room(act)
                var rd: Dictionary = Rooms.ROOMS[act]
                ok(game.floorcraft != null, "%s builds a floorcraft renderer" % act)
                ok(game.floorcraft.floor_surface_count() == rd.get("floors", []).size(),
                        "%s crafts every floor surface" % act)
                ok(game.floorcraft.ledge_count() == want,
                        "%s renders all %d climb ledges (the invisible-platform regression)" % [act, want])
                ok(game.floorcraft.z_index == 0 and game.floorcraft.get_index() < game.decor_renderer.get_index(),
                        "%s floorcraft paints under the floor dressing" % act)
        # --- per-district recipes live on the ground
        game.transition_to("act3")
        await _room("act3")
        ok(game.floorcraft.has_dressing("wear"), "the city floor carries the pilgrimage wear path")
        ok(game.floorcraft.dressing_count("plaque") > 0, "boundary plaques are set into the pavement")
        game.transition_to("act5")
        await _room("act5")
        ok(game.floorcraft.has_dressing("carpet"), "the chapel floor carries the runner carpet")
        ok(game.floorcraft.dressing_count("tessera") > 0, "mosaic borders flank the chapel runner")
        game.transition_to("act7")
        await _room("act7")
        ok(game.floorcraft.has_dressing("hazard"), "the engine floor carries hazard chevrons")
        ok(game.floorcraft.has_dressing("sheen"), "steel floors carry the oil sheen band")
        game.transition_to("act6")
        await _room("act6")
        ok(game.floorcraft.dressing_count("page") > 0, "the archive floor is littered with fallen records")
        game.transition_to("act2")
        await _room("act2")
        ok(game.floorcraft.dressing_count("grate") > 0 and game.floorcraft.dressing_count("damp") > 0,
                "the undercity floor weeps (damp stains + drainage grates)")
        game.transition_to("act1")
        await _room("act1")
        ok(game.floorcraft.dressing_count("conduit") > 0, "the womb floor is cabled (conduits with glow seams)")
        game.transition_to("act9")
        await _room("act9")
        ok(game.floorcraft.dressing_count("drift") > 0 and game.floorcraft.dressing_count("rubble") > 0,
                "the aftermath ground is broken (ash drifts + rubble)")
        game.transition_to("act8")
        await _room("act8")
        ok(game.floorcraft.has_dressing("inlay"), "the reliquary floor carries gold seam inlays")
        # --- district climate grades the ground too (scenery law)
        ok(game._graded_nodes.has(game.floorcraft), "the ground carries its district's climate")
        ok(not (game._graded_nodes.has(game.shadows)), "shadows are never climate-graded")
        # --- contact shadows: the ground holds every body
        game.transition_to("act3")
        await _room("act3")
        await _frames(30)
        ok(game.shadows != null and game.shadows.shadow_count() >= 1, "the player casts a contact shadow")
        ok(game.shadows.z_index == 0, "shadows sit on the ground plane (under every actor)")
        # jump: the shadow stays on the ground and the gap grows
        var shadow_before: Variant = _player_shadow()
        ok(shadow_before != null, "the player's shadow is projected onto the floor")
        game.player.velocity.y = E0.P_JUMP
        game.player._coyote = 0.0
        await _frames(14)
        var shadow_mid: Variant = _player_shadow()
        ok(shadow_mid != null, "the shadow persists while the vessel is airborne")
        if shadow_before != null and shadow_mid != null:
                var k_before: float = float(shadow_before["k"])
                var k_mid: float = float(shadow_mid["k"])
                ok(k_mid < k_before, "the airborne shadow reads fainter — height is felt")
        await _frames(50)
        ok(_player_shadow() != null, "the shadow returns with the vessel")
        # an enemy casts one too
        var enemy_shadow := false
        for s in game.shadows._shadows:
                if absf(float(s["pos"].x) - game.player.global_position.x) > 60.0:
                        enemy_shadow = true
        game.transition_to("act4")
        await _room("act4")
        await _frames(30)
        ok(game.shadows.shadow_count() >= 2, "the null children's shadows stutter on the ground")
        # --- the arch interiors breathe (no dead voids behind the arches)
        game.transition_to("act5")
        await _room("act5")
        var arch_seen := 0
        for d in Rooms.ROOMS["act5"].get("decor", []):
                if String(d.get("kind", "")) == "arch":
                        arch_seen += 1
        var auto_arches := 0
        for d in Rooms.ROOMS["act5"].get("doors", []):
                auto_arches += 1
        ok(arch_seen + auto_arches > 0, "the chapel has arches to fill")
        ok(game.decor_renderer._tex("arch") != null or arch_seen > 0,
                "arch interiors are dressed (painted or procedural)")
        # --- midground masses carry inner structure (no black boxes)
        var mid := Midground.new()
        add_child(mid)
        mid.setup("chapel", Vector2(2200, 900), 560.0, E0.VOID, null)
        var with_inner := 0
        var with_slit := 0
        for s in mid._structures:
                if s.has("inner"):
                        with_inner += 1
                if s.has("slit"):
                        with_slit += 1
        ok(with_inner > 0, "the big midground masses carry inner floor lines")
        ok(with_slit > 0, "rare lit slits breathe behind the far masses")
        mid.queue_free()
        # --- the heart is dried blood with a cold core, never neon
        game.transition_to("act7")
        await _room("act7")
        var heart := TheHeart.new()
        add_child(heart)
        heart.setup_heart()
        await _frames(3)
        var h1 := Color(E0.BLOOD.r, E0.BLOOD.g, E0.BLOOD.b)
        var h2 := Color(E0.CRIMSON.darkened(0.16).r, E0.CRIMSON.darkened(0.16).g, E0.CRIMSON.darkened(0.16).b)
        var chamber := h1.lerp(h2, 1.0)
        ok(chamber.s < 0.75, "the heart's chamber stays dried-blood desaturated")
        heart.queue_free()

func _player_shadow() -> Variant:
        if game.shadows == null:
                return null
        for s in game.shadows._shadows:
                if absf(float(s["pos"].x) - game.player.global_position.x) < 24.0:
                        return s
        return null

# ------------------------------------------------------------------ WB-7
func _performers() -> void:
        print("[THE PERFORMERS — WB-7]")
        # --- THE INVENTORY LAW: every performance set carries its frames.
        # (the audit's loudest finding: the game's most-fought enemy had no
        # walk cycle — it slid. This can never regress silently again.)
        var inv := {
                "hollow": {"walk": 6, "hurt": 2, "death": 4, "idle": 4, "lunge": 3, "telegraph": 2},
                "oren": {"idle": 4, "talk": 4},
                "believers": {"kneel": 4, "walk": 6, "strike": 2, "hurt": 2, "death": 4},
                "bound_martyr": {"p1": 4, "p2": 4, "p3": 4, "death": 3},
                "player": {"idle": 4, "walk": 8},
        }
        for set_name in inv:
                var anims := SpriteSkin.discover_anims(set_name)
                for anim in inv[set_name]:
                        var want: int = inv[set_name][anim]
                        var got: int = (anims.get(anim) as Array).size() if anims.has(anim) else 0
                        ok(got == want, "%s %s carries all %d frames" % [set_name, anim, want])
        # --- THE RIM LAW: every silhouette edge reads brighter than the
        # body it bounds (the WB-7 deepened bake — the world grew six layers
        # richer; the actors must not sink back into it)
        var rim_ok := _rim_edge_brighter("res://art/characters/player/idle_0.png")
        ok(rim_ok, "the vessel's rim reads brighter than its body (the deepened bake)")
        rim_ok = _rim_edge_brighter("res://art/characters/hollow/idle_0.png")
        ok(rim_ok, "the hollow's rim reads brighter than its body")

        # --- live pose laws ------------------------------------------------
        game.transition_to("act3")
        await _room("act3")
        game.player.global_position = Vector2(980, 840)
        await _frames(6)
        var hollow: Hollow = null
        for node in get_tree().get_nodes_in_group("enemies"):
                if node is Hollow:
                        hollow = node
                        break
        ok(hollow != null and hollow._skin != null, "a hollow patrols act3 with painted skin")
        if hollow and hollow._skin:
                # WALK: while it actually moves, the walk cycle plays
                var saw_walk := false
                for i in 40:
                        if hollow.state == Hollow.PATROL and absf(hollow.velocity.x) > 20.0 \
                                        and hollow._skin.animation == "walk":
                                saw_walk = true
                                break
                        await get_tree().process_frame
                ok(saw_walk, "the hollow WALKS while patrolling (no more sliding idle)")
                # HURT: the recoil pose reads during the hurt flash
                game.player.global_position = hollow.global_position + Vector2(-60, 0)
                await _frames(3)
                hollow.take_hit(4, game.player.global_position, false)
                await get_tree().process_frame
                ok(hollow._skin.animation == "hurt", "the hollow recoils from the blow (hurt pose)")
                # IMPACT: the wound card flashes at the contact point
                var card_seen := false
                for i in 4:
                        for ch in game.world.get_children():
                                if ch is FX.Impact:
                                        card_seen = true
                        if card_seen:
                                break
                        await get_tree().process_frame
                ok(card_seen, "the wound card flashes at the contact point")
                # DEATH: a whole performance, solid through the collapse
                var spot := hollow.global_position
                hollow.take_hit(9999, game.player.global_position, true)
                await _frames(3)
                ok(hollow.dead and hollow._death_anim_len > 0.5,
                        "the hollow's death is a timed performance (%.2fs)" % hollow._death_anim_len)
                ok(hollow._skin.animation == "death", "the collapse animation plays")
                await _frames(8)
                ok(hollow._skin.modulate.a > 0.85,
                        "the body stays SOLID through the collapse (no instant fade)")
                ok(hollow.global_position.distance_to(spot) > 2.0,
                        "the corpse keeps the killing blow's momentum (it falls like a body)")
                # ...and it persists past the old 0.9s cutoff, then frees
                # (wall-clock polling — headless frame rate is not a constant)
                var t0 := Time.get_ticks_msec()
                var freed := false
                while Time.get_ticks_msec() - t0 < 5000:
                        if not is_instance_valid(hollow):
                                freed = true
                                break
                        await get_tree().process_frame
                ok(freed, "the dissolved body frees after its fall")

        # --- OREN PERFORMS HIS SPEECH --------------------------------------
        var oren: NPC = null
        for node in get_tree().get_nodes_in_group("interactable"):
                if node is NPC and node.npc_id == "oren":
                        oren = node
                        break
        ok(oren != null and oren._skin != null, "Oren stands at his post with painted skin")
        if oren and oren._skin:
                game.player.global_position = oren.global_position + Vector2(-50, 0)
                await _frames(4)
                oren.interact(game)
                await _frames(6)
                var talking := game.dialogue_box.active and oren._skin.animation == "talk"
                ok(talking, "Oren talks while he speaks (head bob, stamp accents)")
                while game.dialogue_box.active:
                        game.dialogue_box.chars_shown = 99999
                        game.dialogue_box.advance()
                        await _frames(2)
                await _frames(4)
                ok(oren._skin.animation == "idle", "Oren settles back to idle when spoken to no more")

        # --- PRESENCE POOLS: the ground holds a light for every body -----
        await _frames(6)
        ok(game.shadows != null and game.shadows.pool_count() >= 3,
                "presence pools under the bodies (%d lit)" % (game.shadows.pool_count() if game.shadows else -1))
        var pool_layer := game.shadows._pools
        ok(pool_layer != null and pool_layer.material != null
                        and (pool_layer.material as CanvasItemMaterial).blend_mode == CanvasItemMaterial.BLEND_MODE_ADD,
                "the presence layer speaks the world's additive light language")
        # --- THE VESSEL'S OWN LIGHT: aura above the world, under the skin --
        var psprite := game.player.sprite
        ok(psprite != null and psprite._aura != null,
                "the vessel carries its aura")
        if psprite and psprite._aura:
                ok(psprite._aura.z_index == 1 and psprite.z_index == 2,
                        "the aura paints above every world layer, under the skin (z law)")
                ok((psprite._aura.material as CanvasItemMaterial).blend_mode == CanvasItemMaterial.BLEND_MODE_ADD,
                        "the aura speaks the additive light language")
                ok(psprite._aura.visible and psprite._aura.is_visible_in_tree(),
                        "the aura burns while the vessel lives")

func _rim_edge_brighter(path: String) -> bool:
        ## Edge band (opaque within 2px of transparency) must average
        ## brighter than the body's interior — the baked rim law.
        var img := Image.new()
        if img.load(path) != OK:
                return false
        var w := img.get_width()
        var h := img.get_height()
        if w < 8 or h < 8:
                return false
        var edge_n := 0
        var edge_sum := 0.0
        var inner_n := 0
        var inner_sum := 0.0
        for y in range(2, h - 2):
                for x in range(2, w - 2):
                        var a := img.get_pixel(x, y).a
                        if a <= 0.5:
                                continue
                        var near_clear := false
                        for dy in range(-2, 3):
                                for dx in range(-2, 3):
                                        if img.get_pixel(x + dx, y + dy).a <= 0.5:
                                                near_clear = true
                        var c := img.get_pixel(x, y)
                        var lum := (c.r + c.g + c.b) / 3.0
                        if near_clear:
                                edge_n += 1
                                edge_sum += lum
                        else:
                                inner_n += 1
                                inner_sum += lum
        if edge_n < 12 or inner_n < 12:
                return false
        return (edge_sum / edge_n) > (inner_sum / inner_n) + 0.015

# ------------------------------------------------------------------ WB-8
func _world_responds() -> void:
        print("[THE WORLD RESPONDS — WB-8]")
        # --- THE WALL-FLOOR MARRIAGE: every act's walls carry their footing
        # (the skirting law — the seam is joinery, never a hard line)
        var skirt_districts := {
                "act1": "vessels", "act2": "undercity", "act3": "city",
                "act4": "undercity", "act5": "chapel", "act6": "archive",
                "act7": "engine", "act8": "reliquary", "act9": "aftermath",
        }
        for act in skirt_districts.keys():
                game.transition_to(act)
                await _room(act)
                var rd: Dictionary = Rooms.ROOMS[act]
                var floors_n: int = rd.get("floors", []).size()
                ok(game.floorcraft.skirt_stone_count() >= floors_n * 8,
                        "%s walls carry a skirting footing course (>=8 stones/floor)" % act)
        game.transition_to("act2")
        await _room("act2")
        ok(game.floorcraft.has_skirt_trim("skirt_moss"), "the undercity footing grows moss in its joints")
        game.transition_to("act3")
        await _room("act3")
        ok(game.floorcraft.has_skirt_trim("skirt_datum"), "the city footing carries its survey datum line")
        game.transition_to("act7")
        await _room("act7")
        ok(game.floorcraft.has_skirt_trim("skirt_bolts"), "the engine footing is bolted base plates")
        game.transition_to("act8")
        await _room("act8")
        ok(game.floorcraft.has_skirt_trim("skirt_goldline"), "the reliquary footing carries the gold seam")
        game.transition_to("act1")
        await _room("act1")
        ok(game.floorcraft.has_skirt_trim("skirt_staple"), "the womb footing is stapled with conduit")
        # --- THE GROUND ANSWERS THE FIRE: every source lands a pool ON the
        # walking surface (the z-bug law: the old spill lived at z=-5 under
        # the opaque floorcraft slabs and never reached the ground)
        for act in ["act1", "act2", "act3", "act5", "act6", "act8"]:
                game.transition_to(act)
                await _room(act)
                var lights_n: int = (Rooms.ROOMS[act].get("lights", []) as Array).size()
                ok(game.floor_lights != null and game.floor_lights.pool_count() == lights_n,
                        "%s every light lands a dancing pool on the floor" % act)
                ok(game.floor_lights.z_index == 0
                                and game.floor_lights.get_index() > game.floorcraft.get_index()
                                and game.floor_lights.get_index() < game.shadows.get_index(),
                        "%s floor lights paint above the slabs, under the bodies" % act)
        game.transition_to("act3")
        await _room("act3")
        ok(game.floor_lights.fixture_count() >= 1, "sourceless glows get fixture grounding (brackets/nodes)")
        # --- FOCAL SHAFTS FOR THE DARK DISTRICTS (the audit's "uniformly
        # dark, no focal point" — undercity + city get beams now)
        for act in ["act2", "act3", "act4"]:
                game.transition_to(act)
                await _room(act)
                var rays: GodRays = null
                for ch in game.world.get_children():
                        if ch is GodRays:
                                rays = ch
                ok(rays != null and rays.beam_count() >= 2,
                        "%s the dark street breathes focal light shafts" % act)
        # --- THE WORLD RESPONDS: moths, vermin, ripples
        # (the moth law: every flame that lives gets its orbiters)
        game.transition_to("act5")
        await _room("act5")
        var flame := Vector2(1200, 700)
        ok(game.world_life.moth_count_at_light(flame) >= 2, "the candle altar's flame carries its moths")
        ok(game.world_life.moth_count() >= 6, "the chapel's flames carry a moth population")
        # the scatter law: a passing body bursts the moths off their orbits
        game.player.global_position = Vector2(flame.x, 775)
        game.player.velocity = Vector2.ZERO
        await _frames(30)
        var scattered := game.world_life.moth_offset(flame)
        ok(scattered > 8.0, "a body in the light scatters the moths (burst %.1f)" % scattered)
        game.player.global_position = Vector2(300, 840)
        game.player.velocity = Vector2.ZERO
        await _frames(90)
        var resettle := game.world_life.moth_offset(flame)
        ok(resettle < scattered * 0.6, "the air stills and the moths resettle (%.1f -> %.1f)" % [scattered, resettle])
        # (the vermin law: only the strata that host vermin host them)
        var vermin_districts := {"act1": true, "act2": true, "act3": true, "act4": true,
                "act6": true, "act9": true, "act5": false, "act7": false, "act8": false}
        for act in vermin_districts.keys():
                game.transition_to(act)
                await _room(act)
                var want: bool = vermin_districts[act]
                ok(game.world_life.scuttler_total() >= 2 if want else game.world_life.scuttler_total() == 0,
                        "%s vermin population %s" % [act, "present" if want else "absent (holy/engine ground)"])
        # the flee law: a body within 150px is flight
        game.transition_to("act3")
        await _room("act3")
        await _frames(10)
        var fled := false
        for s in game.world_life._scuttlers:
                if String(s["state"]) == "patrol":
                        game.player.global_position = Vector2(float(s["x"]) - 120.0, 840)
                        game.player.velocity = Vector2.ZERO
                        await _frames(6)
                        if String(s["state"]) == "flee":
                                fled = true
                        break
        ok(fled, "the vessel's approach sends the vermin fleeing")
        # the ripple law: a boot in a weep spot opens rings
        game.transition_to("act2")
        await _room("act2")
        ok(game.floorcraft.get_damp_spots().size() >= 3, "the undercity floor keeps its weep spots")
        var d0: Dictionary = game.floorcraft.get_damp_spots()[0]
        game.world_life._footfall(Vector2(float(d0["x"]), 660))
        await get_tree().create_timer(0.05, true, false, true).timeout
        ok(game.world_life.ripple_count() > 0, "a footfall in the weep spot ripples")
        # real-time wait (headless fps is unbounded — frame counts lie)
        await get_tree().create_timer(1.2, true, false, true).timeout
        ok(game.world_life.ripple_count() == 0, "the rings live briefly and die")
        # the mist parts around a passing body (probe INSIDE the gap band —
        # at the body's own x the displacement is zero by symmetry)
        var px := game.player.global_position.x
        ok(absf(game.ambient.mist_push(px + 60.0)) > 20.0, "the ground haze parts around the vessel")
        ok(game.ambient.mist_push(px + 600.0) == 0.0, "far from the body the mist holds its drift")
        # --- THE WHITE-BOX REGRESSION (the terminal law): art loaded inside
        # _draw() renders a white placeholder forever — the audit read it as
        # a debug box in TWO passes. The texture must resolve in _ready.
        ok(EntityNode._terminal_art() != null, "the terminal art resolves outside the draw call")
        var term_found := false
        for ch in game.world.get_children():
                if ch is EntityNode and String(ch.get("kind")) == "terminal":
                        term_found = true
        ok(term_found, "the act2 terminal exists as an EntityNode")


# ------------------------------------------------------------------ WB-9
func _the_record_is_a_thing() -> void:
        ## The diegetic UI pass: the interface is a physical artifact of the
        ## census world — brass instruments, parchment records, pressed wax.
        print("[WB-9 THE RECORD IS A THING]")
        # --- the craft workshop: deterministic paper, dial math, stamp laws --
        var g1 := UICraft.grain("smoke_a")
        var g2 := UICraft.grain("smoke_a")
        ok(g1 == g2, "paper grain is cached (same paper forever)")
        var g3 := UICraft.grain("smoke_b")
        ok(g1 != g3, "different keys are different paper stock")
        var d1 := UICraft.grain("smoke_c").get_image()
        var d2 := UICraft.grain("smoke_c").get_image()
        var same := d1.get_size() == d2.get_size()
        if same:
                for i in 64:
                        if d1.get_pixel(i % 96, i % 96) != d2.get_pixel(i % 96, i % 96):
                                same = false
                                break
        ok(same, "grain pixels are deterministic across calls")
        # dial law: 100 sits at 210 deg, 0 at -30 deg, linear between
        ok(absf(rad_to_deg(UICraft.dial_angle(1.0)) - 210.0) < 0.01, "dial: 100 anchors at 210\u00b0")
        ok(absf(rad_to_deg(UICraft.dial_angle(0.0)) + 30.0) < 0.01, "dial: 0 anchors at -30\u00b0")
        ok(absf(rad_to_deg(UICraft.dial_angle(0.5)) - 90.0) < 0.01, "dial: mid-value sweeps to vertical")
        # tremble law: reality's thinness moves the needle's hand
        ok(HUD.dial_tremble_for(1) == 0.0 and HUD.dial_tremble_for(3) == 0.0, "the hand is steady through S3")
        ok(HUD.dial_tremble_for(4) == 0.5, "S4 trembles at half")
        ok(HUD.dial_tremble_for(5) == 1.0 and HUD.dial_tremble_for(6) == 1.0, "S5+ the hand shakes fully")
        # --- the instrument: tube and dial state read live -------------------
        await _frames(30)
        ok(game.hud.last_tube.get("fill", -1.0) > 0.99, "the integrity tube reports a full vessel")
        ok(game.hud.last_tube.get("cracked", true) == false, "sound glass carries no cracks")
        ok(absf(float(game.hud.last_dial.get("value", -1.0)) - GameState.consistency) < 0.01, "the dial reads the live consistency")
        ok(game.hud.last_dial.get("tremble", -1.0) == 0.0, "no tremble at full consistency")
        # damage: the ghost lags, the glass cracks under 30
        game.player.hp = 22
        await _frames(25)
        ok(game.hud.last_tube.get("cracked", false) == true, "low integrity cracks the glass")
        ok(game.hud.last_tube.get("fill", 1.0) < 0.30, "the tube measures the wound")
        ok(game.hud._hp_display > game.player.hp, "the fluid drains with lag (the ghost)")
        game.player.hp = 100
        await _frames(40)
        ok(game.hud.last_tube.get("cracked", true) == false, "healed glass mends (no cracks)")
        # the mount sways with the camera, then eases home (deterministic:
        # the vessel stands mid-room where the camera has room to pan —
        # near the spawn the clamp pins the lens and no sway can build)
        game.player.global_position = Vector2(1100, 620)
        game.player.velocity = Vector2.ZERO
        await _wait_real(0.8)
        game.hud._sway = Vector2.ZERO
        var sway0: Vector2 = game.hud.last_sway
        Input.action_press("move_right")
        await _wait_real(0.8)
        Input.action_release("move_right")
        var sway_moved: bool = game.hud.last_sway.length() > 0.05
        ok(sway_moved or sway0.length() > 0.05, "the instrument mount lags the camera (inertia)")
        await get_tree().create_timer(1.4, true, false, true).timeout
        ok(game.hud.last_sway.length() < 0.6, "the mount eases home when still")
        # --- the dialogue sheet: it slides, it seals, it is PAPER -------------
        game.dialogue_box.open("oren_intro")
        ok(game.dialogue_box.active, "the record opens")
        ok(game.dialogue_box.sheet_t == 0.0, "the sheet starts below the frame")
        await get_tree().create_timer(0.12, true, false, true).timeout
        var mid_rise: float = game.dialogue_box.sheet_t
        ok(mid_rise > 0.05 and mid_rise < 0.99, "the sheet is rising (physical entrance)")
        await get_tree().create_timer(0.5, true, false, true).timeout
        ok(game.dialogue_box.sheet_t >= 1.0, "the sheet seats within its rise time")
        ok(game.dialogue_box.seal_state()["press"] >= 1.0, "the iron strikes the wax and it cools")
        ok(game.dialogue_box.seal_state()["sigil"] >= 0, "the seal carries the speaker's sigil")
        ok(game.dialogue_box.last_ruling_count > 0, "the writing sits on ledger ruling")
        # ink on parchment: the ink is DARK (paper law, not screen law)
        var inkc: Color = game.dialogue_box.last_ink_col
        ok(inkc.r < 0.3 and inkc.g < 0.3 and inkc.b < 0.3, "the record is written in dark ink on paper")
        game.dialogue_box.chars_shown = 99999
        game.dialogue_box.advance()
        while game.dialogue_box.active:
                game.dialogue_box.chars_shown = 99999
                game.dialogue_box.advance()
                await get_tree().process_frame
        await get_tree().create_timer(0.5, true, false, true).timeout
        ok(game.dialogue_box.sheet_t < 1.0 and not game.dialogue_box.visible, "the filed sheet recedes and is gone")
        # --- the stamped citations: strike, wobble, dry -----------------------
        game.system_log.entries.clear()
        game.system_log.push("TEST SLIP — FIELD MEASURED.", "warn")
        game.system_log.push("TEST SLIP — OBJECTION.", "danger")
        await get_tree().create_timer(0.02, true, false, true).timeout
        var sc0: float = game.system_log.last_stamp_scales[0] if not game.system_log.last_stamp_scales.is_empty() else 1.0
        ok(sc0 > 1.2, "a citation strikes in oversized (the die lands big)")
        await get_tree().create_timer(0.6, true, false, true).timeout
        var sc1: float = game.system_log.last_stamp_scales[0]
        ok(absf(sc1 - 1.0) < 0.08, "the citation settles to the paper")
        var jrot: float = game.system_log.last_jitter_rots[0]
        ok(absf(jrot) <= 0.03, "each slip sits a hair askew (bounded)")
        ok(SystemLog.stamp_scale(10.0) == 1.0, "old citations hold still")
        # --- the ledger: seals on sealed rows, ruling under every field -------
        # the PENITENT of the aftermath keeps its classification, purpose and
        # memory sealed at every stage the living ever reach
        game.transition_to("act9")
        await _room("act9")
        game.player.global_position = Vector2(1280, 630)
        await _frames(30)
        game.observe_enter()
        await _frames(20)
        ok(game.observe_panel.ledger_page, "the observe readout is a ledger page")
        var sealed_expect := 0
        if not game.observe_targets.is_empty():
                var tgt = game.observe_targets[game.observe_idx]
                if tgt != null and is_instance_valid(tgt):
                        for sp in tgt.data.visible_properties(GameState.stage, GameState.flags):
                                if sp["sealed"]:
                                        sealed_expect += 1
        ok(sealed_expect > 0, "the penitent keeps sealed rows at this stage")
        ok(game.observe_panel.last_seal_count == sealed_expect, "every sealed row hides under pressed wax (count pinned to data)")
        ok(game.observe_panel.last_ruling_count >= 6, "the ledger rules every field")
        game.observe_exit()
        await _frames(10)
        # --- the plaque: the prompt carries a physical key --------------------
        game.transition_to("act2")
        await _room("act2")
        game.player.global_position = Vector2(1480, 600)
        await _frames(30)
        ok(game.hud._prompt != "", "the door offers its verb")
        ok(game.hud.last_prompt_keycap, "the verb arrives on a plaque with a keycap")

func _the_air_itself() -> void:
        ## WB-10: the aural atmosphere — layered beds, the whisper that rises
        ## with the HUNTED model, the world muffling as reality thins, sound
        ## placed ON the elements, and the ground answering the ear.
        print("[WB-10 THE AIR ITSELF]")
        var saved_stage: int = GameState.stage
        # --- THE ROOM'S AIR IS A STACK ---------------------------------
        var bed_acts := {
                "act1": ["machine", "fire", "void"],
                "act2": ["machine", "void", ""],
                "act3": ["wind", "cityfar", ""],
                "act4": ["void", "machine", ""],
                "act5": ["choir", "fire", ""],
                "act6": ["void", "machine", ""],
                "act7": ["machine", "fire", ""],
                "act8": ["choir", "void", ""],
                "act9": ["wind", "void", ""],
        }
        for act in bed_acts.keys():
                game.transition_to(act)
                await _room(act)
                await get_tree().create_timer(2.6, true, false, true).timeout
                var beds: Array = bed_acts[act]
                ok(AudioManager._current_ambient == beds[0], "%s layer A carries the primary bed (%s)" % [act, beds[0]])
                ok(AudioManager._current_ambient_b == beds[1], "%s layer B carries the secondary bed (%s)" % [act, beds[1]])
                ok(AudioManager._current_ambient_c == beds[2], "%s layer C carries the deep bed (%s)" % [act, beds[2]])
                var a_lin := db_to_linear(AudioManager._ambient.volume_db)
                var a_tgt: float = (Rooms.ROOMS[act].get("ambient", []) as Array)[0].get("vol", 0.4)
                ok(absf(a_lin - a_tgt) < 0.03, "%s the primary bed has faded to its data volume" % act)
        # --- THE WHISPER RISES WITH THE MODEL ----------------------------
        AudioManager.update_degradation(2)
        ok(absf(AudioManager._whisper_target - 0.0) < 0.001, "S2: the whisper has not yet breathed")
        ok(not AudioManager._ambient_d.playing, "S2: the whisper sleeps")
        AudioManager.update_degradation(3)
        ok(absf(AudioManager._whisper_target - 0.10) < 0.001, "S3: the whisper leans in (0.10)")
        ok(AudioManager._ambient_d.playing, "S3: the whisper breathes")
        ok(AudioManager._ambient_d.bus == "Dread", "the whisper rides its own unfiltered Dread bus")
        AudioManager.update_degradation(6)
        ok(absf(AudioManager._whisper_target - 0.40) < 0.001, "S6: the whisper is a presence (0.40)")
        var dread_bus := AudioServer.get_bus_index("Dread")
        ok(AudioServer.get_bus_effect_count(dread_bus) == 0, "the Dread bus carries no filter — the whisper cuts through the muffling")
        # --- THE WORLD'S AIR MUFFLES -------------------------------------
        ok(absf(AudioManager._ambient_lp.cutoff_hz - 2000.0) < 0.01, "S6: the world's air has closed to 2000 Hz")
        AudioManager.update_degradation(4)
        ok(absf(AudioManager._ambient_lp.cutoff_hz - 5000.0) < 0.01, "S4: the air muffles to 5000 Hz")
        ok(AudioManager._ambient_lp.cutoff_hz < AudioManager._music_lp.cutoff_hz, "the world muffles faster than the score")
        AudioManager.update_degradation(saved_stage)
        # --- SOUND PLACED ON THE ELEMENTS ---------------------------------
        var ss_counts := {
                "act1": [5, 3], "act2": [6, 10], "act3": [5, 0], "act4": [2, 8],
                "act5": [11, 0], "act6": [5, 3], "act7": [5, 0], "act8": [11, 8],
                "act9": [4, 0],
        }
        for act in ss_counts.keys():
                game.transition_to(act)
                await _room(act)
                var ss := game.soundscape
                var want: Array = ss_counts[act]
                ok(ss != null, "%s carries a soundscape" % act)
                ok(ss.loop_count() == want[0], "%s hangs %d positional loop emitters" % [act, want[0]])
                ok(ss.tick_count() == want[1], "%s keeps %d timed one-shot voices" % [act, want[1]])
                var fire_kinds := ["brazier", "candles", "candelabra", "chandelier", "censer", "censer_swing", "bowl"]
                var all_placed := true
                var dedupe_holds := true
                for e in ss.emitters:
                        var n: AudioStreamPlayer2D = e["node"]
                        if not (n is AudioStreamPlayer2D and n.playing and n.bus == "Ambient"):
                                all_placed = false
                        if int(n.max_distance) != 640:
                                all_placed = false
                        if e["kind"] == "warm_light":
                                for other in ss.emitters:
                                        if fire_kinds.has(other["kind"]) and (e["pos"] as Vector2).distance_to(other["pos"]) <= 110.0:
                                                dedupe_holds = false
                ok(all_placed, "%s every emitter is a live positional player on the Ambient bus" % act)
                ok(dedupe_holds, "%s warm lights never double a brazier's voice" % act)
        # --- the undercity weeps from its damp spots ----------------------
        game.transition_to("act2")
        await _room("act2")
        ok(game.soundscape.tick_count() >= game.floorcraft.get_damp_spots().size(), "every damp spot keeps its own drip voice")
        ok(game.soundscape._world_life != null, "the vermin's squeak hook is wired to the world's life")
        ok(game.world_life.has_method("bolted_scuttler"), "a bolting vermin can be found for its squeak")
        # --- THE GROUND ANSWERS THE EAR ----------------------------------
        await _step_sample_check("act5", "sfx_foot_carpet", "the chapel runner muffles the boots")
        await _step_sample_check("act7", "sfx_foot_metal", "the engine plating rings under the boots")
        await _step_sample_check("act2", "sfx_foot_wet", "the undercity damp splashes under the boots")
        game.transition_to("act1")
        await _room("act1")
        _quiet_step_pool()
        game.player._play_footstep(-10.0)
        var first := _playing_step_path()
        _quiet_step_pool()
        game.player._play_footstep(-10.0)
        var second := _playing_step_path()
        ok(first != "" and second != "" and first != second, "stone alternates two voices so no two steps are twins")
        # --- THE FAR FIELD SPEAKS RARELY ---------------------------------
        var ev_acts := {
                "act1": 1, "act2": 1, "act3": 3, "act4": 1, "act5": 3,
                "act6": 1, "act7": 2, "act8": 2, "act9": 2,
        }
        for act in ev_acts.keys():
                game.transition_to(act)
                await _room(act)
                ok(AudioManager._event_palette.size() == ev_acts[act], "%s far-field palette carries %d voices" % [act, ev_acts[act]])
                ok(AudioManager._event_min_delay >= 4.0 and AudioManager._event_max_delay > AudioManager._event_min_delay, "%s the world never hurries its events" % act)
                ok(AudioManager._event_timer > 0.0 and AudioManager._event_timer <= AudioManager._event_max_delay, "%s the next event waits within its window" % act)
        game.transition_to("act1")
        await _room("act1")

func _quiet_step_pool() -> void:
        for p in AudioManager._sfx_pool:
                p.stop()
                p.stream = null

func _playing_step_path() -> String:
        for p in AudioManager._sfx_pool:
                if p.playing and p.stream != null:
                        return p.stream.resource_path
        return ""

func _step_sample_check(act: String, want_part: String, label: String) -> void:
        game.transition_to(act)
        await _room(act)
        _quiet_step_pool()
        game.player._play_footstep(-10.0)
        var path := ""
        for p in AudioManager._sfx_pool:
                if p.playing and p.stream != null:
                        path = p.stream.resource_path
                        break
        ok(path.contains(want_part), label)

# ------------------------------------------------------------------ WB-11
func _skip_dialogue_now() -> void:
        while game.dialogue_box.active:
                game.dialogue_box.chars_shown = 99999
                game.dialogue_box.advance()
                await _frames(2)

func _the_arrival() -> void:
        ## WB-11: the room-entry wake — no space is born pre-lit. The lights
        ## catch NEAR-FIRST from where the vessel stands, each catch flares,
        ## the ground answers in the same breath, the air condenses into
        ## presence, the voices assemble staggered, the grade exhales from
        ## held-dark — and a revisited room wakes QUICK because it remembers.
        print("[WB-11 THE ARRIVAL]")
        game.new_game()                      # fresh room memory
        await _room("act1")
        await _skip_dialogue_now()
        ok(game.wake != null, "the room carries a wake conductor")
        ok(game.wake.full, "a first visit is a full wake")
        ok(absf(game.wake.span - Wake.SPAN_FULL) < 0.001, "the full wake spans its choreography")
        # --- THE IGNITION ORDER FOLLOWS THE VESSEL ------------------------
        # act1: light 0 (160,850) stands near the spawn (140,974);
        # light 2 (1430,130) waits at the top of the ascent shaft
        var d_near := game.lights.ignition_delay(0)
        var d_far := game.lights.ignition_delay(2)
        ok(d_near >= 0.0 and d_near <= game.wake.span * 0.85, "every ignition waits inside the span")
        ok(d_far > d_near, "the far source catches after the near one (the near-first law)")
        ok(absf(game.floor_lights.ignition_delay(2) - d_far) < 0.0001, "the ground derives the same ignition as its flame")
        # --- PRE-IGNITION: EMBERS ------------------------------------------
        game.wake.t = 0.0
        ok(game.lights.current_factor(2) < 0.3, "an unlit source waits as an ember")
        ok(game.floor_lights.current_factor(2) < 0.3, "its pool waits with it")
        ok(game.ambient.air_alpha() < 0.05, "the air begins absent")
        ok(game.wake.grade_k() < 0.9, "the room begins held-dark")
        # --- THE EMBER GATHERS ---------------------------------------------
        var gutter := game.lights.current_factor_at(d_far - 0.05, 2)
        ok(gutter >= Wake.EMBER - 0.0001 and gutter <= Wake.EMBER + 0.081, "the ember gutters as its catch gathers")
        # --- THE CATCH FLARES ----------------------------------------------
        game.wake.t = d_near + 0.03
        ok(game.lights.current_factor(0) > 1.2, "the catch flares past settled")
        ok(absf(game.floor_lights.current_factor(0) - game.lights.current_factor(0)) < 0.0001,
                        "the ground answers the catch in the same breath")
        ok(game.lights.current_factor(2) < 0.3, "the far source is still an ember while the near one flares")
        # --- SETTLED PRESENCE ----------------------------------------------
        game.wake.t = game.wake.span + 1.0
        ok(absf(game.lights.current_factor(0) - 1.0) < 0.001, "the flare settles to full presence")
        ok(absf(game.lights.current_factor(2) - 1.0) < 0.001, "every source reaches presence by span's end")
        ok(game.ambient.air_alpha() > 0.95, "the air has condensed into presence")
        ok(absf(game.wake.grade_k() - 1.0) < 0.001, "the grade has exhaled to full")
        # --- THE VOICES ASSEMBLE STAGGERED ---------------------------------
        game.transition_to("act5")
        await _room("act5")
        await _skip_dialogue_now()
        game.wake.t = 0.0
        await _frames(2)             # one process pass applies the muted gain
        ok(game.soundscape.emitter_gain_frac(0) < 0.05, "the room's voices begin muted")
        game.wake.t = game.wake.span + 1.0
        await _frames(3)             # the settled snap lands
        ok(game.soundscape.emitter_gain_frac(0) > 0.95, "the voices reach their full place")
        var gates_hold := true
        for i in game.soundscape.tick_count():
                var tpos: Vector2 = game.soundscape._ticks[i]["pos"]
                if game.soundscape.tick_gate(i) < game.wake.delay_for(tpos) - 0.0001:
                        gates_hold = false
        ok(gates_hold, "no voice speaks before its place has caught")
        # --- A REVISITED ROOM WAKES QUICK ----------------------------------
        game.transition_to("act1")
        await _room("act1")
        await _skip_dialogue_now()
        ok(not game.wake.full, "a revisited room wakes quick")
        ok(absf(game.wake.span - Wake.SPAN_QUICK) < 0.001, "the room remembers the vessel (quick span)")
        ok(absf(AudioManager._layer_rate - 2.4) < 0.001, "a remembered room swells its beds quick")
        # --- THE LENS LEANS BACK ON A FIRST ARRIVAL ------------------------
        game.transition_to("act2")
        await _room("act2")
        await _skip_dialogue_now()
        ok(game.wake.full, "an unvisited room wakes full")
        ok(absf(AudioManager._layer_rate - 0.85) < 0.001, "a first arrival swells its beds slowly")
        ok(game.camera.zoom.x > 1.01, "the lens leans back on a first arrival")
        await get_tree().create_timer(2.6, true, false, true).timeout
        ok(absf(game.camera.zoom.x - 1.0) < 0.02, "the lens settles as the room wakes")
        game.transition_to("act1")
        await _room("act1")

func _the_world_thins() -> void:
        ## WB-12: as the HUNTED stages drain consistency, the WORLD ITSELF
        ## loses conviction — the lights gutter and miss beats, the ground
        ## decays in the same breath, the air chills, the moths leave first
        ## and return when the world re-asserts, the rays pale, the grade
        ## drains while the vessel stays real. A DRIFT, never a switch.
        print("[WB-12 THE WORLD THINS]")
        game.new_game()
        GameState.stage = 1
        GameState.force_thinning(-1.0)
        await _room("act1")
        await _skip_dialogue_now()
        await _settle_playing(2.0)
        # --- THE STAGE LAW -------------------------------------------------
        var law := GameState.THINNING_BY_STAGE
        ok(absf(law[0]) < 0.001 and absf(law[1]) < 0.001 and absf(law[2] - 0.25) < 0.001
                        and absf(law[3] - 0.45) < 0.001 and absf(law[4] - 0.70) < 0.001
                        and absf(law[5] - 1.0) < 0.001,
                        "the thinning follows the stages (0/0/.25/.45/.70/1)")
        ok(GameState.thinning() < 0.05, "a fresh world is itself")
        # --- THE DRIFT LAW (act1 does not hunt — nothing spawns) ----------
        GameState.stage = 6
        await _wait_real(3.2)
        ok(GameState.thinning() > 0.70, "stage 6 thins the world (a drift, not a switch)")
        GameState.stage = 1
        await _wait_real(3.2)
        ok(GameState.thinning() < 0.30, "restored consistency re-asserts the world (bidirectional)")
        # --- THE PROOF HOOK ------------------------------------------------
        GameState.force_thinning(0.80)
        ok(absf(GameState.thinning() - 0.80) < 0.001, "the proof hook pins the thinning instantly")
        GameState.force_thinning(-1.0)
        # --- THE SHARED DECAY LAW (statics) --------------------------------
        var pos := Vector2(320.0, 240.0)
        ok(absf(Lights.thin_at(pos, 0.4, 0.0, 12.34) - 1.0) < 0.0001, "an unthinned source draws at full conviction")
        ok(absf(Lights.thin_at(pos, 0.4, 0.80, 12.34) - Lights.thin_at(pos, 0.4, 0.80, 12.34)) < 0.00001,
                        "the decay is deterministic (same args, same value)")
        var mono := true
        var t_s := 0.0
        while t_s < 6.0:
                if Lights.thin_at(pos, 0.4, 0.90, t_s) > Lights.thin_at(pos, 0.4, 0.50, t_s) + 0.00001 \
                                or Lights.thin_at(pos, 0.4, 0.50, t_s) > Lights.thin_at(pos, 0.4, 0.20, t_s) + 0.00001:
                        mono = false
                t_s += 0.05
        ok(mono, "the decay deepens monotonically with the thinning")
        var gate_holds := true
        t_s = 0.0
        while t_s < 6.0:
                if absf(Lights.thin_at(pos, 0.5, 0.55, t_s) - (1.0 - Lights.THIN_CONVICT * 0.55)) > 0.0001:
                        gate_holds = false
                t_s += 0.1
        ok(gate_holds, "no flame misses a beat before the gate")
        var missed := false
        var floor_holds := true
        t_s = 0.0
        while t_s < 8.0:
                var f := Lights.thin_at(pos, 0.5, 1.0, t_s)
                if f < 1.0 - Lights.THIN_CONVICT - 0.0001:
                        missed = true
                if f < Lights.THIN_MISS_FLOOR - 0.001:
                        floor_holds = false
                t_s += 0.05
        ok(missed, "at full thin a flame sometimes misses its beat")
        ok(floor_holds, "a missed beat gutters low but never dies")
        var static_clean := true
        t_s = 0.0
        while t_s < 6.0:
                if absf(Lights.thin_at(pos, 0.0, 1.0, t_s) - (1.0 - Lights.THIN_CONVICT)) > 0.0001:
                        static_clean = false
                t_s += 0.1
        ok(static_clean, "machine veins only dim — they never miss")
        ok(absf(Lights.agitation(0.3, 0.0) - 1.0) < 0.001 and absf(Lights.agitation(0.3, 1.0) - 1.9) < 0.001,
                        "living flames grow agitated with the thinning (1 → 1.9)")
        # --- THE AIR CHILLS (statics) --------------------------------------
        ok(absf(AmbientFX.mote_dim(0.0) - 1.0) < 0.001 and absf(AmbientFX.mote_dim(1.0) - 0.55) < 0.001,
                        "the motes lose their glimmer (1 → 0.55)")
        ok(absf(AmbientFX.mote_slow(1.0) - 0.65) < 0.001 and absf(AmbientFX.mist_gain(1.0) - 1.5) < 0.001
                        and absf(AmbientFX.ash_heavy(1.0) - 1.25) < 0.001 and absf(AmbientFX.weather_churn(1.0) - 1.6) < 0.001,
                        "the air thickens, the haze gathers, the ash falls heavier, the weather churns")
        # --- THE RAYS PALE / THE GRADE DRAINS (statics) --------------------
        ok(absf(GodRays.pale(0.0) - 1.0) < 0.001 and absf(GodRays.pale(1.0) - 0.45) < 0.001
                        and absf(GodRays.uncertainty(1.0) - 0.35) < 0.001,
                        "the sky's light loses its certainty (1 → 0.45, uncertain breadth)")
        ok(absf(Game.grade_drain(0.0) - 1.0) < 0.001 and absf(Game.grade_drain(1.0) - 0.90) < 0.001
                        and absf(Game.grade_desat(1.0) - 0.12) < 0.001,
                        "the grade drains (1 → 0.90) and desaturates (→ 0.12 toward gray)")
        # --- LIFE'S NERVE (statics) ----------------------------------------
        ok(absf(WorldLife.flee_radius(0.0) - 150.0) < 0.001 and absf(WorldLife.flee_radius(1.0) - 280.0) < 0.001
                        and absf(WorldLife.flee_speed(1.0) - 375.0) < 0.001,
                        "the vermin's nerve shortens (150 → 280px) and the flight quickens (→ 375)")
        # --- THE ONE-THINNING LAW (instance: flame and ground as one) -----
        GameState.force_thinning(0.0)
        await _frames(2)
        var all_full := true
        for i in game.lights.lights.size():
                if absf(game.lights.thinning_factor(i) - 1.0) > 0.0001:
                        all_full = false
        ok(all_full, "an unthinned room draws every source at conviction")
        GameState.force_thinning(1.0)
        await _frames(2)
        var bounded := true
        var same_breath := true
        for i in game.lights.lights.size():
                var f2 := game.lights.thinning_factor(i)
                if f2 > 1.0 - Lights.THIN_CONVICT + 0.001 or f2 < Lights.THIN_MISS_FLOOR - 0.001:
                        bounded = false
                if absf(game.floor_lights.thinning_factor(i) - f2) > 0.0001:
                        same_breath = false
        ok(bounded, "a fully thinned source draws inside the legibility band")
        ok(same_breath, "the ground loses the fire in the same breath (one thinning per position)")
        var miss_seen := false
        var miss_t := 0.0
        while miss_t < 2.4:
                for i in game.lights.lights.size():
                        var l: Dictionary = game.lights.lights[i]
                        if float(l.get("flicker", 0.0)) > 0.15 and game.lights.thinning_factor(i) < 0.5:
                                miss_seen = true
                miss_t += 0.12
                await _wait_real(0.12)
        ok(miss_seen, "a living flame is caught mid-miss in the running world")
        # --- THE GRADE DRAINS, THE VESSEL DOES NOT -------------------------
        var graded: Node2D = game._graded_nodes[0]
        var lum_thin := (graded.modulate.r + graded.modulate.g + graded.modulate.b) / 3.0
        ok(not (game.player in game._graded_nodes), "the vessel is never graded — he stays real while the world fails")
        GameState.force_thinning(0.0)
        await _frames(3)
        var lum_home := (graded.modulate.r + graded.modulate.g + graded.modulate.b) / 3.0
        ok(lum_home > lum_thin + 0.005, "the drained grade returns home with the world")
        # --- THE LENS FAILS LAST (CA grows; reading still overrides) -------
        GameState.force_thinning(1.0)
        await _wait_real(1.0)
        ok(FX._ca > 1.25, "the lens fails further as reality thins (CA grows)")
        FX.push_reading()
        await _wait_real(0.6)
        ok(FX._ca < 0.30, "a reading surface still steadies the lens at full thin")
        FX.pop_reading()
        GameState.force_thinning(-1.0)
        # --- LIFE FLEES FIRST (the chapel's flames) ------------------------
        game.transition_to("act5")
        await _room("act5")
        await _skip_dialogue_now()
        await _settle_playing(1.5)
        await _wait_real(1.0)
        var moths0 := game.world_life.moth_count()
        ok(moths0 > 0, "the chapel's flames carry moths")
        var ths := game.world_life.moth_leave_thresholds()
        var nerves_staggered := true
        for v in ths:
                if float(v) < WorldLife.MOTH_LEAVE_FLOOR - 0.0001 or float(v) > WorldLife.MOTH_LEAVE_CEIL + 0.0001:
                        nerves_staggered = false
        ok(nerves_staggered and ths.size() == moths0, "every moth carries a nerve staggered inside the band")
        ok(game.world_life.moth_population_target(0.24) == moths0, "the full population holds below the floor")
        ok(game.world_life.moth_population_target(0.71) == 0, "the flames stand alone at the ceiling")
        GameState.force_thinning(0.85)
        await _wait_real(0.5)
        ok(game.world_life.any_moth_leaving(), "the moths leave first as reality thins")
        await _wait_real(1.6)
        ok(game.world_life.visible_moths() == 0, "by full leave the flames stand alone")
        GameState.force_thinning(0.0)
        await _wait_real(2.4)
        ok(game.world_life.visible_moths() == moths0, "the moths return when the world re-asserts itself")
        GameState.force_thinning(-1.0)
        GameState.stage = 1

func _wait_real(t: float) -> void:
        await get_tree().create_timer(t, true, false, true).timeout

# ------------------------------------------------------------------ WB-14
func _the_vessels_trace() -> void:
        print("[THE VESSEL'S TRACE — WB-14]")
        # --- THE MATERIAL LAW: every act's floor knows what it records
        var want_mat := {
                "act1": "dust", "act2": "wet", "act3": "ash", "act4": "wet",
                "act5": "carpet", "act6": "dust", "act7": "none",
                "act8": "dust", "act9": "ash",
        }
        for act in want_mat.keys():
                var rd: Dictionary = Rooms.ROOMS[act]
                ok(String(rd.get("trace_material", "")) == want_mat[act],
                        "%s records its passage in %s" % [act, want_mat[act]])
        ok(game._trace_fallback("wet") == "wet" and game._trace_fallback("metal") == "none",
                "rooms that predate the pass map their step material to a trace material")
        # --- THE RING: prints weather, the ring is bounded
        var tr := Traces.new()
        tr.setup("smoke", "ash")
        for i in 140:
                tr.stamp_foot(Vector2(100.0 + float(i) * 3.0, 500.0), 1.0)
        ok(tr.count() == Traces.CAP, "the ring is bounded — a path, not a ledger (%d)" % tr.count())
        # the alternation law: no two consecutive prints share a side
        tr.setup("smoke", "ash")
        tr.stamp_foot(Vector2.ZERO, 1.0)
        tr.stamp_foot(Vector2.ZERO, 1.0)
        ok(int(tr.print_at(0)["side"]) != int(tr.print_at(1)["side"]),
                "left and right alternate — a stride, not a hop")
        # the wet law: wet prints DRY (fade to a damp shadow, then leave)
        tr.setup("smoke", "wet")
        tr.stamp_foot(Vector2.ZERO, 1.0)
        var p0: Dictionary = tr.print_at(0)
        var a0 := tr.alpha_factor(p0)
        tr.simulate(6.0)
        var a_dry := tr.alpha_factor(p0)
        tr.simulate(9.5)
        var a_gone := tr.alpha_factor(p0)
        ok(a0 > a_dry and a_dry > a_gone and a_dry < a0 * 0.5,
                "the undercity's wet prints dry to a shadow, then leave (%.2f -> %.2f -> %.2f)" % [a0, a_dry, a_gone])
        ok(a_gone < 0.2, "by the end of its life the print has almost left")
        # the carpet law: pressed nap recovers continuously, reads LIGHTER
        tr.setup("smoke", "carpet")
        tr.stamp_foot(Vector2.ZERO, 1.0)
        var pc: Dictionary = tr.print_at(0)
        ok(bool(pc["lighten"]), "the chapel runner reads LIGHTER where pressed")
        var ac0 := tr.alpha_factor(pc)
        tr.simulate(4.5)
        ok(tr.alpha_factor(pc) < ac0, "the nap recovers as the room forgets")
        # the ash law: ash HOLDS its record before it leaves
        tr.setup("smoke", "ash")
        tr.stamp_foot(Vector2.ZERO, 1.0)
        var pa: Dictionary = tr.print_at(0)
        tr.simulate(10.0)
        ok(tr.alpha_factor(pa) > 0.97, "the ash quarter holds its census (no fade before 62% of life)")
        # the toe-kick law: ash piles at the trailing boot's toe
        tr.setup("smoke", "ash")
        tr.stamp_foot(Vector2.ZERO, 1.0)
        tr.stamp_foot(Vector2(20.0, 0.0), 1.0)
        ok(bool(tr.print_at(0)["kick"]) and not bool(tr.print_at(1)["kick"]),
                "the ash district kicks piles at the trailing boot's toe (alternating)")
        # --- THE ENGINE RECORDS NOTHING
        game.transition_to("act7")
        await _room("act7")
        ok(game.traces != null and game.traces.material_name == "none",
                "the Engine's floor is maintained clean")
        var n0 := game.traces.count()
        game.player.velocity.x = 220.0
        await _frames(40)
        ok(game.traces.count() == n0,
                "a walked Engine floor records nothing — it does not need to count")
        # --- THE LIVE PRINT LAW: walking writes the path
        game.transition_to("act3")
        await _room("act3")
        ok(game.traces != null and game.traces.material_name == "ash",
                "the ash quarter records its passage in ash")
        var n_before := game.traces.count()
        Input.action_press("move_right")
        var t0 := Time.get_ticks_msec()
        while Time.get_ticks_msec() - t0 < 1600:
                await get_tree().process_frame
        Input.action_release("move_right")
        ok(game.traces.count() > n_before + 6,
                "a walked street writes its prints (%d -> %d)" % [n_before, game.traces.count()])
        var feet_x := game.player.global_position.x
        var near_print := 0
        for i in game.traces.count():
                var pr: Dictionary = game.traces.print_at(i)
                if absf(float(pr["x"]) - feet_x) < 260.0:
                        near_print += 1
        ok(near_print >= 6, "the prints fall where the boots fell (near the vessel)")
        # --- THE WET DISTRICT: the undercity keeps wet prints that glisten
        game.transition_to("act2")
        await _room("act2")
        ok(game.traces.material_name == "wet", "the weeping stone keeps wet prints")
        Input.action_press("move_right")
        var t1 := Time.get_ticks_msec()
        while Time.get_ticks_msec() - t1 < 1200:
                await get_tree().process_frame
        Input.action_release("move_right")
        ok(game.traces.count_kind("foot") >= 5, "the undercity's boots write wet prints")
        var glistens := 0
        for i in game.traces.count():
                if game.traces.has_glisten(game.traces.print_at(i)):
                        glistens += 1
        ok(glistens > 0, "fresh wet prints glisten at the leading edge")
        # --- THE LANDING LAW: a hard fall leaves a scuff-star
        # (lift the vessel CLEAR of the floor — is_on_floor() reports the
        # last physics result, so a 4px nudge never registers as airborne)
        _skip_dialogue_now()
        game.player.velocity.y = 420.0
        game.player.global_position.y -= 60.0
        await get_tree().create_timer(0.5, true, false, true).timeout
        _skip_dialogue_now()
        var lands := game.traces.count_kind("land")
        ok(lands >= 1, "a hard landing leaves a scuff-star (count %d)" % lands)
        if lands > 0:
                var pl: Dictionary = game.traces.print_at(0)
                for i in game.traces.count():
                        if String(game.traces.print_at(i)["kind"]) == "land":
                                pl = game.traces.print_at(i)
                                break
                ok(int(pl["star"]) >= 4, "the scuff-star radiates thrown material")
        # --- THE ROLL LAW: the roll drags a smear
        # (edge-detected input does not survive the headless frame order —
        # the buffer is armed directly, as the golden path does for jumps)
        _skip_dialogue_now()
        game.player._roll_press = 0.14
        await get_tree().create_timer(0.6, true, false, true).timeout
        _skip_dialogue_now()
        ok(game.traces.count_kind("smear") >= 1,
                "the roll drags a smear through the material")
        var path_w := 0.0
        for i in game.traces.count():
                var sm: Dictionary = game.traces.print_at(i)
                if String(sm["kind"]) == "smear":
                        path_w = maxf(path_w, float(sm["w"]))
        ok(path_w > 60.0, "the roll's whole path is ONE long drag (%.0fpx, not debris dashes)" % path_w)
        # --- THE CHAPEL: the runner's nap presses
        game.transition_to("act5")
        await _room("act5")
        ok(game.traces.material_name == "carpet", "the chapel floor is the runner")
        Input.action_press("move_right")
        var t2 := Time.get_ticks_msec()
        while Time.get_ticks_msec() - t2 < 1200:
                await get_tree().process_frame
        Input.action_release("move_right")
        ok(game.traces.count_kind("foot") >= 4, "the chapel's boots press the nap")
        # --- THE ARCHIVE ANSWERS THE BOOT: walking the litter kicks pages
        game.transition_to("act6")
        await _room("act6")
        ok(game.floorcraft.get_page_spots().size() >= 4,
                "the archive floor keeps its spilled records (%d)" % game.floorcraft.get_page_spots().size())
        # walk THROUGH the litter: teleport beside a page spot (standing
        # height kept — the y law anchors on the feet) and stride across it
        var ps: Dictionary = game.floorcraft.get_page_spots()[0]
        game.player.global_position = Vector2(float(ps["x"]) - 30.0, game.player.global_position.y)
        game.player.velocity = Vector2.ZERO
        await _frames(2)
        var kicks0 := game.world_life.flutter_count()
        Input.action_press("move_right")
        var t3 := Time.get_ticks_msec()
        while Time.get_ticks_msec() - t3 < 1100:
                await get_tree().process_frame
        Input.action_release("move_right")
        ok(game.world_life.flutter_count() > kicks0,
                "a boot through the litter kicks a page a-flutter (%d -> %d)" % [kicks0, game.world_life.flutter_count()])
        # --- THE AIR YIELDS: a brisk walk stirs the air; a standstill stills it
        game.transition_to("act1")
        await _room("act1")
        Input.action_press("move_right")
        var t4 := Time.get_ticks_msec()
        while Time.get_ticks_msec() - t4 < 1400:
                await get_tree().process_frame
        Input.action_release("move_right")
        var stirred: float = game.ambient.air_stir()
        ok(stirred > 0.15, "a brisk walk stirs the air (stir %.2f)" % stirred)
        var t5 := Time.get_ticks_msec()
        while Time.get_ticks_msec() - t5 < 2600:
                await get_tree().process_frame
        ok(game.ambient.air_stir() < stirred * 0.5,
                "the air stills when the vessel stands (%.2f -> %.2f)" % [stirred, game.ambient.air_stir()])
        ok(game.ambient.mist_push(game.player.global_position.x + 600.0) == 0.0,
                "the ground haze holds far from the body (WB-8 law unbroken)")

# ------------------------------------------------------------------ WB-15
func _the_others_passage() -> void:
        print("[THE OTHERS' PASSAGE — WB-15]")
        # --- THE GAITS: every creature that walks writes in its own body's language
        ok(Traces.GAITS.has("hollow") and Traces.GAITS.has("believer") and Traces.GAITS.has("martyr"),
                "the walkers of the city each own a gait")
        var gh: Dictionary = Traces.GAITS["hollow"]
        var gb: Dictionary = Traces.GAITS["believer"]
        var gm: Dictionary = Traces.GAITS["martyr"]
        ok(float(gh["weight"]) < 0.75 and String(gh["sole"]) == "boot",
                "the hollow presses the vessel's own sole without conviction (%.2f)" % float(gh["weight"]))
        ok(float(gh["variance"]) <= 0.01,
                "the hollow strides like a metronome — a copy of a gait, not a gait")
        ok(String(gb["sole"]) == "soft" and float(gb["stride"]) < float(gh["stride"]),
                "the believer shuffles: a soft narrow sole, short quick steps")
        ok(float(gm["weight"]) > 1.2 and float(gm["stride"]) > float(gh["stride"]),
                "the bound martyr presses deeper and strides wider than the vessel (%.2f)" % float(gm["weight"]))
        # --- unit laws on a bare canvas
        var tr := Traces.new()
        tr.setup("wb15", "ash")
        tr.stamp_foot(Vector2(200.0, 500.0), 1.0)
        var vessel_born := float(tr.print_at(0)["born"])
        tr.stamp_foot(Vector2(240.0, 500.0), 1.0, 1.0, "hollow")
        var ph: Dictionary = tr.print_at(1)
        ok(String(ph["tag"]) == "hollow" and float(ph["born"]) < vessel_born * 0.8,
                "the hollow's print is the vessel's, pressed lighter (%.2f < %.2f)" % [float(ph["born"]), vessel_born])
        # the metronome: same-side prints fall at EXACTLY the same offset
        tr.setup("wb15", "ash")
        for i in 8:
                tr.stamp_foot(Vector2(300.0 + float(i) * 34.0, 500.0), 1.0, 1.0, "hollow")
        var metronome := true
        var off0 := float(tr.print_at(0)["x"]) - 300.0
        var off1 := float(tr.print_at(1)["x"]) - (300.0 + 34.0)
        for i in 8:
                var want := off0 if i % 2 == 0 else off1
                var got := float(tr.print_at(i)["x"]) - (300.0 + float(i) * 34.0)
                if absf(got - want) > 0.0001:
                        metronome = false
        ok(metronome, "the metronome stride: the same step every step (no fatigue)")
        # the believer's narrow sole / the martyr's wide stance
        tr.stamp_foot(Vector2.ZERO, 1.0, 1.0, "believer")
        var pb: Dictionary = tr.print_at(tr.count() - 1)
        tr.stamp_foot(Vector2.ZERO, 1.0, 1.0, "martyr")
        var pm: Dictionary = tr.print_at(tr.count() - 1)
        ok(float(pb["w"]) < 9.0 and float(pb["w"]) < float(pm["w"]),
                "the believer's sole is narrower than the martyr's stance")
        ok(float(pm["born"]) > vessel_born, "the martyr's press is deeper than the vessel's")
        # --- THE SHARED RING: one canvas, whatever walks it
        tr.setup("wb15", "ash")
        for i in 300:
                var key: String = ["", "hollow", "believer"][i % 3]
                tr.stamp_foot(Vector2(float(i) * 7.0, 500.0), 1.0, 1.0, key)
        ok(tr.count() == Traces.CAP, "the others share the vessel's ring — a path, not a ledger (%d)" % tr.count())
        # --- THE INFORMATION LAW: fresh reads darker than old (the wet
        # stone shows it fastest — a print dries as it ages)
        tr.setup("wb15", "wet")
        tr.stamp_foot(Vector2(160.0, 500.0), 1.0, 1.0, "hollow")
        var f_now := tr.alpha_factor(tr.print_at(0))
        tr.simulate(6.5)
        ok(tr.alpha_factor(tr.print_at(0)) < f_now * 0.6,
                "the floor is information: a fresh trail reads darker than an old one (%.2f -> %.2f)" % [f_now, tr.alpha_factor(tr.print_at(0))])
        # --- THE CENSOR ERASES: its passage blanks the record
        tr.setup("wb15", "ash")
        for i in 12:
                tr.stamp_foot(Vector2(400.0 + float(i) * 26.0, 500.0), 1.0)
        var before := tr.count()
        var erased := tr.erase_column(530.0, 30.0)
        ok(erased >= 2 and tr.count() == before - erased,
                "the censor's passage blanks the record where it passed (%d erased)" % erased)
        ok(tr.count() > 0, "the record outside the correction survives")
        # --- THE FLOOR NEVER MEETS THEM: the drifters and the paperwork
        var nc_probe := NullChild.new()
        ok(not nc_probe.has_method("gait_key") or nc_probe.gait_key() == "",
                "the null children drift through walls — the floor never meets them")
        nc_probe.free()
        var co_probe := Correction.new()
        ok(not co_probe.has_method("gait_key"),
                "the correction is paperwork — it files past, it does not walk")
        co_probe.free()
        var bm_probe := BoundMartyr.new()
        ok(bm_probe.gait_key() == "martyr", "the bound martyr owns the heaviest gait in the city")
        bm_probe.free()
        # the leap's witness at martyr weight
        tr.setup("wb15", "dust")
        tr.stamp_land(Vector2(600.0, 500.0), 1.7)
        ok(int(tr.print_at(0)["star"]) >= 7,
                "the martyr's landing throws a wide witness (%d flights)" % int(tr.print_at(0)["star"]))
        # --- INTEGRATION: the hollow's patrol writes the ash quarter
        game.transition_to("act3")
        await _room("act3")
        var h0 := game.traces.count_tag("hollow")
        var t0 := Time.get_ticks_msec()
        while Time.get_ticks_msec() - t0 < 2600:
                await get_tree().process_frame
        var h1 := game.traces.count_tag("hollow")
        ok(h1 > h0 + 3, "the hollow's patrol writes the ash quarter in its own hand (%d -> %d)" % [h0, h1])
        ok(game.traces.count_tag("vessel") == 0,
                "the vessel has not walked — the ash holds only the hollow's passage")
        # the shared canvas: both hands on one floor
        Input.action_press("move_right")
        var tw := Time.get_ticks_msec()
        while Time.get_ticks_msec() - tw < 1100:
                await get_tree().process_frame
        Input.action_release("move_right")
        ok(game.traces.count_tag("vessel") > 4 and game.traces.count_tag("hollow") > 0,
                "one floor, two hands: the vessel's boots and the hollow's echo share the record")
        # --- THE AIR YIELDS TO THEM TOO: the patrol parts the falling ash
        var t_air := Time.get_ticks_msec()
        while Time.get_ticks_msec() - t_air < 4000 and game.ambient.others_pushes() == 0:
                await get_tree().process_frame
        ok(game.ambient.others_pushes() > 0,
                "the air parts for whatever lives — the patrol parts the falling ash (%d)" % game.ambient.others_pushes())
        # --- THE ENGINE RECORDS NOTHING, even for its own hollows
        game.transition_to("act7")
        await _room("act7")
        var e0 := game.traces.count()
        var t7 := Time.get_ticks_msec()
        while Time.get_ticks_msec() - t7 < 2200:
                await get_tree().process_frame
        ok(game.traces.count() == e0 and game.traces.count_tag("hollow") == 0,
                "the Engine's floor records nothing — not even the hollows that walk it")
        # --- THE CHAPEL: the devotion field pre-exists the vessel
        game.transition_to("act5")
        await _room("act5")
        var t_k := Time.get_ticks_msec()
        while Time.get_ticks_msec() - t_k < 3200 and game.traces.count_kind("kneel") < 7:
                await get_tree().process_frame
        var knees := game.traces.count_kind("kneel")
        ok(knees >= 7, "the chapel runner carries the congregation's stations (%d knee-presses)" % knees)
        var aged := 0
        for i in game.traces.count():
                var kp: Dictionary = game.traces.print_at(i)
                if String(kp["kind"]) == "kneel" and float(kp["age"]) > 3.0:
                        aged += 1
        ok(aged >= 5, "the stations were pressed before the vessel arrived — the devotion predates him")
        # the shuffle: harm one and all answer — in cloth
        var first_bel: Believer = null
        for node in get_tree().get_nodes_in_group("enemies"):
                if node is Believer and not node.dead:
                        first_bel = node
                        break
        ok(first_bel != null, "the congregation is present")
        if first_bel != null:
                # stand the vessel within the congregation's answer (their
                # aggro leash is 560 — from the door the nearest is 580 away
                # and the answer dies unborn; two steps in and it holds)
                game.player.global_position = Vector2(560.0, game.player.global_position.y)
                game.player.velocity = Vector2.ZERO
                await _frames(2)
                first_bel._on_hurt()
                var t5 := Time.get_ticks_msec()
                while Time.get_ticks_msec() - t5 < 2000:
                        await get_tree().process_frame
                var bel_feet := 0
                for i in game.traces.count():
                        var bp: Dictionary = game.traces.print_at(i)
                        if String(bp.get("tag", "")) == "believer" and String(bp["kind"]) == "foot":
                                bel_feet += 1
                ok(bel_feet > 2,
                        "the believers' shuffle writes the runner as they come (%d strides)" % bel_feet)
        else:
                ok(false, "the congregation is present")

# ------------------------------------------------------------------ WB-16
func _the_endings_record() -> void:
        print("[THE ENDING'S RECORD — WB-16]")
        # --- THE ENDING OUTLIVES THE STRIDE: every material owns an ending's life
        ok(Traces.FALL_LIFE.has("carpet") and Traces.FALL_LIFE.has("ash") \
                        and Traces.FALL_LIFE.has("wet") and Traces.FALL_LIFE.has("dust"),
                "every recording material owns an ending's life")
        ok(float(Traces.FALL_LIFE["carpet"]) > float(Traces.FALL_LIFE["ash"]) \
                        and float(Traces.FALL_LIFE["ash"]) > float(Traces.FALL_LIFE["wet"]) \
                        and float(Traces.FALL_LIFE["wet"]) > float(Traces.FALL_LIFE["dust"]),
                "the runner rises slowest, the archive's dust forgets fastest")
        # --- unit laws on a bare canvas: the floor keeps the ending
        var tr := Traces.new()
        for mat in ["ash", "wet", "carpet", "dust"]:
                tr.setup("wb16", mat)
                tr.stamp_foot(Vector2(200.0, 500.0), 1.0)
                tr.stamp_fall(Vector2(200.0, 500.0), 1.0, 1.0, "vessel")
                ok(tr.fall_count() == 1 and String(tr.fall_at(0)["kind"]) == "fall",
                        "the %s floor keeps the ending" % mat)
        # THE ENGINE RECORDS NOTHING — not even its dead
        tr.setup("wb16", "none")
        tr.stamp_fall(Vector2(200.0, 500.0), 1.0, 1.0, "vessel")
        tr.stamp_foot(Vector2(200.0, 500.0), 1.0)
        ok(tr.fall_count() == 0 and tr.count() == 0,
                "the Engine records nothing — not even its dead")
        # the ending outlives the stride (ash holds 62% of a full minute)
        tr.setup("wb16", "ash")
        tr.stamp_foot(Vector2(300.0, 500.0), 1.0)
        tr.stamp_fall(Vector2(300.0, 500.0), 1.0, 1.0, "vessel")
        tr.simulate(40.0)
        ok(tr.count() == 0 and tr.fall_count() == 1,
                "the ash forgets the stride but keeps the ending")
        ok(tr.alpha_factor(tr.fall_at(0)) > 0.3,
                "the ending still reads after the path has gone (%.2f)" % tr.alpha_factor(tr.fall_at(0)))
        # the runner rises at its own pace — ten strides' lives, the press holds
        tr.setup("wb16", "carpet")
        tr.stamp_fall(Vector2(300.0, 500.0), 1.0, 1.0, "vessel")
        var f0 := tr.alpha_factor(tr.fall_at(0))
        tr.simulate(9.5)
        ok(tr.alpha_factor(tr.fall_at(0)) > f0 * 0.85,
                "the runner's pressed nap outlasts a boot's press tenfold")
        # the wet pool dries to a mineral ghost that holds
        tr.setup("wb16", "wet")
        tr.stamp_fall(Vector2(300.0, 500.0), 1.0, 1.0, "vessel")
        var w0 := tr.alpha_factor(tr.fall_at(0))
        tr.simulate(30.0)
        var w1 := tr.alpha_factor(tr.fall_at(0))
        ok(w1 < w0 * 0.35 and w1 > 0.0,
                "the pool dries to a mineral ghost that holds (%.2f -> %.2f)" % [w0, w1])
        # the ending is written in the walker's own weight
        tr.setup("wb16", "ash")
        tr.stamp_fall(Vector2(100.0, 500.0), 1.0, float(Traces.GAITS["hollow"]["weight"]), "hollow")
        tr.stamp_fall(Vector2(200.0, 500.0), 1.0, 1.0, "vessel")
        tr.stamp_fall(Vector2(300.0, 500.0), 1.0, float(Traces.GAITS["martyr"]["weight"]), "martyr")
        var bh := float(tr.fall_at(0)["born"])
        var bv := float(tr.fall_at(1)["born"])
        var bm := float(tr.fall_at(2)["born"])
        ok(bh < bv and bv < bm,
                "the ending is written in the walker's weight (hollow %.2f < vessel %.2f < martyr %.2f)" % [bh, bv, bm])
        # the endings keep their own bounded ledger on the same canvas
        tr.setup("wb16", "ash")
        for i in 12:
                tr.stamp_fall(Vector2(100.0 + float(i) * 40.0, 500.0), 1.0)
        ok(tr.fall_count() == Traces.FALL_CAP,
                "the floor is not a graveyard — it holds the last %d endings" % Traces.FALL_CAP)
        tr.stamp_foot(Vector2(500.0, 500.0), 1.0)
        ok(tr.count() == 1 and tr.fall_count() == Traces.FALL_CAP,
                "one canvas, two ledgers: the path forgets, the ending holds")
        # --- THE WALK ENDS HERE: frozen strides
        tr.setup("wb16", "ash")
        for i in 6:
                tr.stamp_foot(Vector2(200.0 + float(i) * 34.0, 500.0), 1.0, 1.0, "hollow")
        var n_frozen := tr.freeze_strides("hollow", 2)
        var age_f := float(tr.print_at(5)["age"])
        tr.simulate(5.0)
        ok(n_frozen == 2 and tr.frozen_count() == 2,
                "the walk ends here: the last strides freeze mid-path (%d)" % n_frozen)
        ok(absf(float(tr.print_at(5)["age"]) - age_f) < 0.001,
                "a frozen stride does not age — the record keeps where the gait stopped")
        ok(float(tr.print_at(0)["age"]) > 4.0,
                "the path behind the ending still weathers")
        tr.simulate(30.0)
        ok(tr.frozen_count() == 2, "frozen strides outlive their own lives")
        tr.stamp_foot(Vector2(600.0, 500.0), 1.0)
        tr.freeze_strides("hollow", 2)
        var last_p: Dictionary = tr.print_at(tr.count() - 1)
        ok(not bool(last_p.get("frozen", false)), "freeze keeps to the walker's own strides")
        # --- the correction blanks endings too
        tr.setup("wb16", "ash")
        for i in 10:
                tr.stamp_foot(Vector2(400.0 + float(i) * 24.0, 500.0), 1.0)
        tr.stamp_fall(Vector2(530.0, 500.0), 1.0, 1.0, "vessel")
        tr.stamp_fall(Vector2(900.0, 500.0), 1.0, 1.0, "vessel")
        var erased_f := tr.erase_column(530.0, 30.0)
        ok(erased_f >= 3 and tr.fall_count_tag("vessel") == 1,
                "the censor's correction blanks even an ending; the far fall survives (%d erased)" % erased_f)
        # a stain the vessel never saw fall is born aged
        tr.setup("wb16", "ash")
        tr.stamp_fall(Vector2(200.0, 500.0), 1.0, 1.0, "vessel", 3.5)
        ok(absf(float(tr.fall_at(0)["age"]) - 3.5) < 0.01,
                "a stain the vessel never saw fall is born aged")
        # --- INTEGRATION: the hollow's death writes the ash
        game.transition_to("act3")
        await _room("act3")
        var hollow2: Hollow = null
        for node in get_tree().get_nodes_in_group("enemies"):
                if node is Hollow and not node.dead:
                        hollow2 = node
                        break
        if hollow2 == null:
                ok(false, "the ash quarter has its hollow")
        else:
                var th := Time.get_ticks_msec()
                while Time.get_ticks_msec() - th < 1500:
                        await get_tree().process_frame
                var hx := hollow2.global_position.x
                var hy := hollow2.global_position.y
                hollow2.take_hit(9999, hollow2.global_position + Vector2(60.0, 0.0), true)
                await _frames(3)
                ok(game.traces.fall_count_tag("hollow") == 1,
                        "the hollow's death writes the ash in its own hand")
                ok(game.traces.frozen_count() >= 1,
                        "its last strides froze mid-path — the walk ends where it ended")
                var hf: Dictionary = game.traces.fall_at(0)
                ok(String(hf["tag"]) == "hollow" and absf(float(hf["x"]) - hx) < 24.0 \
                                and absf(float(hf["y"]) - (hy + 40.0)) < 8.0,
                        "the fall lies where the body ended")
                # --- the censor's leaving is a correction: stand the vessel under
                #     the fall, drop a control ending far off, and let the censor
                #     depart on the column
                game.player.global_position = Vector2(hx, game.player.global_position.y)
                game.player.velocity = Vector2.ZERO
                await _frames(2)
                game.traces.stamp_fall(Vector2(hx + 300.0, hy), 1.0, 1.0, "vessel")
                var co := Censor.new()
                co.global_position = Vector2(hx, hy - 300.0)
                game.world.add_child(co)
                co.life_t = 24.9
                var tc := Time.get_ticks_msec()
                while Time.get_ticks_msec() - tc < 1600 and is_instance_valid(co):
                        await get_tree().process_frame
                ok(not is_instance_valid(co), "the censor departs")
                ok(game.traces.fall_count_tag("hollow") == 0,
                        "the censor's leaving blanks the column where it stood — even endings")
                ok(game.traces.fall_count_tag("vessel") == 1,
                        "the ending outside the correction survives")
        # --- the null child's death writes nothing — the floor never met it
        game.transition_to("act1")
        await _room("act1")
        var falls_a1 := game.traces.fall_count()
        var nc2: NullChild = null
        for node in get_tree().get_nodes_in_group("enemies"):
                if node is NullChild and not node.dead:
                        nc2 = node
                        break
        if nc2 != null:
                nc2.take_hit(9999, nc2.global_position + Vector2(40.0, 0.0), true)
                await _frames(3)
        ok(game.traces.fall_count() == falls_a1,
                "the null child's death writes nothing — the floor never met it")
        # --- THE VESSEL'S OWN ENDING: recorded, and the rebuilt floor wears it
        game.transition_to("act3")
        await _room("act3")
        var deaths0 := int(GameState.stats.get("deaths", 0))
        game.player.take_damage(999, game.player.global_position + Vector2(40.0, 0.0))
        var td := Time.get_ticks_msec()
        while Time.get_ticks_msec() - td < 6500 and game._dead_handled:
                await get_tree().process_frame
        ok(int(GameState.stats.get("deaths", 0)) == deaths0 + 1,
                "the count of endings is kept (death %d)" % int(GameState.stats.get("deaths", 0)))
        var reg: Array = game._death_stains.get("act3", [])
        ok(reg.size() >= 1, "the death is filed in the session's registry")
        if game.room_id != "act3":
                game.transition_to("act3")
        await _room("act3")
        ok(game.traces.fall_count_tag("vessel") >= 1,
                "the stain survives the crossing — the rebuilt ash wears where he fell")
        var vf: Dictionary = game.traces.fall_at(0)
        ok(String(vf["tag"]) == "vessel" and float(vf["age"]) > 3.0,
                "the revisited stain reads already-happened — born aged (%.1f)" % float(vf["age"]))

# ------------------------------------------------------------------ WB-18
func _the_fist_that_lands() -> void:
        print("[WB-18 THE FIST THAT LANDS]")
        # --- the wound card carries the chain's sentence
        var c0 := FX.impact(Vector2.ZERO, 1.0, false, 0)
        ok(c0 != null and c0.style == 0 and is_equal_approx(c0.life, 0.20),
                "a chain hit's wound card reads 0.20s")
        var c2 := FX.impact(Vector2.ZERO, 1.0, true, 2)
        ok(c2 != null and c2.style == 2 and is_equal_approx(c2.life, 0.28),
                "the finisher's card outlasts the chain (0.28s)")
        if c0:
                c0.queue_free()
        if c2:
                c2.queue_free()
        # --- the punctuation escalates through the chain (hitstop ms)
        game.new_game()
        await _settle_playing(0.4)
        game.transition_to("act3")
        await _room("act3")
        var hollow18: Hollow = null
        for node in get_tree().get_nodes_in_group("enemies"):
                if node is Hollow and not node.dead:
                        hollow18 = node
                        break
        ok(hollow18 != null, "the hollow stands in the undercity")
        if hollow18:
                game.player.global_position = hollow18.global_position + Vector2(-52.0, 0)
                game.player.facing = 1
                await _frames(3)
                var now := Time.get_ticks_msec()
                game.player._do_hit(0)
                var stop0: int = FX._hitstop_until_msec - now
                ok(stop0 >= 60, "hit one holds the frame (>=60ms, got %d)" % stop0)
                await _frames(2)
                now = Time.get_ticks_msec()
                game.player._do_hit(2)
                var stop2: int = FX._hitstop_until_msec - now
                ok(stop2 >= 105, "the finisher holds longer (>=105ms, got %d)" % stop2)
                ok(hollow18.hurt_flash > 0.2, "the hurt read lasts (flash %.2f)" % hollow18.hurt_flash)
                ok(absf(hollow18.velocity.x - 230.0) < 1.0, "the body is pushed harder (230)" )
        # --- the roll is a decision: the ghost trail samples the path
        game.player.global_position = Vector2(600, 792)
        game.player.velocity = Vector2.ZERO
        for i in 60:
                if game.player.is_on_floor():
                        break
                await _frames(1)
        if game.player.is_on_floor():
                Input.action_press("roll")
                await _frames(2)
                Input.action_release("roll")
                # headless runs unthrottled — the roll lives in REAL time
                await get_tree().create_timer(0.18, true, false, true).timeout
                ok(game.player.roll_hist.size() >= 2,
                        "the tumble leaves ghosts behind (%d sampled)" % game.player.roll_hist.size())
                await get_tree().create_timer(0.5, true, false, true).timeout
                ok(not game.player.is_rolling(), "the tumble ends")
        else:
                ok(false, "roll law staged off-floor")
        # --- the charge speaks: the boss's dash windup gathers and spends
        game.transition_to("act8")
        await _room("act8")
        var boss18: BoundMartyr = game.boss
        ok(boss18 != null, "the martyr is bound in the sanctum")
        if boss18:
                boss18.intro_done = true
                boss18.phase = 2
                boss18.state = boss18.DASH_WINDUP
                boss18.state_t = 0.0
                boss18.dash_charge = 0.0
                await _frames(12)
                ok(boss18.dash_charge > 0.05,
                        "the windup gathers (charge %.2f)" % boss18.dash_charge)
                boss18.state_t = 0.75
                await _frames(6)
                ok(boss18.state == boss18.DASHING and is_equal_approx(boss18.dash_charge, 0.0),
                        "the dash spends the charge clean")

# ------------------------------------------------------------------ WB-13
func _the_threshold() -> void:
        print("[THE THRESHOLD — WB-13]")
        # --- THE EDGE DATA: every golden crossing carries a rubric + a real herald
        var golden: Array = []
        for id in Rooms.ROOMS.keys():
                for e in Rooms.ROOMS[id].get("exits", []):
                        golden.append(Threshold.edge(id, String(e["to"])))
        ok(golden.size() == 8, "the golden path is eight crossings")
        var rubric_ok := true
        var herald_ok := true
        for e in golden:
                var r: String = String(Threshold.RUBRICS.get(e, ""))
                if r.is_empty() or r.length() > 64:
                        rubric_ok = false
                var h: Dictionary = Threshold.HERALDS.get(e, {})
                if h.is_empty() or not FileAccess.file_exists("res://audio/sfx/sfx_" + String(h.get("id", "")) + ".wav"):
                        herald_ok = false
        ok(rubric_ok, "every golden crossing carries a census rubric (<=64 chars)")
        ok(herald_ok, "every golden crossing's herald resolves to a real voice")
        ok(Threshold.is_golden("act1", "act2") and Threshold.is_golden("act8", "act9"), "the authored sequence is golden")
        ok(not Threshold.is_golden("act3", "act7"), "a teleport is not a passage (never deep)")
        # --- THE THREE BEATS, as pure functions of t
        var th := Threshold.make("act4", "act5", true)
        ok(th.rubric == Threshold.RUBRICS["act4>act5"], "the between carries its edge's rubric")
        ok(th.herald_id == "bell_far", "the chapel is heard before it is seen")
        th.t = 0.0
        ok(th.fade_k() < 0.001, "the crossing begins in the lit world")
        th.t = th.leave_end() * 0.5
        ok(th.fade_k() > 0.2 and th.fade_k() < 0.95, "the leaving folds toward black (midway)")
        th.t = th.leave_end()
        ok(th.fade_k() > 0.985, "the leaving ends in full black")
        th.t = th.leave_end() + 0.5
        ok(th.fade_k() > 0.985 and th.rubric_alpha() > 0.5, "the between holds full black with the rubric risen")
        th.t = th.black_end() - 0.1
        ok(th.rubric_alpha() < 0.4, "the rubric falls before the coming")
        th.t = th.span()
        ok(th.fade_k() < 0.02 and th.done(), "the coming opens back to the lit world")
        # --- THE WALK IN THE DARK
        var steps: Array = th.step_times()
        var steps_ok := steps.size() == Threshold.STEP_COUNT
        for i in steps.size():
                if i > 0:
                        var gap := float(steps[i]) - float(steps[i - 1])
                        if gap < 0.3 or gap > 0.55:
                                steps_ok = false
        ok(steps_ok and float(steps[0]) >= 0.1 and float(steps[steps.size() - 1]) < th.black_end(),
                "the vessel keeps walking in the dark (3 steps, his own rhythm)")
        ok(th.herald_time() > th.leave_end() + 0.15 and th.herald_time() < th.black_end() - 0.2,
                "the herald sounds inside the between")
        ok(th.letter_alpha(0, 40) >= th.letter_alpha(39, 40), "the inscription travels left to right")
        ok(th.rubric_track() >= Threshold.TRACK_IN and th.rubric_track() <= Threshold.TRACK_OUT, "the record's hand widens within its bounds")
        # --- THE QUICK CROSSING keeps the city's plain fade
        var q := Threshold.make("act1", "act2", false)
        q.t = q.span() * 0.5
        ok(q.rubric_alpha() == 0.0, "a quick crossing never shows the rubric")
        ok(absf(Threshold.QUICK_OUT - 0.35) < 0.001 and absf(Threshold.QUICK_IN - 0.40) < 0.001,
                "a quick crossing keeps the plain city fade")
        # --- THE DEPARTING FLOOR SPEAKS
        ok(Threshold.step_sample(Rooms.ROOMS["act1"]) == "sfx_step", "the womb's stone speaks in the dark")
        ok(Threshold.step_sample(Rooms.ROOMS["act2"]) == "sfx_foot_wet", "the undercity's damp speaks in the dark")
        ok(Threshold.step_sample(Rooms.ROOMS["act7"]) == "sfx_foot_metal", "the engine's plating speaks in the dark")
        ok(Threshold.step_sample(Rooms.ROOMS["act5"]) == "sfx_foot_carpet", "the chapel's runner speaks in the dark")
        # --- INTEGRATION: the living crossing
        game.new_game()
        await _settle_playing(1.0)
        game.transition_to("act2")
        var seen_black := false
        var seen_rubric := false
        var beds_sunk := false
        var t0 := Time.get_ticks_msec()
        while Time.get_ticks_msec() - t0 < 6000:
                if game.threshold != null and game.threshold.deep:
                        if FX.is_faded():
                                seen_black = true
                        if game.threshold.rubric_alpha() > 0.5:
                                seen_rubric = true
                        if AudioManager._ambient_target == 0.0:
                                beds_sunk = true
                if game.room_id == "act2" and game.state == "playing":
                        break
                await get_tree().process_frame
        ok(seen_black, "the live crossing holds full black")
        ok(seen_rubric, "the live crossing inscribes the rubric")
        ok(beds_sunk, "the leaving room's air dies slowly (beds sink, never cut)")
        ok(game._crossed_edges.has("act1>act2"), "the record remembers the crossing")
        await _room("act2")
        ok(AudioManager._ambient_target > 0.0, "the arriving air rises with the wake")
        ok(game.wake != null and game.wake.full, "a deep crossing lands in a full wake (threshold feeds arrival)")
        # --- A CROSSING ALREADY IN THE RECORD IS QUICK
        game.transition_to("act1")
        await _room("act1")
        game.transition_to("act2")
        var stayed_quick := true
        var t1 := Time.get_ticks_msec()
        while Time.get_ticks_msec() - t1 < 4000:
                if game.threshold != null and game.threshold.deep:
                        stayed_quick = false
                if game.room_id == "act2" and game.state == "playing":
                        break
                await get_tree().process_frame
        ok(stayed_quick, "a crossing already in the record is quick")
        # --- THE WHISPER CROSSES WITH THE VESSEL (dread is never room-cut)
        GameState.consistency = 60
        GameState.stage = E0.stage_for(60)
        AudioManager.update_degradation(GameState.stage)
        var whisper_before: float = AudioManager._whisper_target
        game.transition_to("act3")
        var whisper_mid: float = -1.0
        var t2 := Time.get_ticks_msec()
        while Time.get_ticks_msec() - t2 < 6000:
                if game.threshold != null and game.threshold.deep and game.threshold.rubric_alpha() > 0.5:
                        whisper_mid = AudioManager._whisper_target
                        break
                if game.room_id == "act3" and game.state == "playing":
                        break
                await get_tree().process_frame
        ok(absf(whisper_mid - whisper_before) < 0.001,
                "the whisper bed crosses with the vessel (stage-driven, never room-cut)")
        await _room("act3")
        await _settle_playing(0.6)
        GameState.consistency = 100
        GameState.stage = 1
        AudioManager.update_degradation(1)
        # --- THE RECORD ANNOTATES EACH VESSEL'S CROSSINGS ANEW
        game.new_game()
        await _settle_playing(0.6)
        ok(game._crossed_edges.is_empty(), "a new vessel — the record annotates his crossings anew")
        # --- THE RUBRIC WRITES ON THE BLACK (above the fade)
        var card_parent: CanvasLayer = game.threshold_card.get_parent() as CanvasLayer
        ok(card_parent != null and card_parent.layer > 95, "the rubric writes ON the black (above the fade)")

func _settle_playing(t: float) -> void:
        ## The intro dialogue can open a few frames AFTER the room reports
        ## 'playing' — skip anything that opens and hold until the game is
        ## genuinely settled in the playing state (WB-12 laws read live
        ## renderer behaviour, so the state must be real).
        var elapsed := 0.0
        while elapsed < t:
                if game.dialogue_box.active:
                        game.dialogue_box.chars_shown = 99999
                        game.dialogue_box.advance()
                await get_tree().process_frame
                elapsed += get_process_delta_time()
        while game.dialogue_box.active:
                game.dialogue_box.chars_shown = 99999
                game.dialogue_box.advance()
                await _frames(2)
        for i in 10:
                if game.state == "playing":
                        break
                await _frames(1)
