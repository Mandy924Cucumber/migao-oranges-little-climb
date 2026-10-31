class_name OrangePlayer
extends CharacterBody2D

signal landed(platform: Node)
signal jumped(is_double: bool)

const SPEED := 355.0
const ACCEL := 2200.0
const GRAVITY := 1510.0
const JUMP_SPEED := -630.0
const DOUBLE_SPEED := -610.0
var active := false
var jumps_used := 0
var coyote := 0.0
var jump_buffer := 0.0
var squash := Vector2.ONE
var squash_target := Vector2.ONE
var clock := 0.0
var facing := 1.0
var grounded_last := false
var invincible := 0.0
var surface: Node
var visual_only := false

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 5.0
	floor_stop_on_slope = true
	var collider := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 18.0
	shape.height = 38.0
	collider.shape = shape
	collider.position = Vector2(0, -21)
	add_child(collider)
	z_index = 10

func _physics_process(delta: float) -> void:
	clock += delta
	invincible = maxf(0, invincible - delta)
	squash = squash.lerp(squash_target, 1.0 - exp(-16 * delta))
	squash_target = squash_target.lerp(Vector2.ONE, 1.0 - exp(-9 * delta))
	queue_redraw()
	if not active:
		return
	var grounded := is_on_floor() and velocity.y >= 0.0
	if grounded:
		coyote = 0.11
		jumps_used = 0
	else:
		coyote = maxf(0, coyote - delta)
	jump_buffer = maxf(0, jump_buffer - delta)
	if Input.is_action_just_pressed("jump"):
		jump_buffer = 0.12
	var axis := Input.get_axis("move_left", "move_right")
	velocity.x = move_toward(velocity.x, axis * SPEED, ACCEL * delta)
	if absf(axis) > 0.1:
		facing = signf(axis)
	velocity.y = minf(velocity.y + GRAVITY * delta, 1150.0)
	if jump_buffer > 0 and (grounded or coyote > 0 or jumps_used < 2):
		if not grounded and coyote <= 0 and jumps_used == 0:
			jumps_used = 1
		_jump()
	# Releasing Space makes a shorter, more precise hop.
	if Input.is_action_just_released("jump") and velocity.y < -260:
		velocity.y *= 0.72
	var falling_speed := velocity.y
	move_and_slide()
	position.x = clampf(position.x, 46.0, 1394.0)
	if is_on_floor():
		for i in range(get_slide_collision_count()):
			var hit := get_slide_collision(i)
			if hit.get_normal().y < -0.7:
				var body := hit.get_collider() as Node
				if not grounded or body != surface:
					surface = body
					squash = Vector2(1.23, 0.75) if falling_speed > 250 else Vector2(1.1, 0.88)
					landed.emit(body)
				break
	grounded_last = grounded

func _jump() -> void:
	var double := jumps_used >= 1 and coyote <= 0
	velocity.y = DOUBLE_SPEED if double else JUMP_SPEED
	jumps_used += 1
	coyote = 0.0
	jump_buffer = 0.0
	squash = Vector2(0.84, 1.19)
	squash_target = Vector2.ONE
	jumped.emit(double)

func bounce() -> void:
	velocity.y = -845.0
	jumps_used = 1
	coyote = 0.0
	squash = Vector2(1.28, 0.73)
	squash_target = Vector2(0.88, 1.16)

func reset_at(at: Vector2) -> void:
	position = at
	velocity = Vector2.ZERO
	jumps_used = 0
	jump_buffer = 0
	coyote = 0
	surface = null
	invincible = 0.65
	squash = Vector2.ONE

func _draw() -> void:
	var bob := sin(clock * 2.4) * 1.0 if not active or is_on_floor() else 0.0
	var foot_step := sin(clock * 20) * 3.5 if active and is_on_floor() and absf(velocity.x) > 20 else 0.0
	var alpha := 0.55 if invincible > 0 and sin(clock * 38) > 0 else 1.0
	draw_set_transform(Vector2(0, bob), 0.0, squash)
	Paint.ellipse(self, Vector2(-16, -5 - foot_step), Vector2(12, 5.5), Color(0.94, 0.35, 0.06, alpha))
	Paint.ellipse(self, Vector2(16, -5 + foot_step), Vector2(12, 5.5), Color(0.94, 0.35, 0.06, alpha))
	Paint.box(self, Rect2(-21, -13 - foot_step, 10, 10), Color(1.0, 0.45, 0.08, alpha), 3)
	Paint.box(self, Rect2(11, -13 + foot_step, 10, 10), Color(1.0, 0.45, 0.08, alpha), 3)
	Paint.ellipse(self, Vector2(0, -27), Vector2(39, 19.5), Color(0.98, 0.40, 0.055, alpha))
	Paint.ellipse(self, Vector2(-2, -29), Vector2(36, 17), Color(1.0, 0.46, 0.075, alpha))
	Paint.ellipse(self, Vector2(-8, -38), Vector2(17, 3.7), Color(1.0, 0.67, 0.26, 0.28 * alpha))
	var blink := fmod(clock, 4.7) > 4.56
	for x in [-9.0, 9.0]:
		Paint.ellipse(self, Vector2(x + facing * 1.5, -29), Vector2(2.6, 0.7 if blink else 4.9), Color(0.12, 0.12, 0.09, alpha))
	draw_set_transform(Vector2.ZERO)
	if active and not is_on_floor():
		for i in range(2):
			var dot_color := Color("c7aa6c") if i < 2 - jumps_used else Color(0.65, 0.61, 0.49, 0.2)
			draw_circle(Vector2(-5 + i * 10, -56), 2.3, dot_color)
