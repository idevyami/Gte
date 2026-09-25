## Game — the conductor. Builds rooms from data, owns the player, the camera,
## the UI stack, OBSERVE targeting, dialogue flow, hunted spawns, the boss,
## the ward, transitions, saving, death, and the ending.
class_name Game
extends Node2D

var world: Node2D
var player: Player
var camera: CameraRig
var parallax: Parallax
var masonry: Masonry
var decor_renderer: Decor
var lights: Lights

var ui_layer: CanvasLayer
var hud: HUD
var dialogue_box: DialogueBox
var system_log: SystemLog
var observe_panel: ObservePanel
var brackets: ObserveBrackets
var pause_menu: PauseMenu
var end_screen: EndScreen

var dialogues: Dictionary = {}
var room_id := ""
var room_title := ""
var room_data: Dictionary = {}
var room_size := Vector2(1280, 720)

var state := "boot"           # boot | title | playing | dialogue | transition | dead | ending
var active := false

# OBSERVE state
var observe_active := false
var observe_targets: Array = []
var observe_idx := 0
var observe_prop_idx := 0

# room-runtime
var boss: BoundMartyr = null
var ward: WardBarrier = null
var rotors: Array = []
var penitent: NPC = null
var monument: EntityNode = null
var hidden_platform: CollisionShape2D = null
var hidden_platform_visual: Node2D = null
var hidden_revealed := false
var _hidden_prop: EntityNode = null
var _gate_doors: Array = []
var _combat_check_t := 0.0
var _transitioning := false
var _pending_room := ""
var _dead_handled := false
var _exits: Array = []
var _triggers: Array = []

func _ready() -> void:
        add_to_group("game")
        _load_dialogues()
        _build_ui()
        world = Node2D.new()
        world.name = "World"
        add_child(world)
        EventBus.player_died.connect(_on_player_died)
        EventBus.property_modified.connect(_on_property_modified)
        EventBus.dialogue_finished.connect(_on_dialogue_finished)
        EventBus.boss_defeated.connect(_on_boss_defeated)
        EventBus.fragment_found.connect(func(_f): queue_redraw())
        process_mode = Node.PROCESS_MODE_ALWAYS

func _load_dialogues() -> void:
        var txt := FileAccess.get_file_as_string("res://data/dialogue.json")
        var parsed: Variant = JSON.parse_string(txt)
        if typeof(parsed) == TYPE_DICTIONARY:
                dialogues = parsed
        else:
                push_error("Game: dialogue.json failed to parse")

func _build_ui() -> void:
        ui_layer = CanvasLayer.new()
        ui_layer.layer = 50
        add_child(ui_layer)
        hud = HUD.new()
        hud.set_game(self)
        ui_layer.add_child(hud)
        system_log = SystemLog.new()
        ui_layer.add_child(system_log)
        observe_panel = ObservePanel.new()
        observe_panel.set_game(self)
        ui_layer.add_child(observe_panel)
        dialogue_box = DialogueBox.new()
        dialogue_box.set_game(self)
        ui_layer.add_child(dialogue_box)
        pause_menu = PauseMenu.new()
        pause_menu.resume_requested.connect(func(): state = "playing")
        pause_menu.restart_requested.connect(_restart_from_anchor)
        pause_menu.quit_to_title_requested.connect(_quit_to_title)
        ui_layer.add_child(pause_menu)
        end_screen = EndScreen.new()
        end_screen.return_to_title.connect(_quit_to_title)
        ui_layer.add_child(end_screen)

# ------------------------------------------------------------------ lifecycle
func set_active(v: bool) -> void:
        active = v
        world.visible = v
        world.process_mode = Node.PROCESS_MODE_INHERIT if v else Node.PROCESS_MODE_DISABLED
        ui_layer.visible = v
        set_process(v)
        if not v:
                if observe_active:
                        observe_exit()

func teardown() -> void:
        set_active(false)
        if boss:
                boss.queue_free()
                boss = null
        GameState.censor_active = null

