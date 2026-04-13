extends CanvasLayer
class_name GameUI

@onready var health_bar: ProgressBar = $HUD/Margin/TopRow/HealthBar
@onready var health_label: Label = $HUD/Margin/TopRow/HealthLabel
@onready var kill_label: Label = $HUD/Margin/TopRow/KillLabel
@onready var score_label: Label = $HUD/Margin/TopRow/ScoreLabel
@onready var dash_cd_bar: ProgressBar = get_node_or_null("HUD/Margin/AbilityColumn/DashCooldown") as ProgressBar
@onready var knife_cd_bar: ProgressBar = get_node_or_null("HUD/Margin/AbilityColumn/KnifeCooldown") as ProgressBar
@onready var stealth_cd_bar: ProgressBar = get_node_or_null("HUD/Margin/AbilityColumn/StealthCooldown") as ProgressBar
@onready var air_jump_cd_bar: ProgressBar = get_node_or_null("HUD/Margin/AbilityColumn/AirJumpCooldown") as ProgressBar
@onready var stealth_status_label: Label = get_node_or_null("HUD/Margin/TopRow/StealthStatusLabel") as Label
@onready var game_over_panel: PanelContainer = $GameOver

func _ready() -> void:
	game_over_panel.visible = false
	if dash_cd_bar == null:
		dash_cd_bar = get_node_or_null("HUD/Margin/AbilityRow/DashCooldown") as ProgressBar
	if knife_cd_bar == null:
		knife_cd_bar = get_node_or_null("HUD/Margin/AbilityRow/KnifeCooldown") as ProgressBar
	if stealth_cd_bar == null:
		stealth_cd_bar = get_node_or_null("HUD/Margin/AbilityRow/StealthCooldown") as ProgressBar
	if air_jump_cd_bar == null:
		air_jump_cd_bar = get_node_or_null("HUD/Margin/AbilityRow/AirJumpCooldown") as ProgressBar
	if dash_cd_bar:
		dash_cd_bar.value = 100
	if knife_cd_bar:
		knife_cd_bar.value = 100
	if stealth_cd_bar:
		stealth_cd_bar.value = 100
	if air_jump_cd_bar:
		air_jump_cd_bar.value = 100

func update_health(current: float, max_health: float) -> void:
	health_bar.max_value = max_health
	health_bar.value = current
	health_label.text = "HP: %d / %d" % [int(current), int(max_health)]

func update_kills(value: int) -> void:
	kill_label.text = "Kills: %d" % value

func update_score(value: int) -> void:
	if score_label:
		score_label.text = "Score: %d" % value

func update_cooldowns(dash_ratio: float, knife_ratio: float, stealth_ratio: float, air_jump_ratio: float = 1.0, is_stealthed_now: bool = false) -> void:
	if dash_cd_bar:
		dash_cd_bar.value = dash_ratio * 100.0
	if knife_cd_bar:
		knife_cd_bar.value = knife_ratio * 100.0
	if stealth_cd_bar:
		stealth_cd_bar.value = stealth_ratio * 100.0
	if air_jump_cd_bar:
		air_jump_cd_bar.value = air_jump_ratio * 100.0
	if stealth_status_label:
		stealth_status_label.text = "Stealth: ON" if is_stealthed_now else "Stealth: OFF"

func show_game_over() -> void:
	game_over_panel.visible = true
