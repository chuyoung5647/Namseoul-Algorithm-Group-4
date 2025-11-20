extends Control

# --- [노드 참조] ---
# 1. 게임오버 알림 이미지 (처음에 떴다가 사라질 것)
@onready var title_image = $GameOverTitleImage  

# 2. 결과판 배경 이미지 (나중에 통계와 함께 뜰 것)
@onready var result_board = $gameover_bacckground 

# 3. 결과 라벨들
@onready var score_label = $ScoreLabel
@onready var combo_label = $ComboLabel
@onready var success_label = $SuccessLabel
@onready var fail_label = $FailLabel

# 4. 버튼들
@onready var retry_button = $RetryButton
@onready var menu_button = $MenuButton

func _ready():
	# --- 1. 초기화: 데이터 표시 ---
	score_label.text = "최종 만족도: %d" % GameStats.total_satisfaction
	combo_label.text = "최대 콤보: %d" % GameStats.max_combo
	success_label.text = "요리 성공: %d" % GameStats.success_count
	fail_label.text = "요리 실패: %d" % GameStats.fail_count
	
	# --- 2. 초기 상태: 모든 요소를 투명하게 숨김 ---
	title_image.modulate.a = 0.0   # 게임오버 이미지 숨김
	result_board.modulate.a = 0.0  # 결과판 이미지 숨김
	
	# 텍스트와 버튼들도 숨김
	score_label.modulate.a = 0.0
	combo_label.modulate.a = 0.0
	success_label.modulate.a = 0.0
	fail_label.modulate.a = 0.0
	retry_button.modulate.a = 0.0
	menu_button.modulate.a = 0.0
	
	# --- 3. 버튼 연결 ---
	retry_button.pressed.connect(_on_retry_button_pressed)
	menu_button.pressed.connect(_on_menu_button_pressed)
	
	# --- 4. 연출 시작 ---
	start_sequence()

func start_sequence():
	var tween = create_tween()
	
	# [단계 1] '게임오버 알림 이미지' 페이드인 (1초)
	tween.tween_property(title_image, "modulate:a", 1.0, 1.0)
	
	# [단계 2] 잠시 보여주기 (1.5초 대기)
	tween.tween_interval(1.5)
	
	# [단계 3] '게임오버 알림 이미지' 사라지기 (0.5초)
	tween.tween_property(title_image, "modulate:a", 0.0, 0.5)
	
	# [단계 4] '결과판 이미지' + '통계/버튼' 동시에 등장 (0.5초)
	# set_parallel(true)로 아래 요소들이 한꺼번에 나타나게 함
	tween.set_parallel(true)
	tween.tween_property(result_board, "modulate:a", 1.0, 0.5)
	tween.tween_property(score_label, "modulate:a", 1.0, 0.5)
	tween.tween_property(combo_label, "modulate:a", 1.0, 0.5)
	tween.tween_property(success_label, "modulate:a", 1.0, 0.5)
	tween.tween_property(fail_label, "modulate:a", 1.0, 0.5)
	tween.tween_property(retry_button, "modulate:a", 1.0, 0.5)
	tween.tween_property(menu_button, "modulate:a", 1.0, 0.5)

# --- [버튼 기능] ---
func _on_retry_button_pressed():
	# 다시하기
	GameStats.reset()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_menu_button_pressed():
	# 메인메뉴
	GameStats.reset()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
