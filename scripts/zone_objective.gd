extends Node3D
class_name ZoneObjective

signal objective_state_changed(active: bool, time_left: float, inside_time: float)

@export var player_path: NodePath
@export var active_duration: float = 15.0
@export var downtime_duration: float = 2.0
@export var zone_radius: float = 3.6
@export var point_tick_interval: float = 1.0
@export var base_points_per_tick: int = 1
@export var bounds_min: Vector2 = Vector2(-54.0, -54.0)
@export var bounds_max: Vector2 = Vector2(54.0, 54.0)

var _rng := RandomNumberGenerator.new()
var _player: Node3D
var _phase_timer := 0.0
var _point_tick_timer := 0.0
var _inside_time := 0.0
var _inside := false
var _active := true

@onready var zone_area: Area3D = $ZoneArea
@onready var zone_collision: CollisionShape3D = $ZoneArea/CollisionShape3D
@onready var zone_mesh: MeshInstance3D = $ZoneMesh

func _ready() -> void:
	_rng.randomize()
	if player_path != NodePath():
		_player = get_node_or_null(player_path)
	if zone_collision.shape is SphereShape3D:
		(zone_collision.shape as SphereShape3D).radius = zone_radius
	if zone_mesh.mesh is CylinderMesh:
		(zone_mesh.mesh as CylinderMesh).top_radius = zone_radius
		(zone_mesh.mesh as CylinderMesh).bottom_radius = zone_radius
	zone_area.body_entered.connect(_on_body_entered)
	zone_area.body_exited.connect(_on_body_exited)
	_start_active_phase()

func _physics_process(delta: float) -> void:
	_phase_timer += delta
	if _active:
		_process_active(delta)
	else:
		_process_downtime()

func _process_active(delta: float) -> void:
	if _phase_timer >= active_duration:
		_start_downtime_phase()
		return

	if _inside and _player != null and is_instance_valid(_player):
		_inside_time += delta
		_point_tick_timer += delta
		if _point_tick_timer >= point_tick_interval:
			_point_tick_timer = 0.0
			var bonus := int(floor(_inside_time / 4.0))
			if _player.has_method("add_objective_points"):
				_player.call("add_objective_points", base_points_per_tick + bonus)

	objective_state_changed.emit(true, active_duration - _phase_timer, _inside_time)

func _process_downtime() -> void:
	if _phase_timer >= downtime_duration:
		_start_active_phase()
		return
	objective_state_changed.emit(false, downtime_duration - _phase_timer, 0.0)

func _start_active_phase() -> void:
	_active = true
	_phase_timer = 0.0
	_inside = false
	_inside_time = 0.0
	_point_tick_timer = 0.0
	zone_area.monitoring = true
	zone_mesh.visible = true
	_relocate_zone_within_bounds()
	objective_state_changed.emit(true, active_duration, 0.0)

func _start_downtime_phase() -> void:
	_active = false
	_phase_timer = 0.0
	_inside = false
	_inside_time = 0.0
	_point_tick_timer = 0.0
	zone_area.monitoring = false
	zone_mesh.visible = false
	objective_state_changed.emit(false, downtime_duration, 0.0)

func _relocate_zone_within_bounds() -> void:
	var x := _rng.randf_range(bounds_min.x + zone_radius, bounds_max.x - zone_radius)
	var z := _rng.randf_range(bounds_min.y + zone_radius, bounds_max.y - zone_radius)
	global_position = Vector3(x, 0.15, z)

func _on_body_entered(body: Node) -> void:
	if not _active:
		return
	if body == _player:
		_inside = true
		_inside_time = 0.0
		_point_tick_timer = 0.0

func _on_body_exited(body: Node) -> void:
	if body == _player:
		_inside = false
		_inside_time = 0.0
		_point_tick_timer = 0.0
