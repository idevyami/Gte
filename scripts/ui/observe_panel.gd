## ObservePanel — THE CENSUS LEDGER: the readout is a page of the census's
## own record book — parchment stock, ruled fields (no dot leaders), values
## in dark ink, modifiable properties in gold ink, SEALED rows hidden under
## pressed wax that thins as reality does. The census cross stamps the
## header; receipts strike in as stamped chits.
## WB-9 law: the data panel is a physical ledger page.
class_name ObservePanel
extends Control

var game
var receipt := ""          # last modification receipt lines
var receipt_t := 0.0
# draw-state accessors (smoke pins the laws)
var last_seal_count := 0
var last_ruling_count := 0
var ledger_page := true

func _ready() -> void:
        set_anchors_preset(Control.PRESET_FULL_RECT)
        mouse_filter = Control.MOUSE_FILTER_IGNORE
        visible = false

func set_game(p_game) -> void:
        game = p_game

func show_receipt(lines: Array) -> void:
        receipt = "\n".join(PackedStringArray(lines))
        receipt_t = 3.2

func _process(delta: float) -> void:
        if receipt_t > 0.0:
                receipt_t -= delta
        visible = game != null and game.observe_active
        if visible:
                queue_redraw()

## Ink colors for the ledger: dark archival ink on parchment.
const INK := Color(0.20, 0.16, 0.12, 0.95)
const INK_DIM := Color(0.34, 0.29, 0.23, 0.8)
const INK_GOLD := Color(0.48, 0.36, 0.13, 0.95)
const INK_SEAL := Color(0.42, 0.27, 0.24, 0.9)

