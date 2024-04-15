extends Decal

func _ready():
	modulate = Color(0, 0, 0)

func _on_timer_timeout():
	queue_free()
