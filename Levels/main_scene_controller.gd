class_name MainSceneController extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var classic_button: Button = $ScrollContainer/GridContainer/Classic
@onready var warning_panel: Panel = $WarningPanel

func _ready() -> void:
	if DareManager.is_warning_ready:
		warning_panel.visible = false

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
	play_anim_then_change_scene(animation_player, &"start_classic", "res://Levels/classic_level_01.tscn")


func _on_extreme_button_down() -> void:
	play_anim_then_change_scene(animation_player, &"start_classic", "res://Levels/extreme_level_01.tscn")


func _on_sexy_button_down() -> void:
	play_anim_then_change_scene(animation_player, &"start_classic", "res://Levels/sexy_level_01.tscn")
	

func _on_dirty_button_down() -> void:
	play_anim_then_change_scene(animation_player, &"start_dirty", "res://Levels/dirty_level_01.tscn")


func _on_play_button_button_down() -> void:
	DareManager.is_warning_ready = true
	warning_panel.visible = false
