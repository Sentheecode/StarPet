extends Control

# ========== 状态机 ==========
enum State { IDLE, HUNGRY, HAPPY, SAD, EAT, PLAY, SLEEP }
var current_state = State.IDLE
var state_timer: float = 0.0
var decay_timer: float = 0.0
var click_count: int = 0

# ========== 节点 ==========
var game_layer
var ui_layer
var pet_layer
var bg_layer
var dog
var dog_sprite
var dog_eye_l
var dog_eye_r
var dog_tail
var dog_emotion
var dog_status_bar
var cat
var player
var player_shadow
var food_bowl
var plant_leaves = []
var dog_timer: float = 0.0
var blink_timer: float = 0.0
var player_pos = Vector2(165, 400)

# ========== 颜色 ==========
const COL_WALL = Color(0.78, 0.75, 0.68)
const COL_FLOOR = Color(0.62, 0.48, 0.28)
const COL_WOOD = Color(0.48, 0.30, 0.16)
const COL_BED = Color(0.95, 0.93, 0.90)
const COL_BLANKET = Color(0.45, 0.68, 0.85)
const COL_SKIN = Color(0.98, 0.82, 0.70)
const COL_HAIR = Color(0.15, 0.10, 0.05)
const COL_PLAYER = Color(0.25, 0.65, 0.95)
const COL_DOG = Color(0.95, 0.65, 0.25)
const COL_DOG_LIGHT = Color(1.0, 0.92, 0.75)
const COL_CAT = Color(0.65, 0.65, 0.70)
const COL_PLANT = Color(0.25, 0.75, 0.25)

func _ready():
	setup_layers()
	draw_parallax_bg()
	draw_room()
	draw_furniture()
	draw_decorations()
	draw_player()
	draw_pets()
	draw_items()
	draw_ui()
	refresh_pet()
	
	# 连接信号
	GameManager.pet_switched.connect(refresh_pet)
	GameManager.data_changed.connect(refresh_pet)

func refresh_pet():
	var pet = GameManager.get_active_pet()
	if pet:
		update_ui()
		rebuild_pet_sprite()

func rebuild_pet_sprite():
	var pet = GameManager.get_active_pet()
	if pet == null: return
	
	# 获取品种配置
	var config = GameManager.get_breed_config(pet.breed)
	
	# 重建宠物显示
	if dog:
		dog.queue_free()
	
	dog = Node2D.new()
	dog.position = Vector2(135, 422)
	dog.z_index = 422
	game_layer.add_child(dog)
	dog_sprite = Node2D.new()
	dog.add_child(dog_sprite)
	
	# 判断是猫还是狗
	if pet.species == "cat":
		# 猫咪：使用图片
		var cat_index = 0
		# 根据品种获取图片索引
		var cat_breeds = GameManager.cat_breeds
		if pet.breed in cat_breeds:
			cat_index = cat_breeds.find(pet.breed) % 16
		
		var sprite = Sprite2D.new()
		var img_path = "res://sprites/cats/cat_%02d.png" % cat_index
		sprite.texture = load(img_path)
		
		# 调整大小和位置
		var scale_factor = 0.8
		sprite.scale = Vector2(scale_factor, scale_factor)
		sprite.position = Vector2(0, -20)  # 居中偏上
		dog_sprite.add_child(sprite)
		
		# 猫咪不动，所以不需要添加行为相关节点
		return
	
	# 狗狗：用代码绘制
	var size_info = GameManager.size_bases[config.body_size]
	var base_w = size_info["w"]
	var base_h = size_info["h"]
	var base_scale = size_info["scale"]
	
	# 大型宠物位置稍微靠前一点
	if config.body_size == 2:
		dog.position.x = 140
	elif config.body_size == 0:
		dog.position.x = 130
	dog.scale = Vector2(base_scale, base_scale)
	
	# 身体
	var body_w = base_w
	var body_h = base_h
	var body_y = 0
	
	# 体态调整
	if config.body_shape == 1:  # 短腿
		body_h = body_h - 2
	elif config.body_shape == 2:  # 修长
		body_w = body_w - 2
		body_h = body_h + 2
	
	add_child_to(dog_sprite, mkrect(0, body_y, body_w, body_h, config.body_color))
	
	# 腹部浅色
	add_child_to(dog_sprite, mkrect(4, body_y + 4, body_w - 8, body_h - 8, config.secondary_color))
	
	# 头
	var head_size = min(body_w * 0.6, 18)
	var head_x = -head_size * 0.5
	var head_y = -head_size * 0.7
	add_child_to(dog_sprite, mkrect(head_x, head_y, head_size, head_size * 0.9, config.body_color))
	
	# 耳朵
	if config.ear_type == 1:  # 垂耳
		add_child_to(dog_sprite, mkrect(head_x - 2, head_y - 2, 5, 6, config.body_color))
		add_child_to(dog_sprite, mkrect(head_x + head_size - 3, head_y - 2, 5, 6, config.body_color))
	elif config.ear_type == 2:  # 尖耳
		var ear_l = Polygon2D.new()
		ear_l.polygon = PackedVector2Array([Vector2(head_x - 2, head_y), Vector2(head_x + 2, head_y - 6), Vector2(head_x + 6, head_y)])
		ear_l.color = config.body_color
		dog_sprite.add_child(ear_l)
		var ear_r = Polygon2D.new()
		ear_r.polygon = PackedVector2Array([Vector2(head_x + head_size + 2, head_y), Vector2(head_x + head_size - 2, head_y - 6), Vector2(head_x + head_size - 6, head_y)])
		ear_r.color = config.body_color
		dog_sprite.add_child(ear_r)
	
	# 眼睛
	var eye_size = 3
	var eye_y = head_y + head_size * 0.3
	var eye_color = Color(0.1, 0.08, 0.08)
	if pet.breed == "哈士奇":
		eye_color = Color(0.3, 0.5, 0.9)
	elif config.is_cat:
		eye_color = Color(0.2, 0.7, 0.4)  # 猫绿色眼睛
	
	dog_eye_l = mkrect(head_x + 2, eye_y, eye_size, eye_size, eye_color)
	dog_eye_r = mkrect(head_x + head_size - eye_size - 2, eye_y, eye_size, eye_size, eye_color)
	add_child_to(dog_sprite, dog_eye_l)
	add_child_to(dog_sprite, dog_eye_r)
	
	# 花纹
	if config.has_pattern:
		var pattern_y = body_y + 2
		if pet.species == "cat" and pet.breed == "暹罗":
			add_child_to(dog_sprite, mkrect(head_x, head_y + head_size * 0.7, head_size, head_size * 0.3, config.pattern_color))
	
	# 腿
	var leg_w = max(5, body_w * 0.18)
	var leg_h = body_h * 0.4
	if config.body_shape == 1:  # 短腿
		leg_h = leg_h * 0.7
	elif config.body_shape == 2:  # 修长
		leg_h = leg_h * 1.1
	var leg_y = body_y + body_h - 2
	add_child_to(dog_sprite, mkrect(2, leg_y, leg_w, leg_h, config.body_color))
	add_child_to(dog_sprite, mkrect(body_w - leg_w - 2, leg_y, leg_w, leg_h, config.body_color))
	
	# 尾巴
	var tail_w = max(4, body_w * 0.25)
	var tail_h = 4
	if config.tail_length == 0:
		tail_w = tail_w * 0.6
	elif config.tail_length == 2:
		tail_w = tail_w * 1.3
	
	dog_tail = mkrect(body_w - 2, body_y + 2, tail_w, tail_h, config.body_color)
	add_child_to(dog_sprite, dog_tail)
	
	# 长毛效果
	if config.fur_length >= 2:
		add_child_to(dog_sprite, mkrect(2, body_y - 1, 5, 3, config.secondary_color))
		add_child_to(dog_sprite, mkrect(body_w - 7, body_y - 1, 5, 3, config.secondary_color))
	
	# 点击区域
	var dog_area = Area2D.new()
	dog_area.input_event.connect(_on_dog_input_event)
	var collision = CollisionShape2D.new()
	collision.shape = RectangleShape2D.new()
	collision.shape.size = Vector2(body_w + 15, body_h + 30)
	dog_area.add_child(collision)
	dog.add_child(dog_area)
	
	# 状态气泡
	dog_emotion = Label.new()
	dog_emotion.add_theme_font_size_override("font_size", 14)
	dog_emotion.position = Vector2(10, -30)
	dog.add_child(dog_emotion)
	
	# 状态条
	dog_status_bar = HBoxContainer.new()
	dog_status_bar.position = Vector2(-5, -45)
	dog.add_child(dog_status_bar)
	update_pet_status()

