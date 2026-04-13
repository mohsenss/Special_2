extends Node3D
class_name ZoneObjective

signal zone_status_changed(time_left: float, inside_seconds: float, active: bool)

@export var player_path: NodePath
@export var move_interval: float = 15.0
@export var intermission_time: float = 2.0
@export var map_half_extent: float = 58.0
@export var edge_padding: float = 6.0
@export var zone_radius: float = 3.6
@export var point_tick_interval: float = 1.0
@export var base_points_per_tick: int = 1

var _rng := RandomNumberGenerator.new()
var _player: PlayerController
var _cycle_timer := 0.0
var _point_tick_timer := 0.0
var _inside_time := 0.0
var _inside := false
var _active := true

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
	_activate_zone()

func _physics_process(delta: float) -> void:
	_cycle_timer += delta
	if _active and _cycle_timer >= move_interval:
		_deactivate_zone()
	elif not _active and _cycle_timer >= intermission_time:
		_activate_zone()

	if not _active or not _inside or _player == null:
		_emit_status()
		return

	_inside_time += delta
	_point_tick_timer += delta
	if _point_tick_timer >= point_tick_interval:
		_point_tick_timer = 0.0
		var bonus := int(floor(_inside_time / 4.0))
		_player.add_objective_points(base_points_per_tick + bonus)
	_emit_status()

func _activate_zone() -> void:
	_active = true
	_cycle_timer = 0.0
	_inside = false
	_inside_time = 0.0
	_point_tick_timer = 0.0
	visible = true
	zone_area.monitoring = true
	_relocate_zone()
	_emit_status()

func _deactivate_zone() -> void:
	_active = false
	_cycle_timer = 0.0
	_inside = false
	_inside_time = 0.0
	_point_tick_timer = 0.0
	zone_area.monitoring = false
	visible = false
	_emit_status()

func _relocate_zone() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var max_range := map_half_extent - edge_padding - zone_radius
	var min_x := -max_range
	var max_x := max_range
	var min_z := -max_range
	var max_z := max_range
	global_position = Vector3(
		_rng.randf_range(min_x, max_x),
		0.15,
		_rng.randf_range(min_z, max_z)
	)

func _emit_status() -> void:
	var time_left := move_interval - _cycle_timer if _active else intermission_time - _cycle_timer
	zone_status_changed.emit(max(time_left, 0.0), _inside_time, _active)

func _on_body_entered(body: Node) -> void:
	if _active and body == _player:
		_inside = true
		_inside_time = 0.0
		_point_tick_timer = 0.0

func _on_body_exited(body: Node) -> void:
	if body == _player:
		_inside = false
		_inside_time = 0.0
		_point_tick_timer = 0.0
