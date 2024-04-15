extends Sprite3D

var hitscale = 1.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	hitscale -= delta*3.5
	scale = Vector3(4, 4, 4) * hitscale
	if hitscale <= 0:
		queue_free()
