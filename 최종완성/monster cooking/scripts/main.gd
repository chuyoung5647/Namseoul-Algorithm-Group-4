extends Node2D

# --- 씬 경로 ---
const IngredientCardScene = preload("res://scenes/ingredient_card.tscn")

# --- 재료(덱) 관리 ---
var deck = [
	"불꽃버섯", "얼음나무 열매", "독초",
	"용암고기", "바다소금", "허브",
	"황금생선", "마법가루"
]

#레시피 관리
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
const SATISFACTION_TIME_TIER_1: float = 5.0
const SATISFACTION_SCORE_TIER_1: int = 10
const SATISFACTION_TIME_TIER_2: float = 10.0
const SATISFACTION_SCORE_TIER_2: int = 5
const SATISFACTION_TIME_TIER_3: float = 15.0
const SATISFACTION_SCORE_TIER_3: int = 1
const SATISFACTION_SCORE_LATE: int = -3
const SATISFACTION_SCORE_FAIL: int = -5
# 주문마감시간 기준
const ORDER_TIME_LIMIT: float = 30.0 

# --- 상태 변수 ---
var order_list: Array = []
var current_order: String = ""
var cards_in_slots = {}
var hand_cards: Array = []
var currently_dragged_card = null

# --- 콤보 시스템 ---
var combo_count: int = 0   # 연속 성공 카운트

# --- 리롤 ---
const MAX_REROLL: int = 2
var reroll_count: int = 0
var selected_for_reroll: Array = []

# --- 게임 타이머 ---
var game_time_limit: float = 180.0
var remaining_time: float = game_time_limit
var game_over: bool = false

# --- 사운드 (변수명 충돌 해결: success -> success_sound) ---
const card_draw = preload("res://sound/card draw.wav")
const combine = preload("res://sound/(튀김)餃子を揚げる.mp3")
const new_order = preload("res://sound/the_sound_of_bells_w_#1-1762585193096 (1).mp3")
const success_sound = preload("res://sound/success.wav") 
const money = preload("res://sound/(돈소리)お金がジャラジャラ.mp3")
const wrong = preload("res://sound/the_sound_of_wrong_#3-1762585638727.mp3")
const timeover = preload("res://sound/(타임오버)柱時計の鐘.mp3")
const reroll = preload("res://sound/(리롤)カードをきる2.mp3")

# --- 노드 ---
@onready var player_hand = $PlayerHand
@onready var cooking_area = $CookingArea
@onready var monster_label = $Monster/OrderLabel
@onready var result_label = $ResultLabel
@onready var draw_button = $DrawButton
@onready var combine_button = $CombineButton
@onready var monster_node = $Monster
@onready var reroll_button = $RerollButton
@onready var reroll_label = $RerollLabel
@onready var order_timer = $OrderTimer
@onready var satisfaction_label = $SatisfactionLabel
@onready var pause_overlay = $PauseOverlay
@onready var recipe_guide_layer = $RecipeGuideLayer 

# --- ProgressBar & 내부 라벨 ---
@onready var timer_bar = $Timerbar
@onready var game_timer_label = $Timerbar/GameTimerLabel

# --- 사운드 노드 ---
@onready var button_click_sound: AudioStreamPlayer2D = $button_click_sound
@onready var game_timer_sound: AudioStreamPlayer2D = $timer
@onready var result_sound: AudioStreamPlayer2D = $result_sound

func _ready():
	# 슬롯 초기화
	for i in range(1, 4):
		cards_in_slots["IngredientSlot%d" % i] = null

	# 타이머 초기값 보장
	remaining_time = game_time_limit
	_update_game_timer_label()
	_update_satisfaction_label() # [복구] 초기 만족도 표시

	get_new_order()
	deck.shuffle()

	if draw_button:
		draw_button.connect("pressed", Callable(self, "_on_draw_button_pressed"))
	if combine_button:
		combine_button.connect("pressed", Callable(self, "_on_combine_button_pressed"))
	if reroll_button:
		reroll_button.connect("pressed", Callable(self, "_on_reroll_button_pressed"))

	# PauseOverlay가 씬에 있다면 연결
	if pause_overlay:
		var resume_button = pause_overlay.get_node_or_null("VBoxContainer/ResumeButton")
		if resume_button:
			resume_button.connect("pressed", Callable(self, "_on_resume_button_pressed"))

		var main_menu_button = pause_overlay.get_node_or_null("VBoxContainer/MainMenuButton")
		if main_menu_button:
			main_menu_button.connect("pressed", Callable(self, "_on_main_menu_button_pressed"))

	_update_reroll_label()

