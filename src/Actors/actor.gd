extends CharacterBody2D
class_name Actor

@export var max_velocity: = Vector2(300, 1000)
@export var gravity: = Vector2(0, 3000)

var previous_physics_position

func _enter_tree() -> void:
	previous_physics_position = position

func _process(_delta: float) -> void:
#	if Engine.get_frames_per_second() > Engine.physics_ticks_per_second:
#	position = previous_physics_position + velocity * get_physics_process_delta_time() * Engine.get_physics_interpolation_fraction() #interpolation test
	pass

func _physics_process(_delta: float) -> void:
#	position = previous_physics_position # interpolation test
	velocity = velocity.clamp(-max_velocity, max_velocity)
	move_and_slide()
#	previous_physics_position = position #interpolation test
