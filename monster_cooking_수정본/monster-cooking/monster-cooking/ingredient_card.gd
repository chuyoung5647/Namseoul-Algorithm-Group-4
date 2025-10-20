extends TextureRect

signal card_picked_up(card)

var card_name: String
var is_in_pot = false

func _ready():
	custom_minimum_size = Vector2(100, 140)

func setup(name: String, tex: Texture):
	card_name = name
	self.texture = tex
	$Label.text = name

func _init():
	mouse_filter = MOUSE_FILTER_STOP

func _gui_input(event: InputEvent):
	# is_in_pot 체크를 제거하여 슬롯 안의 카드도 다시 집을 수 있게 합니다.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		emit_signal("card_picked_up", self)
