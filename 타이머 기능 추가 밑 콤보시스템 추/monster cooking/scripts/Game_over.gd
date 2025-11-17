extends Control

# --- 노드 참조 ---
@onready var score_label = $ScoreLabel
@onready var success_label = $SuccessLabel
@onready var fail_label = $FailLabel
@onready var retry_button = $RetryButton
@onready var menu_button = $MenuButton

func _ready():
	# 1. GameStats에서 데이터 읽어와서 라벨에 표시
	score_label.text = "최종 만족도: %d" % GameStats.total_satisfaction
	success_label.text = "요리 성공: %d" % GameStats.success_count
	fail_label.text = "요리 실패: %d" % GameStats.fail_count
	
	# 2. 버튼 신호 연결 (공식 배선)
	retry_button.pressed.connect(_on_retry_button_pressed)
	menu_button.pressed.connect(_on_menu_button_pressed)

func _on_retry_button_pressed():
	# 3. GameStats 리셋하고 게임 씬으로
	GameStats.reset()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_menu_button_pressed():
	# 4. GameStats 리셋하고 메인 메뉴 씬으로
	GameStats.reset()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
