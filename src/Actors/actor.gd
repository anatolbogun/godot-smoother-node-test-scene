extends CharacterBody2D
class_name Actor

@export var max_velocity: = Vector2(300, 1000)
@export var gravity: = Vector2(0, 3000)

signal screen_entered
signal screen_exited

# Note: For performance improvement, it may be advantageous to create and hook up a
# VisibleOnScreenNotifier2D via code if all/most moveable sprites extend this class, rather than
# having to remember to add one in the GUI node tree every time.

func _ready() -> void:
	print("ready: ", name)
	if $Label: $Label.text = name


func _enter_tree() -> void:
	# For performance improvement via the Smoother.excludes array:
	# The VisibleOnScreenNotifier2D signal on_screen_entered fires automatically, but not so the
	# on_screen_exited signal, so we also want to know at this point what nodes are not on screen.
	# To get an accurate is_on_screen() result we need to await RenderingServer.frame_post_draw, so
	# the nodes that should be smoothed with this optimisation can only be known on frame 2.
	# (This can be ignored for performance improvements via the Smoother.includes array.)

	await RenderingServer.frame_post_draw
#
	if !$VisibleOnScreenNotifier2D.is_on_screen():
		_on_screen_exited()


func _exit_tree() -> void:
	# For performance improvements (either method):
	# The VisibleOnScreenNotifier2D does not automatically emit the screen_exited signal when a node
	# exits the tree, so we better emit this manually to update the Smoother includes or excludes
	# array.
	_on_screen_exited()


func _physics_process(_delta: float) -> void:
	velocity = velocity.clamp(-max_velocity, max_velocity)
	move_and_slide()


func _on_screen_entered() -> void:
	emit_signal("screen_entered", self)


func _on_screen_exited() -> void:
	emit_signal("screen_exited", self)
