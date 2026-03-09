extends Control

func _ready():
	# 加载素材
	var bg_texture = load("res://res/sprites/office_bg.png")
	
	# 显示 office_bg
	if bg_texture:
		var bg_sprite = Sprite2D.new()
		bg_sprite.texture = bg_texture
		bg_sprite.position = Vector2(0, 0)
		add_child(bg_sprite)
		print("显示图片: ", bg_texture.get_size())
	else:
		print("图片加载失败")
