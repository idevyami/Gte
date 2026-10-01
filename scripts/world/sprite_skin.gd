## SpriteSkin — the painted-artwork layer for characters. Builds SpriteFrames
## at runtime from res://art/characters/<set>/ (pipeline-processed, palette-
## locked sprites). If the art is missing the owner keeps its procedural rig,
## which always remains available as the debug/fallback representation
## (F9 in-game toggles between painted art and procedural rig).
class_name SpriteSkin
extends AnimatedSprite2D

const RIM_SHADER := preload("res://art/shaders/rim.gdshader")

## Per-set rim-light tint: player warm bone, censor cold cyan, boss gold.
## [tint, strength, width] — width lets small actors (believers at the
## boss's feet) keep a readable edge without bloating the big silhouettes.
const RIM_TINTS := {
        "player": [Color(0.87, 0.82, 0.70), 0.55, 2.5],
        "oren": [Color(0.82, 0.78, 0.68), 0.40, 2.5],
        "penitent": [Color(0.72, 0.78, 0.85), 0.42, 2.5],
        "censor": [Color(0.50, 0.85, 0.86), 0.60, 2.5],
        "hollow": [Color(0.80, 0.76, 0.66), 0.38, 2.5],
        "null_children": [Color(0.62, 0.55, 0.80), 0.45, 2.5],
        "believers": [Color(0.86, 0.74, 0.52), 0.55, 3.2],
        "bound_martyr": [Color(0.86, 0.72, 0.36), 0.60, 2.5],
}

## One-shot animations (play through and hold the last frame).
const NO_LOOP := [
        "attack1", "attack2", "attack3", "death", "telegraph", "lunge",
        "strike", "interact", "p1_attack", "p2_attack", "p3_attack",
]
const DEFAULT_FPS := 6.0

static var _art_cache := {}

static func art_available(set_name: String) -> bool:
        return not discover_anims(set_name).is_empty()

static func discover_anims(set_name: String) -> Dictionary:
        ## { anim_name: [res:// frame paths in order] }
        if _art_cache.has(set_name):
                return _art_cache[set_name]
        var out: Dictionary = {}
        var dir_path := "res://art/characters/%s" % set_name
        if DirAccess.dir_exists_absolute(dir_path):
                var d := DirAccess.open(dir_path)
                if d:
                        var frames := {}
                        d.list_dir_begin()
                        var fn := d.get_next()
                        while fn != "":
                                if fn.ends_with(".png"):
                                        var base := fn.get_basename()
                                        var idx := base.rfind("_")
                                        if idx > 0:
                                                var anim := base.substr(0, idx)
                                                var ord := base.substr(idx + 1).to_int()
                                                if not frames.has(anim):
                                                        frames[anim] = []
                                                frames[anim].append([ord, dir_path + "/" + fn])
                                fn = d.get_next()
                        d.list_dir_end()
                        for anim in frames:
                                var lst: Array = frames[anim]
                                lst.sort_custom(func(a, b): return a[0] < b[0])
                                var paths: Array = []
                                for e in lst:
                                        paths.append(e[1])
                                out[anim] = paths
        _art_cache[set_name] = out
        return out

var skin_set := ""
var anim_fps: Dictionary = {}

func setup(p_set: String, p_fps: Dictionary = {}) -> bool:
        skin_set = p_set
        anim_fps = p_fps
        var anims := discover_anims(p_set)
        if anims.is_empty():
                return false
        var sf := SpriteFrames.new()
        var any_frame := false
        for anim in anims:
                sf.add_animation(anim)
                sf.set_animation_speed(anim, float(p_fps.get(anim, DEFAULT_FPS)))
                sf.set_animation_loop(anim, not NO_LOOP.has(anim))
                for path in anims[anim]:
                        var tex := load(path)
                        if tex:
                                sf.add_frame(anim, tex)
                                any_frame = true
        if not any_frame:
                return false
        sprite_frames = sf
        _apply_rim()
        return true

func _apply_rim() -> void:
        ## Rim light: the painted actors are dark against a dark city — a thin
        ## tinted edge (palette-locked per set) recovers their silhouettes.
        var rim: Array = RIM_TINTS.get(skin_set, [Color(0.81, 0.78, 0.72), 0.42, 2.5])
        var rim_w := float(rim[2]) if rim.size() > 2 else 2.5
        var mat := ShaderMaterial.new()
        mat.shader = RIM_SHADER
        mat.set_shader_parameter("rim_color", Color(rim[0]))
        mat.set_shader_parameter("rim_strength", float(rim[1]))
        mat.set_shader_parameter("rim_width", rim_w)
        material = mat

func pose(anim: String, speed := 1.0) -> void:
        if sprite_frames == null or not sprite_frames.has_animation(anim):
                return
        if sprite_frames.get_frame_count(anim) == 0:
                return
        if animation != anim:
                play(anim)
                _apply_anchor()
        elif not is_playing() and sprite_frames.get_animation_loop(anim):
                play(anim)   # looping anim stalled — resume
        set_speed_scale(maxf(0.05, speed))

func _apply_anchor() -> void:
        ## Frame canvases are bottom-center padded; rest the feet line on the
        ## node origin (characters draw upward in negative Y).
        if sprite_frames == null:
                return
        var tex := sprite_frames.get_frame_texture(animation, 0)
        if tex:
                offset = Vector2(0.0, -float(tex.get_height()) * 0.5)

func anim_finished() -> bool:
        return not is_playing()
