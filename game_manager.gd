extends Node

class PetProfile:
	var id: String
	var name: String
	var species: String
	var breed: String
	var gender: String
	var age_months: int
	var hunger: int = 80
	var happiness: int = 90
	var cleanliness: int = 100
	var last_interaction: int = 0
	
	func to_dict():
		return {"id": id, "name": name, "species": species, "breed": breed, "gender": gender, "age_months": age_months, "hunger": hunger, "happiness": happiness, "cleanliness": cleanliness, "last_interaction": last_interaction}
	
	func from_dict(d):
		id = d.get("id", "")
		name = d.get("name", "豆豆")
		species = d.get("species", "dog")
		breed = d.get("breed", "柯基")
		gender = d.get("gender", "male")
		age_months = d.get("age_months", 12)
		hunger = d.get("hunger", 80)
		happiness = d.get("happiness", 90)
		cleanliness = d.get("cleanliness", 100)
		last_interaction = d.get("last_interaction", 0)

class BreedConfig:
	var name: String
	var body_color: Color
	var secondary_color: Color
	var body_size: int  # 0=小型, 1=中型, 2=大型
	var body_shape: int  # 0=普通, 1=短腿, 2=修长
	var ear_type: int  # 0=普通, 1=垂耳, 2=尖耳
	var tail_length: int  # 0=短, 1=普通, 2=长
	var fur_length: int  # 0=短毛, 1=中毛, 2=长毛
	var has_pattern: bool
	var pattern_color: Color
	var is_cat: bool
	# 品种特异性行为
	var behavior_energy: int = 50  # 精力水平 (0-100)
	var behavior_vocal: int = 30   # 叫声频率
	var behavior_playful: int = 50  # 玩耍欲望
	var behavior_loyal: int = 50   # 粘人程度
	var behavior_active: int = 50  # 活跃程度
	var special_action: String = ""  # 特殊动作名称
	
	func _init(n, bc, sc, bs, bsh, et, tl, fl, hp, pc, ic,
		be=50, bv=30, bp=50, bl=50, ba=50, sa=""):
		name = n
		body_color = bc
		secondary_color = sc
		body_size = bs
		body_shape = bsh
		ear_type = et
		tail_length = tl
		fur_length = fl
		has_pattern = hp
		pattern_color = pc
		is_cat = ic
		behavior_energy = be
		behavior_vocal = bv
		behavior_playful = bp
		behavior_loyal = bl
		behavior_active = ba
		special_action = sa
		fur_length = fl
		has_pattern = hp
		pattern_color = pc
		is_cat = ic

var breed_configs = {}
var size_bases = {0: {"w": 30, "h": 20, "scale": 0.7}, 1: {"w": 38, "h": 24, "scale": 0.85}, 2: {"w": 45, "h": 28, "scale": 1.0}}

var pets: Array = []
var active_pet_id: String = ""
var coin: int = 1000

signal pet_switched
signal data_changed

func _ready():
	_init_breeds()
	dog_breeds = get_dog_breeds()
	cat_breeds = get_cat_breeds()
	load_game()

