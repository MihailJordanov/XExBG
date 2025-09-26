class_name AddingDares extends Node2D


@onready var enter_new_dare_line_edit: LineEdit = $EnterPlayerPanel/EnterNewDareLineEdit
@onready var id_line_edit: LineEdit = $EnterPlayerPanel/IDLineEdit
@onready var show_dares_label: RichTextLabel = $EnterPlayerPanel/ShowDaresLabel
@onready var error_label: RichTextLabel = $EnterPlayerPanel/ErrorLabel
@onready var add_dare_button: Button = $EnterPlayerPanel/AddDareButton
@onready var save_button: Button = $EnterPlayerPanel/SaveButton
@onready var load_button: Button = $EnterPlayerPanel/LoadButton
@onready var delete_button: Button = $EnterPlayerPanel/DeleteButton

@onready var category_option_button: OptionButton = $EnterPlayerPanel/CategoryOptionButton
@onready var sub_option_button: OptionButton = $EnterPlayerPanel/SubOptionButton


const CATEGORY_MAP := {
	"classic": "classic_dares",
	"extreme": "extreme_dares",
	"sexy":    "sexy_dares",
	"dirty":   "dirty_dares",
}
const SUB_MAP := {
	"one":   "daresOne",
	"two":   "daresTwo",
	"three": "daresThree",
	"four":  "daresFour",
	"all":   "daresAll",
}

func _ready() -> void:
	_handing_with_popup()
	show_dares_label.bbcode_enabled = true
	error_label.bbcode_enabled = true
	error_label.visible = false

	load_button.pressed.connect(_on_load_pressed)
	save_button.pressed.connect(_on_save_pressed)
	add_dare_button.pressed.connect(_on_add_pressed)
	delete_button.pressed.connect(_on_delete_pressed)

func _on_load_pressed() -> void:
	var cat_key := _get_selected_category_key()
	var sub_key := _get_selected_sub_key()
	if cat_key.is_empty() or sub_key.is_empty():
		return _show_error("[b]Моля, избери категория и тип.[/b]")

	DareManager.load_dares()
	var arr := DareManager.get_category_list(cat_key, sub_key)
	_render_list(arr)
	_hide_error()

func _on_save_pressed() -> void:
	if DareManager.save_dares():
		_show_info("[color=#00ff88]Записът е успешен.[/color]")
	else:
		_show_error("[b]Грешка при запис.[/b]")

func _on_add_pressed() -> void:
	var cat_key := _get_selected_category_key()
	var sub_key := _get_selected_sub_key()
	if cat_key.is_empty() or sub_key.is_empty():
		return _show_error("[b]Моля, избери категория и тип.[/b]")

	if sub_key == "daresAll":
		return _show_error("Не можеш да добавяш директно в [b]All[/b]. Избери one/two/three/four.")

	var text := enter_new_dare_line_edit.text.strip_edges()
	if text.is_empty():
		return _show_error("Полето за ново dare е празно.")
	if text.length() > 120:
		return _show_error("Текстът е твърде дълъг (макс 120).")

	DareManager.add_dare(cat_key, sub_key, text)
	DareManager.save_dares()
	enter_new_dare_line_edit.clear()

	# Презареди текущия списък (показвай избрания подсписък):
	var arr := DareManager.get_category_list(cat_key, sub_key)
	_render_list(arr)
	_hide_error()

func _on_delete_pressed() -> void:
	var cat_key := _get_selected_category_key()
	var sub_key := _get_selected_sub_key()
	if cat_key.is_empty() or sub_key.is_empty():
		return _show_error("[b]Моля, избери категория и тип.[/b]")

	var id_text := id_line_edit.text.strip_edges()
	if not id_text.is_valid_int():
		return _show_error("ID трябва да е число (индекс).")
	var idx := int(id_text)

	# Вземи текущия видим списък
	var arr := DareManager.get_category_list(cat_key, sub_key, false) # вземи референция за скорост
	if idx < 0 or idx >= arr.size():
		return _show_error("Невалиден индекс: %d" % idx)

	var value := String(arr[idx])

	# Ако трием от "all" – махни стойността от всички 4 подсписъка
	if sub_key == "daresAll":
		for k in ["daresOne","daresTwo","daresThree","daresFour"]:
			DareManager.remove_dare(cat_key, k, value)
	else:
		DareManager.remove_dare(cat_key, sub_key, value)

	DareManager.save_dares()
	# Пререндни според избрания подсписък
	var refreshed := DareManager.get_category_list(cat_key, sub_key)
	_render_list(refreshed)
	_hide_error()
	id_line_edit.clear()

# ---------- UI helpers ----------
func _render_list(arr: Array[String]) -> void:
	var bb := ""
	for i in arr.size():
		# Номерация по ИНДЕКС (0,1,2,...) + по желание wave ефект:
		# bb += "%d. [wave amp=28 freq=2]%s[/wave]\n" % [i, arr[i]]
		bb += "%d. %s\n" % [i, arr[i]]
	show_dares_label.text = bb   

func _get_selected_category_key() -> String:
	var idx := category_option_button.selected
	if idx < 0: return ""
	var txt := category_option_button.get_item_text(idx).strip_edges().to_lower()
	return CATEGORY_MAP.get(txt, "")

func _get_selected_sub_key() -> String:
	var idx := sub_option_button.selected
	if idx < 0: return ""
	var txt := sub_option_button.get_item_text(idx).strip_edges().to_lower()
	return SUB_MAP.get(txt, "")

func _show_error(msg: String) -> void:
	error_label.visible = true
	error_label.text = "[color=#ff4d4d]" + msg + "[/color]"

func _show_info(msg: String) -> void:
	error_label.visible = true
	error_label.text = msg

func _hide_error() -> void:
	error_label.visible = false
	error_label.text = ""


	
func _handing_with_popup() -> void:
	var p1 := category_option_button.get_popup()              # това е падащото меню (PopupMenu)
	p1.add_theme_font_size_override("font_size", 12)           # по-малък шрифт
	p1.add_theme_constant_override("item_start_padding", 4)    # ляв padding
	p1.add_theme_constant_override("item_end_padding", 4)      # десен padding
	p1.add_theme_constant_override("h_separation", 4)          # хор. разстояние
	p1.add_theme_constant_override("v_separation", 2)          # верт. разстояние
	# По желание: по-тънък панел
	var panel1 := StyleBoxFlat.new()
	panel1.content_margin_left  = 2
	panel1.content_margin_right = 2
	panel1.content_margin_top   = 2
	panel1.content_margin_bottom= 2

	
	var p2 := sub_option_button.get_popup()              # това е падащото меню (PopupMenu)
	p2.add_theme_font_size_override("font_size", 12)           # по-малък шрифт
	p2.add_theme_constant_override("item_start_padding", 4)    # ляв padding
	p2.add_theme_constant_override("item_end_padding", 4)      # десен padding
	p2.add_theme_constant_override("h_separation", 4)          # хор. разстояние
	p2.add_theme_constant_override("v_separation", 2)          # верт. разстояние
	# По желание: по-тънък панел
	var panel2 := StyleBoxFlat.new()
	panel2.content_margin_left  = 2
	panel2.content_margin_right = 2
	panel2.content_margin_top   = 2
	panel2.content_margin_bottom= 2