func _process(delta):
	var pet = GameManager.get_active_pet()
	if pet == null: return
	
	# 数值衰减
	decay_timer += delta
	if decay_timer > 10.0:
		decay_timer = 0
		pet.hunger = max(0, pet.hunger - 2)
		pet.happiness = max(0, pet.happiness - 1)
		pet.cleanliness = max(0, pet.cleanliness - 1)
		update_pet_status()
		GameManager.save_game()
	
	process_dog(pet, delta)
	process_cat(delta)
	process_plant(delta)
	process_player(delta)
	
	state_timer += delta
	if state_timer > 30.0:
		GameManager.save_game()
		state_timer = 0

# ========== 状态机 ==========
func change_state(new_state, pet):
	current_state = new_state
	state_timer = 0
	var emoji = "IDLE"
	match new_state:
		State.IDLE: emoji = "IDLE"
		State.HUNGRY: emoji = "FOOD"
		State.HAPPY: emoji = "HEART"
		State.SAD: emoji = "SAD"
		State.EAT: emoji = "EAT"
		State.PLAY: emoji = "PLAY"
		State.SLEEP: emoji = "ZZZ"
	if dog_emotion: dog_emotion.text = emoji

func process_dog(pet, delta):
	dog_timer += delta
	blink_timer += delta
	
	# 获取品种配置和特性行为
	var config = GameManager.get_breed_config(pet.breed)
	
	# ===== 品种特异性行为 =====
	# 根据品种特性触发特殊动作
	
	# 1. 精力旺盛的宠物更活跃
	if config.behavior_energy > 70 and randf() < 0.005:
		trigger_special_action(config.special_action, "精力旺盛")
	
	# 2. 粘人的宠物更跟随玩家
	if config.behavior_loyal > 70 and randf() < 0.01:
		show_emotion(config.special_action, "粘人")
	
	# 3. 心情好时摇尾巴/特殊动作
	if pet.happiness > 70 and randf() < 0.008:
		if dog_tail:
			var tw = create_tween()
			tw.tween_property(dog_tail, "rotation", 0.5, 0.2)
			tw.tween_property(dog_tail, "rotation", 0.0, 0.2)
	
	# 4. 特定品种的特殊行为
	match pet.breed:
		"柯基":
			# 柯基：开心时摇屁股
			if pet.happiness > 80 and randf() < 0.01:
				trigger_wiggle()
		"哈士奇":
			# 哈士奇：精力旺盛，偶尔拆家
			if pet.happiness < 40 and randf() < 0.005:
				show_emotion("!", "无聊想拆家")
		"萨摩耶":
			# 萨摩耶：微笑
			if pet.happiness > 60:
				show_emotion("^ω^", "微笑")
		"泰迪", "比熊":
			# 泰迪/比熊：喜欢撒娇
			if config.behavior_loyal > 60 and randf() < 0.015:
				show_emotion("♥ω♥", "撒娇")
		"博美":
			# 博美：警惕/叫声
			if randf() < 0.008:
				show_emotion("汪!", "警惕")
		"边牧":
			# 边牧：聪明，活跃
			if config.behavior_active > 80 and randf() < 0.01:
				show_emotion("◎ω◎", "聪明")
	
	# 猫的特殊行为
	if config.is_cat:
		process_cat_behavior(pet, config, delta)
	
	# 眨眼
	if blink_timer > 3.0 + randf() * 2:
		blink_timer = 0
		var tw = create_tween()
		tw.tween_property(dog_eye_l, "size", Vector2(4, 1), 0.1)
		tw.tween_property(dog_eye_r, "size", Vector2(4, 1), 0.1)
		tw.tween_interval(0.15)
		tw.tween_property(dog_eye_l, "size", Vector2(4, 4), 0.1)
		tw.tween_property(dog_eye_r, "size", Vector2(4, 4), 0.1)
	
	# 尾巴
	var tail_speed = 8.0
	if current_state == State.HAPPY: tail_speed = 15.0
	elif current_state == State.SAD: tail_speed = 2.0
	elif current_state == State.EAT: tail_speed = 0.0
	if dog_tail: dog_tail.rotation_degrees = sin(dog_timer * tail_speed) * 25
	
	# 呼吸
	if dog_sprite: dog_sprite.position.y = sin(dog_timer * 3) * 1.5
	
	# 状态行为
	match current_state:
		State.IDLE:
			if state_timer > 5.0: wander()
		State.HUNGRY:
			move_to(Vector2(80, 440), delta)
			if state_timer > 8.0:
				pet.hunger = max(0, pet.hunger - 5)
				update_pet_status()
		State.HAPPY, State.PLAY:
			follow_player(delta)
			if state_timer > 10.0 and current_state == State.HAPPY:
				pet.happiness = max(0, pet.happiness - 3)
				update_pet_status()
		State.SAD:
			if int(state_timer) % 5 == 0: play_cry()
		State.EAT:
			if state_timer > 3.0:
				pet.hunger = min(100, pet.hunger + 30)
				change_state(State.HAPPY, pet)

