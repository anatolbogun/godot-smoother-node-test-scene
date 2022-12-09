extends Node2D

func _ready() -> void:
	$"NestedTest/Player/Camera2D".limit_right = $TileMap.get_used_rect().end.x * $TileMap.tile_set.tile_size.x
