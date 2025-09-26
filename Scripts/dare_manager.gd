# DareManager.gd
extends Node

const SAVE_PATH := "user://save.sav"

const CATEGORY_KEYS := [
	"classic_dares",
	"extreme_dares",
	"sexy_dares",
	"dirty_dares",
]

const SUB_KEYS := [
	"daresOne",
	"daresTwo",
	"daresThree",
	"daresFour",
	"daresAll",
]

var current_save: Dictionary = {}

func _init() -> void:
	current_save = _default_save()

# ---------- Defaults ----------
func _default_bucket() -> Dictionary:
	return {
		"daresOne":  [] as Array[String],
		"daresTwo":  [] as Array[String],
		"daresThree":[] as Array[String],
		"daresFour": [] as Array[String],
		"daresAll":  [] as Array[String],
	}

func _default_save() -> Dictionary:
	return {
		"classic_dares": _default_bucket(),
		"extreme_dares": _default_bucket(),
		"sexy_dares":    _default_bucket(),
		"dirty_dares":   _default_bucket(),
	}

# ---------- Public API ----------
func add_dare(category: String, subgroup: String, text: String) -> void:
	if not current_save.has(category):
		push_warning("Unknown category: %s" % category); return
	if not SUB_KEYS.has(subgroup):
		push_warning("Unknown subgroup: %s" % subgroup); return

	text = text.strip_edges()
	if text.is_empty(): return

	var arr := current_save[category][subgroup] as Array
	arr.append(text)
	_rebuild_dares_all(category)

func remove_dare(category: String, subgroup: String, text: String) -> void:
	if not (current_save.has(category) and SUB_KEYS.has(subgroup)): return
	var arr := current_save[category][subgroup] as Array
	arr.erase(text)
	_rebuild_dares_all(category)

func get_dares(category: String, subgroup: String) -> Array[String]:
	if not (current_save.has(category) and SUB_KEYS.has(subgroup)):
		return [] as Array[String]
	return current_save[category][subgroup]

func clear_category(category: String) -> void:
	if not current_save.has(category): return
	current_save[category] = _default_bucket()

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

	current_save = _merge_with_defaults(data)
	return true

# ---------- Helpers ----------
func _rebuild_dares_all(category: String) -> void:
	if not current_save.has(category): return
	var bucket := current_save[category] as Dictionary
	var combined: Array[String] = []
	for key in ["daresOne","daresTwo","daresThree","daresFour"]:
		var arr := bucket.get(key, []) as Array
		for v in arr:
			var s := String(v)
			if not combined.has(s):
				combined.append(s)
	bucket["daresAll"] = combined

func _merge_with_defaults(loaded: Dictionary) -> Dictionary:
	var def := _default_save()
	for cat in CATEGORY_KEYS:
		var lb := (loaded.get(cat, {}) as Dictionary)
		var db := def[cat] as Dictionary
		# Увери се, че всеки под-списък е масив от String
		for sk in SUB_KEYS:
			var arr := []
			if lb.has(sk) and typeof(lb[sk]) == TYPE_ARRAY:
				for v in (lb[sk] as Array):
					arr.append(String(v))
			db[sk] = arr
	return def



func has_category(category: String) -> bool:
	return current_save.has(category)

func get_category_list(category: String, subgroup: String, duplicate_result := true) -> Array[String]:
	if not has_category(category) or not SUB_KEYS.has(subgroup):
		return [] as Array[String]

	var raw_arr: Array = current_save[category][subgroup]
	var arr: Array[String] = [] 
	for v in raw_arr:
		arr.append(str(v))  # гарантираме, че е String

	return arr.duplicate() if duplicate_result else arr



func get_dares_one(category: String)   -> Array[String]:
	return get_category_list(category, "daresOne")
func get_dares_two(category: String)   -> Array[String]:
	return get_category_list(category, "daresTwo")
func get_dares_three(category: String) -> Array[String]:
	return get_category_list(category, "daresThree")
func get_dares_four(category: String)  -> Array[String]:
	return get_category_list(category, "daresFour")
func get_dares_all(category: String)   -> Array[String]:
	return get_category_list(category, "daresAll")

func get_category_bucket(category: String, duplicate_result := true) -> Dictionary:
	if not has_category(category): return {}
	return current_save[category].duplicate(true) if duplicate_result else current_save[category]

func get_lists_for(category: String) -> Dictionary:
	return {
		"daresOne":   get_dares_one(category),
		"daresTwo":   get_dares_two(category),
		"daresThree": get_dares_three(category),
		"daresFour":  get_dares_four(category),
		"daresAll":   get_dares_all(category),
	}