func wander():
	var tween = create_tween()
	tween.tween_property(dog, "position:x", 40 + randf() * 50, 1.5)
	state_timer = 0

# ========== 品种特异性行为函数 ==========
func trigger_special_action(action_name, reason: String):
	if not dog: return
	show_emotion(action_name, reason)
	# 播放特殊动作动画
	match action_name:
		"摇屁股":
			trigger_wiggle()
		"嚎叫":
			trigger_howl()
		"握手":
			trigger_shake()
		"捡球":
			show_emotion("🎾", "想玩球")
		"接飞盘":
			show_emotion("飞盘", "想接飞盘")
		_:
			var tw = create_tween()
			tw.tween_property(dog, "scale", Vector2(1.1, 0.9), 0.15)
			tw.tween_property(dog, "scale", Vector2(1.0, 1.0), 0.15)

func trigger_wiggle():
	# 摇屁股动画（柯基特色）
	if not dog: return
	var tw = create_tween()
	for i in range(3):
		tw.tween_property(dog, "position:x", dog.position.x + 3, 0.1)
		tw.tween_property(dog, "position:x", dog.position.x - 3, 0.1)
	tw.tween_property(dog, "position:x", dog.position.x, 0.1)

func trigger_howl():
	# 嚎叫动画（哈士奇特色）
	show_emotion("oooo~", "嚎叫")

func trigger_shake():
	# 握手动画（金毛特色）
	show_emotion("握手", "想握手")
	if dog:
		var tw = create_tween()
		tw.tween_property(dog, "position:y", dog.position.y - 10, 0.2)
		tw.tween_property(dog, "position:y", dog.position.y, 0.2)

func process_cat_behavior(pet, config, delta):
	# 猫咪特殊行为
	match pet.breed:
		"暹罗":
			# 暹罗：粘人、话痨
			if randf() < 0.02:
				show_emotion("喵~", "话痨")
		"布偶":
			# 布偶：慵懒、呼噜
			if pet.happiness > 70 and randf() < 0.01:
				show_emotion("呼噜~", "好舒服")
		"美短":
			# 美短：活泼
			if config.behavior_active > 50 and randf() < 0.01:
				show_emotion("活跃", "玩耍")
		"波斯":
			# 波斯：高贵慵懒
			if randf() < 0.005:
				show_emotion("优雅", "高贵")
		"孟加拉":
			# 豹猫：野性
			if randf() < 0.01:
				show_emotion("野性", "狩猎本能")
		"德文", "柯尼斯":
			# 德文/柯尼斯：精灵特质
			if randf() < 0.015:
				show_emotion("电臀", "兴奋")

func move_to(target, delta):
	var dir = (target - dog.position).normalized()
	if dog.position.distance_to(target) > 5: dog.position += dir * 35 * delta

# ========== 情绪显示 ==========
func show_emotion(emoji: String, reason: String = ""):
	if dog_emotion:
		dog_emotion.text = emoji
		# 动画效果
		var tw = create_tween()
		tw.tween_property(dog_emotion, "modulate:a", 0.0, 0.1)
		tw.parallel().tween_property(dog_emotion, "modulate:a", 1.0, 0.1)
		# 2秒后消失
		await get_tree().create_timer(2.0).timeout
		if dog_emotion: dog_emotion.text = ""

