extends CharacterBody2D

@onready var collision_shape2d = $Area2D/CollisionShape2D
@onready var character_body2d = $"."

var speed = 200
var lane_switch_distance = null

func _ready():
	lane_switch_distance = collision_shape2d.shape.get_rect().size[1]

func _input(event):
	if event.is_action_pressed("car_up") and character_body2d.position.y > -73.75:
		lane_switch(-1)
	elif event.is_action_pressed("car_down") and character_body2d.position.y < 73.75:
		lane_switch(1)

func lane_switch(direction):
	var previous_location = character_body2d.position
	var target_location = previous_location.y + (direction * lane_switch_distance * 2.5)
	character_body2d.position = Vector2(previous_location.x, target_location)