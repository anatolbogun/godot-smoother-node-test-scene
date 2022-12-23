extends Actor

@export var stomp_impulse: = 1000.0

var origin: Vector2

signal teleport_started


func _ready() -> void:
	super()

	# the portal will simply teleport the player back to the original position
	origin = position


func _on_node_detector_area_entered(area: Area2D) -> void:
	if area.is_in_group("portals"):
		# Emitting teleport_started will call $Smoother.reset_node(node) in the level code so that
		# the teleported sprite position isn't interpolated during a teleport.
		emit_signal("teleport_started", self)

		# Teleport the player back to the original start position and reset the velocity.
		position = origin
		velocity = Vector2.ZERO
	else:
		velocity = calculate_stomp_velocity(stomp_impulse)


func _on_node_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		get_tree().reload_current_scene()


func _physics_process(delta: float) -> void:
	var is_jump_interrupted: = Input.is_action_just_released("jump") and velocity.y < 0.0
	var direction: = get_direction()
	velocity = calculate_move_velocity(direction, max_velocity, is_jump_interrupted)
	super(delta)


func get_direction() -> Vector2:
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		-1.0 if Input.is_action_just_pressed("jump") and is_on_floor() else 1.0
	)


func calculate_move_velocity(
	direction: Vector2,
	speed: Vector2,
	is_jump_interrupted: bool,
) -> Vector2:
	var new_velocity: = velocity
	new_velocity.x = speed.x * direction.x
	new_velocity += gravity * get_physics_process_delta_time()

	if direction.y == -1.0:
		new_velocity.y = speed.y * direction.y

	if is_jump_interrupted:
		new_velocity.y = 0

	return new_velocity


func calculate_stomp_velocity( impulse: float ) -> Vector2:
	var new_velocity: = velocity
	new_velocity.y = -impulse
	return new_velocity
