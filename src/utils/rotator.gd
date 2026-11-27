extends MeshInstance3D

@export var speed : float = 1.0

func _physics_process(delta: float) -> void:
	var rot = (rotation.y + delta * speed )
	if rot >= 360:
		rot = 0
	rotation.y = rot
