class_name LevelController
extends Node2D

# Gnerall
@onready var prev_button: Button = $PrevButton
@onready var next_button: Button = $NextButton
@onready var back_button: Button = $BackButton
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var dares_rich_text_label: RichTextLabel = $QuestionPanel/DaresRichTextLabel
@onready var dare_type_panel: Panel = $QuestionPanel/DareTypePanel
@onready var exit_panel: Panel = $ExitPanel

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
@export var is_user_dare    : bool = false : set = _set_is_user

# Ако искаш да се разбъркват въпросите при зареждане
@export var shuffle_dares : bool = true

var players : Array[String] = []
var dares   : Array[String] = []   # въпросите за текущото ниво
var dare_index : int = -1          # индекс в dares

# --- ЧЕСТНА РОТАЦИЯ + ИСТОРИЯ ---
var pool: Array[String] = []       # текущ басейн от играчи за ротация
var history: Array[String] = []    # показани вече предизвикателства (след замяна)
var history_index: int = -1        # позиция в history (за Prev/Next навигация)
var history_need: Array[int] = []

const NEXT_ANIM : StringName = &"next_question"
const PREV_ANIM : StringName = &"prev_question"

func _ready() -> void:
	
	animation_player.play("opening_scene")
	
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
	
func _set_is_user(v: bool) -> void:
	is_user_dare = v
	_reload_level_dares()

func _selected_categories() -> Array[String]:
	var cats: Array[String] = []
	if is_classic_dare: cats.append("classic_dares")
	if is_extreme_dare: cats.append("extreme_dares")
	if is_sexy_dare:    cats.append("sexy_dares")
	if is_dirty_dare:   cats.append("dirty_dares")
	if is_user_dare:    cats.append("user_dares")
	return cats

func _reload_level_dares() -> void:
	# събира въпроси само от избраните категории
	var cats := _selected_categories()
	var combined: Array[String] = []

	if cats.is_empty():
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
	dare_index = -1
	# при ново зареждане — занули историята
	history.clear()
	history_index = -1
	history_need.clear()

# ---------- ЛОГИКА ЗА РОТАЦИЯ И ПРЕДИЗВИКАТЕЛСТВА ----------
func _reset_pool() -> void:
	pool = players.duplicate()
	pool.shuffle()

# 1) За колко играча е нужно (намира _1, _2, _3...)
func _dare_required_indices(text: String) -> Array[int]:
	var re := RegEx.new()
	re.compile("_(\\d+)")
	var uniq := {}
	for m in re.search_all(text):
		var idx := int(m.get_string(1))
		uniq[idx] = true
	var out: Array[int] = []
	for k in uniq.keys():
		out.append(int(k))
	out.sort()
	return out

func _dare_required_count(text: String) -> int:
	return _dare_required_indices(text).size()

# 2) Замяна на _1, _2, ... с подадени имена
func _replace_placeholders(text: String, selected: Array[String]) -> String:
	var indices := _dare_required_indices(text)
	indices.reverse() # заменяме от по-големите към по-малките (_10 преди _1)
	var out := text
	for i in indices:
		var pos := i - 1
		if pos >= 0 and pos < selected.size():
			out = out.replace("_%d" % i, selected[pos])
	return out

# 3) Може ли да се изпълни с наличния басейн (или е обща карта)?
func _can_execute_with_pool(text: String) -> bool:
	var need := _dare_required_count(text)
	return need == 0 or need <= pool.size()

# Взима n играча от басейна; ако се изпразни — ресет
func _take_from_pool(n: int) -> Array[String]:
	var picked: Array[String] = []
	var k: int = min(n, pool.size())
	for i in k:
		picked.append(pool[0])
		pool.remove_at(0)
	if pool.is_empty():
		_reset_pool()
	return picked

