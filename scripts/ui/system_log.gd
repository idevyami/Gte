## SystemLog — STAMPED CITATIONS: the world files its objections as slips of
## census paper that STRIKE into the frame (an inked die lands at 1.4x and
## settles to 1.0 with a wobble), each slip torn, grain-ruled, a hair askew.
## Danger citations carry a pressed crimson seal-fragment; the quiet ones
## arrive as pencil. They dry and are gone.
## WB-9 law: system messages are physical citations, not floating text.
class_name SystemLog
extends Control

var entries: Array = []   # {text, shown, t, color, mode, stamp_t, rot}
var _had_entries := false
const MAX_ENTRIES := 4
# draw-state accessors (smoke pins the laws)
var last_stamp_scales: Array = []
var last_jitter_rots: Array = []

const STRIKE_TIME := 0.16

func _ready() -> void:
        set_anchors_preset(Control.PRESET_FULL_RECT)
        mouse_filter = Control.MOUSE_FILTER_IGNORE
        EventBus.consistency_stage_changed.connect(_on_stage)
        EventBus.correction_spawned.connect(func(_p): push("CORRECTION FILED.", "warn"))

func push(text: String, mode := "system") -> void:
        var col := E0.CYAN
        match mode:
                "warn":
                        col = E0.GOLD
                "danger":
                        col = E0.CRIMSON
                "quiet":
                        col = E0.DIM
        # each slip is its own physical thing: its own skew, its own strike
        var rng := RandomNumberGenerator.new()
        rng.seed = hash(text + str(Time.get_ticks_msec()))
        entries.append({
                "text": text, "shown": 0, "t": 0.0, "color": col, "mode": mode,
                "stamp_t": 0.0,
                "rot": (rng.randf() - 0.5) * 0.045,
                "xoff": (rng.randf() - 0.5) * 10.0,
        })
        while entries.size() > MAX_ENTRIES:
                entries.pop_front()

func _on_stage(stage: int) -> void:
        var names := ["", "WHISPERS", "ENVIRONMENTAL INCONSISTENCIES", "NPC AWARENESS",
                "THE CENSOR HUNTS", "REALITY ACTIVELY HUNTS", "HIDDEN STRUCTURES"]
        push("CONSISTENCY %03d%% — STAGE %d: %s" % [GameState.consistency, stage, names[clampi(stage, 1, 6)]],
                "danger" if stage >= 4 else "warn")
        FX.stage_transition_glitch(stage)

## The strike's scale over its life: 1.4 -> 1.0 with a settle wobble.
static func stamp_scale(stamp_t: float) -> float:
        var k := clampf(stamp_t / STRIKE_TIME, 0.0, 1.0)
        var settle := 1.0 + (1.0 - k) * 0.4
        # a dying wobble right after impact
        if k >= 1.0:
                var w := clampf((stamp_t - STRIKE_TIME) / 0.22, 0.0, 1.0)
                settle += sin(w * PI * 2.5) * 0.03 * (1.0 - w)
        return settle

func _process(delta: float) -> void:
        var dirty := false
        for e in entries:
                e["t"] += delta
                e["stamp_t"] += delta
                if e["t"] < 6.0:
                        e["shown"] = mini(int(ceil(60.0 * delta)) + int(e["shown"]), String(e["text"]).length())
                dirty = true
        for i in range(entries.size() - 1, -1, -1):
                if entries[i]["t"] > 7.0:
                        entries.remove_at(i)
                        dirty = true
        if dirty or (_had_entries and entries.is_empty()):
                queue_redraw()
        _had_entries = not entries.is_empty()

func _draw() -> void:
        var vp := get_viewport_rect().size
        var y := 64.0
        if GameState.boss_defeated == false and _boss_active():
                y = 92.0
        last_stamp_scales = []
        last_jitter_rots = []
        for e in entries:
                var text: String = e["text"].substr(0, int(e["shown"]))
                var alpha := 1.0
                if e["t"] > 6.0:
                        alpha = clampf(1.0 - (e["t"] - 6.0), 0.0, 1.0)
                if E0.mono:
                        var w := E0.mono.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
                        var x := (vp.x - w) * 0.5 + float(e["xoff"])
                        var rot := float(e["rot"])
                        var scale := stamp_scale(float(e["stamp_t"]))
                        last_stamp_scales.append(scale)
                        last_jitter_rots.append(rot)
                        # the slip: a torn paper chip, stamped-in about its own center
                        var chip := Rect2(x - 10, y - 14, w + 20, 20)
                        var pivot := chip.get_center()
                        draw_set_transform(pivot - Vector2(scale, scale) * pivot, rot, Vector2(scale, scale))
                        # shadow beneath the chip
                        draw_rect(Rect2(chip.position + Vector2(2, 3), chip.size), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.5 * alpha))
                        # the paper: aged slip stock (quiet ones are pencil-pale)
                        var stock := 0.62 if e["mode"] == "quiet" else 0.78
                        draw_rect(chip, Color(E0.PARCH.r * stock, E0.PARCH.g * stock, E0.PARCH.b * stock, 0.9 * alpha))
                        # torn top edge — the slip was ripped from the roll
                        var rng := RandomNumberGenerator.new()
                        rng.seed = hash(String(e["text"]))
                        var tx := chip.position.x
                        while tx < chip.end.x:
                                var tw := 6.0 + rng.randf() * 10.0
                                draw_rect(Rect2(Vector2(tx, chip.position.y + 1.5), Vector2(minf(tw, chip.end.x - tx), 3.0)), Color(E0.PARCH.r * stock * 0.82, E0.PARCH.g * stock * 0.82, E0.PARCH.b * stock * 0.82, 0.9 * alpha))
                                tx += tw
                        # stamp-ink text — the die's pressure varies
                        var col: Color = e["color"]
                        var ink := Color(col.r * 0.55, col.g * 0.55, col.b * 0.55, alpha)
                        UICraft.stamp_text(self, E0.mono, Vector2(x, y), text, ink, 13, rot * 0.4, 13)
                        # danger slips carry a pressed crimson seal-fragment at the right
                        if e["mode"] == "danger":
                                UICraft.wax_seal(self, Vector2(chip.end.x - 12.0, chip.get_center().y), 5.5,
                                        Color(E0.CRIMSON.r * 0.7, E0.CRIMSON.g * 0.7, E0.CRIMSON.b * 0.7, alpha), 4, clampf(float(e["stamp_t"]) / STRIKE_TIME, 0.2, 1.0))
                        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
                y += 26.0

func _boss_active() -> bool:
        var game := get_tree().get_first_node_in_group("game")
        return game != null and game.get("boss") != null
