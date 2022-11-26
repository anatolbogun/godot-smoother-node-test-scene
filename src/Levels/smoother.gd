extends Node

# NOTE:
# - For this to work this node must be at the bottom of the scene tree. Hence
#   get_parent().move_child(self, -1)
# - manual way in each physics object:
#   # _process
#   position = previous_physics_position + velocity * get_physics_process_delta_time() * Engine.get_physics_interpolation_fraction()
#   # _physics_process
#   position = previous_physics_position
#	move_and_slide()
#	previous_physics_position = position

# TO DO:
# - running a smoothed and not smoothed player sprite simultaneously shows that the
#   smoothed one is slightly slower (maybe need to take delta time into account)?
# - this node needs export vars such as recursive (currently recursive isn't even supported),
#   include or exclude specific nodes
# - may need something similar for rotations, etc. and export vars to include these properties;
#   need to check what is potentially affected by _physics_process
# - clean up origin_positions and target_positions
# - maybe combine origin_positions and target_positions (may be a bit faster?)

var origin_positions := {}
var target_positions := {}


func _ready() -> void:
	# move this node to the bottom of the scene tree so that it is called after all other _physics_processes have been completed
	get_parent().move_child(self, -1)


func _process(_delta: float) -> void:
	var physics_interpolation_fraction: = Engine.get_physics_interpolation_fraction()

	for child in _get_relevant_children():
		if origin_positions.has(child) && target_positions.has(child): # clean this up later, maybe not all checks are needed
			child.position = origin_positions[child].lerp(target_positions[child], physics_interpolation_fraction)
#

func _physics_process(_delta: float) -> void:
	get_parent().move_child(self, -1)

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


# scene children that ignore any nodes that don't have a _physics_process overwrite
func _get_relevant_children() -> Array[Node]:
	return get_parent().get_children().filter( func (child):
		return child != self && child.has_method("_physics_process") && child.name != "Player2"
	)
