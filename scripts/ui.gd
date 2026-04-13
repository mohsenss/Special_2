extends CanvasLayer
class_name GameUI

@onready var health_bar: ProgressBar = $HUD/Margin/TopRow/HealthBar
@onready var health_label: Label = $HUD/Margin/TopRow/HealthLabel
@onready var kill_label: Label = $HUD/Margin/TopRow/KillLabel
@onready var score_label: Label = $HUD/Margin/TopRow/ScoreLabel
@onready var stealth_status_label: Label = $HUD/Margin/TopRow/StealthStatusLabel
@onready var objective_time_left_label: Label = $HUD/Margin/ObjectivePanel/VBox/TimeLeft
@onready var objective_inside_label: Label = $HUD/Margin/ObjectivePanel/VBox/InsideTime
@onready var game_over_panel: PanelContainer = $GameOver

var dash_cd_bar: ProgressBar
var knife_cd_bar: ProgressBar
var stealth_cd_bar: ProgressBar
var air_jump_cd_bar: ProgressBar

func _ready() -> void:
	game_over_panel.visible = false
	dash_cd_bar = _resolve_bar("DashCooldown")
	knife_cd_bar = _resolve_bar("KnifeCooldown")
	stealth_cd_bar = _resolve_bar("StealthCooldown")
	air_jump_cd_bar = _resolve_bar("AirJumpCooldown")
	for bar in [dash_cd_bar, knife_cd_bar, stealth_cd_bar, air_jump_cd_bar]:
		if bar:
			bar.value = 100.0
	update_objective_status(false, 0.0, 0.0)

func _resolve_bar(name: String) -> ProgressBar:
	var bar := get_node_or_null("HUD/Margin/BottomCooldowns/%s" % name) as ProgressBar
	if bar:
		return bar
	bar = get_node_or_null("HUD/Margin/AbilityRow/%s" % name) as ProgressBar
	if bar:
		return bar
	return get_node_or_null("HUD/Margin/AbilityColumn/%s" % name) as ProgressBar

func update_health(current: float, max_health: float) -> void:
	health_bar.max_value = max_health
	health_bar.value = current
	health_label.text = "HP: %d / %d" % [int(current), int(max_health)]

func update_kills(value: int) -> void:
	kill_label.text = "Kills: %d" % value

func update_score(value: int) -> void:
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
	stealth_status_label.text = "Stealth: ON" if is_stealthed_now else "Stealth: OFF"

func update_objective_status(active: bool, time_left: float, inside_time: float) -> void:
	if not active:
		objective_time_left_label.text = "Zone: next in %.1fs" % max(time_left, 0.0)
		objective_inside_label.text = "Inside: %.1fs" % 0.0
		return
	objective_time_left_label.text = "Zone ends in: %.1fs" % max(time_left, 0.0)
	objective_inside_label.text = "Inside: %.1fs" % max(inside_time, 0.0)

func show_game_over() -> void:
	game_over_panel.visible = true