func _init_breeds():
	# 大型狗 - 精力旺盛
	breed_configs["金毛"] = BreedConfig.new("金毛", Color(0.85, 0.65, 0.25), Color(0.95, 0.85, 0.5), 2, 0, 0, 1, 1, false, Color(0,0,0), false, 70, 40, 80, 70, 60, "握手")
	breed_configs["拉布拉多"] = BreedConfig.new("拉布拉多", Color(0.6, 0.45, 0.25), Color(0.3, 0.25, 0.15), 2, 0, 0, 1, 0, false, Color(0,0,0), false, 75, 30, 85, 65, 70, "捡球")
	breed_configs["哈士奇"] = BreedConfig.new("哈士奇", Color(0.7, 0.7, 0.75), Color(0.95, 0.95, 0.95), 2, 2, 2, 2, 1, true, Color(0.2, 0.25, 0.3), false, 95, 80, 70, 40, 90, "嚎叫")
	breed_configs["边牧"] = BreedConfig.new("边牧", Color(0.15, 0.15, 0.15), Color(0.85, 0.85, 0.85), 2, 2, 2, 1, 1, true, Color(0.85,0.85,0.85), false, 90, 50, 95, 55, 95, "接飞盘")
	breed_configs["萨摩耶"] = BreedConfig.new("萨摩耶", Color(0.95, 0.95, 0.95), Color(1, 1, 1), 2, 0, 0, 2, 0, false, Color(0,0,0), false, 60, 35, 65, 75, 55, "微笑")
	breed_configs["阿拉斯加"] = BreedConfig.new("阿拉斯加", Color(0.35, 0.35, 0.4), Color(0.6, 0.5, 0.45), 2, 0, 1, 2, 1, true, Color(0.5,0.4,0.35), false, 70, 45, 55, 60, 60, "拉雪橇")
	breed_configs["德牧"] = BreedConfig.new("德牧", Color(0.2, 0.15, 0.1), Color(0.3, 0.25, 0.2), 2, 0, 0, 1, 0, false, Color(0,0,0), false, 80, 55, 60, 50, 75, "警戒")
	breed_configs["杜宾"] = BreedConfig.new("杜宾", Color(0.15, 0.1, 0.08), Color(0.25, 0.2, 0.15), 2, 2, 0, 1, 0, false, Color(0,0,0), false, 85, 60, 50, 45, 80, "护卫")
	breed_configs["罗威纳"] = BreedConfig.new("罗威纳", Color(0.15, 0.1, 0.08), Color(0.2, 0.15, 0.1), 2, 0, 0, 0, 0, false, Color(0,0,0), false, 75, 70, 40, 55, 65, "守卫")
	breed_configs["大丹"] = BreedConfig.new("大丹", Color(0.85, 0.8, 0.7), Color(0.95, 0.9, 0.8), 2, 2, 0, 1, 0, false, Color(0,0,0), false, 50, 25, 45, 80, 40, "温柔靠靠")
	breed_configs["圣伯纳"] = BreedConfig.new("圣伯纳", Color(0.85, 0.75, 0.6), Color(0.9, 0.8, 0.65), 2, 0, 0, 2, 1, true, Color(0.7,0.6,0.5), false, 40, 20, 35, 90, 35, "救生")
	breed_configs["大白熊"] = BreedConfig.new("大白熊", Color(0.95, 0.95, 0.95), Color(1, 1, 1), 2, 0, 0, 2, 0, false, Color(0,0,0), false, 45, 25, 40, 85, 40, "守护")
	breed_configs["秋田"] = BreedConfig.new("秋田", Color(0.75, 0.55, 0.4), Color(0.9, 0.7, 0.55), 2, 0, 0, 1, 0, false, Color(0,0,0), false, 55, 65, 45, 60, 50, "忠诚")
	breed_configs["柴犬"] = BreedConfig.new("柴犬", Color(0.85, 0.55, 0.25), Color(0.95, 0.9, 0.85), 1, 0, 2, 0, 0, true, Color(0.95,0.9,0.85), false, 65, 75, 55, 50, 60, "微笑")
	
	# 中型狗
	breed_configs["柯基"] = BreedConfig.new("柯基", Color(0.95, 0.65, 0.25), Color(1, 1, 1), 1, 1, 1, 0, 0, true, Color(1,1,1), false, 80, 70, 60, 55, 75, "摇屁股")
	breed_configs["法斗"] = BreedConfig.new("法斗", Color(0.7, 0.65, 0.55), Color(0.5, 0.45, 0.4), 1, 1, 1, 0, 0, false, Color(0,0,0), false, 45, 55, 40, 70, 40, "打呼")
	breed_configs["松狮"] = BreedConfig.new("松狮", Color(0.65, 0.45, 0.3), Color(0.8, 0.5, 0.35), 1, 0, 0, 2, 0, false, Color(0,0,0), false, 35, 20, 30, 85, 30, "懒洋洋")
	breed_configs["沙皮"] = BreedConfig.new("沙皮", Color(0.7, 0.6, 0.5), Color(0.8, 0.7, 0.6), 1, 0, 0, 0, 0, false, Color(0,0,0), false, 30, 25, 35, 75, 30, "发呆")
	breed_configs["巴哥"] = BreedConfig.new("巴哥", Color(0.75, 0.7, 0.6), Color(0.85, 0.8, 0.7), 1, 1, 0, 0, 0, false, Color(0,0,0), false, 35, 50, 30, 80, 30, "委屈")
	breed_configs["牛头梗"] = BreedConfig.new("牛头梗", Color(0.95, 0.9, 0.85), Color(1, 1, 1), 1, 0, 0, 0, 0, false, Color(0,0,0), false, 60, 45, 50, 65, 55, "调皮")
	breed_configs["腊肠"] = BreedConfig.new("腊肠", Color(0.65, 0.45, 0.3), Color(0.8, 0.6, 0.4), 1, 1, 0, 0, 0, false, Color(0,0,0), false, 55, 40, 45, 60, 50, "钻洞")
	breed_configs["比格"] = BreedConfig.new("比格", Color(0.7, 0.55, 0.4), Color(0.85, 0.7, 0.5), 1, 0, 0, 0, 1, true, Color(0.5,0.4,0.3), false, 70, 60, 55, 50, 65, "嗅觉")
	breed_configs["惠比特"] = BreedConfig.new("惠比特", Color(0.55, 0.5, 0.45), Color(0.7, 0.65, 0.6), 1, 2, 0, 0, 0, false, Color(0,0,0), false, 80, 20, 60, 45, 75, "奔跑")
	breed_configs["贝灵顿"] = BreedConfig.new("贝灵顿", Color(0.65, 0.6, 0.55), Color(0.8, 0.75, 0.7), 1, 2, 2, 2, 0, false, Color(0,0,0), false, 50, 30, 45, 70, 45, "高贵")
	breed_configs["雪纳瑞"] = BreedConfig.new("雪纳瑞", Color(0.55, 0.55, 0.55), Color(0.7, 0.7, 0.7), 0, 0, 0, 2, 0, false, Color(0,0,0), false, 55, 45, 50, 65, 50, "威严")
	
	# 小型狗
	breed_configs["博美"] = BreedConfig.new("博美", Color(0.85, 0.55, 0.25), Color(1, 0.9, 0.7), 0, 0, 2, 2, 0, false, Color(0,0,0), false, 65, 80, 55, 60, 60, "炸毛")
	breed_configs["泰迪"] = BreedConfig.new("泰迪", Color(0.45, 0.3, 0.2), Color(0.6, 0.5, 0.4), 0, 0, 2, 2, 0, false, Color(0,0,0), false, 50, 35, 70, 80, 50, "撒娇")
	breed_configs["吉娃娃"] = BreedConfig.new("吉娃娃", Color(0.75, 0.6, 0.5), Color(0.9, 0.8, 0.7), 0, 0, 2, 0, 0, false, Color(0,0,0), false, 40, 85, 35, 55, 40, "警惕")
	breed_configs["约克夏"] = BreedConfig.new("约克夏", Color(0.25, 0.2, 0.25), Color(0.4, 0.35, 0.4), 0, 0, 2, 2, 0, true, Color(0.35,0.3,0.35), false, 45, 40, 50, 70, 45, "高贵")
	breed_configs["马尔济斯"] = BreedConfig.new("马尔济斯", Color(0.98, 0.98, 0.98), Color(1, 1, 1), 0, 0, 2, 2, 0, false, Color(0,0,0), false, 35, 25, 40, 85, 35, "公主")
	breed_configs["比熊"] = BreedConfig.new("比熊", Color(0.98, 0.98, 0.98), Color(1, 1, 1), 0, 0, 2, 2, 0, false, Color(0,0,0), false, 50, 30, 55, 75, 50, "棉花糖")
	breed_configs["西高地"] = BreedConfig.new("西高地", Color(0.95, 0.95, 0.95), Color(1, 1, 1), 0, 0, 0, 1, 0, false, Color(0,0,0), false, 55, 40, 50, 65, 50, "活力")
	breed_configs["马尔基"] = BreedConfig.new("马尔基", Color(0.65, 0.55, 0.45), Color(0.8, 0.7, 0.6), 0, 0, 2, 1, 0, false, Color(0,0,0), false, 40, 30, 35, 75, 40, "眨眼")
	breed_configs["北京犬"] = BreedConfig.new("北京犬", Color(0.75, 0.6, 0.45), Color(0.9, 0.75, 0.6), 0, 1, 2, 1, 1, true, Color(0.6,0.5,0.4), false, 30, 55, 25, 70, 30, "傲娇")
	breed_configs["西施"] = BreedConfig.new("西施", Color(0.7, 0.55, 0.4), Color(0.85, 0.7, 0.55), 0, 0, 2, 2, 0, false, Color(0,0,0), false, 35, 25, 30, 85, 35, "贵妃")
	breed_configs["蝴蝶犬"] = BreedConfig.new("蝴蝶犬", Color(0.95, 0.9, 0.8), Color(1, 0.95, 0.85), 0, 2, 0, 1, 1, true, Color(0.5,0.4,0.3), false, 60, 35, 55, 70, 55, "飞舞")
	breed_configs["小鹿犬"] = BreedConfig.new("小鹿犬", Color(0.65, 0.45, 0.3), Color(0.8, 0.6, 0.45), 0, 0, 0, 0, 0, false, Color(0,0,0), false, 70, 50, 50, 45, 65, "精灵")
	
	# 大型猫
	breed_configs["布偶"] = BreedConfig.new("布偶", Color(0.95, 0.92, 0.88), Color(0.7, 0.65, 0.6), 2, 0, 0, 2, 2, true, Color(0.5, 0.45, 0.4), true, 25, 20, 30, 95, 20, "呼噜")
	breed_configs["缅因"] = BreedConfig.new("缅因", Color(0.5, 0.45, 0.4), Color(0.65, 0.55, 0.5), 2, 0, 2, 2, 2, true, Color(0.3,0.25,0.2), true, 45, 25, 40, 75, 40, "绅士")
	breed_configs["挪威森林"] = BreedConfig.new("挪威森林", Color(0.45, 0.42, 0.4), Color(0.6, 0.55, 0.5), 2, 0, 2, 2, 2, true, Color(0.4,0.35,0.3), true, 50, 20, 45, 70, 45, "森林")
	breed_configs["西伯利亚"] = BreedConfig.new("西伯利亚", Color(0.5, 0.5, 0.55), Color(0.65, 0.65, 0.7), 2, 0, 2, 2, 1, true, Color(0.3,0.3,0.35), true, 45, 25, 45, 70, 40, "勇士")
	breed_configs["土耳其梵"] = BreedConfig.new("土耳其梵", Color(0.95, 0.95, 0.95), Color(1, 1, 1), 2, 0, 0, 1, 0, false, Color(0,0,0), true, 50, 30, 45, 65, 45, "游泳")
	breed_configs["孟加拉"] = BreedConfig.new("孟加拉", Color(0.75, 0.65, 0.5), Color(0.3, 0.25, 0.2), 2, 2, 0, 0, 0, true, Color(0.2,0.15,0.1), true)
	
	# 中型猫
	breed_configs["英短"] = BreedConfig.new("英短", Color(0.6, 0.65, 0.7), Color(0.5, 0.55, 0.6), 1, 0, 0, 0, 0, false, Color(0,0,0), true)
	breed_configs["美短"] = BreedConfig.new("美短", Color(0.7, 0.7, 0.7), Color(0.4, 0.4, 0.45), 1, 0, 0, 0, 0, true, Color(0.3,0.3,0.35), true)
	breed_configs["波斯"] = BreedConfig.new("波斯", Color(0.95, 0.9, 0.85), Color(0.5, 0.5, 0.5), 1, 0, 1, 2, 2, false, Color(0,0,0), true)
	breed_configs["加菲"] = BreedConfig.new("加菲", Color(0.85, 0.7, 0.5), Color(0.7, 0.55, 0.4), 1, 1, 0, 1, 0, false, Color(0,0,0), true)
	breed_configs["异国"] = BreedConfig.new("异国", Color(0.75, 0.7, 0.6), Color(0.85, 0.8, 0.7), 1, 1, 0, 1, 0, false, Color(0,0,0), true)
	breed_configs["德文"] = BreedConfig.new("德文", Color(0.6, 0.5, 0.45), Color(0.75, 0.65, 0.6), 1, 2, 0, 0, 0, false, Color(0,0,0), true)
	breed_configs["柯尼斯"] = BreedConfig.new("柯尼斯", Color(0.7, 0.55, 0.4), Color(0.85, 0.7, 0.55), 1, 2, 0, 0, 0, false, Color(0,0,0), true)
	breed_configs["俄罗斯蓝"] = BreedConfig.new("俄罗斯蓝", Color(0.7, 0.75, 0.8), Color(0.8, 0.85, 0.9), 1, 0, 0, 0, 0, false, Color(0,0,0), true, 35, 15, 40, 75, 30, "安静")
	breed_configs["苏格兰折耳"] = BreedConfig.new("苏格兰折耳", Color(0.65, 0.6, 0.55), Color(0.8, 0.75, 0.7), 1, 1, 0, 1, 0, false, Color(0,0,0), true, 40, 25, 35, 80, 35, "萌态")
	
	# 小型猫
	breed_configs["暹罗"] = BreedConfig.new("暹罗", Color(0.95, 0.9, 0.8), Color(0.35, 0.25, 0.2), 0, 2, 2, 2, 0, true, Color(0.35,0.25,0.2), true, 60, 85, 65, 90, 60, "话痨")
	breed_configs["田园"] = BreedConfig.new("田园", Color(0.8, 0.75, 0.6), Color(0.3, 0.3, 0.3), 0, 0, 1, 0, 0, true, Color(0.2,0.2,0.2), true, 50, 40, 45, 55, 50, "机警")
	breed_configs["豹猫"] = BreedConfig.new("豹猫", Color(0.75, 0.65, 0.5), Color(0.3, 0.25, 0.2), 0, 2, 1, 0, 0, true, Color(0.2,0.15,0.1), true, 75, 35, 70, 40, 75, "猎手")
	breed_configs["矮脚猫"] = BreedConfig.new("矮脚猫", Color(0.7, 0.65, 0.6), Color(0.85, 0.8, 0.75), 0, 1, 0, 1, 0, false, Color(0,0,0), true, 45, 30, 50, 70, 45, "萌短")
	breed_configs["新加坡"] = BreedConfig.new("新加坡", Color(0.55, 0.45, 0.4), Color(0.7, 0.6, 0.55), 0, 0, 0, 0, 0, false, Color(0,0,0), true, 40, 35, 45, 65, 40, "迷你")
	breed_configs["孟买"] = BreedConfig.new("孟买", Color(0.1, 0.1, 0.1), Color(0.15, 0.15, 0.15), 0, 0, 0, 0, 0, false, Color(0,0,0), true, 50, 40, 55, 75, 50, "黑豹")
	breed_configs["埃及猫"] = BreedConfig.new("埃及猫", Color(0.6, 0.6, 0.6), Color(0.4, 0.4, 0.4), 0, 0, 0, 0, 0, true, Color(0.2,0.2,0.2), true, 55, 45, 50, 60, 55, "神圣")
	breed_configs["日本短尾"] = BreedConfig.new("日本短尾", Color(0.75, 0.7, 0.6), Color(0.9, 0.85, 0.75), 0, 0, 0, 0, 0, true, Color(0,0,0), true, 50, 50, 55, 65, 50, "招财")
	breed_configs["临清狮猫"] = BreedConfig.new("临清狮猫", Color(0.95, 0.95, 0.95), Color(1, 1, 1), 1, 0, 2, 2, 0, false, Color(0,0,0), true, 35, 25, 30, 80, 30, "仙风")

	# 中型猫补充
	breed_configs["英短"] = BreedConfig.new("英短", Color(0.6, 0.65, 0.7), Color(0.5, 0.55, 0.6), 1, 0, 0, 0, 0, false, Color(0,0,0), true, 30, 20, 25, 75, 25, "肥宅")
	breed_configs["美短"] = BreedConfig.new("美短", Color(0.7, 0.7, 0.7), Color(0.4, 0.4, 0.45), 1, 0, 0, 0, 0, true, Color(0.3,0.3,0.35), true, 55, 35, 50, 65, 50, "活泼")
	breed_configs["波斯"] = BreedConfig.new("波斯", Color(0.95, 0.9, 0.85), Color(0.5, 0.5, 0.5), 1, 0, 1, 2, 2, false, Color(0,0,0), true, 20, 15, 20, 90, 15, "高贵")
	breed_configs["加菲"] = BreedConfig.new("加菲", Color(0.85, 0.7, 0.5), Color(0.7, 0.55, 0.4), 1, 1, 0, 1, 0, false, Color(0,0,0), true, 25, 30, 25, 85, 20, "扁脸")
	breed_configs["异国"] = BreedConfig.new("异国", Color(0.75, 0.7, 0.6), Color(0.85, 0.8, 0.7), 1, 1, 0, 1, 0, false, Color(0,0,0), true, 25, 25, 25, 80, 20, "扁圆")
	breed_configs["德文"] = BreedConfig.new("德文", Color(0.6, 0.5, 0.45), Color(0.75, 0.65, 0.6), 1, 2, 0, 0, 0, false, Color(0,0,0), true, 65, 40, 70, 75, 65, "精灵")
	breed_configs["柯尼斯"] = BreedConfig.new("柯尼斯", Color(0.7, 0.55, 0.4), Color(0.85, 0.7, 0.55), 1, 2, 0, 0, 0, false, Color(0,0,0), true, 65, 45, 65, 65, 65, "电臀")
	breed_configs["孟加拉"] = BreedConfig.new("孟加拉", Color(0.75, 0.65, 0.5), Color(0.3, 0.25, 0.2), 2, 2, 0, 0, 0, true, Color(0.2,0.15,0.1), true, 80, 40, 75, 45, 80, "野性")

