extends Node

# NOTE:
# - For this to work this node must be at the bottom of the scene tree. Hence
#   get_parent().move_child(self, -1)
# - For easier understanding consider:
#	_positions[child][0] is the origin position
#	_positions[child][1] is the target position
# - manual alternative that needs to be applied in each physics object:
#   # _process
#   position = previous_physics_position + velocity * get_physics_process_delta_time() * Engine.get_physics_interpolation_fraction()
#   # _physics_process
#   position = previous_physics_position
#	move_and_slide()
#	previous_physics_position = position

# TO DO:
# - running a smoothed and not smoothed player sprite simultaneously shows that the
#   smoothed one is slightly slower (maybe need to take delta time into account)?
# - check if collision detection really works reliably, this seems a bit sketchy
# - consider if we need any extra properties such as recursive, includes and excludes (not even sure about the last 2)
#   e.g. do we need a mode where we don't follow the parent children but only apply includes, i.e. includes only either as an enum mode or a simple bool
# - may need something similar for rotations, etc. and export vars to include these properties;
#   need to check what is potentially affected by _physics_process
# - there's a bug where sometimes

@export var recursive: = true
@export var includes: Array[NodePath] = []
@export var excludes: Array[NodePath] = []


var _positions := {}
var _physics_process_nodes: Array[Node]
var _physics_process_just_updated: = false


func _process(_delta: float) -> void:
	# position = previous_physics_position + velocity * get_physics_process_delta_time() * Engine.get_physics_interpolation_fraction() # local smoothing approach
	var physics_interpolation_fraction: = Engine.get_physics_interpolation_fraction()

	for child in _physics_process_nodes:
		if _positions.has(child) && _positions[child].size() == 2:
			if _physics_process_just_updated:
				child.position = _positions[child][0]
			child.position = _positions[child][0].lerp(_positions[child][1], physics_interpolation_fraction)
#			child.position = _positions[child][0] + child.velocity * child.get_physics_process_delta_time() * physics_interpolation_fraction

	if _physics_process_just_updated:
		_physics_process_just_updated = false


func _physics_process(_delta: float) -> void:
	# position = previous_physics_position # local smoothing approach
	var parent: = get_parent()

	if parent == null: return

#	print("SMOOTHER _physics_process")

	# move this node to the bottom of the parent tree (typically a scene's root node) so that it is called after all other _physics_processes have been completed
	parent.move_child(self, -1)

	# it's enough to update the relevant physics process nodes once per _physics_process
	_physics_process_nodes = _get_physics_process_nodes(parent)

#	print(_physics_process_nodes.map(func (node): return node.name))

	for node in _physics_process_nodes:
		if (!_positions.has(node)):
			# only called on the first frame after this node was added to _positions
			_positions[node] = [node.position]
			# clean up _positions when a node exited the tree
			node.tree_exited.connect(func (): _positions.erase(node))
		elif (_positions[node].size() < 2):
			# only called on the second frame after this node was added to _positions
			_positions[node].push_front(_positions[node][0])
			_positions[node][1] = node.position
		else:
			_positions[node][0] = _positions[node][1]
			_positions[node][1] = node.position
			node.position = _positions[node][0]

	_physics_process_just_updated = true

	# previous_physics_position = position # local smoothing approach

#   # the smoothed sprite position seems to be decreasing by about 1 pixel per physics process call if there is a velocity
#	print("ORIGIN: ", parent.find_child("Player2").position - parent.find_child("Player").position)

# CONTINUE:
# Assume Player is smoothed and Player2 is exempt from smoothing.
# I think I need to compare Player and Player2 origin positions and see where the target positions differ
# or maybe print out the movement between each frame and compare by how much Player and Player2
# differ. Then figure out what that number means, i.e. is it a single extra physics step that's missing?
# That's actually possible because I think when the physics process is called there's likely
# a physics_process between the same two frames, and so maybe it causes an issue if both
# are applied simultaneously. What's called first, _process or _physics_process?
# Maybe child.position shouldn't be set? No, when I comment ot the child.position line in
# _physics_process both players at times move identically, but it's erratic. Still,
# there may be a one (_process) frame difference between Player and Player2.


# get scene children that ignore any nodes that don't have a _physics_process overwrite
#func _get_physics_process_nodes(parent) -> Array[Node]:
#	var nodes: Array[Node] = includes.map( func (include): return get_node(include))
#
#	for node in parent.get_children():
#		if node != self && !excludes.has(get_path_to(node)):
#			if node.has_method("_physics_process") && node.get("position") && !nodes.has(node):
#				nodes.push_back(node)
#
#			if recursive && node.get_child_count() > 0:
#				nodes.append_array(_get_physics_process_nodes(node))
#
#	return nodes

# get scene children that ignore any nodes that don't have a _physics_process overwrite
func _get_physics_process_nodes(node: Node, withIncludes: = true) -> Array[Node]:
	var nodes: Array[Node] = includes.map( func (include): return get_node_or_null(include)).filter(func (node): return node != null) if withIncludes else []

	if node != self && !nodes.has(node) && !excludes.has(get_path_to(node)) && node.has_method("_physics_process") && node.get("position"):
		nodes.push_back(node)

	if recursive:
		for child in node.get_children():
			nodes.append_array(_get_physics_process_nodes(child, false))

	return nodes
