extends SceneTree
var failed := false
func _initialize() -> void:
	run.call_deferred()
func verify(value: bool, message: String) -> void:
	if not value:
		failed = true
		push_error(message)
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.testing = true
	game.save_path = "user://orange_save_verification.json"
	root.add_child(game)
	await process_frame
	game.start_run(false)
	game.visited = {1: true, 5: true, 24: true}
	game.checkpoint_index = 24
	game.elapsed = 125.5
	game.max_height = 2900.0
	game.testing = false
	game._save_checkpoint()
	verify(FileAccess.file_exists(game.save_path), "Checkpoint must write to disk")
	game.save_data = {}
	game.has_save = false
	game._read_save()
	verify(game.has_save and int(game.save_data.get("checkpoint", 0)) == 24, "Checkpoint reload from disk")
	game.testing = true
	game.start_run(true)
	verify(game.visited.size() == 3 and game.visited.has(5), "Unique item IDs survive JSON number conversion")
	verify(is_equal_approx(game.elapsed, 125.5), "Elapsed timer survives restart")
	verify(game.player.position.distance_to(game.checkpoint_position) < 1, "Continue uses brick checkpoint position")
	# Malformed data should be ignored without crashing.
	var file := FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string("{bad json")
	file.close()
	game.has_save = false
	game._read_save()
	verify(not game.has_save, "Corrupt save is safely ignored")
	DirAccess.remove_absolute(game.save_path)
	game.queue_free()
	await process_frame
	print("SAVE TESTS: 6 checks, %d failures" % int(failed))
	quit(1 if failed else 0)
