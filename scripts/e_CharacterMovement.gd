extends CharacterBody3D

@export var input:c_PlayerInput
@export var rbs:RollbackSynchronizer
@export var head:Node3D
@export var speed:float = 5.0
@export var jump_strength:float = 5.0
@export var sensitivity:float = 5.0

var gravity = ProjectSettings.get_setting(&"physics/3d/default_gravity")
var extra_velocity:Vector3 = Vector3.ZERO
var knocked:bool = false
static var _logger: _NetfoxLogger = _NetfoxLogger.for_extras("Movement")

func _rollback_tick(delta, _tick, _is_fresh):
	rotate_object_local(Vector3(0, 1, 0), input.look_direction.x)
	head.rotate_object_local(Vector3(1, 0, 0), input.look_direction.y)
	head.rotation.x = clamp(head.rotation.x, -1.57, 1.57)
	head.rotation.z = 0
	head.rotation.y = 0
	
	if is_on_floor():
		var input_dir = input.move_direction
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.z)).normalized()
		if input.jump:
			#velocity.y = jump_strength
			var dir = Vector3.FORWARD
			var dir2 = Vector2(dir.x, dir.z).normalized()
			var extra_velocity = Vector3(dir2.x, 0.5, dir2.y).normalized()
			knockback(extra_velocity * 360 * NetworkTime.ticktime)
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
	else:
		velocity.y -= gravity * delta
	if extra_velocity != Vector3.ZERO:
		velocity += extra_velocity
		extra_velocity = Vector3.ZERO
		knocked = true
	
	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor

func knockback(motion:Vector3):
	extra_velocity = motion
	NetworkRollback.mutate(self)
	#$TickInterpolator.teleport()

func shove(motion: Vector3):
	move_and_collide(motion)
