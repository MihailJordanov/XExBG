class_name UserCreateDares
extends Control

@onready var list: VBoxContainer = $ScrollContainer/DaresList
@onready var template_button: Button = $Button

# Панелът и вътрешните му контроли
@onready var show_selected_dare_root: Control = $ShowSelectedDarePanel      # контейнерът (може да е Control/Panel)
@onready var show_selected_dare_panel: Panel = $ShowSelectedDarePanel/TextPanel
@onready var info_rich_label: RichTextLabel = $ShowSelectedDarePanel/TextPanel/InfoRichLabel
@onready var delete_button: Button = $ShowSelectedDarePanel/DeleteButton
@onready var back_button: Button = $ShowSelectedDarePanel/BackButton
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var show_number_label: Label = $ShowSelectedDarePanel/ShowNumberLabel



var dares: Array[String] = [
	"Направи 10 лицеви опори Сегаааааа садсадададсд асд асд асдс асд ададасда ",
	"Изпей куплет от любима песен Сегаааааа садсадададсд асд асд асдс асд ададасда",
	"Направи смешно селфи Сегаааааа садсадададсд асд асд асдс асд ададасда",
	"Направи 10 лицеви опори Сегаааааа садсадададсд асд асд асдс асд ададасда",
	"Изпей куплет от любима песен Сегаааааа садсадададсд асд асд асдс асд ададасда",
	"Направи смешно селфи Сегаааааа садсадададсд асд асд асдс асд ададасда",
	"Направи 10 лицеви опори Сегаааааа садсадададсд асд асд асдс асд ададасда",
	"Изпей куплет от любима песен Сегаааааа садсадададсд асд асд асдс асд ададасда",
	"Направи смешно селфи Сегаааааа садсадададсд асд асд асдс асд ададасда",
	"Направи 10 лицеви опори Сегаааааа садсадададсд асд асд асдс асд ададасда",
	"Изпей куплет от любима песен Сегаааааа садсадададсд асд асд асдс асд ададасда",
	"Направи смешно селфи Сегаааааа садсадададсд асд асд асдс асд ададасда",
	"Направи 10 лицеви опори Сегаааааа садсадададсд асд асд асдс асд ададасда",
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

	# панелът е скрит по подразбиране
	show_selected_dare_root.visible = false

	# свържи бутоните на панела
	delete_button.pressed.connect(_on_confirm_delete)
	back_button.pressed.connect(_hide_panel)

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
	# НЕ пазим глобален индекс тук
	btn.pressed.connect(func(): _open_panel(text, btn))
	return btn

func _open_panel(dare_text: String, node: Button) -> void:
	_pending_delete_text = dare_text
	_pending_delete_node = node

	# номерът според текущия ред на бутона
	var index := list.get_children().find(node) + 1
	show_number_label.text = "%d." % index

	info_rich_label.bbcode_enabled = false
	info_rich_label.text = dare_text
	_show_panel()



func _on_confirm_delete() -> void:
	if _pending_delete_text == "" or _pending_delete_node == null:
		_hide_panel()
		return

	# 1) махни от модела
	dares.erase(_pending_delete_text)
	# 2) махни от UI
	_pending_delete_node.queue_free()
	await get_tree().process_frame
	_renumber_buttons()

	_pending_delete_text = ""
	_pending_delete_node = null
	_hide_panel()


# ---------- Helpers ----------
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
	
func _renumber_buttons() -> void:
	var i := 1
	for child in list.get_children():
		if child is Button:
			var raw_text := _strip_index_prefix((child as Button).text)
			(child as Button).text = " %d. %s" % [i, raw_text]
			i += 1

func _strip_index_prefix(s: String) -> String:
	var dot := s.find(". ")
	return s.substr(dot + 2) if dot != -1 else s
