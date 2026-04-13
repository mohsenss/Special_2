extends CanvasLayer
class_name GameUI

@onready var health_bar: ProgressBar = $HUD/Margin/TopRow/HealthBar
@onready var health_label: Label = $HUD/Margin/TopRow/HealthLabel
@onready var kill_label: Label = $HUD/Margin/TopRow/KillLabel
@onready var score_label: Label = $HUD/Margin/TopRow/ScoreLabel
@onready var stealth_status_label: Label = $HUD/Margin/TopRow/StealthStatusLabel
@onready var dash_cd_bar: ProgressBar = $HUD/Margin/BottomCenter/AbilityBars/DashCooldown
@onready var knife_cd_bar: ProgressBar = $HUD/Margin/BottomCenter/AbilityBars/KnifeCooldown
@onready var stealth_cd_bar: ProgressBar = $HUD/Margin/BottomCenter/AbilityBars/StealthCooldown
@onready var air_jump_cd_bar: ProgressBar = $HUD/Margin/BottomCenter/AbilityBars/AirJumpCooldown
@onready var zone_timer_label: Label = $HUD/Margin/TopRight/ZoneTimerLabel
@onready var zone_progress_label: Label = $HUD/Margin/TopRight/ZoneProgressLabel
@onready var game_over_panel: PanelContainer = $GameOver

func _ready() -> void:
	game_over_panel.visible = false
	for bar in [dash_cd_bar, knife_cd_bar, stealth_cd_bar, air_jump_cd_bar]:
		bar.value = 100.0
	update_zone_status(0.0, 0.0, false)

func update_health(current: float, max_health: float) -> void:
	health_bar.max_value = max_health
	health_bar.value = current
	health_label.text = "HP: %d / %d" % [int(current), int(max_health)]

func update_kills(value: int) -> void:
	kill_label.text = "Kills: %d" % value

func update_score(value: int) -> void:
	score_label.text = "Score: %d" % value

func update_cooldowns(dash_ratio: float, knife_ratio: float, stealth_ratio: float, air_jump_ratio: float, is_stealthed_now: bool) -> void:
	dash_cd_bar.value = dash_ratio * 100.0
	knife_cd_bar.value = knife_ratio * 100.0
	stealth_cd_bar.value = stealth_ratio * 100.0
	air_jump_cd_bar.value = air_jump_ratio * 100.0
	stealth_status_label.text = "Stealth: ON" if is_stealthed_now else "Stealth: OFF"

func update_zone_status(time_left: float, inside_seconds: float, active: bool) -> void:
	if active:
		zone_timer_label.text = "Zone: %.1fs" % max(time_left, 0.0)
		zone_progress_label.text = "Inside: %.1fs" % max(inside_seconds, 0.0)
	else:
		zone_timer_label.text = "Zone: incoming"
		zone_progress_label.text = "Inside: 0.0s"

func show_game_over() -> void:
	game_over_panel.visible = true
