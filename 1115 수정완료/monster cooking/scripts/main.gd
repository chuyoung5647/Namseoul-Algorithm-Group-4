extends Node2D

# --- 씬 경로 ---
const IngredientCardScene = preload("res://scenes/ingredient_card.tscn")

# --- 재료(덱) 관리 ---
var deck = [
	"불꽃버섯", "얼음나무 열매", "독초",
	"용암고기", "바다소금", "허브",
	"황금생선", "마법가루"
]

# --- 레시피(요리법) ---
var recipes = {
	"매콤한 스튜": ["불꽃버섯", "얼음나무 열매", "독초"],
	"용암구이": ["용암고기", "바다소금", "허브"],
	"황금생선찜": ["황금생선", "바다소금", "허브"],
	"비밀의 스프": ["마법가루", "불꽃버섯", "얼음나무 열매"]
}

# --- 재료 이미지 맵 ---
var card_textures = {
	"불꽃버섯": preload("res://Images/test_image/resource/resource_fire_mushroom.png"),
	"얼음나무 열매": preload("res://Images/test_image/resource/resource_ice_fruit.png"),
	"독초": preload("res://Images/test_image/resource/resource_poison_herb.png"),
	"용암고기": preload("res://Images/test_image/resource/resource_lava_meat.png"),
	"바다소금": preload("res://Images/test_image/resource/resource_sea_salt.png"),
	"허브": preload("res://Images/test_image/resource/resource_fresh_herb.png"),
	"황금생선": preload("res://Images/test_image/resource/resource_golden_fish.png"),
	"마법가루": preload("res://Images/test_image/resource/resource_magic_powder.png")
}

# --- 만족도 시스템 밸런스 ---
# (SATISFACTION_START는 GameStats.gd로 이동)
const SATISFACTION_TIME_TIER_1: float = 5.0  # 5초 이내
const SATISFACTION_SCORE_TIER_1: int = 10   # +10점
const SATISFACTION_TIME_TIER_2: float = 10.0 # 10초 이내
const SATISFACTION_SCORE_TIER_2: int = 5    # +5점
const SATISFACTION_TIME_TIER_3: float = 15.0 # 15초 이내
const SATISFACTION_SCORE_TIER_3: int = 1    # +1점
const SATISFACTION_SCORE_LATE: int = -3     # 15초 초과 시
const SATISFACTION_SCORE_FAIL: int = -5     # 요리 실패 시

# --- 상태 변수 ---
var order_list: Array = []
var current_order: String = ""
var cards_in_slots = {}
var hand_cards: Array = []
var currently_dragged_card = null
# (total_satisfaction은 GameStats.gd로 이동)

# --- 리롤 관련 ---
const MAX_REROLL: int = 2
var reroll_count: int = 0
var selected_for_reroll: Array = []

# --- 게임 타이머 관련 ---
var game_time_limit: float = 60.0  # 전체 제한 시간 (초 단위)
var remaining_time: float = game_time_limit
var game_over: bool = false

# --- 사운드 ---
const card_draw = preload("res://sound/card draw.wav")
const combine = preload("res://sound/(튀김)餃子を揚げる.mp3")
const new_order = preload("res://sound/the_sound_of_bells_w_#1-1762585193096 (1).mp3")
const success = preload("res://sound/success.wav")
const money = preload("res://sound/(돈소리)お金がジャラジャラ.mp3")
const wrong = preload("res://sound/the_sound_of_wrong_#3-1762585638727.mp3")
const timeover = preload("res://sound/(타임오버)柱時計の鐘.mp3")
const reroll = preload("res://sound/(리롤)カードをきる2.mp3")

# --- 노드 참조 ---
@onready var player_hand = $PlayerHand
@onready var cooking_area = $CookingArea
@onready var monster_label = $Monster/OrderLabel
@onready var result_label = $ResultLabel
@onready var draw_button = $DrawButton
@onready var combine_button = $CombineButton
@onready var monster_node = $Monster
@onready var reroll_button = $RerollButton
@onready var reroll_label = $RerollLabel
@onready var game_timer_label = $GameTimerLabel
@onready var order_timer = $OrderTimer
@onready var satisfaction_label = $SatisfactionLabel
@onready var pause_overlay = $PauseOverlay 

# --- 사운드 노드 참조 ---
@onready var button_click_sound: AudioStreamPlayer2D = $button_click_sound
@onready var game_timer_sound: AudioStreamPlayer2D = $timer
@onready var result_sound: AudioStreamPlayer2D = $result_sound


