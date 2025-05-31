extends Node3D
class_name NetworkScene

## Base class for creating responsive networked scenes, by spawning instances locally,
## but keeping control on the server.

var _instances: Dictionary = {}
var _instance_data: Dictionary = {}
var _reconcile_buffer: Array = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _last_activation_tick: int = -1

static var _logger: _NetfoxLogger = _NetfoxLogger.for_extras("NetworkScene")

func _ready():
	_rng.randomize()
	NetworkTime.before_tick_loop.connect(_before_tick_loop)

## Get the tick when the scene was last activated.
## [br][br]
## Whenever a scene gets activated, it takes time for that event to be transmitted
## to the server. To account for this latency, the exact tick is sent along
## with other data, so implementations can compensate for the latency.
## [br][br]
## One way to use this is to manually simulate the instance after it's
## created:
## [codeblock]
## func _after_activation(instance: Node3D):
##     last_activation = get_last_activation_tick()
##     sound.play()
##
##     for t in range(get_last_activation_tick(), NetworkTime.tick):
##         if instance.is_queued_for_deletion():
##             break
##         instance._tick(NetworkTime.ticktime, t)
## [/codeblock]
func get_last_activation_tick() -> int:
	return _last_activation_tick

## Override this method with your own activation logic.
## [br][br]
## This can be used to implement e.g. cooldowns and resource checks.
func _can_activate() -> bool:
	return true

## Override this method to check if a given peer can use this scene.
## [br][br]
## Usually this should check if the scene's owner is trying to activate it, but 
## for some special cases this can be some different logic.
func _can_peer_use(peer_id: int) -> bool:
	return true

## Override this method to run any logic needed after successfully activating the 
## scene.
## [br][br]
## This can be used to e.g. reset cooldowns or consume resources.
func _after_activation(instance: Node3D):
	pass

## Override this method to spawn and initialize an instance.
## [br][br]
## Make sure to return the instance spawned!
func _spawn() -> Node3D:
	return null

## Override this method to extract instance data that should be synchronized
## over the network.
## [br][br]
## This will be captured both locally and on the server, and will be used for 
## reconciliation.
func _get_data(instance: Node3D) -> Dictionary:
	return {}

## Override this method to apply instance data that should be synchronized 
## over the network.
## [br][br]
## This is used in cases where some other client activates the scene and the server 
## instructs us to spawn an instance for it.
func _apply_data(instance: Node3D, data: Dictionary):
	pass

## Override this method to check if two instance states can be reconciled.
## [br][br]
## This can be used to prevent cheating, for example by not allowing the client 
## to say it's activating from the other side of the map compared to its actual 
## position.
## [br][br]
## When this method returns false, the server will decline the instance
## request.
func _is_reconcilable(instance: Node3D, request_data: Dictionary, local_data: Dictionary) -> bool:
	return true

## Override this method to reconcile the initial local and remote instance
## state.
## [br][br]
## Let's say the instance has a specific position, but we receive a different 
## position from the server. In this reconciliation step, the instance's position 
## can be adjusted to account for the different position.
## [br][br]
## Unless the use case is niche, the best practice is to consider the server's
## state as authorative.
func _reconcile(instance: Node3D, local_data: Dictionary, remote_data: Dictionary):
	pass

## Try to activate the scene and return the instance.
## [br][br]
## Returns null if the scene can't be activated.
func activate() -> Node3D:
	if not _can_activate():
		return null
	
	var id: String = _generate_id()
	var instance = _spawn()
	_save_instance(instance, id)
	var data = _instance_data[id]
	# _logger.debug("act id %s, instance %s", [id, instance.name])
	if is_multiplayer_authority():
		_accept_instance.rpc(id, NetworkTime.tick, data)
	else:
		_request_instance.rpc_id(get_multiplayer_authority(), id, NetworkTime.tick, data)
	
	# _logger.debug("Calling after activation hook for %s", [instance.name])
	_last_activation_tick = NetworkTime.tick
	_after_activation(instance)
	
	return instance

func _save_instance(instance: Node3D, id: String, data: Dictionary = {}):
	_instances[id] = instance
	instance.name += " " + id
	instance.set_multiplayer_authority(get_multiplayer_authority())
	
	if data.is_empty():
		data = _get_data(instance)
	
	_instance_data[id] = data
	# _logger.debug("Saved instance %s, total instances: %d, authority: %d", [id, _instances.size(), get_multiplayer_authority()])

func _before_tick_loop():
	# Reconcile instances
	for recon in _reconcile_buffer:
		var instance = recon[0]
		var local_data = recon[1]
		var response_data = recon[2]
		var instance_id = recon[3]
		
		if is_instance_valid(instance):
			_reconcile(instance, local_data, response_data)
		else:
			_logger.warning("Instance %s vanished by the time of reconciliation!", [instance_id])

	_reconcile_buffer.clear()

