extends CharacterBody2D

const SPEED = 80.0
const JUMP_VELOCITY = -280.0
const ATTACK_DAMAGE = 15

var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")
var player: CharacterBody2D = null

var health: int = 50

var is_attacking: bool = false
var is_dead: bool = false
var can_attack: bool = true
var is_damaged: bool = false

@onready var animated_sprite = $AnimatedSprite2D
@onready var wall_check = $WallCheck
@onready var ledge_check = $LedgeCheck
@onready var attack_area = $AttackArea

@onready var attack_collision = $AttackArea/CollisionShape2D
var attack_collision_offset_x: float

func _ready() -> void:
	var current_map = get_tree().current_scene.name
	if GameManager.dead_enemies.has(current_map):
		if name in GameManager.dead_enemies[current_map]:
			queue_free()

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	if is_damaged:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		move_and_slide()
		return

	if is_attacking:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		move_and_slide()
		return

	if player:
		var is_in_attack_range = false
		for body in attack_area.get_overlapping_bodies():
			if body.is_in_group("player"):
				is_in_attack_range = true
				break

		if is_in_attack_range:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			if is_on_floor():
				animated_sprite.play("idle")
			if can_attack:
				start_attack_sequence()
		else:
			var direction = sign(player.global_position.x - global_position.x)
			velocity.x = direction * SPEED

			if direction != 0:
				update_facing(direction)

				wall_check.target_position = Vector2(direction * 30, 0)

				ledge_check.position.x = abs(ledge_check.position.x) * direction
				ledge_check.target_position = Vector2(0, 65)

				wall_check.force_raycast_update()
				ledge_check.force_raycast_update()

			if is_on_floor():
				var hit_wall = wall_check.is_colliding()
				var hit_ledge = not ledge_check.is_colliding()

				if hit_wall or hit_ledge:
					velocity.y = JUMP_VELOCITY
					velocity.x = sign(player.global_position.x - global_position.x) * (SPEED * 2)

			if is_on_floor():
				animated_sprite.play("run")
			else:
				animated_sprite.play("jump")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if is_on_floor():
			animated_sprite.play("idle")

	move_and_slide()

func update_facing(direction: float) -> void:
	if direction == 0:
		return
	
	animated_sprite.flip_h = direction < 0

	if direction < 0:
		attack_collision.position.x = -attack_collision_offset_x
	else:
		attack_collision.position.x = attack_collision_offset_x

func start_attack_sequence() -> void:
	can_attack = false
	is_attacking = true
	animated_sprite.play("slash")

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = null

func _on_animated_sprite_2d_frame_changed() -> void:
	if not animated_sprite or not is_instance_valid(animated_sprite):
		return

	if animated_sprite.animation == "slash" and animated_sprite.frame == 3:
		for body in attack_area.get_overlapping_bodies():
			if body.is_in_group("player") and body.has_method("take_damage"):
				body.take_damage(ATTACK_DAMAGE)
				break

func take_damage(amount: int) -> void:
	is_damaged = true
	is_attacking = false
	can_attack = false
	
	health -= amount
	print('Enemy kena damage, sisa HP: ', health)
	
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	
	if health <= 0:
		die()
	else:
		animated_sprite.play("damaged")
		
func die() -> void:
	var current_map = get_tree().current_scene.name
	
	if not GameManager.dead_enemies.has(current_map):
		GameManager.dead_enemies[current_map] = []
		
	if not (name in GameManager.dead_enemies[current_map]):
		GameManager.dead_enemies[current_map].append(name)
	
	is_dead = true
	velocity = Vector2.ZERO
	animated_sprite.play("death")
	
	await get_tree().create_timer(0.5).timeout
	queue_free()

func _on_animated_sprite_2d_animation_finished() -> void:
	if not animated_sprite or not is_instance_valid(animated_sprite):
		return

	if animated_sprite.animation == "slash":
		is_attacking = false
		
		await get_tree().create_timer(0.2).timeout # attack speed
		can_attack = true
		
	if animated_sprite.animation == "damaged":
		is_damaged = false
		can_attack = true
