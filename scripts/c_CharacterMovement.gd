extends CharacterBody3D

@export var input:c_PlayerInput
@export var head:Node3D
@export var speed:float = 5.0
@export var jump_strength:float = 5.0
@export var sensitivity:float = 5.0

var gravity = ProjectSettings.get_setting(&"physics/3d/default_gravity")

func _rollback_tick(delta, _tick, _is_fresh):
	# Handle look left and right
	rotate_object_local(Vector3(0, 1, 0), input.look_direction.x)
	
	# Handle look up and down
	head.rotate_object_local(Vector3(1, 0, 0), input.look_direction.y)
	
	head.rotation.x = clamp(head.rotation.x, -1.57, 1.57)
	head.rotation.z = 0
	head.rotation.y = 0
	
	var old_velocity = velocity
	velocity = Vector3.ZERO
	move_and_slide()
	velocity = old_velocity

	if is_on_floor():
		if input.jump:
			velocity.y = jump_strength
	else:
		velocity.y -= gravity * delta

	var input_dir = input.move_direction
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.z)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	# move_and_slide assumes physics delta
	# multiplying velocity by NetworkTime.physics_factor compensates for it
	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor
