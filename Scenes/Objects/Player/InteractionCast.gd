extends RayCast3D
@onready var player = $"../../.."

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var obj = self.get_collider()
	
	if self.is_colliding():
		if obj.is_in_group("interactable") && obj.canInteract:
			$InteractionGUI.show()
			if Input.is_action_just_pressed("punch"):
				obj.interact()
				
		elif obj.is_in_group("climbable"):
			$InteractionGUI.show()
			if Input.is_action_just_pressed("grapple"):
				player.direction = -get_collision_normal()
				player.velocity.y = player.jumpvelocity
			
		else:
			$InteractionGUI.hide()
	else:
		$InteractionGUI.hide()
