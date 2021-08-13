extends KinematicBody

export var gravity = 0.1
export var jump = 16
export var speed = 10
export var acceleration = 0.1

var mouse_sensitivity = 0.4

var direction = Vector3()
var velocity = Vector3()

var new_velocity: Vector3 = Vector3.ZERO

var wall_normal

var canJump = false
var sprinting = false
var wr = false

onready var pivot = $Pivot
onready var pivoting = $Pivot/Pivot2
onready var rotation_pivot = $RotationPivot
onready var rotation_helper = $RotationHelper
onready var character_mesh: MeshInstance = $MeshInstance
onready var coyote = $CoyoteClock
onready var wall = $WallRunner
onready var jumpcast = $FloorCast

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	

func _input(event):
	
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if event is InputEventMouseMotion:
		pivot.rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
		pivoting.rotate_x(deg2rad(-event.relative.y * mouse_sensitivity))
		pivoting.rotation.x = clamp(pivoting.rotation.x, deg2rad(-89), deg2rad(89))
	
	if event is InputEventJoypadMotion:
		pivot.rotate_y(deg2rad(-event.axis.x * mouse_sensitivity))
		pivoting.rotate_x(deg2rad(-event.relative.y * mouse_sensitivity))
		pivoting.rotation.x = clamp(pivoting.rotation.x, deg2rad(-89), deg2rad(89))
	
func _physics_process(_delta):
	direction = Vector3.ZERO
	
	if Input.is_action_pressed("shift"):
		speed = 10 * 2
	else:
		speed = 10
	
	
	if Input.is_action_pressed("forward"):
		direction -= pivot.global_transform.basis.z
	
	elif Input.is_action_pressed("backward"):
		direction += pivot.global_transform.basis.z
	
	if Input.is_action_pressed("left"):
		direction -= pivot.global_transform.basis.x
	
	elif Input.is_action_pressed("right"):
		direction += pivot.global_transform.basis.x
	
	direction = direction.normalized()
	
	new_velocity = direction * speed
	
	new_velocity = lerp(Vector3(velocity.x, 0, velocity.z), new_velocity, acceleration)
	
	new_velocity.y = velocity.y - gravity
	
	if jumpcast.is_colliding():
		canJump = true
	
	if canJump == true:
		if Input.is_action_just_pressed("ui_select"):
			new_velocity.y = jump
			canJump = false
			wr = true
	
	if !jumpcast.is_colliding():
		coyote.start()
	
	wall_run()
	
	velocity = move_and_slide(new_velocity, Vector3.UP, true)
	
	if direction != Vector3.ZERO:
		rotation_helper.look_at(global_transform.origin - pivot.global_transform.basis.z, Vector3.UP)
		
		character_mesh.rotation.y = lerp_angle(character_mesh.rotation.y, rotation_helper.rotation.y, 0.2)
		
	

func wall_run():
	if wr:
		if Input.is_action_pressed("shift"):
			if Input.is_action_pressed("forward"):
				if is_on_wall():
					wall.start()
					wall_normal = get_slide_collision(0)
					#yield(get_tree().create_timer(0.2), "timeout")
					new_velocity.y = 0
					direction = - wall_normal.normal * speed
				


func _on_CoyoteClock_timeout():
	canJump = false


func _on_WallRunner_timeout():
	wr = false
