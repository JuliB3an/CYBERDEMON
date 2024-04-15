extends MeshInstance3D

var alpha = 1.0

@onready var hit_place = $HitPlace

func _ready():
	var dup_mat = material_override.duplicate()
	material_override = dup_mat

func init(pos1, pos2):
	var drawMesh = ImmediateMesh.new()
	mesh = drawMesh
	drawMesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, material_override)
	drawMesh.surface_add_vertex(pos1)
	drawMesh.surface_add_vertex(pos2)
	drawMesh.surface_end()
	hit_place.global_translate(pos2)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	alpha -= delta*2.5
	material_override.albedo_color.a = alpha


func _on_timer_timeout():
	queue_free()
