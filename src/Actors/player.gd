extends Actor

# Notes:
# - better than polling input events on every frame it should be better to use
#   func _unhandled_input(event: InputEvent) -> void: (try to change this)
# - I don't think it's a good idea to check stomp both in enemy and player
#   because it doesn't seem to be precise. e.g. it's possible for the player to
#   get a stomp impulse even if the enemy didn't die. Maybe instead the dying
#   enemy should emit a signal (either directly to the player or to a player
#   group) that tells the player that the enemy was killed successfully and the
#   stomp impulse happens only then (try to change this)
# - I'd be also cautious with checking the stomp (where the enemy dies) and the
#   the collision (where the player dies) using separate Area2D with collision
#   shapes. On low performance devices it may be conceivable that when multiple
#   frames are skipped, the player bypasses the enemy's StompDetector and dies
#   instead. But this may not be a problem in _physics_process which promises to
#   be called very regularly and code in there is automatically threaded.

@export var stomp_impulse: = 1000.0

func _ready() -> void:
	$Label.text = name

func _on_enemy_detector_area_entered(_area: Area2D) -> void:
	velocity = calculate_stomp_velocity(stomp_impulse)

func _on_enemy_detector_body_entered(_body: Node2D) -> void:
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
