extends Control

# Words paired with immersive contextual sentence hints
const WORD_DATABASE = {
	"CODE": "Used for compiling core software routines and logic instructions.",
	"HACK": "The primary method used by netrunners to bypass core security nodes.",
	"DATA": "Raw digital packets flowing continuously across the mainframe network.",
	"NODE": "A localized junction point connecting different sectors of the system.",
	"CHIP": "Hardware-level processing unit embedded into cybernetic neural links.",
	"BYTE": "A foundational unit of digital information storage.",
	"SYNC": "The required state for aligning frequency pulses across the mainframe.",
	"LINK": "A secure transmission bridge established between two terminals.",
	"GRID": "The massive virtual infrastructure spanning the entire cyberpunk city.",
	"NET": "The global web of interconnected servers and databanks.",
	"SYSTEM": "The overarching automated mainframe governing all municipal sectors.",
	"VIRUS": "Malicious self-replicating code designed to corrupt memory clusters.",
	"ACCESS": "Granted or denied privilege level required to bypass security gates.",
	"SERVER": "A heavy-duty remote core unit housing critical mainframe files.",
	"CORE": "The central processing heart of the mainframe architecture.",
	"GLITCH": "A sudden visual or logic anomaly caused by system instability.",
	"FIREWALL": "Aggressive network security barrier designed to block unauthorized intruders.",
	"OVERRIDE": "Manual command sequence used to force system compliance.",
	"PROTOCOL": "A strict set of rules governing secure data transmission.",
	"SYNTHWAVE": "The iconic audio frequency style echoing through the neon underground.",
	"TERMINAL": "An individual access station connected to the central mainframe.",
	"MATRIX": "The deep multi-dimensional data grid navigated by expert netrunners.",
	"NETRUNNER": "An elite cyber-operative who dives directly into corporate networks.",
	"VAPORWAVE": "A nostalgic retro-aesthetic style drenched in pink and cyan hues.",
	"CYBERPUNK": "A high-tech, low-life society ruled by corrupt mega-corporations."
}

var secret_word: String = ""
var word_hint_sentence: String = ""
var guessed_letters: Array = []
var max_attempts: int = 6
var remaining_attempts: int = 6
var hints_remaining: int = 1
var combo_streak: int = 0

# --- TIME-BOMB & CORRUPTION VARIABLES ---
var corruption_time_max: float = 12.0
var corruption_time_left: float = 12.0
var corruption_timer_bar: ProgressBar = null
var corruption_warning_label: Label = null

var word_display_label: Label = null
var attempts_label: Label = null
var keyboard_container: VBoxContainer = null
var hangman_visual_node: Control = null
var hint_btn: Button = null
var terminal_log_label: Label = null
var sfx_player: AudioStreamPlayer = null

var is_paused: bool = false
var pause_canvas: CanvasLayer = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	
	setup_audio_system()
	setup_vaporwave_background()
	setup_crt_overlay()
	
	randomize()
	var all_keys = WORD_DATABASE.keys()
	secret_word = all_keys.pick_random()
	word_hint_sentence = WORD_DATABASE[secret_word]
	
	remaining_attempts = max_attempts
	corruption_time_left = corruption_time_max
	
	setup_terminal_ui()
	
	# Dynamically read current level/terminal index from main.gd
	var current_term = 7
	var main_script = load("res://main.gd")
	if main_script:
		current_term = main_script.current_level
		
	append_terminal_log("CONNECTION ESTABLISHED TO HOST SEC-0%d (DATA MATRIX TIME-BOMB)." % current_term)
	append_terminal_log("TARGET DECRYPTION KEY LENGTH: " + str(secret_word.length()) + " BYTES.")

	# --- ADD LEVEL INTRO POPUP DYNAMICALLY ---
	if ResourceLoader.exists("res://level_intro.gd"):
		var intro = load("res://level_intro.gd").new(current_term)
		get_tree().root.add_child(intro)

func _process(delta: float) -> void:
	if is_paused or is_game_over_state():
		return
		
	# --- TIME-BOMB CORRUPTION TICKER ---
	corruption_time_left -= delta
	if corruption_timer_bar:
		corruption_timer_bar.value = corruption_time_left
		
	if corruption_time_left <= 0.0:
		trigger_data_corruption()

func is_game_over_state() -> bool:
	return remaining_attempts <= 0

