extends RichTextLabel

const MIN_FS := 5
const MAX_FS := 48

signal font_fit_done(final_size:int)

func _ready() -> void:
	bbcode_enabled = true
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	resized.connect(_on_resized)
	call_deferred("_deferred_refit")

func set_text_smart(t: String) -> void:
	text = t
	call_deferred("_deferred_refit")

func _on_resized() -> void:
	call_deferred("_deferred_refit")

func _deferred_refit() -> void:
	await get_tree().process_frame
	await fit_font_to_bounds_instant()

# --- Напасване без „анимация“ ---
func fit_font_to_bounds_instant() -> void:
	var was_visible := visible
	visible = false
	await get_tree().process_frame

	# 1) Първо приближение
	add_theme_font_size_override("normal_font_size", MAX_FS)
	add_theme_font_size_override("bold_font_size",   MAX_FS)
	await get_tree().process_frame

	var cw := maxf(1.0, float(get_content_width()))
	var ch := maxf(1.0, float(get_content_height()))
	var sx := size.x / cw
	var sy := size.y / ch
	var guess := clampi(floori(MAX_FS * minf(sx, sy)), MIN_FS, MAX_FS)

	add_theme_font_size_override("normal_font_size", guess)
	add_theme_font_size_override("bold_font_size",   guess)
	await get_tree().process_frame

	# 2) Фино напасване (бинарно търсене)
	var best := guess
	var lo := MIN_FS
	var hi := MAX_FS

	var fits_guess := (get_content_width() <= size.x and get_content_height() <= size.y)
	if fits_guess:
		lo = guess
	else:
		hi = guess - 1

	while lo <= hi:
		var mid := (lo + hi) >> 1
		add_theme_font_size_override("normal_font_size", mid)
		add_theme_font_size_override("bold_font_size",   mid)
		await get_tree().process_frame

		var fits_mid := (get_content_width() <= size.x and get_content_height() <= size.y)
		if fits_mid:
			best = mid
			lo = mid + 1
		else:
			hi = mid - 1

	# 3) Краен размер
	add_theme_font_size_override("normal_font_size", best)
	add_theme_font_size_override("bold_font_size",   best)

	visible = was_visible
	emit_signal("font_fit_done", best)