func _draw() -> void:
        if game == null or not game.observe_active:
                return
        if game.observe_targets.is_empty():
                return
        var target = game.observe_targets[game.observe_idx]
        if target == null or not is_instance_valid(target):
                return
        var data: EntityData = target.data
        var vp := get_viewport_rect().size
        var w := 430.0
        var h := 470.0
        var x := vp.x - w - 24.0
        var y := 64.0
        last_seal_count = 0
        last_ruling_count = 0
        # the page: aged archive stock, grain, torn bottom, punched filing holes
        var page := Rect2(x, y, w, h)
        draw_rect(Rect2(page.position + Vector2(4, 6), page.size), Color(E0.VOID.r, E0.VOID.g, E0.VOID.b, 0.4))
        UICraft.parchment(self, page, "ledger_" + data.id_number, true, 5, 0.8)
        var pad := 18.0
        var cx := x + pad + 8.0
        var cy := y + 28.0
        # header: the census cross strikes first, then the record's identity
        UICraft.wax_seal(self, Vector2(x + w - 34.0, y + 26.0), 12.0, Color(E0.BLOOD.r * 0.85 + 0.1, E0.BLOOD.g * 0.85, E0.BLOOD.b * 0.85, 1.0), 4, 1.0)
        if E0.mono_bold:
                UICraft.stamp_text(self, E0.mono_bold, Vector2(cx, cy), "> OBSERVE \u2014 TARGET: " + data.display, Color(E0.BLOOD.r + 0.1, E0.BLOOD.g + 0.08, E0.BLOOD.b + 0.08, 0.92), 13, -0.008, 1)
        cy += 26.0
        UICraft.ruling(self, Vector2(cx - 6.0, cy - 6.0), Vector2(x + w - 56.0, cy - 6.0), true)
        last_ruling_count += 1
        # ruled fields — the ledger's law: every value sits on a ruled line
        var props := data.visible_properties(GameState.stage, GameState.flags)
        var target_props: Array = []
        for p in props:
                target_props.append(p)
        _field("ID", data.id_number, cy, cx, w - pad * 2.0); cy += 22.0
        _field("TYPE", data.type, cy, cx, w - pad * 2.0); cy += 22.0
        _field("STATE", data.state, cy, cx, w - pad * 2.0); cy += 22.0
        # properties block
        if E0.mono:
                UICraft.stamp_text(self, E0.mono, Vector2(cx, cy), "PROPERTIES", INK_DIM, 12, 0.0, 2)
        cy += 20.0
        var mod_idx := 0
        for p in target_props:
                var is_selected: bool = p["modifiable"] and mod_idx == game.observe_prop_idx
                var line_col := INK
                var val_text := _fmt(p["value"])
                var sealed: bool = p["sealed"]
                if sealed:
                        line_col = INK_DIM
                        val_text = ""
                elif p["modifiable"]:
                        line_col = INK_GOLD
                if is_selected:
                        line_col = Color(0.10, 0.08, 0.06, 0.98)
                if E0.mono:
                        var sel_arrow := "\u25b8 " if is_selected else "   "
                        var cost_text := ""
                        if p["modifiable"] and int(p["cost"]) > 0:
                                cost_text = "  [\u2212%d]" % int(p["cost"])
                        var preview := ""
                        if is_selected:
                                var nv = data.next_value(String(p["name"]))
                                if String(_fmt(nv)) != _fmt(p["value"]):
                                        preview = "  \u2192 " + _fmt(nv)
                        var line := sel_arrow + String(p["name"]) + "=" + val_text + preview + cost_text
                        draw_string(E0.mono, Vector2(cx + 8.0, cy), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, line_col)
                # the row's ruling — the ledger line under every property
                UICraft.ruling(self, Vector2(cx + 2.0, cy + 5.0), Vector2(x + w - pad - 10.0, cy + 5.0))
                last_ruling_count += 1
                # sealed rows: the value hides under pressed wax
                if sealed:
                        UICraft.wax_seal(self, Vector2(x + w - pad - 40.0, cy - 4.0), 7.0,
                                Color(E0.BLOOD.r * 0.8 + 0.08, E0.BLOOD.g * 0.8, E0.BLOOD.b * 0.8, 0.96), 4, 1.0)
                        last_seal_count += 1
                if p["modifiable"]:
                        mod_idx += 1
                cy += 19.0
        cy += 4.0
        _field("PURPOSE", "\u201c%s\u201d" % data.purpose, cy, cx, w - pad * 2.0, true); cy += 22.0
        if not data.memory.is_empty():
                _field("MEMORY", data.memory, cy, cx, w - pad * 2.0, true); cy += 22.0
        if data.belief > 0.0:
                _field("BELIEF", "%.0f" % data.belief, cy, cx, w - pad * 2.0); cy += 22.0
                # belief as a mercury line: inked gauge on the ruling
                draw_rect(Rect2(cx + 8.0, cy - 12.0, 160.0, 6), Color(0.3, 0.26, 0.2, 0.5))
                draw_rect(Rect2(cx + 8.0, cy - 12.0, 160.0 * clampf(data.belief / 100.0, 0.0, 1.0), 6), INK_GOLD)
        for note in data.notes:
                if E0.mono:
                        draw_string(E0.mono, Vector2(cx + 8.0, cy), String(note), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, INK_DIM)
                cy += 17.0
        # receipt: a stamped chit over the page's foot — the world's answer is
        # FILED loudly: bright stock, heavy ink, no dot-leader mush
        if receipt_t > 0.0 and not receipt.is_empty():
                if E0.mono:
                        var ry := y + h - 108.0
                        var chit := Rect2(cx - 4.0, ry - 18.0, w - pad * 2.0, 92.0)
                        draw_rect(chit, Color(E0.PARCH.r * 0.88, E0.PARCH.g * 0.88, E0.PARCH.b * 0.86, 0.97 * clampf(receipt_t, 0.0, 1.0)))
                        draw_rect(chit, Color(E0.BLOOD.r + 0.05, E0.BLOOD.g + 0.03, E0.BLOOD.b, 0.4), false, 1.0)
                        var yy := ry
                        for ln in receipt.split("\n"):
                                var shown_ln := ln
                                while shown_ln.begins_with("."):
                                        shown_ln = shown_ln.substr(1)
                                shown_ln = "  " + shown_ln
                                var col := Color(0.14, 0.11, 0.08, 0.97)
                                if shown_ln.contains("CONSISTENCY"):
                                        col = Color(E0.BLOOD.r + 0.2, E0.BLOOD.g + 0.14, E0.BLOOD.b + 0.14, 0.97)
                                elif shown_ln.begins_with("  >"):
                                        col = Color(0.10, 0.26, 0.27, 0.97)
                                elif shown_ln.contains("ACK"):
                                        col = Color(0.42, 0.30, 0.10, 0.97)
                                draw_string(E0.mono, Vector2(cx + 6.0, yy), shown_ln, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(col.r, col.g, col.b, clampf(receipt_t, 0.0, 1.0)))
                                UICraft.ruling(self, Vector2(cx + 2.0, yy + 5.0), Vector2(chit.end.x - 8.0, yy + 5.0))
                                yy += 19.0
        # footer help: pencil marginalia (bright enough to squint-test)
        if E0.mono:
                var foot := "TAB: NEXT / EXIT   W/S: SELECT   E: MODIFY"
                draw_string(E0.mono, Vector2(cx, y + h - 18.0), foot, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.45, 0.40, 0.32, 0.88))

func _field(name: String, value: String, y: float, x: float, width: float, small := false) -> void:
        if E0.mono == null:
                return
        var size := 12 if small else 12
        draw_string(E0.mono, Vector2(x, y), name, HORIZONTAL_ALIGNMENT_LEFT, -1, size, INK_DIM)
        var lw := E0.mono.get_string_size(name + "  ", HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
        # long values are trimmed by the census's own economy — an ellipsis, never
        # a hard slice past the ruling (the ledger never bleeds off the page)
        var vmax := width * 0.54
        var v := value
        while E0.mono.get_string_size(v, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > vmax and v.length() > 4:
                v = v.substr(0, v.length() - 4) + "\u2026"
        draw_string(E0.mono, Vector2(x + width * 0.40, y), v, HORIZONTAL_ALIGNMENT_LEFT, -1, size, INK)
        # the ruling under the field — the ledger's structure
        UICraft.ruling(self, Vector2(x, y + 5.0), Vector2(x + width * 0.96, y + 5.0))
        last_ruling_count += 1

func _fmt(v: Variant) -> String:
        match typeof(v):
                TYPE_BOOL:
                        return "true" if v else "false"
                TYPE_INT, TYPE_FLOAT:
                        return str(v)
                _:
                        return String(v)
