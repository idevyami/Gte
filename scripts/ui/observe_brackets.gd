## ObserveBrackets — world-space corner brackets around every observable
## entity in range. The selected target burns gold; the rest wait in cyan.
class_name ObserveBrackets
extends Node2D

var game
var _pulse := 0.0

func _ready() -> void:
        z_index = 40

func _process(delta: float) -> void:
        _pulse += delta
        queue_redraw()

func _draw() -> void:
        if game == null or not game.observe_active:
                return
        var cam: CameraRig = game.camera
        var cam_pos: Vector2 = cam.global_position if cam else Vector2.ZERO
        var vp_half := Vector2(700, 420)
        var i := 0
        for target in game.observe_targets:
                if target == null or not is_instance_valid(target):
                        continue
                var anchor: Vector2 = target.observe_anchor()
                # only bracket entities near the view
                if absf(anchor.x - cam_pos.x) > vp_half.x + 80.0 or absf(anchor.y - cam_pos.y) > vp_half.y + 120.0:
                        i += 1
                        continue
                var size: Vector2 = target.bracket_size()
                var selected: bool = i == game.observe_idx
                var col := E0.GOLD if selected else Color(E0.CYAN.r, E0.CYAN.g, E0.CYAN.b, 0.55)
                var a := 0.55 + 0.25 * sin(_pulse * 4.0) if selected else 0.5
                var col2 := Color(col.r, col.g, col.b, a)
                var l := 12.0
                var t := 2.0
                var w2 := size.x * 0.5
                var h2 := size.y * 0.5
                # four corners
                for corner in [Vector2(-w2, -h2), Vector2(w2, -h2), Vector2(w2, h2), Vector2(-w2, h2)]:
                        var dir_x := 1.0 if corner.x < 0 else -1.0
                        var dir_y := 1.0 if corner.y < 0 else -1.0
                        draw_line(anchor + corner, anchor + corner + Vector2(dir_x * l, 0), col2, t)
                        draw_line(anchor + corner, anchor + corner + Vector2(0, dir_y * l), col2, t)
                if selected:
                        # tag above the bracket
                        if E0.mono:
                                draw_string(E0.mono, anchor + Vector2(-w2, -h2 - 8.0), String(target.data.display),
                                        HORIZONTAL_ALIGNMENT_LEFT, -1, 11, E0.GOLD)
                i += 1
