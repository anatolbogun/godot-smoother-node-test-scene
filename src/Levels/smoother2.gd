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

# THOUGHTS:
# I think there's currently a problem because in _process the code assumes the target position
# purely based on velocity, so the position may be set to one frame early and this is
# very noticeable when either there was a collision (where the sprite may go partly through
# a wall for 1 physics frame, or where the movement is not even, e.g. decreasing velocity while
# jumping up. So instead of looking ahead, the position should rather be calculated one
# physics frame behind after any collision detection and velocity changes have been calculated

# BUG:
# This doesn't work well if e.g. the smoother is somewhere nested but should update a parent or
# includes node elsewhere, probably because of the order in which the _physics_process and
# _process runs
# I should rethink the entire structure, maybe I'm trying to add too many bells and whistles where
# it should simply be attached to a scene's root node and be done with
# At the very least we should store the initial parent node, then change the parent
# to owner, then perform move_child. I tried changing the parent to owner but no luck.

# After all I seem to be overthinking this. Maybe just add a note that even if includes are added
# that these must be a child of the smoother parent.

@export var recursive: = true
@export var includes: Array[NodePath] = []
@export var excludes: Array[NodePath] = []

var _original_parent: Node
var _positions := {}
var _physics_process_nodes: Array[Node]
var _physics_process_just_updated: = false
var _physics_process_counter: = 0


func _process(_delta: float) -> void:
	# position = previous_physics_position + velocity * get_physics_process_delta_time() * Engine.get_physics_interpolation_fraction() # local smoothing approach
#	var physics_interpolation_fraction: = Engine.get_physics_interpolation_fraction()

#	print("SMOOTHER 2 _process")

	for node in _physics_process_nodes:
		if _positions.has(node):
			if _physics_process_just_updated:
				_physics_process_counter = 0
				_positions[node] = node.position
#				print("  _positions[node] = ", node.position)

#			node.position = _positions[node] + node.velocity * node.get_physics_process_delta_time() * Engine.get_physics_interpolation_fraction()
#			node.position = _positions[node].lerp(_positions[node] + node.velocity * node.get_physics_process_delta_time(), Engine.get_physics_interpolation_fraction())
			node.position = _positions[node].lerp(_positions[node] - node.velocity * node.get_physics_process_delta_time(), 1 - Engine.get_physics_interpolation_fraction())

#			print("  node.position = ", _positions[node], " + etc.")

	_physics_process_just_updated = false
	_physics_process_counter += 1


func _physics_process(_delta: float) -> void:
	# position = previous_physics_position # local smoothing approach
	var parent: = get_parent()

	if parent == null: return

	print("SMOOTHER 2 _physics_process (", _physics_process_counter, " physics processes)")

	# move this node to the bottom of the parent tree (typically a scene's root node) so that it is called after all other _physics_processes have been completed
#	parent.move_child(self, -1)
	parent.move_child(self, 0)

	# it's enough to update the relevant physics process nodes once per _physics_process
	_physics_process_nodes = _get_physics_process_nodes(parent)

	for node in _physics_process_nodes:
		if (!_positions.has(node)):
			# only called on the first frame after this node was added to _positions
			_positions[node] = node.position

			# clean up _positions when a node exited the tree
			node.tree_exited.connect(func (): _positions.erase(node))

#			print("  _positions[node] = ", node.position)
		else:
			node.position = _positions[node]
#			print("  node.position = ", _positions[node])

#		_positions[node] = node.position

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
##	print("RELEVANT NODES", nodes.map(func (node): return node.name))
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
