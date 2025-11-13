extends Control

@export var is_spin: bool = false
@export var speed: int = 10
@export var power: int = 2
@export var reward_position = 0

@onready var front: TextureRect = $background/front
@onready var info_rich_text_label: RichTextLabel = $InfoPanel/InfoRichTextLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var is_more_games_panel_show : bool = false


var vat_pham = [
	{
		"name": "Dark blue",
		"from": 0,
		"to": 45,
		"text": "Една глътка"
	},
	{
		"name": "Dark green",
		"from": 45,
		"to": 90,
		"text": "Върти пак"
	},
	{
		"name": "Blue",
		"from": 90,
		"to": 135,
		"text": "Довършваш напитката си"
	},
	{
		"name": "Yellow",
		"from": 135,
		"to": 180,
		"text": "Не пиеш"
	},
	{
		"name": "Purple",
		"from": 180,
		"to": 225,
		"text": "Три глътки"
	},
	{
		"name": "Green",
		"from": 225,
		"to": 270,
		"text": "Една глътка"
	},
	{
		"name": "Orange",
		"from": 270,
		"to": 315,
		"text": "Пиеш шот"
	},
	{
		"name": "Pink",
		"from": 315,
		"to": 360,
		"text": "Въртиш два пъти"
	}
	]
	

var selected_item: Dictionary = {}

func _ready() -> void:
	animation_player.play("opening_scene")

func _on_button_button_down() -> void:
	if is_spin:
		return
		
	if animation_player.is_playing():
		return

	animation_player.play("hide_info")
	is_spin = true

	var tween := get_tree().create_tween().set_parallel(true)
	tween.finished.connect(func ():
		var old_rotation: float = front.rotation_degrees
		is_spin = false

		if old_rotation > 360:
			var rad := fmod(old_rotation, 360)
			front.rotation_degrees = rad

		# ❗ Показваме info чак след като въртенето свърши
		if selected_item:
			info_rich_text_label.text = selected_item.text
			animation_player.play("show_info")
	)

	# Случайна позиция
	reward_position = randi_range(0, 360)

	# Намираме наградата, но НЕ показваме още информацията
	for item in vat_pham:
		if reward_position >= item.from - 22.5 and reward_position <= item.to - 22.5:
			selected_item = item
			print(item.name)

	var final_rotation : float = reward_position + 360.0 * speed * power

	var track = tween.tween_property(
		front,
		"rotation_degrees",
		final_rotation,
		3.0
	)

	if track == null:
		push_error("❗ tween_property върна NULL – провери front или rotation_degrees")
	else:
		track.set_ease(Tween.EASE_IN_OUT)
		track.set_trans(Tween.TRANS_CIRC)


func play_anim_then_change_scene(anim_player: AnimationPlayer, anim: StringName, scene: Variant) -> void:
	if anim_player and anim_player.has_animation(anim):
		anim_player.play(anim)
		var finished: StringName = await anim_player.animation_finished
		if finished != anim:
			push_warning("Different animation finished: %s" % finished)
	else:
		push_warning("Animation '%s' not found; switching immediately." % anim)

	if typeof(scene) == TYPE_STRING:
		get_tree().change_scene_to_file(String(scene))            
	elif typeof(scene) == TYPE_OBJECT and scene is PackedScene:
		get_tree().change_scene_to_packed(scene as PackedScene)   
	else:
		push_error("Invalid scene argument (use path String or PackedScene).")



func _on_show_button_button_down() -> void:
	if !is_more_games_panel_show:
		animation_player.play("show_more_games_panel")
		is_more_games_panel_show = true
	else:
		animation_player.play("hide_more_games_panel")
		is_more_games_panel_show = false


func _on_wheel_button_button_down() -> void:
	if !is_more_games_panel_show:
		animation_player.play("show_more_games_panel")
		is_more_games_panel_show = true
	else:
		animation_player.play("hide_more_games_panel")
		is_more_games_panel_show = false


func _on_dares_button_button_down() -> void:
	play_anim_then_change_scene(animation_player, &"start_classic", "res://Scenes/main_scene.tscn")


func _on_truths_button_button_down() -> void:
	play_anim_then_change_scene(animation_player, &"start_classic", "res://Scenes/main_scene_truths.tscn")