func new_game() -> void:
        GameState.new_game()
        _dead_handled = false
        state = "playing"
        load_room("act1")
        _spawn_player_at(Vector2(room_data["spawn"].x, room_data["spawn"].y))

func continue_from_save() -> void:
        var data := GameState.load_game()
        if data.is_empty():
                new_game()
                return
        GameState.apply_save(data)
        _dead_handled = false
        state = "playing"
        load_room(String(data.get("room", "act1")))
        var pos_dict: Dictionary = data.get("pos", {"x": 120, "y": 620})
        _spawn_player_at(Vector2(float(pos_dict["x"]), float(pos_dict["y"])))
        player.hp = int(data.get("hp", E0.P_MAX_HP))
        EventBus.player_health_changed.emit(player.hp, player.max_hp)
        EventBus.player_respawned.emit(room_id, player.global_position)

# ------------------------------------------------------------------ room build
func load_room(id: String) -> void:
        if not room_id.is_empty():
                EventBus.room_exited.emit(room_id)
        # clear previous world
        for child in world.get_children():
                child.queue_free()
        boss = null
        ward = null
        rotors = []
        penitent = null
        monument = null
        hidden_platform = null
        hidden_platform_visual = null
        hidden_revealed = GameState.has_flag("hidden_seen")
        _gate_doors = []
        _exits = []
        _triggers = []
        if is_instance_valid(GameState.censor_active):
                GameState.censor_active.queue_free()
                GameState.censor_active = null

        if dialogue_box and dialogue_box.active:
                dialogue_box.close()
        room_id = id
        room_data = Rooms.ROOMS[id]
        room_title = String(room_data.get("title", ""))
        room_size = room_data.get("size", Vector2(1280, 720))
        GameState.current_room = id

        # --- static geometry
        var floors: Array = room_data.get("floors", [])
        var plats: Array = room_data.get("platforms", [])
        var walls: Array = room_data.get("walls", [])
        for r in floors:
                _add_static_rect(r, false)
        for r in plats:
                _add_static_rect(r, true)
        for r in walls:
                _add_static_rect(r, false)
        # ceiling for tall rooms handled via walls data

        # --- renderers
        masonry = Masonry.new()
        var all_rects: Array[Rect2] = []
        for r in floors + walls:
                all_rects.append(r)
        masonry.setup(all_rects, hash(id), _terrain_style(id))
        world.add_child(masonry)
        decor_renderer = Decor.new()
        decor_renderer.setup(room_data.get("decor", []))
        world.add_child(decor_renderer)
        camera = CameraRig.new()
        world.add_child(camera)
        parallax = Parallax.new()
        parallax.setup(String(room_data.get("backdrop", "")), room_data.get("fog", E0.VOID), float(room_data.get("fog_a", 0.3)), room_size, camera)
        world.add_child(parallax)
        lights = Lights.new()
        lights.setup(room_data.get("lights", []))
        world.add_child(lights)

        # --- entities
        for d in room_data.get("doors", []):
                _build_door(d)
        for p in room_data.get("props", []):
                _build_prop(p)
        for a in room_data.get("anchors", []):
                var anchor := Anchor.new()
                anchor.setup_anchor(String(a.get("instance", "ANCHOR")))
                anchor.position = a["pos"]
                world.add_child(anchor)
        for n in room_data.get("npcs", []):
                _build_npc(n)
        if room_data.has("ward"):
                _build_ward(room_data["ward"])
        for e in room_data.get("enemies", []):
                _build_enemy(e)
        if room_data.has("boss"):
                _build_boss(room_data["boss"])
        if room_data.has("hidden"):
                _build_hidden(room_data["hidden"])
        # OBSERVE brackets live in world space
        brackets = ObserveBrackets.new()
        brackets.game = self
        brackets.visible = false
        world.add_child(brackets)

        # --- triggers / exits
        for t in room_data.get("triggers", []):
                _triggers.append(t.duplicate())
        _exits = room_data.get("exits", [])

        # --- player
        _spawn_player_at(room_data["spawn"] as Vector2)
        camera.setup(player, room_size)

        # --- presentation
        AudioManager.play_music(String(room_data.get("music", "")))
        var amb: Dictionary = room_data.get("ambient", {})
        AudioManager.play_ambient(String(amb.get("id", "")), float(amb.get("vol", 0.4)))
        for msg in room_data.get("system_on_enter", []):
                system_message(String(msg))
        EventBus.room_entered.emit(id)
        hud.set_boss(boss)

