## Main — boot: fonts, game, title, and the global options overlay. One scene,
## one root, everything in code.
extends Node

var game: Game
var title: TitleScreen
var options: OptionsScreen
var _title_layer: CanvasLayer
var _options_layer: CanvasLayer

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
        _options_layer = CanvasLayer.new()
        _options_layer.layer = 90
        add_child(_options_layer)
        options = OptionsScreen.new()
        options.closed.connect(_on_options_closed)
        options.save_erased.connect(func(): title._rebuild_menu())
        _options_layer.add_child(options)
        title.options_requested.connect(func(): options.open("title"))
        game.options_requested.connect(func(): options.open("pause"))
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

func _on_options_closed() -> void:
        # returning from options to the pause context: the pause menu is still
        # up underneath — nothing to do. From title: the menu may need its
        # CONTINUE row rebuilt if a save was erased inside options.
        pass

func return_to_title() -> void:
        game.set_active(false)
        game.teardown()
        _show_title()
