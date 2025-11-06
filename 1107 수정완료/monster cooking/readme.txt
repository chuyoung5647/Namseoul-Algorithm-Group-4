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


2025_11_01 변경사항:
	임시로 이미지를 test_image 폴더와 before_image 폴더로 분리

		test_image 폴더에는 새로 추가된 이미지들 적용.
		before_image 폴더에는 기존에 적용되어 있던 이미지들 보관
		(향후 test이미지로 사용여부가 확실시 된다면 삭제해도 무방)
		
	배성우 님이 제작해주신 배경이미지, 재료이미지, 음식이미지 등등 게임에 적용.
		해당 배경의 모양에 따라재료카드들이 놓이는 위치, 슬롯  위치, 버튼 위치, 몬스터 이미지위치 등  조정


2025_11_07 변경사항:
	check_recipe함수가 구분이 좀 어려워서 분리를 시킴:


		기존버전:func check_recipe():
			# --- [A] 재료 수집 ---
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

			# --- [B] 레시피 검사 로직 ---
			if not recipes.has(current_order):
				result_label.text = "이 주문의 레시피가 없습니다."
				return
			var required_ingredients = recipes[current_order].duplicate()
			placed_ingredients.sort()
			required_ingredients.sort()

			# --- [C] 성공/실패 분기 ---
			if placed_ingredients == required_ingredients:
				# --- [D] 성공 UI + 보상 ---
				result_label.text = current_order + " 완성!"
				monster_label.text = "맛있겠다!"
				if reroll_count > 0:
					reroll_count -= 1
					_update_reroll_label()
					result_label.text += "\n리롤 기회 +1!"
					reroll_button.disabled = false
			else:
				# --- [E] 실패 UI ---
				result_label.text = "이상한 요리가 나왔다..."

			# --- [F] 슬롯 정리 ---
			for slot_name in cards_in_slots:
				var card_node = cards_in_slots[slot_name]
				if card_node and is_instance_valid(card_node):
					card_node.queue_free()
				cards_in_slots[slot_name] = null

			# --- [G] 다음 주문 (흐름 제어) ---
			await get_tree().create_timer(2.0).timeout
			result_label.text = ""
			get_new_order()

		검사용: check_recipe_specialist()
			[A], [B], [C]
		제어용: _on_combine_button_pressed()
			[D], [E]
		결과처리용: process_satisfaction_logic()
			[F], [G]


	만족도 추가:
		main.tscn에 OrderTimer노드와 SatisfactionLabel 노드를추가함.
		
		process_satifaction_logic 함수를 만들어 만족도 관련 내용을 넣음.
		
		_on_game_over 함수에 연동하여 만족도가 0이된다면 타이머의 시간이 다 되었을때와 같이 게임오버되게 만듬.

		음식을 5초안에 만들었을떄: 만족도 +10
		음식을 10초 안에 만들었을떄: 만족도 +5
		음식을 15초 안에 만들었을떄: 만족도 +1
		음식을 그 이상 걸려서 만들었을떄: 만족도 -3
		음식을 만들지 못했을떄: 만족도 -5

		위의 사항들은 코드 윗부분에 모아둬서 향후 밸런스패치가 용이하도록 만듬.
			const SATISFACTION_START: int = 50        # 기본 만족도
			const SATISFACTION_TIME_TIER_1: float = 5.0  # 5초 이내
			const SATISFACTION_SCORE_TIER_1: int = 10   # +10점
			const SATISFACTION_TIME_TIER_2: float = 10.0 # 10초 이내
			const SATISFACTION_SCORE_TIER_2: int = 5    # +5점
			const SATISFACTION_TIME_TIER_3: float = 15.0 # 15초 이내
			const SATISFACTION_SCORE_TIER_3: int = 1    # +1점
			const SATISFACTION_SCORE_LATE: int = -3     # 15초 초과 시
			const SATISFACTION_SCORE_FAIL: int = -5     # 요리 실패 시
			
