extends Node
class_name c_CharacterAim

@export var sensitivity:float = 5.0
@export var input:c_PlayerInput
@export var body:CharacterBody3D
@export var head:Node3D

func _rollback_tick(_delta, _tick, _is_fresh):
	if input.look_direction != Vector2.ZERO:
		pass
	# Handle look left and right
	body.rotate_object_local(Vector3(0, 1, 0), input.look_direction.x)
	
	# Handle look up and down
	head.rotate_object_local(Vector3(1, 0, 0), input.look_direction.y)
	
	head.rotation.x = clamp(head.rotation.x, -1.57, 1.57)
	head.rotation.z = 0
	head.rotation.y = 0
