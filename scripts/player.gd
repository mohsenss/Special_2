extends CharacterBody3D
class_name PlayerController

signal health_changed(current: float, max_health: float)
signal kill_count_changed(value: int)
signal score_changed(value: int)
signal cooldowns_changed(dash_ratio: float, knife_ratio: float, stealth_ratio: float, air_jump_ratio: float)
signal player_died

@export var max_health: float = 100.0
@export var move_speed: float = 11.0
@export var accel: float = 28.0
@export var air_control: float = 0.45
@export var jump_velocity: float = 10.5
@export var max_air_jumps: int = 1
@export var air_jump_cooldown: float = 10.0
@export var mouse_sensitivity: float = 0.003

@export var knife_damage: float = 34.0
@export var knife_range: float = 3.2
@export var knife_radius: float = 2.1
@export var knife_cooldown: float = 0.24
@export var knife_knockback: float = 8.5

@export var rifle_damage: float = 34.0
@export var rifle_fire_rate: float = 12.0
@export var rifle_range: float = 180.0

@export var dash_speed: float = 38.0
@export var dash_duration: float = 0.18
@export var dash_cooldown: float = 1.8
@export var dash_damage: float = 70.0
@export var dash_knockback: float = 16.0
@export var dash_hit_radius: float = 1.8

@export var stealth_duration: float = 3.8
@export var stealth_cooldown: float = 11.0
@export var heal_on_kill: float = 8.0

@onready var pivot: Node3D = $Pivot
@onready var camera: Camera3D = $Pivot/Camera3D
@onready var body_mesh: MeshInstance3D = $BodyMesh

var gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
var health: float
var kill_count: int = 0
var score: int = 0

var _yaw := 0.0
var _pitch := 0.0
var _air_jumps_left := 0

var _knife_timer := 0.0
var _rifle_timer := 0.0
var _dash_timer := 0.0
var _dash_cooldown_timer := 0.0
var _air_jump_cooldown_timer := 0.0
var _dash_hits: Dictionary = {}
var _dash_prev_origin: Vector3 = Vector3.ZERO
var _dash_key_was_down := false

var _stealth_timer := 0.0
var _stealth_cooldown_timer := 0.0
var _alive := true

func _ready() -> void:
	health = max_health
	_air_jumps_left = max_air_jumps
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	health_changed.emit(health, max_health)
	kill_count_changed.emit(kill_count)
	score_changed.emit(score)
	_emit_cooldowns()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch = clamp(_pitch - event.relative.y * mouse_sensitivity, deg_to_rad(-87), deg_to_rad(87))
		rotation.y = _yaw
		pivot.rotation.x = _pitch
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta: float) -> void:
	if not _alive:
		return
	_update_timers(delta)
	_update_stealth_visuals()

	if Input.is_action_pressed("attack"):
		_try_knife_attack()
	if Input.is_action_pressed("rifle_fire"):
		_try_rifle_fire()
	var shift_down := Input.is_key_pressed(KEY_SHIFT)
	if Input.is_action_just_pressed("dash") or (shift_down and not _dash_key_was_down):
		_try_dash()
	_dash_key_was_down = shift_down
	if Input.is_action_just_pressed("stealth"):
		_try_stealth()

	var input_vec := Input.get_vector("move_left", "move_right", "move_backward", "move_forward")
	var forward := -transform.basis.z
	var right := transform.basis.x
	var desired_dir := (forward * input_vec.y + right * input_vec.x)
	if desired_dir.length_squared() > 0.001:
		desired_dir = desired_dir.normalized()
	var target_speed := move_speed
	var current_control := accel if is_on_floor() else accel * air_control
	velocity.x = move_toward(velocity.x, desired_dir.x * target_speed, current_control * delta)
	velocity.z = move_toward(velocity.z, desired_dir.z * target_speed, current_control * delta)

	if is_on_floor():
		_air_jumps_left = max_air_jumps
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
	else:
		velocity.y -= gravity * delta
		if Input.is_action_just_pressed("jump") and _air_jumps_left > 0 and _air_jump_cooldown_timer <= 0.0:
			_air_jumps_left -= 1
			_air_jump_cooldown_timer = air_jump_cooldown
			velocity.y = jump_velocity * 0.95

	if _dash_timer > 0.0:
		_dash_prev_origin = global_transform.origin
		var dash_dir := -transform.basis.z
		velocity.x = dash_dir.x * dash_speed
		velocity.z = dash_dir.z * dash_speed
		_apply_dash_hits()

	move_and_slide()

	if _dash_timer > 0.0:
		_apply_dash_hits()

func _process(_delta: float) -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and (Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("rifle_fire")):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _update_timers(delta: float) -> void:
	_knife_timer = max(_knife_timer - delta, 0.0)
	_rifle_timer = max(_rifle_timer - delta, 0.0)
	_dash_timer = max(_dash_timer - delta, 0.0)
	_dash_cooldown_timer = max(_dash_cooldown_timer - delta, 0.0)
	_air_jump_cooldown_timer = max(_air_jump_cooldown_timer - delta, 0.0)
	_stealth_timer = max(_stealth_timer - delta, 0.0)
	_stealth_cooldown_timer = max(_stealth_cooldown_timer - delta, 0.0)
	_emit_cooldowns()

