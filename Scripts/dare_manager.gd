# DareManager.gd
extends Node

const SAVE_PATH := "user://save.sav"

# Работим само с категории (без под-ключове)
const CATEGORY_KEYS := [
	"classic_dares",
	"extreme_dares",
	"sexy_dares",
	"dirty_dares",
]

var current_save: Dictionary = {}

func _init() -> void:
	current_save = _default_save()
	
func _ready() -> void:
	# опитай да заредиш сейва веднага щом автолоудът тръгне
	var ok := load_dares()
	if ok:
		print("[DareManager] Save loaded.")
	else:
		print("[DareManager] No save found -> using defaults.")

# ---------- Defaults ----------
func _default_save() -> Dictionary:
	var d: Dictionary = {}
	for cat in CATEGORY_KEYS:
		d[cat] = [] as Array[String]
	return d

# ---------- Public API (само категории) ----------
func has_category(category: String) -> bool:
	return CATEGORY_KEYS.has(category)

func add_dare(category: String, text: String) -> void:
	if not has_category(category):
		push_warning("Unknown category: %s" % category); return
	text = text.strip_edges()
	if text.is_empty():
		return
	var arr := current_save[category] as Array
	# избягваме дубли
	if not arr.has(text):
		arr.append(text)

func remove_dare(category: String, text: String) -> void:
	if not has_category(category):
		return
	var arr := current_save[category] as Array
	arr.erase(text)

func get_dares(category: String, duplicate_result := true) -> Array[String]:
	if not has_category(category):
		return [] as Array[String]
	var arr: Array = current_save[category]
	return arr.duplicate() if duplicate_result else arr

func clear_category(category: String) -> void:
	if not has_category(category): return
	current_save[category] = [] as Array[String]

func get_all_categories() -> Dictionary:
	# Връща копие за безопасно четене
	var out := {}
	for cat in CATEGORY_KEYS:
		out[cat] = (current_save[cat] as Array).duplicate()
	return out

# ---------- Save / Load ----------
func save_dares() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Save failed: %s" % FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(current_save))
	return true

func load_dares() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		current_save = _default_save()
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Load failed: %s" % FileAccess.get_open_error())
		current_save = _default_save()
		return false

	var text := file.get_as_text()
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("Save corrupted; using defaults.")
		current_save = _default_save()
		return false

	current_save = _normalize_loaded(data)
	return true

# ---------- Helpers ----------
# Приема както новия плосък формат, така и стария (с под-ключове), и връща плосък.
func _normalize_loaded(loaded: Dictionary) -> Dictionary:
	var result := _default_save()

	for cat in CATEGORY_KEYS:
		if not loaded.has(cat):
			continue

		var v = loaded[cat]
		match typeof(v):
			TYPE_ARRAY:
				# Нов формат: директно списък с низове
				result[cat] = _as_string_array(v as Array)
			TYPE_DICTIONARY:
				# Стар формат: комбинираме известните под-ключове в една листа
				var legacy := v as Dictionary
				var combined: Array[String] = []
				for sk in ["daresOne","daresTwo","daresThree","daresFour","daresAll"]:
					if legacy.has(sk) and typeof(legacy[sk]) == TYPE_ARRAY:
						for item in (legacy[sk] as Array):
							var s := String(item)
							if not combined.has(s):
								combined.append(s)
				result[cat] = combined
			_:
				# Непознат тип – игнорираме, оставяме празно по дефолт
				pass

	return result

func _as_string_array(arr: Array) -> Array[String]:
	var out: Array[String] = []
	for v in arr:
		var s := String(v)
		if not out.has(s):
			out.append(s)
	return out
