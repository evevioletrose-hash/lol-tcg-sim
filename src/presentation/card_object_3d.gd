extends Node3D
## A game-independent world-space card. Supply two textures and a face aspect.
## The host owns any SubViewports that produce those textures.

var body: MeshInstance3D
var front: MeshInstance3D
var back: MeshInstance3D
var extent: Vector2
var using_authored_mesh: bool = false
const THICKNESS = 0.035

func configure(front_texture: Texture2D, back_texture: Texture2D, dimensions: Vector2, authored_mesh: Mesh = null) -> bool:
	if front_texture == null or back_texture == null or dimensions.x <= 0 or dimensions.y <= 0:
		return false
	for child in get_children():
		child.free()
	extent = dimensions
	body = MeshInstance3D.new()
	body.name = "Body"
	var edge = StandardMaterial3D.new()
	edge.albedo_color = Color(0.36, 0.19, 0.39)
	edge.roughness = 0.6
	body.material_override = edge
	using_authored_mesh = false
	if authored_mesh != null:
		var bounds = authored_mesh.get_aabb()
		if bounds.size.x > 0 and bounds.size.y > 0 and bounds.size.z > 0:
			body.mesh = authored_mesh
			body.scale = Vector3(extent.x, extent.y, THICKNESS) / bounds.size
			body.position = -bounds.get_center() * body.scale
			using_authored_mesh = true
	if not using_authored_mesh:
		var box = BoxMesh.new()
		box.size = Vector3(extent.x, extent.y, THICKNESS)
		body.mesh = box
	add_child(body)
	front = _make_face("Front", front_texture, false)
	back = _make_face("Back", back_texture, true)
	return true

func _make_face(node_name: String, texture: Texture2D, reversed: bool) -> MeshInstance3D:
	var face = MeshInstance3D.new()
	face.name = node_name
	var quad = QuadMesh.new()
	quad.size = extent
	face.mesh = quad
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = texture
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.alpha_scissor_threshold = 0.5
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	face.material_override = material
	face.position.z = -(THICKNESS * 0.5 + 0.002) if reversed else THICKNESS * 0.5 + 0.002
	face.rotation.y = PI if reversed else 0.0
	add_child(face)
	return face
