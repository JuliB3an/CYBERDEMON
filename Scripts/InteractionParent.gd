class_name InteractableObject
extends Node3D

@export var canInteract : bool = true
@export var interactDialoge = ""

func _ready():
	add_to_group("interactable")
	pass

func interact():
	print(interactDialoge)
