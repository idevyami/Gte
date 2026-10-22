## GP-3 diagnostic v2 — does the world actually freeze on pause? Control first
## (hold right unpaused — the vessel MUST walk), then the same hold paused.
## Logs the axis, the velocity and the node's own can_process().
extends Node

var game: Game
var t := 0.0
var phase := 0
var x_start := 0.0

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS   # the probe must watch the paused world
        var main_scene: PackedScene = load("res://main.tscn")
        var main = main_scene.instantiate()
        add_child(main)
        game = main.game
        GameState.clear_save()
        game.set_active(true)          # the title flow leaves the game inactive
        game.new_game()
        game.load_room("act3")
        game._spawn_player_at(Vector2(600, 600))
        game.state = "playing"

func _physics_process(delta: float) -> void:
        t += delta
        match phase:
                0:
                        if t > 0.8:
                                x_start = game.player.global_position.x
                                Input.action_press("move_right")
                                phase = 1
                                t = 0.0
                1:
                        # CONTROL: unpaused hold — must move
                        if t > 0.6:
                                Input.action_release("move_right")
                                var xc := game.player.global_position.x
                                print("CONTROL unpaused: moved %.1f px" % (xc - x_start))
                                # now the same, paused
                                game.pause_menu.open()
                                get_tree().paused = true
                                x_start = game.player.global_position.x
                                Input.action_press("move_right")
                                phase = 2
                                t = 0.0
                2:
                        if fmod(t, 0.3) < delta:
                                print("paused hold: t=%.2f axis=%.2f vx=%.1f x=%.0f can_process=%s" % [
                                        t, Input.get_axis("move_left", "move_right"),
                                        game.player.velocity.x, game.player.global_position.x,
                                        str(game.player.can_process())])
                        if t > 1.0:
                                Input.action_release("move_right")
                                var xp := game.player.global_position.x
                                print("PAUSED hold result: moved %.1f px" % (xp - x_start))
                                print("VERDICT: %s" % ("WORLD RUNS DURING PAUSE — BUG" if absf(xp - x_start) > 2.0 else "world frozen on pause — no bug"))
                                get_tree().quit()
