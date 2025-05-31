extends Node
class_name c_PlayerInput

@export var mouse_sensitivity_h: float = 0.15
@export var mouse_sensitivity_v: float = 0.15

var move_direction:Vector3 = Vector3.ZERO
var look_direction:Vector2 = Vector2.ZERO
var mouse_relative_motion:Vector2 = Vector2.ZERO
var jump:bool = false
var activate:bool = false
var flip:bool = false
var override_mouse:bool = false

func _notification(what):
	if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		override_mouse = false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	NetworkTime.before_tick_loop.connect(_gather)

func _input(event: InputEvent) -> void:
	if !is_multiplayer_authority(): return
	
	if event is InputEventMouseMotion:
		mouse_relative_motion.y = event.relative.x * mouse_sensitivity_h
		mouse_relative_motion.x = event.relative.y * mouse_sensitivity_v
	
	if event.is_action_pressed("escape"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		override_mouse = true

func _gather():
	if !is_multiplayer_authority(): return
	
	if override_mouse:
		look_direction = Vector2.ZERO
		mouse_relative_motion = Vector2.ZERO
		return
	
	move_direction = Vector3(
		Input.get_axis("move_left", "move_right"),
		Input.get_action_strength("jump"),
		Input.get_axis("move_forward", "move_backward")
	)
	
	look_direction = Vector2(-mouse_relative_motion.y * NetworkTime.ticktime, -mouse_relative_motion.x * NetworkTime.ticktime)
	mouse_relative_motion = Vector2.ZERO
	
	jump = Input.get_action_strength("jump")
	activate = Input.get_action_strength("activate")
	flip = Input.get_action_strength("flip")
