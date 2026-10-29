extends CharacterBody2D

var SPEED = 130.0
var RUN_SPEED = 200
var JUMP_VELOCITY = -260.0
const FALL_DAMAGE_THRESHOLD = 420.0
const CLIMB_SPEED = 80.0 #LADDER

var lava_layer: TileMapLayer
var lava_damage: int = 5
var lava_damage_interval: float = 0.3
var lava_damage_timer: float = 0.0

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
var PLAYER_ATTACK_DAMAGE = 5

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

var defeated_bosses: Array[String] = []

var is_using_rope: bool = false
var rope_start_position: Vector2
var rope_end_position: Vector2
var rope_speed: float = 150.0

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
	
	if is_using_rope:
		handle_rope_movement(delta)
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
	
	handle_lava_damage(delta)

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
		if not is_inside_tree():
			return
		GameManager.respawn_to_main_map()
		#get_tree().reload_current_scene()

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

# Lava
func find_lava_layer() -> void:
	lava_layer = get_tree().get_first_node_in_group("lava_layer") as TileMapLayer
	
func is_touching_lava() -> bool:
	if lava_layer == null:
		return false

	var feet_position = global_position + Vector2(0, feet_y + 2.0)
	var local_position = lava_layer.to_local(feet_position)
	var cell = lava_layer.local_to_map(local_position)

	return lava_layer.get_cell_source_id(cell) != -1
	
func handle_lava_damage(delta: float) -> void:
	if is_touching_lava():
		lava_damage_timer -= delta

		if lava_damage_timer <= 0.0:
			take_damage(lava_damage)
			
			if not is_dead:
				velocity.y = JUMP_VELOCITY
				
			lava_damage_timer = lava_damage_interval
	else:
		lava_damage_timer = 0.0

# power collected

func apply_power_up(power_type: String) -> void:
	match power_type:
		"double_jump":
			max_jumps = 2
			print("Power-up: Double Jump!")

		"speed":
			SPEED += 30.0
			RUN_SPEED += 30.0
			print("Power-up: Speed meningkat!")
			
		"heal":
			current_health = min(current_health + 15, max_health)
			if hud:
				hud.update_health(current_health, max_health)
			print("Power-up: Heal!")

# nambah attack damage tiap kalahih musuh kroco
func gain_attack_damage(amount: int) -> void:
	PLAYER_ATTACK_DAMAGE += amount
	print("Attack damage meningkat menjadi: ", PLAYER_ATTACK_DAMAGE)
	
func gain_max_health(amount: int) -> void:
	max_health += amount
	current_health += amount
	print("Max health meningkat menjadi: ", max_health, ", Current health menjadi: ", current_health)
	
	current_health = min(current_health, max_health)
	current_stamina = min(current_stamina, max_stamina)

	if hud:
		hud.update_health(current_health, max_health)
		hud.update_stamina(current_stamina, max_stamina)
	
# power up after defeated a boss
func boss_power_up() -> void:
	for boss_id in GameManager.deafeated_bosses:
		if boss_id in defeated_bosses:
			continue
		
		match boss_id:
			"golem":
				SPEED += 20
				RUN_SPEED += 20
				max_health += 20
				current_health += 20
				max_stamina += 20
				PLAYER_ATTACK_DAMAGE += 5
			"dark_golem":
				SPEED += 10
				RUN_SPEED += 20
				max_health += 30
				current_health += 30
				stamina_regen += 5
				PLAYER_ATTACK_DAMAGE += 10
			"ice_golem":
				SPEED += 10
				RUN_SPEED += 10
				max_health += 30
				current_health += 30
				max_stamina += 10
				stamina_regen +=5
				PLAYER_ATTACK_DAMAGE += 15
			
		defeated_bosses.append(boss_id)
		print("Power Up dari boss: ", boss_id)
	
	current_health = min(current_health, max_health)
	current_stamina = min(current_stamina, max_stamina)

	if hud:
		hud.update_health(current_health, max_health)
		hud.update_stamina(current_stamina, max_stamina)


# Rope Function

func start_rope_transport(start_pos: Vector2, end_pos: Vector2, speed: float) -> void:
	is_using_rope = true
	rope_start_position = start_pos
	rope_end_position = end_pos
	rope_speed = speed

	global_position = start_pos
	velocity = Vector2.ZERO
	animated_sprite.play("idle")

func handle_rope_movement(delta: float) -> void:
	var direction := Input.get_axis("ui_left", "ui_right")

	velocity = Vector2.ZERO

	global_position.x += direction * rope_speed * delta

	var min_x := minf(
		rope_start_position.x,
		rope_end_position.x
	)
	var max_x := maxf(
		rope_start_position.x,
		rope_end_position.x
	)

	global_position.x = clampf(
		global_position.x,
		min_x,
		max_x
	)

	global_position.y = rope_start_position.y

	if direction != 0:
		update_facing(direction)
		animated_sprite.play("roping")
	else:
		animated_sprite.play("idle")

	if Input.is_action_just_pressed("interact"):
		is_using_rope = false
		velocity = Vector2.ZERO
