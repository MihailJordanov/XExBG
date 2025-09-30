class_name LevelController
extends Node2D

# Gnerall
@onready var prev_button: Button = $PrevButton
@onready var next_button: Button = $NextButton
@onready var back_button: Button = $BackButton
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var dares_rich_text_label: RichTextLabel = $QuestionPanel/DaresRichTextLabel

# Enter Player Panel
@onready var line_edit: LineEdit = $EnterPlayerPanel/LineEdit
@onready var rich_text_label: RichTextLabel = $EnterPlayerPanel/RichTextLabel
@onready var add_player_button: Button = $EnterPlayerPanel/AddPlayerButton
@onready var error_label: RichTextLabel = $EnterPlayerPanel/ErrorLabel
@onready var start_game_button: Button = $EnterPlayerPanel/StartGameButton
@onready var enter_player_panel: Panel = $EnterPlayerPanel

# --- Избор на категории за това ниво ---
@export var is_classic_dare : bool = true  : set = _set_is_classic
@export var is_extreme_dare : bool = false : set = _set_is_extreme
@export var is_sexy_dare    : bool = false : set = _set_is_sexy
@export var is_dirty_dare   : bool = false : set = _set_is_dirty

# Ако искаш да се разбъркват въпросите при зареждане
@export var shuffle_dares : bool = true

var players : Array[String] = []
var dares   : Array[String] = []   # <-- тук са въпросите за текущото ниво
var dare_index : int = -1          # текущ индекс в даres

const NEXT_ANIM : StringName = &"next_question"
const PREV_ANIM : StringName = &"prev_question"

func _ready() -> void:
	next_button.pressed.connect(_on_next_pressed)
	prev_button.pressed.connect(_on_prev_pressed)
	add_player_button.pressed.connect(_on_add_pressed)
	line_edit.text_submitted.connect(_on_text_submitted)
	start_game_button.pressed.connect(_on_start_game_pressed)

	_reload_level_dares()

# ---------- КАТЕГОРИИ / ЗАРЕЖДАНЕ НА ВЪПРОСИ ----------
func _set_is_classic(v: bool) -> void:
	is_classic_dare = v
	_reload_level_dares()

func _set_is_extreme(v: bool) -> void:
	is_extreme_dare = v
	_reload_level_dares()

func _set_is_sexy(v: bool) -> void:
	is_sexy_dare = v
	_reload_level_dares()

func _set_is_dirty(v: bool) -> void:
	is_dirty_dare = v
	_reload_level_dares()

func _selected_categories() -> Array[String]:
	var cats: Array[String] = []
	if is_classic_dare: cats.append("classic_dares")
	if is_extreme_dare: cats.append("extreme_dares")
	if is_sexy_dare:    cats.append("sexy_dares")
	if is_dirty_dare:   cats.append("dirty_dares")
	return cats

func _reload_level_dares() -> void:
	# събира въпроси само от избраните категории
	var cats := _selected_categories()
	var combined: Array[String] = []

	if cats.is_empty():
		# ако нищо не е избрано – оставяме празно и предупреждаваме в конзолата
		push_warning("Няма избрани категории за това ниво. Избери поне една.")
		dares = []
		dare_index = -1
		return

	for c in cats:
		var arr := DareManager.get_dares(c, true) # дублира масива за безопасност
		for v in arr:
			var s := String(v)
			if not combined.has(s):
				combined.append(s)

	if shuffle_dares:
		combined.shuffle()

	dares = combined
	dare_index = -1  # започваме отначало

# Връща следващ въпрос; ако стигнем края – въртим отначало
func get_next_dare() -> String:
	if dares.is_empty():
		return ""
	dare_index = (dare_index + 1) % dares.size()
	return dares[dare_index]

# Връща предишен въпрос (с въртене в обратна посока)
func get_prev_dare() -> String:
	if dares.is_empty():
		return ""
	dare_index = (dare_index - 1 + dares.size()) % dares.size()
	return dares[dare_index]

# ---------- БУТОНИ/АНИМАЦИИ ----------
func _on_next_pressed() -> void:
	if not animation_player.has_animation(NEXT_ANIM):
		push_warning("Animation '%s' not found." % NEXT_ANIM)
		return
	_set_buttons_disabled(true)
	animation_player.play(NEXT_ANIM)

	var q := get_next_dare()
	if q.is_empty():
		q = "[i]Няма достъпни въпроси. Провери избраните категории или сейва.[/i]"
	dares_rich_text_label.set_text_smart(q)  

	await animation_player.animation_finished
	_set_buttons_disabled(false)


func _on_prev_pressed() -> void:
	if not animation_player.has_animation(PREV_ANIM):
		push_warning("Animation '%s' not found." % PREV_ANIM)
		return
	_set_buttons_disabled(true)
	animation_player.play(PREV_ANIM)

	var q := get_prev_dare()
	if q.is_empty():
		q = "[i]Няма достъпни въпроси. Провери избраните категории или сейва.[/i]"
	dares_rich_text_label.set_text_smart(q)

	await animation_player.animation_finished
	_set_buttons_disabled(false)



func _set_buttons_disabled(disabled: bool) -> void:
	prev_button.disabled = disabled
	next_button.disabled = disabled
	back_button.disabled = disabled

# ---------- ИГРАЧИ ----------
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
	rich_text_label.text = bb

func _show_error(msg: String) -> void:
	error_label.visible = true
	error_label.text = msg

func _hide_error() -> void:
	error_label.visible = false
	
func _on_start_game_pressed() -> void:
	if players.size() < 2:
		_show_error("[color=#ff4d4d][b]Нужни са поне двама играчи, за да стартирате.[/b][/color]")
		return

	_hide_error()

	enter_player_panel.hide()
