extends Node

const DEFAULT_SAVE_PATH := "res://data/save.json"  # вътре в проекта (влиза в .aab)
const SAVE_PATH := "user://save.json"              # истинският сейв на устройството

var is_warning_ready := false

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
	var def := _try_load_json_dict(DEFAULT_SAVE_PATH)
	var def_ok: bool = def["ok"]
	var def_dict: Dictionary = def["data"]

	var usr := _try_load_json_dict(SAVE_PATH)
	var usr_ok: bool = usr["ok"]
	var usr_dict: Dictionary = usr["data"]

	if not def_ok and not usr_ok:
		push_warning("No valid default or user save; using defaults.")
		current_save = _default_save()
		return false

	if def_ok and not usr_ok:
		current_save = def_dict
		save_dares()
		return true

	if usr_ok and not def_ok:
		current_save = usr_dict
		return true

	var merged := def_dict.duplicate(true)

	if has_category("user_dares"):
		var usr_arr: Array[String] = []
		if usr_dict.has("user_dares") and typeof(usr_dict["user_dares"]) == TYPE_ARRAY:
			usr_arr = _as_string_array(usr_dict["user_dares"])
		merged["user_dares"] = usr_arr

	current_save = _normalize_loaded(merged)

	save_dares()
	return true

# ---------- Helpers ----------
func _try_load_json_dict(path: String) -> Dictionary:
	var res := {"ok": false, "data": _default_save()}

	if not FileAccess.file_exists(path):
		return res

	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_warning("Cannot open: %s (err %s)" % [path, str(FileAccess.get_open_error())])
		return res

	var text := f.get_as_text()
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("Invalid JSON in: %s" % path)
		return res

	res["ok"] = true
	res["data"] = _normalize_loaded(data)
	return res

func _normalize_loaded(loaded: Dictionary) -> Dictionary:
	var result := _default_save()

	for cat in CATEGORY_KEYS:
		if not loaded.has(cat):
			continue

		var v = loaded[cat]
		match typeof(v):
			TYPE_ARRAY:
				result[cat] = _as_string_array(v as Array)
			TYPE_DICTIONARY:
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
				pass

	return result

func _as_string_array(arr: Array) -> Array[String]:
	var out: Array[String] = []
	for v in arr:
		var s := String(v)
		if not out.has(s):
			out.append(s)
	return out
