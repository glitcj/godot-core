@tool
extends Node2D
class_name _RPGM_Portrait

@export var mark : String = "MRK"
@export_category("Portrait")
@export_enum("ghost", "evaporate", "creature_v1", "highlight", "fog", "shine", "function",
			 "random", "wiggle", "sphere", "outline", "chessboard"
			) var type: String = "random":
	set(v):
		type = v
		_update_material()
		
# note: onready variables are ignored by the editor
@onready var animation_player = %AnimationPlayer as AnimationPlayer


var atlas : AtlasTexture
var _material : ShaderMaterial
var is_moving = false
var facing := Vector2(-1, 0):
	set(value):
		facing = value
		if %AnimationTree: 
			%AnimationTree.set("parameters/BlendSpace2D/blend_position",  facing)
			%AnimationPlayer.stop()
			%AnimationPlayer.play("actioned")



var sprite : String = "cream":
	set(v):
		sprite = v
		if %AnimatedSprite2D == null: return
		%AnimatedSprite2D.animation = sprite
		_update_atlas()

func _editor_update():
	pass
	
func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	var anim_names = _get_available_animation_names()
	properties.append({
		"name": "sprite",
		"type": TYPE_STRING,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": ",".join(anim_names)
	})
	return properties

func _get_available_animation_names() -> Array:
	var sprite_node =  %AnimatedSprite2D # get_node_or_null("AnimatedSprite2D")
	if sprite_node and sprite_node.sprite_frames:
		return Array(sprite_node.sprite_frames.get_animation_names())
	return ["None"]
	
func _update_material():
		_material = ShaderMaterial.new() as ShaderMaterial
		if type == "highlight":
			_material.shader = load("res://scenes/peekaboo/shaders/_highlight.gdshader")
		if type == "evaporate":
			_material.shader = load("res://scenes/peekaboo/shaders/_evaporate.gdshader")
		if type == "ghost":
			_material.shader = load("res://scenes/peekaboo/shaders/_ghost.gdshader")
		if type == "random":
			_material.shader = load("res://scenes/peekaboo/shaders/_random.gdshader")
		if type == "wiggle":
			_material.shader = load("res://scenes/peekaboo/shaders/_wiggle.gdshader")
		if type == "sphere":
			_material.shader = load("res://scenes/peekaboo/shaders/_sphere_and_correct_rgb_belnding.gdshader")
		if type == "outline":
			_material.shader = load("res://scenes/peekaboo/shaders/_outline.gdshader")
		if type == "fog":
			_material.shader = load("res://scenes/peekaboo/shaders/_fog.gdshader")
		if type == "chessboard":
			_material.shader = load("res://scenes/peekaboo/shaders/_chessboard.gdshader")
		if type == "shine":
			_material.shader = load("res://scenes/peekaboo/shaders/_shine.gdshader")
		if type == "function":
			_material.shader = load("res://scenes/peekaboo/shaders/_function.gdshader")
		if type == "creature_v1":
			_material.shader = load("res://scenes/peekaboo/shaders/_shader_creature_v1.gdshader")
			
		if not is_node_ready(): return
		# material = _material
		
		
		var shader = _material.shader
		if shader:
			var params = shader.get_shader_uniform_list()
			var has_noise = params.any(func(p): return p["name"] == "noise_tex")
			if has_noise:
				var noise = FastNoiseLite.new()
				noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
				noise.frequency = 0.001
				var noise_tex = NoiseTexture2D.new()
				noise_tex.noise = noise
				noise_tex.seamless = true
				noise_tex.width = 256
				noise_tex.height = 256
				_material.set_shader_parameter("noise_tex", noise_tex)
		
		
		
		%_material_anchor.material = _material
		
		
		# %Sprite2D.material = _material  # ← assign to the sprite, not self
		# %AnimatedSprite2D.material = _material  # ← assign to the sprite, not self

		
func _ready() -> void:
	# if get_tree().current_scene != self: %Camera2D.enabled = false
	
	atlas = AtlasTexture.new()
	%Sprite2D.texture = atlas
	
	%"Label Mark".text = mark
	
	# this step might be heavy and can be GPU optimised later on
	%AnimatedSprite2D.frame_changed.connect(_update_atlas)
	
	# sync atlas to whatever frame is current on load
	_update_atlas()
	_update_material()
	
func _update_atlas():
	var frame = %AnimatedSprite2D.frame
	var tex = %AnimatedSprite2D.sprite_frames.get_frame_texture(%AnimatedSprite2D.animation, frame)
	
	var source_image : Image
	var region : Rect2
	
	if tex is AtlasTexture:
		source_image = tex.atlas.get_image()
		region = tex.region
	else:
		source_image = tex.get_image()
		region = Rect2(Vector2.ZERO, tex.get_size())
	
	# extract just this frame's pixels into a brand new standalone texture
	# UV will now genuinely be 0→1 with no atlas behind it
	var cropped = source_image.get_region(Rect2i(region))
	%Sprite2D.texture = ImageTexture.create_from_image(cropped)
	
func _tween_material_progress(duration := 10.0):
	var tween = create_tween()
	tween.tween_method(
		func(v): $AnimatedSprite2D.material.set_shader_parameter("progress", v),
		0.0, 1.0, duration
	)
