extends Node

var target_positions := {}
var origin_positions := {}
var print = 3

func _process(_delta: float) -> void:
#   # if the following code was in a Node2D instance this would work in combination with setting the position in _physics_process
#	position = previous_physics_position + velocity * get_physics_process_delta_time() * Engine.get_physics_interpolation_fraction()

	for child in _get_relevant_children():
		if origin_positions.has(child) && target_positions.has(child):
			# probably also need to filter children by position and velocity properties or handle this differently if they don't exist
			child.position = target_positions[child] + child.velocity * get_physics_process_delta_time() * Engine.get_physics_interpolation_fraction()
#			child.position = target_positions[child] + child.velocity * get_physics_process_delta_time() * Engine.get_physics_interpolation_fraction() - (target_positions[child] - origin_positions[child])

			if child.name == "Player" && print > 0:
				print("position interpolation: ", child.position)

func _physics_process(_delta: float) -> void:
#   # if the following code was in a Node2D instance this would work in combination with setting the position in _process
#	position = previous_physics_position
#	move_and_slide()
#	previous_physics_position = position

	for child in _get_relevant_children():
		if (!target_positions.has(child)):
			target_positions[child] = child.position
		elif (!origin_positions.has(child)):
			origin_positions[child] = target_positions[child]
			target_positions[child] = child.position
		else:
			origin_positions[child] = target_positions[child]
			target_positions[child] = child.position
			child.position = origin_positions[child]

			if child.name == "Player" &&  print > 0:
				print("+++++ _physics_process +++++")
				print("position:               ", child.position)
				print("origin_positions:       ", origin_positions[child])
				print("target_positions:       ", target_positions[child])
				print -= 1


# scene children that ignore any nodes that don't have a _physics_process overwrite
func _get_relevant_children() -> Array[Node]:
	return owner.get_children().filter( func (child):
		return child != self && child.has_method("_physics_process")
	)