func _terrain_style(id: String) -> String:
        ## Visual material of load-bearing geometry (gameplay unchanged).
        if id.begins_with("act7"):
                return "metal"
        return "stone"

func _add_static_rect(r: Rect2, one_way: bool) -> void:
        var body := StaticBody2D.new()
        body.collision_layer = E0.L_WORLD
        body.collision_mask = 0
        var shape := CollisionShape2D.new()
        var rect := RectangleShape2D.new()
        rect.size = r.size
        shape.shape = rect
        shape.one_way_collision = one_way
        shape.position = r.get_center()
        body.add_child(shape)
        world.add_child(body)

func _build_door(d: Dictionary) -> void:
        var door := Door.new()
        door.setup_door(String(d.get("entity", "DOOR_029")), String(d.get("instance", "")), String(d.get("mode", "lock")), d.get("size", Vector2(54, 160)))
        door.position = d["pos"]
        if d.has("flag"):
                door.extra["flag"] = String(d["flag"])
        world.add_child(door)
        if String(d.get("mode", "")) == "gate":
                _gate_doors.append(door)
        # re-apply persisted open state
        if EntityDB.overrides.has(door.instance_key):
                var ov: Dictionary = EntityDB.overrides[door.instance_key]
                for prop_name in ov.get("props", {}):
                        door.data.properties[prop_name]["value"] = ov["props"][prop_name]
                if String(ov.get("state", "")) == "OPEN":
                        door.try_open_from_flag()

func _build_prop(p: Dictionary) -> void:
        var node := EntityNode.new()
        node.setup(String(p.get("entity", "")), String(p.get("instance", "")), String(p.get("kind", "prop")), p.get("extra", {}))
        node.position = p["pos"]
        world.add_child(node)
        if String(p.get("kind", "")) == "rotor":
                rotors.append(node)
        if bool(p.get("hidden_s6", false)):
                _hidden_prop = node
                node.visible_prop(false)

func _build_npc(n: Dictionary) -> void:
        var npc := NPC.new()
        npc.setup_npc(String(n.get("id", "oren")), String(n.get("entity", "MEASURER_OREN")), String(n.get("instance", "")), bool(n.get("silent", false)))
        npc.position = n["pos"]
        world.add_child(npc)
        if String(n.get("id", "")) == "penitent":
                penitent = npc
                if not room_data.get("penitent_starts_visible", true):
                        npc.visible_prop(false)

func _build_enemy(e: Dictionary) -> void:
        match String(e.get("type", "")):
                "hollow":
                        var h := Hollow.new()
                        h.setup_hollow(e["pos"], e.get("patrol", Vector2(200, 600)))
                        h.add_to_group("enemies")
                        world.add_child(h)
                "null":
                        var nc := NullChild.new()
                        nc.setup_null(e["pos"])
                        nc.add_to_group("enemies")
                        world.add_child(nc)
                "believer":
                        var b := Believer.new()
                        b.setup_believer(e["pos"], ward, bool(e.get("kneel", true)))
                        b.add_to_group("enemies")
                        world.add_child(b)

func _build_ward(w: Dictionary) -> void:
        ward = WardBarrier.new()
        ward.setup_ward(String(w.get("instance", "WARD_BARRIER")), float(w.get("height", 300.0)))
        ward.position = w["pos"]
        world.add_child(ward)

func _build_boss(b: Dictionary) -> void:
        boss = BoundMartyr.new()
        boss.setup_martyr(b["pos"], b.get("arena", Vector2(300, 1300)), float(b.get("floor_y", 840.0)))
        boss.add_to_group("enemies")
        world.add_child(boss)
        for p in b.get("bearers", []):
                var bb := Believer.new()
                bb.setup_believer(p, null, true)
                bb.add_to_group("enemies")
                world.add_child(bb)
                boss._bearers.append(bb)

