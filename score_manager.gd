class_name ScoreManager
extends Node
# score_manager.gd - Global static manager for persistent leaderboard scores

const SAVE_PATH = "user://leaderboard_data.json"

static func save_score(player_name: String, final_score: int) -> void:
	var records = load_scores()
	var formatted_name = player_name.to_upper().strip_edges()
	if formatted_name == "":
		formatted_name = "AAA"
	if formatted_name.length() > 3:
		formatted_name = formatted_name.substr(0, 3)
		
	records.append({
		"name": formatted_name,
		"score": final_score,
		"date": Time.get_date_string_from_system()
	})
	
	# Sort descending by score
	records.sort_custom(func(a, b): return b["score"] > a["score"])
	
	# Keep top 10 high scores only
	if records.size() > 10:
		records.resize(10)
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(records))

static func load_scores() -> Array:
	var records = []
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var json = JSON.new()
			var error = json.parse(file.get_as_text())
			if error == OK:
				var result = json.get_data()
				if result is Array:
					records = result
					
	# If leaderboard is empty, prepopulate with some cool default cyberpunk scores!
	if records.is_empty():
		records = [
			{"name": "NEO", "score": 35, "date": "2026-10-01"},
			{"name": "CYB", "score": 25, "date": "2026-10-02"},
			{"name": "TRN", "score": 15, "date": "2026-10-03"}
		]
	return records

static func is_high_score(new_score: int) -> bool:
	var records = load_scores()
	if records.size() < 10:
		return true
	return new_score > records[-1]["score"]
