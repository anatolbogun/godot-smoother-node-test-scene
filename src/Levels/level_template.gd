extends Node2D


func _ready() -> void:
	$"Player/Camera2D".limit_right = $TileMap.get_used_rect().end.x * $TileMap.tile_set.tile_size.x


func _on_player_teleport_started(node) -> void:
	$Smoother.reset(node)
	pass