func _try_knife_attack() -> void:
	if _knife_timer > 0.0 or not _alive:
		return
	_knife_timer = knife_cooldown
	var shape := SphereShape3D.new()
	shape.radius = knife_radius
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	var attack_origin := global_transform.origin + (-global_transform.basis.z * knife_range)
	params.transform = Transform3D(Basis.IDENTITY, attack_origin)
	params.collide_with_areas = false
	params.collide_with_bodies = true
	params.exclude = [self]
	var hits: Array[Dictionary] = get_world_3d().direct_space_state.intersect_shape(params, 64)
	for hit_data: Dictionary in hits:
		var collider_obj: Object = hit_data.get("collider") as Object
		var enemy := collider_obj as EnemyUnit
		if enemy:
			var to_target := enemy.global_transform.origin - global_transform.origin
			if to_target.normalized().dot(-global_transform.basis.z) > 0.1:
				enemy.take_damage(knife_damage, to_target.normalized() * knife_knockback)

func _try_rifle_fire() -> void:
	if _rifle_timer > 0.0 or not _alive:
		return
	_rifle_timer = 1.0 / rifle_fire_rate if rifle_fire_rate > 0.0 else 0.08
	var from := camera.global_transform.origin
	var to := from + (-camera.global_transform.basis.z * rifle_range)
	var params := PhysicsRayQueryParameters3D.create(from, to)
	params.collide_with_areas = false
	params.collide_with_bodies = true
	params.exclude = [self]
	var result := get_world_3d().direct_space_state.intersect_ray(params)
	if result.is_empty():
		return
	var enemy := result.get("collider") as EnemyUnit
	if enemy:
		enemy.take_damage(rifle_damage)

func _try_dash() -> void:
	if _dash_cooldown_timer > 0.0 or _dash_timer > 0.0 or not _alive:
		return
	_dash_timer = dash_duration
	_dash_cooldown_timer = dash_cooldown
	_dash_hits.clear()
	_dash_prev_origin = global_transform.origin

func _apply_dash_hits() -> void:
	var shape := SphereShape3D.new()
	shape.radius = dash_hit_radius
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.collide_with_areas = false
	params.collide_with_bodies = true
	params.exclude = [self]
	var samples := 5
	for i in range(samples):
		var t := float(i) / float(max(samples - 1, 1))
		var probe_origin := _dash_prev_origin.lerp(global_transform.origin, t)
		params.transform = Transform3D(Basis.IDENTITY, probe_origin)
		var hits: Array[Dictionary] = get_world_3d().direct_space_state.intersect_shape(params, 24)
		for hit_data: Dictionary in hits:
			var collider_obj: Object = hit_data.get("collider") as Object
			var enemy := collider_obj as EnemyUnit
			if enemy:
				var id := enemy.get_instance_id()
				if _dash_hits.has(id):
					continue
				_dash_hits[id] = true
				var push := (enemy.global_transform.origin - global_transform.origin).normalized()
				enemy.take_damage(dash_damage, push * dash_knockback)

func _try_stealth() -> void:
	if _stealth_cooldown_timer > 0.0 or _stealth_timer > 0.0 or not _alive:
		return
	_stealth_timer = stealth_duration
	_stealth_cooldown_timer = stealth_cooldown
	_emit_cooldowns()

func is_stealthed() -> bool:
	return _stealth_timer > 0.0

func take_damage(amount: float) -> void:
	if not _alive or is_stealthed():
		return
	health = max(health - amount, 0.0)
	health_changed.emit(health, max_health)
	if health <= 0.0:
		_alive = false
		player_died.emit()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func register_kill() -> void:
	on_enemy_killed()

func on_enemy_killed() -> void:
	kill_count += 1
	health = min(max_health, health + heal_on_kill)
	kill_count_changed.emit(kill_count)
	health_changed.emit(health, max_health)

func add_objective_points(amount: int) -> void:
	if amount <= 0:
		return
	score += amount
	score_changed.emit(score)

func _update_stealth_visuals() -> void:
	var mat := body_mesh.material_override
	if mat == null:
		return
	if mat is StandardMaterial3D:
		var std := mat as StandardMaterial3D
		if is_stealthed():
			std.albedo_color.a = 0.2
			std.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		else:
			std.albedo_color.a = 1.0
			std.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED

func _emit_cooldowns() -> void:
	var dash_ratio := 1.0 - (_dash_cooldown_timer / dash_cooldown) if dash_cooldown > 0.0 else 1.0
	var knife_ratio := 1.0 - (_knife_timer / knife_cooldown) if knife_cooldown > 0.0 else 1.0
	var stealth_ratio := 1.0 - (_stealth_cooldown_timer / stealth_cooldown) if stealth_cooldown > 0.0 else 1.0
	var air_jump_ratio := 1.0 - (_air_jump_cooldown_timer / air_jump_cooldown) if air_jump_cooldown > 0.0 else 1.0
	cooldowns_changed.emit(clamp(dash_ratio, 0.0, 1.0), clamp(knife_ratio, 0.0, 1.0), clamp(stealth_ratio, 0.0, 1.0), clamp(air_jump_ratio, 0.0, 1.0))