func _ready():
	# 슬롯 등록
	for i in range(1, 4):
		var slot_name = "IngredientSlot%d" % i
		cards_in_slots[slot_name] = null

	get_new_order()
	deck.shuffle()

	# 버튼 신호 연결
	 #해당 부분은 의미가 없는것으로 보임 2025-11-12
	# 필요없어 보였던건 버튼노드에서 함수에 직접 연결한것과 이 코드가 중복된 역할을 수행하고 있었기 때문. 
	# 현재는 혹시모를 오류를 방지하기위해 둘 다 살려두고 추가작업들이 모두 끝났을떄 둘중 하나를 제거하겠음.(2025-11-15)
	if draw_button:
		draw_button.connect("pressed", Callable(self, "_on_draw_button_pressed"))
	if combine_button:
		combine_button.connect("pressed", Callable(self, "_on_combine_button_pressed"))
	if reroll_button:
		reroll_button.connect("pressed", Callable(self, "_on_reroll_button_pressed"))
	
	# 일시정지 버튼 신호 연결
	var resume_button = pause_overlay.get_node("VBoxContainer/ResumeButton")
	resume_button.connect("pressed", Callable(self, "_on_resume_button_pressed"))
	
	var main_menu_button = pause_overlay.get_node("VBoxContainer/MainMenuButton")
	main_menu_button.connect("pressed", Callable(self, "_on_main_menu_button_pressed"))

	_update_reroll_label()
	_update_game_timer_label()
	_update_satisfaction_label() # GameStats의 값으로 라벨을 초기화

# --- 주문 뽑기 ---
func get_new_order():
	if game_over: return
	
	var monster_id = randi() % 3
	monster_node.set_monster(monster_id)

	current_order = monster_node.m_order
	monster_label.text = "주문: " + current_order
	
	get_new_order_sound_play() 
	
	# 주문 타이머 시작
	order_timer.wait_time = SATISFACTION_TIME_TIER_3
	order_timer.start()

# --- 카드 픽업 ---
func _on_card_picked_up(card):
	if game_over: return
	
	if currently_dragged_card:
		return
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

# --- 리롤 선택 토글 ---
func _on_card_reroll_toggled(card, selected):
	if card.is_in_pot:
		if selected:
			if selected_for_reroll.has(card):
				selected_for_reroll.erase(card)
			result_label.text = "포트에 있는 카드는 리롤할 수 없습니다."
			await get_tree().create_timer(1.2).timeout
			result_label.text = ""
		return

	if selected:
		if not selected_for_reroll.has(card):
			selected_for_reroll.append(card)
	else:
		if selected_for_reroll.has(card):
			selected_for_reroll.erase(card)

# --- 드래그/드롭 ---
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
						if selected_for_reroll.has(dropped_card):
							selected_for_reroll.erase(dropped_card)
						break
			if not dropped_on_slot:
				dropped_card.z_index = 0
				if not hand_cards.has(dropped_card):
					hand_cards.append(dropped_card)
				if dropped_card.get_parent() == self:
					remove_child(dropped_card)
				player_hand.add_child(dropped_card)

# --- 메인 루프 (Process) ---
func _process(delta):
	# '일시정지' (ESC 키) 
	if Input.is_action_just_pressed("ui_cancel"):
		if get_tree().paused:
			get_tree().paused = false
			pause_overlay.hide()
		else:
			get_tree().paused = true
			pause_overlay.show()
	
	if get_tree().paused:
		return
	
	
	# 카드 드래그 처리
	if currently_dragged_card:
		currently_dragged_card.global_position = get_global_mouse_position() - (currently_dragged_card.size / 2)

	# 전체 게임 타이머 갱신
	if not game_over:
		remaining_time -= delta
		
		# 10초 남았을 때 사운드
		if "%.1f" % remaining_time == "10.0": 
			almost_time_out_sound_play()
			
		if remaining_time <= 0:
			remaining_time = 0
			_on_game_over() # 시간으로 인한 게임 오버
		_update_game_timer_label()

# --- 카드 뽑기 ---
func _on_draw_button_pressed():
	if game_over: return

	if deck.is_empty():
		deck = Array(card_textures.keys())
		deck.shuffle()

	if not deck.is_empty() and hand_cards.size() < 5:
		var card_name = deck.pop_front()
		var new_card = IngredientCardScene.instantiate()
		player_hand.add_child(new_card)
		new_card.setup(card_name, card_textures[card_name])
		
		draw_button_sound_play() 
		
		hand_cards.append(new_card)
		if new_card.has_signal("card_picked_up"):
			new_card.connect("card_picked_up", Callable(self, "_on_card_picked_up"))
		if new_card.has_signal("reroll_toggled"):
			new_card.connect("reroll_toggled", Callable(self, "_on_card_reroll_toggled"))

