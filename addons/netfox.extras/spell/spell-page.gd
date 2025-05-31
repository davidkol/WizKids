extends Node3D
class_name SpellPage

## The spell this page represents.
var spell: NetworkSpell

## The mesh for the page.
@onready var page_mesh: MeshInstance3D = $PageMesh

## The container for spell effects.
@onready var effects_container: Node3D = $EffectsContainer

## The container for spell information.
@onready var info_container: Node3D = $InfoContainer

## Initialize the page with a spell.
func initialize(spell: NetworkSpell):
	self.spell = spell
	
	# Set up the page mesh
	_setup_page_mesh()
	
	# Set up spell information
	_setup_spell_info()
	
	# Set up spell effects
	_setup_spell_effects()

## Set up the page mesh with appropriate materials and animations.
func _setup_page_mesh():
	# Create a simple page mesh if none exists
	if not page_mesh:
		var mesh = PlaneMesh.new()
		mesh.size = Vector2(1, 1.5)  # Standard book page size
		page_mesh = MeshInstance3D.new()
		page_mesh.mesh = mesh
		add_child(page_mesh)
		move_child(page_mesh, 0)
	
	# Create a material for the page
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.95, 0.95, 0.9)  # Slightly off-white
	material.roughness = 0.8
	page_mesh.material_override = material

## Set up the spell information display.
func _setup_spell_info():
	# Create containers if they don't exist
	if not info_container:
		info_container = Node3D.new()
		info_container.name = "InfoContainer"
		add_child(info_container)
	
	# Add spell name
	var name_label = Label3D.new()
	name_label.text = spell.name
	name_label.font_size = 24
	name_label.position = Vector3(0, 0.5, 0.01)
	info_container.add_child(name_label)
	
	# Add spell description
	var desc_label = Label3D.new()
	desc_label.text = spell.description
	desc_label.font_size = 16
	desc_label.position = Vector3(0, 0.3, 0.01)
	info_container.add_child(desc_label)
	
	# Add spell stats
	var stats_label = Label3D.new()
	stats_label.text = "Mana Cost: %d\nCooldown: %.1fs" % [spell.mana_cost, spell.cooldown]
	stats_label.font_size = 14
	stats_label.position = Vector3(0, 0, 0.01)
	info_container.add_child(stats_label)

## Set up visual effects for the spell.
func _setup_spell_effects():
	# Create container if it doesn't exist
	if not effects_container:
		effects_container = Node3D.new()
		effects_container.name = "EffectsContainer"
		add_child(effects_container)
	
	# Add a particle system for ambient effects
	var particles = GPUParticles3D.new()
	particles.emitting = true
	particles.amount = 20
	particles.lifetime = 2.0
	particles.position = Vector3(0, 0, 0.02)
	effects_container.add_child(particles)
	
	# Add a light for illumination
	var light = OmniLight3D.new()
	light.light_color = Color(0.8, 0.8, 1.0)
	light.light_energy = 0.5
	light.omni_range = 2.0
	light.position = Vector3(0, 0, 0.1)
	effects_container.add_child(light)

## Play a casting animation when the spell is cast.
func play_cast_animation():
	# Create a flash effect
	var flash = GPUParticles3D.new()
	flash.amount = 50
	flash.lifetime = 0.5
	flash.position = Vector3(0, 0, 0.02)
	effects_container.add_child(flash)
	
	# Animate the page
	var tween = create_tween()
	tween.tween_property(page_mesh, "rotation:x", PI/4, 0.2)
	tween.tween_property(page_mesh, "rotation:x", 0, 0.2)
	
	# Remove the flash after animation
	await tween.finished
	flash.queue_free() 