# --- 주문 ---
func get_new_order():
	if game_over: return

	var monster_id = randi() % 4
	monster_node.set_monster(monster_id)

	current_order = monster_node.m_order
	monster_label.text = "주문: " + current_order

	get_new_order_sound_play()

	order_timer.wait_time = ORDER_TIME_LIMIT
	order_timer.start()

# --- 카드 픽업 ---
func _on_card_picked_up(card):
	if game_over: return
	if currently_dragged_card: return

	currently_dragged_card = card

	if card.is_in_pot:
		card.is_in_pot = false
		for s in cards_in_slots:
			if cards_in_slots[s] == card:
				cards_in_slots[s] = null
				break

	var gpos = card.global_position
	if card.get_parent() != self:
		card.get_parent().remove_child(card)
		add_child(card)
		card.global_position = gpos
	card.z_index = 10

# --- 리롤 토글 ---
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
		selected_for_reroll.erase(card)

# --- 드래그 ---
func _input(event):
	# [추가] J키 레시피 가이드 
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_J:
			recipe_guide_layer.visible = !recipe_guide_layer.visible
			
			
	if currently_dragged_card:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed():
			var dropped = currently_dragged_card
			currently_dragged_card = null
			var mpos = get_global_mouse_position()

			var placed = false
			for s in cards_in_slots:
				var slot = cooking_area.get_node(s)
				var bg = slot.get_node("Background")
				if bg.get_global_rect().has_point(mpos):
					if not cards_in_slots[s]:
						placed = true
						var cp = bg.global_position + (bg.size / 2)
						dropped.size = bg.size
						dropped.global_position = cp - (dropped.size / 2)
						dropped.z_index = 1
						dropped.is_in_pot = true
						cards_in_slots[s] = dropped
						hand_cards.erase(dropped)
						selected_for_reroll.erase(dropped)
						break

			if not placed:
				dropped.z_index = 0
				if not hand_cards.has(dropped):
					hand_cards.append(dropped)
				if dropped.get_parent() == self:
					remove_child(dropped)
				player_hand.add_child(dropped)

# --- 메인 루프 ---
func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		if get_tree().paused:
			get_tree().paused = false
			if pause_overlay: pause_overlay.hide()
		else:
			get_tree().paused = true
			if pause_overlay: pause_overlay.show()
			
			
		


	if get_tree().paused:
		return

	if currently_dragged_card:
		currently_dragged_card.global_position = get_global_mouse_position() - (currently_dragged_card.size / 2)

	if not game_over:
		var prev_time = remaining_time
		remaining_time -= delta

		# 10초 교차 시 사운드 재생
		if prev_time > 10.0 and remaining_time <= 10.0:
			almost_time_out_sound_play()

		if remaining_time <= 0:
			remaining_time = 0
			_update_game_timer_label()
			_on_game_over()
			return

		_update_game_timer_label()
		
# 카드 이름을 덱에 넣을 때 최대 2장까지만 허용
func _safe_add_to_deck(card_name: String):
	var count := 0
	for c in deck:
		if c == card_name:
			count += 1
	if count >= 2:
		return
	deck.append(card_name)
	
# --- 카드 뽑기 ---
func _on_draw_button_pressed():
	if game_over:
		return

	# 덱 비었을 때 최대 2장씩 리필
	if deck.is_empty():
		deck.clear()
		#name -> key로 변경
		for key in card_textures.keys():
			deck.append(key)
			deck.append(key)   # 카드당 2장 유지
		deck.shuffle()

	# 일반 드로우
	if not deck.is_empty() and hand_cards.size() < 5:

		var card_name = deck.pop_front()
		var card = IngredientCardScene.instantiate()
		player_hand.add_child(card)
		card.setup(card_name, card_textures[card_name])

		draw_button_sound_play()
		hand_cards.append(card)

		if card.has_signal("card_picked_up"):
			card.connect("card_picked_up", Callable(self, "_on_card_picked_up"))
		if card.has_signal("reroll_toggled"):
			card.connect("reroll_toggled", Callable(self, "_on_card_reroll_toggled"))

