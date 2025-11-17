extends Control

# 게임 시작 버튼 노드를 연결할 변수
@onready var start_button = $Button
@onready var door_open: AudioStreamPlayer2D = $door_open

func _ready():
	# 버튼의 pressed 신호를 _on_start_button_pressed 함수와 연결합니다.
	start_button.pressed.connect(_on_start_button_pressed)

func _on_start_button_pressed():
	GameStats.reset() #  새 게임 시작 시 통계 리셋
	
	print(door_open.stream)
	door_open.play()
	await get_tree().create_timer(0.8).timeout
	get_tree().change_scene_to_file("res://scenes/main.tscn")
