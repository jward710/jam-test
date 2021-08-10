extends KinematicBody


export var gravity = 0.98
export var speed = 10
export var acceleration = 0.1

var mouse_sensitivity = 0.4

var direction = Vector3()
var velocity = Vector3()


	
func _physics_process(_delta):
	direction = Vector3.ZERO
	
	var new_velocity: Vector3 = Vector3.ZERO
	
	
	if Input.is_action_pressed("ui_up"):
		direction -= global_transform.basis.z
	
	elif Input.is_action_pressed("ui_down"):
		direction += global_transform.basis.z
	
	if Input.is_action_pressed("ui_left"):
		direction -= global_transform.basis.x
	
	elif Input.is_action_pressed("ui_right"):
		direction += global_transform.basis.x
	
	direction = direction.normalized()
	
	new_velocity = direction * speed
	
	new_velocity = lerp(Vector3(velocity.x, 0, velocity.z), new_velocity, acceleration)
	
	new_velocity.y = velocity.y - gravity
	
	velocity = move_and_slide(new_velocity, Vector3.UP)
	

