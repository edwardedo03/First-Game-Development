extends CharacterBody2D

const SPEED = 130.0
const RUN_SPEED = 200
const JUMP_VELOCITY = -280.0
const FALL_DAMAGE_THRESHOLD = 420.0
const CLIMB_SPEED = 80.0 #LADDER

var max_health: int = 100
var current_health: int = 100

var max_stamina: float = 100.0
var current_stamina: float = 100.0
var stamina_drain: float = 30.0
var stamina_regen: float = 10.0

var is_stamina_exhausted: bool = false

var max_jumps: int = 1
var jump_count: int = 0
var previous_y_velocity: float = 0.0

@onready var attack_area = $AttackArea
@onready var attack_collision = $AttackArea/CollisionShape2D
var attack_collision_offset_x: float
const PLAYER_ATTACK_DAMAGE = 5

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D #LADDER

@export var hud: CanvasLayer
@export var ladder_layer: TileMapLayer #LADDER (import tilemap ke char)
@export var feet_margin := 2.0 #LADDER (biar ada jarak kaki ke bawah, supaya seluruh badan char ketika naik tangga full diatas tangga)

var is_attacking: bool = false
var is_running: bool = false
var is_hurt: bool = false
var is_dead: bool = false
var is_climbing := false #LADDER
var feet_y := 0.0 #LADDER (ngitung jarak dari titik pusat ke kaki)

func _ready() -> void:
	attack_collision_offset_x = abs(attack_collision.position.x)
	
	var shape = collision.shape

	if shape is RectangleShape2D:
		feet_y = collision.position.y + shape.size.y / 2.0
	elif shape is CapsuleShape2D:
		feet_y = collision.position.y + shape.height / 2.0
	
	#var rect_shape := collision.shape as RectangleShape2D #LADDER (dipake buat pengukuran aja)
	#if rect_shape: #LADDER
		#feet_y = collision.position.y + rect_shape.size.y / 2.0 #LADDER (ngitung jarak dari titik pusat node char ke kaki)
	
	if not hud:
		hud = get_node_or_null('HUD')
	if hud:
		hud.update_health(current_health, max_health)
		hud.update_stamina(current_stamina, max_stamina)

func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("ui_left", "ui_right")
	var climb_dir := Input.get_axis("ui_up", "ui_down")
	
	if is_dead:
		animated_sprite.play('death')
		if not is_on_floor():
			velocity += get_gravity() * delta
		else:
			velocity.x = 0
		move_and_slide()
		return
	
	if not is_on_floor():
		previous_y_velocity = velocity.y
		velocity += get_gravity() * delta
	else:
		if previous_y_velocity > FALL_DAMAGE_THRESHOLD:
			var damage = int((previous_y_velocity - FALL_DAMAGE_THRESHOLD) * 0.2) + 10
			take_damage(damage)
		
		jump_count = 0
		previous_y_velocity = 0.0

	if is_hurt:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		move_and_slide()
		return

	# LADDER
	var probe := Vector2(0, feet_y + feet_margin) #LADDER (geser titik tengah, untuk deteksi di feet_cell)
	var body_cell = get_ladder_cell(global_position) #LADDER (cek pusat node char kena ladder ngga)
	var feet_cell = get_ladder_cell(global_position + probe) #LADDER (cek di kaki kena ladder ngga)
	var ladder_cell = body_cell if body_cell != null else feet_cell #LADDER (tentuin yg kena)

	if ladder_cell != null and climb_dir != 0 and not is_climbing: #LADDER
		is_climbing = true #LADDER
		global_position.x = cell_center_x(ladder_cell) #LADDER (ke tengahin posisi di laddernya)

	if is_climbing: #LADDER
		if ladder_cell == null or direction != 0: #LADDER (cek masih di tangga atau ngga, dan gerak kanan kiri atau ngga)
			is_climbing = false #LADDER (ubah ke false)
		elif is_on_floor() and climb_dir > 0: #LADDER (kalo di lantai, dan player klik turun (positif dalam y artinya ke bawah))
			is_climbing = false #LADDER (ubah ke false)

	if is_climbing: #LADDER
		velocity.x = 0 #LADDER (biar ga kanan kiri)
		velocity.y = climb_dir * CLIMB_SPEED #LADDER (kecepatan naik tangga)

		if climb_dir < 0 and feet_cell != null: #LADDER (cek lagi naik dan kaki masih di tangga)
			var next_probe := global_position + probe + Vector2(0, velocity.y * delta) #LADDER (perkiraan posisi kaki dalam 1 frame ke depan)
			if get_ladder_cell(next_probe) == null: #LADDER (kalo udh ga di ladder, ga bisa naik lagi)
				velocity.y = 0 #LADDER

		if Input.is_action_just_pressed("ui_accept"): #LADDER (kalo loncat)
			is_climbing = false #LADDER (ke cancel naik tangganya)
			velocity.y = JUMP_VELOCITY #LADDER
		
		move_and_slide() #LADDER
		return #LADDER
	## LADDER
	
	var wants_to_run = Input.is_action_pressed("run") and direction != 0
	
	if current_stamina <= 0:
		is_stamina_exhausted = true

	if is_stamina_exhausted:
		if not Input.is_action_pressed('run') or current_stamina > 30:
			is_stamina_exhausted = false

	if wants_to_run and not is_stamina_exhausted and current_stamina > 0:
		is_running = true
		current_stamina -= stamina_drain * delta
		current_stamina = max(current_stamina, 0.0)
		if hud:
			hud.update_stamina(current_stamina, max_stamina)
	else:
		is_running = false
		if current_stamina < max_stamina:
			current_stamina += stamina_regen * delta
			current_stamina = min(current_stamina, max_stamina)
			if hud:
				hud.update_stamina(current_stamina, max_stamina)

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept"):
		if not is_on_floor() and max_jumps == 2 and jump_count < max_jumps:
			velocity.y = JUMP_VELOCITY
			jump_count += 2
		if is_on_floor() and jump_count < max_jumps:
			velocity.y = JUMP_VELOCITY
			jump_count += 1
		
	if Input.is_action_just_pressed('slash') and not is_attacking:
		is_attacking = true
		if is_running:
			animated_sprite.play('run_slash')
		else:
			animated_sprite.play('slash')
			
	var current_speed = RUN_SPEED if is_running else SPEED
	
	if is_attacking:
		if animated_sprite.animation == 'run_slash' or animated_sprite.animation == 'slash':
			if is_running:
				velocity.x = direction * RUN_SPEED
				if direction != 0:
					update_facing(direction)
			elif direction != 0:
				velocity.x = direction * SPEED
				update_facing(direction)
			else:
				velocity.x = move_toward(velocity.x, 0, SPEED)

		move_and_slide()
		return
	
	if direction:
		velocity.x = direction * current_speed
		update_facing(direction)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	update_animation(direction)

	move_and_slide()