func get_breed_config(breed_name: String):
	return breed_configs.get(breed_name, breed_configs.get("柯基"))

# 品种列表（用于UI下拉选择）
func get_dog_breeds() -> Array:
	return ["金毛", "拉布拉多", "哈士奇", "边牧", "萨摩耶", "阿拉斯加", "德牧", "杜宾", "罗威纳", "大丹", "圣伯纳", "大白熊", "秋田", "柴犬", "柯基", "法斗", "松狮", "沙皮", "巴哥", "牛头梗", "腊肠", "比格", "惠比特", "贝灵顿", "雪纳瑞", "博美", "泰迪", "吉娃娃", "约克夏", "马尔济斯", "比熊", "西高地", "马尔基", "北京犬", "西施", "蝴蝶犬", "小鹿犬"]

func get_cat_breeds() -> Array:
	return ["布偶", "缅因", "挪威森林", "西伯利亚", "土耳其梵", "孟加拉", "英短", "美短", "波斯", "加菲", "异国", "德文", "柯尼斯", "俄罗斯蓝", "苏格兰折耳", "暹罗", "田园", "豹猫", "矮脚猫", "新加坡", "孟买", "埃及猫", "日本短尾", "临清狮猫"]

var dog_breeds = []
var cat_breeds = []

func add_pet(profile: PetProfile):
	pets.append(profile)
	if active_pet_id == "": active_pet_id = profile.id
	save_game()
	data_changed.emit()

