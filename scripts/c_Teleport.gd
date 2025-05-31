extends Node
class_name c_Teleport

@export var teleport_distance: float = 6.0
@export var input:c_PlayerInput
@export var tick_interpolator:TickInterpolator

var body:Node3D
@onready var teleport_action:RewindableAction = $RewindableAction
var last_teleport:int = -1

func _ready() -> void:
	body = owner
	teleport_action.mutate(self)
	teleport_action.mutate(body)

func _rollback_tick(_dt, _tick: int, _if):
	teleport_action.set_active(input.activate and _can_activate())
	match teleport_action.get_status():
		RewindableAction.CONFIRMING, RewindableAction.ACTIVE:
			_activate(body)
		RewindableAction.CANCELLING:
			_unactivate(body)
	#if input.activate and _can_activate():
		#_activate(body)

func _activate(e_TargetToTeleport: Node3D) -> void:
	last_teleport = NetworkRollback.tick
	e_TargetToTeleport.global_transform.origin += e_TargetToTeleport.global_transform.basis.y * teleport_distance
	tick_interpolator.teleport()

func _unactivate(_e_TargetToTeleport: Node3D) -> void:
	pass

func _can_activate() -> bool:
	return NetworkTime.seconds_between(last_teleport, NetworkRollback.tick) >= 0.5
