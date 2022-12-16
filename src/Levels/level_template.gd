extends Node2D


func _ready() -> void:
	$"Player/Camera2D".limit_right = $TileMap.get_used_rect().end.x * $TileMap.tile_set.tile_size.x


func _on_player_teleport_started(node) -> void:
	$Smoother.reset(node)
	pass


func _on_node_screen_entered(node) -> void:
	print("ENTERED SCREEN: ", node)
	# TO DO: update Smoother node includes or excludes arrays.
	# Also consider to have excludes overwrite includes in Smoother, should be super easy.
	# Then simply keep the usual setup but add all off-screen sprites to excludes.


func _on_node_screen_exited(node) -> void:
	print("EXITED SCREEN: ", node)