func follow_player(delta):
	var target = player_pos + Vector2(30, 20)
	var dir = (target - dog.position).normalized()
	var dist = dog.position.distance_to(target)
	if dist > 40: dog.position += dir * 80 * delta
	elif dist < 20: dog.position -= dir * 30 * delta

func play_cry():
	var tw = create_tween()
	tw.tween_property(dog_sprite, "scale", Vector2(1.05, 0.95), 0.2)
	tw.tween_property(dog_sprite, "scale", Vector2(1, 1), 0.2)

# ========== 交互 ==========
func _on_dog_clicked():
	var pet = GameManager.get_active_pet()
	if pet == null: return
	
	pet.last_interaction = Time.get_unix_time_from_system()
	click_count += 1
	pet.happiness = min(100, pet.happiness + 5)
	show_radial_menu()

func show_radial_menu():
	var existing = ui_layer.get_node_or_null("RadialMenu")
	if existing: existing.queue_free()
	
	var menu = PanelContainer.new()
	menu.name = "RadialMenu"
	menu.position = dog.position + Vector2(40, -70)
	menu.custom_minimum_size = Vector2(100, 90)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.06, 0.95)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	menu.add_theme_stylebox_override("panel", style)
	ui_layer.add_child(menu)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	menu.add_child(vbox)
	
	var actions = [["喂食", "feed"], ["抚摸", "pet"], ["玩耍", "play"], ["洗澡", "bath"]]
	for action in actions:
		var btn = Button.new()
		btn.text = action[0]
		btn.pressed.connect(_on_action_selected.bind(action[1]))
		vbox.add_child(btn)

func _on_action_selected(action):
	var existing = ui_layer.get_node_or_null("RadialMenu")
	if existing: existing.queue_free()
	
	var pet = GameManager.get_active_pet()
	if pet == null: return
	
	match action:
		"feed":
			pet.hunger = min(100, pet.hunger + 25)
			change_state(State.EAT, pet)
			spawn_food_effects()
		"pet":
			pet.happiness = min(100, pet.happiness + 15)
			change_state(State.HAPPY, pet)
			spawn_hearts()
		"play":
			pet.happiness = min(100, pet.happiness + 20)
			change_state(State.PLAY, pet)
			if click_count >= 3:
				click_count = 0
				var tw = create_tween()
				tw.tween_property(dog, "rotation", PI * 2, 0.5)
				tw.tween_property(dog, "rotation", 0, 0)
			else:
				var tw = create_tween()
				tw.tween_property(dog, "position:y", dog.position.y - 25, 0.12)
				tw.tween_property(dog, "position:y", dog.position.y, 0.18)
			spawn_hearts()
		"bath":
			pet.cleanliness = min(100, pet.cleanliness + 30)
			change_state(State.HAPPY, pet)
			spawn_bubbles()
	
	update_pet_status()
	GameManager.save_game()

func spawn_food_effects():
	for i in range(5):
		var food = Label.new()
		food.text = "+25"
		food.add_theme_font_size_override("font_size", 14)
		food.modulate = Color(0.3, 1, 0.3)
		food.position = dog.position + Vector2(10, -30 - i * 8)
		pet_layer.add_child(food)
		var tw = create_tween()
		tw.tween_property(food, "position:y", food.position.y - 40, 0.6)
		tw.tween_property(food, "modulate:a", 0, 0.6)
		tw.chain().tween_callback(food.queue_free)

func spawn_hearts():
	for i in range(3):
		var heart = Label.new()
		heart.text = "HEART"
		heart.add_theme_font_size_override("font_size", 16)
		heart.position = dog.position + Vector2(5 + i * 12, -35 - i * 8)
		pet_layer.add_child(heart)
		var tw = create_tween()
		tw.set_parallel(true)
		tw.tween_property(heart, "position:y", heart.position.y - 40, 0.6)
		tw.tween_property(heart, "modulate:a", 0, 0.6)
		tw.chain().tween_callback(heart.queue_free)

func spawn_bubbles():
	for i in range(5):
		var bubble = Label.new()
		bubble.text = "BUBBLE"
		bubble.add_theme_font_size_override("font_size", 12)
		bubble.position = dog.position + Vector2(randf() * 30, -20 - i * 10)
		pet_layer.add_child(bubble)
		var tw = create_tween()
		tw.tween_property(bubble, "position:y", bubble.position.y - 30, 0.8)
		tw.tween_property(bubble, "modulate:a", 0, 0.8)
		tw.chain().tween_callback(bubble.queue_free)

func _on_food_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		feed_pet()

func feed_pet():
	var pet = GameManager.get_active_pet()
	if pet == null: return
	pet.hunger = min(100, pet.hunger + 40)
	pet.happiness = min(100, pet.happiness + 10)
	change_state(State.EAT, pet)
	update_pet_status()
	GameManager.save_game()

# ========== 绘制 ==========
func setup_layers():
	bg_layer = CanvasLayer.new()
	bg_layer.layer = -10
	add_child(bg_layer)
	game_layer = CanvasLayer.new()
	game_layer.layer = 1
	add_child(game_layer)
	pet_layer = CanvasLayer.new()
	pet_layer.layer = 50
	add_child(pet_layer)
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 100
	add_child(ui_layer)

func draw_parallax_bg():
	var sky = ColorRect.new()
	sky.color = Color(0.5, 0.7, 0.95)
	sky.size = Vector2(400, 250)
	bg_layer.add_child(sky)
	
	for i in range(4):
		var cloud = ColorRect.new()
		cloud.color = Color(1, 1, 1, 0.6)
		cloud.position = Vector2(i * 120 + 30, 20 + i * 15)
		cloud.size = Vector2(70 + i * 15, 20)
		bg_layer.add_child(cloud)
	
	var mountain = Polygon2D.new()
	mountain.polygon = PackedVector2Array([Vector2(0, 250), Vector2(80, 190), Vector2(180, 220), Vector2(280, 180), Vector2(400, 250)])
	mountain.color = Color(0.35, 0.5, 0.4)
	bg_layer.add_child(mountain)

