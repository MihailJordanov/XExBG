class_name LevelController
extends Node2D

# Gnerall
@onready var prev_button: Button = $PrevButton
@onready var next_button: Button = $NextButton
@onready var back_button: Button = $BackButton
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Enter Player Pantel
@onready var line_edit: LineEdit = $EnterPlayerPanel/LineEdit
@onready var rich_text_label: RichTextLabel = $EnterPlayerPanel/RichTextLabel
@onready var add_player_button: Button = $EnterPlayerPanel/AddPlayerButton
@onready var error_label: RichTextLabel = $EnterPlayerPanel/ErrorLabel

var players : Array[String] = []

const NEXT_ANIM : StringName = &"next_question"
const PREV_ANIM : StringName = &"prev_question"

func _ready() -> void:
	next_button.pressed.connect(_on_next_pressed)
	prev_button.pressed.connect(_on_prev_pressed)
	add_player_button.pressed.connect(_on_add_pressed)
	line_edit.text_submitted.connect(_on_text_submitted)


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


func _on_add_pressed() -> void:
	_add_current_player()
	
func _on_text_submitted(_text: String) -> void:
	_add_current_player()


func _add_current_player() -> void:
	var name := line_edit.text.strip_edges()
	if name.is_empty():
		return
		
	var L := name.length()
	
	
	# Валидация: 1..15 символа
	if L < 1:
		_show_error("[color=#ff4d4d][b]Името е твърде кратко (мин. 1 символ).[/b][/color]")
		return
		
	if L > 15:
		_show_error("[color=#ff4d4d][b]Името е твърде дълго: %d/15[/b][/color]" % L)
		return
		
	if name in players:
		_show_error("[color=#00bfff][b]Този играч вече е добавен.[/b][/color]")
		return
	
	if players.size() >= 30:
		_show_error("[color=#ff4d4d][b]Списъкът е пълен (макс 30).[/b][/color]")
		return

		
	_hide_error()
	players.append(name)
	line_edit.clear()
	_render_players()
	
func _render_players() -> void:
	var bb := ""
	for i in players.size():
		var player := players[i]

		bb += "%d. [b]%s[/b]\n" % [i + 1, player]
	rich_text_label.bbcode_text = bb
	
	
func _show_error(msg: String) -> void:
	error_label.visible = true
	error_label.bbcode_text = msg


func _hide_error() -> void:
	error_label.visible = false
	
	
	
	
	
	
	
	
	
