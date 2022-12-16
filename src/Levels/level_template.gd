extends Node2D

func _ready() -> void:
	$"Player/Camera2D".limit_right = $TileMap.get_used_rect().end.x * $TileMap.tile_set.tile_size.x

	var node = $RigidBody2DTest
	print( node is RigidBody2D, ", ", node.has_method("_physics_process"), ", ", node.get("position"))
