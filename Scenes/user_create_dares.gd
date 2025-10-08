class_name UserCreateDares
extends Control

@onready var list: VBoxContainer = $ScrollContainer/DaresList
@onready var template_button: Button = $Button

# Панелът за изтриване и вътрешните му контроли
@onready var show_selected_dare_root: Control = $ShowSelectedDarePanel
@onready var show_selected_dare_panel: Panel = $ShowSelectedDarePanel/TextPanel
@onready var info_rich_label: RichTextLabel = $ShowSelectedDarePanel/TextPanel/InfoRichLabel
@onready var delete_button: Button = $ShowSelectedDarePanel/DeleteButton
@onready var back_button_delete_panel: Button = $ShowSelectedDarePanel/BackButton
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var show_number_label: Label = $ShowSelectedDarePanel/ShowNumberLabel

@onready var choice_panel: Panel = $ShowSelectedDarePanel/ChoicePanel
@onready var yes_button: Button = $ShowSelectedDarePanel/ChoicePanel/YesButton
@onready var no_button: Button = $ShowSelectedDarePanel/ChoicePanel/NoButton

# Панелът за добавяне и вътрешните му контроли
@onready var show_adding_dare_panel: Panel = $ShowAddingDarePanel
@onready var back_button_add_panel: Button = $ShowAddingDarePanel/BackButton
@onready var text_edit: TextEdit = $ShowAddingDarePanel/EnterTextPanel/TextEdit
@onready var add_button_add_panel: Button = $ShowAddingDarePanel/AddButton
@onready var error_show_label: Label = $ShowAddingDarePanel/ErrorShowLabel

var dares: Array[String] = [
	"Направи 10 лицеви опори Сегаааааа садсадададсд асд асд асдс асд ададасда ",
	"Изпей куплет от любима песен Сегаааааа садсадададсд асд асд асдс асд ададасда",
	"Направи смешно селфи Сегаааааа садсадададсд асд асд асдс асд ададасда",
]

var _pending_delete_text: String = ""
var _pending_delete_node: Button = null

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# растене на списъка
	$ScrollContainer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	$ScrollContainer.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.size_flags_vertical   = Control.SIZE_EXPAND_FILL

	# тънък вертикален скрол
	var vbar: VScrollBar = $ScrollContainer.get_v_scroll_bar()
	if vbar:
		vbar.add_theme_constant_override("thickness", 6)
		var normal = StyleBoxFlat.new();  normal.bg_color = Color(0,0,0,0)
		var hover  = StyleBoxFlat.new();  hover.bg_color  = Color(0,0,0,0.4)
		var press  = StyleBoxFlat.new();  press.bg_color  = Color(0,0,0,1)
		var track  = StyleBoxFlat.new();  track.bg_color  = Color(0,0,0,0)
		vbar.add_theme_stylebox_override("grabber", normal)
		vbar.add_theme_stylebox_override("grabber_highlight", hover)
		vbar.add_theme_stylebox_override("grabber_pressed", press)
		vbar.add_theme_stylebox_override("scroll", track)

	# шаблонният бутон не се показва сам
	template_button.visible = false

	# панелите са скрити по подразбиране
	show_selected_dare_root.visible = false
	show_adding_dare_panel.visible = false
	_clear_add_error()

	# Свързване: панел за изтриване
	yes_button.pressed.connect(_on_confirm_delete)
	back_button_delete_panel.pressed.connect(_hide_panel)

	# Свързване: панел за добавяне
	back_button_add_panel.pressed.connect(_hide_add_panel)
	add_button_add_panel.pressed.connect(_on_add_dare_pressed)

	_populate_list()


func _populate_list() -> void:
	for c in list.get_children():
		c.queue_free()

	var idx := 1
	for text in dares:
		var btn := _make_button(text, idx)
		list.add_child(btn)
		idx += 1


func _make_button(text: String, cur_index: int) -> Button:
	var btn := template_button.duplicate() as Button
	btn.visible = true
	btn.disabled = false
	btn.text = " %d. %s" % [cur_index, text]
	btn.focus_mode = Control.FOCUS_ALL
	btn.clip_text = true
	btn.pressed.connect(func(): _open_panel(text, btn))
	return btn


# ---------- Панел: изтриване ----------
func _open_panel(dare_text: String, node: Button) -> void:
	_pending_delete_text = dare_text
	_pending_delete_node = node

	var index := list.get_children().find(node) + 1
	show_number_label.text = "%d." % index

	info_rich_label.bbcode_enabled = false
	info_rich_label.text = dare_text
	_show_panel()

func _on_confirm_delete() -> void:
	choice_panel.visible = false
	if _pending_delete_text == "" or _pending_delete_node == null:
		_hide_panel()
		return

	dares.erase(_pending_delete_text)
	# rebuild -> коректна номерация
	_populate_list()

	_pending_delete_text = ""
	_pending_delete_node = null
	_hide_panel()

func _show_panel() -> void:
	animation_player.play("show_dare_panel")
	show_selected_dare_root.visible = true
	show_selected_dare_root.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(show_selected_dare_root, "modulate:a", 1.0, 0.15)

func _hide_panel() -> void:
	animation_player.play("hide_dare_panel")
	var tw = create_tween()
	tw.tween_property(show_selected_dare_root, "modulate:a", 0.0, 0.15)
	tw.tween_callback(Callable(show_selected_dare_root, "set_visible").bind(false))


# ---------- Панел: добавяне ----------
func _on_add_button_button_down() -> void:
	_show_add_panel()

func _show_add_panel() -> void:
	# reset полетата
	text_edit.text = ""
	_clear_add_error()

	# по желание: wrap и стил за удобен вход
	text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY

	show_adding_dare_panel.visible = true
	show_adding_dare_panel.modulate.a = 0.0
	animation_player.play("show_adding_dare_panel")
	var tw = create_tween()
	tw.tween_property(show_adding_dare_panel, "modulate:a", 1.0, 0.15)

func _hide_add_panel() -> void:
	animation_player.play("hide_adding_dare_panel")
	var tw = create_tween()
	tw.tween_property(show_adding_dare_panel, "modulate:a", 0.0, 0.15)
	tw.tween_callback(Callable(show_adding_dare_panel, "set_visible").bind(false))

func _on_add_dare_pressed() -> void:
	_clear_add_error()

	var raw := text_edit.text
	var val := raw.strip_edges()

	# валидации
	if val.is_empty():
		_set_add_error("Моля, въведи текст.")
		return
	if val.length() > 1024:
		_set_add_error("Текстът е твърде дълъг (макс. 1024 символа).")
		return

	# по желание: защита от дубли
	# if dares.has(val):
	# 	_set_add_error("Това предизвикателство вече съществува.")
	# 	return

	# добавяне в модела и обновяване на списъка
	dares.append(val)
	_populate_list()

	# (по желание) скрол до дъното, за да се види новият елемент
	#var vbar := $ScrollContainer.get_v_scroll_bar()
	#if vbar:
	#	await get_tree().process_frame
	#	vbar.value = vbar.max_value

	_hide_add_panel()


# ---------- Helpers (добавяне) ----------
func _set_add_error(msg: String) -> void:
	error_show_label.text = msg
	error_show_label.visible = true

func _clear_add_error() -> void:
	error_show_label.text = ""
	error_show_label.visible = false


func _on_delete_button_button_down() -> void:
	choice_panel.visible = true


func _on_no_button_button_down() -> void:
	choice_panel.visible = false
