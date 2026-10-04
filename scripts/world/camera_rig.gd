## CameraRig — cinematic 2D camera: smoothed follow, lookahead, room-bounds
## clamp, FX shake, eased zoom punches (observe leans IN, death looms).
## Subtle shake only: the world is wrong, not the camera.
class_name CameraRig
extends Camera2D

var target: Node2D
var room_size := Vector2(1280, 720)
var smoothing := 7.0
var lookahead := 60.0
var _desired := Vector2.ZERO

# zoom punch: eases toward zoom_target; zoom speed adapts (observe is a slow
# lean, death is a slower loom, release springs back quicker)
var zoom_target := 1.0
var zoom_speed := 3.0

func setup(p_target: Node2D, p_room_size: Vector2) -> void:
        target = p_target
        room_size = p_room_size
        position = target.global_position
        zoom = Vector2.ONE
        zoom_target = 1.0
        make_current()

func punch_zoom(p_target: float, p_speed := 3.0) -> void:
        ## Cinematic zoom: 1.0 is neutral; >1 leans in.
        zoom_target = maxf(0.5, p_target)
        zoom_speed = maxf(0.5, p_speed)

func _process(delta: float) -> void:
        # eased zoom (Vector2 zoom; keep it uniform)
        var z := zoom.x
        z = lerpf(z, zoom_target, 1.0 - exp(-zoom_speed * delta))
        zoom = Vector2(z, z)
        if target == null:
                return
        var vel := Vector2.ZERO
        if "velocity" in target:
                vel = target.velocity
        var look := Vector2(clampf(vel.x * 0.22, -lookahead, lookahead), clampf(vel.y * 0.08, -34.0, 34.0))
        _desired = target.global_position + look
        # VERTICAL DEADZONE: small hops and falls never yank the frame — the
        # camera only commits vertically once the target truly changes height
        # (a climb, a drop, a platform ride). Horizontal stays fully smoothed.
        var dy := _desired.y - position.y
        if absf(dy) < 84.0:
                _desired.y = position.y
        position = position.lerp(_desired, 1.0 - exp(-smoothing * delta))
        # clamp inside room bounds (viewport 1280x720)
        var half := Vector2(640, 360)
        var min_x := half.x
        var max_x := room_size.x - half.x
        var min_y := half.y
        var max_y := room_size.y - half.y
        if room_size.x <= 1280.0:
                position.x = room_size.x * 0.5
        else:
                position.x = clampf(position.x, min_x, max_x)
        if room_size.y <= 720.0:
                position.y = room_size.y * 0.5
        else:
                position.y = clampf(position.y, min_y, max_y)
        # shake is applied as offset, never rotation
        offset = FX.get_shake_offset()