func draw_room():
	rect_z(20, 70, 360, 175, COL_WALL, 70)
	rect_z(20, 250, 360, 175, COL_FLOOR, 250)
	
	# 添加2D光照效果 - 窗户光线
	var window_light = DirectionalLight2D.new()
	window_light.position = Vector2(350, 80)
	window_light.rotation_degrees = -45
	window_light.color = Color(1, 0.95, 0.8, 0.3)
	window_light.energy = 0.4
	window_light.z_index = 500
	game_layer.add_child(window_light)
	
	# 环境光
	var ambient = WorldEnvironment.new()
	# 创建简单的环境光效果 - 用一个大的半透明矩形模拟
	var ambient_rect = ColorRect.new()
	ambient_rect.color = Color(0.8, 0.85, 1.0, 0.15)
	ambient_rect.size = Vector2(400, 720)
	ambient_rect.position = Vector2(0, 0)
	ambient_rect.z_index = 600
	game_layer.add_child(ambient_rect)

func draw_furniture():
	rect_z(30, 145, 100, 118, COL_WOOD, 145)
	rect_z(33, 150, 94, 20, COL_BED, 150)
	rect_z(33, 165, 94, 88, COL_BLANKET, 165)
	rect_z(290, 245, 92, 15, COL_WOOD, 245)
	rect_z(305, 205, 60, 42, Color(0.15, 0.15, 0.18), 205)
	rect_z(308, 208, 54, 32, Color(0.50, 0.72, 0.95), 208)
	rect_z(305, 118, 68, 105, COL_WOOD, 118)
	rect_z(195, 115, 85, 115, COL_WOOD, 115)
	rect_z(75, 82, 105, 100, Color(0.20, 0.12, 0.08), 82)
	rect_z(82, 88, 90, 88, Color(0.55, 0.75, 0.95), 88)

func draw_decorations():
	rect_z(285, 95, 70, 60, COL_WOOD, 95)
	circ_z(250, 112, 20, Color(0.95, 0.95, 0.90), 112)
	rect_z(22, 365, 45, 42, Color(0.15, 0.10, 0.06), 365)
	var leaf_pos = [[35, 340], [50, 345], [42, 332]]
	for pos in leaf_pos:
		var leaf = mkrect(pos[0], pos[1], 14, 18, COL_PLANT)
		leaf.z_index = pos[1]
		game_layer.add_child(leaf)
		plant_leaves.append(leaf)

func draw_player():
	player_shadow = mkrect(168, 455, 35, 8, Color(0,0,0,0.25))
	player_shadow.z_index = 455
	game_layer.add_child(player_shadow)
	player = Node2D.new()
	player.position = Vector2(165, 375)
	player.z_index = 375
	game_layer.add_child(player)
	add_child_to(player, mkrect(0, 8, 32, 48, COL_PLAYER))
	add_child_to(player, mkrect(4, -22, 24, 30, COL_SKIN))
	add_child_to(player, mkrect(4, -30, 24, 16, COL_HAIR))

func draw_pets():
	food_bowl = Node2D.new()
	food_bowl.position = Vector2(80, 440)
	food_bowl.z_index = 440
	game_layer.add_child(food_bowl)
	add_child_to(food_bowl, mkrect(0, 0, 30, 15, Color(0.5, 0.45, 0.4)))
	var food_area = Area2D.new()
	food_area.input_event.connect(_on_food_input_event)
	var fcol = CollisionShape2D.new()
	fcol.shape = RectangleShape2D.new()
	fcol.shape.size = Vector2(30, 20)
	food_area.add_child(fcol)
	food_bowl.add_child(food_area)
	
	dog = Node2D.new()
	dog.position = Vector2(135, 422)
	dog.z_index = 422
	game_layer.add_child(dog)
	dog_sprite = Node2D.new()
	dog.add_child(dog_sprite)
	add_child_to(dog_sprite, mkrect(0, 0, 42, 25, COL_DOG))
	add_child_to(dog_sprite, mkrect(6, 4, 28, 14, COL_DOG_LIGHT))
	dog_eye_l = mkrect(-4, -12, 4, 4, Color(0.10, 0.05, 0.05))
	dog_eye_r = mkrect(6, -12, 4, 4, Color(0.10, 0.05, 0.05))
	add_child_to(dog_sprite, dog_eye_l)
	add_child_to(dog_sprite, dog_eye_r)
	dog_tail = mkrect(40, -8, 14, 6, COL_DOG)
	add_child_to(dog_sprite, dog_tail)
	
	var dog_area = Area2D.new()
	dog_area.input_event.connect(_on_dog_input_event)
	var collision = CollisionShape2D.new()
	collision.shape = RectangleShape2D.new()
	collision.shape.size = Vector2(50, 35)
	dog_area.add_child(collision)
	dog.add_child(dog_area)
	
	dog_emotion = Label.new()
	dog_emotion.add_theme_font_size_override("font_size", 14)
	dog_emotion.position = Vector2(10, -40)
	dog.add_child(dog_emotion)
	
	dog_status_bar = HBoxContainer.new()
	dog_status_bar.position = Vector2(-5, -55)
	dog.add_child(dog_status_bar)
	
	cat = Node2D.new()
	cat.position = Vector2(330, 95)
	cat.z_index = 95
	game_layer.add_child(cat)
	add_child_to(cat, mkrect(0, 0, 30, 20, COL_CAT))

