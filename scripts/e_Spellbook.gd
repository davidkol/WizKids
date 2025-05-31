extends NetworkScene
class_name e_Spellbook

@export var input:c_PlayerInput

@export var spell: PackedScene
@export var flip_cooldown: float = 0.65

var activation_tick: int = -1
var current_spell:NetworkSpell

func _ready():
	NetworkTime.on_tick.connect(_tick)
	NetworkEvents.on_peer_join.connect(_handle_new_peer)

func _can_activate() -> bool:
	return NetworkTime.seconds_between(activation_tick, NetworkTime.tick) >= flip_cooldown

func _can_peer_use(peer_id: int) -> bool:
	return peer_id == input.get_multiplayer_authority()

func _spawn() -> Node3D:
	var spell_scene: NetworkSpell = spell.instantiate() as NetworkSpell
	spell_scene.input = input
	spell_scene.spawn_point = $SpawnPoint
	$RightPage.add_child(spell_scene, true)
	current_spell = spell_scene
	return spell_scene

func _tick(_delta: float, _t: int):
	if input.flip:
		activate()
	if input.activate and current_spell:
		current_spell.activate()

func _after_activation(_instance: Node3D):
	activation_tick = NetworkTime.tick