# --- 합성 ---
func _on_combine_button_pressed():
	if game_over: return

	# [1] 버튼 비활성화 (몬스터 바뀌는 동안 클릭 금지)
	combine_button.disabled = true
	reroll_button.disabled = true
	draw_button.disabled = true 

	var elapsed_time = order_timer.wait_time - order_timer.time_left
	order_timer.stop() # 타이머 정지
	
	var success_result = check_recipe_specialist()

	process_satisfaction_logic(success_result, elapsed_time)

	if game_over: return

	# 슬롯 비우기
	for s in cards_in_slots:
		var c = cards_in_slots[s]
		if c and is_instance_valid(c):
			c.queue_free()
		cards_in_slots[s] = null

	# [2] 몬스터 교체 딜레이 
	await get_tree().create_timer(2.0).timeout
	
	result_label.text = ""
	get_new_order() # 새 몬스터 등장

	# [3] 버튼 다시 활성화 (새 주문 받으면 잠금 해제)
	combine_button.disabled = false
	draw_button.disabled = false
	
	# 리롤 버튼은 횟수가 남았을 때만 활성화
	if reroll_count < MAX_REROLL:
		reroll_button.disabled = false

# --- 조합 검사 ---
func check_recipe_specialist() -> bool:
	var placed = []
	for i in range(1, 4):
		var s = "IngredientSlot%d" % i
		var c = cards_in_slots.get(s)
		if c and "card_name" in c:
			placed.append(c.card_name if c.card_name else "빈칸")
		else:
			placed.append("빈칸")

	if not recipes.has(current_order):
		result_label.text = "이 주문의 레시피가 없습니다."
		return false

	var req = recipes[current_order].duplicate()
	placed.sort()
	req.sort()

	return placed == req

# # --- 리롤 ---
func _on_reroll_button_pressed():
	if game_over: return

	if reroll_count >= MAX_REROLL:
		result_label.text = "리롤 기회가 없습니다!"
		return

	if hand_cards.is_empty():
		result_label.text = "버릴 카드가 없습니다!"
		return
	
	# [1] 일단 버튼 잠금 (연타 방지)
	reroll_button.disabled = true
	
	reroll_button_sound_play()

	# --- 기존 리롤 로직 시작 ---
	var to_reroll = []
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

	var draw_count = to_reroll.size()
	for i in range(draw_count):
		if deck.is_empty():
			# 덱 리필 로직 
			deck.clear()
			#name --> key로 변경( 오류제거 목적)
			for key in card_textures.keys():
				deck.append(key)
				deck.append(key)
			deck.shuffle()
			
		if deck.is_empty(): break
		
		var card_name = deck.pop_front()
		var card = IngredientCardScene.instantiate()
		player_hand.add_child(card)
		card.setup(card_name, card_textures[card_name])
		hand_cards.append(card)

		if card.has_signal("card_picked_up"):
			card.connect("card_picked_up", Callable(self, "_on_card_picked_up"))
		if card.has_signal("reroll_toggled"):
			card.connect("reroll_toggled", Callable(self, "_on_card_reroll_toggled"))

	selected_for_reroll.clear()
	reroll_count += 1
	_update_reroll_label()

	result_label.text = "리롤 사용: %d / %d" % [reroll_count, MAX_REROLL]
	

	# [2] 연타 방지용 딜레이 (0.5초)
	await get_tree().create_timer(0.5).timeout

	# [3] 딜레이 끝난 후, 횟수 남았으면 버튼 다시 켜기
	if reroll_count < MAX_REROLL:
		reroll_button.disabled = false
		
# --- 리롤 라벨 ---
func _update_reroll_label():
	if reroll_label:
		var remain = MAX_REROLL - reroll_count
		reroll_label.text = "남은 리롤: %d" % max(remain, 0)

