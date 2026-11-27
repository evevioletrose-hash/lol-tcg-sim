extends SubViewport
## A texture-producing miniature scene, independent of card definitions.
var pivot: Node3D
var model: Node3D
var mesh_count: int = 0
var bounds: AABB

# Takes ownership of an unattached subject, including on failure.
func setup(subject: Node3D, resolution: Vector2i) -> bool:
	if subject == null:
		return false
	if resolution.x < 2 or resolution.y < 2 or not is_inside_tree():
		subject.free()
		return false
	size = resolution
	own_world_3d = true
	transparent_bg = true
	render_target_update_mode = SubViewport.UPDATE_DISABLED
	pivot = Node3D.new()
	add_child(pivot)
	var mount = Node3D.new()
	pivot.add_child(mount)
	model = subject
	# Imported cameras and lights belong to the old stage, not this one.
	for child in model.find_children("*", "Camera3D", true, false):
		child.free()
	for child in model.find_children("*", "Light3D", true, false):
		child.free()
	mount.add_child(model)
	var first = true
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance = node as MeshInstance3D
		if mesh_instance.mesh == null or not mesh_instance.is_visible_in_tree():
			continue
		var relative: Transform3D = mount.global_transform.affine_inverse() * mesh_instance.global_transform
		var box: AABB = relative * mesh_instance.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
		mesh_count += 1
	if first or not bounds.size.is_finite() or bounds.size.length() < 0.001:
		return false
	# Center and normalize once in mount coordinates. Leave skeleton/mesh
	# transforms intact. A bounding sphere keeps the rotating rest pose in frame.
	var factor = 2.0 / bounds.size.length()
	mount.scale = Vector3.ONE * factor
	mount.position = -bounds.get_center() * factor
	var camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.size = 2.25 * maxf(1.0, float(size.y) / float(size.x))
	camera.position = Vector3(0, 0, 4)
	add_child(camera)
	camera.current = true
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.16, 0.115, 0.18)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.82, 0.77, 0.91)
	environment.ambient_light_energy = 0.65
	var world_environment = WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-30, -35, 0)
	light.light_energy = 1.15
	add_child(light)
	var fill = DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(15, 145, 0)
	fill.light_energy = 0.65
	add_child(fill)
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	return true

func _process(delta: float) -> void:
	if is_instance_valid(pivot):
		pivot.rotation.y = fposmod(pivot.rotation.y + delta * 0.45, TAU)