# --- 합성 버튼 (메인 로직) ---
func _on_combine_button_pressed():
	if game_over: return

	# 주문 타이머 정지 및 시간 계산
	order_timer.stop()
	var elapsed_time = order_timer.wait_time - order_timer.time_left

	# 레시피 검사 실행
	var success = check_recipe_specialist() 

	# 만족도 시스템 처리
	process_satisfaction_logic(success, elapsed_time)
	
	if game_over: return # 만족도가 0이 되어 게임오버 되면, 아래 로직 실행 안 함

	# 슬롯 정리
	for slot_name in cards_in_slots:
		var card_node = cards_in_slots[slot_name]
		if card_node and is_instance_valid(card_node):
			card_node.queue_free()
		cards_in_slots[slot_name] = null

	# 다음 주문
	await get_tree().create_timer(2.0).timeout
	result_label.text = ""
	get_new_order()

# --- 조합 검사  ---
# 레시피 일치 여부만 검사하여 true/false 반환
func check_recipe_specialist() -> bool:
	var placed_ingredients = []
	for i in range(1, 4):
		var slot_name = "IngredientSlot%d" % i
		var card = cards_in_slots.get(slot_name, null)
		
		if card and "card_name" in card:
			if card.card_name:
				placed_ingredients.append(card.card_name)
			else:
				placed_ingredients.append("빈칸")
		elif card:
			placed_ingredients.append("빈칸")
		else:
			placed_ingredients.append("빈칸")

	if not recipes.has(current_order):
		result_label.text = "이 주문의 레시피가 없습니다."
		return false

	var required_ingredients = recipes[current_order].duplicate()
	placed_ingredients.sort()
	required_ingredients.sort()

	if placed_ingredients == required_ingredients:
		return true
	else:
		return false

# --- 리롤 버튼 ---
func _on_reroll_button_pressed():
	if game_over: return

	if reroll_count >= MAX_REROLL:
		result_label.text = "리롤 기회가 없습니다!"
		return

	if hand_cards.is_empty():
		result_label.text = "버릴 카드가 없습니다!"
		return

	reroll_button_sound_play() 
	
	var to_reroll: Array = []
	if selected_for_reroll.size() > 0:
		to_reroll = selected_for_reroll.duplicate()
	else:
		to_reroll = hand_cards.duplicate()

	for card in to_reroll:
		if is_instance_valid(card):
			deck.append(card.card_name)
			if card.get_parent():
				card.get_parent().remove_child(card)
			card.queue_free()
			hand_cards.erase(card)

	deck.shuffle()

	var count_to_draw = to_reroll.size()
	for i in range(count_to_draw):
		if deck.is_empty():
			deck = Array(card_textures.keys())
			deck.shuffle()
		if deck.is_empty():
			break
		var card_name = deck.pop_front()
		var new_card = IngredientCardScene.instantiate()
		player_hand.add_child(new_card)
		new_card.setup(card_name, card_textures[card_name])
		hand_cards.append(new_card)
		if new_card.has_signal("card_picked_up"):
			new_card.connect("card_picked_up", Callable(self, "_on_card_picked_up"))
		if new_card.has_signal("reroll_toggled"):
			new_card.connect("reroll_toggled", Callable(self, "_on_card_reroll_toggled"))

	selected_for_reroll.clear()

	reroll_count += 1
	_update_reroll_label()

	result_label.text = "리롤 사용: %d / %d" % [reroll_count, MAX_REROLL]
	if reroll_count >= MAX_REROLL and reroll_button:
		reroll_button.disabled = true

# --- 리롤 라벨 갱신 ---
func _update_reroll_label():
	if reroll_label:
		var remain = MAX_REROLL - reroll_count
		if remain < 0:
			remain = 0
		reroll_label.text = "남은 리롤: %d" % remain

# --- 게임 타이머 라벨 갱신 ---
func _update_game_timer_label():
	if game_timer_label:
		game_timer_label.text = "남은 시간: %.1f초" % remaining_time