func _build_hidden(h: Dictionary) -> void:
        var body := StaticBody2D.new()
        body.collision_layer = E0.L_WORLD
        body.collision_mask = 0
        var shape := CollisionShape2D.new()
        var rect := RectangleShape2D.new()
        var r: Rect2 = h["rect"]
        rect.size = r.size
        shape.shape = rect
        shape.position = r.get_center()
        body.add_child(shape)
        hidden_platform = shape
        hidden_platform_visual = _HiddenPlatformVisual.new()
        hidden_platform_visual.position = r.get_center()
        hidden_platform_visual.size = r.size
        world.add_child(body)
        world.add_child(hidden_platform_visual)
        _apply_hidden_state(true)

func _apply_hidden_state(initial := false) -> void:
        if hidden_platform == null and _hidden_prop == null:
                return
        var should_show: bool = GameState.stage >= 6
        if hidden_platform:
                hidden_platform.disabled = not should_show
        if hidden_platform_visual:
                hidden_platform_visual.visible = should_show
        if _hidden_prop:
                _hidden_prop.visible_prop(should_show)
        if should_show and not hidden_revealed and not initial:
                hidden_revealed = true
                GameState.set_flag("hidden_seen")
                system_message("AN UNLISTED STRUCTURE HAS BECOME VISIBLE.", "warn")
                AudioManager.play_sfx("sfx_reveal", -6.0)

func _spawn_player_at(pos: Vector2) -> void:
        if player and is_instance_valid(player):
                player.remove_from_group("player")
                player.queue_free()
        player = Player.new()
        player.add_to_group("player")
        world.add_child(player)
        player.global_position = pos
        player.input_locked = false
        player.controllable = true

# ------------------------------------------------------------------ process
func _process(delta: float) -> void:
        if not active:
                return
        if pause_menu.visible:
                return
        match state:
                "playing":
                        _scan_interact()
                        _check_triggers()
                        _check_exits()
                        _hunted(delta)
                        _combat_music(delta)
                        _apply_hidden_state()
                "dialogue":
                        pass
                "dead", "transition", "ending":
                        pass

# ------------------------------------------------------------------ interact
var _nearest_interactable = null

func _scan_interact() -> void:
        if player == null:
                return
        _nearest_interactable = null
        var best := 1e9
        for node in get_tree().get_nodes_in_group("interactable"):
                var en := node as EntityNode
                if en == null or not en.visible:
                        continue
                var d := player.global_position.distance_to(en.global_position + Vector2(0, -10.0))
                if d < 58.0 and d < best:
                        best = d
                        _nearest_interactable = en
        if _nearest_interactable:
                hud.show_prompt(_nearest_interactable.prompt)
        else:
                hud.show_prompt("")

# ------------------------------------------------------------------ input
func _unhandled_input(event: InputEvent) -> void:
        if not active or pause_menu.visible or end_screen.visible:
                return
        if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
                GameState.debug_no_sprites = not GameState.debug_no_sprites
                system_message("SPRITE ART " + ("DISABLED — PROCEDURAL RIGS" if GameState.debug_no_sprites else "ENABLED"), "quiet")
                return
        if event.is_action_pressed("pause") and state in ["playing", "dialogue"]:
                pause_menu.open()
                return
        match state:
                "dialogue":
                        if event.is_action_pressed("interact"):
                                dialogue_box.advance()
                        return
                "playing":
                        pass
                _:
                        return
        if event.is_action_pressed("observe"):
                _observe_key()
        elif event.is_action_pressed("interact"):
                _interact_key()
        elif event.is_action_pressed("modify"):
                _modify_key()
        elif event.is_action_pressed("move_up"):
                if observe_active:
                        _cycle_property(-1)
        elif event.is_action_pressed("move_down"):
                if observe_active:
                        _cycle_property(1)

