# DareManager.gd
extends Node

#"user://save.sav"
const DEFAULT_SAVE_PATH := "res://data/save.json"  # вътре в проекта (влиза в .aab)
const SAVE_PATH := "user://save.json"              # истинският сейв на устройството

var is_warning_ready = false

# Работим само с категории (без под-ключове)
const CATEGORY_KEYS := [
	"classic_dares",
	"extreme_dares",
	"sexy_dares",
	"dirty_dares",
	"user_dares"
]

	
var current_save: Dictionary = {}

func _init() -> void:
	current_save = _default_save()
	
func _ready() -> void:
	_ensure_user_save()
	var ok := load_dares()
	if ok:
		print("[DareManager] Save loaded.")
	else:
		print("[DareManager] No save found -> using defaults.")

func _ensure_user_save() -> void:
	# Ако няма user сейв, копирай дефолтния от res://
	if not FileAccess.file_exists(SAVE_PATH):
		if FileAccess.file_exists(DEFAULT_SAVE_PATH):
			var src := FileAccess.open(DEFAULT_SAVE_PATH, FileAccess.READ)
			var buf := src.get_buffer(src.get_length())
			src.close()

			var dst := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
			if dst == null:
				push_error("Cannot write user save: " + str(FileAccess.get_open_error()))
				return
			dst.store_buffer(buf)
			dst.close()
			print("[DareManager] Default save copied to user://")
		else:
			push_warning("[DareManager] DEFAULT not found in res:// (check export filters).")


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
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("Save failed: " + str(FileAccess.get_open_error()))
		return false
	f.store_string(JSON.stringify(current_save))
	return true

func load_dares() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		current_save = _default_save()
		return false

	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		push_error("Load failed: " + str(FileAccess.get_open_error()))
		current_save = _default_save()
		return false

	var text := f.get_as_text()
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
