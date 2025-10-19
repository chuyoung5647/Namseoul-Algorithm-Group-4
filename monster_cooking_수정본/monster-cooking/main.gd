extends Node2D

# --- 씬 경로(너의 프로젝트 경로에 맞게 변경) ---
const IngredientCardScene = preload("res://scenes/ingredient_card.tscn")
# 만약 씬이 res://scenes/ingredient_card.tscn 이면 위 경로를 바꿔줘!

# --- 재료(덱) 관리 ---
var deck = ["불꽃버섯", "얼음나무 열매", "독초", "용암고기", "바다소금", "허브"]
var hand_cards = []
var cards_in_slots = {
	"IngredientSlot1": null,
	"IngredientSlot2": null,
	"IngredientSlot3": null
}

var currently_dragged_card = null

# --- 주문(음식) 관리 ---
var order_list = ["매콤한 스튜", "용암구이"]
var current_order = ""

# --- 레시피(요리법) ---
var recipes = {
	"매콤한 스튜": ["불꽃버섯", "얼음나무 열매", "독초"],
	"용암구이": ["용암고기", "바다소금", "허브"]
}

# --- 재료 이미지 맵(추가한 3개 포함) ---
var card_textures = {
	"불꽃버섯": preload("res://Images/fire_mushroom.png"),
	"얼음나무 열매": preload("res://Images/ice_fruit.png"),
	"독초": preload("res://Images/poison_herb.png"),
	"용암고기": preload("res://Images/lava_meat.png"),
	"바다소금": preload("res://Images/sea_salt.png"),
	"허브": preload("res://Images/fresh_herb.png")
}

# --- 노드 참조(신(scene) 구조에 따라 경로가 다르면 바꿔줘) ---
@onready var player_hand = $PlayerHand
@onready var cooking_area = $CookingArea
@onready var monster_label = $Monster/OrderLabel
@onready var result_label = $ResultLabel
@onready var draw_button = $DrawButton
@onready var combine_button = $CombineButton

func _ready():
	get_new_order()
	deck.shuffle()
	draw_button.pressed.connect(_on_draw_button_pressed)
	combine_button.pressed.connect(_on_combine_button_pressed)

# --- 주문 뽑기 ---
func get_new_order():
	if order_list.is_empty():
		order_list = recipes.keys()
		order_list.shuffle()
	current_order = order_list.pop_front()
	monster_label.text = "주문: " + current_order

# --- 카드 픽업(IngredientCard 씬에서 emit한 시그널로 호출) ---
func _on_card_picked_up(card):
	if currently_dragged_card: return
	currently_dragged_card = card
	if card.is_in_pot:
		card.is_in_pot = false
		for slot_name in cards_in_slots:
			if cards_in_slots[slot_name] == card:
				cards_in_slots[slot_name] = null
				break

	var card_global_pos = card.global_position
	if card.get_parent() != self:
		card.get_parent().remove_child(card)
		add_child(card)
		card.global_position = card_global_pos
	card.z_index = 10

# --- 드래그 드롭 처리 ---
func _input(event: InputEvent):
	if currently_dragged_card:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed():
			var dropped_card = currently_dragged_card
			currently_dragged_card = null
			var mouse_pos = get_global_mouse_position()
			var dropped_on_slot = false
			for slot_name in cards_in_slots:
				var slot_node = cooking_area.get_node(slot_name)
				var background = slot_node.get_node("Background")
				var background_rect = background.get_global_rect()
				if background_rect.has_point(mouse_pos):
					if not cards_in_slots[slot_name]:
						dropped_on_slot = true
						var slot_center = background.global_position + (background.size / 2)
						dropped_card.size = background.size
						dropped_card.global_position = slot_center - (dropped_card.size / 2)
						dropped_card.z_index = 1
						dropped_card.is_in_pot = true
						cards_in_slots[slot_name] = dropped_card
						hand_cards.erase(dropped_card)
						break 
			if not dropped_on_slot:
				dropped_card.z_index = 0
				if not hand_cards.has(dropped_card):
					hand_cards.append(dropped_card)
				if dropped_card.get_parent() == self:
					remove_child(dropped_card)
				player_hand.add_child(dropped_card)

func _process(delta):
	if currently_dragged_card:
		currently_dragged_card.global_position = get_global_mouse_position() - (currently_dragged_card.size / 2)

# --- 카드 뽑기 버튼 동작 ---
func _on_draw_button_pressed():
	if not deck.is_empty() and hand_cards.size() < 5:
		var card_name = deck.pop_front()
		var new_card = IngredientCardScene.instantiate()
		player_hand.add_child(new_card)
		# setup 함수는 ingredient_card.gd에 있어야 하고 (name, texture) 받음
		new_card.setup(card_name, card_textures[card_name])
		hand_cards.append(new_card)
		new_card.card_picked_up.connect(_on_card_picked_up)
		if deck.is_empty():
			deck = card_textures.keys()
			deck.shuffle()

# --- 합성 버튼 동작 ---
func _on_combine_button_pressed():
	check_recipe()

func check_recipe():
	var placed_ingredients = []
	for i in range(1, 4):
		var slot_name = "IngredientSlot%d" % i
		var card = cards_in_slots[slot_name]
		if card:
			placed_ingredients.append(card.card_name)
		else:
			placed_ingredients.append("빈칸")

	# 현재 주문에 필요한 재료
	if not recipes.has(current_order):
		result_label.text = "이 주문의 레시피가 없습니다."
		return

	var required_ingredients = recipes[current_order]
	if placed_ingredients == required_ingredients:
		result_label.text = current_order + " 완성!"
		monster_label.text = "맛있겠다!"
	else:
		result_label.text = "이상한 요리가 나왔다..."

	# 슬롯 정리
	for slot_name in cards_in_slots:
		if cards_in_slots[slot_name]:
			cards_in_slots[slot_name].queue_free()
			cards_in_slots[slot_name] = null

	await get_tree().create_timer(2.0).timeout
	result_label.text = ""
	get_new_order()
