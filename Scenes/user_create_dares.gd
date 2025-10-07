class_name UserCreateDares
extends Control

@onready var list: VBoxContainer        = $ScrollContainer/DaresList
@onready var template_button: Button    = $Button           # шаблонен бутон (скрит)
@onready var panel: Panel               = $Panel            # панелът за потвърждение
@onready var info_label: Label          = $Panel/Label
@onready var yes_button: Button         = $Panel/YesButton
@onready var no_button: Button          = $Panel/NoButton

var dares: Array[String] = [
	"Направи 10 лицеви опори Сегаааааа садсадададсд асд асд асдс асд ададасда",
	"Изпей куплет от любима песен Сегаааааа садсадададсд асд асд асдс асд ададасда",
	"Направи смешно селфи Сегаааааа садсадададсд асд асд асдс асд ададасда",
	# ... (останалите)
]

var _pending_delete_text: String = ""
var _pending_delete_node: Button = null

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# ScrollContainer & VBox grow
	$ScrollContainer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	$ScrollContainer.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.size_flags_vertical   = Control.SIZE_EXPAND_FILL

	# тънък скрол (Godot 4)
	var vbar: VScrollBar = $ScrollContainer.get_v_scroll_bar()
	if vbar:
		vbar.add_theme_constant_override("thickness", 6)
		var normal = StyleBoxFlat.new();  normal.bg_color  = Color(0,0,0,0)
		var hover  = StyleBoxFlat.new();  hover.bg_color   = Color(0,0,0,0.4)
		var press  = StyleBoxFlat.new();  press.bg_color   = Color(0,0,0,1)
		var track  = StyleBoxFlat.new();  track.bg_color   = Color(0,0,0,0)
		vbar.add_theme_stylebox_override("grabber", normal)
		vbar.add_theme_stylebox_override("grabber_highlight", hover)
		vbar.add_theme_stylebox_override("grabber_pressed", press)
		vbar.add_theme_stylebox_override("scroll", track)

	# шаблонният бутон да не се вижда сам
	template_button.visible = false

	# панелът е скрит по подразбиране
	panel.visible = false
	yes_button.pressed.connect(_on_confirm_delete)
	no_button.pressed.connect(func(): _hide_panel())

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
	#btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.clip_text = true
	#btn.autowrap_mode = TextServer.AUTOWRAP_WORD   # ако шаблонът е FlatButton с текст
	#btn.custom_minimum_size = Vector2(0, 36)       # по-четим ред
	#btn.tooltip_text = text                        # показва целия текст при hover

	btn.pressed.connect(func(): _open_delete_panel(text, btn))
	return btn

func _open_delete_panel(dare_text: String, node: Button) -> void:
	_pending_delete_text = dare_text
	_pending_delete_node = node
	info_label.text = "Изтриване на:\n" + dare_text
	_show_panel()

func _on_confirm_delete() -> void:
	if _pending_delete_text == "" or _pending_delete_node == null:
		_hide_panel()
		return

	dares.erase(_pending_delete_text)
	_pending_delete_node.queue_free()

	_pending_delete_text = ""
	_pending_delete_node = null
	_hide_panel()

# — малко удобство: плавно показване/скриване —
func _show_panel() -> void:
	panel.visible = true
	panel.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.18)

func _hide_panel() -> void:
	var tw = create_tween()
	tw.tween_property(panel, "modulate:a", 0.0, 0.18)
	tw.tween_callback(Callable(panel, "set_visible").bind(false))
