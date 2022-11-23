extends Node

var physics_positions := {}
var previous_physics_positions := {}

func _process(_delta: float) -> void:
#	position = previous_physics_position + velocity * get_physics_process_delta_time() * Engine.get_physics_interpolation_fraction()

	for child in _get_relevant_children():
		if (physics_positions.has(child)):
			# probably also need to filter children by position and velocity properties or handle this differently if they don't exist
			child.position = physics_positions[child] + child.velocity * get_physics_process_delta_time() * Engine.get_physics_interpolation_fraction()
#			child.position = physics_positions[child] + child.velocity * get_physics_process_delta_time() * Engine.get_physics_interpolation_fraction() + (physics_positions[child] - previous_physics_positions[child])


func _physics_process(_delta: float) -> void:
#	position = previous_physics_position
#	move_and_slide()
#	previous_physics_position = position

	for child in _get_relevant_children():
		if (previous_physics_positions.has(child)):
			child.position = physics_positions[child]
			previous_physics_positions[child] = physics_positions[child]
		else:
			physics_positions[child] = child.position
			print(child)
			print(physics_positions[child])


# scene children that ignore any nodes that don't have a _physics_process overwrite
func _get_relevant_children() -> Array[Node]:
	return owner.get_children().filter( func (child):
		return child != self && child.has_method("_physics_process")
	)
