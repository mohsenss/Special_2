extends CanvasLayer
class_name GameUI

@onready var health_bar: ProgressBar = $HUD/Margin/TopRow/HealthBar
@onready var health_label: Label = $HUD/Margin/TopRow/HealthLabel
@onready var kill_label: Label = $HUD/Margin/TopRow/KillLabel
@onready var dash_cd_bar: ProgressBar = $HUD/Margin/AbilityRow/DashCooldown
@onready var stealth_cd_bar: ProgressBar = $HUD/Margin/AbilityRow/StealthCooldown
@onready var stealth_state: Label = $HUD/Margin/AbilityRow/StealthState
@onready var game_over_panel: PanelContainer = $GameOver

func _ready() -> void:
	game_over_panel.visible = false
	dash_cd_bar.value = 100
	stealth_cd_bar.value = 100

func update_health(current: float, max_health: float) -> void:
	health_bar.max_value = max_health
	health_bar.value = current
	health_label.text = "HP: %d / %d" % [int(current), int(max_health)]

func update_kills(value: int) -> void:
	kill_label.text = "Kills: %d" % value

func update_cooldowns(dash_ratio: float, stealth_ratio: float, stealth_active: bool) -> void:
	dash_cd_bar.value = dash_ratio * 100.0
	stealth_cd_bar.value = stealth_ratio * 100.0
	stealth_state.text = "STEALTH ACTIVE" if stealth_active else "Stealth Ready" if stealth_ratio >= 1.0 else "Stealth Cooling"

func show_game_over() -> void:
	game_over_panel.visible = true
