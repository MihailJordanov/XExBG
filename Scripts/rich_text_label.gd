extends RichTextLabel

const MIN_FS := 4
const MAX_FS := 48

func _ready() -> void:
	bbcode_enabled = true
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	resized.connect(_on_resized)

	# изчакай да има валидни размери
	await get_tree().process_frame
	await fit_font_to_bounds()

# ------- НОВО: удобен setter + рефит -------
func set_text_smart(t: String) -> void:
	text = t   # няма значение дали е plain или съдържа bbcode, щом bbcode_enabled = true
	call_deferred("_deferred_refit")


func _deferred_refit() -> void:
	await get_tree().process_frame
	await fit_font_to_bounds()

func _on_resized() -> void:
	call_deferred("_deferred_refit")

# ------- твоето рефитване -------
func fit_font_to_bounds():
	var font_size := MAX_FS
	while font_size >= MIN_FS:
		add_theme_font_size_override("normal_font_size", font_size)
		add_theme_font_size_override("bold_font_size", font_size)

		await get_tree().process_frame  # изчакай layout-а

		var fits_vertically: bool = get_content_height() <= size.y
		var fits_horizontally: bool = get_content_width() <= size.x

		if fits_vertically and fits_horizontally:
			break

		font_size -= 1