func draw_items(): pass

func draw_ui():
	var top = Panel.new()
	top.name = "TopPanel"
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 60
	var top_style = StyleBoxFlat.new()
	top_style.bg_color = Color(0.06, 0.04, 0.02, 0.96)
	top.add_theme_stylebox_override("panel", top_style)
	ui_layer.add_child(top)
	
	var pet = GameManager.get_active_pet()
	var pet_name = "豆豆"
	var pet_breed = "柯基"
	if pet:
		pet_name = pet.name
		pet_breed = pet.breed
	
	# 宠物名字
	var name_label = Label.new()
	name_label.name = "PetName"
	name_label.text = pet_name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.position = Vector2(10, 8)
	ui_layer.add_child(name_label)
	
	# 切换按钮
	var switch_btn = Button.new()
	switch_btn.text = "切换"
	switch_btn.position = Vector2(120, 5)
	switch_btn.custom_minimum_size = Vector2(50, 28)
	switch_btn.pressed.connect(show_pet_switch_panel)
	ui_layer.add_child(switch_btn)
	
	# 添加按钮
	var add_btn = Button.new()
	add_btn.text = "+添加"
	add_btn.position = Vector2(180, 5)
	add_btn.custom_minimum_size = Vector2(50, 28)
	add_btn.pressed.connect(show_add_pet_dialog)
	ui_layer.add_child(add_btn)
	
	# 金币
	var coin_label = Label.new()
	coin_label.text = "金币:" + str(GameManager.coin)
	coin_label.position = Vector2(300, 8)
	ui_layer.add_child(coin_label)
	
	# 底部栏
	var bottom = HBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -62
	bottom.custom_minimum_size = Vector2(0, 62)
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	ui_layer.add_child(bottom)
	
	var btns = ["家园", "商店", "社交", "设置"]
	for i in range(4):
		var btn = Button.new()
		btn.text = btns[i]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(70, 50)
		btn.pressed.connect(func(): _on_bottom_btn_pressed(i))
		bottom.add_child(btn)
	
	update_pet_status()

func update_ui():
	# 刷新顶部UI - 只显示名字
	var name_label = ui_layer.get_node_or_null("TopPanel/PetName")
	if name_label:
		var pet = GameManager.get_active_pet()
		if pet:
			name_label.text = pet.name

