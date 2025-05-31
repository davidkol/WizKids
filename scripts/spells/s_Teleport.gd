extends NetworkSpell
class_name TeleportSpell

@export var activate_cooldown: float = 0.55
@export var input: c_PlayerInput
@onready var sound: AudioStreamPlayer3D = $AudioStreamPlayer3D

var last_activate: int = -1

@export var teleport_distance: float = 6.0
@export var tick_interpolator:TickInterpolator

var body:Node3D
@onready var teleport_action:RewindableAction = $RewindableAction
var last_teleport:int = -1

func _init():
	spell_name = "Teleport"
	description = "Teleports the player to the target location."

func _ready() -> void:
	super._ready()
	teleport_action.mutate(self)
	teleport_action.mutate(body)
	NetworkEvents.on_peer_join.connect(_handle_new_peer)

func _activate(e_TargetToTeleport: Node3D) -> void:
	last_teleport = NetworkRollback.tick
	e_TargetToTeleport.global_transform.origin += e_TargetToTeleport.global_transform.basis.y * teleport_distance
	tick_interpolator.teleport()

func _can_activate() -> bool:
	return NetworkTime.seconds_between(last_activate, NetworkTime.tick) >= activate_cooldown

func _can_peer_use(peer_id: int) -> bool:
	return peer_id == input.get_multiplayer_authority()

func _after_activation(instance: Node3D):
	super._after_activation(instance)
	last_activate = get_last_activation_tick()
	# if sound:
	# 	sound.play()
	
	tick_interpolator.teleport()
	
	# for t in range(last_activate, NetworkTime.tick):
	# 	if instance.is_queued_for_deletion():
	# 		break
	# 	instance._tick(NetworkTime.ticktime, t)

func _spawn() -> Node3D:
	var instance: Node3D = spell_scene.instantiate() as Node3D
	get_tree().root.add_child(instance, true)
	instance.global_transform = global_transform
	instance.activated_by = get_parent()
	instance.cast_time = cast_time
	instance.set_multiplayer_authority(get_multiplayer_authority())
	
	return instance

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
	pass
