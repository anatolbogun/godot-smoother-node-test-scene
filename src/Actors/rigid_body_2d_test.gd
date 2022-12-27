extends RigidBody2D


func _ready() -> void:
	print("ready: ", name)
	if $Label: $Label.text = name


func _physics_process(delta: float) -> void:
	# RigidBody2D is not supported by the Smoother, so even though this node has
	# a custom _physics_process it gets ignored by the Smoother.
	if $Hint: $Hint.rotation = -rotation
