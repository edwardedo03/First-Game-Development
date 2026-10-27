
extends CharacterBody2D

const SPEED = 30.0
const JUMP_VELOCITY = -280.0

@export var chase_range: float = 200.0
@export var return_tolerance: float = 5.0

@export var attack_damage: int = 10
@export var attack_cooldown: float = 1

var can_attack: bool = true
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var player: CharacterBody2D = null

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_collision: CollisionShape2D = $AttackArea/CollisionShape2D

@export var patrol_left: float = 20.0
@export var patrol_right: float = 20.0

var attack_collision_offset_x: float
var spawn_position: Vector2
var patrol_direction: float = 1.0
var is_patrolling: bool = true

func _ready() -> void:
	spawn_position = global_position
	
	attack_collision_offset_x = absf(attack_collision.position.x)

	var current_map = get_tree().current_scene.scene_file_path
	if GameManager.dead_enemies.has(current_map):
		if name in GameManager.dead_enemies[current_map]:
			queue_free()
			return

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	# Musuh tetap patroli kiri-kanan
	patrol()

	# Kalau player masuk area serang, serang
	var bodies = attack_area.get_overlapping_bodies()

	for body in bodies:
		if body.is_in_group("player"):
			velocity.x = 0.0

			if is_on_floor() and animated_sprite.animation != "slash":
				animated_sprite.play("slash")

			if can_attack:
				attack_player()
			break

	move_and_slide()

func move_toward_spawn() -> void:
	var direction: float = signf(spawn_position.x - global_position.x)
	velocity.x = direction * SPEED

	if direction != 0:
		update_facing(direction)

	if is_on_floor():
		if direction != 0:
			animated_sprite.play("run")
		else:
			animated_sprite.play("idle")

func update_facing(direction: float) -> void:
	if direction == 0:
		return

	animated_sprite.flip_h = direction < 0
	
	if direction < 0:
		attack_collision.position.x = -attack_collision_offset_x
	else:
		attack_collision.position.x = attack_collision_offset_x
	
func patrol() -> void:
	var left_bound: float = spawn_position.x - patrol_left
	var right_bound: float = spawn_position.x + patrol_right

	if global_position.x <= left_bound:
		patrol_direction = 1.0
	elif global_position.x >= right_bound:
		patrol_direction = -1.0

	velocity.x = patrol_direction * SPEED

	update_facing(patrol_direction)

	if is_on_floor() and animated_sprite.animation != "slash":
		animated_sprite.play("run")

func attack_player() -> void:
	if not can_attack:
		return

	can_attack = false

	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("player"):
			if body.has_method("take_damage"):
				body.take_damage(attack_damage)
			break

	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