func trigger_data_corruption() -> void:
	corruption_time_left = corruption_time_max
	play_cyber_sfx("error")
	trigger_screen_flash(Color(1.0, 0.0, 0.4, 0.5), 0.2)
	
	# Scramble one revealed letter back to encrypted symbol if possible
	var revealed_correct = []
	for i in range(secret_word.length()):
		var c = secret_word[i]
		if c in guessed_letters:
			revealed_correct.append(c)
			
	if revealed_correct.size() > 0:
		var bad_c = revealed_correct.pick_random()
		guessed_letters.erase(bad_c)
		append_terminal_log("CRITICAL: TIME-BOMB EXPLOSION! BYTE '" + bad_c + "' RE-ENCRYPTED BY ICE!")
	else:
		remaining_attempts = max(0, remaining_attempts - 1)
		append_terminal_log("CRITICAL: TIME-BOMB DETONATED! -1 CHANCE LOST.")
		
	update_word_display()
	build_virtual_keyboard()

func trigger_screen_flash(flash_color: Color, duration: float = 0.2) -> void:
	var flash = ColorRect.new()
	flash.color = flash_color
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var canvas = CanvasLayer.new()
	canvas.layer = 150
	canvas.add_child(flash)
	add_child(canvas)
	
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, duration)
	await tween.finished
	if is_instance_valid(canvas):
		canvas.queue_free()

func setup_audio_system() -> void:
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)

func play_cyber_sfx(sound_type: String) -> void:
	var sample_rate = 22050
	var duration = 0.08
	var freq = 440.0
	
	match sound_type:
		"key":
			duration = 0.03
			freq = 1200.0
		"hint":
			duration = 0.2
			freq = 880.0
		"error":
			duration = 0.25
			freq = 150.0
		"victory":
			duration = 0.35
			freq = 1046.50
			
	var num_samples = int(sample_rate * duration)
	var buffer = PackedByteArray()
	buffer.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var envelope = 1.0 - (float(i) / num_samples)
		var wave = sin(t * freq * TAU) * envelope
		var val = int(wave * 12000)
		buffer.encode_s16(i * 2, val)

	var sample_stream = AudioStreamWAV.new()
	sample_stream.format = AudioStreamWAV.FORMAT_16_BITS
	sample_stream.mix_rate = sample_rate
	sample_stream.data = buffer

	sfx_player.stream = sample_stream
	sfx_player.play()

func setup_vaporwave_background() -> void:
	var bg_node = VaporwaveBackground.new()
	bg_node.name = "VaporwaveBackground"
	bg_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_node)
	move_child(bg_node, 0)

func setup_crt_overlay() -> void:
	var crt = Control.new()
	crt.name = "CRTOverlay"
	crt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	crt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var scanlines = CRTLines.new()
	scanlines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scanlines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crt.add_child(scanlines)
	add_child(crt)