func update_facing(direction: float) -> void:
	if direction == 0:
		return

	animated_sprite.flip_h = direction < 0

	if direction < 0:
		attack_collision.position.x = -attack_collision_offset_x
	else:
		attack_collision.position.x = attack_collision_offset_x

func update_animation(direction: float) -> void:
	if not is_on_floor():
		animated_sprite.play('jump')
	else:
		if direction != 0:
			if is_running:
				animated_sprite.play('run')
			else:
				animated_sprite.play('walk')
		else:
			animated_sprite.play('idle')

func jump_power_up() -> void:
	max_jumps = 2
	
func take_damage(amount: int) -> void:
	current_health -= amount
	current_health = clamp(current_health, 0, max_health)
	
	print("Kena damage sebesar: ", amount, " | Sisa HP: ", current_health)
	
	if hud:
		hud.update_health(current_health, max_health)
		
	if current_health <= 0:
		die()
	else:
		is_hurt = true
		is_attacking = false
		animated_sprite.play('damaged')
		flash_red()
		
func flash_red() -> void:
	var tween = create_tween()
	animated_sprite.modulate = Color.RED
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.2)
		
func die() -> void:
	is_dead = true
	is_attacking = false
	is_hurt = false
	velocity.x = 0

func _on_animated_sprite_2d_frame_changed() -> void:
	if not animated_sprite or not is_instance_valid(animated_sprite):
		return

	if animated_sprite.animation == "slash":
		if animated_sprite.frame == 3:
			for body in attack_area.get_overlapping_bodies():
				if body.has_method("take_damage") and body != self:
					body.take_damage(PLAYER_ATTACK_DAMAGE)

func _on_animated_sprite_2d_animation_finished() -> void:
	
	if animated_sprite.animation == 'slash' or animated_sprite.animation == 'run_slash':
		is_attacking = false
	elif animated_sprite.animation == 'damaged':
		is_hurt = false
	elif animated_sprite.animation == 'death':
		print("RELOAD SCENE")
		get_tree().reload_current_scene()

func get_ladder_cell(pos: Vector2) -> Variant: #LADDER (buat ubah koordinat / ngecek koordinat yg dikirimkan berada di koordinat ladder ngga)
	if ladder_layer == null: #LADDER
		return null #LADDER
	var cell := ladder_layer.local_to_map(ladder_layer.to_local(pos)) #LADDER (ubah posisi lokal ke koordinat petak)
	if ladder_layer.get_cell_source_id(cell) != -1: #LADDER (cek di koordinat cell, terisi ladder ga)
		return cell #LADDER
	return null #LADDER

func cell_center_x(cell: Vector2i) -> float: #LADDER
	var local_center = ladder_layer.map_to_local(cell) #LADDER ambil koordinat dari tilemap (tengahnya mana)
	return ladder_layer.to_global(local_center).x #LADDER trus diimplementasi di posisi globalnya