func show_pet_switch_panel():
	var existing = ui_layer.get_node_or_null("PetSwitchPanel")
	if existing:
		existing.queue_free()
		return
	
	var panel = PanelContainer.new()
	panel.name = "PetSwitchPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(260, 350)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.06, 0.95)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", style)
	ui_layer.add_child(panel)
	
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(240, 250)
	panel.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(240, 300)
	vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox)
	
	var title = Label.new()
	title.text = "我的宠物"
	title.add_theme_font_size_override("font_size", 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	for p in GameManager.pets:
		var pet_card = HBoxContainer.new()
		pet_card.custom_minimum_size = Vector2(220, 50)
		vbox.add_child(pet_card)
		
		var icon = Label.new()
		icon.text = "🐶" if p.species == "dog" else "🐱"
		icon.add_theme_font_size_override("font_size", 24)
		icon.custom_minimum_size = Vector2(40, 40)
		pet_card.add_child(icon)
		
		var info = VBoxContainer.new()
		pet_card.add_child(info)
		
		var name_label = Label.new()
		name_label.text = p.name + " (" + p.breed + ")"
		name_label.add_theme_font_size_override("font_size", 14)
		info.add_child(name_label)
		
		var detail = Label.new()
		var gender_txt = "♂" if p.gender == "male" else "♀"
		detail.text = gender_txt + " " + str(p.age_months) + "个月"
		detail.add_theme_font_size_override("font_size", 10)
		detail.modulate = Color(0.7, 0.7, 0.7)
		info.add_child(detail)
		
		var btn_box = VBoxContainer.new()
		btn_box.custom_minimum_size = Vector2(80, 50)
		pet_card.add_child(btn_box)
		
		# 选中/编辑按钮
		if p.id == GameManager.active_pet_id:
			var cur_btn = Button.new()
			cur_btn.text = "当前"
			cur_btn.disabled = true
			cur_btn.custom_minimum_size = Vector2(70, 22)
			btn_box.add_child(cur_btn)
		else:
			var select_btn = Button.new()
			select_btn.text = "选择"
			select_btn.custom_minimum_size = Vector2(70, 22)
			select_btn.pressed.connect(_on_pet_selected.bind(p.id))
			btn_box.add_child(select_btn)
		
		var edit_btn = Button.new()
		edit_btn.text = "编辑"
		edit_btn.custom_minimum_size = Vector2(70, 22)
		edit_btn.pressed.connect(_on_edit_pet.bind(p))
		btn_box.add_child(edit_btn)
	
	var close_btn = Button.new()
	close_btn.text = "关闭"
	close_btn.pressed.connect(func(): panel.queue_free())
	vbox.add_child(close_btn)

func _on_edit_pet(pet):
	show_edit_pet_dialog(pet)

func show_edit_pet_dialog(pet):
	var existing = ui_layer.get_node_or_null("EditPetPanel")
	if existing: existing.queue_free()
	
	var panel = PanelContainer.new()
	panel.name = "EditPetPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(260, 300)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.06, 0.95)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", style)
	ui_layer.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "编辑宠物"
	title.add_theme_font_size_override("font_size", 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# 名字
	var name_box = HBoxContainer.new()
	vbox.add_child(name_box)
	var name_lbl = Label.new()
	name_lbl.text = "名字:"
	name_lbl.custom_minimum_size = Vector2(60, 30)
	name_box.add_child(name_lbl)
	var name_edit = LineEdit.new()
	name_edit.text = pet.name
	name_edit.custom_minimum_size = Vector2(150, 30)
	name_box.add_child(name_edit)
	
	# 年龄
	var age_box = HBoxContainer.new()
	vbox.add_child(age_box)
	var age_lbl = Label.new()
	age_lbl.text = "年龄:"
	age_lbl.custom_minimum_size = Vector2(60, 30)
	age_box.add_child(age_lbl)
	var age_slider = HSlider.new()
	age_slider.min_value = 1
	age_slider.max_value = 180
	age_slider.value = pet.age_months
	age_slider.custom_minimum_size = Vector2(100, 30)
	age_box.add_child(age_slider)
	var age_val = Label.new()
	age_val.text = str(pet.age_months) + "月"
	age_box.add_child(age_val)
	age_slider.value_changed.connect(func(v): age_val.text = str(int(v)) + "月")
	
	# 性别
	var gender_box = HBoxContainer.new()
	vbox.add_child(gender_box)
	var gender_lbl = Label.new()
	gender_lbl.text = "性别:"
	gender_lbl.custom_minimum_size = Vector2(60, 30)
	gender_box.add_child(gender_lbl)
	var gender_option = OptionButton.new()
	gender_option.add_item("♂ 公", 0)
	gender_option.add_item("♀ 母", 1)
	gender_option.selected = 0 if pet.gender == "male" else 1
	gender_option.custom_minimum_size = Vector2(100, 30)
	gender_box.add_child(gender_option)
	
	# 按钮
	var btn_box = HBoxContainer.new()
	vbox.add_child(btn_box)
	
	var save_btn = Button.new()
	save_btn.text = "保存"
	save_btn.custom_minimum_size = Vector2(80, 35)
	save_btn.pressed.connect(func():
		pet.name = name_edit.text if name_edit.text.strip_edges() != "" else pet.name
		pet.age_months = int(age_slider.value)
		pet.gender = "male" if gender_option.selected == 0 else "female"
		GameManager.save_game()
		update_ui()
		panel.queue_free()
	)
	btn_box.add_child(save_btn)
	
	var delete_btn = Button.new()
	delete_btn.text = "删除"
	delete_btn.custom_minimum_size = Vector2(80, 35)
	delete_btn.pressed.connect(func():
		GameManager.remove_pet(pet.id)
		panel.queue_free()
		refresh_pet()
		refresh_pet_panel()
	)
	btn_box.add_child(delete_btn)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "取消"
	cancel_btn.custom_minimum_size = Vector2(80, 35)
	cancel_btn.pressed.connect(func(): panel.queue_free())
	btn_box.add_child(cancel_btn)

func _on_pet_selected(pet_id):
	GameManager.switch_pet(pet_id)
	var panel = ui_layer.get_node_or_null("PetSwitchPanel")
	if panel: 
		panel.queue_free()
	refresh_pet()

func refresh_pet_panel():
	var panel = ui_layer.get_node_or_null("PetSwitchPanel")
	if panel:
		panel.queue_free()
		show_pet_switch_panel()

func show_add_pet_dialog():
	var existing = ui_layer.get_node_or_null("AddPetPanel")
	if existing:
		existing.queue_free()
		return
	
	var panel = PanelContainer.new()
	panel.name = "AddPetPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(280, 320)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.06, 0.95)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", style)
	ui_layer.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "添加新宠物"
	title.add_theme_font_size_override("font_size", 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# 名字输入
	var name_edit = LineEdit.new()
	name_edit.placeholder_text = "名字"
	name_edit.custom_minimum_size = Vector2(200, 30)
	vbox.add_child(name_edit)
	
	# 物种选择
	var species_option = OptionButton.new()
	species_option.add_item("🐶 狗狗", 0)
	species_option.add_item("🐱 猫咪", 1)
	vbox.add_child(species_option)
	
	# 品种选择
	var breed_option = OptionButton.new()
	for b in GameManager.dog_breeds:
		breed_option.add_item(b)
	vbox.add_child(breed_option)
	
	# 物种变化时更新品种
	species_option.item_selected.connect(func(idx):
		breed_option.clear()
		var breeds = GameManager.dog_breeds if idx == 0 else GameManager.cat_breeds
		for b in breeds:
			breed_option.add_item(b)
	)
	
	# 性别选择
	var gender_option = OptionButton.new()
	gender_option.add_item("♂ 公", 0)
	gender_option.add_item("♀ 母", 1)
	vbox.add_child(gender_option)
	
	# 确认按钮
	var confirm_btn = Button.new()
	confirm_btn.text = "确认添加"
	confirm_btn.pressed.connect(func():
		var new_pet = GameManager.PetProfile.new()
		new_pet.id = str(Time.get_unix_time_from_system()) + str(randi() % 1000)
		new_pet.name = name_edit.text if name_edit.text.strip_edges() != "" else "新宠物"
		new_pet.species = "dog" if species_option.selected == 0 else "cat"
		new_pet.breed = breed_option.text
		new_pet.gender = "male" if gender_option.selected == 0 else "female"
		new_pet.age_months = 12
		GameManager.add_pet(new_pet)
		panel.queue_free()
		refresh_pet()
		refresh_pet_panel()
	)
	vbox.add_child(confirm_btn)
	
	var close_btn = Button.new()
	close_btn.text = "取消"
	close_btn.pressed.connect(func(): panel.queue_free())
	vbox.add_child(close_btn)

func update_pet_status():
	var pet = GameManager.get_active_pet()
	if pet == null or dog_status_bar == null: return
	
	# 重建状态条
	for c in dog_status_bar.get_children():
		c.queue_free()
	
	dog_status_bar.add_child(create_bar("饥饿", pet.hunger))
	dog_status_bar.add_child(create_bar("快乐", pet.happiness))
	dog_status_bar.add_child(create_bar("清洁", pet.cleanliness))

func create_bar(label_text, value):
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(22, 28)
	var icon_label = Label.new()
	icon_label.text = label_text
	icon_label.add_theme_font_size_override("font_size", 8)
	container.add_child(icon_label)
	var bar = ProgressBar.new()
	bar.value = value
	bar.custom_minimum_size = Vector2(18, 6)
	bar.show_percentage = false
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.3, 0.3, 0.3)
	bar.add_theme_stylebox_override("background", style)
	container.add_child(bar)
	return container