func _interact_key() -> void:
        if observe_active:
                return
        if _nearest_interactable:
                _nearest_interactable.interact(self)
                if player:
                        player.play_interact()

func _observe_key() -> void:
        if not GameState.observe_installed:
                system_message("OBSERVE IS NOT INSTALLED. SOMETHING BELOW CAN INSTALL IT.", "quiet")
                return
        if dialogue_box.active:
                return
        if not observe_active:
                observe_enter()
        else:
                observe_cycle()

func observe_enter() -> void:
        _collect_targets()
        if observe_targets.is_empty():
                system_message("NOTHING OBSERVABLE IN RANGE.", "quiet")
                return
        observe_active = true
        observe_idx = 0
        observe_prop_idx = 0
        FX.set_observe(true)
        AudioManager.play_sfx("sfx_observe_enter", -4.0)
        EventBus.observe_toggled.emit(true)
        brackets.visible = true

func _collect_targets() -> void:
        observe_targets = []
        if player == null:
                return
        var cands: Array = []
        for node in EntityDB.live_nodes():
                if node == null or not is_instance_valid(node):
                        continue
                if node is EntityNode and not node.visible:
                        continue
                var anchor: Vector2 = node.observe_anchor()
                var d := player.global_position.distance_to(anchor)
                if d < 380.0:
                        cands.append({"d": d, "node": node})
        cands.sort_custom(func(a, b): return a["d"] < b["d"])
        observe_targets = []
        for c in cands:
                observe_targets.append(c["node"])

func observe_cycle() -> void:
        observe_idx += 1
        if observe_idx >= observe_targets.size():
                observe_exit()
                return
        observe_prop_idx = 0
        AudioManager.play_sfx("sfx_ui_move", -6.0)
        EventBus.observe_target_changed.emit(_target_id())

func observe_exit() -> void:
        observe_active = false
        observe_targets = []
        FX.set_observe(false)
        AudioManager.play_sfx("sfx_observe_exit", -6.0)
        EventBus.observe_toggled.emit(false)
        brackets.visible = false

func _target_id() -> String:
        if observe_idx < observe_targets.size() and observe_targets[observe_idx]:
                return observe_targets[observe_idx].instance_key
        return ""

func _modifiable_props(target) -> Array:
        var props: Array = target.data.visible_properties(GameState.stage, GameState.flags)
        var moddable: Array = []
        for p in props:
                if p["modifiable"]:
                        moddable.append(p)
        return moddable

func _cycle_property(dir: int) -> void:
        var target = _current_target()
        if target == null:
                return
        var mods := _modifiable_props(target)
        if mods.is_empty():
                return
        observe_prop_idx = wrapi(observe_prop_idx + dir, 0, mods.size())
        AudioManager.play_sfx("sfx_ui_move", -10.0)

func _current_target():
        if observe_idx < observe_targets.size():
                return observe_targets[observe_idx]
        return null

func _modify_key() -> void:
        if not observe_active:
                return
        var target = _current_target()
        if target == null:
                return
        var mods := _modifiable_props(target)
        if mods.is_empty():
                AudioManager.play_sfx("sfx_ui_deny", -6.0)
                system_message("NOTHING HERE IS MODIFIABLE. SOME THINGS ARE ONLY TRUE.", "quiet")
                return
        observe_prop_idx = clampi(observe_prop_idx, 0, mods.size() - 1)
        var prop_name: String = mods[observe_prop_idx]["name"]
        var new_value: Variant = target.data.next_value(prop_name)
        var cost: int = mods[observe_prop_idx]["cost"]
        var ok := EntityDB.modify(target, prop_name)
        if ok:
                var lines := [
                        "> MODIFY \u2192 %s=%s" % [prop_name, _fmt_v(new_value)],
                        "............ ACK. THE WORLD OBEYS.",
                        "............ CONSISTENCY \u2212%d." % cost,
                ]
                observe_panel.show_receipt(lines)
                FX.tear_pulse(0.6)
                # target may have died / changed — refresh
                _collect_targets_keep_index()

