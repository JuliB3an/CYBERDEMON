extends Node3D

@onready var weapon_animator = $FPSRig/WeaponAnimator
@onready var muzzle = $FPSRig/Muzzle
@onready var bullet_trail = $FPSRig/bulletTrail
@onready var hitflash = $FPSRig/Muzzle/Hitflash
@onready var interaction_sphere_cast = $"../Eyes/AdditionalCameraRotations/Camera3D/InteractionSphereCast"

var debugHitpoint = preload("res://Scenes/Hitpoint.tscn")
var bulletRayLine = preload("res://Scenes/shootCast.tscn")

var currentWeapon = null
var weaponList = {}
var weaponIndex = 0
var weaponsHeld = []

enum {NULL, HITSCAN, PROJECTILE}

var justShot = 0

@export var wepResources: Array[Weapon_Resource]
@export var wepArray: Array[String]

func _ready():
	Initialize(wepArray)

func _input(event):
	if event.is_action_pressed('weaponup'):
		weaponIndex = min(weaponIndex+1, weaponsHeld.size()-1)
		ChangeWep(weaponIndex)
	
	if event.is_action_pressed('weapondown'):
		weaponIndex = max(weaponIndex-1, 0)
		ChangeWep(weaponIndex)

func _process(_delta):
	hitflash.hide()
	
	justShot = move_toward(justShot, 0, 1)
	match currentWeapon.auto:
		true:
			if Input.is_action_pressed('shoot'):
				Shoot()
		false:
			if Input.is_action_just_pressed('shoot'):
				justShot = 5
			
			if justShot > 0:
				Shoot()

func Initialize(_start_weapons: Array):
	for weapon in wepResources:
		weaponList[weapon.weaponName] = weapon
	
	for i in wepArray:
		weaponsHeld.push_back(i)
	
	ChangeWep(0)

#when swap to weapon, show self and do start-up. 
func Enter():
	get_node(currentWeapon.weaponPath).show()
	weapon_animator.play(currentWeapon.activateAnimation)

#hide all weapons, then set current weapon to the right weapon
func ChangeWep(id: int):
	for weapon in weaponsHeld:
		get_node(weaponList[weapon].weaponPath).hide()
	
	if currentWeapon != weaponList[weaponsHeld[id]]:
		currentWeapon = weaponList[weaponsHeld[id]]
		Enter()
	else:
		get_node(currentWeapon.weaponPath).show()

func Hide():
	weapon_animator.play(currentWeapon.awayAnimation, -1, 2)

func Shoot():
	var cameraCollision = Get_Camera_Collision()
	muzzle.look_at(cameraCollision)
	
	if !weapon_animator.is_playing():
		hitflash.show()
		weapon_animator.play(currentWeapon.shootAnimation, -1, currentWeapon.shootAnimSpeed)
		match currentWeapon.Type:
			NULL:
				print("YOU FAILED")
			HITSCAN:
				print("pew")
				var world = get_tree().get_root()
				var collisionPoint = debugHitpoint.instantiate()
				world.add_child(collisionPoint)
				collisionPoint.global_translate(cameraCollision)
				
				var shotLine = bulletRayLine.instantiate()
				world.add_child(shotLine)
				shotLine.init(muzzle.global_transform.origin, cameraCollision)
			PROJECTILE:
				projectileShot(cameraCollision, currentWeapon.projectileCount)
	

func Get_Camera_Collision():
	return(interaction_sphere_cast.get_collision_point())

func projectileShot(point, count):
	var direction = (point - muzzle.global_position)
	
	for bullet in range(count):
		var finalSpread = currentWeapon.projectileSpread * (bullet/(count/1.5))
		var finaldirection = direction.rotated(Vector3(0, 0, 1), randf_range(-finalSpread, finalSpread))
		finaldirection = finaldirection.rotated(Vector3(0, 1, 0), randf_range(-finalSpread, finalSpread))
		finaldirection = finaldirection.rotated(Vector3(1, 0, 0), randf_range(-finalSpread, finalSpread))
		
		var projectile = currentWeapon.projectile.instantiate()
		muzzle.add_child(projectile)
		projectile.damage = currentWeapon.damage
		projectile.set_linear_velocity(finaldirection.normalized() * currentWeapon.projectileSpeed)
