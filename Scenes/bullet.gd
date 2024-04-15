extends RigidBody3D

var debugHitpoint = preload("res://Scenes/Hitpoint.tscn")
var hit_place = preload("res://Scenes/hit_place.tscn")
var damage: float = 0

func _on_body_entered(body):
	if body.is_in_group("Target") && body.has_method("hitSuccessful"):
		body.hitSuccessful(damage)
	
	var world = get_tree().get_root()
	
	var collisionPoint = debugHitpoint.instantiate()
	world.add_child(collisionPoint)
	collisionPoint.global_translate(global_position)
	
	collisionPoint = hit_place.instantiate()
	world.add_child(collisionPoint)
	collisionPoint.global_translate(global_position)
	queue_free()


func _on_timer_timeout():
	queue_free()
