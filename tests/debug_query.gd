extends Node2D
var area: Area2D
var t := 0.0
func _ready() -> void:
	area = Area2D.new()
	area.collision_layer = 5
	area.collision_mask = 0
	var s := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 22.0
	s.shape = c
	area.add_child(s)
	area.position = Vector2(100, 0)
	add_child(area)
func _physics_process(delta: float) -> void:
	t += delta
	if t < 0.5:
		return
	t = 0.0
	var space := get_world_2d().direct_space_state
	var params := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 46.0
	params.shape = circle
	params.transform = Transform2D(0.0, Vector2(80, 0))
	params.collision_mask = 5
	params.collide_with_areas = true
	params.collide_with_bodies = false
	var hits := space.intersect_shape(params, 8)
	print("hits=", hits.size(), " area_layer=", area.collision_layer, " area_pos=", area.global_position)
	for h in hits:
		print("  collider=", h.get("collider"))
	get_tree().quit()
