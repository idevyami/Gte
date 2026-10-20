## WB-26 diagnostic — act6 backward drift: hold right constantly, log
## position/velocity/input state. Is the drift the game or the driver?
extends Node

var game: Game
var t := 0.0
var held_right := false

func _ready() -> void:
        var main_scene: PackedScene = load("res://main.tscn")
        var main = main_scene.instantiate()
        add_child(main)
        game = main.game
        GameState.clear_save()
        game.new_game()
        game.load_room("act6")
        game._spawn_player_at(Vector2(560, 814))
        game.state = "playing"

func _hold_right(on: bool) -> void:
        if on == held_right:
                return
        held_right = on
        for ev in InputMap.action_get_events("move_right"):
                if ev is InputEventKey:
                        var k := InputEventKey.new()
                        k.physical_keycode = ev.physical_keycode
                        k.pressed = on
                        Input.parse_input_event(k)
                        return

func _physics_process(delta: float) -> void:
        t += delta
        _hold_right(true)
        if fmod(t, 0.25) < delta:
                var p := game.player
                print("%.2f x=%.0f vx=%.0f vy=%.0f facing=%d nearest=%s" % [
                        t, p.global_position.x, p.velocity.x, p.velocity.y, p.facing,
                        str(game._nearest_interactable.instance_key) if game._nearest_interactable else "-"])
        if game.dialogue_box.active:
                game.dialogue_box.chars_shown = 99999
                game.dialogue_box.advance()
        if t > 22.0:
                get_tree().quit()
