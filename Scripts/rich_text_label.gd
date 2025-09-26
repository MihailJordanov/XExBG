extends RichTextLabel

const MIN_FS := 4
const MAX_FS := 48

func _ready():
	bbcode_enabled = true
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fit_font_to_bounds()

func fit_font_to_bounds():
	var font_size := MAX_FS
	while font_size >= MIN_FS:
		add_theme_font_size_override("normal_font_size", font_size)
		add_theme_font_size_override("bold_font_size", font_size) # ако имаш [b]...[/b]

		await get_tree().process_frame  # изчакай да се преизчисли layout-а

		var fits_vertically: bool = get_content_height() <= size.y
		var fits_horizontally: bool = get_content_width() <= size.x

		if fits_vertically and fits_horizontally:
			break

		font_size -= 1
