extends NetworkScene
class_name NetworkSpell

@export var spell_scene: PackedScene
@export var spell_name: String = "Unnamed Spell"
@export var description: String = "No description available."
@export var cast_time: float = 1.0  # Cast time in seconds

var _current_cast: Node3D = null

func _can_activate() -> bool:
	# Can only activate if there's no current cast
	return _current_cast == null

func _after_activation(instance: Node3D):
	# Start the cast time
	_current_cast = instance
	instance.start_casting()

func _spawn() -> Node3D:
	var instance = spell_scene.instantiate()
	instance.cast_time = cast_time
	return instance

func _cast_spell():
	pass

func _get_data(instance: Node3D) -> Dictionary:
	var data = super._get_data(instance)
	data["cast_tick"] = instance.cast_tick
	data["cast_time"] = instance.cast_time
	return data

func _apply_data(instance: Node3D, data: Dictionary):
	super._apply_data(instance, data)
	instance.cast_tick = data["cast_tick"]
	instance.cast_time = data["cast_time"]

func _is_reconcilable(instance: Node3D, local_data: Dictionary, remote_data: Dictionary) -> bool:
	return instance is SpellInstance

func _reconcile(instance: Node3D, local_data: Dictionary, remote_data: Dictionary):
	# Compare and reconcile spell-specific properties
	if local_data.has("cast_tick") and remote_data.has("cast_tick"):
		# Use the earlier cast tick
		var reconciled_tick = min(local_data["cast_tick"], remote_data["cast_tick"])
		instance.cast_tick = reconciled_tick
		
		# If this instance is currently casting, update its start tick
		if _current_cast == instance:
			_current_cast.cast_tick = reconciled_tick

func _process(delta: float):
	# Check for completed cast time
	if _current_cast == null:
		return
		
	if not is_instance_valid(_current_cast):
		_current_cast == null
		return
	
	var elapsed_ticks = NetworkTime.tick - _current_cast.cast_tick
	if elapsed_ticks >= int(_current_cast.cast_time / NetworkTime.ticktime):
		_current_cast.complete_casting()
		_cast_spell()
		_current_cast == null

## Cancels the current spell cast if one is in progress.
## Returns true if a cast was cancelled, false if there was no cast to cancel.
func cancel_cast() -> bool:
	if _current_cast == null:
		return false
		
	if not is_instance_valid(_current_cast):
		_current_cast.clear()
		return false
		
	# Use the delete_instance functionality from NetworkScene
	var success = delete_instance(_current_cast.name.split(" ")[-1])  # Get the ID from the instance name
	if success:
		_current_cast.clear()
	return success 
