extends Node2D

@export var camera:NodePath


func _ready() -> void:
	var cameraNode: = get_node_or_null(camera)

	if cameraNode:
		cameraNode.limit_right = $TileMap.get_used_rect().end.x * $TileMap.tile_set.tile_size.x


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_max_fps"):
		Engine.max_fps = 10 if Engine.max_fps == 0 else 0
		print('Engine.max_fps: ', Engine.max_fps)


func _on_node_teleport_started(node: Node) -> void:
	print("teleporting: ", node.name)

	if $Smoother: $Smoother.reset_node(node)

	# If we want a hard cut to the teleport position, we need to turn camera position smoothing off.
	# This is optional, with camera smoothing enabled it may be less confusing for the player.
	var cameraNode: = get_node_or_null(camera)
	if cameraNode: cameraNode.position_smoothing_enabled = false

	# We need to wait 2 process frames to re-enable camera position smoothing
	await get_tree().process_frame
	await get_tree().process_frame

	if cameraNode: cameraNode.position_smoothing_enabled = true


func _on_node_screen_entered(node:Node) -> void:
	if $Smoother:
		# method 1: keep default Smoother settings and exclude off-screen nodes
		$Smoother.remove_exclude_node(node)

		# method 2: set Smoother to smooth_parent: false, recursive: false and include on-screen nodes
#		$Smoother.add_include_node(node)

		print("smoothed nodes: ", $Smoother.smoothed_nodes.map(func (_node:Node): return _node.name))


func _on_node_screen_exited(node:Node) -> void:
	if $Smoother:
		# method 1: keep default Smoother settings and exclude off-screen nodes
		$Smoother.add_exclude_node(node)

		# method 2: set Smoother to smooth_parent: false, recursive: false and include on-screen nodes
#		$Smoother.remove_include_node(node)

		print("smoothed nodes: ", $Smoother.smoothed_nodes.map(func (_node:Node): return _node.name))