func setup_terminal_ui() -> void:
	var full_screen_center = CenterContainer.new()
	full_screen_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(full_screen_center)
	
	var outer_panel = PanelContainer.new()
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.04, 0.02, 0.1, 0.92)
	card_style.border_width_left = 3
	card_style.border_width_top = 3
	card_style.border_width_right = 3
	card_style.border_width_bottom = 3
	card_style.border_color = Color(1.0, 0.0, 0.6)
	card_style.corner_radius_top_left = 12
	card_style.corner_radius_top_right = 12
	card_style.corner_radius_bottom_left = 12
	card_style.corner_radius_bottom_right = 12
	card_style.content_margin_left = 25
	card_style.content_margin_right = 25
	card_style.content_margin_top = 20
	card_style.content_margin_bottom = 20
	outer_panel.add_theme_stylebox_override("panel", card_style)
	full_screen_center.add_child(outer_panel)
	
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(620, 1060) # Expanded container to house enlarged hint box and keyboard
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	outer_panel.add_child(vbox)
	
	# Top bar
	var top_bar = HBoxContainer.new()
	top_bar.alignment = BoxContainer.ALIGNMENT_BEGIN
	vbox.add_child(top_bar)
	
	var title_box = VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title = Label.new()
	
	var main_script = load("res://main.gd")
	var term_num = main_script.current_level if main_script else 7
	title.text = "TERMINAL " + str(term_num) + ": DATA MATRIX"
	
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.7, 0.0))
	title_box.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "// TWISTED SECURITY HANGMAN & TIME-BOMB //"
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color(1.0, 0.0, 0.4))
	title_box.add_child(subtitle)
	top_bar.add_child(title_box)
	
	var pause_btn = Button.new()
	pause_btn.text = "❚❚"
	pause_btn.custom_minimum_size = Vector2(50, 50)
	pause_btn.add_theme_font_size_override("font_size", 18)
	pause_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.08, 0.05, 0.18, 0.95)
	btn_style.border_width_left = 2
	btn_style.border_width_top = 2
	btn_style.border_width_right = 2
	btn_style.border_width_bottom = 2
	btn_style.border_color = Color(0.0, 0.9, 1.0)
	btn_style.corner_radius_top_left = 6
	btn_style.corner_radius_top_right = 6
	btn_style.corner_radius_bottom_left = 6
	btn_style.corner_radius_bottom_right = 6
	pause_btn.add_theme_stylebox_override("normal", btn_style)
	pause_btn.add_theme_stylebox_override("hover", btn_style)
	pause_btn.add_theme_stylebox_override("pressed", btn_style)
	pause_btn.pressed.connect(toggle_pause_menu)
	top_bar.add_child(pause_btn)
	
	# --- TIME-BOMB CORRUPTION TIMER UI ---
	var timer_vbox = VBoxContainer.new()
	timer_vbox.add_theme_constant_override("separation", 3)
	vbox.add_child(timer_vbox)
	
	corruption_warning_label = Label.new()
	corruption_warning_label.text = "⚠ DATA CORRUPTION TIME-BOMB TICKING ⚠"
	corruption_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	corruption_warning_label.add_theme_font_size_override("font_size", 12)
	corruption_warning_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2))
	timer_vbox.add_child(corruption_warning_label)
	
	corruption_timer_bar = ProgressBar.new()
	corruption_timer_bar.custom_minimum_size = Vector2(0, 14)
	corruption_timer_bar.max_value = corruption_time_max
	corruption_timer_bar.value = corruption_time_left
	corruption_timer_bar.show_percentage = false
	
	var bar_bg = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.04, 0.02, 0.1, 0.8)
	bar_bg.corner_radius_top_left = 4
	bar_bg.corner_radius_top_right = 4
	bar_bg.corner_radius_bottom_left = 4
	bar_bg.corner_radius_bottom_right = 4
	
	var bar_fill = StyleBoxFlat.new()
	bar_fill.bg_color = Color(1.0, 0.0, 0.4)
	bar_fill.corner_radius_top_left = 4
	bar_fill.corner_radius_top_right = 4
	bar_fill.corner_radius_bottom_left = 4
	bar_fill.corner_radius_bottom_right = 4
	
	corruption_timer_bar.add_theme_stylebox_override("background", bar_bg)
	corruption_timer_bar.add_theme_stylebox_override("fill", bar_fill)
	timer_vbox.add_child(corruption_timer_bar)

	# Cyber Core Hangman Graphic
	hangman_visual_node = CyberHangmanVisual.new()
	hangman_visual_node.custom_minimum_size = Vector2(520, 140)
	hangman_visual_node.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(hangman_visual_node)
	
	# Word & Attempts Panel
	var inner_panel = PanelContainer.new()
	var inner_style = StyleBoxFlat.new()
	inner_style.bg_color = Color(0.02, 0.01, 0.05, 0.95)
	inner_style.border_width_left = 2
	inner_style.border_width_top = 2
	inner_style.border_width_right = 2
	inner_style.border_width_bottom = 2
	inner_style.border_color = Color(0.0, 0.9, 1.0)
	inner_style.corner_radius_top_left = 8
	inner_style.corner_radius_top_right = 8
	inner_style.corner_radius_bottom_left = 8
	inner_style.corner_radius_bottom_right = 8
	inner_style.content_margin_left = 15
	inner_style.content_margin_top = 10
	inner_style.content_margin_right = 15
	inner_style.content_margin_bottom = 10
	inner_panel.add_theme_stylebox_override("panel", inner_style)
	vbox.add_child(inner_panel)
	
	var panel_vbox = VBoxContainer.new()
	panel_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel_vbox.add_theme_constant_override("separation", 5)
	inner_panel.add_child(panel_vbox)
	
	word_display_label = Label.new()
	word_display_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	word_display_label.add_theme_font_size_override("font_size", 32)
	word_display_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	panel_vbox.add_child(word_display_label)
	
	attempts_label = Label.new()
	attempts_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	attempts_label.add_theme_font_size_override("font_size", 14)
	attempts_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.6))
	panel_vbox.add_child(attempts_label)
	
	# --- ENLARGED & READABLE LIVE TERMINAL LOG CONSOLE PANEL ---
	var log_panel = PanelContainer.new()
	var log_style = StyleBoxFlat.new()
	log_style.bg_color = Color(0.01, 0.005, 0.03, 0.98)
	log_style.border_width_left = 2
	log_style.border_width_top = 2
	log_style.border_width_right = 2
	log_style.border_width_bottom = 2
	log_style.border_color = Color(0.0, 0.9, 1.0, 0.8)
	log_style.corner_radius_top_left = 8
	log_style.corner_radius_top_right = 8
	log_style.corner_radius_bottom_left = 8
	log_style.corner_radius_bottom_right = 8
	log_style.content_margin_left = 16
	log_style.content_margin_top = 12
	log_style.content_margin_right = 16
	log_style.content_margin_bottom = 12
	log_panel.add_theme_stylebox_override("panel", log_style)
	log_panel.custom_minimum_size = Vector2(0, 95) # Enlarged height for comfortable reading
	vbox.add_child(log_panel)
	
	terminal_log_label = Label.new()
	terminal_log_label.text = "> SYSTEM INITIALIZED..."
	terminal_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# --- ENLARGED FONT SIZE FOR MOBILE READABILITY ---
	terminal_log_label.add_theme_font_size_override("font_size", 18)
	terminal_log_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.7, 0.95))
	log_panel.add_child(terminal_log_label)
	
	# Contextual Sentence Hint Button
	hint_btn = Button.new()
	hint_btn.text = "⚡ REQUEST CONTEXT HINT (1 LEFT) ⚡"
	hint_btn.custom_minimum_size = Vector2(380, 48)
	hint_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hint_btn.add_theme_font_size_override("font_size", 15)
	hint_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	var hint_style = StyleBoxFlat.new()
	hint_style.bg_color = Color(0.08, 0.04, 0.16, 0.95)
	hint_style.border_width_left = 2
	hint_style.border_width_top = 2
	hint_style.border_width_right = 2
	hint_style.border_width_bottom = 2
	hint_style.border_color = Color(0.0, 0.9, 1.0)
	hint_style.corner_radius_top_left = 6
	hint_style.corner_radius_top_right = 6
	hint_style.corner_radius_bottom_left = 6
	hint_style.corner_radius_bottom_right = 6
	hint_btn.add_theme_stylebox_override("normal", hint_style)
	hint_btn.add_theme_stylebox_override("hover", hint_style)
	hint_btn.add_theme_stylebox_override("pressed", hint_style)
	hint_btn.pressed.connect(use_context_hint)
	vbox.add_child(hint_btn)
	
	# Virtual Keyboard (Centered and Enlarged for effortless tapping)
	keyboard_container = VBoxContainer.new()
	keyboard_container.alignment = BoxContainer.ALIGNMENT_CENTER
	keyboard_container.add_theme_constant_override("separation", 8)
	vbox.add_child(keyboard_container)
	
	update_word_display()
	build_virtual_keyboard()