# Избира следващо „играемо“ предизвикателство спрямо басейна (прескача невъзможните)
# Връща {"raw": String, "render": String, "players": Array[String]} или {} ако няма валидно
func _next_playable_dare(_after_reset := false) -> Dictionary:
	if dares.is_empty():
		return {}
	var scanned := 0
	while scanned < dares.size():
		dare_index = (dare_index + 1) % dares.size()
		var raw := dares[dare_index]
		var need := _dare_required_count(raw)
		if need == 0:
			var render0 := _replace_placeholders(raw, [])
			return {"raw": raw, "render": render0, "players": []}
		if need <= pool.size():
			var picked := _take_from_pool(need)
			var render := _replace_placeholders(raw, picked)
			return {"raw": raw, "render": render, "players": picked}
		scanned += 1
	# Ако с текущия басейн няма валидно, опитай след ресет веднъж
	if not _after_reset and not players.is_empty():
		_reset_pool()
		return _next_playable_dare(true)
	return {}

# ---------- БУТОНИ/АНИМАЦИИ ----------
func _on_next_pressed() -> void:
	if not animation_player.has_animation(NEXT_ANIM):
		push_warning("Animation '%s' not found." % NEXT_ANIM)
		return
	_set_buttons_disabled(true)
	animation_player.play(NEXT_ANIM)

	var txt := ""
	# ако сме навигирали назад, ходи напред в историята без да генерираш ново
	if history_index < history.size() - 1:
		history_index += 1
		txt = history[history_index]
		dare_type_panel.visible = (history_index < history_need.size() and history_need[history_index] == 0)

	else:
		var entry := _next_playable_dare()
		if entry.is_empty():
			txt = "[i]Няма валидни предизвикателства за текущите играчи.[/i]"
			dare_type_panel.visible = false
		else:
			txt = String(entry["render"])
			var raw: String = String(entry["raw"])
			var need: int = _dare_required_count(raw)

			history.append(txt)
			history_need.append(need)
			history_index = history.size() - 1
			dare_type_panel.visible = (need == 0)



	dares_rich_text_label.set_text_smart(txt)

	await animation_player.animation_finished
	_set_buttons_disabled(false)

func _on_prev_pressed() -> void:
	if not animation_player.has_animation(PREV_ANIM):
		push_warning("Animation '%s' not found." % PREV_ANIM)
		return
	_set_buttons_disabled(true)
	animation_player.play(PREV_ANIM)

	var txt := ""
	if history.is_empty():
		txt = "[i]Няма предишни предизвикателства.[/i]"
		dare_type_panel.visible = false

	else:
		history_index = max(0, history_index - 1)
		txt = history[history_index]
		dare_type_panel.visible = (history_index < history_need.size() and history_need[history_index] == 0)

	dares_rich_text_label.set_text_smart(txt)

	await animation_player.animation_finished
	_set_buttons_disabled(false)

func _set_buttons_disabled(disabled: bool) -> void:
	prev_button.disabled = disabled
	next_button.disabled = disabled
	back_button.disabled = disabled

# ---------- ИГРАЧИ ----------
func _on_add_pressed() -> void:
	animation_player.play("LineEdit_glow")
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

	# инициализирай ротацията и историята
	_reset_pool()
	if shuffle_dares:
		dares.shuffle()
	history.clear()
	history_index = -1
	dare_index = -1

	# покажи първото валидно предизвикателство веднага
	var entry := _next_playable_dare()
	var txt: String = String(entry.get("render", "[i]Няма валидни предизвикателства.[/i]"))
	dares_rich_text_label.set_text_smart(txt)
	
	var raw0: String = String(entry.get("raw", ""))
	var need0: int = _dare_required_count(raw0)
	dare_type_panel.visible = (need0 == 0)
	
	history.append(txt)
	history_need.append(need0)
	history_index = history.size() - 1
	
	
	

func _on_stay_button_button_down() -> void:
	exit_panel.visible = false

func _on_back_button_button_down() -> void:
	exit_panel.visible = true

func _on_exit_button_button_down() -> void:
	play_anim_then_change_scene(animation_player, &"back_to_main", "res://Scenes/main_scene.tscn")
	exit_panel.visible = false
	
	
	
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
