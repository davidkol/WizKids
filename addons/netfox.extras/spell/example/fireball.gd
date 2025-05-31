extends NetworkSpell
class_name FireballSpell

@export var fire_cooldown: float = 0.55
@export var input: c_PlayerInput
@onready var sound: AudioStreamPlayer3D = $AudioStreamPlayer3D

var spawn_point:Marker3D
var last_fire: int = -1

func _ready():
	super._ready()
	NetworkEvents.on_peer_join.connect(_handle_new_peer)

func _init():
	spell_name = "Fireball"
	description = "Launches a ball of fire that explodes on impact, dealing damage to nearby enemies."

func _can_activate() -> bool:
	return NetworkTime.seconds_between(last_fire, NetworkTime.tick) >= fire_cooldown

func _can_peer_use(peer_id: int) -> bool:
	return peer_id == input.get_multiplayer_authority()

func _after_activation(instance: Node3D):
	super._after_activation(instance)
	var fireball_projectile = instance
	last_fire = get_last_activation_tick()
	fireball_projectile.cast_tick = last_fire
	# if sound:
	# 	sound.play()
	
	# var tick_interpolator = instance.get_node("TickInterpolator")
	# if tick_interpolator:
	# 	tick_interpolator.teleport()
	
	# for t in range(last_fire, NetworkTime.tick):
	# 	if instance.is_queued_for_deletion():
	# 		break
	# 	instance._tick(NetworkTime.ticktime, t)

func _spawn() -> Node3D:
	var fireball = spell_scene.instantiate()
	get_tree().root.add_child(fireball, true)
	fireball.global_transform = spawn_point.global_transform
	fireball.fired_by = get_parent()
	fireball.cast_time = cast_time
	fireball.set_multiplayer_authority(get_multiplayer_authority())
	
	return fireball

func _get_data(instance: Node3D) -> Dictionary:
	var data = super._get_data(instance)
	data["global_transform"] = instance.global_transform
	return data

func _apply_data(instance: Node3D, data: Dictionary):
	super._apply_data(instance, data)
	instance.global_transform = data["global_transform"]

func _is_reconcilable(instance: Node3D, request_data: Dictionary, local_data: Dictionary) -> bool:
	return true

func _reconcile(instance: Node3D, local_data: Dictionary, remote_data: Dictionary):
	var local_transform = local_data["global_transform"] as Transform3D
	var remote_transform = remote_data["global_transform"] as Transform3D
	
	var relative_transform = instance.global_transform * local_transform.inverse()
	var final_transform = remote_transform * relative_transform
	
	instance.global_transform = final_transform
