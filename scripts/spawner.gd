extends Node3D
class_name EnemySpawner

@export var enemy_scene: PackedScene
@export var player_path: NodePath
@export var spawn_interval: float = 0.8
@export var spawn_per_wave: int = 2
@export var desired_alive: int = 28
@export var max_alive: int = 36
@export var min_spawn_radius: float = 16.0
@export var max_spawn_radius: float = 30.0

var _timer := 0.0
var _rng := RandomNumberGenerator.new()
var _player: PlayerController

func _ready() -> void:
	_rng.randomize()
	add_to_group("enemy_spawner")
	if player_path != NodePath():
		_player = get_node_or_null(player_path)

func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if not _player.is_inside_tree() or _player.health <= 0.0:
		return

	var alive := get_tree().get_nodes_in_group("enemy").size()
	if alive < desired_alive:
		_spawn_batch(min(spawn_per_wave, desired_alive - alive))

	_timer += delta
	if _timer >= spawn_interval:
		_timer = 0.0
		alive = get_tree().get_nodes_in_group("enemy").size()
		if alive < desired_alive:
			_spawn_batch(min(spawn_per_wave, desired_alive - alive))

func request_replacement() -> void:
	var alive := get_tree().get_nodes_in_group("enemy").size()
	if alive < desired_alive:
		_spawn_one()

func _spawn_batch(count: int) -> void:
	for i in count:
		_spawn_one()

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
	enemy.target = _player
	add_child(enemy)

func _pick_spawn_position() -> Vector3:
	var angle := _rng.randf_range(0.0, TAU)
	var radius := _rng.randf_range(min_spawn_radius, max_spawn_radius)
	var offset := Vector3(cos(angle), 0.0, sin(angle)) * radius
	var pos := _player.global_position + offset
	pos.y = 1.2
	return pos