# --- 게임 종료 처리 ---
func _on_game_over():
	if game_over: return # 중복 호출 방지
	
	game_over = true
	result_label.text = "게임 오버!"
	
	reroll_button.disabled = true
	combine_button.disabled = true
	draw_button.disabled = true

	# 카드 드래그 불가 처리
	for card in hand_cards:
		if is_instance_valid(card):
			card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for slot_name in cards_in_slots:
		var card = cards_in_slots[slot_name]
		if card and is_instance_valid(card):
			card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 2초 뒤에 게임 오버 씬으로 이동
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/game_over.tscn")

# --- 만족도 시스템 함수 ---

# 만족도 로직 종합 처리 (UI, 점수, 보상)
func process_satisfaction_logic(success: bool, elapsed_time: float):
	
	var satisfaction_change = _calculate_satisfaction_score(success, elapsed_time)
	
	GameStats.total_satisfaction += satisfaction_change
	_update_satisfaction_label()

	# 만족도 0 이하 시 게임 오버 처리
	if GameStats.total_satisfaction <= 0:
		GameStats.total_satisfaction = 0 # 0 이하로 내려가지 않게
		_update_satisfaction_label()
		_on_game_over() # 만족도로 인한 게임 오버
		return

	if success:
		result_label.text = "완성! (만족도 %+d)" % satisfaction_change
		monster_label.text = "맛있겠다!"
		
		combine_success_sound_play() 
		
		# 리롤 보상 로직
		if reroll_count > 0:
			reroll_count -= 1
			_update_reroll_label()
			result_label.text += "\n리롤 기회 +1!"
			reroll_button.disabled = false
	else:
		result_label.text = "이상한 요리가 나왔다... (만족도 %d)" % satisfaction_change
		
		combine_fail_sound_play() 
		
		# 전체 타이머 감소 로직을 여기에 추가할 수 있습니다.
		# 예: remaining_time -= 5.0

# 만족도 점수 계산 (순수 함수)
func _calculate_satisfaction_score(success: bool, elapsed_time: float) -> int:
	if not success:
		GameStats.fail_count += 1 # GameStats에 실패 횟수 기록
		return SATISFACTION_SCORE_FAIL 

	# 성공 시
	GameStats.success_count += 1 # GameStats에 성공 횟수 기록
	
	if elapsed_time <= SATISFACTION_TIME_TIER_1:
		return SATISFACTION_SCORE_TIER_1
	elif elapsed_time <= SATISFACTION_TIME_TIER_2:
		return SATISFACTION_SCORE_TIER_2
	elif elapsed_time <= SATISFACTION_TIME_TIER_3:
		return SATISFACTION_SCORE_TIER_3
	else:
		return SATISFACTION_SCORE_LATE

# 만족도 라벨 갱신
func _update_satisfaction_label():
	if satisfaction_label:
		satisfaction_label.text = "현재 만족도: %d" % GameStats.total_satisfaction
		
		
# --- 사운드 작동 함수 ---
func draw_button_sound_play(): #드로우 버튼 
	button_click_sound.stream = card_draw
	button_click_sound.play()
func reroll_button_sound_play(): #리롤 버튼 
	button_click_sound.stream = reroll
	button_click_sound.play()
func get_new_order_sound_play(): #새로운 주문이 들어오면 작동 
	result_sound.stream = new_order
	result_sound.play()
func combine_fail_sound_play(): #조합실패시 
	result_sound.stream = combine
	result_sound.play()
	await get_tree().create_timer(1.0).timeout
	result_sound.stream = wrong
	result_sound.play()
func combine_success_sound_play(): #조합성공시 
	result_sound.stream = combine
	result_sound.play()
	await get_tree().create_timer(1.0).timeout
	result_sound.stream = success
	result_sound.play()
	await get_tree().create_timer(0.45).timeout
	result_sound.stream = money
	result_sound.play()
func almost_time_out_sound_play(): #시간 10초 남았을 때 작동 
	game_timer_sound.play()
	await get_tree().create_timer(10.0).timeout
	game_timer_sound.stream = timeover
	game_timer_sound.play()
		
		
		
# --- '일시정지' 메뉴 함수 ---
func _on_resume_button_pressed():
	# '계속하기' 버튼: 일시정지를 풀고 메뉴를 숨김.
	get_tree().paused = false
	pause_overlay.hide()

func _on_main_menu_button_pressed():
	# '메인메N' 버튼: 일시정지를 '반드시' 먼저 풀고 씬을 변경함.
	get_tree().paused = false
	#메인메뉴 씬 경로
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
