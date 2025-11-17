extends Node

# --- 게임 플레이 데이터 ---
var total_satisfaction: int = 50
var success_count: int = 0
var fail_count: int = 0

# --- 기본값 ---
const DEFAULT_SATISFACTION: int = 50

# '다시하기' 또는 '메인 메뉴'로 갈 때 호출할 리셋 함수
func reset():
	total_satisfaction = DEFAULT_SATISFACTION
	success_count = 0
	fail_count = 0
