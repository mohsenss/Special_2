extends Node
class_name GameManager

@export var player_path: NodePath
@export var ui_path: NodePath
@export var objective_path: NodePath

var player: PlayerController
var ui: GameUI
var objective: ZoneObjective

func _ready() -> void:
	player = get_node_or_null(player_path)
	ui = get_node_or_null(ui_path)
	objective = get_node_or_null(objective_path)
	if player and ui:
		player.health_changed.connect(ui.update_health)
		player.kill_count_changed.connect(ui.update_kills)
		player.score_changed.connect(ui.update_score)
		player.cooldowns_changed.connect(ui.update_cooldowns)
		player.player_died.connect(_on_player_died)
		ui.update_health(player.health, player.max_health)
		ui.update_kills(player.kill_count)
		ui.update_score(player.score)
		ui.update_cooldowns(1.0, 1.0, 1.0, 1.0, false)
	if objective and ui:
		objective.objective_state_changed.connect(ui.update_objective_status)

func _on_player_died() -> void:
	if ui:
		ui.show_game_over()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		get_tree().reload_current_scene()
