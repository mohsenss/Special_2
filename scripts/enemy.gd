extends CharacterBody3D
class_name EnemyUnit

@export var max_health: float = 100.0
@export var move_speed: float = 5.2
@export var acceleration: float = 16.0
@export var touch_damage: float = 11.0
@export var attack_interval: float = 0.85
@export var detection_range: float = 80.0
@export var deaggro_range: float = 120.0
@export var despawn_distance: float = 42.0
@export var despawn_time: float = 4.0

var health: float
var gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
var target: PlayerController
var _attack_cd := 0.0
var _external_knockback: Vector3 = Vector3.ZERO
const MAX_KNOCKBACK := 12.0
var _far_timer := 0.0

func _ready() -> void:
	health = max_health
	add_to_group("enemy")

func _physics_process(delta: float) -> void:
	_attack_cd = max(_attack_cd - delta, 0.0)

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	if target == null or not is_instance_valid(target):
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
		move_and_slide()
		return

	if target.is_stealthed():
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
		move_and_slide()
		return

	var to_player: Vector3 = target.global_transform.origin - global_transform.origin
	var planar: Vector3 = Vector3(to_player.x, 0.0, to_player.z)
	var dist: float = planar.length()

	if dist > despawn_distance:
		_far_timer += delta
		if _far_timer >= despawn_time:
			_request_replacement()
			queue_free()
			return
	else:
		_far_timer = 0.0

	if dist > deaggro_range:
		queue_free()
		return

	if dist < detection_range:
		var dir: Vector3 = planar.normalized() if dist > 0.001 else Vector3.ZERO
		velocity.x = move_toward(velocity.x, dir.x * move_speed + _external_knockback.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, dir.z * move_speed + _external_knockback.z, acceleration * delta)
		look_at(global_transform.origin + dir, Vector3.UP)

		var vertical_gap: float = absf(to_player.y)
		if dist <= 1.65 and vertical_gap <= 1.1 and _attack_cd <= 0.0:
			_attack_cd = attack_interval
			target.take_damage(touch_damage)

	_external_knockback = _external_knockback.move_toward(Vector3.ZERO, 24.0 * delta)
	move_and_slide()

func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO) -> void:
	health -= amount
	_external_knockback += Vector3(knockback.x, 0.0, knockback.z)
	_external_knockback = _external_knockback.limit_length(MAX_KNOCKBACK)
	if health <= 0.0:
		if target and is_instance_valid(target):
			target.register_kill()
		queue_free()

func _request_replacement() -> void:
	var spawners := get_tree().get_nodes_in_group("enemy_spawner")
	if spawners.is_empty():
		return
	var spawner := spawners[0] as EnemySpawner
	if spawner:
		spawner.request_replacement()
