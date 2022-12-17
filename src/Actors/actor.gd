extends CharacterBody2D
class_name Actor

@export var max_velocity: = Vector2(300, 1000)
@export var gravity: = Vector2(0, 3000)
@export var local_smoothed: = false # apply local smoothing to compare with smoother node results

var previous_physics_position

signal screen_entered
signal screen_exited

# TO DO:
# Better to automatically add a VisibleOnScreenNotifier2D in _ready and hook it up by code
# otherwise this'll get tedious and I'll probably forget this half the time.


func _ready() -> void:
	pass


func _enter_tree() -> void:
	previous_physics_position = position

	if !$VisibleOnScreenNotifier2D.is_on_screen():
		# onScreenEntered seems to fire automatically, but we also want to know at this point what
		# nodes are not on screen so that we can implement some performance improvements
		emit_signal("screen_exited", self)


func _exit_tree() -> void:
	emit_signal("screen_exited", self)


func _process(_delta: float) -> void:
	if local_smoothed:
		position = previous_physics_position + velocity * get_physics_process_delta_time() * Engine.get_physics_interpolation_fraction() #interpolation test


func _physics_process(_delta: float) -> void:
	if local_smoothed: position = previous_physics_position # interpolation test
	velocity = velocity.clamp(-max_velocity, max_velocity)
	move_and_slide()
	if local_smoothed: previous_physics_position = position #interpolation test


func _on_screen_entered() -> void:
	emit_signal("screen_entered", self)


func _on_screen_exited() -> void:
	emit_signal("screen_exited", self)