func append_terminal_log(msg: String) -> void:
	if terminal_log_label:
		terminal_log_label.text = "> " + msg

func use_context_hint() -> void:
	if hints_remaining <= 0:
		return
		
	hints_remaining -= 1
	hint_btn.text = "⚡ CONTEXT HINT DEPLOYED ⚡"
	hint_btn.disabled = true
	
	corruption_time_left = corruption_time_max # Reset bomb timer on hint use
	play_cyber_sfx("hint")
	
	# Display the contextual sentence hint in the terminal log with high-contrast formatting!
	append_terminal_log("CONTEXT HINT: " + word_hint_sentence)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and (event.keycode == KEY_ESCAPE or event.keycode == KEY_P):
		toggle_pause_menu()

func toggle_pause_menu() -> void:
	is_paused = not is_paused
	get_tree().paused = is_paused
	if is_paused:
		show_pause_overlay()
	else:
		if pause_canvas and is_instance_valid(pause_canvas):
			pause_canvas.queue_free()

func show_pause_overlay() -> void:
	pause_canvas = CanvasLayer.new()
	pause_canvas.layer = 100
	pause_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	
	var overlay = ColorRect.new()
	overlay.color = Color(0.02, 0.01, 0.05, 0.85)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_canvas.add_child(overlay)
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_canvas.add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.custom_minimum_size = Vector2(380, 0)
	vbox.add_theme_constant_override("separation", 18)
	center.add_child(vbox)
	
	var title = Label.new()
	title.text = "SYSTEM PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	vbox.add_child(title)
	
	create_menu_btn(vbox, "▶ RESUME PROTOCOL", Color(0.0, 0.9, 1.0), func(): toggle_pause_menu())
	create_menu_btn(vbox, "↺ RESTART HACK", Color(1.0, 0.0, 0.6), func():
		get_tree().paused = false
		get_tree().reload_current_scene()
	)
	create_menu_btn(vbox, "⌂ MAIN MENU", Color(1.0, 0.0, 0.4), func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://menu.tscn")
	)
	add_child(pause_canvas)

