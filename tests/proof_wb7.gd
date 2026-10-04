## WB-7 "The Performers" proof — the walk cycles (hollow walks, Oren talks),
## the hurt recoil + wound card, the death performance (stun / buckle /
## going down / prone / dissolve), the deepened prayer, the boss sway, and
## the presence pools + deepened rims against the busy world.
## CONTROLLED STAGING: for the performance shots every other enemy is
## cleared from the room and the performer is parked at a marked spot —
## one body, one read, no confounds.
extends Node

var game: Game
var main: Node

const STAGE_X := 1780.0   # the performance spot — lit, open, mid-view

func _ready() -> void:
        DirAccess.make_dir_recursive_absolute("res://screenshots")
        _run.call_deferred()

func _snap(name: String) -> void:
        if game and game.system_log:
                game.system_log.entries.clear()
                game.system_log.queue_redraw()
        await get_tree().process_frame
        await get_tree().process_frame
        var img := get_viewport().get_texture().get_image()
        img.save_png("res://screenshots/" + name + ".png")
        print("SNAP ", name)

func _wait(t: float) -> void:
        await get_tree().create_timer(t, true, false, true).timeout

func _skip_dialogue() -> void:
        while game.dialogue_box.active:
                game.dialogue_box.chars_shown = 99999
                game.dialogue_box.advance()
                await get_tree().process_frame

func _room(id: String, pos := Vector2(640, 600)) -> void:
        game.transition_to(id)
        for i in 900:
                if game.room_id == id and game.state == "playing":
                        break
                if game.dialogue_box.active:
                        game.dialogue_box.chars_shown = 99999
                        game.dialogue_box.advance()
                await get_tree().process_frame
        for i in 900:
                if not game.cinema.is_showing():
                        break
                await get_tree().process_frame
        await _wait(0.5)
        game.player.global_position = pos
        game.player.velocity = Vector2.ZERO
        await _wait(0.5)
        _skip_dialogue()
        await _wait(0.3)

func _stage_hollow() -> Hollow:
        ## ONE hollow, parked at the performance spot with a tight patrol
        ## band — every other enemy leaves the room.
        var h: Hollow = null
        for n in get_tree().get_nodes_in_group("enemies"):
                if n is Hollow:
                        if h == null:
                                h = n
                        else:
                                n.queue_free()
        if h:
                h.global_position = Vector2(STAGE_X, 814)
                h.velocity = Vector2.ZERO
                h.patrol_from = STAGE_X - 110.0
                h.patrol_to = STAGE_X + 110.0
                h.state = Hollow.PATROL
                h.state_t = 0.0
        return h