func _collect_targets_keep_index() -> void:
        var keep := _target_id()
        _collect_targets()
        for i in observe_targets.size():
                if observe_targets[i] and observe_targets[i].instance_key == keep:
                        observe_idx = i
                        return
        observe_idx = 0

func _abandon_all_believers() -> void:
        for node in get_tree().get_nodes_in_group("enemies"):
                var b := node as Believer
                if b and not b.dead:
                        b.begin_flee()

func _fmt_v(v: Variant) -> String:
        if v is bool:
                return "true" if v else "false"
        return str(v)

# ------------------------------------------------------------------ triggers / exits
func _check_triggers() -> void:
        if player == null:
                return
        for t in _triggers:
                var rect: Rect2 = t["rect"]
                if rect.has_point(player.global_position):
                        var requires := String(t.get("requires", ""))
                        if not requires.is_empty() and not EntityData._condition_holds(requires, GameState.stage, GameState.flags, GameState.consistency):
                                continue
                        if GameState.fire_once(room_id + ":" + String(t.get("id", ""))):
                                _fire_trigger(String(t["action"]))

func _fire_trigger(action: String) -> void:
        if action.begins_with("dialogue:"):
                start_dialogue(action.substr(9))
        elif action.begins_with("system:"):
                system_message(action.substr(7))
        elif action == "penitent:appear":
                _penitent_appear()
        elif action == "boss_intro":
                _boss_intro()

func _check_exits() -> void:
        if _transitioning or player == null:
                return
        for e in _exits:
                var rect: Rect2 = e["rect"]
                if rect.has_point(player.global_position):
                        transition_to(String(e["to"]))
                        return

func transition_to(next_room: String) -> void:
        if _transitioning:
                # a transition is finishing — queue this one instead of
                # dropping it (a player standing in an exit is never ignored)
                _pending_room = next_room
                return
        _transitioning = true
        state = "transition"
        if player:
                player.input_locked = true
        if dialogue_box and dialogue_box.active:
                dialogue_box.close()
        FX.fade_out(0.35)
        await get_tree().create_timer(0.4, true, false, true).timeout
        load_room(next_room)
        state = "playing"
        FX.fade_in(0.4)
        await get_tree().create_timer(0.45, true, false, true).timeout
        _transitioning = false
        if not _pending_room.is_empty():
                var queued := _pending_room
                _pending_room = ""
                transition_to(queued)

# ------------------------------------------------------------------ dialogue
func start_dialogue(key: String) -> void:
        if state == "dialogue":
                return
        state = "dialogue"
        player.input_locked = true
        dialogue_box.open(key)

func _on_dialogue_finished(key: String) -> void:
        if state == "dialogue":
                state = "playing"
        if player:
                player.input_locked = false
        match key:
                "martyr_intro":
                        if boss:
                                boss.begin_fight()
                                hud.set_boss(boss)
                "penitent":
                        if penitent and is_instance_valid(penitent):
                                penitent.vanish()
                "ending_sequence":
                        _finish_game()

func system_message(text: String, mode := "system") -> void:
        system_log.push(text, mode)

# ------------------------------------------------------------------ hunted
func _hunted(delta: float, allow := -1.0) -> void:
        if allow < 0.0:
                allow = bool(room_data.get("hunts", false)) and state == "playing"
        var plan := GameState.hunted_update(delta, allow)
        if plan["censor"] and GameState.censor_active == null:
                var censor := Censor.new()
                censor.position = Vector2(clampf(player.global_position.x + (500.0 if randf() < 0.5 else -500.0), 60.0, room_size.x - 60.0), clampf(player.global_position.y - 160.0, 80.0, room_size.y - 80.0))
                world.add_child(censor)
                GameState.censor_active = censor
                system_message("THE CENSOR HAS ENTERED THE RECORD.", "danger")
                AudioManager.play_sfx("sfx_censor", 4.0)
        if plan["correction"]:
                var c := Correction.new()
                var ang := randf() * TAU
                c.position = player.global_position + Vector2(cos(ang), sin(ang) * 0.5) * 320.0
                world.add_child(c)