func create_menu_btn(parent: Node, text: String, border_color: Color, callback: Callable) -> void:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(340, 52)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.04, 0.12, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = border_color
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.pressed.connect(callback)
	parent.add_child(btn)

func update_word_display() -> void:
	var displayed_text = ""
	var all_guessed = true
	for i in range(secret_word.length()):
		var c = secret_word[i]
		if c in guessed_letters:
			displayed_text += c + " "
		else:
			var placeholder = "#" if (i % 2 == 0) else "?"
			displayed_text += placeholder + " "
			all_guessed = false
	word_display_label.text = displayed_text.strip_edges()
	attempts_label.text = "CHANCES REMAINING: " + str(remaining_attempts) + " / " + str(max_attempts)
	
	if hangman_visual_node:
		var visual_errors = clamp(max_attempts - remaining_attempts, 0, max_attempts)
		hangman_visual_node.errors_count = visual_errors
		hangman_visual_node.queue_redraw()
	
	if all_guessed:
		trigger_victory()
	elif remaining_attempts <= 0:
		trigger_game_over()

func build_virtual_keyboard() -> void:
	for child in keyboard_container.get_children():
		child.queue_free()
	
	var rows = ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"]
	for r in rows:
		var row_box = HBoxContainer.new()
		row_box.alignment = BoxContainer.ALIGNMENT_CENTER
		row_box.add_theme_constant_override("separation", 6)
		
		for i in range(r.length()):
			var letter = r[i]
			var btn = Button.new()
			btn.text = letter
			btn.custom_minimum_size = Vector2(54, 60)
			btn.add_theme_font_size_override("font_size", 22)
			
			var btn_style = StyleBoxFlat.new()
			btn_style.bg_color = Color(0.06, 0.04, 0.12, 0.95)
			btn_style.border_width_left = 2
			btn_style.border_width_top = 2
			btn_style.border_width_right = 2
			btn_style.border_width_bottom = 2
			
			if letter in guessed_letters:
				btn_style.border_color = Color(0.3, 0.3, 0.3)
				btn.disabled = true
			else:
				btn_style.border_color = Color(1.0, 0.0, 0.6)
				
			btn_style.corner_radius_top_left = 8
			btn_style.corner_radius_top_right = 8
			btn_style.corner_radius_bottom_left = 8
			btn_style.corner_radius_bottom_right = 8
			
			btn.add_theme_stylebox_override("normal", btn_style)
			btn.add_theme_stylebox_override("hover", btn_style)
			btn.add_theme_stylebox_override("pressed", btn_style)
			btn.add_theme_stylebox_override("disabled", btn_style)
			btn.pressed.connect(func(): handle_guess(letter))
			row_box.add_child(btn)
			
		keyboard_container.add_child(row_box)

func handle_guess(letter: String) -> void:
	if letter in guessed_letters:
		return
	guessed_letters.append(letter)
	corruption_time_left = corruption_time_max # Reset bomb timer on player action
	
	if letter in secret_word:
		combo_streak += 1
		play_cyber_sfx("key")
		append_terminal_log("MATCH VERIFIED: BYTE '" + letter + "' LOCKED. [COMBO x" + str(combo_streak) + "]")
	else:
		remaining_attempts -= 1
		combo_streak = 0
		play_cyber_sfx("error")
		trigger_screen_flash(Color(1.0, 0.0, 0.4, 0.4), 0.15)
		append_terminal_log("WARNING: WRONG KEY BYTE '" + letter + "'. ICE BREACHED!")
		
	update_word_display()
	build_virtual_keyboard()

