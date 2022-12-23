extends "res://src/Actors/actor.gd"


func _ready() -> void:
	super()
	velocity.x = -max_velocity.x


func _on_stomp_detector_body_entered(body: Node2D) -> void:
	if body.global_position.y > $StompDetector.global_position.y:
		return

	queue_free()


func _physics_process(delta: float) -> void:
	velocity += gravity * delta

	if is_on_wall():
		velocity.x *= -1.0

	super(delta)