func process_cat(delta): pass
func process_plant(delta):
	var pt = 0.0
	pt += delta
	var sway = sin(pt * 1.5) * 3
	for leaf in plant_leaves: leaf.rotation_degrees = sway + randf_range(-3, 3)

func process_player(delta):
	var pt = 0.0
	pt += delta
	player.position.y = 373 + sin(pt * 2) * 2
	player_shadow.position.x = player.position.x + 5
	player_pos = player.position

func _on_dog_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_dog_clicked()

func mkrect(x, y, w, h, color):
	var r = ColorRect.new()
	r.color = color
	r.position = Vector2(x, y)
	r.size = Vector2(w, h)
	return r

func add_child_to(p, c): p.add_child(c)

func rect_z(x, y, w, h, color, z):
	var r = mkrect(x, y, w, h, color)
	r.z_index = z
	game_layer.add_child(r)

func circ_z(x, y, r, color, z):
	var p = Polygon2D.new()
	var pts = PackedVector2Array()
	for i in range(20):
		var a = i * TAU / 20
		pts.append(Vector2(x + cos(a) * r, y + sin(a) * r))
	p.polygon = pts
	p.color = color
	p.z_index = z
	game_layer.add_child(p)

func _on_bottom_btn_pressed(idx):
	match idx:
		0: pass  # 家园
		1: show_shop_panel()  # 商店
		2: pass  # 社交
		3: pass  # 设置

func show_shop_panel():
	var existing = ui_layer.get_node_or_null("ShopPanel")
	if existing:
		existing.queue_free()
	
	var panel = PanelContainer.new()
	panel.name = "ShopPanel"
	panel.custom_minimum_size = Vector2(360, 500)
	panel.position = Vector2(20, 100)
	ui_layer.add_child(panel)
	
	var scroll = ScrollContainer.new()
	panel.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	scroll.add_child(vbox)
	
	var title = Label.new()
	title.text = "🛒 商店 - 金币: " + str(GameManager.coin)
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)
	
	var items = GameManager.get_shop_items()
	for item in items:
		var item_box = HBoxContainer.new()
		vbox.add_child(item_box)
		
		var info = Label.new()
		info.text = item.name + "\n" + item.desc + "\n💰 " + str(item.price)
		info.custom_minimum_size = Vector2(200, 50)
		item_box.add_child(info)
		
		var buy_btn = Button.new()
		buy_btn.text = "购买"
		buy_btn.pressed.connect(func(): _buy_item(item.id, item.price, item.name))
		item_box.add_child(buy_btn)
	
	var close_btn = Button.new()
	close_btn.text = "关闭"
	close_btn.pressed.connect(func(): panel.queue_free())
	vbox.add_child(close_btn)

func _buy_item(item_id, price, item_name):
	if GameManager.coin >= price:
		GameManager.coin -= price
		GameManager.save_game()
		show_message("购买成功: " + item_name)
		# 刷新商店面板
		show_shop_panel()
	else:
		show_message("金币不足!")

func show_message(msg):
	var existing = ui_layer.get_node_or_null("MessageLabel")
	if existing: existing.queue_free()
	var label = Label.new()
	label.name = "MessageLabel"
	label.text = msg
	label.add_theme_font_size_override("font_size", 16)
	label.position = Vector2(100, 350)
	label.modulate = Color(1, 0.5, 0.5)
	ui_layer.add_child(label)
	await get_tree().create_timer(2.0).timeout
	if label: label.queue_free()

# ========== 情绪粒子效果 ==========
func emit_emotion_particles(emotion: String):
	if not dog: return
	
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.lifetime = 1.5
	particles.position = dog.position + Vector2(0, -30)
	particles.z_index = 500
	
	match emotion:
		"happy":
			particles.amount = 10
			particles.color = Color(1, 0.5, 0.7, 1)
			particles.scale_amount = 8
			particles.gravity = Vector2(0, -50)
			particles.direction = Vector2(0, -1)
			particles.spread = 45
		"hungry":
			particles.amount = 8
			particles.color = Color(0.5, 0.5, 0.5, 1)
			particles.scale_amount = 6
			particles.gravity = Vector2(0, -30)
		"angry":
			particles.amount = 12
			particles.color = Color(1, 0.2, 0.2, 1)
			particles.scale_amount = 10
			particles.gravity = Vector2(0, -80)
		"sick":
			particles.amount = 6
			particles.color = Color(0.5, 1, 0.5, 1)
			particles.scale_amount = 8
			particles.gravity = Vector2(0, -20)
	
	game_layer.add_child(particles)
	await get_tree().create_timer(2.0).timeout
	particles.queue_free()

# 在心情好时自动触发粒子
func _check_happiness_particles(pet):
	if pet.happiness > 80 and randf() < 0.005:
		emit_emotion_particles("happy")
	elif pet.hunger < 30 and randf() < 0.005:
		emit_emotion_particles("hungry")
