extends Node3D
class_name ZoneObjective

@export var player_path: NodePath
@export var move_interval: float = 15.0
@export var min_radius: float = 10.0
@export var max_radius: float = 36.0
@export var zone_radius: float = 3.6
@export var point_tick_interval: float = 1.0
@export var base_points_per_tick: int = 1

var _rng := RandomNumberGenerator.new()
var _player: PlayerController
var _move_timer := 0.0
var _point_tick_timer := 0.0
var _inside_time := 0.0
var _inside := false

@onready var zone_area: Area3D = $ZoneArea
@onready var zone_collision: CollisionShape3D = $ZoneArea/CollisionShape3D

func _ready() -> void:
	_rng.randomize()
	if player_path != NodePath():
		_player = get_node_or_null(player_path)
	if zone_collision.shape is SphereShape3D:
		(zone_collision.shape as SphereShape3D).radius = zone_radius
	zone_area.body_entered.connect(_on_body_entered)
	zone_area.body_exited.connect(_on_body_exited)
	_relocate_zone()

func _physics_process(delta: float) -> void:
	_move_timer += delta
	if _move_timer >= move_interval:
		_move_timer = 0.0
		_relocate_zone()

	if not _inside or _player == null:
		return

	_inside_time += delta
	_point_tick_timer += delta
	if _point_tick_timer >= point_tick_interval:
		_point_tick_timer = 0.0
		var bonus := int(floor(_inside_time / 4.0))
		_player.add_objective_points(base_points_per_tick + bonus)

func _relocate_zone() -> void:
	_inside = false
	_inside_time = 0.0
	_point_tick_timer = 0.0
	if _player == null or not is_instance_valid(_player):
		return
	var angle := _rng.randf_range(0.0, TAU)
	var radius := _rng.randf_range(min_radius, max_radius)
	var offset := Vector3(cos(angle), 0.0, sin(angle)) * radius
	global_position = _player.global_position + offset
	global_position.y = 0.15

func _on_body_entered(body: Node) -> void:
	if body == _player:
		_inside = true
		_inside_time = 0.0
		_point_tick_timer = 0.0

func _on_body_exited(body: Node) -> void:
	if body == _player:
		_inside = false
		_inside_time = 0.0
		_point_tick_timer = 0.0
