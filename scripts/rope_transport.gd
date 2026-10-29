extends Node2D

@export var rope_speed: float = 150.0

@onready var interact_area: Area2D = $InteractArea
@onready var rope_start: Marker2D = $RopeStart
@onready var rope_end: Marker2D = $RopeEnd

var player_nearby: CharacterBody2D = null

func _ready() -> void:
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if not is_instance_valid(player_nearby):
		return

	if Input.is_action_just_pressed("interact"):
		if not player_nearby.is_using_rope:
			start_transport(player_nearby)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.is_in_group("player"):
		player_nearby = body

func _on_body_exited(body: Node2D) -> void:
	if body == player_nearby:
		player_nearby = null

func start_transport(player: CharacterBody2D) -> void:
	var distance_to_start := player.global_position.distance_to(
		rope_start.global_position
	)

	var distance_to_end := player.global_position.distance_to(
		rope_end.global_position
	)

	var start_pos: Vector2

	if distance_to_start <= distance_to_end:
		start_pos = rope_start.global_position
	else:
		start_pos = rope_end.global_position

	player.start_rope_transport(
		start_pos,
		rope_end.global_position if start_pos == rope_start.global_position
		else rope_start.global_position,
		rope_speed
	)
