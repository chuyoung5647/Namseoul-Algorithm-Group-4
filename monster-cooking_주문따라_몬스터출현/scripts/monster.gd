extends Sprite2D
var monster_order = { #주문으로 몬스터 정하기
	"매콤한 스튜" : "가고일",
	"용암구이" : "미믹",
	#"spider" : "몬스터 스테이크",
	#"demon" : "몬스터 스테이크",
}
var monster_texture = { #코드로 몬스터를 찾고 이미지를 변경
	"가고일" : preload("res://Images/monster1.png"),
	"미믹" : preload("res://Images/monster2.png"),
#	"spider" : preload(),
#	"demon" : preload(),
}
#var under_boss_monster_cord= {
#	0: "demon",
#}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
func set_monster(order:String): #정수를 받아서 몬스터를 초기화
	self.texture = monster_texture[monster_order[order]] #몬스터의 텍스쳐변경
	
#func set_under_boss_monster(cord:String): #중간 보스 몬스터 초기화
#	self.texture = monster_texture[monster_order[order]] #몬스터의 텍스쳐변경
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
