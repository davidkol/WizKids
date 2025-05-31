extends ShapeCast3D
class_name FireballProjectile

@export var speed: float = 12.0
@export var strength: float = 2.0
@export var distance: float = 300.0

var distance_left: float
var fired_by: Node
var is_first_tick: bool = true
var cast_time: float = 0.0
var cast_tick: int = -1
var original_tick: int
var original_position: Vector3
var hit_array:Array[Dictionary] = []

func _ready():
	set_physics_process(false)
	distance_left = distance
	hide()

func start_casting():
	pass

func complete_casting():
	if not NetworkTime.on_tick.is_connected(_tick): NetworkTime.on_tick.connect(_tick)
	#if not NetworkRollback.on_process_tick.is_connected(_rollback_tick): NetworkRollback.on_process_tick.connect(_rollback_tick)
	#original_position = global_position
	#original_tick = NetworkTime.tick - 1
	show()

func _tick(delta, tick):
	var dst = speed * delta
	var motion = transform.basis.z * dst
	target_position = Vector3.FORWARD * dst
	distance_left -= dst
	
	if distance_left <= 0:
		queue_free()
	
	force_shapecast_update()
	var space := get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	query.motion = motion
	query.shape = shape
	query.transform = global_transform
	query.collision_mask = 2
	
	var hit_interval := space.cast_motion(query)
	if hit_interval[0] != 1.0 or hit_interval[1] != 1.0:
		global_position += motion * hit_interval[1]
		_explode()
	else:
		global_position += motion

func _explode():
	queue_free()
	# if not is_multiplayer_authority(): return
	var space := get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	$ShapeCast3D.enabled = true
	query.shape = $ShapeCast3D.shape
	query.transform = global_transform
	query.collision_mask = 2
	hit_array = space.intersect_shape(query)
	for hit in hit_array:
		var body = hit["collider"]
		if body != null:
			var direction = (body.global_position - global_position)
			var direction2 = Vector2(direction.x, direction.z).normalized()
			var extra_velocity = Vector3(direction2.x, 0.5, direction2.y).normalized()
			body.knockback(extra_velocity * 360 * NetworkTime.ticktime)
