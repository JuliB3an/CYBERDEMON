extends Resource

class_name Weapon_Resource

@export var weaponName: String
@export var weaponPath: NodePath

@export var activateAnimation: String
@export var shootAnimation: String
@export var shootAnimSpeed: float = 1

@export var auto: bool

@export_flags("Hitscan", "Projectile")var Type
@export var projectile: PackedScene
@export var projectileSpeed: float
@export var projectileCount: int = 1
@export var projectileSpread: float = 0
@export var damage: float = 5