func trigger_victory() -> void:
	play_cyber_sfx("victory")
	get_tree().paused = true
	
	var errors_made = max_attempts - remaining_attempts
	var error_penalty_bonus = remaining_attempts * 150
	var perfect_bonus = 500 if errors_made == 0 else 0
	var terminal_score = 600 + error_penalty_bonus + perfect_bonus + (combo_streak * 50)
	
	var main_script = load("res://main.gd")
	if main_script:
		main_script.total_score += terminal_score
	
	var canvas = CanvasLayer.new()
	canvas.name = "VictoryOverlay"
	canvas.layer = 100
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	
	var rect = ColorRect.new()
	rect.color = Color(0.02, 0.01, 0.06, 0.94)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(rect)
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(center)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 460)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.02, 0.12, 0.98)
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color(0.2, 1.0, 0.4)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	panel_style.content_margin_left = 25
	panel_style.content_margin_right = 25
	panel_style.content_margin_top = 25
	panel_style.content_margin_bottom = 25
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)
	
	var lbl = Label.new()
	lbl.text = "⚡ DATA MATRIX DECRYPTED ⚡"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	vbox.add_child(lbl)
	
	var current_term = main_script.current_level if main_script else 7
	var sub_lbl = Label.new()
	sub_lbl.text = "// TIME-BOMB DEFUSED IN SECTOR 0%d //" % current_term
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 11)
	sub_lbl.add_theme_color_override("font_color", Color(1.0, 0.0, 0.4))
	vbox.add_child(sub_lbl)
	
	var stats_panel = PanelContainer.new()
	var stats_style = StyleBoxFlat.new()
	stats_style.bg_color = Color(0.01, 0.005, 0.03, 0.95)
	stats_style.border_width_left = 1
	stats_style.border_width_top = 1
	stats_style.border_width_right = 1
	stats_style.border_width_bottom = 1
	stats_style.border_color = Color(1.0, 0.0, 0.4, 0.4)
	stats_style.corner_radius_top_left = 6
	stats_style.corner_radius_top_right = 6
	stats_style.corner_radius_bottom_left = 6
	stats_style.corner_radius_bottom_right = 6
	stats_style.content_margin_left = 15
	stats_style.content_margin_top = 10
	stats_style.content_margin_right = 15
	stats_style.content_margin_bottom = 10
	stats_panel.add_theme_stylebox_override("panel", stats_style)
	vbox.add_child(stats_panel)
	
	var stats_vbox = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 4)
	stats_panel.add_child(stats_vbox)
	
	var key_found_lbl = Label.new()
	key_found_lbl.text = "DECRYPTED KEY: " + secret_word
	key_found_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_found_lbl.add_theme_font_size_override("font_size", 14)
	key_found_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	stats_vbox.add_child(key_found_lbl)
	
	var score_lbl = Label.new()
	var breakdown_text = "ICE BREACHES: " + str(errors_made) + " / " + str(max_attempts) + "\n"
	if perfect_bonus > 0:
		breakdown_text += "PERFECT HACK BONUS: +500 PTS\n"
	breakdown_text += "DECRYPTION REWARD: +" + str(terminal_score) + " PTS\n"
	breakdown_text += "TOTAL SYSTEM SCORE: " + str(main_script.total_score if main_script else 0)
	score_lbl.text = breakdown_text
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_lbl.add_theme_font_size_override("font_size", 12)
	score_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	stats_vbox.add_child(score_lbl)
	
	var proceed_btn = Button.new()
	var next_target = current_term + 1
	proceed_btn.text = "▶ PROCEED TO TERMINAL " + str(next_target)
	proceed_btn.custom_minimum_size = Vector2(340, 46)
	proceed_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	proceed_btn.add_theme_font_size_override("font_size", 15)
	proceed_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.06, 0.04, 0.14, 0.95)
	btn_style.border_width_left = 2
	btn_style.border_width_top = 2
	btn_style.border_width_right = 2
	btn_style.border_width_bottom = 2
	btn_style.border_color = Color(0.2, 1.0, 0.4)
	btn_style.corner_radius_top_left = 6
	btn_style.corner_radius_top_right = 6
	btn_style.corner_radius_bottom_left = 6
	btn_style.corner_radius_bottom_right = 6
	proceed_btn.add_theme_stylebox_override("normal", btn_style)
	proceed_btn.add_theme_stylebox_override("hover", btn_style)
	proceed_btn.add_theme_stylebox_override("pressed", btn_style)
	
	proceed_btn.pressed.connect(func():
		get_tree().paused = false
		if main_script:
			main_script.current_level = next_target
		canvas.queue_free()
		get_tree().change_scene_to_file("res://main.tscn")
	)
	vbox.add_child(proceed_btn)
	
	var menu_btn = Button.new()
	menu_btn.text = "⌂ RETURN TO MAIN MENU"
	menu_btn.custom_minimum_size = Vector2(340, 46)
	menu_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu_btn.add_theme_font_size_override("font_size", 15)
	menu_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	var menu_style = StyleBoxFlat.new()
	menu_style.bg_color = Color(0.06, 0.04, 0.14, 0.95)
	menu_style.border_width_left = 2
	menu_style.border_width_top = 2
	menu_style.border_width_right = 2
	menu_style.border_width_bottom = 2
	menu_style.border_color = Color(1.0, 0.0, 0.4)
	menu_style.corner_radius_top_left = 6
	menu_style.corner_radius_top_right = 6
	menu_style.corner_radius_bottom_left = 6
	menu_style.corner_radius_bottom_right = 6
	menu_btn.add_theme_stylebox_override("normal", menu_style)
	menu_btn.add_theme_stylebox_override("hover", menu_style)
	menu_btn.add_theme_stylebox_override("pressed", menu_style)
	
	menu_btn.pressed.connect(func():
		get_tree().paused = false
		canvas.queue_free()
		get_tree().change_scene_to_file("res://menu.tscn")
	)
	vbox.add_child(menu_btn)
	
	get_tree().root.add_child(canvas)

