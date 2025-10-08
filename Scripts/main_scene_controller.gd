class_name MainSceneController extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var classic_button: Button = $ScrollContainer/GridContainer/Classic
@onready var warning_panel: Panel = $WarningPanel
@onready var user_dares_choice_panel: Panel = $UserDaresChoicePanel
@onready var user_dares_button: Button = $ScrollContainer/GridContainer/UserDares

# UserDaresChoicePanel
@onready var user_dare_play_button: Button = $UserDaresChoicePanel/VBoxContainer/Play
@onready var user_dare_error_label: Label = $UserDaresChoicePanel/ErrorLabel



func _ready() -> void:
	animation_player.play("opening_scene")
	if DareManager.is_warning_ready:
		warning_panel.visible = false
		
	user_dare_error_label.visible = false
	

# Пусни анимация -> изчакай края -> смени сцената
func play_anim_then_change_scene(anim_player: AnimationPlayer, anim: StringName, scene: Variant) -> void:
	if anim_player and anim_player.has_animation(anim):
		anim_player.play(anim)
		var finished: StringName = await anim_player.animation_finished
		# по желание: гаранция, че чакахме точната анимация
		if finished != anim:
			push_warning("Different animation finished: %s" % finished)
	else:
		push_warning("Animation '%s' not found; switching immediately." % anim)

	if typeof(scene) == TYPE_STRING:
		get_tree().change_scene_to_file(String(scene))            # "res://path/to_scene.tscn"
	elif typeof(scene) == TYPE_OBJECT and scene is PackedScene:
		get_tree().change_scene_to_packed(scene as PackedScene)   # ако подадеш PackedScene
	else:
		push_error("Invalid scene argument (use path String or PackedScene).")




func _on_classic_button_down() -> void:
	play_anim_then_change_scene(animation_player, &"start_classic", "res://Scenes/classic_level_01.tscn")


func _on_extreme_button_down() -> void:
	play_anim_then_change_scene(animation_player, &"start_classic", "res://Scenes/extreme_level_01.tscn")


func _on_sexy_button_down() -> void:
	play_anim_then_change_scene(animation_player, &"start_classic", "res://Scenes/sexy_level_01.tscn")
	

func _on_dirty_button_down() -> void:
	play_anim_then_change_scene(animation_player, &"start_dirty", "res://Scenes/dirty_level_01.tscn")


func _on_create_button_down() -> void:
	play_anim_then_change_scene(animation_player, &"start_classic", "res://Scenes/user_create_dares.tscn")

func _on_play_button_down() -> void:
	var v := _validate_user_dares()

	# Твърдо изискване: трябва да има поне едно с _1
	if not v.has_one:
		user_dare_error_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
		user_dare_error_label.text = "Нужно е поне едно предизвикателство\nс _1 (име на играч) в него."
		user_dare_error_label.visible = true
		return
	else:
		user_dare_error_label.visible = false

	# Всичко е ок -> стартирай сцената
	play_anim_then_change_scene(animation_player, &"start_classic", "res://Scenes/user_dares.tscn")

func _on_play_button_button_down() -> void:
	DareManager.is_warning_ready = true
	warning_panel.visible = false


func _on_user_dares_button_down() -> void:
	user_dares_choice_panel.visible = true
	_update_user_dares_hint()


func _on_close_button_user_dares_choice_panel_down() -> void:
	user_dares_choice_panel.visible = false


func _validate_user_dares() -> Dictionary:
	var dares: Array[String] = DareManager.get_dares("user_dares")
	var has_one := false
	var has_pair := false

	for d in dares:
		var s := String(d)
		var has1 := s.find("_1") != -1
		var has2 := s.find("_2") != -1
		if has1:
			has_one = true
		if has1 and has2:
			has_pair = true
		# micro-оптимизация: ако вече имаме и двете, прекъсваме
		if has_one and has_pair:
			break

	return {
		"count": dares.size(),
		"has_one": has_one,   # има поне едно с _1
		"has_pair": has_pair  # има поне едно с _1 и _2
	}

func _update_user_dares_hint() -> void:
	var v := _validate_user_dares()
	if v.count == 0:
		user_dare_error_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3))
		user_dare_error_label.text = "Няма добавени предизвикателства.\nСъздай поне едно с _1."
		user_dare_error_label.visible = true
	elif not v.has_one:
		user_dare_error_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3))
		user_dare_error_label.text = "Нужно е поне едно предизвикателство\nс _1 (име на играч) в него."
		user_dare_error_label.visible = true
	elif not v.has_pair:
		user_dare_error_label.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0)) # неоново синьо
		user_dare_error_label.text = "По избор: добави и предизвикателство\nс _1 и _2 за 2+ играчи."
		user_dare_error_label.visible = true
	else:
		user_dare_error_label.visible = false