# ------------------------------------------------------------------ combat music
func _combat_music(delta: float) -> void:
        _combat_check_t += delta
        if _combat_check_t < 0.5:
                return
        _combat_check_t = 0.0
        if boss and boss.intro_done and not boss.is_dead_state():
                AudioManager.set_combat_layer(false)
                return
        var any_aggro := false
        for node in get_tree().get_nodes_in_group("enemies"):
                var e := node as EnemyBase
                if e and not e.dead and e.aggro:
                        any_aggro = true
                        break
        AudioManager.set_combat_layer(any_aggro)

# ------------------------------------------------------------------ boss
func _boss_intro() -> void:
        if boss == null or boss.intro_done:
                return
        player.input_locked = true
        start_dialogue("martyr_intro")

func _on_boss_defeated(_entity_id: String) -> void:
        on_boss_defeated()

func on_boss_defeated() -> void:
        hud.set_boss(null)
        AudioManager.set_combat_layer(false)
        AudioManager.play_music("aftermath")
        # the monument persists — it is the story of this room now
        monument = EntityNode.new()
        monument.setup("MONUMENT", "MONUMENT", "monument")
        monument.position = boss.global_position if boss else Vector2(900, 840)
        world.add_child(monument)
        system_message("ENTITY_000_001 — FAILED — REPURPOSED. THE INSCRIPTION IS HIS.", "warn")
        for door in _gate_doors:
                door.try_open_from_flag()

# ------------------------------------------------------------------ penitent
func _penitent_appear() -> void:
        if penitent == null or not is_instance_valid(penitent):
                return
        penitent.visible_prop(true)
        AudioManager.play_sfx("sfx_reveal", -8.0)
        start_dialogue("penitent")

# ------------------------------------------------------------------ monument / ending
func monument_read() -> void:
        if GameState.game_finished:
                return
        start_dialogue("ending_sequence")

func _finish_game() -> void:
        GameState.game_finished = true
        if not GameState.has_fragment("FRAGMENT_04"):
                EventBus.fragment_found.emit("FRAGMENT_04")
                AudioManager.play_sfx("sfx_reveal", -2.0)
        var elapsed := (Time.get_ticks_msec() - GameState.run_started_at) / 1000
        var stats := GameState.stats.duplicate()
        stats["elapsed"] = elapsed
        state = "ending"
        player.input_locked = true
        end_screen.open(stats)

# ------------------------------------------------------------------ anchors / save / death
func save_at_anchor(anchor: Anchor) -> bool:
        return GameState.save_game(room_id, player.global_position, player.hp, anchor.instance_key)

func _restart_from_anchor() -> void:
        _restore_after_death()

func _on_player_died() -> void:
        if _dead_handled:
                return
        _dead_handled = true
        GameState.stats["deaths"] += 1
        _handle_death()

func _handle_death() -> void:
        state = "dead"
        player.input_locked = true
        await get_tree().create_timer(2.4, true, false, true).timeout
        FX.fade_out(0.5)
        await get_tree().create_timer(0.6, true, false, true).timeout
        _restore_after_death()
        FX.fade_in(0.5)
        await get_tree().create_timer(0.6, true, false, true).timeout
        _dead_handled = false

func _restore_after_death() -> void:
        if GameState.has_save():
                var data := GameState.load_game()
                GameState.apply_save(data)
                load_room(String(data.get("room", room_id)))
                var pos_dict: Dictionary = data.get("pos", {})
                _spawn_player_at(Vector2(float(pos_dict.get("x", 120.0)), float(pos_dict.get("y", 620.0))))
                player.hp = int(data.get("hp", E0.P_MAX_HP))
        else:
                load_room(room_id)
                _spawn_player_at(room_data["spawn"] as Vector2)
                player.hp = E0.P_MAX_HP
        EventBus.player_health_changed.emit(player.hp, player.max_hp)
        EventBus.player_respawned.emit(room_id, player.global_position)
        state = "playing"
        hud.set_boss(boss)