func trigger_game_over() -> void:
	get_tree().paused = true
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	
	var rect = ColorRect.new()
	rect.color = Color(0.06, 0.01, 0.02, 0.92)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(rect)
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(center)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 360)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.02, 0.04, 0.98)
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color(1.0, 0.0, 0.4)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	panel_style.content_margin_left = 25
	panel_style.content_margin_right = 25
	panel_style.content_margin_top = 25
	panel_style.content_margin_bottom = 25
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)
	
	var lbl = Label.new()
	lbl.text = "⚠ SYSTEM LOCKOUT ⚠"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.0, 0.4))
	vbox.add_child(lbl)
	
	var sub_lbl = Label.new()
	sub_lbl.text = "DECRYPTION FAILED. SECRET KEY WAS: " + secret_word
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub_lbl.add_theme_font_size_override("font_size", 13)
	sub_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	vbox.add_child(sub_lbl)
	
	var retry_btn = Button.new()
	retry_btn.text = "↺ RE-ATTEMPT HACK"
	retry_btn.custom_minimum_size = Vector2(340, 46)
	retry_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	retry_btn.add_theme_font_size_override("font_size", 15)
	retry_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.06, 0.04, 0.14, 0.95)
	btn_style.border_width_left = 2
	btn_style.border_width_top = 2
	btn_style.border_width_right = 2
	btn_style.border_width_bottom = 2
	btn_style.border_color = Color(1.0, 0.0, 0.4)
	btn_style.corner_radius_top_left = 6
	btn_style.corner_radius_top_right = 6
	btn_style.corner_radius_bottom_left = 6
	btn_style.corner_radius_bottom_right = 6
	retry_btn.add_theme_stylebox_override("normal", btn_style)
	retry_btn.add_theme_stylebox_override("hover", btn_style)
	retry_btn.add_theme_stylebox_override("pressed", btn_style)
	
	retry_btn.pressed.connect(func():
		get_tree().paused = false
		canvas.queue_free()
		get_tree().reload_current_scene()
	)
	vbox.add_child(retry_btn)
	
	var menu_btn = Button.new()
	menu_btn.text = "⌂ RETURN TO MAIN MENU"
	menu_btn.custom_minimum_size = Vector2(340, 46)
	menu_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu_btn.add_theme_font_size_override("font_size", 15)
	menu_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	var menu_style = StyleBoxFlat.new()
	menu_style.bg_color = Color(0.06, 0.04, 0.14, 0.95)
	menu_style.border_width_left = 2
	menu_style.border_width_top = 2
	menu_style.border_width_right = 2
	menu_style.border_width_bottom = 2
	menu_style.border_color = Color(0.0, 0.9, 1.0)
	menu_style.corner_radius_top_left = 6
	menu_style.corner_radius_top_right = 6
	menu_style.corner_radius_bottom_left = 6
	menu_style.corner_radius_bottom_right = 6
	menu_btn.add_theme_stylebox_override("normal", menu_style)
	menu_btn.add_theme_stylebox_override("hover", menu_style)
	menu_btn.add_theme_stylebox_override("pressed", menu_style)
	
	menu_btn.pressed.connect(func():
		get_tree().paused = false
		canvas.queue_free()
		get_tree().change_scene_to_file("res://menu.tscn")
	)
	vbox.add_child(menu_btn)
	
	get_tree().root.add_child(canvas)

