extends Node3D
class_name EnemySpawner

@export var enemy_scene: PackedScene
@export var player_path: NodePath
@export var spawn_interval: float = 0.45
@export var spawn_per_wave: int = 5
@export var max_alive: int = 180
@export var min_spawn_radius: float = 16.0
@export var max_spawn_radius: float = 30.0
@export var wave_ramp_time: float = 45.0

var _timer := 0.0
var _elapsed := 0.0
var _rng := RandomNumberGenerator.new()
var _player: PlayerController

func _ready() -> void:
	_rng.randomize()
	if player_path != NodePath():
		_player = get_node_or_null(player_path)

func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if not _player.is_inside_tree() or _player.health <= 0.0:
		return

	_elapsed += delta
	_timer += delta
	if _timer >= spawn_interval:
		_timer = 0.0
		_spawn_wave()

func _spawn_wave() -> void:
	if enemy_scene == null:
		return
	var alive := get_tree().get_nodes_in_group("enemy").size()
	if alive >= max_alive:
		return
	var wave_bonus := int(_elapsed / wave_ramp_time)
var count: int = int(min(spawn_per_wave + wave_bonus, max_alive - alive))
for i in count:
	var enemy := enemy_scene.instantiate() as EnemyUnit
		if enemy == null:
			continue
		var pos := _pick_spawn_position()
		enemy.global_position = pos
		enemy.target = _player
		add_child(enemy)

func _pick_spawn_position() -> Vector3:
	var angle := _rng.randf_range(0.0, TAU)
	var radius := _rng.randf_range(min_spawn_radius, max_spawn_radius)
	var offset := Vector3(cos(angle), 0.0, sin(angle)) * radius
	var pos := _player.global_position + offset
	pos.y = 1.2
	return pos
