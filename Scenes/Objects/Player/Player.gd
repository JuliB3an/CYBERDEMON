extends CharacterBody3D
#nodes
@onready var head = $Head
@onready var standing_collision_shape = $StandingCollisionShape
@onready var crouching_collision_shape = $CrouchingCollisionShape
@onready var crouching_raycast = $CrouchingRaycast
@onready var additional_camera_rotations = $Head/Eyes/AdditionalCameraRotations
@onready var eyes = $Head/Eyes
@onready var head_cast = $HeadCast
@onready var toe_cast = $ToeCast
@onready var animation_player = $Head/Eyes/AdditionalCameraRotations/AnimationPlayer
@onready var camera_3d = $Head/Eyes/AdditionalCameraRotations/Camera3D
@onready var wall_slide_cast = $WallSlideCast
@onready var interaction_cast = $Head/Eyes/InteractionCast

#hand animations
@onready var idle_right_hand = $Head/Eyes/AdditionalCameraRotations/Camera3D/PlayerGUI/IdleRightHand
@onready var grapple_out_right_hand = $Head/Eyes/AdditionalCameraRotations/Camera3D/PlayerGUI/GrappleOutRightHand
@onready var holding_item_right_hand = $Head/Eyes/AdditionalCameraRotations/Camera3D/PlayerGUI/HoldingItemRightHand
@onready var right_hand_crawl = $Head/Eyes/AdditionalCameraRotations/Camera3D/PlayerGUI/RightHandCrawl
@onready var right_hand_grapple_back = $Head/Eyes/AdditionalCameraRotations/Camera3D/PlayerGUI/RightHandGrappleBack
@onready var both_hand_lunge = $Head/Eyes/AdditionalCameraRotations/Camera3D/PlayerGUI/BothHandLunge
@onready var left_hand_punch = $Head/Eyes/AdditionalCameraRotations/Camera3D/PlayerGUI/LeftHandPunch
@onready var left_hand_crawl = $Head/Eyes/AdditionalCameraRotations/Camera3D/PlayerGUI/LeftHandCrawl
@onready var left_hand_parry = $Head/Eyes/AdditionalCameraRotations/Camera3D/PlayerGUI/LeftHandParry
@onready var holding_item_left_hand = $Head/Eyes/AdditionalCameraRotations/Camera3D/PlayerGUI/HoldingItemLeftHand


enum LEFT{
	free,
	punch,
	parry,
	crawl,
	lunge,
	holding
}

enum RIGHT{
	free,
	holding,
	grappleOut,
	grappleIn,
	crawl,
	lunge
}

var RightHandState = RIGHT.free
var LeftHandState = LEFT.free


#crouching
var crouchingDepth = -0.6

#speed
var momentumBonus = 0.0
var direction = Vector3.ZERO
var curspeed = 5.0
var targspeed = 0.0
var isCrouched = false
var justCrouched = 0
var lastDashSpeed = 0
var freeClimb = false
var dashing = false
var slamming = false
var dashDir = Vector3.ZERO

const walkingSpeed = 8.0
const sprintSpeed = 12.0
const crouchingSpeed = 2.0
var sprintUpping = 0.0
var wallStopTimer = 0.0

const jumpvelocity = 7.2

#mouse sensetivity
var mouseMultiplier = 1
var screen_scale = ProjectSettings.get_setting("display/window/stretch/scale")
var mouseSensitivity = 0.2*screen_scale

#juicy animations
var headbobVector = Vector2.ZERO
var headbobIndex = 0.0
var headbobIntensityCurrent = 0.0

var headbobIntensityCrouch = 0.03

var headbobCrouch = 0.3

var fovTarget = 100.0

#vaulting
var justVaulted = false
var canVault = false
var vaultTilt = 0.0
var wallRan = false;

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func AnimatedTexturePlayOnce(node):
	return node.texture.current_frame == node.texture.frames-1

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	#head rotation
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x*(mouseSensitivity)))
		vaultTilt = lerp(vaultTilt, event.relative.x*(mouseSensitivity), 0.2)
		head.rotate_x(deg_to_rad(-event.relative.y*(mouseSensitivity)))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-80), deg_to_rad(90))
		

