extends Node
class_name GameManager

@export var player_path: NodePath
@export var ui_path: NodePath

var player: PlayerController
var ui: GameUI

func _ready() -> void:
	player = get_node_or_null(player_path)
	ui = get_node_or_null(ui_path)
	if player and ui:
		player.health_changed.connect(ui.update_health)
		player.kill_count_changed.connect(ui.update_kills)
		player.cooldowns_changed.connect(ui.update_cooldowns)
		player.player_died.connect(_on_player_died)

func _on_player_died() -> void:
	if ui:
		ui.show_game_over()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		if player and player.health <= 0.0:
			get_tree().reload_current_scene()
