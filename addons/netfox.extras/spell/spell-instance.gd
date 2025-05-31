extends Node3D
class_name SpellInstance

var cast_tick: int

func _initialize():
	cast_tick = NetworkTime.tick

func _physics_process(delta: float):
	pass

func _on_hit(target: Node):
	pass

func _on_destroy():
	pass

func destroy():
	_on_destroy()
	queue_free() 