# MIT LICENSE
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
# SMOOTHER NODE
# -------------
#
# This node interpolates the position of other nodes between their _physics_process es. The
# interpolation is applied in the _process loop which ensures that nodes move smoothly, even if the
# _physics_process is called less often than the games fps rate which is typically synced to the
# current screen's refresh rate.
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
# - Collision detection still happens in the _physics_process, so if the physics_ticks_per_second
#   in the project settings are too low you may experience seemingly incorrect or punishing
#   collision detection. The default 60 physics_ticks_per_second should a good value. To test this
#   node you may want to temporarily reduce physics ticks to a lower value and toggle this node on
#   and off.
# - The code will keep this node as the first child of the parent node because its _physics_process
#   and _process code must be applied before any other nodes.
# - When smooth_parent is enabled the process_priority will be kept at a lower value than the
#   parent's, i.e. it will be processed earlier.
# - When teleporting a sprite you may want to call reset(node) for the affected sprite/s, otherwise
#   a teleport (changing the sprite's position) may not work as expected.
# - For easier understanding of the code, consider:
#	_positions[node][0] is the origin position
#	_positions[node][1] is the target position
#
# LIMITATIONS:
# - Currently this does not work with RigidBody2D or RigidBody3D nodes. Please check out
#   https://github.com/lawnjelly/smoothing-addon/ which has a more complicated setup but has more
#   precision and less limitations. Or help to make this code work with rigid bodies if it's
#   possible at all.
# - Interpolation is one _physics_process step behind because we need to know the origin and target
#   value for an interpolation to occur, so in a typical scenario this means a delay of 1/60 second
#   which is the default physics_ticks_per_second in the project settings.
# - Interpolation does not look ahead for collision detection. That means that if for example a
#   sprite falls to hit the ground and the last _physics_process step before impact is very close
#   to the ground, interpolation will still occur on all _physics frames between which may have a
#   slight impact cushioning effect. However, with 60 physics fps this is hopefully negligible.


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
func reset(nodes = null) -> void:
	if nodes is Node:
		nodes = [nodes]

	if nodes is Array:
		for node in nodes:
			_positions.erase(node)
	else:
		_positions.clear()


func _process(_delta: float) -> void:
	for node in _physics_process_nodes:
		if _positions.has(node) && _positions[node].size() == 2:
			if _physics_process_just_updated:
				_positions[node][1] = node.position

			node.position = _positions[node][0].lerp(
				_positions[node][1],
				Engine.get_physics_interpolation_fraction()
			)
#
	_physics_process_just_updated = false


func _physics_process(_delta: float) -> void:
	var parent: = get_parent()
	if parent == null: return

	# move this node to the top of the parent tree (typically a scene's root
	# node) so that it is called before all other _physics_processes
	parent.move_child(self, 0)

	if smooth_parent:
		process_priority = parent.process_priority - 1

	# update the relevant nodes once per _physics_process
	_physics_process_nodes = _get_physics_process_nodes(parent, !smooth_parent)

	for node in _physics_process_nodes:
		if (!_positions.has(node)):
			# called on the first frame after this node was added to _positions
			_positions[node] = [node.position]

			# clean up _positions when a node exited the tree
			node.tree_exited.connect(func (): _positions.erase(node))
		elif (_positions[node].size() < 2):
			# called on the second frame after this node was added to _positions
			_positions[node].push_front(_positions[node][0])
			_positions[node][1] = node.position
		else:
			_positions[node][0] = _positions[node][1]
			node.position = _positions[node][0]

	_physics_process_just_updated = true


# get relevant nodes to be smoothed
func _get_physics_process_nodes(node: Node, ignoreNode: = false, withIncludes: = true) -> Array[Node]:
	var nodes: Array[Node] = includes.map(
		func (include): return get_node_or_null(include)
	).filter(
		func (node): return node != null
	) if withIncludes else []

	if (!ignoreNode
		&& node != self
		&& !nodes.has(node)
		&& !excludes.has(get_path_to(node))
		&& node.has_method("_physics_process")
		&& node.get("position")
	):
		nodes.push_back(node)

	if recursive:
		for child in node.get_children():
			nodes.append_array(_get_physics_process_nodes(child, false, false))

	return nodes
