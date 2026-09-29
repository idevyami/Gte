## EventBus — the 21-signal spine (Systems Bible §9). Exactly 21. Adding one
## requires a bible amendment; route extra telemetry through existing signals.
extends Node

# Player (4)
signal player_health_changed(hp: int, max_hp: int)
signal player_died
signal player_respawned(room: String, position: Vector2)
signal observe_toggled(active: bool)

# Consistency (4)
signal consistency_changed(value: int)
signal consistency_stage_changed(stage: int)
signal consistency_spent(amount: int, reason: String)
signal correction_spawned(position: Vector2)

# Entities (4)
signal entity_registered(entity_id: String)
signal entity_unregistered(entity_id: String)
signal observe_target_changed(entity_id: String)
signal property_modified(entity_id: String, prop: String, old_value: Variant, new_value: Variant)

# World (4)
signal room_entered(room_id: String)
signal room_exited(room_id: String)
signal flag_set(flag: String, value: bool)
signal anchor_used(anchor_id: String, room: String)

# Narrative (5)
signal dialogue_started(speaker: String)
signal dialogue_finished(key: String)
signal fragment_found(fragment_id: String)
signal belief_changed(source: String, amount: float)
signal boss_defeated(entity_id: String)
