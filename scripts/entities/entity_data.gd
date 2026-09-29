## EntityData — one entity's true record. Loaded from data/entities.json,
## mutated by OBSERVE modification, persisted through property_overrides.
class_name EntityData
extends RefCounted

var key: String = ""            # definition key, e.g. "DOOR_029"
var display: String = ""        # target label shown by OBSERVE
var id_number: String = ""      # e.g. "ENTITY_0142"
var type: String = "UNKNOWN"
var state: String = "UNKNOWN"
var purpose: String = "\u2014"
var memory: String = ""
var belief: float = 0.0
var notes: Array = []           # extra readout lines (contextual)
var properties: Dictionary = {} # name -> {value,type,modifiable,cost,options,hidden_until}

static func from_def(key: String, def: Dictionary) -> EntityData:
        var d := EntityData.new()
        d.key = key
        d.display = String(def.get("display", key))
        d.id_number = String(def.get("id_number", ""))
        d.type = String(def.get("type", "UNKNOWN"))
        d.state = String(def.get("state", "UNKNOWN"))
        d.purpose = String(def.get("purpose", "\u2014"))
        d.memory = String(def.get("memory", ""))
        d.belief = float(def.get("belief", 0.0))
        d.notes = def.get("notes", [])
        var props: Dictionary = {}
        for prop_name in def.get("properties", {}).keys():
                var src: Dictionary = def["properties"][prop_name]
                var p: Dictionary = {
                        "value": src.get("value"),
                        "type": String(src.get("type", "text")),
                        "modifiable": bool(src.get("modifiable", false)),
                        "cost": int(src.get("cost", 0)),
                }
                if src.has("options"):
                        p["options"] = src["options"]
                if src.has("hidden_until"):
                        p["hidden_until"] = String(src["hidden_until"])
                props[prop_name] = p
        d.properties = props
        return d

# ------------------------------------------------------------------ readout
func visible_properties(stage: int, flags: Dictionary) -> Array:
        ## Returns [{name, value, sealed, modifiable, cost, selected_value}]
        var out: Array = []
        for prop_name in properties.keys():
                var p: Dictionary = properties[prop_name]
                var sealed := _is_sealed(p, stage, flags)
                out.append({
                        "name": prop_name,
                        "value": p["value"],
                        "sealed": sealed,
                        "modifiable": bool(p["modifiable"]) and not sealed,
                        "cost": int(p["cost"]),
                })
        return out

func _is_sealed(p: Dictionary, stage: int, flags: Dictionary) -> bool:
        if not p.has("hidden_until"):
                return false
        return not _condition_holds(String(p["hidden_until"]), stage, flags)

static func _condition_holds(cond: String, stage: int, flags: Dictionary, consistency := -1) -> bool:
        ## Tiny condition language: "stage>=N" | "stage<=N" | "flag:x" | "!flag:x"
        ## | "consistency<=N" | "consistency>=N"
        if cond.is_empty():
                return true
        if cond.begins_with("stage>="):
                return stage >= int(cond.substr(8))
        if cond.begins_with("stage<="):
                return stage <= int(cond.substr(8))
        if cond.begins_with("consistency>="):
                return consistency >= 0 and consistency >= int(cond.substr(15))
        if cond.begins_with("consistency<="):
                return consistency >= 0 and consistency <= int(cond.substr(15))
        if cond.begins_with("flag:"):
                return bool(flags.get(cond.substr(5), false))
        if cond.begins_with("!flag:"):
                return not bool(flags.get(cond.substr(6), false))
        return false

# ------------------------------------------------------------------ modification
func next_value(prop_name: String) -> Variant:
        ## The value MODIFY would write: bool toggles; enums cycle; numbers step.
        var p: Dictionary = properties.get(prop_name, {})
        if p.is_empty():
                return null
        match String(p["type"]):
                "bool":
                        return not bool(p["value"])
                "enum":
                        var options: Array = p.get("options", [])
                        var idx := options.find(p["value"])
                        return options[(idx + 1) % options.size()] if options.size() > 0 else p["value"]
                "number":
                        return float(p["value"]) + 1.0
        return p["value"]

func apply_modification(prop_name: String, new_value: Variant) -> Variant:
        var old: Variant = properties[prop_name]["value"]
        properties[prop_name]["value"] = new_value
        return old

func set_state(new_state: String) -> void:
        state = new_state

# ------------------------------------------------------------------ serialization
func to_override() -> Dictionary:
        var props: Dictionary = {}
        for prop_name in properties.keys():
                props[prop_name] = properties[prop_name]["value"]
        return {"state": state, "props": props}

func apply_override(ov: Dictionary) -> void:
        if ov.has("state"):
                state = String(ov["state"])
        if ov.has("props"):
                for prop_name in ov["props"].keys():
                        if properties.has(prop_name):
                                properties[prop_name]["value"] = ov["props"][prop_name]
