extends Control

# 게임 시작 버튼 노드를 연결할 변수
@onready var start_button = $Button

func _ready():
	# 버튼의 pressed 신호를 _on_start_button_pressed 함수와 연결합니다.
	start_button.pressed.connect(_on_start_button_pressed)

func _on_start_button_pressed():
	# get_tree().change_scene_to_file() 함수는 현재 씬을 괄호 안의 씬으로 바꿔줍니다.
	get_tree().change_scene_to_file("res://main.tscn")
