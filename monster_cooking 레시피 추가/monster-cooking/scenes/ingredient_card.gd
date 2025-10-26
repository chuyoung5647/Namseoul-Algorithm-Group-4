extends Control
@onready var tex_rect = $TextureRect

signal card_picked_up(card)

var card_name: String
var is_in_pot = false

func _ready():
	custom_minimum_size = Vector2(100, 140)
	mouse_filter = MOUSE_FILTER_STOP

func setup(name: String, tex: Texture):
	card_name = name
	tex_rect.texture = tex
	$Label.text = name

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		emit_signal("card_picked_up", self)
