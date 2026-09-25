## Main — boot: fonts, game, title. One scene, one root, everything in code.
extends Node

var game: Game
var title: TitleScreen
var _title_layer: CanvasLayer

func _ready() -> void:
        E0.load_fonts()
        game = Game.new()
        game.name = "Game"
        add_child(game)
        _title_layer = CanvasLayer.new()
        _title_layer.layer = 80
        add_child(_title_layer)
        title = TitleScreen.new()
        title.new_game_requested.connect(_on_new_game)
        title.continue_requested.connect(_on_continue)
        title.hide_screen()
        _title_layer.add_child(title)
        _show_title()
        AudioManager.play_music("title")
        AudioManager.play_ambient("wind", 0.18)

func _show_title() -> void:
        game.set_active(false)
        title.show_screen()
        AudioManager.play_music("title")

func _on_new_game() -> void:
        title.hide_screen()
        game.set_active(true)
        game.new_game()
        FX.fade_in(0.6)

func _on_continue() -> void:
        title.hide_screen()
        game.set_active(true)
        game.continue_from_save()
        FX.fade_in(0.6)

func return_to_title() -> void:
        game.set_active(false)
        game.teardown()
        _show_title()
