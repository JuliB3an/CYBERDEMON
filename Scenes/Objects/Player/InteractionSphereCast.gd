extends RayCast3D
@onready var interaction_sphere = $InteractionSphere

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if self.is_colliding():
		interaction_sphere.global_position = self.get_collision_point()
	else:
		interaction_sphere.position = Vector3(0.0, 0.0, 0.8)
