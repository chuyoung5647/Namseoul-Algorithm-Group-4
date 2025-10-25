extends Node2D

const IngredientCardScene = preload("res://ingredient_card.tscn")
#재료카드 관리
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
	"용암구이": ["용암고기", "바다소금", "허브"],
}

# --- 재료 이미지 맵(추가한 3개 포함) ---
var card_textures = {
	"불꽃버섯": preload("res://Images/불꽃버섯-removebg-preview.png"),
	"얼음나무 열매": preload("res://Images/얼음사과-removebg-preview.png"),
	"독초": preload("res://Images/독초-removebg-preview.png"),
	"용암고기": preload("res://Images/용암고기-removebg-preview.png"),
	"바다소금": preload("res://Images/소금-removebg-preview.png"),
	"허브": preload("res://Images/허브-removebg-preview.png"),
}

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


func get_new_order():
	# 만약 주문 목록이 비었다면,
	if order_list.is_empty():
		# 'recipes' 딕셔너리에서 모든 요리 이름(key)을 가져와
		# 새로운 주문 목록을 만듭니다.
		order_list = recipes.keys()
		# 그리고 다시 섞어서 순서가 매번 다르게 나오도록 합니다.
		order_list.shuffle()

	# 주문 목록의 맨 앞에서 '요리 이름' 하나만 꺼내옵니다.
	current_order = order_list.pop_front()
	# 몬스터 라벨에 주문을 표시합니다.
	monster_label.text = "주문: " + current_order

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

func _on_draw_button_pressed():
	if not deck.is_empty() and hand_cards.size() < 5:
		var card_name = deck.pop_front()
		var new_card = IngredientCardScene.instantiate()
		player_hand.add_child(new_card)
		new_card.setup(card_name, card_textures[card_name])
		hand_cards.append(new_card)
		new_card.card_picked_up.connect(_on_card_picked_up)
		if deck.is_empty():
			deck = card_textures.keys()
			deck.shuffle()

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
			
	if not recipes.has(current_order):
		result_label.text = "이 주문의 레시피가 없습니다."
		return
		
	var required_ingredients = recipes[current_order]
	if placed_ingredients == required_ingredients:
		result_label.text = current_order + " 완성!"
		monster_label.text = "맛있겠다!"
	else:
		result_label.text = "이상한 요리가 나왔다..."

	for slot_name in cards_in_slots:
		if cards_in_slots[slot_name]:
			cards_in_slots[slot_name].queue_free()
			cards_in_slots[slot_name] = null
	
	await get_tree().create_timer(2.0).timeout
	result_label.text = ""
	get_new_order()