func get_active_pet() -> PetProfile:
	for p in pets:
		if p.id == active_pet_id: return p
	return null

func switch_pet(new_id: String):
	active_pet_id = new_id
	save_game()
	pet_switched.emit()

func remove_pet(pet_id: String):
	var idx = -1
	for i in range(pets.size()):
		if pets[i].id == pet_id: idx = i
	if idx != -1:
		pets.remove_at(idx)
		if active_pet_id == pet_id:
			active_pet_id = pets[0].id if pets.size() > 0 else ""
	save_game()
	data_changed.emit()

func save_game():
	var arr = []
	for p in pets: arr.append(p.to_dict())
	var d = {"pets": arr, "active_id": active_pet_id, "coin": coin, "last_save": Time.get_unix_time_from_system()}
	var f = FileAccess.open("user://savegame.json", FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(d)); f.close()

func load_game():
	if FileAccess.file_exists("user://savegame.json"):
		var f = FileAccess.open("user://savegame.json", FileAccess.READ)
		if f:
			var j = JSON.new()
			var e = j.parse(f.get_as_text())
			if e == OK:
				var d = j.get_data()
				for pd in d.get("pets", []):
					var p = PetProfile.new()
					p.from_dict(pd)
					pets.append(p)
				active_pet_id = d.get("active_id", "")
				coin = d.get("coin", 1000)
				var ls = d.get("last_save", 0)
				if ls > 0:
					var om = (Time.get_unix_time_from_system() - ls) / 60
					if om > 0:
						for p in pets:
							p.hunger = max(0, p.hunger - int(om))
							p.cleanliness = max(0, p.cleanliness - int(om/2))
			f.close()
	if pets.size() == 0:
		var dp = PetProfile.new()
		dp.id = str(Time.get_unix_time_from_system()) + str(randi() % 1000)
		dp.name = "豆豆"
		dp.species = "dog"
		dp.breed = "柯基"
		dp.gender = "male"
		dp.age_months = 12
		add_pet(dp)

