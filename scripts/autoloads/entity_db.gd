## EntityDB — data-driven entity registry. Loads data/entities.json, mints
## per-instance EntityData, keeps the live registry OBSERVE cycles through,
## executes modifications (charging consistency), and persists overrides.
extends Node

var defs: Dictionary = {}            # key -> definition dict
var live: Dictionary = {}            # instance_key -> EntityNode (weak usage)
var overrides: Dictionary = {}       # key -> EntityData.to_override()
var _instance_counter := 100

func _ready() -> void:
	var txt := FileAccess.get_file_as_string("res://data/entities.json")
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) == TYPE_DICTIONARY:
		defs = parsed
	else:
		push_error("EntityDB: data/entities.json failed to parse")

# ------------------------------------------------------------------ definitions
func has_def(key: String) -> bool:
	return defs.has(key)

func get_def(key: String) -> Dictionary:
	return defs.get(key, {})

## Mint an EntityData for a world instance. Applies any persisted override.
func mint(key: String, instance_key: String = "") -> EntityData:
	var use_key := instance_key if not instance_key.is_empty() else key
	var d := EntityData.from_def(use_key, defs.get(key, {}))
	if defs.has(key) and not defs[key].get("dynamic_id", false):
		pass
	elif defs.has(key):
		d.id_number = _mint_id()
	d.display = d.display.replace("{SELF}", use_key)
	if overrides.has(use_key):
		d.apply_override(overrides[use_key])
	return d

func _mint_id() -> String:
	_instance_counter += 7
	return "ENTITY_0" + str(_instance_counter)

# ------------------------------------------------------------------ live registry
func register(node) -> void:
	var key: String = node.instance_key
	if key.is_empty():
		return
	live[key] = node
	EventBus.entity_registered.emit(key)

func unregister(node) -> void:
	for k in live.keys():
		if live[k] == node:
			live.erase(k)
			EventBus.entity_unregistered.emit(k)
			return

func live_nodes() -> Array:
	return live.values()

# ------------------------------------------------------------------ modification
func modify(node, prop_name: String) -> bool:
	## Perform the OBSERVE modification on a live entity. Charges consistency,
	## emits property_modified, stores the override. Returns success.
	var data: EntityData = node.data
	if data == null or not data.properties.has(prop_name):
		return false
	var p: Dictionary = data.properties[prop_name]
	if not bool(p.get("modifiable", false)):
		return false
	var new_value: Variant = data.next_value(prop_name)
	var old: Variant = data.apply_modification(prop_name, new_value)
	if prop_name == "state":
		data.set_state(str(new_value))
	var cost := int(p.get("cost", 0))
	overrides[node.instance_key] = data.to_override()
	GameState.stats["edits"] += 1
	EventBus.property_modified.emit(node.instance_key, prop_name, old, new_value)
	if cost > 0:
		GameState.spend(cost, "%s: %s" % [node.instance_key, prop_name])
	if node.has_method("on_modified"):
		node.on_modified(prop_name, old, new_value)
	return true

# ------------------------------------------------------------------ persistence
func export_overrides() -> Dictionary:
	return overrides.duplicate(true)

func import_overrides(data: Dictionary) -> void:
	overrides = data.duplicate(true) if data != null else {}
