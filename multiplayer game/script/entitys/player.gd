extends KinematicBody

var speed = 5

var direction = Vector3()

#this is being told from the client where the other player/s are moving and is setting that players positon based on this players view
remote func _set_position(pos):
	global_transform.origin = pos


func _physics_process(_delta):
	direction = Vector3()
	
	if Input.is_action_pressed("ui_up"):
		direction -= transform.basis.z
	elif Input.is_action_pressed("ui_down"):
		direction += transform.basis.z
	if Input.is_action_pressed("ui_left"):
		direction -= transform.basis.x
	elif Input.is_action_pressed("ui_right"):
		direction += transform.basis.x
	direction = direction.normalized()
	
	if direction != Vector3():
		if is_network_master():
			direction = move_and_slide(direction * speed, Vector3.UP)
			#telling the client that the other player is moving and is comunicating that to the "_set_position" fuction
		rpc_unreliable("_set_position", global_transform.origin)
	
