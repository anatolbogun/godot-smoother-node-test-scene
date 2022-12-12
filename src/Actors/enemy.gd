extends "res://src/Actors/actor.gd"

func _ready() -> void:
	super()
	velocity.x = -max_velocity.x

func _on_stomp_detector_body_entered(body: Node2D) -> void:
	if body.global_position.y > $StompDetector.global_position.y:
		return

	# TO DO: this is a potential error if the enemy has been destroyed but the
	# script is still trying to do something with the enemy's CollisionShape2D
	# which being the Enemy's child in this case no longer exists.
	# get_node_or_null("CollisionShape2D") may be the safer approach
	# or find out where and why the enemy was destroyed earlier because that
	# should be solely the job of queue_free() below
	# The error is:
	# Can't change this state while flushing queries. Use call_deferred() or set_deferred()
	# to change monitoring state instead. So (if we need $CollisionShape2D.disabled = true at all):
#	$CollisionShape2D.set_deferred("disabled", true)
#	$CollisionShape2D.disabled = true
	queue_free()

func _physics_process(delta: float) -> void:
	super(delta)

	velocity += gravity * delta

	if is_on_wall():
		velocity.x *= -1.0

