extends Control
@onready var tex_rect = $TextureRect

signal card_picked_up(card)

var card_name: String
var is_in_pot = false

func _ready():
	custom_minimum_size = Vector2(100, 140)
	mouse_filter = MOUSE_FILTER_STOP
# [수정 후]
# 매개변수 이름을 'name' -> 'new_name'으로 변경 (이름 충돌 방지)
func setup(new_name: String, tex: Texture):
	card_name = new_name      # 내부 변수에 바뀐 이름(new_name) 대입
	tex_rect.texture = tex
	$Label.text = new_name    # 라벨 텍스트도 바뀐 이름(new_name)으로 설정

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		emit_signal("card_picked_up", self)
