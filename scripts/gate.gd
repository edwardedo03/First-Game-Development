extends Area2D

@export_file("*.tscn") var target_scene: String
@export var scene_destination: String = "trap_gate"

var entered = false
var player_ref: Node2D = null

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		entered = true
		player_ref = body

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		entered = false
		player_ref = null

func _process(delta: float):
	if entered == true:
		if Input.is_action_just_pressed('interact'):
			if target_scene and player_ref:
				GameManager.transition_to_scene(target_scene, scene_destination, player_ref)
			else:
				print("Error: Target scene atau player belum siap!")
