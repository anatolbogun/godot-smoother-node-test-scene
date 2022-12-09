extends Node

# NOTE:
# - For this to work this node must be at the top of the scene tree. Hence
#   get_parent().move_child(self, 0)
# - manual (flawed?) alternative that needs to be applied in each physics object:
#   # _process
#   position = previous_physics_position + velocity * get_physics_process_delta_time() * Engine.get_physics_interpolation_fraction()
#   # _physics_process
#   position = previous_physics_position
#	move_and_slide()
#	previous_physics_position = position

# TO DO:
# - wouldn't an approach in _physics that does not require node.velocity be better, instead work
#   with an origin and target position?
# - consider if we need any extra properties such as recursive, includes and excludes (not even sure about the last 2)
#   e.g. do we need a mode where we don't follow the parent children but only apply includes, i.e. includes only either as an enum mode or a simple bool
# - may need something similar for rotations, etc. and export vars to include these properties;
#   need to check what is potentially affected by _physics_process

# THOUGHTS:
# If e.g. the smoother is somewhere nested but should update a parent or includes node elsewhere,
# probably because of the order in which the _physics_process and _process runs.
# I should rethink the entire structure, maybe I'm trying to add too many bells and whistles where
# it should simply be attached to a scene's root node and be done with
# At the very least we should store the initial parent node, then change the parent
# to owner, then perform move_child. I tried changing the parent to owner but no luck.
# After all I seem to be overthinking this. Maybe just add a note that even if includes are added
# that these must be children of the smoother parent.

@export var recursive: = true
@export var includes: Array[NodePath] = []
@export var excludes: Array[NodePath] = []

var _original_parent: Node
var _positions := {}
var _physics_process_nodes: Array[Node]
var _physics_process_just_updated: = false


func _process(_delta: float) -> void:
#	var physics_interpolation_fraction: = Engine.get_physics_interpolation_fraction()

	for node in _physics_process_nodes:
		if _positions.has(node):
			if _physics_process_just_updated:
				_positions[node] = node.position

#			node.position = _positions[node] + node.velocity * node.get_physics_process_delta_time() * Engine.get_physics_interpolation_fraction()
			node.position = _positions[node].lerp(_positions[node] - node.velocity * node.get_physics_process_delta_time(), 1 - Engine.get_physics_interpolation_fraction())

	_physics_process_just_updated = false


func _physics_process(_delta: float) -> void:
	var parent: = get_parent()
	if parent == null: return

	# move this node to the top of the parent tree (typically a scene's root node) so that it is called before all other _physics_processes
	parent.move_child(self, 0)

	# it's enough to update the relevant physics process nodes once per _physics_process
	_physics_process_nodes = _get_physics_process_nodes(parent)

	for node in _physics_process_nodes:
		if (!_positions.has(node)):
			# only called on the first frame after this node was added to _positions
			_positions[node] = node.position

			# clean up _positions when a node exited the tree
			node.tree_exited.connect(func (): _positions.erase(node))
		else:
			node.position = _positions[node]

	_physics_process_just_updated = true


# get scene children that ignore any nodes that don't have a _physics_process overwrite
func _get_physics_process_nodes(node: Node, withIncludes: = true) -> Array[Node]:
	var nodes: Array[Node] = includes.map( func (include): return get_node_or_null(include)).filter(func (node): return node != null) if withIncludes else []

	# TO DO: this may not be necessary because the smoother node does not work applied to a parent,
	# so either we save the original parent and move the node under the owner somehow, then call
	# _get_physics_process_nodes with the original parent (target node), or recursive
	# only applies to the second node hierarchy down; right now I think the next 2 lines
	# will do nothing because the root node doesn't validate. However, if the parent node would
	# validate we would get erratic movements because the _physics_process and _process of the
	# smoother node being a child of the node to be smoothed gets called after, not before.
	if node != self && !nodes.has(node) && !excludes.has(get_path_to(node)) && node.has_method("_physics_process") && node.get("position"):
		nodes.push_back(node)

	if recursive:
		for child in node.get_children():
			nodes.append_array(_get_physics_process_nodes(child, false))

	return nodes
