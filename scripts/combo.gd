extends Node2D

@onready var arrows_NODE = $Arrows
@onready var timer = $Timer

signal speed_changed(new_speed)
signal spin_control_animation()
signal got_hit()
signal wrong_input()
signal loop_mode()

@export var speed = 5
var loop_mode_min = speed * 1.2

var rng = RandomNumberGenerator.new()
const arrow_scene: PackedScene = preload("res://scenes/arrow.tscn")
const spin_control_arrows_scene: PackedScene = preload("res://scenes/spin_control_arrows.tscn")

var spin_control_node = null
var switch_mode = false
var arrows = []
var spin_control_input = 0
var mode 

const CAP = 50
const PAC = 2

func _ready():
	check_mode()
	rng.randomize()
	
func _process(delta):
	if mode != "hit":
		check_mode()
		timer_fixer_upper_loop_mode()
	
func check_mode():
	if speed >= loop_mode_min and mode != "loop_mode":
		loop_mode.emit()
		order66()
		mode =  "loop_mode"
		timer.start()
	elif switch_mode:
		spin_control_animation.emit()
		switch_mode = false
		order66()
		loop_mode_min = speed * 1.2
		mode = "spin_control"
		spawn_spin_control_arrows()
		timer.start()
	
func _input(event):
	if event.is_action_pressed("ui_up"):
		arrow_combo(0)
	elif event.is_action_pressed("ui_right"):
		arrow_combo(1)
	elif event.is_action_pressed("ui_down"):
		arrow_combo(2)
	elif event.is_action_pressed("ui_left"):
		arrow_combo(3)
		
func arrow_combo(direction):
	if mode == "loop_mode":
		if len(arrows) > 0 and direction == arrows[0].rotation_degrees / 90:
			arrows[0].queue_free()
			arrows.pop_front()
			increase_speed()
		else:
			_on_road_hit()
			order66()
	elif mode == "spin_control":
		if len(arrows) > 0 and direction == arrows[0]:
			arrows.pop_front()
			spin_control_animation.emit()
		else:
			_on_road_hit()
		
			
func spawn_random_child_arrow():
	"""returns random number between 0 and 3 (inclusive)
	"""
	var r = rng.randi_range(0, 3)
	var new_arrow = arrow_scene.instantiate()
	#new_arrow.position.x = new_arrow.position.x + 800
	arrows_NODE.add_child(new_arrow)
	new_arrow.rotation_degrees = r * 90
	arrows.append(new_arrow)

func spawn_spin_control_arrows():
	var new_spin_control_arrows = spin_control_arrows_scene.instantiate()
	arrows_NODE.add_child(new_spin_control_arrows)
	spin_control_node = arrows_NODE.get_child(0)
	spin_control_input = 2
	spin_control_node.frame = (spin_control_input + 2) % 4
	spin_control_node.position = Vector2(spin_control_node.position.x - 750, spin_control_node.position.y + 120)
	arrows.append(spin_control_input)

func order66():
	for n in arrows_NODE.get_children():
		arrows_NODE.remove_child(n)
		n.queue_free()
		arrows.pop_front()
		
func increase_speed():
	if speed < CAP:
		speed += 20
	speed_changed.emit(speed)
	
func decrease_speed():
	if speed > PAC:
		speed -= 1
	speed_changed.emit(speed)
	
func timer_fixer_upper_loop_mode():
	var cof = 7
	timer.wait_time = cof / 1.0/speed
		
func _on_kill_zone_area_shape_entered(area_rid, area, area_shape_index, local_shape_index): #killzone for incoming arrows in loop_mode
	_on_road_hit()

func _on_timer_timeout():
	if mode == "spin_control":
		if len(arrows) > 0:
			reset_spin_control()
		else:
			spin_control_input += 1
			spin_control_node.frame = (spin_control_input + 2) % 4
			spin_control_input = spin_control_input % 4
			arrows.append(spin_control_input)
			spin_control_animation.emit()
			#add animations
			if spin_control_input == 2:
				increase_speed()
			
	elif mode == "loop_mode":
		spawn_random_child_arrow()
	else:
		mode = "spin_control"
		timer_fixer_upper_loop_mode()

func reset_spin_control():
	timer.stop()
	arrows = []
	spin_control_input = 2
	spin_control_node.frame = (spin_control_input + 2) % 4
	arrows.append(spin_control_input)
	wrong_input.emit()
	timer.start()
	timer_fixer_upper_loop_mode()

func _on_road_hit(): #hitbox detection for obstacles hitting car
	if mode == "spin_control":
		reset_spin_control()
	else:
		switch_mode = true
	decrease_speed()
	got_hit.emit()


func _on_character_body_2d_hit_animation_playing():
	if mode != "hit":
		mode = "hit"
		timer.wait_time = 0.5
		timer.start()
