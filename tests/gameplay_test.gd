extends SceneTree

var game: Node
var failures: Array[String] = []
var last_landed: Node
var total_checks := 0
var jumps: Array[bool] = []

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, description: String) -> void:
	total_checks += 1
	if not condition:
		failures.append(description)
		push_error(description)

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame

func release_keys() -> void:
	for action in ["move_left", "move_right", "jump"]:
		Input.action_release(action)

func _run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.testing = true
	root.add_child(game)
	await frames(5)
	game.sound.set_enabled(false)
	game.backdrop.set_process(false)
	game.hud.set_process(false)
	for platform in game.platforms:
		platform.set_process(false)
	game.player.landed.connect(func(body: Node): last_landed = body)
	game.player.jumped.connect(func(second: bool): jumps.append(second))
	check(game.platforms.size() == 150, "144 objects + 5 checkpoints + summit")
	check(game.checkpoint_platforms.size() == 5, "Checkpoint every 24 objects")
	game.start_run(false)
	await frames(10)
	check(game.player.is_on_floor(), "Start player stands on floor")
	check(game.mode == "play", "Initial floor does not trigger game over")
	# Three input taps must produce exactly two jumps.
	Input.action_press("jump")
	await frames(7)
	Input.action_release("jump")
	await frames(2)
	Input.action_press("jump")
	await frames(7)
	Input.action_release("jump")
	await frames(2)
	Input.action_press("jump")
	await frames(2)
	Input.action_release("jump")
	check(jumps.size() == 2, "Two jumps allowed; third airborne press rejected")
	check(jumps == [false, true], "First and second jump events distinguished")
	await frames(160)
	check(game.mode == "over", "Landing on bottom floor ends a started run")
	# Exercise the entire route with actual physics and synthetic key presses.
	game.start_run(false)
	await frames(8)
	var reached := 0
	for target in game.platforms:
		last_landed = null
		var ticks := 0
		var second_used := false
		var second_tick := -1
		if game.player.is_on_floor() and game.player.velocity.y >= 0:
			Input.action_press("jump")
		while ticks < 400 and last_landed != target and game.mode == "play":
			var dx: float = target.position.x - game.player.position.x
			var vx: float = game.player.velocity.x
			var brake: float = vx * vx / (2 * OrangePlayer.ACCEL) + 6
			Input.action_release("move_left")
			Input.action_release("move_right")
			if absf(dx) > maxf(10, brake):
				Input.action_press("move_right" if dx > 0 else "move_left")
			if ticks == 39:
				Input.action_release("jump")
			if not second_used and ticks >= 40 and game.player.velocity.y > -160 and not game.player.is_on_floor():
				Input.action_press("jump")
				second_used = true
				second_tick = ticks
			if second_used and ticks > second_tick + 12 and game.player.velocity.y > -180:
				Input.action_release("jump")
			await frames(1)
			ticks += 1
		release_keys()
		if last_landed == target:
			reached += 1
		else:
			check(false, "Route unreachable at %d %s; player %s target %s mode %s last %s" % [target.index, target.kind, game.player.position, target.position, game.mode, last_landed])
			break
		if reached % 25 == 0:
			print("Route verified: %d / 150 landings" % reached)
	check(reached == 150, "Every object and checkpoint reachable using keyboard physics")
	check(game.mode == "win", "Summit triggers win screen")
	check(game.visited.size() == 144, "All 144 unique objects counted")
	check(game.checkpoint_index == 120, "Last checkpoint is 120")
	# Verify duplicates, elastic bounce, pause, and checkpoint restore independently.
	game.start_run(false)
	await frames(3)
	var one = game.platforms[0]
	game._on_landed(one)
	game._on_landed(one)
	check(game.visited.size() == 1, "Repeated landing never increments collection")
	game._on_landed(game.platforms[3])
	check(game.player.velocity.y == -845, "Bed launches player with stronger bounce")
	check(game.player.jumps_used == 1, "Bed leaves exactly one midair jump")
	var cp = game.checkpoint_platforms[24]
	game._on_landed(cp)
	check(game.checkpoint_index == 24 and game.has_save, "Checkpoint activated and save prepared")
	game.player.position = Vector2(600, cp.position.y + 610)
	game._process(1.0 / 120.0)
	check(game.player.position.distance_to(game.checkpoint_position) < 1, "A fall returns to most recent checkpoint")
	check(game.mode == "play", "Checkpoint fall preserves active run")
	var before: float = game.elapsed
	game.set_paused(true)
	await frames(15)
	check(is_equal_approx(game.elapsed, before), "Pause freezes game timer")
	check(not game.player.active, "Pause freezes player")
	game.set_paused(false)
	check(game.player.active, "Resume reenables player")
	game._save_checkpoint()
	game.start_run(true)
	check(game.checkpoint_index == 24 and game.visited.size() == 2, "Continue restores checkpoint and collected objects")
	check(game.player.position.distance_to(game.checkpoint_position) < 1, "Continue starts at saved checkpoint")
	# The bottom floor remains a failure even after a checkpoint.
	game.player.invincible = 0
	game._on_landed(game.world.get_node("StartFloor"))
	check(game.mode == "over", "Bottom floor always ends run")
	print("GAMEPLAY TESTS: %d checks, %d failures" % [total_checks, failures.size()])
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