# --- CRT SCANLINE SHADER LAYER ---
class CRTLines extends Control:
	func _draw() -> void:
		var sz = get_viewport_rect().size
		for y in range(0, int(sz.y), 4):
			draw_line(Vector2(0, y), Vector2(sz.x, y), Color(0.0, 0.0, 0.0, 0.25), 1.0)

# --- ADVANCED HOLOGRAPHIC CYBER-CORE GRAPHIC DRAWER ---
class CyberHangmanVisual extends Control:
	var errors_count: int = 0
	
	func _draw() -> void:
		var center_pt = size * 0.5
		var cyan = Color(0.0, 0.9, 1.0, 0.8)
		var pink = Color(1.0, 0.0, 0.6)
		
		draw_arc(center_pt, 45.0, 0, TAU, 32, cyan, 2.0)
		draw_arc(center_pt, 30.0, 0, TAU, 32, cyan, 1.5)
		draw_circle(center_pt, 6.0, cyan)
		
		if errors_count >= 1:
			draw_line(center_pt + Vector2(-25, -25), center_pt + Vector2(-50, -50), pink, 3.0)
			draw_circle(center_pt + Vector2(-50, -50), 4.0, pink)
		if errors_count >= 2:
			draw_line(center_pt + Vector2(25, -25), center_pt + Vector2(50, -50), pink, 3.0)
			draw_circle(center_pt + Vector2(50, -50), 4.0, pink)
		if errors_count >= 3:
			draw_line(center_pt + Vector2(-25, 25), center_pt + Vector2(-50, 50), pink, 3.0)
			draw_circle(center_pt + Vector2(-50, 50), 4.0, pink)
		if errors_count >= 4:
			draw_line(center_pt + Vector2(25, 25), center_pt + Vector2(50, 50), pink, 3.0)
			draw_circle(center_pt + Vector2(50, 50), 4.0, pink)
		if errors_count >= 5:
			draw_line(center_pt + Vector2(0, -45), center_pt + Vector2(0, -70), Color(1.0, 1.0, 0.0), 3.0)
		if errors_count >= 6:
			draw_arc(center_pt, 55.0, 0, TAU, 16, Color(1.0, 0.0, 0.0), 3.0)

# --- VAPORWAVE GRID BACKGROUND ---
class VaporwaveBackground extends Control:
	var grid_offset: float = 0.0
	
	func _process(delta: float) -> void:
		grid_offset += delta * 40.0
		if grid_offset > 50.0:
			grid_offset = 0.0
		queue_redraw()
		
	func _draw() -> void:
		var sz = size
		var horizon_y = sz.y * 0.52
		draw_rect(Rect2(0, 0, sz.x, horizon_y), Color(0.07, 0.02, 0.14))
		
		var sun_center = Vector2(sz.x * 0.5, horizon_y - 20)
		var sun_radius = 75.0
		for i in range(10):
			var r = sun_radius - (i * 4)
			var alpha = 0.15 + (i * 0.04)
			draw_circle(sun_center, r, Color(1.0, 0.35, 0.65, alpha))
			
		draw_rect(Rect2(0, horizon_y, sz.x, sz.y - horizon_y), Color(0.02, 0.01, 0.05))
		draw_line(Vector2(0, horizon_y), Vector2(sz.x, horizon_y), Color(1.0, 0.0, 0.7), 2.5)
		
		var vp = Vector2(sz.x * 0.5, horizon_y)
		for i in range(12):
			var t = float(i) / 11.0
			var bx = (t * sz.x * 2.0) - (sz.x * 0.5)
			draw_line(vp, Vector2(bx, sz.y), Color(0.0, 0.9, 1.0, 0.3), 1.2)
