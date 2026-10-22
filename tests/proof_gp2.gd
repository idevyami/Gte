## GP-2 THE RECORD SPEAKS — the text-integrity audit. The world's own
## inscriptions had never been proofread as PUBLISHED TEXT: the 207-bank and
## GP-1 read frames for composition and legibility, not for what the words
## themselves claim. Three event-locked shots on the three surfaces this
## pass corrected: the census stele's struck-count (r13, read), the fourth
## fundamental's observe memory (r15, OBSERVE), and the mural notice's
## title (r22, read). Real paths only: the reading panels arrive by the
## real open_reading, the observe panel by the real observe_enter with the
## vessel standing at the stone (cycling the true Tab path onto it).
extends Node

var game: Game
var main: Node
var _shot := 0

func _ready() -> void:
        DirAccess.make_dir_recursive_absolute("res://screenshots/gp2")
        _run.call_deferred()

func _snap(name: String) -> void:
        ## frame_post_draw: the saved image is the frame JUST drawn — the
        ## state set before this call is guaranteed visible
        await RenderingServer.frame_post_draw
        var img := get_viewport().get_texture().get_image()
        img.save_png("res://screenshots/gp2/%s.png" % name)
        _shot += 1
        print("GP2 STILL ", name, " saved")

func _wait(t: float) -> void:
        var t0 := Time.get_ticks_msec()
        while Time.get_ticks_msec() - t0 < int(t * 1000.0):
                await get_tree().process_frame

func _wait_room(id: String, pos := Vector2(700, 700)) -> void:
        game.transition_to(id)
        var t0 := Time.get_ticks_msec()
        while Time.get_ticks_msec() - t0 < 12000:
                if game.room_id == id and game.state == "playing":
                        break
                if game.dialogue_box.active:
                        game.dialogue_box.chars_shown = 99999
                        game.dialogue_box.advance()
                await get_tree().process_frame
        for i in 600:
                if not game.cinema.is_showing():
                        break
                await get_tree().process_frame
        await _wait(0.5)
        game.player.global_position = pos
        game.player.velocity = Vector2.ZERO
        game.player.facing = 1
        await _wait(0.6)

func _skip_dialogue() -> void:
        while game.dialogue_box != null and game.dialogue_box.active:
                game.dialogue_box.chars_shown = 99999
                game.dialogue_box.advance()
                await get_tree().process_frame

func _find_readable(id: String) -> Readable:
        for ch in game.world.get_children():
                if ch is Readable and String(ch.entry.get("id", "")) == id:
                        return ch
        return null

func _run() -> void:
        main = (load("res://main.tscn") as PackedScene).instantiate()
        get_tree().root.add_child(main)
        await get_tree().process_frame
        await get_tree().process_frame
        game = main.game
        main.title.hide_screen()
        game.set_active(true)
        game.new_game()
        await _wait(1.0)
        _skip_dialogue()
        await _wait(0.3)

        # ================================================= THE CENSUS STELE (r13)
        # the full reading surface: body, the system's struck-count stamp,
        # the later hand's margin — the panel a player actually reads
        await _wait_room("act4", Vector2(700, 700))
        var r13 := _find_readable("r13_census_ward")
        if r13 == null:
                print("GP2 ERROR: r13 not found in act4")
                get_tree().quit(1)
                return
        game.open_reading(r13)                     # the real reading flow
        await _wait(0.35)
        game.reading_panel._chars = 1.0e9          # finish the carving
        game.reading_panel._margin_t = 1.0         # and the later hand
        await _wait(0.6)
        await _snap("gp2_01_census")
        game.reading_panel.close()
        await _wait(0.4)

        # ============================================ THE FOURTH FUNDAMENTAL (r15)
        # the OBSERVE readout of the posted law — the record's own memory of
        # where its gold-leaf copy hangs. The vessel stands at the stone and
        # cycles the true Tab path onto it.
        await _wait_room("act5", Vector2(240.0, 800.0))
        GameState.observe_installed = true
        game.observe_enter()
        # cycle until the ledger reads the law itself (bounded — the room
        # hosts other observable bodies)
        var tries := 0
        while game.observe_active and game._current_target() != null \
                        and String(game._current_target().instance_key) != "r15_fundamental_four" and tries < 24:
                game.observe_cycle()
                tries += 1
                await _wait(0.08)
        await _wait(1.2)                           # the lens leans in
        await _snap("gp2_02_law_obs")
        game.observe_exit()
        await _wait(0.4)

        # ================================================ THE MURAL NOTICE (r22)
        # the corrected mural notice in the archive — title, body, stamp
        await _wait_room("act6", Vector2(1000.0, 800.0))
        var r22 := _find_readable("r22_correction_notice")
        if r22 == null:
                print("GP2 ERROR: r22 not found in act6")
                get_tree().quit(1)
                return
        game.open_reading(r22)
        await _wait(0.35)
        game.reading_panel._chars = 1.0e9
        game.reading_panel._margin_t = 1.0
        await _wait(0.6)
        await _snap("gp2_03_mural")
        game.reading_panel.close()
        await _wait(0.4)

        # ============================================= THE SCREAMING CRADLE (wrap)
        # the longest memory in the record (74 characters) sits two strides
        # from the vessel's own cradle — and the ledger's single-line
        # economy never showed more than its first breath. The observe
        # readout of CRADLE_SHELF_1: the memory layer, wrapped or cut.
        await _wait_room("act1", Vector2(300.0, 970.0))
        GameState.observe_installed = true
        game.observe_enter()
        var tries2 := 0
        while game.observe_active and game._current_target() != null \
                        and String(game._current_target().instance_key) != "CRADLE_SHELF_1" and tries2 < 24:
                game.observe_cycle()
                tries2 += 1
                await _wait(0.08)
        await _wait(1.2)
        await _snap("gp2_04_cradle")

        print("GP-2 STILLS DONE (", _shot, ")")
        get_tree().quit(0)
