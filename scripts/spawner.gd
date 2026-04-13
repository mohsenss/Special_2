extends Node3D
class_name EnemySpawner

@export var enemy_scene: PackedScene
@export var player_path: NodePath
@export var spawn_interval: float = 0.5
@export var spawn_batch: int = 3
@export var desired_alive: int = 24
@export var max_alive: int = 36
@export var min_spawn_radius: float = 16.0
@export var max_spawn_radius: float = 30.0

var _timer := 0.0
var _rng := RandomNumberGenerator.new()
var _player: Node3D

func _ready() -> void:
	_rng.randomize()
	add_to_group("enemy_spawner")
	if player_path != NodePath():
		_player = get_node_or_null(player_path)

func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if not _player.is_inside_tree() or float(_player.get("health")) <= 0.0:
		return

	_timer += delta
	if _timer >= spawn_interval:
		_timer = 0.0
		_fill_to_target()

func _fill_to_target() -> void:
	if enemy_scene == null:
		return
	var alive := get_tree().get_nodes_in_group("enemy").size()
	if alive >= desired_alive:
		return
	var missing := mini(desired_alive - alive, spawn_batch)
	for i in range(missing):
		_spawn_one()

func request_replacement() -> void:
	_fill_to_target()

func _spawn_one() -> void:
	if enemy_scene == null:
		return
	var alive := get_tree().get_nodes_in_group("enemy").size()
	if alive >= max_alive:
		return
	var enemy := enemy_scene.instantiate() as EnemyUnit
	if enemy == null:
		return
	enemy.global_position = _pick_spawn_position()
	enemy.target = _player as PlayerController
	add_child(enemy)

func _pick_spawn_position() -> Vector3:
	var angle := _rng.randf_range(0.0, TAU)
	var radius := _rng.randf_range(min_spawn_radius, max_spawn_radius)
	var offset := Vector3(cos(angle), 0.0, sin(angle)) * radius
	var pos := _player.global_position + offset
	pos.y = 1.2
	return pos
