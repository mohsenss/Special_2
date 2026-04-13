extends CanvasLayer
class_name GameUI

@onready var health_bar: ProgressBar = $HUD/Margin/TopRow/HealthBar
@onready var health_label: Label = $HUD/Margin/TopRow/HealthLabel
@onready var kill_label: Label = $HUD/Margin/TopRow/KillLabel
@onready var score_label: Label = $HUD/Margin/TopRow/ScoreLabel
@onready var dash_cd_bar: ProgressBar = $HUD/Margin/AbilityColumn/DashCooldown
@onready var knife_cd_bar: ProgressBar = $HUD/Margin/AbilityColumn/KnifeCooldown
@onready var stealth_cd_bar: ProgressBar = $HUD/Margin/AbilityColumn/StealthCooldown
@onready var air_jump_cd_bar: ProgressBar = $HUD/Margin/AbilityColumn/AirJumpCooldown
@onready var game_over_panel: PanelContainer = $GameOver

func _ready() -> void:
	game_over_panel.visible = false
	dash_cd_bar.value = 100
	knife_cd_bar.value = 100
	stealth_cd_bar.value = 100
	air_jump_cd_bar.value = 100

func update_health(current: float, max_health: float) -> void:
	health_bar.max_value = max_health
	health_bar.value = current
	health_label.text = "HP: %d / %d" % [int(current), int(max_health)]

func update_kills(value: int) -> void:
	kill_label.text = "Kills: %d" % value

func update_score(value: int) -> void:
	score_label.text = "Score: %d" % value

func update_cooldowns(dash_ratio: float, knife_ratio: float, stealth_ratio: float, air_jump_ratio: float) -> void:
	dash_cd_bar.value = dash_ratio * 100.0
	knife_cd_bar.value = knife_ratio * 100.0
	stealth_cd_bar.value = stealth_ratio * 100.0
	air_jump_cd_bar.value = air_jump_ratio * 100.0

func show_game_over() -> void:
	game_over_panel.visible = true
