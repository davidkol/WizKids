extends NetworkScene
class_name NetworkSpellPage

@export var spell: PackedScene

# NetworkScene overrides
func _can_activate() -> bool:
	return spell != null

func _after_activation(instance: Node3D):
	pass

func _spawn() -> Node3D:
	return self

func _get_data(instance: Node3D) -> Dictionary:
	var data = super._get_data(instance)
	if instance is SpellPage:
		data["transform"] = instance.global_transform
		data["rotation"] = instance.page_mesh.rotation
	return data

func _apply_data(instance: Node3D, data: Dictionary):
	super._apply_data(instance, data)
	if instance is SpellPage and data.has("transform"):
		instance.global_transform = data["transform"]
		if data.has("rotation"):
			instance.page_mesh.rotation = data["rotation"]

func _is_reconcilable(instance: Node3D, request_data: Dictionary, local_data: Dictionary) -> bool:
	return true  # Pages are purely visual, so we can always reconcile

func _reconcile(instance: Node3D, local_data: Dictionary, remote_data: Dictionary):
	if instance is SpellPage:
		# Use the server's transform and rotation
		if remote_data.has("transform"):
			instance.global_transform = remote_data["transform"]
		if remote_data.has("rotation"):
			instance.page_mesh.rotation = remote_data["rotation"] 
