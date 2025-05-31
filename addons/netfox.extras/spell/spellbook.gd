extends Node3D
class_name Spellbook

## The scene for a spellbook page.
@export var page_scene: PackedScene

## The collection of spells in this spellbook.
var spells: Array[NetworkSpell] = []

## The current page being displayed.
var current_page: int = 0

## The 3D model of the book.
@onready var book_model: Node3D = $BookModel

## The container for spell pages.
@onready var pages_container: Node3D = $PagesContainer

## The owner of this spellbook.
var spellbook_owner: Node

func _ready():
	# Initialize the book model and pages
	_initialize_book()
	
	# Add the book to the "spellbooks" group
	add_to_group("spellbooks")

## Initialize the book model and create pages for each spell.
func _initialize_book():
	# Create pages for each spell
	for spell in spells:
		var page = page_scene.instantiate()
		pages_container.add_child(page)
		page.initialize(spell)
	
	# Show the first page
	_show_page(0)

## Show a specific page in the spellbook.
func _show_page(page_index: int):
	# Hide all pages
	for page in pages_container.get_children():
		page.visible = false
	
	# Show the requested page
	if page_index >= 0 and page_index < pages_container.get_child_count():
		pages_container.get_child(page_index).visible = true
		current_page = page_index

## Turn to the next page.
func next_page():
	if current_page < pages_container.get_child_count() - 1:
		_show_page(current_page + 1)

## Turn to the previous page.
func previous_page():
	if current_page > 0:
		_show_page(current_page - 1)

## Cast the spell on the current page.
func cast_current_spell():
	if current_page >= 0 and current_page < spells.size():
		var spell = spells[current_page]
		spell.caster = spellbook_owner
		spell.activate()

## Add a spell to the spellbook.
func add_spell(spell: NetworkSpell):
	spells.append(spell)
	
	# If this is the first spell, create the page
	if spells.size() == 1:
		_initialize_book()
	else:
		# Add a new page for the spell
		var page = page_scene.instantiate()
		pages_container.add_child(page)
		page.initialize(spell)

## Remove a spell from the spellbook.
func remove_spell(spell: NetworkSpell):
	var index = spells.find(spell)
	if index != -1:
		spells.remove_at(index)
		
		# Remove the page
		if index < pages_container.get_child_count():
			pages_container.get_child(index).queue_free()
		
		# Update current page if needed
		if current_page >= spells.size():
			current_page = max(0, spells.size() - 1)
			_show_page(current_page) 