func _generate_id(length: int = 12, charset: String = "abcdefghijklmnopqrstuvwxyz0123456789") -> String:
	var result = ""
	
	# Generate a random ID
	for i in range(length):
		var idx = _rng.randi_range(0, charset.length() - 1)
		result += charset[idx]
	
	return result

@rpc("authority", "reliable", "call_local")
func _accept_instance(id: String, tick: int, response_data: Dictionary):
	if multiplayer.get_unique_id() == multiplayer.get_remote_sender_id():
		# Instance is local, nothing to do
		return
	
	#_logger.info("Accepting instance %s from %s", [id, multiplayer.get_remote_sender_id()])
	# _logger.debug("acc id %s", [id])
	
	if _instances.has(id):
		var instance = _instances[id]
		var local_data = _instance_data[id]
		_reconcile_buffer.push_back([instance, local_data, response_data, id])
	else:
		_last_activation_tick = tick
		var instance = _spawn()
		_apply_data(instance, response_data)
		_save_instance(instance, id, response_data)
		_after_activation(instance)

@rpc("any_peer", "reliable", "call_remote")
func _request_instance(id: String, tick: int, request_data: Dictionary):
	var sender = multiplayer.get_remote_sender_id()
	
	# Reject if sender can't use this input
	_last_activation_tick = tick
	if not _can_peer_use(sender) or not _can_activate():
		_decline_instance.rpc_id(sender, id)
		_logger.error("Instance %s rejected! Peer %s can't use this scene now", [id, sender])
		return
	
	# Validate incoming data
	var instance = _spawn()
	var local_data: Dictionary = _get_data(instance)
	
	if not _is_reconcilable(instance, request_data, local_data):
		instance.queue_free()
		_decline_instance.rpc_id(sender, id)
		_logger.error("Instance %s rejected! Can't reconcile states: [%s, %s]", [id, request_data, local_data])
		return
	
	_save_instance(instance, id, local_data)
	# _logger.debug("Server saved instance %s for peer %s", [id, sender])
	# _logger.debug("req id %s", [id])
	_accept_instance.rpc(id, tick, local_data)
	_after_activation(instance)

@rpc("authority", "reliable", "call_remote")
func _decline_instance(id: String):
	if not _instances.has(id):
		return
	
	var instance = _instances[id]
	if is_instance_valid(instance):
		instance.queue_free()
	
	_instances.erase(id)
	_instance_data.erase(id)

# only connect this in the extended class or it might conflict with spawned instances, if they are also derived from NetworkScene
func _handle_new_peer(peer_id: int) -> void:
	if not is_multiplayer_authority():
		return
	
	# Server sends all existing instances to the new peer
	for id in _instances:
		var instance = _instances[id]
		if is_instance_valid(instance):
			var data = _instance_data[id]
			_logger.debug("Replicating instance %s to peer %d", [id, peer_id])
			_replicate_instance.rpc_id(peer_id, id, NetworkTime.tick, data)
		else:
			# Clean up invalid instances
			_logger.debug("Cleaning up invalid instance %s", [id])
			_instances.erase(id)
			_instance_data.erase(id)

@rpc("authority", "reliable", "call_remote")
func _replicate_instance(id: String, tick: int, data: Dictionary) -> void:
	if _instances.has(id):
		# Instance already exists, reconcile if needed
		var instance = _instances[id]
		var local_data = _instance_data[id]
		_reconcile_buffer.push_back([instance, local_data, data, id])
	else:
		# Create new instance from replicated data
		var instance = _spawn()
		_apply_data(instance, data)
		_save_instance(instance, id, data)
		_after_activation(instance)

## Delete an instance and notify all clients.
## [br][br]
## This should be called on the server to properly delete an instance across the network.
## Returns true if the instance was found and deleted.
func delete_instance(id: String) -> bool:
	if not _instances.has(id):
		return false
		
	if is_multiplayer_authority():
		# Server notifies all clients about the deletion
		_delete_instance.rpc(id)
	else:
		# Client requests deletion from server
		_request_delete_instance.rpc_id(get_multiplayer_authority(), id)
		return false
		
	# Server performs local deletion
	_perform_delete(id)
	return true

## Internal method to perform the actual deletion
func _perform_delete(id: String) -> void:
	if not _instances.has(id):
		return
		
	var instance = _instances[id]
	if is_instance_valid(instance):
		instance.queue_free()
	
	_instances.erase(id)
	_instance_data.erase(id)
	_logger.debug("Deleted instance %s, remaining instances: %d", [id, _instances.size()])

@rpc("any_peer", "reliable", "call_remote")
func _request_delete_instance(id: String) -> void:
	if not is_multiplayer_authority():
		return
		
	# Server validates and broadcasts deletion
	if _instances.has(id):
		_delete_instance.rpc(id)
		_perform_delete(id)

@rpc("authority", "reliable", "call_local")
func _delete_instance(id: String) -> void:
	_perform_delete(id) 
