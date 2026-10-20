## WB-26 diagnostic — watch the act5 ward's live state on entry, the way
## the playthrough experienced it: does it hold? does it open? for whom?
extends Node

var game: Game
var t := 0.0
var log: FileAccess

func _trace(s: String) -> void:
        log.store_line(s)
        log.flush()
        print(s)

func _ready() -> void:
        log = FileAccess.open("/tmp/wb26_ward.txt", FileAccess.WRITE)
        var main_scene: PackedScene = load("res://main.tscn")
        var main = main_scene.instantiate()
        add_child(main)
        game = main.game
        game.new_game()
        game.load_room("act5")
        game._spawn_player_at(Vector2(120, 814))
        game.state = "playing"

func _physics_process(delta: float) -> void:
        t += delta
        if fmod(t, 0.5) < delta:
                var w = game.ward
                if w == null:
                        _trace("%.1f ward=null" % t)
                        return
                _trace("%.1f broken=%s passable=%s belief=%.0f chanters=%d/7 body_disabled=%s player_x=%.0f relic=%s joined=%s wardbroken_flag=%s" % [
                        t, str(w.broken), str(w.passable), w.belief_now(), w.chanter_count(),
                        str(w._body_shape.disabled), game.player.global_position.x,
                        str(GameState.has_flag(GameState.F_RELIQ_CARRIED)),
                        str(GameState.has_flag(GameState.F_JOINED_RITUAL)),
                        str(GameState.has_flag("ward_broken"))])
        if t > 8.0:
                # now walk the player into the ward like the playthrough did
                game.player.global_position = Vector2(1700, 814)
                game.player.velocity = Vector2(260, 0)
        if t > 14.0:
                _trace("FINAL player_x=%.0f (ward at 1830, exit at 1960)" % game.player.global_position.x)
                get_tree().quit()
