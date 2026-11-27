extends SubViewportContainer

const CardObject = preload("res://src/presentation/card_object_3d.gd")
const BODY_PATH = "res://assets/3d/card_mesh.tres"
const ModelArtView = preload("res://src/presentation/model_art_view.gd")
const LIVE_ART = {"tabletop:1-001": "res://assets/3d/MERGED_popheart.blend"}
const LEGACY_POP_HEART = "res://src/cards/3dCard.tscn"
var live_art_source: SubViewport
var live_art_origin: String = ""
var front_source: Card
var back_source: Card
var front_view: SubViewport
var back_view: SubViewport
var world_view: SubViewport
var object: Node3D
var camera: Camera3D
var dragging: bool = false
var yaw: float = 0.0
var pitch: float = 0.0

# The two texture sources are ordinary catalogue card scenes, not a second
# implementation of printed fields. No dependencies on Blender import.
func setup(game: Game, definition: Dictionary, face_up: bool) -> bool:
	if definition.is_empty():
		return false
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = "Drag to rotate the card. Show card front/back resets orientation."
	var landscape = definition.type == Game.Card_Types.Place
	var pixels = Vector2i(442, 333) if landscape else Vector2i(333, 442)
	front_view = _make_source(pixels)
	back_view = _make_source(pixels)
	front_source = game.spawn_card_definition(definition, front_view)
	back_source = game.spawn_card_definition(definition, back_view)
	if front_source == null or back_source == null:
		return false
	for source in [front_source, back_source]:
		source.set_anchors_preset(Control.PRESET_TOP_LEFT)
		source.position = Vector2.ZERO
		source.size = Vector2(pixels)
		source.get_node("Button").mouse_filter = Control.MOUSE_FILTER_IGNORE
	front_source.set_face(true)
	back_source.set_face(false)
	_try_live_art(definition)
	world_view = SubViewport.new()
	world_view.name = "InspectionWorld"
	world_view.own_world_3d = true
	world_view.transparent_bg = true
	world_view.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(world_view)
	object = CardObject.new()
	world_view.add_child(object)
	var dimensions = Vector2(pixels) / float(maxi(pixels.x, pixels.y)) * 3.0
	var mesh: Mesh = null
	if ResourceLoader.exists(BODY_PATH, "Mesh"):
		mesh = ResourceLoader.load(BODY_PATH, "Mesh") as Mesh
	if not object.configure(front_view.get_texture(), back_view.get_texture(), dimensions, mesh):
		return false
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.position = Vector3(0, 0, 6)
	world_view.add_child(camera)
	camera.current = true
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -25, 0)
	world_view.add_child(light)
	resized.connect(_fit_camera)
	_fit_camera()
	set_face(face_up)
	return true

static func live_model_path(definition: Dictionary) -> String:
	var key = str(definition.get("edition", "tabletop")) + ":" + str(definition.get("number", ""))
	return LIVE_ART.get(key, "")

func _try_live_art(definition: Dictionary) -> void:
	var path = live_model_path(definition)
	if path.is_empty():
		return
	var subject: Node3D
	if ResourceLoader.exists(path, "PackedScene"):
		var packed = ResourceLoader.load(path, "PackedScene") as PackedScene
		if packed != null:
			var instance = packed.instantiate()
			if instance is Node3D:
				subject = instance
				live_art_origin = path
			else:
				instance.free()
	# The original packed scene contains the already embedded character.
	# Extract only that subtree before entering the tree, not the old stage.
	if subject == null and ResourceLoader.exists(LEGACY_POP_HEART, "PackedScene"):
		var legacy = ResourceLoader.load(LEGACY_POP_HEART, "PackedScene") as PackedScene
		if legacy != null:
			var stage = legacy.instantiate()
			var embedded = stage.get_node_or_null("MERGED_popheart") as Node3D
			if embedded != null:
				stage.remove_child(embedded)
				embedded.transform = Transform3D.IDENTITY
				subject = embedded
				live_art_origin = LEGACY_POP_HEART + "#MERGED_popheart"
			stage.free()
	if subject == null:
		push_warning("LOL_LIVE_ART unavailable; retaining static Pop Heart artwork")
		return
	var art = ModelArtView.new()
	art.name = "LiveArtwork"
	# Nested producer belongs to the front face; all are freed with inspector.
	front_view.add_child(art)
	var aperture = Vector2i(front_source.artwork_panel.size) * 2
	if not art.setup(subject, aperture) or not front_source.override_artwork_texture(art.get_texture()):
		art.free()
		live_art_origin = ""
		push_warning("LOL_LIVE_ART invalid model bounds; retaining static Pop Heart artwork")
		return
	live_art_source = art
	front_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	print("LOL_LIVE_ART card=1-001 meshes=%d source=%s" % [art.mesh_count, live_art_origin])

func _make_source(pixels: Vector2i) -> SubViewport:
	var viewport = SubViewport.new()
	viewport.size = pixels
	viewport.transparent_bg = true
	viewport.disable_3d = true
	# Static faces need only one render. The containing inspector remains live.
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	# Sibling viewports cannot be direct children of the stretching container.
	var sources = get_node_or_null("TextureSources")
	if sources == null:
		sources = Node.new()
		sources.name = "TextureSources"
		add_child(sources)
	sources.add_child(viewport)
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	return viewport

func _fit_camera() -> void:
	if not is_instance_valid(camera) or not is_instance_valid(object):
		return
	var aspect = maxf(0.01, size.x / maxf(1.0, size.y))
	camera.size = maxf(object.extent.y, object.extent.x / aspect) * 1.15

func set_face(up: bool) -> void:
	yaw = 0.0 if up else PI
	pitch = 0.0
	_apply_rotation()

func _apply_rotation() -> void:
	if is_instance_valid(object):
		object.rotation = Vector3(pitch, yaw, 0.0)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
		accept_event()
	elif event is InputEventMouseMotion and dragging:
		yaw = fposmod(yaw + event.relative.x * 0.012, TAU)
		pitch = clampf(pitch + event.relative.y * 0.012, -0.65, 0.65)
		_apply_rotation()
		accept_event()

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		dragging = false