func _physics_process(delta):
	headbobIntensityCurrent = 0.0
	
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	#punch
	if Input.is_action_just_pressed("punch"):
		if interaction_cast.is_colliding():
			left_hand_parry.texture.current_frame = 0
			LeftHandState = LEFT.parry
		else:
			left_hand_punch.texture.current_frame = 0
			LeftHandState = LEFT.punch
		
	#movement choices
	if Input.is_action_just_pressed("crouch") && !is_on_floor():
		slamming = true;
		velocity.y = -40
	
	if Input.is_action_just_pressed("sprint"):
		slamming = false
		sprintUpping = -1
		wallRan = false
		dashing = true
		curspeed += sprintSpeed+6
		targspeed = curspeed
		dashDir = (transform.basis * Vector3(0, 0, -1)).normalized()
		velocity.y = 0
	
	#set crouch toggle
	if !(dashing || slamming):
		if (Input.is_action_pressed("crouch")):
			targspeed = lerp(float(targspeed), sprintSpeed, 10*delta)
			isCrouched = true
			justCrouched += 1
			head.position.y = lerp(head.position.y, 0.4 + crouchingDepth, delta*10)
			crouching_collision_shape.disabled = false
			standing_collision_shape.disabled = true
		elif crouching_raycast.is_colliding():
			isCrouched = false
		else:
			targspeed = lerp(float(targspeed), walkingSpeed, 4*delta)
			head.position.y = lerp(head.position.y, 0.4, delta*10)
			isCrouched = false
			crouching_collision_shape.disabled = true
			standing_collision_shape.disabled = false
		
		headbobIndex += headbobCrouch
		headbobIntensityCurrent = headbobIntensityCrouch
		if isCrouched || (crouching_raycast.is_colliding() && input_dir != Vector2.ZERO):
			RightHandState = RIGHT.crawl
			if LeftHandState != LEFT.punch && LeftHandState != LEFT.parry:
				LeftHandState = LEFT.crawl
		else:
			RightHandState = RIGHT.free
			if LeftHandState != LEFT.punch && LeftHandState != LEFT.parry:
				LeftHandState = LEFT.free
	elif slamming:
		velocity.y = max(velocity.y-gravity*delta, -30)
		direction = lerp(direction, Vector3(0, 0, 0), delta*2)
		if is_on_floor():
			slamming = false
			if !Input.is_action_pressed("crouch"):
				curspeed = 0
				targspeed = 0
			else:
				curspeed = sprintSpeed
				targspeed = sprintSpeed
				momentumBonus = clamp(momentumBonus - velocity.y*15, 2.0, 15.0)
	else:
		curspeed = lerp(curspeed, crouchingSpeed, 10*delta)
		targspeed = curspeed
		direction = dashDir
		if ((curspeed <= sprintSpeed && input_dir != Vector2.ZERO) || curspeed <= crouchingSpeed+1) || isCrouched:
			dashing = false
	
	# Add the gravity.
	if not is_on_floor():
		momentumBonus = move_toward(momentumBonus, 0.0, 0.05)
		
		if !dashing:
			velocity.y -= gravity * delta
		if is_on_wall_only() && velocity.y < 0.0:
			velocity.y *= 0.9
		
		if !head_cast.is_colliding() && toe_cast.is_colliding() && (dashing||canVault):
			curspeed = min(curspeed, sprintSpeed+2)
			velocity.y = jumpvelocity
			if !justVaulted:
				animation_player.play('VaultAnimation')
			justVaulted = true
			canVault = false
		elif !toe_cast.is_colliding() && justVaulted:
			canVault = false
		elif (head_cast.is_colliding() && toe_cast.is_colliding()) && !wallRan && (curspeed+momentumBonus) > sprintSpeed:
			velocity.y = max(jumpvelocity*((curspeed+momentumBonus)/sprintSpeed), jumpvelocity)
			curspeed *= 0.25
			animation_player.play('WallClimb')
			sprintUpping = clamp(sprintUpping-1, 0, 6)
			freeClimb = false
			dashing = false
			wallRan = true
			canVault = true
			justVaulted = false
	else:
		wallRan = false
		sprintUpping = 1
		justVaulted = false
		momentumBonus = move_toward(momentumBonus, 0.0, 0.1)
		curspeed = lerp(curspeed, targspeed, 10*delta)
	
	print(momentumBonus)
	
	# Handle jump.
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = jumpvelocity
			if dashing:
				momentumBonus += 3
			if isCrouched:
				momentumBonus += 5
			
			if input_dir != Vector2.ZERO:
				curspeed += 3
			
		elif is_on_wall_only():
			slamming = false
			var wall_normal = get_slide_collision(0)
			velocity.y = jumpvelocity
			direction = wall_normal.get_normal()*1.5
			curspeed = walkingSpeed
	
	match RightHandState:
		RIGHT.free:
			right_hand_crawl.hide()
			grapple_out_right_hand.hide()
			holding_item_right_hand.hide()
		RIGHT.crawl:
			right_hand_crawl.show()
			grapple_out_right_hand.hide()
			holding_item_right_hand.hide()
			right_hand_grapple_back.hide()
			idle_right_hand.hide()
	
	match LeftHandState:
		LEFT.free:
			left_hand_crawl.hide()
			left_hand_punch.hide()
			left_hand_parry.hide()
			holding_item_left_hand.hide()
		LEFT.parry:
			left_hand_crawl.hide()
			left_hand_punch.hide()
			left_hand_parry.show()
			holding_item_left_hand.hide()
			if AnimatedTexturePlayOnce(left_hand_parry):
				LeftHandState = LEFT.free
		LEFT.punch:
			left_hand_crawl.hide()
			left_hand_punch.show()
			left_hand_parry.hide()
			holding_item_left_hand.hide()
			if AnimatedTexturePlayOnce(left_hand_punch):
				LeftHandState = LEFT.free
		LEFT.crawl:
			left_hand_crawl.show()
			left_hand_punch.hide()
			left_hand_parry.hide()
			holding_item_left_hand.hide()
		LEFT.holding:
			left_hand_crawl.hide()
			left_hand_punch.hide()
			left_hand_parry.hide()
			holding_item_left_hand.show()
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	
	if isCrouched:
		direction = lerp(direction, (transform.basis * Vector3(0, 0, -1)).normalized(), delta*15)
	elif !dashing:
		if (is_on_floor() || is_on_wall()):
			direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*10)
		else:
			if input_dir != Vector2.ZERO:
				direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*3)
		
	if direction:
		velocity.x = direction.x * (curspeed + momentumBonus)
		velocity.z = direction.z * (curspeed + momentumBonus)
	else:
		velocity.x = move_toward(velocity.x, 0, curspeed)
		velocity.z = move_toward(velocity.z, 0, curspeed)
	
	#headbob
	if is_on_floor() && input_dir != Vector2.ZERO:
		headbobVector.y = sin(headbobIndex)
		headbobVector.x = sin(headbobIndex/2)+0.5
		
		eyes.position.y = lerp(eyes.position.y, headbobVector.y*(headbobIntensityCurrent/2), delta*10)
		eyes.position.x = lerp(eyes.position.x, headbobVector.x*headbobIntensityCurrent, delta*10)
	else:
		eyes.position.y = lerp(eyes.position.y, 0.0, delta*10)
		eyes.position.x = lerp(eyes.position.x, 0.0, delta*10)
	
	#rotateCam
	vaultTilt = lerp(vaultTilt, 0.0, 10*delta)
	additional_camera_rotations.rotation.z = deg_to_rad(vaultTilt)
	camera_3d.fov = fovTarget

	move_and_slide()
