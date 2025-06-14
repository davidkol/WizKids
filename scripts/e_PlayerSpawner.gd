extends Node

@export var player_scene: PackedScene
@export var spawn_points: Array[Marker3D] = []

var avatars: Dictionary = {}

static var _logger := _NetfoxLogger.new("RollbackFPSComposition", "PlayerSpawner")

func _ready():
	NetworkEvents.on_client_start.connect(_handle_connected)
	NetworkEvents.on_server_start.connect(_handle_host)
	NetworkEvents.on_peer_join.connect(_handle_new_peer)
	NetworkEvents.on_peer_leave.connect(_handle_leave)
	NetworkEvents.on_client_stop.connect(_handle_stop)
	NetworkEvents.on_server_stop.connect(_handle_stop)

func _handle_connected(id: int):
	# Spawn an avatar for us
	_spawn(id)

func _handle_host():
	# Spawn own avatar on host machine
	_spawn(1)

func _handle_new_peer(id: int):
	# Spawn an avatar for new player
	_spawn(id)

func _handle_leave(id: int):
	if not avatars.has(id):
		return

	var avatar = avatars[id] as Node
	avatar.queue_free()
	avatars.erase(id)

func _handle_stop():
	# Remove all avatars on game end
	for avatar in avatars.values():
		avatar.queue_free()
	avatars.clear()

func _spawn(id: int):
	var avatar = player_scene.instantiate() as Node
	avatars[id] = avatar
	avatar.name += " #%d" % id
	add_child(avatar)
	avatar.global_position = get_next_spawn_point(id)
	
	# Avatar is always owned by server
	avatar.set_multiplayer_authority(1)

	_logger.info("Spawned avatar %s at %s" % [avatar.name, multiplayer.get_unique_id()])

	# Avatar's input object is owned by player
	var input = avatar.find_child("input")
	if input != null:
		input.set_multiplayer_authority(id)
		_logger.info("Set input(%s) ownership to %s" % [input.name, id])

func get_next_spawn_point(_peer_id: int, _spawn_idx: int = 0) -> Vector3:
	return spawn_points[avatars.size()-1].global_position
