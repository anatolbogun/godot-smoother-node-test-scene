extends Node2D


func _ready() -> void:
	$"Player/Camera2D".limit_right = $TileMap.get_used_rect().end.x * $TileMap.tile_set.tile_size.x


func _on_node_teleport_started(node) -> void:
	$Smoother.reset_node(node)


func _on_node_screen_entered(node:Node) -> void:
	var excludes = $Smoother.remove_exclude_node(node)
	print("smoothed nodes: ", $Smoother.smoothed_nodes.map(func (node:Node): return node.name))


func _on_node_screen_exited(node:Node) -> void:
	var excludes = $Smoother.add_exclude_node(node)
	print("smoothed nodes: ", $Smoother.smoothed_nodes.map(func (node:Node): return node.name))