# ========== 商店系统 ==========
class ShopItem:
	var id: String
	var name: String
	var desc: String
	var price: int
	var type: String  # food/toy/decor/medicine
	var effect_value: int
	
	func _init(i, n, d, p, t, e):
		id = i; name = n; desc = d; price = p; type = t; effect_value = e

var shop_items = []

func _init_shop():
	# 食物
	shop_items.append(ShopItem.new("food_basic", "普通狗粮", "+20饥饿", 50, "food", 20))
	shop_items.append(ShopItem.new("food_premium", "高级罐头", "+50饥饿 +10快乐", 150, "food", 50))
	shop_items.append(ShopItem.new("food_snack", "零食", "+5快乐", 30, "food", 5))
	# 玩具
	shop_items.append(ShopItem.new("toy_ball", "网球", "解锁追逐互动", 100, "toy", 0))
	shop_items.append(ShopItem.new("toy_feather", "逗猫棒", "解锁跳跃互动", 120, "toy", 0))
	# 装饰
	shop_items.append(ShopItem.new("decor_carpet", "地毯", "美观+舒适", 200, "decor", 0))
	shop_items.append(ShopItem.new("decor_plant", "盆栽", "+5清洁度", 80, "decor", 5))
	# 医疗
	shop_items.append(ShopItem.new("medicine_pill", "药丸", "恢复健康", 100, "medicine", 0))

func get_shop_items() -> Array:
	if shop_items.size() == 0: _init_shop()
	return shop_items

func buy_item(item_id: String) -> bool:
	var item = null
	for i in shop_items:
		if i.id == item_id: item = i
	if item == null: return false
	if coin >= item.price:
		coin -= item.price
		save_game()
		return true
	return false
