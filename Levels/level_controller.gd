class_name LevelController
extends Node2D

@onready var prev_button: Button = $PrevButton
@onready var next_button: Button = $NextButton
@onready var back_button: Button = $BackButton
@onready var animation_player: AnimationPlayer = $AnimationPlayer

const NEXT_ANIM : StringName = &"next_question"
const PREV_ANIM : StringName = &"prev_question"

func _ready() -> void:
	next_button.pressed.connect(_on_next_pressed)
	prev_button.pressed.connect(_on_prev_pressed)


func _on_next_pressed() -> void:
	if not animation_player.has_animation(NEXT_ANIM):
		push_warning("Animation '%s' not found." % NEXT_ANIM)
		return

	_set_buttons_disabled(true)
	animation_player.play(NEXT_ANIM)

	# изчакай да приключи анимацията (Godot 4):
	await animation_player.animation_finished

	_set_buttons_disabled(false)


func _on_prev_pressed() -> void:
	if not animation_player.has_animation(PREV_ANIM):
		push_warning("Animation '%s' not found." % PREV_ANIM)
		return

	_set_buttons_disabled(true)
	animation_player.play(PREV_ANIM)

	# изчакай да приключи анимацията (Godot 4):
	await animation_player.animation_finished

	_set_buttons_disabled(false)


func _set_buttons_disabled(disabled: bool) -> void:
	prev_button.disabled = disabled
	next_button.disabled = disabled
	back_button.disabled = disabled