# --- 게임 타이머 라벨 & ProgressBar ---
func _update_game_timer_label():
	if timer_bar:
		timer_bar.max_value = game_time_limit
		timer_bar.value = remaining_time

	if game_timer_label:
		game_timer_label.text = "%d초" % int(remaining_time)

# --- 게임오버 ---
func _on_game_over():
	if game_over: return

	game_over = true
	result_label.text = "게임 오버!"

	reroll_button.disabled = true
	combine_button.disabled = true
	draw_button.disabled = true

	for c in hand_cards:
		if is_instance_valid(c):
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for s in cards_in_slots:
		var c = cards_in_slots[s]
		if c and is_instance_valid(c):
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE

	await get_tree().create_timer(2).timeout
	get_tree().change_scene_to_file("res://scenes/game_over.tscn")

# --- 만족도 ---
func process_satisfaction_logic(is_success: bool, elapsed_time: float):
	var change = _calculate_satisfaction_score(is_success, elapsed_time)
	GameStats.total_satisfaction += change

	_update_satisfaction_label() # [복구] 점수 변경 시 라벨 갱신

	if GameStats.total_satisfaction <= 0:
		GameStats.total_satisfaction = 0
		_update_satisfaction_label() # [복구] 0으로 보정 후 갱신
		_on_game_over()
		return

	if is_success:
		result_label.text = "완성! (만족도 %+d, 콤보 %d)" % [change, combo_count]
		monster_label.text = "맛있겠다!"
		combine_success_sound_play()

		if reroll_count > 0:
			reroll_count -= 1
			_update_reroll_label()
			result_label.text += "\n리롤 기회 +1!"
			reroll_button.disabled = false
	else:
		result_label.text = "이상한 요리... (만족도 %d)" % change
		combine_fail_sound_play()

# --- 만족도 라벨 갱신 함수 [복구] ---
func _update_satisfaction_label():
	if satisfaction_label:
		satisfaction_label.text = "만족도: %d" % GameStats.total_satisfaction

func _calculate_satisfaction_score(is_success: bool, elapsed_time: float) -> int:
	if not is_success:
		GameStats.fail_count += 1
		combo_count = 0  # 실패 시 콤보 리셋
		return SATISFACTION_SCORE_FAIL

	GameStats.success_count += 1 

	var base_score = 0

	if elapsed_time <= SATISFACTION_TIME_TIER_1:
		base_score = SATISFACTION_SCORE_TIER_1
	elif elapsed_time <= SATISFACTION_TIME_TIER_2:
		base_score = SATISFACTION_SCORE_TIER_2
	elif elapsed_time <= SATISFACTION_TIME_TIER_3:
		base_score = SATISFACTION_SCORE_TIER_3
	else:
		base_score = SATISFACTION_SCORE_LATE

	var combo_bonus = combo_count * 2
	var total = base_score + combo_bonus

	combo_count += 1 
	
	#  [추가] 최대 콤보 갱신 로직
	if combo_count > GameStats.max_combo:
		GameStats.max_combo = combo_count

	return total
# --- 사운드 ---
func draw_button_sound_play():
	button_click_sound.stream = card_draw
	button_click_sound.play()

func reroll_button_sound_play():
	button_click_sound.stream = reroll
	button_click_sound.play()

func get_new_order_sound_play():
	result_sound.stream = new_order
	result_sound.play()

func combine_fail_sound_play():
	result_sound.stream = combine
	result_sound.play()
	await get_tree().create_timer(1.0).timeout
	result_sound.stream = wrong
	result_sound.play()

func combine_success_sound_play():
	result_sound.stream = combine
	result_sound.play()
	await get_tree().create_timer(1.0).timeout
	# [수정] 변수명 변경 적용 (success -> success_sound)
	result_sound.stream = success_sound
	result_sound.play()
	await get_tree().create_timer(0.45).timeout
	result_sound.stream = money
	result_sound.play()

func almost_time_out_sound_play():
	game_timer_sound.play()
	await get_tree().create_timer(10.0).timeout
	game_timer_sound.stream = timeover
	game_timer_sound.play()

# --- 일시정지 ---
func _on_resume_button_pressed():
	get_tree().paused = false
	if pause_overlay: pause_overlay.hide()

func _on_main_menu_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
