extends Sprite2D
var monster_cord = { #코드로 몬스터찾기
	0 : "slime",
	1 : "mimic",
	2: "spider",
	3: "demon",
	
}
var monster_order = { #코드로 몬스터의 선호 정하기
	"slime" : "매콤한 스튜",
	"mimic" : "용암구이",
	"spider" : "황금생선찜",
	"demon" : "비밀의 스프",
}
var monster_texture = { #코드로 몬스터를 찾고 이미지를 변경
	"slime" : preload("res://Images/test_image/monster/monster_slime.png"),
	"mimic" : preload("res://Images/test_image/monster/monster_mimic.png"),
	"spider" : preload("res://Images/test_image/monster/monster_spider.png"),
	"demon" : preload("res://Images/test_image/monster/monster_demon.png"),
}
var under_boss_monster_cord= {
	0: "demon",
}
var m_order
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
func set_monster(cord:int): #정수를 받아서 몬스터를 초기화
	m_order = monster_order[monster_cord[cord]] #코드로 몬스터의 주문 정하기
	self.texture = monster_texture[monster_cord[cord]] #몬스터의 텍스쳐변경
func set_under_boss_monster(cord:int):
	m_order = monster_order[under_boss_monster_cord[cord]] #코드로 몬스터의 주문 정하기
	self.texture = monster_texture[under_boss_monster_cord[cord]] #몬스터의 텍스쳐변경
