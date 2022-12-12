extends Node

# NOTE:
# - This node can only be applied to siblings or (if recursive is true) children or nested children
#   of this node or its siblings.
# - The most common scenario is to make it a direct child of the root node, e.g. in a level scene.
#   By default it will then smooth all children and deep nested children in the same scene tree.
# - For this to work this node must be at the top of the scene tree. Hence
#   get_parent().move_child(self, 0)
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
# - consider if we need any extra properties such as recursive, includes and excludes (not even sure about the last 2)
#   e.g. do we need a mode where we don't follow the parent children but only apply includes, i.e. includes only either as an enum mode or a simple bool
# - may need something similar for rotations, etc. and export vars to include these properties;
#   need to check what is potentially affected by _physics_process

@export var smooth_parent: = false :
	set (value):
		if value == false:
			# remove parent from _positions in case this gets toggled on and off during runtime
			_positions.erase(get_parent())

		smooth_parent = value

@export var recursive: = true
@export var includes: Array[NodePath] = []
@export var excludes: Array[NodePath] = []

var _positions := {}
var _physics_process_nodes: Array[Node]
var _physics_process_just_updated: = false


# resets a node, array of nodes or all smoothed nodes in the _positions dictionary;
# you may want to call this when a sprite gets teleported
# TO DO: test this
func reset(nodes) -> void:
	if nodes.typeof(Node):
		nodes = [nodes]

	if nodes.typeof(TYPE_ARRAY):
		print("resetting ", nodes)
		for node in nodes:
			_positions.erase(node)
	else:
		print("resetting all")
		_positions.clear()


func _process(_delta: float) -> void:
#	var physics_interpolation_fraction: = Engine.get_physics_interpolation_fraction()

	for node in _physics_process_nodes:
		if _positions.has(node) && _positions[node].size() == 2:
			if _physics_process_just_updated:
				_positions[node][1] = node.position

			node.position = _positions[node][0].lerp(_positions[node][1], Engine.get_physics_interpolation_fraction())
#
	_physics_process_just_updated = false


func _physics_process(_delta: float) -> void:
	var parent: = get_parent()
	if parent == null: return

	if smooth_parent:
		process_priority = parent.process_priority - 1

	# move this node to the top of the parent tree (typically a scene's root node) so that it is called before all other _physics_processes
	parent.move_child(self, 0)

	if smooth_parent:
		process_priority = parent.process_priority - 1

	# it's enough to update the relevant physics process nodes once per _physics_process
	_physics_process_nodes = _get_physics_process_nodes(parent, !smooth_parent, true)

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
			node.position = _positions[node][0]

	_physics_process_just_updated = true


# get scene children that ignore any nodes that don't have a _physics_process overwrite
func _get_physics_process_nodes(node: Node, ignoreNode: = false, withIncludes: = false) -> Array[Node]:
	var nodes: Array[Node] = includes.map( func (include): return get_node_or_null(include)).filter(func (node): return node != null) if withIncludes else []

	# TO DO: this may not be necessary because the smoother node does not work applied to a parent,
	# so either we save the original parent and move the node under the owner somehow, then call
	# _get_physics_process_nodes with the original parent (target node), or recursive
	# only applies to the second node hierarchy down; right now I think the next 2 lines
	# will do nothing because the root node doesn't validate. However, if the parent node would
	# validate we would get erratic movements because the _physics_process and _process of the
	# smoother node being a child of the node to be smoothed gets called after, not before.
	if !ignoreNode && node != self && !nodes.has(node) && !excludes.has(get_path_to(node)) && node.has_method("_physics_process") && node.get("position"):
		nodes.push_back(node)

	if recursive:
		for child in node.get_children():
			nodes.append_array(_get_physics_process_nodes(child))

	return nodes
