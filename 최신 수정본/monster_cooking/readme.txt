이전 변경사항:
	기초 프로토타입제작(이미지, 코드, 로직 등)
	-박준석
2025_10_15 변경사항:
	카드 추가, 변경, 레시피추가, 변경등이 용이하게 코드 수정
	재료카드를 넣을 슬롯3개를 추가하고 그 슬롯이 정상작동하게 코드수정함.
	변경사항이 있다면 이곳에 적어주길 바랍니다.
	-박준석

2025_10_19 변경사항:
	1. 드래그 앤 드롭 시스템 전면 교체 (핵심 버그 수정)
		문제: 수정된 버전에서 카드를 드래그하여 특정 슬롯에 놓아도 해당위치에 똑바로 들어가지 않는 버그 발생.
		원인: 카드의 물리적인 CollisionShape이 너무 넓어, 의도치 않은 여러 슬롯을 동시에 감지함.
		해결: 물리 충돌 감지 방식(get_overlapping_areas)을 폐기. 
			대신 마우스 포인터의 현재 위치(get_global_mouse_position)가 정확히 어떤 슬롯의 배경(Background) 위에 있는지만을 
			판단하도록 로직을 전면 수정.

	2. '카드 이름' 표시 버그 수정
		문제: 카드 이미지(TextureRect)의 자식으로 있던 Label이 이미지 뒤에 그려져 보이지 않았던 버그.
		해결: ingredient_card.tscn 씬에서 Label 노드의 Ordering 탭 -> Z Index 값을 1로 설정하여,
			 부모 이미지보다 항상 위에 그려지도록 렌더링 순서를 수정함. (복잡한 씬 구조 변경 없이 해결)

	3. 기타 안정성 및 구조 개선
		복잡한 ingredient_card 씬(extends Control) 대신, 기존의 단순한 extends TextureRect 씬을 유지하기로 결정.
		 (불필요한 복잡성 제거)
		check_recipe 함수에 recipes.has(current_order) 방어 코드를 추가하여,
		 레시피가 없는 주문으로 인해 게임이 멈추는 버그를 예방함. (1차수정 코드에서 반영)

2025_10_29 변경사항:
	check_recipe 함수에서 레시피를 판별할 때 기존에는
	var required_ingredients = recipes[current_order]
	함수로 조합법과 슬롯에 올린 재료가 완벽히 같아야 했지만 이것을 
	
	var required_ingredients = recipes[current_order].duplicate()
	placed_ingredients.sort()
	required_ingredients.sort()
	원본레시피를 복제하여 레시피가 맞는지 판단할 기준을 생성해주고 카드 슬롯에 있는 레시피와 기준레시피 두가지 모두 정렬을 해준다음
	그 두가지가 일치하는지를 판단하는방식으로 변경함.
	
	[dish.gd], [dish.tscn], [recipe.gd], [recipe.tscn]같은 기능이 없는 더미파일을 제거하였고
	ingredient_card.gd파일과 ingredient_card.tscn 파일들이 같은이름을 가진채 여러개가 있어서 기능을 하고있지 않는 
	2개의 중복이름파일을 제거함.
	
	Monster.gd파일과 main.gd파일을 연동시켜 몬스터 이미지가 정상적으로 적용되고 monster.gd파일에 있던 몬스터마다 주문내용이 
	다르도록 하는 기능이 작동하게함.
	
	기존에 scripts나 scenes 폴더 바깥에 산재해 있던 각종 .gd파일과 .tscn파일들을 각각 확장자에 맞는 폴더에 집어넣어
	프로젝트 폴더를 정리함.
