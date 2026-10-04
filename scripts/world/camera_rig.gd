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

# idle micro-drift: a held frame still breathes — the world is never a
# photograph. Ramps in after 2.5s of stillness, releases on any movement,
# halves while zoomed (observe lean-in stays composed)
var _idle_t := 0.0
var _drift_t := 0.0

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
        # idle micro-drift (AFTER the deadzone — otherwise the deadzone
        # freezes it back out); a slow two-axis sway, sub-3px, eased in
        if vel.length() < 8.0:
                _idle_t = minf(_idle_t + delta, 2.5)
        else:
                _idle_t = maxf(_idle_t - delta * 3.0, 0.0)
        _drift_t += delta
        var drift_k := (_idle_t / 2.5) * (_idle_t / 2.5)
        var damp := 1.0 if z < 1.02 else 0.5
        _desired += Vector2(sin(_drift_t * 0.35) * 2.4, cos(_drift_t * 0.27) * 1.5) * drift_k * damp
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
