extends TextureRect

signal card_picked_up(card)

var card_name: String
var is_in_pot = false

func _ready():
	custom_minimum_size = Vector2(100, 140)#노드의 경계사각형의 가장작은사이즈에 크기조정

func setup(name: String, tex: Texture):
	card_name = name
	self.texture = tex
	$Label.text = name
#처음 만들어지면 발동
func _init():
	mouse_filter = MOUSE_FILTER_STOP

func _gui_input(event: InputEvent): #입력이벤트를 매개변수로 받고 작동?하나, 아마 텍스쳐에 클릭하는걸 반응할듯
	# is_in_pot 체크를 제거하여 냄비 안의 카드도 다시 집을 수 있게 합니다.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		emit_signal("card_picked_up", self) #마우스 왼클릭을 감지하면 신호를 보낸다.
