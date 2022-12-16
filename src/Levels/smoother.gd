# MIT License
#
# Copyright 2022 Anatol Bogun
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
# associated documentation files (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge, publish, distribute,
# sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
# NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
#
# NOTES:
# - By default this node applies to its parent, siblings and recursive children. Nodes that have no
#   custom _physics_process code or a position property are automatically ignored.
# - The most common scenario is to make it a direct child of the root node, e.g. in a level scene.
#   By default it will then smooth the parent, all children and deep nested children in the same
#   scene tree.
# - If the smoother should be applied to only specific nodes, just select those nodes in the
#   includes option and disable smooth_parent and recursive, or give each node that should be
#   smoothed a Smoother node child with the recursive option off.
# - The excludes option ignores nodes that would otherwise be covered by other Smoother options.
# - The code will keep this node as the first child of the parent node because its _physics_process
#   and _process code must be applied before any other nodes.
# - When smooth_parent is enabled the process_priority will be kept at a lower value than the
#   parent's, i.e. it will be processed earlier.
# - For easier understanding of the code, consider:
#	_positions[node][0] is the origin position
#	_positions[node][1] is the target position

# TO DO:
# - may need something similar for rotations, etc. and export vars to include these properties;
#   need to check what is potentially affected by _physics_process
class_name Smoother extends Node


@export var smooth_parent: = true :
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

	# move this node to the top of the parent tree (typically a scene's root node) so that it is called before all other _physics_processes
	parent.move_child(self, 0)

	if smooth_parent:
		process_priority = parent.process_priority - 1

	# it's enough to update the relevant physics process nodes once per _physics_process
	_physics_process_nodes = _get_physics_process_nodes(parent, !smooth_parent)

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
func _get_physics_process_nodes(node: Node, ignoreNode: = false, withIncludes: = true) -> Array[Node]:
	var nodes: Array[Node] = includes.map( func (include): return get_node_or_null(include)).filter(func (node): return node != null) if withIncludes else []

	if !ignoreNode && node != self && !nodes.has(node) && !excludes.has(get_path_to(node)) && node.has_method("_physics_process") && node.get("position"):
		nodes.push_back(node)

	if recursive:
		for child in node.get_children():
			nodes.append_array(_get_physics_process_nodes(child, false, false))

	return nodes