func _quit_to_title() -> void:
        get_tree().paused = false
        set_active(false)
        teardown()
        _notify_title()

func _notify_title() -> void:
        var main := get_tree().root.get_node_or_null("Main")
        if main and main.has_method("return_to_title"):
                main.return_to_title()

# ------------------------------------------------------------------ hidden platform visual
class _HiddenPlatformVisual:
        extends Node2D
        var size := Vector2(200, 22)
        var _t := 0.0
        func _process(delta: float) -> void:
                _t += delta
                queue_redraw()
        func _draw() -> void:
                var pulse := 0.35 + 0.25 * sin(_t * 2.2)
                draw_rect(Rect2(-size * 0.5, size), Color(E0.VIOLET.r, E0.VIOLET.g, E0.VIOLET.b, 0.8))
                draw_rect(Rect2(-size * 0.5, size), Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, pulse * 0.6), false, 1.5)
                for i in 5:
                        var gx := -size.x * 0.4 + i * size.x * 0.2
                        draw_rect(Rect2(Vector2(gx - 2.0, -size.y * 0.5), Vector2(4, 4)), Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, pulse))

# ------------------------------------------------------------------ rotors
func rotor_pulled(rotor: EntityNode) -> void:
        var seq: int = int(rotor.extra.get("seq", 0))
        if rotor.extra.get("pulled", false):
                system_message("THE ROTOR IS ALREADY TURNED.", "quiet")
                return
        rotor.extra["pulled"] = true
        AudioManager.play_sfx("sfx_boss_chain", -8.0)
        # the sequence is ascending: turning a later rotor while an earlier waits resets
        for r in rotors:
                if r != rotor and not r.extra.get("pulled", false):
                        if int(r.extra.get("seq", 0)) < seq:
                                for r2 in rotors:
                                        r2.extra["pulled"] = false
                                AudioManager.play_sfx("sfx_ui_deny", -4.0)
                                FX.shake(3.0, 0.2)
                                system_message("THE RHYTHM REJECTS THE SEQUENCE. THE ROTORS RESET.", "warn")
                                return
        var all_pulled := true
        for r in rotors:
                if not r.extra.get("pulled", false):
                        all_pulled = false
        if all_pulled and not GameState.has_flag(GameState.F_HEART_ALIGNED):
                GameState.set_flag(GameState.F_HEART_ALIGNED)
                start_dialogue("heart_aligned")
                AudioManager.play_sfx("sfx_reveal", 0.0)
                for door in _gate_doors:
                        door.try_open_from_flag()

# ------------------------------------------------------------------ property responses
func _on_property_modified(instance_key: String, prop_name: String, _old: Variant, new_value: Variant) -> void:
        # Believers / the censer: rewriting purpose to ABANDON stops every ritual.
        if prop_name == "purpose" and String(new_value) == "ABANDON":
                _abandon_all_believers()
                system_message("THE CHANT STOPS. BELIEF IS A MACHINE AND MACHINES CAN BE SWITCHED OFF.", "warn")
        # The toll gate opens when the machine is settled (BROKEN).
        if instance_key == "TOLL_MACHINE_03" and prop_name == "state" and String(new_value) == "BROKEN":
                for door in _gate_doors:
                        if String(door.extra.get("mode", "")) == "toll":
                                door.try_open_from_flag()
                system_message("THE ACCOUNT IS SETTLED. THE GATE FORGETS IT WAS CLOSED.")
        # The archive ledger reconciled: the records stop arguing, and something notices.
        if instance_key == "DISCREPANCY_LEDGER" and prop_name == "record" and String(new_value) == "RECONCILED":
                GameState.set_flag(GameState.F_ARCHIVE_FIXED)
                system_message("THE LEDGER AGREES WITH ITSELF NOW. IT DID NOT ENJOY BEING WRONG.", "warn")
                if penitent and is_instance_valid(penitent) and not GameState.has_flag(GameState.F_PENITENT_SEEN):
                        _penitent_appear()