func _run() -> void:
        main = (load("res://main.tscn") as PackedScene).instantiate()
        get_tree().root.add_child(main)
        await get_tree().process_frame
        await get_tree().process_frame
        game = main.game
        GameState.clear_save()   # a stale smoke save must never hijack a respawn
        main.title.hide_screen()
        game.set_active(true)
        game.new_game()
        for i in 900:
                if game.room_id == "act1" and game.state == "playing":
                        break
                if game.dialogue_box.active:
                        game.dialogue_box.chars_shown = 99999
                        game.dialogue_box.advance()
                await get_tree().process_frame
        for i in 900:
                if not game.cinema.is_showing():
                        break
                await get_tree().process_frame
        await _wait(0.5)

        # --- 01/02 · THE WALK — full stride, then the counter stride -------
        # (PERFORMANCE CLOSE-UP: the camera glues to the performer at 2.2x —
        # a 43px body must be judged at the scale the animation lives in.
        # The player parks FAR away: no stalk, no lunge, no accidents.)
        await _room("act3", Vector2(1000, 840))
        var h := _stage_hollow()
        game.camera.target = h
        game.camera.zoom = Vector2(2.2, 2.2)
        game.camera.zoom_target = 2.2
        game.camera.zoom_speed = 8.0
        await _wait(0.4)
        for i in 300:
                if h and is_instance_valid(h) and h.state == Hollow.PATROL and absf(h.velocity.x) > 20.0 \
                                and h._skin and h._skin.animation == "walk" \
                                and h._skin.frame in [0, 3]:
                        break
                await get_tree().process_frame
        await _snap("wb7_01_hollow_walk")
        # the opposite phase (counter reach) — half a cycle later
        for i in 300:
                if h and h._skin and h._skin.animation == "walk" \
                                and h._skin.frame in [2, 5]:
                        break
                await get_tree().process_frame
        await _snap("wb7_02_hollow_walk_late")

        # --- 03 · THE WOUND — strike lands, recoil + impact card -----------
        if h and is_instance_valid(h):
                # freeze the performer (RECOVER = decelerating, no walking)
                h.state = Hollow.RECOVER
                h.velocity = Vector2.ZERO
                # stand the player ON the floor at strike range and LET HIM
                # LAND (attacks only start grounded)
                game.player.global_position = Vector2(h.global_position.x - 56.0, h.global_position.y)
                game.player.velocity = Vector2.ZERO
                game.player.facing = 1
                await _wait(0.3)
                # the press must come from a process-frame continuation (the
                # smoke-suite law): a timer-context press stamps just_pressed
                # where the player's _process never reads it
                await get_tree().process_frame
                Input.action_press("attack")
                await get_tree().process_frame
                Input.action_release("attack")
                # the swing is running; the hit lands 80ms in — catch the
                # wound card, the recoil and the mid-swing together (the snap
                # itself costs ~2 frames + PNG save, so trigger just past
                # impact)
                await _wait(0.062)
                await _snap("wb7_03_strike_woundcard")
                # step out of aggro range while the wound settles
                game.player.global_position = Vector2(1000, 840)
                game.player.velocity = Vector2.ZERO
                await _wait(0.4)

        # --- 05 · THE DEATH PERFORMANCE (four phases + the dissolve) -------
        if h and is_instance_valid(h) and not h.dead:
                var spot := h.global_position
                h.take_hit(9999, spot - Vector2(56.0, 0.0), true)
        await _wait(0.16)
        await _snap("wb7_05a_death_stun")
        await _wait(0.24)
        await _snap("wb7_05b_death_buckle")
        await _wait(0.26)
        await _snap("wb7_05c_death_goingdown")
        await _wait(0.28)
        await _snap("wb7_05d_death_prone")
        await _wait(0.22)
        await _snap("wb7_05e_death_dissolve")
        # back to the player at gameplay scale for the world shots
        game.camera.target = game.player
        game.camera.zoom_target = 1.0
        game.camera.zoom_speed = 3.0
        await _wait(0.8)

        # --- 06 · OREN PERFORMS HIS SPEECH -----------------------------------
        game.player.global_position = Vector2(980, 840)
        game.player.velocity = Vector2.ZERO
        await _wait(0.5)
        _skip_dialogue()
        var oren: NPC = null
        for node in get_tree().get_nodes_in_group("interactable"):
                if node is NPC and node.npc_id == "oren":
                        oren = node
        if oren:
                game.player.global_position = oren.global_position + Vector2(-52, 0)
                await _wait(0.3)
                oren.interact(game)
                await _wait(0.7)
                await _snap("wb7_06_oren_talk")
                _skip_dialogue()
                await _wait(0.4)
                await _snap("wb7_06b_oren_idle")

        # --- 07 · THE DEEPENED PRAYER (chapel kneelers, 4-frame bow) --------
        await _room("act5", Vector2(1470, 814))
        await _wait(0.8)
        await _snap("wb7_07_believers_prayer")

        # --- 08 · THE BOSS SWAYS (4-frame phase idles + strain sag) ---------
        await _room("act8", Vector2(640, 814))
        await _wait(0.5)
        _skip_dialogue()
        await _snap("wb7_08_boss_sway")
        await _wait(1.4)
        await _snap("wb7_08b_boss_sway_late")

        # --- 09 · PRESENCE: pools + deepened contact shadows + rims ---------
        await _room("act3", Vector2(1700, 814))
        await _wait(0.8)
        await _snap("wb7_09_presence_pools")
        # the readability frame — same spot as the audit's camouflage finding
        game.player.global_position = Vector2(1150, 814)
        game.player.velocity = Vector2.ZERO
        await _wait(0.7)
        await _snap("wb7_10_readability")
        # the lit case: standing in a brazier's pool — room light + aura
        game.player.global_position = Vector2(1985, 814)
        game.player.velocity = Vector2.ZERO
        await _wait(0.7)
        await _snap("wb7_11_readability_lit")

        print("WB7 PROOFS DONE")
        get_tree().quit(0)
