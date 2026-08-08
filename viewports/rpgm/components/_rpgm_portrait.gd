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
		# CLAUDE: not every portrait scene has an AnimationTree — a bare
		# %AnimationTree lookup logs "Node not found" on those, so probe with
		# get_node_or_null; likewise only play "actioned" if it exists, which
		# raised 'p_animation_library.is_null()' on scenes without it
		var tree := get_node_or_null("%AnimationTree")
		if tree:
			tree.set("parameters/BlendSpace2D/blend_position", facing)
			var player : AnimationPlayer = get_node_or_null("%AnimationPlayer")
			if player and player.has_animation("actioned"):
				player.stop()
				player.play("actioned")



var sprite : String = "cream":
	set(v):
		sprite = v
		if not is_node_ready(): return
		if %_sampler == null: return
		%_sampler.animation = sprite
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
	if not is_node_ready(): return ["null"]
	var sprite_node =  %_sampler
	if sprite_node and sprite_node.sprite_frames:
		return Array(sprite_node.sprite_frames.get_animation_names())
	return ["None"]
	
func _update_material():
		_material = ShaderMaterial.new() as ShaderMaterial
		if type == "highlight":
			_material.shader = load("res://viewports/rpgm/shaders/_highlight.gdshader")
		if type == "evaporate":
			_material.shader = load("res://viewports/rpgm/shaders/_evaporate.gdshader")
		if type == "ghost":
			_material.shader = load("res://viewports/rpgm/shaders/_ghost.gdshader")
		if type == "random":
			_material.shader = load("res://viewports/rpgm/shaders/_random.gdshader")
		if type == "wiggle":
			_material.shader = load("res://viewports/rpgm/shaders/_wiggle.gdshader")
		if type == "sphere":
			_material.shader = load("res://viewports/rpgm/shaders/_sphere_and_correct_rgb_belnding.gdshader")
		if type == "outline":
			_material.shader = load("res://viewports/rpgm/shaders/_outline.gdshader")
		if type == "fog":
			_material.shader = load("res://viewports/rpgm/shaders/_fog.gdshader")
		if type == "chessboard":
			_material.shader = load("res://viewports/rpgm/shaders/_chessboard.gdshader")
		if type == "shine":
			_material.shader = load("res://viewports/rpgm/shaders/_shine.gdshader")
		if type == "function":
			_material.shader = load("res://viewports/rpgm/shaders/_function.gdshader")
		if type == "creature_v1":
			_material.shader = load("res://viewports/rpgm/shaders/_shader_creature_v1.gdshader")
			
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
	%_sampler.frame_changed.connect(_update_atlas)
	
	# CLAUDE: apply the stored sprite before the first sync — scene files assign
	# properties pre-ready, so the sprite setter's is_node_ready() guard drops them
	%_sampler.animation = sprite

	# sync atlas to whatever frame is current on load
	_update_atlas()
	_update_material()
	
# frames extracted once, shared by every portrait using the same sprite_frames
static var _frame_cache : Dictionary = {}

func _update_atlas():
	var frames : SpriteFrames = %_sampler.sprite_frames
	var anim = %_sampler.animation
	var frame = %_sampler.frame
	var key := "%d/%s/%d" % [frames.get_instance_id(), anim, frame]

	if not _frame_cache.has(key):
		var tex = frames.get_frame_texture(anim, frame)

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
		_frame_cache[key] = ImageTexture.create_from_image(cropped)

	%Sprite2D.texture = _frame_cache[key]
	
func _tween_material_progress(duration := 10.0):
	var tween = create_tween()
	tween.tween_method(
		func(v): $_sampler.material.set_shader_parameter("progress", v),
		0.0, 1.0, duration
	)
