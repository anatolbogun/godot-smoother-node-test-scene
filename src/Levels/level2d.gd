extends Node2D


func _ready() -> void:
	$"Player/Camera2D".limit_right = $TileMap.get_used_rect().end.x * $TileMap.tile_set.tile_size.x


func _on_node_teleport_started(node: Node) -> void:
	print("teleporting: ", node.name)
	$Smoother.reset_node(node)


func _on_node_screen_entered(node:Node) -> void:
	# method 1: keep default Smoother settings and exclude off-screen nodes
	$Smoother.remove_exclude_node(node)

	# method 2: set Smoother to smooth_parent: false, recursive: false and include on-screen nodes
#	$Smoother.add_include_node(node)

	print("smoothed nodes: ", $Smoother.smoothed_nodes.map(func (node:Node): return node.name))


func _on_node_screen_exited(node:Node) -> void:
	# method 1: keep default Smoother settings and exclude off-screen nodes
	$Smoother.add_exclude_node(node)

	# method 2: set Smoother to smooth_parent: false, recursive: false and include on-screen nodes
#	$Smoother.remove_include_node(node)

	print("smoothed nodes: ", $Smoother.smoothed_nodes.map(func (node:Node): return node.name))
