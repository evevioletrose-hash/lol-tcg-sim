extends Control

# This workshop inspects definitions. It does not create a match or run powers.
var game: Game
var preview: Card
var flip_button: Button
var inspect_3d_button: Button
var inspect_3d: SubViewportContainer
const Inspector3D = preload("res://src/card_viewer/card_inspector_3d.gd")
var selected_id: String = ""
var archivist: bool = false
var draft: Dictionary = {}
var filling: bool = false
var inputs: Dictionary = {}
var field_rows: Dictionary = {}
var editor_panel: VBoxContainer
var status: Label
var save_button: Button
var revert_button: Button
var close_dialog: ConfirmationDialog
var import_button: Button
var export_button: Button
var sheet_status: Label
var verification_filter: OptionButton
var verification_input: OptionButton
var source_input: LineEdit
var profile_store
var profile_selector: OptionButton
var profile_name: LineEdit
var profile_status: Label
var collection_kind: String = ""
var deck_mode: bool = false
var deck_policy: String = "unrestricted"
var deck_policy_selector: OptionButton
const DeckOwnership = preload("res://src/profiles/deck_ownership.gd")
var deck_panel: VBoxContainer
var deck_selector: OptionButton
var deck_name: LineEdit
var deck_rows: ItemList
var deck_summary: Label
var deck_notice: Label
var deck_add: Button
var deck_remove: Button
var deck_rename: Button
var deck_create: Button
var deck_snapshot: Dictionary = {}
var active_deck: String = ""
const DeckComposition = preload("res://src/profiles/deck_composition.gd")
const ChampionshipDeck = preload("res://src/rules/championship_deck.gd")
var deck_rules_button: Button
var deck_rules_dialog: AcceptDialog
var deck_rules_report: Dictionary = {}
var collection_mode: OptionButton
var developer_grants: bool = false
var grant_button: Button
var revoke_button: Button
var collection_summary: Label
var collection_controls: VBoxContainer
var ownership_filter: OptionButton
var collection_selected: Label
var collection_quantity: LineEdit
var collection_minus: Button
var collection_plus: Button
var collection_apply: Button
var collection_next: Button
var collection_notice: Label
const ProfileStore = preload("res://src/profiles/profile_store.gd")
const TYPED_FILTER = 101
const Reconciliation = preload("res://src/cards/catalogue_reconciliation.gd")
const ReconciliationWindow = preload("res://src/card_viewer/reconciliation_window.gd")
const INCOMPLETE_FILTER = 100

@onready var search: LineEdit = $Margin/Layout/Body/Catalogue/Search
@onready var type_filter: OptionButton = $Margin/Layout/Body/Catalogue/TypeFilter
@onready var count_label: Label = $Margin/Layout/Body/Catalogue/Count
@onready var cards: ItemList = $Margin/Layout/Body/Catalogue/Cards
@onready var preview_holder: Control = $Margin/Layout/Body/Inspection/Preview
@onready var details: RichTextLabel = $Margin/Layout/Body/Inspection/Details

func setup(source: Game, edit_mode: bool = false) -> void:
	game = source
	archivist = edit_mode
	get_viewport().size_changed.connect(_sync_viewport_layout)
	preview_holder.resized.connect(_fit_preview)
	_sync_viewport_layout()
	type_filter.add_item("All types", 0)
	type_filter.add_item("B.B.", Game.Card_Types.BB + 1)
	type_filter.add_item("Item", Game.Card_Types.Item + 1)
	type_filter.add_item("Surprise", Game.Card_Types.Surprise + 1)
	type_filter.add_item("Place", Game.Card_Types.Place + 1)
	if archivist:
		type_filter.add_item("Typed slots", TYPED_FILTER)
		type_filter.add_item("Incomplete slots", INCOMPLETE_FILTER)
		build_editor()
	flip_button = Button.new()
	flip_button.text = "Show card back"
	flip_button.disabled = true
	flip_button.pressed.connect(_flip_preview)
	var catalogue_panel = type_filter.get_parent()
	catalogue_panel.add_child(flip_button)
	catalogue_panel.move_child(flip_button, type_filter.get_index() + 1)
	inspect_3d_button = Button.new()
	inspect_3d_button.text = "Inspect in 3D"
	inspect_3d_button.disabled = true
	inspect_3d_button.visible = not archivist
	inspect_3d_button.pressed.connect(_toggle_3d)
	catalogue_panel.add_child(inspect_3d_button)
	catalogue_panel.move_child(inspect_3d_button, flip_button.get_index() + 1)
	type_filter.select(0)
	search.text_changed.connect(_on_search_changed)
	type_filter.item_selected.connect(_on_filter_changed)
	cards.item_selected.connect(_on_card_selected)
	refresh_list()

func layout_size() -> Vector2:
	# Headless DisplayServer has a tiny dummy window; use a virtual test area.
	if DisplayServer.get_name() == "headless":
		return Vector2(1152, 648)
	return get_viewport().get_visible_rect().size

func _sync_viewport_layout() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	grow_horizontal = Control.GROW_DIRECTION_END
	grow_vertical = Control.GROW_DIRECTION_END
	size = layout_size()
	position = Vector2.ZERO

func report_layout() -> void:
	var title: Label = $Margin/Layout/Title
	print("LOL_WORKSHOP_LAYOUT display=%s viewport=%s root=%s title=%s list=%s items=%d filter=%d visible=%s" % [
		DisplayServer.get_name(), get_viewport().get_visible_rect(), get_global_rect(),
		title.get_global_rect(), cards.get_global_rect(), cards.item_count,
		type_filter.get_selected_id(), is_visible_in_tree()
	])

func _on_search_changed(_value: String) -> void:
	refresh_list()

func _on_filter_changed(_index: int) -> void:
	refresh_list()

func _on_card_selected(index: int) -> void:
	var id = str(cards.get_item_metadata(index))
	if archivist and is_dirty():
		for i in range(cards.item_count):
			if cards.get_item_metadata(i) == selected_id:
				cards.select(i)
				break
		return
	show_card(id)

func type_name(value: int) -> String:
	match value:
		Game.Card_Types.BB: return "B.B."
		Game.Card_Types.Item: return "Item"
		Game.Card_Types.Surprise: return "Surprise"
		Game.Card_Types.Place: return "Place"
	return "Unknown"

func club_name(data: Dictionary) -> String:
	if not data.has("club"):
		return ""
	return str(Game.Clubs.keys()[data.club]).replace("_", " ")

func phase_name(data: Dictionary) -> String:
	if data.has("printed_phase"):
		return str(data.printed_phase) if not str(data.printed_phase).strip_edges().is_empty() else "Not catalogued"
	if not data.has("phase"):
		return ""
	match data.phase:
		Game.Game_Phases.Any_Phase: return "Any Phase"
		Game.Game_Phases.Call_BB: return "Call Your B.B.s"
		Game.Game_Phases.Dress_Up: return "Dress Up"
		Game.Game_Phases.Dance_Off: return "Dance Off"
	return "Unknown"

func refresh_list() -> void:
	var previous_id = selected_id
	cards.clear()
	var ids = game.catalogue.records.keys() if archivist or not collection_kind.is_empty() else game.card_database.keys()
	ids.sort()
	var query = search.text.strip_edges().to_lower()
	var exact_number = ""
	# In collection mode a short numeric query is an exact set-one card number.
	if (not collection_kind.is_empty() or deck_mode) and query.is_valid_int() and query.length() <= 3 and int(query) > 0:
		exact_number = "1-%03d" % int(query)
	var filter_id = type_filter.get_selected_id()
	var selection_index = -1
	for id in ids:
		if not exact_number.is_empty() and id != exact_number:
			continue
		var raw: Dictionary = game.catalogue.records[id]
		var typed = game.card_database.has(id)
		var kind = game.get_card_type(str(raw.get("type", "")))
		if filter_id == INCOMPLETE_FILTER:
			if typed:
				continue
		elif filter_id == TYPED_FILTER:
			if not typed:
				continue
		elif filter_id > 0 and (not typed or kind != filter_id - 1):
			continue
		if archivist and verification_filter.selected > 0:
			if game.catalogue.verification(raw) != verification_filter.get_item_metadata(verification_filter.selected):
				continue
		var quantity = 0
		if not collection_kind.is_empty():
			quantity = profile_store.count(collection_kind, profile_store.card_key("tabletop", id))
			if ownership_filter.selected == 1 and quantity == 0:
				continue
			if ownership_filter.selected == 2 and quantity > 0:
				continue
		if deck_mode and deck_policy != "unrestricted":
			var key = "tabletop:" + id
			if profile_store.count(deck_policy, key) == 0 and int(_deck_counts().get(key, 0)) == 0:
				continue
		var searchable = "%s %s %s %s %s %s" % [id, raw.name, raw.club, raw.text, raw.phase, game.catalogue.source_reference(raw)]
		if exact_number.is_empty() and not query.is_empty() and not searchable.to_lower().contains(query):
			continue
		var display_name = "" if raw.name == null else str(raw.name)
		if display_name.is_empty():
			display_name = "(unnamed)"
		if not typed:
			display_name += " [incomplete]"
		if archivist and game.catalogue.verification(raw) != "unverified":
			display_name += " [" + game.catalogue.verification(raw) + "]"
		var display = "%s  %s" % [id, display_name]
		if not collection_kind.is_empty():
			display += "  ×" + str(quantity)
		elif deck_mode:
			var key = "tabletop:" + id
			var used = int(_deck_counts().get(key, 0))
			display += "  ×" + str(used)
			if deck_policy != "unrestricted":
				var owned: int = profile_store.count(deck_policy, key)
				display += " / " + str(owned)
				if used > owned:
					display += " [short]"
		var index = cards.add_item(display)
		cards.set_item_metadata(index, id)
		if id == previous_id:
			selection_index = index
	count_label.text = "%d / %d cards" % [cards.item_count, ids.size()]
	if not collection_kind.is_empty():
		_update_collection_summary()
	if cards.item_count == 0:
		clear_preview()
		details.text = "No matching cards."
		if archivist:
			draft.clear()
			editor_panel.hide()
		if not collection_kind.is_empty():
			_update_collection_selection()
		if deck_mode:
			_update_deck_buttons()
		return
	if selection_index < 0:
		selection_index = 0
	cards.select(selection_index)
	_on_card_selected(selection_index)

func _flip_preview() -> void:
	if not is_instance_valid(preview):
		return
	preview.set_face(not preview.face_up)
	if is_instance_valid(inspect_3d):
		inspect_3d.set_face(preview.face_up)
	_sync_flip_button()

func _sync_flip_button() -> void:
	flip_button.disabled = not is_instance_valid(preview)
	flip_button.text = "Show card front" if is_instance_valid(preview) and not preview.face_up else "Show card back"
	inspect_3d_button.disabled = archivist or not is_instance_valid(preview)

func _close_3d() -> void:
	if is_instance_valid(inspect_3d):
		inspect_3d.free()
	inspect_3d = null
	if is_instance_valid(preview):
		preview.show()
	inspect_3d_button.text = "Inspect in 3D"

func _toggle_3d() -> void:
	if is_instance_valid(inspect_3d):
		_close_3d()
		return
	if archivist or not is_instance_valid(preview) or not game.card_database.has(selected_id):
		return
	var candidate = Inspector3D.new()
	preview_holder.add_child(candidate)
	candidate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not candidate.setup(game, game.card_database[selected_id], preview.face_up):
		candidate.free()
		inspect_3d_button.tooltip_text = "3D unavailable; showing the 2D card."
		return
	inspect_3d = candidate
	preview.hide()
	inspect_3d_button.text = "Return to 2D"
	inspect_3d_button.tooltip_text = ""

func clear_preview() -> void:
	_close_3d()
	if is_instance_valid(preview):
		preview.free()
	preview = null
	selected_id = ""
	_sync_flip_button()

func show_card(id: String) -> void:
	clear_preview()
	selected_id = id
	if archivist:
		load_draft(id)
		return
	if not game.card_database.has(id):
		var raw: Dictionary = game.catalogue.records[id]
		var raw_name = "(unnamed)" if raw.name == null or str(raw.name).is_empty() else str(raw.name)
		details.text = "%s\n%s\nIncomplete definition. Ownership can still be displayed; development grants require a typed card." % [raw_name, id]
		if not collection_kind.is_empty():
			_update_collection_selection()
		return
	var data: Dictionary = game.card_database[id]
	var lines: PackedStringArray = [
		data.name, id, type_name(data.type), "Rank: %s" % data.rank
	]
	if data.type == Game.Card_Types.BB:
		lines.append("Club: " + club_name(data))
		lines.append("Starting Style: " + str(data.style))
		lines.append("Starting Groove: " + str(data.groove))
	elif data.type == Game.Card_Types.Surprise:
		lines.append("Phase: " + phase_name(data))
	lines.append("")
	lines.append(data.text)
	preview = game.spawn_card(id, preview_holder)
	if is_instance_valid(preview):
		_configure_preview()
		lines.append("")
		lines.append("Artwork: " + ("available" if preview.artwork_status == "available" else "not available"))
	details.text = "\n".join(lines)
	_sync_flip_button()
	if not collection_kind.is_empty():
		_update_collection_selection()
	if deck_mode:
		_update_deck_buttons()

func _configure_preview() -> void:
	preview.set_anchors_preset(Control.PRESET_TOP_LEFT)
	preview.position = Vector2.ZERO
	preview.size = preview.presentation_size()
	preview.get_node("Button").mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fit_preview()

func _fit_preview() -> void:
	if not is_instance_valid(preview):
		return
	# Preserve the approved portrait rendering; landscape fits available width.
	var extent: Vector2 = preview.presentation_size()
	var fit: float = minf(1.0, preview_holder.size.x / extent.x)
	preview.scale = Vector2.ONE * maxf(0.01, fit)

func run_smoke_test() -> int:
	var counts: Dictionary = {}
	var failures: Array[String] = []
	var title: Label = $Margin/Layout/Title
	var viewport_rect = Rect2(Vector2.ZERO, layout_size())
	report_layout()
	if not is_visible_in_tree() or size.x <= 0 or size.y <= 0:
		failures.append("Workshop root is hidden or has no size")
	if not title.is_visible_in_tree() or not viewport_rect.intersects(title.get_global_rect()):
		failures.append("Workshop title is outside viewport")
	if cards.size.x <= 0 or cards.size.y <= 0:
		failures.append("Catalogue has no layout area")
	if cards.item_count != game.card_database.size():
		failures.append("Initial catalogue list is incomplete")
	if not viewport_rect.encloses(get_global_rect()):
		failures.append("Workshop root lies outside layout area")
	if not viewport_rect.intersects(cards.get_global_rect()):
		failures.append("Catalogue list lies outside layout area")
	# Exercise filters through the same refresh path used by signals.
	for index in range(1, type_filter.item_count):
		type_filter.select(index)
		refresh_list()
		var wanted = type_filter.get_selected_id() - 1
		var expected = 0
		for data in game.card_database.values():
			if data.type == wanted:
				expected += 1
		if cards.item_count != expected:
			failures.append("Type filter count mismatch: " + type_name(wanted))
	type_filter.select(0)
	var first_id = str(game.card_database.keys()[0]) if not game.card_database.is_empty() else ""
	search.text = first_id
	refresh_list()
	if not first_id.is_empty() and (cards.item_count != 1 or selected_id != first_id):
		failures.append("Card ID search failed")
	search.text = ""
	refresh_list()
	if cards.item_count != game.card_database.size():
		failures.append("Clearing search failed")
	for id in game.card_database:
		var data: Dictionary = game.card_database[id]
		show_card(id)
		var kind = type_name(data.type)
		counts[kind] = counts.get(kind, 0) + 1
		if preview == null:
			failures.append(id + ": missing preview")
		else:
			if preview.card_name != data.name or preview.catalogue_id != id:
				failures.append(id + ": identity mismatch")
			if preview.cardnum_ui.text != id or preview.rank_ui.text != str(data.rank):
				failures.append(id + ": printed identity mismatch")
			if data.type == Game.Card_Types.BB:
				if preview.get_node("Card/Style").text != data.style or preview.get_node("Card/Groove").text != data.groove:
					failures.append(id + ": stat mismatch")
			if preview.get_node("Card/Text/card_text").text != data.text:
				failures.append(id + ": effect text mismatch")
	refresh_list()
	if game.card_database.size() != game.catalogue.typed_count():
		failures.append("Runtime typed count differs from canonical catalogue")
	for failure in failures:
		push_error(failure)
	print("LOL_WORKSHOP counts=%s failures=%d" % [str(counts), failures.size()])
	return 0 if failures.is_empty() else 1

func build_editor() -> void:
	$Margin/Layout/Title.text = "Dance Off / Card Archivist (Tabletop)"
	verification_filter = OptionButton.new()
	verification_filter.add_item("All verification states")
	for state in game.catalogue.VERIFICATION_STATES:
		verification_filter.add_item(state.capitalize())
		verification_filter.set_item_metadata(verification_filter.item_count - 1, state)
	verification_filter.select(0)
	var catalogue_panel = type_filter.get_parent()
	catalogue_panel.add_child(verification_filter)
	catalogue_panel.move_child(verification_filter, type_filter.get_index() + 1)
	verification_filter.item_selected.connect(_on_filter_changed)
	$Margin/Layout/Body.split_offset = 270
	details.hide()
	var toolbar = HBoxContainer.new()
	var layout = $Margin/Layout
	layout.add_child(toolbar)
	layout.move_child(toolbar, 1)
	import_button = Button.new()
	import_button.text = "Import spreadsheet..."
	import_button.pressed.connect(open_sheet_dialog.bind(false))
	toolbar.add_child(import_button)
	export_button = Button.new()
	export_button.text = "Export spreadsheet..."
	export_button.pressed.connect(open_sheet_dialog.bind(true))
	toolbar.add_child(export_button)
	sheet_status = Label.new()
	sheet_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sheet_status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	toolbar.add_child(sheet_status)
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.x = 275
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	details.get_parent().add_child(scroll)
	editor_panel = VBoxContainer.new()
	editor_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(editor_panel)
	for field in ["name", "type", "rank", "club", "style", "groove", "phase", "text"]:
		var row = VBoxContainer.new()
		editor_panel.add_child(row)
		field_rows[field] = row
		var label = Label.new()
		label.text = "Printed effect / flavour text" if field == "text" else field.capitalize()
		row.add_child(label)
		if field in ["type", "club", "phase"]:
			var choice = OptionButton.new()
			row.add_child(choice)
			inputs[field] = choice
			choice.item_selected.connect(_choice_changed.bind(field))
		elif field == "text":
			var area = TextEdit.new()
			area.custom_minimum_size.y = 105
			area.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
			row.add_child(area)
			inputs[field] = area
			area.text_changed.connect(_effect_changed)
		else:
			var line = LineEdit.new()
			row.add_child(line)
			inputs[field] = line
			line.text_changed.connect(_set_draft_field.bind(field))
	editor_panel.add_child(HSeparator.new())
	var source_label = Label.new()
	source_label.text = "Source reference / evidence (tabletop)"
	editor_panel.add_child(source_label)
	source_input = LineEdit.new()
	source_input.placeholder_text = "Scan path, URL, or transcription note"
	source_input.text_changed.connect(_source_changed)
	editor_panel.add_child(source_input)
	var verification_label = Label.new()
	verification_label.text = "Verification"
	editor_panel.add_child(verification_label)
	verification_input = OptionButton.new()
	for state in game.catalogue.VERIFICATION_STATES:
		verification_input.add_item(state.capitalize())
	verification_input.item_selected.connect(_verification_changed)
	editor_panel.add_child(verification_input)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	editor_panel.add_child(status)
	var buttons = HBoxContainer.new()
	editor_panel.add_child(buttons)
	save_button = Button.new()
	save_button.text = "Save card"
	save_button.pressed.connect(save_draft)
	buttons.add_child(save_button)
	revert_button = Button.new()
	revert_button.text = "Revert"
	revert_button.pressed.connect(revert_draft)
	buttons.add_child(revert_button)
	get_tree().auto_accept_quit = false
	close_dialog = ConfirmationDialog.new()
	close_dialog.title = "Discard unsaved changes?"
	close_dialog.dialog_text = "This card has unsaved changes. Quit without saving?"
	close_dialog.confirmed.connect(func(): get_tree().quit())
	add_child(close_dialog)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and archivist:
		if is_dirty():
			close_dialog.popup_centered()
		else:
			get_tree().quit()

func choices_for(field: String) -> Array:
	match field:
		"type": return ["", "BB", "Items", "Surprise", "Place"]
		"phase": return ["", "Any Phase", "Call your B.B.'s", "Dress Up", "Dance Off"]
		"club":
			var values: Array = [""]
			for key in Game.Clubs.keys():
				if key != "Unknown":
					values.append(str(key).replace("_", " "))
			return values
	return []

func load_draft(id: String) -> void:
	draft = game.catalogue.records[id].duplicate(true)
	filling = true
	editor_panel.show()
	for field in inputs:
		var value = "" if draft[field] == null else str(draft[field])
		var control = inputs[field]
		if control is OptionButton:
			control.clear()
			var options = choices_for(field)
			if not value in options:
				options.append(value)
			for option in options:
				control.add_item("(unknown / blank)" if option == "" else option)
				control.set_item_metadata(control.item_count - 1, option)
			control.select(options.find(value))
		else:
			control.text = value
	source_input.text = game.catalogue.source_reference(draft)
	verification_input.select(game.catalogue.VERIFICATION_STATES.find(game.catalogue.verification(draft)))
	filling = false
	update_draft()

func _choice_changed(index: int, field: String) -> void:
	_set_draft_field(str(inputs[field].get_item_metadata(index)), field)

func _effect_changed() -> void:
	_set_draft_field(inputs["text"].text, "text")

func _set_draft_field(value: String, field: String) -> void:
	if filling or draft.is_empty():
		return
	if draft.get(field) != value:
		draft[field] = value
		game.catalogue.invalidate_verification(draft)
		verification_input.select(game.catalogue.VERIFICATION_STATES.find(game.catalogue.verification(draft)))
	update_draft()

func _source_changed(value: String) -> void:
	if filling or draft.is_empty():
		return
	if value != game.catalogue.source_reference(draft):
		draft["source"] = value
		game.catalogue.invalidate_verification(draft)
		verification_input.select(game.catalogue.VERIFICATION_STATES.find(game.catalogue.verification(draft)))
	update_draft()

func _verification_changed(index: int) -> void:
	if filling or draft.is_empty():
		return
	draft["verification"] = game.catalogue.VERIFICATION_STATES[index]
	update_draft()

func is_dirty() -> bool:
	return not selected_id.is_empty() and not draft.is_empty() and draft != game.catalogue.records.get(selected_id)

func update_draft() -> void:
	var dirty = is_dirty()
	var problem = game.catalogue.validate_edit(selected_id, draft)
	save_button.disabled = not dirty or not problem.is_empty()
	revert_button.disabled = not dirty
	search.editable = not dirty
	type_filter.disabled = dirty
	verification_filter.disabled = dirty
	import_button.disabled = dirty
	export_button.disabled = dirty
	cards.mouse_filter = Control.MOUSE_FILTER_IGNORE if dirty else Control.MOUSE_FILTER_STOP
	cards.focus_mode = Control.FOCUS_NONE if dirty else Control.FOCUS_ALL
	field_rows["club"].visible = draft.type == "BB"
	field_rows["style"].visible = draft.type == "BB"
	field_rows["groove"].visible = draft.type == "BB"
	field_rows["phase"].visible = draft.type == "Surprise"
	status.text = selected_id + (" / Unsaved: save or revert to switch cards" if dirty else " / Saved record")
	if not problem.is_empty():
		status.text += "\n" + problem
	if is_instance_valid(preview):
		preview.free()
	preview = null
	var projected = game.project_card_data(game.catalogue.legacy_row(draft), false)
	if projected.is_empty():
		status.text += "\nIncomplete definition: name and type needed for preview."
	else:
		preview = game.spawn_card_definition(projected, preview_holder)
		if is_instance_valid(preview):
			_configure_preview()
			preview.rank_ui.text = "?" if draft.rank == null or draft.rank == "" else str(draft.rank)
			status.text += "\nArtwork: " + preview.artwork_status
	_sync_flip_button()

func save_draft() -> void:
	if not is_dirty():
		return
	var problem = game.catalogue.save_record(selected_id, draft)
	if not problem.is_empty():
		status.text = problem
		return
	game.refresh_card_definition(selected_id)
	# Keep the saved card selected if a type change would hide it.
	search.text = ""
	type_filter.select(0)
	verification_filter.select(0)
	refresh_list()
	status.text = selected_id + " / Saved to catalogue"

func revert_draft() -> void:
	if not selected_id.is_empty():
		load_draft(selected_id)

func run_editor_test() -> int:
	var failures: Array[String] = []
	if cards.item_count != game.catalogue.records.size():
		failures.append("All-slot listing mismatch")
	type_filter.select(type_filter.item_count - 1)
	refresh_list()
	if cards.item_count != game.catalogue.records.size() - game.card_database.size():
		failures.append("Incomplete filter mismatch")
	type_filter.select(0)
	search.text = "1-055"
	refresh_list()
	if selected_id != "1-055":
		failures.append("Incomplete search failed")
		return 1
	var original: Dictionary = game.catalogue.records[selected_id].duplicate(true)
	var original_runtime = game.card_database.get(selected_id)
	var test_name = ("Fixture" if original.name == null else str(original.name)) + " [test]"
	var original_dir: String = game.catalogue.card_dir
	var fixture = "user://catalogue-test-" + str(Time.get_ticks_usec()) + "/"
	if DirAccess.make_dir_recursive_absolute(fixture) != OK:
		push_error("Cannot create test fixture")
		return 1
	var id = selected_id
	var path = fixture.path_join(id + ".json")
	if DirAccess.copy_absolute(original_dir.path_join(id + ".json"), path) != OK:
		push_error("Cannot copy test fixture")
		return 1
	game.catalogue.card_dir = fixture
	_set_draft_field(test_name, "name")
	_set_draft_field("Items", "type")
	_set_draft_field("2", "rank")
	if not is_dirty() or preview == null or preview.card_name != test_name.strip_edges() or game.card_database.get(id) != original_runtime:
		failures.append("Draft preview or isolation failed")
	_set_draft_field("bad", "rank")
	if not save_button.disabled:
		failures.append("Invalid rank accepted")
	revert_draft()
	if is_dirty() or draft != original:
		failures.append("Revert failed")
	_set_draft_field(test_name, "name")
	_set_draft_field("Items", "type")
	_set_draft_field("2", "rank")
	save_draft()
	if is_dirty() or not game.card_database.has(id) or game.card_database[id].name != test_name.strip_edges() or game.catalogue.read_json(path) != game.catalogue.records[id]:
		failures.append("Save/reload or runtime projection failed")
	# Restore the real catalogue path, then reload original records.
	game.catalogue.card_dir = original_dir
	game.load_cardlist()
	refresh_list()
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(fixture)
	if game.catalogue.records[id] != original:
		failures.append("Canonical record unexpectedly changed")
	for failure in failures:
		push_error(failure)
	print("LOL_ARCHIVIST slots=%d failures=%d" % [game.catalogue.records.size(), failures.size()])
	return 0 if failures.is_empty() else 1

func open_sheet_dialog(exporting: bool) -> void:
	if is_dirty():
		return
	var dialog = FileDialog.new()
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE if exporting else FileDialog.FILE_MODE_OPEN_FILE
	dialog.title = "Export catalogue" if exporting else "Import spreadsheet for review"
	dialog.add_filter("*.csv", "CSV spreadsheet")
	dialog.add_filter("*.tsv, *.txt", "Tab-separated text")
	if exporting:
		dialog.current_file = "catalogue.csv"
	dialog.file_selected.connect(sheet_file_selected.bind(exporting))
	dialog.file_selected.connect(func(_path): dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered_ratio(0.8)

func sheet_file_selected(path: String, exporting: bool) -> void:
	if is_dirty():
		return
	var plan = Reconciliation.new()
	if exporting:
		# Export must never overwrite canonical JSON or original source snapshot.
		if not path.get_extension().to_lower() in ["csv", "tsv", "txt"] or path.simplify_path() == ProjectSettings.globalize_path("res://cardlist.txt").simplify_path():
			sheet_status.text = "Choose a new CSV or TSV file, not the original source."
			return
		var problem = plan.export_sheet(game.catalogue, path)
		sheet_status.text = "Export saved." if problem.is_empty() else problem
		return
	if plan.read_sheet(path):
		plan.compare(game.catalogue)
	var window = ReconciliationWindow.new()
	add_child(window)
	window.records_saved.connect(refresh_list)
	window.setup(game, plan)

func run_reconciliation_test() -> int:
	var failures: Array[String] = []
	var plan = Reconciliation.new()
	var dir = "user://reconcile-test-" + str(Time.get_ticks_usec()) + "/"
	if DirAccess.make_dir_recursive_absolute(dir) != OK:
		push_error("Cannot create reconciliation fixture")
		return 1
	var csv = dir.path_join("roundtrip.csv")
	var tsv = dir.path_join("roundtrip.tsv")
	for path in [csv, tsv]:
		if not plan.export_sheet(game.catalogue, path).is_empty() or not plan.read_sheet(path) or not plan.compare(game.catalogue) or not plan.changes.is_empty():
			failures.append("Round trip failed: " + path)
	var legacy = Reconciliation.new()
	if not legacy.read_sheet("res://cardlist.txt"):
		failures.append("Original TSV parsing failed")
	else:
		# Original may differ intentionally after transcription; compare raw source syntax.
		if legacy.rows.size() != 400 or legacy.rows["1-003"].text != "\"Tag! Ur it!\"":
			failures.append("Original TSV quote preservation failed")
	var id = "1-055"
	var original: Dictionary = game.catalogue.records[id].duplicate(true)
	var fixture_path = dir.path_join(id + ".json")
	var original_dir: String = game.catalogue.card_dir
	if DirAccess.copy_absolute(original_dir.path_join(id + ".json"), fixture_path) != OK:
		push_error("Cannot copy reconciliation fixture")
		return 1
	game.catalogue.card_dir = dir
	var fixture_csv = dir.path_join("changes.csv")
	var file = FileAccess.open(fixture_csv, FileAccess.WRITE)
	file.store_csv_line(PackedStringArray(["id", "name", "type", "rank", "text", "Have"]))
	file.store_csv_line(PackedStringArray([id, "Fixture name", "Items", "2", "Line 1, \"quote\"\nLine 2", "99"]))
	file.close()
	plan = Reconciliation.new()
	if not plan.read_sheet(fixture_csv) or not plan.compare(game.catalogue) or plan.changes.size() != 1:
		failures.append("Conflict preview failed")
	else:
		var chosen = plan.missing_choices()
		if not plan.cell(original.name).is_empty() and chosen.get(id, {}).has("name"):
			failures.append("Nonblank value selected by fill shortcut")
		if not plan.apply_selected(game.catalogue, {}).saved.is_empty() or game.catalogue.records[id] != original:
			failures.append("No-op changed record")
		var selection = {id: {"text":true}}
		var result = plan.apply_selected(game.catalogue, selection)
		if not result.error.is_empty() or result.saved != [id] or game.catalogue.records[id].name != original.name or game.catalogue.records[id].text != "Line 1, \"quote\"\nLine 2":
			failures.append("Selective save / quoted multiline failed")
		if plan.apply_selected(game.catalogue, selection).error.is_empty():
			failures.append("Stale baseline accepted")
		plan.read_sheet(fixture_csv)
		plan.compare(game.catalogue)
		var bad = FileAccess.open(fixture_path, FileAccess.WRITE)
		bad.store_string("{}")
		bad.close()
		if plan.apply_selected(game.catalogue, {id: {"name":true}}).error.is_empty():
			failures.append("External change accepted")
	file = FileAccess.open(fixture_csv, FileAccess.WRITE)
	file.store_string("id,name\n" + id + ",one\n" + id + ",two\n")
	file.close()
	if plan.read_sheet(fixture_csv):
		failures.append("Duplicate ID accepted")
	file = FileAccess.open(fixture_csv, FileAccess.WRITE)
	file.store_string("id,name\n9-999,unknown\n")
	file.close()
	if not plan.read_sheet(fixture_csv) or plan.compare(game.catalogue):
		failures.append("Unknown ID accepted")
	game.catalogue.card_dir = original_dir
	game.load_cardlist()
	refresh_list()
	if game.catalogue.records[id] != original:
		failures.append("Canonical record changed")
	for path in [csv, tsv, fixture_csv, fixture_path]:
		DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(dir)
	for failure in failures:
		push_error(failure)
	print("LOL_RECONCILIATION failures=%d" % failures.size())
	return 0 if failures.is_empty() else 1

func run_provenance_test() -> int:
	var failures: Array[String] = []
	var id = "1-001"
	var original: Dictionary = game.catalogue.records[id].duplicate(true)
	var original_dir: String = game.catalogue.card_dir
	var fixture = "user://provenance-test-" + str(Time.get_ticks_usec()) + "/"
	if DirAccess.make_dir_recursive_absolute(fixture) != OK:
		push_error("Cannot create provenance fixture")
		return 1
	var path = fixture.path_join(id + ".json")
	if DirAccess.copy_absolute(original_dir.path_join(id + ".json"), path) != OK:
		push_error("Cannot copy provenance fixture")
		return 1
	game.catalogue.card_dir = fixture
	search.text = id
	refresh_list()
	_set_draft_field("Fixture Pop Heart", "name")
	_set_draft_field("BB", "type")
	_set_draft_field("1", "rank")
	_source_changed("")
	_verification_changed(2)
	if not save_button.disabled:
		failures.append("Verified without evidence accepted")
	_source_changed("fixture scan reference")
	_verification_changed(2)
	if save_button.disabled:
		failures.append("Valid verification rejected")
	save_draft()
	if game.catalogue.verification(game.catalogue.records[id]) != "verified" or game.catalogue.read_json(path) != game.catalogue.records[id]:
		failures.append("Provenance save/reload failed")
	verification_filter.select(3)
	refresh_list()
	var found = false
	for index in range(cards.item_count):
		if cards.get_item_metadata(index) == id:
			found = true
	if not found:
		failures.append("Verified filter omitted fixture")
	show_card(id)
	_set_draft_field("Fixture changed", "name")
	if game.catalogue.verification(draft) != "unverified" or game.catalogue.source_reference(draft) != "fixture scan reference":
		failures.append("Printed edit did not invalidate verification")
	revert_draft()
	if game.catalogue.verification(draft) != "verified":
		failures.append("Revert lost verification")
	var comparison = Reconciliation.new()
	comparison.rows[id] = {"id": id, "text": "fixture changed effect"}
	if not comparison.compare(game.catalogue):
		failures.append("Provenance reconciliation comparison failed")
	else:
		var result: Dictionary = comparison.apply_selected(game.catalogue, {id: {"text": true}})
		if not result.error.is_empty() or game.catalogue.verification(game.catalogue.records[id]) != "unverified" or game.catalogue.source_reference(game.catalogue.records[id]) != "fixture scan reference":
			failures.append("Import did not invalidate verification")
	# Reset selection/draft before replacing the in-memory fixture.
	draft.clear()
	selected_id = ""
	game.catalogue.card_dir = original_dir
	game.load_cardlist()
	verification_filter.select(0)
	search.text = ""
	refresh_list()
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(fixture)
	if game.catalogue.records[id] != original:
		failures.append("Canonical record changed")
	for failure in failures:
		push_error(failure)
	print("LOL_PROVENANCE edition=tabletop failures=%d" % failures.size())
	return 0 if failures.is_empty() else 1

# Player profiles are intentionally absent from the developer archivist.
func attach_profiles(store, allow_developer_grants: bool = false) -> void:
	profile_store = store
	developer_grants = allow_developer_grants and OS.has_feature("editor")
	var layout = $Margin/Layout
	var toolbar = HBoxContainer.new()
	layout.add_child(toolbar)
	layout.move_child(toolbar, 1)
	var label = Label.new()
	label.text = "Collector"
	toolbar.add_child(label)
	profile_selector = OptionButton.new()
	profile_selector.custom_minimum_size.x = 150
	profile_selector.item_selected.connect(_profile_selected)
	toolbar.add_child(profile_selector)
	profile_name = LineEdit.new()
	profile_name.placeholder_text = "New profile name"
	profile_name.max_length = 64
	profile_name.custom_minimum_size.x = 175
	toolbar.add_child(profile_name)
	var create = Button.new()
	create.text = "Create profile"
	create.pressed.connect(_create_profile)
	profile_name.text_submitted.connect(func(_value: String): _create_profile())
	toolbar.add_child(create)
	profile_status = Label.new()
	profile_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(profile_status)
	layout.move_child(profile_status, 2)
	var problem: String = profile_store.initialize()
	if not problem.is_empty():
		push_warning("LOL_PROFILE_INIT: " + problem)
		profile_status.text = problem
		profile_status.tooltip_text = problem
		profile_selector.disabled = true
		profile_name.editable = false
		create.disabled = true
		return
	_build_collection_controls()
	_build_deck_controls()
	_refresh_profiles()

func _refresh_profiles(message: String = "") -> void:
	profile_selector.clear()
	var active_index = -1
	for entry in profile_store.list_profiles():
		profile_selector.add_item(entry.name)
		var index = profile_selector.item_count - 1
		profile_selector.set_item_metadata(index, entry.profile_id)
		if entry.profile_id == profile_store.active_id:
			active_index = index
	profile_selector.select(active_index)
	if message.is_empty():
		message = "Active: " + str(profile_store.profile.get("name", ""))
	if not profile_store.warnings.is_empty():
		message += " | " + "; ".join(PackedStringArray(profile_store.warnings))
	profile_status.text = message
	profile_status.tooltip_text = message
	if is_instance_valid(collection_summary):
		_update_collection_summary()
	if deck_mode:
		_reload_decks()
		_update_deck_policy_heading()
		refresh_list()
	elif not collection_kind.is_empty():
		collection_notice.text = ""
		refresh_list()

func _profile_selected(index: int) -> void:
	var id = str(profile_selector.get_item_metadata(index))
	var problem: String = profile_store.switch_profile(id)
	_refresh_profiles(problem)

func _create_profile() -> void:
	var result: Dictionary = profile_store.create_profile(profile_name.text)
	if not result.error.is_empty():
		_refresh_profiles(result.error)
		return
	profile_name.clear()
	var problem: String = profile_store.switch_profile(result.id)
	_refresh_profiles(problem)

func _build_collection_controls() -> void:
	var layout = $Margin/Layout
	var mode_row = HBoxContainer.new()
	layout.add_child(mode_row)
	layout.move_child(mode_row, 3)
	collection_mode = OptionButton.new()
	for label in ["Card Workshop", "Physical collection", "In-game collection", "Deck Builder"]:
		collection_mode.add_item(label)
	collection_mode.item_selected.connect(_collection_mode_selected)
	mode_row.add_child(collection_mode)
	collection_summary = Label.new()
	collection_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	collection_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mode_row.add_child(collection_summary)
	collection_controls = VBoxContainer.new()
	layout.add_child(collection_controls)
	layout.move_child(collection_controls, 4)
	var row = HBoxContainer.new()
	collection_controls.add_child(row)
	ownership_filter = OptionButton.new()
	for option in ["All slots", "Owned", "Missing"]:
		ownership_filter.add_item(option)
	ownership_filter.select(0)
	ownership_filter.item_selected.connect(_on_filter_changed)
	row.add_child(ownership_filter)
	collection_selected = Label.new()
	collection_selected.custom_minimum_size.x = 110
	row.add_child(collection_selected)
	collection_minus = Button.new()
	collection_minus.text = "−1"
	collection_minus.pressed.connect(_adjust_physical.bind(-1))
	row.add_child(collection_minus)
	collection_quantity = LineEdit.new()
	collection_quantity.custom_minimum_size.x = 100
	collection_quantity.max_length = 10
	collection_quantity.placeholder_text = "Copies"
	collection_quantity.text_submitted.connect(func(_value: String): _apply_physical_quantity())
	row.add_child(collection_quantity)
	collection_plus = Button.new()
	collection_plus.text = "+1"
	collection_plus.pressed.connect(_adjust_physical.bind(1))
	row.add_child(collection_plus)
	collection_apply = Button.new()
	collection_apply.text = "Set copies"
	collection_apply.pressed.connect(_apply_physical_quantity)
	row.add_child(collection_apply)
	grant_button = Button.new()
	grant_button.text = "Dev grant +1"
	grant_button.pressed.connect(_developer_adjust.bind(1))
	row.add_child(grant_button)
	revoke_button = Button.new()
	revoke_button.text = "Dev remove −1"
	revoke_button.pressed.connect(_developer_adjust.bind(-1))
	row.add_child(revoke_button)
	collection_next = Button.new()
	collection_next.text = "Next card"
	collection_next.pressed.connect(_next_collection_card)
	row.add_child(collection_next)
	collection_notice = Label.new()
	collection_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	collection_controls.add_child(collection_notice)
	collection_controls.hide()
	_update_collection_summary()

func _collection_mode_selected(index: int) -> void:
	if index == 3:
		_set_deck_mode()
	else:
		_set_collection_mode(["", "physical", "digital"][index])

# Keep the physical regression exercising the same shared browser.
func _set_physical_mode(enabled: bool) -> void:
	_set_collection_mode("physical" if enabled else "")

func _set_collection_mode(kind: String) -> void:
	if not kind in ["", "physical", "digital"]:
		return
	deck_mode = false
	if is_instance_valid(deck_panel):
		deck_panel.hide()
	details.show()
	collection_kind = kind
	collection_mode.select(["", "physical", "digital"].find(kind))
	collection_controls.visible = not kind.is_empty()
	collection_notice.text = ""
	var heading = "Card Workshop"
	if kind == "physical":
		heading = "Physical Collection"
	elif kind == "digital":
		heading = "In-game Collection"
	$Margin/Layout/Title.text = "Dance Off / " + heading
	search.placeholder_text = "Card number (e.g. 55), name, club or effect..." if not kind.is_empty() else "Search number, name, club or effect..."
	type_filter.select(0)
	ownership_filter.select(0)
	collection_minus.visible = kind == "physical"
	collection_plus.visible = kind == "physical"
	collection_apply.visible = kind == "physical"
	grant_button.visible = kind == "digital" and developer_grants
	revoke_button.visible = kind == "digital" and developer_grants
	_update_collection_summary()
	refresh_list()

func _summary_for(kind: String) -> String:
	var known = 0
	var copies = 0
	var outside = 0
	var counts: Dictionary = profile_store.collection(kind)
	for key in counts:
		var card_id = str(key).trim_prefix("tabletop:")
		if str(key).begins_with("tabletop:") and game.catalogue.records.has(card_id):
			known += 1
			copies += int(counts[key])
		else:
			outside += 1
	var summary = "%s: %d / %d slots • %d copies • %d duplicates" % ["Physical" if kind == "physical" else "In-game", known, game.catalogue.records.size(), copies, copies - known]
	if outside > 0:
		summary += " • %d other keys preserved" % outside
	return summary

func _update_collection_summary() -> void:
	collection_summary.text = _summary_for(collection_kind if not collection_kind.is_empty() else "physical")
	if collection_kind == "digital" and developer_grants:
		collection_summary.text += " • DEVELOPMENT GRANTS ENABLED"

func _update_collection_selection() -> void:
	var valid = not selected_id.is_empty() and game.catalogue.records.has(selected_id)
	var quantity = profile_store.count(collection_kind, profile_store.card_key("tabletop", selected_id)) if valid else 0
	collection_selected.text = selected_id if valid else "No card"
	collection_quantity.text = str(quantity) if valid else ""
	collection_quantity.editable = valid and collection_kind == "physical"
	collection_minus.disabled = not valid or quantity == 0
	collection_plus.disabled = not valid or quantity >= ProfileStore.MAX_COUNT
	collection_apply.disabled = not valid
	grant_button.disabled = not valid or not game.card_database.has(selected_id) or quantity >= ProfileStore.MAX_COUNT
	revoke_button.disabled = not valid or quantity == 0
	var selected = cards.get_selected_items()
	collection_next.disabled = not valid or selected.is_empty() or selected[0] + 1 >= cards.item_count

func _developer_adjust(delta: int) -> void:
	if collection_kind != "digital" or not developer_grants or not game.catalogue.records.has(selected_id):
		return
	var id = selected_id
	var key: String = profile_store.card_key("tabletop", id)
	var problem: String
	if delta == 1 and game.card_database.has(id):
		problem = profile_store.acquire_cards({key: 1}, profile_store.active_id)
	elif delta == -1:
		problem = profile_store.remove("digital", key)
	else:
		return
	_finish_collection_write(id, problem)

func _adjust_physical(delta: int) -> void:
	if collection_kind != "physical" or not game.catalogue.records.has(selected_id):
		return
	var id = selected_id
	var problem: String = profile_store.adjust("physical", profile_store.card_key("tabletop", id), delta)
	_finish_collection_write(id, problem)

func _apply_physical_quantity() -> void:
	if collection_kind != "physical" or not game.catalogue.records.has(selected_id):
		return
	var value = collection_quantity.text.strip_edges()
	if not value.is_valid_int() or int(value) < 0 or int(value) > ProfileStore.MAX_COUNT:
		collection_notice.text = "Enter a whole number from 0 to " + str(ProfileStore.MAX_COUNT) + "."
		return
	var id = selected_id
	var key: String = profile_store.card_key("tabletop", id)
	var delta: int = int(value) - profile_store.count("physical", key)
	var problem: String = profile_store.adjust("physical", key, delta)
	_finish_collection_write(id, problem)

func _finish_collection_write(id: String, problem: String) -> void:
	if not problem.is_empty():
		collection_notice.text = problem
		_update_collection_selection()
		return
	var quantity: int = profile_store.count(collection_kind, profile_store.card_key("tabletop", id))
	refresh_list()
	collection_notice.text = "%s: %d %s copies saved." % [id, quantity, "physical" if collection_kind == "physical" else "in-game"]
	# Keep the selected row visible during long collection-entry sessions.
	if cards.item_count > 0:
		cards.ensure_current_is_visible()

func _next_collection_card() -> void:
	var selected = cards.get_selected_items()
	if collection_kind.is_empty() or selected.is_empty() or selected[0] + 1 >= cards.item_count:
		return
	var index = selected[0] + 1
	cards.select(index)
	_on_card_selected(index)
	cards.ensure_current_is_visible()
	collection_notice.text = ""

func run_physical_collection_test() -> int:
	var failures: Array[String] = []
	var store = ProfileStore.new()
	store.root = "user://physical-test-" + Crypto.new().generate_random_bytes(12).hex_encode() + "/"
	attach_profiles(store)
	if store.active_id.is_empty() or not is_instance_valid(collection_mode):
		push_error("Physical fixture initialization failed")
		return 1
	var id = "1-001"
	var incomplete = "1-055"
	var key = store.card_key("tabletop", id)
	var incomplete_key = store.card_key("tabletop", incomplete)
	var original: Dictionary = game.catalogue.records[id].duplicate(true)
	if not store.add("digital", key, 4).is_empty():
		failures.append("Digital fixture failed")
	if not store.add("physical", "digital:1-001", 7).is_empty():
		failures.append("Outside edition fixture failed")
	_set_physical_mode(true)
	if cards.item_count != game.catalogue.records.size():
		failures.append("All numbered slots not visible")
	search.text = "1"
	refresh_list()
	if cards.item_count != 1 or selected_id != id:
		failures.append("Short card number search")
	_adjust_physical(1)
	_adjust_physical(1)
	if store.count("physical", key) != 2 or collection_quantity.text != "2":
		failures.append("Quick add")
	collection_quantity.text = "5"
	_apply_physical_quantity()
	if store.count("physical", key) != 5:
		failures.append("Set copies")
	collection_quantity.text = "-1"
	_apply_physical_quantity()
	if store.count("physical", key) != 5:
		failures.append("Negative entry accepted")
	_adjust_physical(-1)
	if store.count("physical", key) != 4:
		failures.append("Quick remove")
	search.text = incomplete
	refresh_list()
	if selected_id != incomplete:
		failures.append("Incomplete card missing")
	_adjust_physical(1)
	if store.count("physical", incomplete_key) != 1:
		failures.append("Incomplete slot ownership")
	search.text = ""
	ownership_filter.select(1)
	refresh_list()
	if cards.item_count != 2 or not collection_summary.text.contains("2 / ") or not collection_summary.text.contains("5 copies"):
		failures.append("Owned filter or summary")
	ownership_filter.select(2)
	refresh_list()
	if cards.item_count != game.catalogue.records.size() - 2:
		failures.append("Missing filter")
	ownership_filter.select(0)
	search.text = id
	refresh_list()
	collection_quantity.text = "0"
	_apply_physical_quantity()
	if store.collection("physical").has(key) or store.count("digital", key) != 4:
		failures.append("Zero removal or digital isolation")
	profile_name.text = "Second collector"
	_create_profile()
	var second_id: String = store.active_id
	if second_id == "default" or store.count("physical", incomplete_key) != 0:
		failures.append("Profile creation/isolation")
	search.text = incomplete
	refresh_list()
	_adjust_physical(1)
	_adjust_physical(1)
	for index in range(profile_selector.item_count):
		if profile_selector.get_item_metadata(index) == "default":
			_profile_selected(index)
			break
	if store.active_id != "default" or store.count("physical", incomplete_key) != 1 or collection_quantity.text != "1":
		failures.append("Profile switch refresh")
	var reopened = ProfileStore.new()
	reopened.root = store.root
	if not reopened.initialize().is_empty() or reopened.count("physical", incomplete_key) != 1 or reopened.count("digital", key) != 4 or reopened.count("physical", "digital:1-001") != 7:
		failures.append("Collection reload or outside edition preservation")
	if second_id != "default":
		if not reopened.switch_profile(second_id).is_empty() or reopened.count("physical", incomplete_key) != 2:
			failures.append("Second profile reload")
	if game.catalogue.records[id] != original:
		failures.append("Canonical definition changed")
	_set_physical_mode(false)
	if cards.item_count != (1 if game.card_database.has(incomplete) else 0):
		failures.append("Normal workshop search after collection mode")
	search.text = ""
	refresh_list()
	if cards.item_count != game.card_database.size():
		failures.append("Normal workshop scope")
	# Remove only the disposable fixture's explicitly known files.
	for entry in store.list_profiles():
		var directory = store.root.path_join(entry.profile_id)
		for filename in ["profile.json", "physical_collection.json", "digital_collection.json"]:
			for suffix in ["", ".bak"]:
				var path = directory.path_join(filename + suffix)
				if FileAccess.file_exists(path):
					DirAccess.remove_absolute(path)
		DirAccess.remove_absolute(directory.path_join("decks"))
		DirAccess.remove_absolute(directory)
	for suffix in ["", ".bak"]:
		var path = store.root.path_join("active_profile.json" + suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(store.root)
	for failure in failures:
		push_error(failure)
	print("LOL_PHYSICAL slots=%d failures=%d" % [game.catalogue.records.size(), failures.size()])
	return 0 if failures.is_empty() else 1

func run_digital_collection_test() -> int:
	var failures: Array[String] = []
	var store = ProfileStore.new()
	store.root = "user://digital-test-" + Crypto.new().generate_random_bytes(12).hex_encode() + "/"
	attach_profiles(store)
	if store.active_id.is_empty() or not is_instance_valid(collection_mode):
		push_error("Digital fixture initialization failed")
		return 1
	var id = "1-001"
	var key = store.card_key("tabletop", id)
	var other = store.card_key("tabletop", "1-002")
	var original: Dictionary = game.catalogue.records[id].duplicate(true)
	if not store.add("physical", key, 8).is_empty():
		failures.append("Physical fixture")
	_set_collection_mode("digital")
	search.text = "1"
	refresh_list()
	if selected_id != id or collection_quantity.text != "0" or collection_quantity.editable or collection_plus.visible or grant_button.visible:
		failures.append("Read-only in-game browser or physical isolation")
	_developer_adjust(1)
	_adjust_physical(1)
	collection_quantity.text = "6"
	_apply_physical_quantity()
	if store.count("digital", key) != 0 or store.count("physical", key) != 8:
		failures.append("Normal browser allowed edits")
	var reward = {key: 2, other: 1}
	if not store.acquire_cards(reward, store.active_id).is_empty():
		failures.append("Batch acquisition")
	if store.count("digital", key) != 2 or store.count("digital", other) != 1:
		failures.append("Batch quantities")
	var before: Dictionary = store.collection("digital")
	for bad in [{key: 1, other: -1}, {key: 1, "bad": 2}, {key: 1, other: 2147483647}, {key: 1, other: 0}, {key: 1, other: 1.5}]:
		if store.acquire_cards(bad, store.active_id).is_empty() or store.collection("digital") != before:
			failures.append("Invalid batch accepted or partially applied")
	if store.acquire_cards({key: 1}, "another-profile").is_empty():
		failures.append("Wrong-profile reward accepted")
	search.text = ""
	ownership_filter.select(1)
	refresh_list()
	if cards.item_count != 2 or not collection_summary.text.contains("3 copies") or not collection_summary.text.contains("1 duplicates"):
		failures.append("Owned filter or summary")
	ownership_filter.select(2)
	refresh_list()
	if cards.item_count != game.catalogue.records.size() - 2:
		failures.append("Missing filter")
	developer_grants = true # fixture only; real attach_profiles checks editor flag
	_set_collection_mode("digital")
	search.text = id
	refresh_list()
	if not grant_button.visible or not revoke_button.visible:
		failures.append("Development controls absent")
	_developer_adjust(1)
	_developer_adjust(-1)
	if store.count("digital", key) != 2:
		failures.append("Development grant/remove")
	search.text = "1-055"
	refresh_list()
	if not grant_button.disabled:
		failures.append("Untyped grant enabled")
	_developer_adjust(1)
	if store.count("digital", "tabletop:1-055") != 0:
		failures.append("Untyped grant accepted")
	profile_name.text = "Second player"
	_create_profile()
	var second_id: String = store.active_id
	if second_id == "default" or store.count("digital", key) != 0:
		failures.append("Profile isolation")
	if not store.acquire_cards({key: 5}, second_id).is_empty():
		failures.append("Second player reward")
	for index in range(profile_selector.item_count):
		if profile_selector.get_item_metadata(index) == "default":
			_profile_selected(index)
			break
	search.text = id
	refresh_list()
	if store.active_id != "default" or collection_quantity.text != "2" or store.count("physical", key) != 8:
		failures.append("Profile switch refresh")
	_set_collection_mode("physical")
	if collection_quantity.text != "8" or not collection_quantity.editable or grant_button.visible:
		failures.append("Shared physical browser")
	var reopened = ProfileStore.new()
	reopened.root = store.root
	if not reopened.initialize().is_empty() or reopened.collection("digital") != before or reopened.count("physical", key) != 8:
		failures.append("Batch persistence or isolation")
	if second_id != "default":
		if not reopened.switch_profile(second_id).is_empty() or reopened.count("digital", key) != 5:
			failures.append("Second player persistence")
	if game.catalogue.records[id] != original:
		failures.append("Canonical record changed")
	_set_collection_mode("")
	search.text = ""
	refresh_list()
	if cards.item_count != game.card_database.size():
		failures.append("Normal browsing scope")
	for entry in store.list_profiles():
		var directory = store.root.path_join(entry.profile_id)
		for filename in ["profile.json", "physical_collection.json", "digital_collection.json"]:
			for suffix in ["", ".bak"]:
				var path = directory.path_join(filename + suffix)
				if FileAccess.file_exists(path):
					DirAccess.remove_absolute(path)
		DirAccess.remove_absolute(directory.path_join("decks"))
		DirAccess.remove_absolute(directory)
	for suffix in ["", ".bak"]:
		var path = store.root.path_join("active_profile.json" + suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(store.root)
	for failure in failures:
		push_error(failure)
	print("LOL_DIGITAL slots=%d failures=%d" % [game.catalogue.records.size(), failures.size()])
	return 0 if failures.is_empty() else 1

func run_artwork_test() -> int:
	var failures: Array[String] = []
	var resolver = preload("res://src/cards/card_artwork.gd")
	var sample_path = "res://assets/card arts/1-001.jpg"
	var sample: Dictionary = resolver.resolve("tabletop", "1-001")
	if sample.path != sample_path or sample.status != "available" or not sample.texture is Texture2D:
		failures.append("Pop Heart artwork failed to resolve; import the existing JPEG")
	if resolver.path_for("digital", "1-001") != "" or resolver.path_for("tabletop", "../1-001") != "":
		failures.append("Artwork identity isolation")
	if resolver.load_texture("res://assets/card arts/__missing_artwork_fixture__.png") != null:
		failures.append("Missing texture did not return null")
	var available = 0
	var placeholders = 0
	var unsupported = 0
	for id in game.card_database:
		show_card(id)
		if preview == null:
			unsupported += 1
			failures.append(id + ": missing card scene")
			continue
		var expected: Dictionary = resolver.resolve("tabletop", id)
		if preview.artwork != expected.path or preview.artwork_status != expected.status:
			failures.append(id + ": artwork identity mismatch")
		if preview.artwork_texture.texture != expected.texture:
			failures.append(id + ": texture binding mismatch")
		if expected.texture == null:
			placeholders += 1
			if not preview.artwork_placeholder.visible or preview.artwork_texture.visible:
				failures.append(id + ": missing artwork fallback not visible")
		else:
			available += 1
			if preview.artwork_placeholder.visible or not preview.artwork_texture.visible:
				failures.append(id + ": valid texture not visible")
		if preview.artwork_panel.size.x <= 0 or preview.artwork_panel.size.y <= 0:
			failures.append(id + ": invalid artwork aperture")
	# Reuse one live B.B. scene to exercise clearing the previous card's texture.
	show_card("1-001")
	if preview != null:
		preview.set_face(false)
		if preview.artwork_panel.visible:
			failures.append("Face-down artwork leaked")
		preview.set_face(true)
		if not preview.artwork_panel.visible:
			failures.append("Face-up artwork did not return")
		if game.card_database.has("1-400"):
			preview.populate(game.card_database["1-400"])
			var rare: Dictionary = resolver.resolve("tabletop", "1-400")
			if preview.artwork_texture.texture != rare.texture or preview.artwork_placeholder.visible != (rare.texture == null):
				failures.append("Repopulation retained stale artwork")
			preview.populate(game.card_database["1-001"])
			if preview.artwork_texture.texture != sample.texture:
				failures.append("Repopulation failed to restore original artwork")
	refresh_list()
	for failure in failures:
		push_error(failure)
	print("LOL_ARTWORK available=%d placeholders=%d unsupported=%d failures=%d" % [available, placeholders, unsupported, failures.size()])
	return 0 if failures.is_empty() else 1

func run_bb_presentation_test() -> int:
	var failures: Array[String] = []
	var tested = 0
	var frame = Rect2(0, 0, 331, 436)
	for id in game.card_database:
		var data: Dictionary = game.card_database[id]
		if data.type != Game.Card_Types.BB:
			continue
		show_card(id)
		if preview == null:
			failures.append(id + ": missing B.B.")
			continue
		tested += 1
		var face = preview.get_node("Card")
		var name_label: Label = face.get_node("Name")
		var club_label: Label = face.get_node("Club")
		var style_label: Label = face.get_node("Style")
		var groove_label: Label = face.get_node("Groove")
		var power: RichTextLabel = face.get_node("Text/card_text")
		if name_label.text != data.name or style_label.text != data.style or groove_label.text != data.groove or power.text != data.text:
			failures.append(id + ": printed field mismatch")
		if preview.cardnum_ui.text != id or preview.rank_ui.text != str(data.rank):
			failures.append(id + ": footer mismatch")
		for region in ["Name", "Club", "StyleBadge", "GrooveBadge", "Text", "img/Artwork", "img/card_num", "img/card_rank"]:
			var node: Control = face.get_node(region)
			var local_rect = Rect2(node.global_position - face.global_position, node.size)
			if not frame.encloses(local_rect):
				failures.append(id + ": region outside face: " + region)
		if name_label.get_rect().intersects(club_label.get_rect()) or name_label.get_rect().intersects(face.get_node("StyleBadge").get_rect()):
			failures.append(id + ": header overlap")
		_flip_preview()
		if preview.face_up or not preview.cardback_ui.visible or name_label.visible or power.is_visible_in_tree() or preview.artwork_panel.visible or preview.rank_ui.visible:
			failures.append(id + ": front content visible on back")
		_flip_preview()
		if not preview.face_up or preview.cardback_ui.visible or not name_label.visible or not preview.artwork_panel.visible:
			failures.append(id + ": failed to restore front")
	# Long names and effects are exercised on an in-memory definition, never saved.
	var sample: Dictionary = game.card_database["1-001"].duplicate(true)
	sample.name = "An exceptionally long B.B. name for a layout stress fixture"
	sample.text = "A long power description. ".repeat(24)
	clear_preview()
	preview = game.spawn_card_definition(sample, preview_holder)
	if preview == null:
		failures.append("Long text fixture failed to spawn")
	else:
		var long_name: Label = preview.get_node("Card/Name")
		var long_power: RichTextLabel = preview.get_node("Card/Text/card_text")
		if long_name.text != sample.name or long_power.text != sample.text or long_name.max_lines_visible != 2:
			failures.append("Long text fixture lost content or wrap limit")
	refresh_list()
	for failure in failures:
		push_error(failure)
	print("LOL_BB_PRESENTATION cards=%d failures=%d" % [tested, failures.size()])
	return 0 if failures.is_empty() else 1

func run_card_family_test() -> int:
	var failures: Array[String] = []
	var counts: Dictionary = {}
	for id in game.card_database:
		var data: Dictionary = game.card_database[id]
		show_card(id)
		if preview == null:
			failures.append(id + ": missing preview")
			continue
		var kind = type_name(data.type)
		counts[kind] = counts.get(kind, 0) + 1
		var face: Control = preview.get_node("Card")
		var frame: Control = face.get_node("img")
		var landscape = data.type == Game.Card_Types.Place
		var wanted_size = Vector2(436, 331) if landscape else Vector2(331, 436)
		if frame.size != wanted_size or preview.presentation_size() != (Vector2(442, 333) if landscape else Vector2(333, 442)):
			failures.append(id + ": native orientation mismatch")
		var power: RichTextLabel = face.get_node("Text/card_text")
		var name_label: Label = face.get_node("Name")
		if power.text != data.text or name_label.text != data.name or preview.cardnum_ui.text != id or preview.rank_ui.text != str(data.rank):
			failures.append(id + ": printed field mismatch")
		if data.type == Game.Card_Types.Surprise:
			var expected = str(data.printed_phase).to_upper() if not str(data.printed_phase).strip_edges().is_empty() else "PHASE NOT CATALOGUED"
			if face.get_node("Phase").text != expected:
				failures.append(id + ": printed timing mismatch")
		var power_panel: Control = face.get_node("Text")
		if not Rect2(Vector2.ZERO, wanted_size).encloses(power_panel.get_rect()) or not Rect2(Vector2.ZERO, wanted_size).encloses(preview.artwork_panel.get_rect()):
			failures.append(id + ": panel outside frame")
		if power_panel.get_rect().intersects(preview.artwork_panel.get_rect()):
			failures.append(id + ": artwork/power overlap")
		if preview.scale.x != preview.scale.y or preview.presentation_size().x * preview.scale.x > preview_holder.size.x + 0.1:
			failures.append(id + ": preview width/scale mismatch")
		_flip_preview()
		if preview.face_up or not preview.cardback_ui.visible or name_label.visible or power.is_visible_in_tree() or preview.artwork_panel.visible or preview.rank_ui.visible:
			failures.append(id + ": front content visible on back")
		if landscape and (not is_equal_approx(preview.cardback_ui.rotation_degrees, 90.0) or preview.cardback_ui.position != Vector2(436, 0)):
			failures.append(id + ": landscape back orientation")
		_flip_preview()
		if not preview.face_up or preview.cardback_ui.visible or not name_label.visible or not power.is_visible_in_tree():
			failures.append(id + ": front not restored")
	refresh_list()
	for failure in failures:
		push_error(failure)
	print("LOL_CARD_FAMILY counts=%s failures=%d" % [str(counts), failures.size()])
	return 0 if failures.is_empty() else 1

func run_3d_preview_test() -> int:
	var failures: Array[String] = []
	var ids: Array[String] = []
	for kind in [Game.Card_Types.BB, Game.Card_Types.Item, Game.Card_Types.Surprise, Game.Card_Types.Place]:
		for id in game.card_database:
			if game.card_database[id].type == kind:
				ids.append(id)
				break
	for id in ids:
		show_card(id)
		_toggle_3d()
		if not is_instance_valid(inspect_3d):
			failures.append(id + ": failed to open 3D")
			continue
		var definition: Dictionary = game.card_database[id]
		var inspector = inspect_3d
		if preview.visible or inspector.front_source.catalogue_id != id or inspector.back_source.catalogue_id != id:
			failures.append(id + ": 2D/3D identity mismatch")
		if inspector.front_source.card_name != definition.name or inspector.front_source.text != definition.text or inspector.front_source.rank != definition.rank:
			failures.append(id + ": 2D/3D printed field mismatch")
		if not inspector.front_source.face_up or inspector.back_source.face_up:
			failures.append(id + ": front/back source state")
		if inspector.front_source.type == Game.Card_Types.BB:
			if inspector.front_source.base_style != definition.style or inspector.front_source.base_groove != definition.groove:
				failures.append(id + ": B.B. stat parity")
		if not inspector.object.using_authored_mesh:
			failures.append(id + ": original card body unavailable")
		if (inspector.object.extent.x > inspector.object.extent.y) != (definition.type == Game.Card_Types.Place):
			failures.append(id + ": physical orientation")
		_flip_preview()
		if not is_equal_approx(inspector.object.rotation.y, PI) or preview.face_up:
			failures.append(id + ": flip sync")
		_toggle_3d()
		if is_instance_valid(inspect_3d) or not preview.visible or preview.face_up:
			failures.append(id + ": 2D restore")
	# A generic host can supply textures without any authored geometry.
	var image = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var texture = ImageTexture.create_from_image(image)
	var standalone = preload("res://src/presentation/card_object_3d.gd").new()
	if not standalone.configure(texture, texture, Vector2(2, 3)) or standalone.using_authored_mesh or not standalone.body.mesh is BoxMesh:
		failures.append("Portable fallback body")
	standalone.free()
	show_card("1-001")
	_toggle_3d()
	if not is_instance_valid(inspect_3d) or not is_instance_valid(inspect_3d.live_art_source):
		failures.append("Pop Heart live model not available")
	else:
		if inspect_3d.live_art_source.mesh_count <= 0 or inspect_3d.front_source.artwork_status != "live_3d" or inspect_3d.front_source.artwork_texture.texture != inspect_3d.live_art_source.get_texture():
			failures.append("Pop Heart live texture binding")
		if inspect_3d.front_view.render_target_update_mode != SubViewport.UPDATE_ALWAYS or preview.artwork_status == "live_3d":
			failures.append("Live update or 2D isolation")
		if inspect_3d.back_view.render_target_update_mode == SubViewport.UPDATE_ALWAYS:
			failures.append("Static back unexpectedly live")
	var previous_art = weakref(inspect_3d.live_art_source) if is_instance_valid(inspect_3d) and is_instance_valid(inspect_3d.live_art_source) else null
	show_card("1-400")
	if previous_art != null and previous_art.get_ref() != null:
		failures.append("Live art viewport leaked")
	if is_instance_valid(inspect_3d) or not preview.visible:
		failures.append("Selection did not dispose 3D inspector")
	_toggle_3d()
	if not is_instance_valid(inspect_3d) or is_instance_valid(inspect_3d.live_art_source):
		failures.append("Rare Pop Heart inherited live art")
	if not Inspector3D.live_model_path({"edition": "digital", "number": "1-001"}).is_empty():
		failures.append("Historical digital ID inherited live art")
	refresh_list()
	for failure in failures:
		push_error(failure)
	print("LOL_3D_PREVIEW types=%d failures=%d" % [ids.size(), failures.size()])
	return 0 if failures.is_empty() else 1

# Deck editing shares the catalogue/preview but never writes an inventory.
func _build_deck_controls() -> void:
	deck_panel = VBoxContainer.new()
	deck_panel.custom_minimum_size.x = 250
	deck_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.get_parent().add_child(deck_panel)
	var heading = Label.new()
	heading.text = "Saved decks"
	deck_panel.add_child(heading)
	deck_policy_selector = OptionButton.new()
	for label in ["Unrestricted sandbox", "Physical collection", "In-game collection"]:
		deck_policy_selector.add_item(label)
	deck_policy_selector.item_selected.connect(_deck_policy_selected)
	deck_panel.add_child(deck_policy_selector)
	deck_selector = OptionButton.new()
	deck_selector.item_selected.connect(_deck_selected)
	deck_panel.add_child(deck_selector)
	deck_name = LineEdit.new()
	deck_name.placeholder_text = "Deck name"
	deck_name.max_length = 64
	deck_panel.add_child(deck_name)
	var names = HBoxContainer.new()
	deck_panel.add_child(names)
	deck_create = Button.new()
	deck_create.text = "New deck"
	deck_create.pressed.connect(_create_deck)
	names.add_child(deck_create)
	deck_rename = Button.new()
	deck_rename.text = "Rename"
	deck_rename.pressed.connect(_rename_deck)
	names.add_child(deck_rename)
	deck_summary = Label.new()
	deck_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	deck_panel.add_child(deck_summary)
	deck_rules_button = Button.new()
	deck_rules_button.text = "Championship details"
	deck_rules_button.pressed.connect(_show_deck_rules)
	deck_panel.add_child(deck_rules_button)
	deck_rules_dialog = AcceptDialog.new()
	deck_rules_dialog.title = "Championship deck validation"
	deck_rules_dialog.min_size = Vector2i(480, 260)
	var rules_text = RichTextLabel.new()
	rules_text.name = "Report"
	rules_text.bbcode_enabled = false
	rules_text.custom_minimum_size = Vector2(460, 200)
	deck_rules_dialog.add_child(rules_text)
	add_child(deck_rules_dialog)
	deck_rows = ItemList.new()
	deck_rows.size_flags_vertical = Control.SIZE_EXPAND_FILL
	deck_rows.custom_minimum_size.y = 90
	deck_rows.item_selected.connect(func(_index: int): _update_deck_buttons())
	deck_rows.item_activated.connect(_inspect_deck_row)
	deck_panel.add_child(deck_rows)
	deck_add = Button.new()
	deck_add.text = "Add selected catalogue card +1"
	deck_add.pressed.connect(_add_deck_card)
	deck_panel.add_child(deck_add)
	deck_remove = Button.new()
	deck_remove.text = "Remove selected deck card -1"
	deck_remove.pressed.connect(_remove_deck_card)
	deck_panel.add_child(deck_remove)
	deck_notice = Label.new()
	deck_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	deck_panel.add_child(deck_notice)
	deck_panel.hide()

func _set_deck_mode() -> void:
	_set_collection_mode("")
	deck_mode = true
	collection_mode.select(3)
	_update_deck_policy_heading()
	$Margin/Layout/Title.text = "Dance Off / Deck Builder"
	details.hide()
	deck_panel.show()
	_reload_decks()
	refresh_list()

func _deck_policy_selected(index: int) -> void:
	if index >= 0 and index < DeckOwnership.MODES.size():
		_set_deck_policy(DeckOwnership.MODES[index])

func _set_deck_policy(policy: String) -> void:
	if not deck_mode or not policy in DeckOwnership.MODES:
		return
	deck_policy = policy
	deck_policy_selector.select(DeckOwnership.MODES.find(policy))
	_update_deck_policy_heading()
	_refresh_deck_rows()
	refresh_list()

func _update_deck_policy_heading() -> void:
	var label = "Unrestricted drafts" if deck_policy == "unrestricted" else ("Physical collection" if deck_policy == "physical" else "In-game collection")
	collection_summary.text = label + " • changes save immediately"
	deck_policy_selector.select(DeckOwnership.MODES.find(deck_policy))

func _deck_owned() -> Dictionary:
	return {} if deck_policy == "unrestricted" else profile_store.collection(deck_policy)

func _reload_decks() -> void:
	var result: Dictionary = profile_store.load_decks()
	deck_snapshot = result.snapshot
	active_deck = ""
	deck_notice.text = result.error
	_rebuild_deck_selector()

func _deck_counts() -> Dictionary:
	return deck_snapshot.get("decks", {}).get(active_deck, {}).get("counts", {})

func _rebuild_deck_selector() -> void:
	deck_selector.clear()
	var decks: Dictionary = deck_snapshot.get("decks", {})
	var ids = decks.keys()
	ids.sort_custom(func(a, b): return str(decks[a].name).nocasecmp_to(str(decks[b].name)) < 0)
	if not decks.has(active_deck):
		active_deck = str(ids[0]) if not ids.is_empty() else ""
	for id in ids:
		deck_selector.add_item(decks[id].name)
		var index = deck_selector.item_count - 1
		deck_selector.set_item_metadata(index, id)
		if id == active_deck:
			deck_selector.select(index)
	deck_name.text = str(decks.get(active_deck, {}).get("name", ""))
	_refresh_deck_rows()

func _deck_selected(index: int) -> void:
	active_deck = str(deck_selector.get_item_metadata(index))
	deck_name.text = deck_snapshot.decks[active_deck].name
	deck_notice.text = ""
	_refresh_deck_rows()
	refresh_list()

func _write_deck_snapshot(next: Dictionary, next_id: String) -> bool:
	var problem: String = profile_store.save_decks(deck_snapshot, next)
	if not problem.is_empty():
		deck_notice.text = problem
		return false
	deck_snapshot = next
	active_deck = next_id
	deck_notice.text = "Saved."
	_rebuild_deck_selector()
	refresh_list()
	return true

func _create_deck() -> void:
	if not deck_mode or deck_snapshot.is_empty():
		return
	var name = deck_name.text.strip_edges()
	if name.is_empty():
		deck_notice.text = "Enter a name for the new deck."
		return
	var id = Crypto.new().generate_random_bytes(12).hex_encode()
	var next = deck_snapshot.duplicate(true)
	next.decks[id] = {"name": name, "counts": {}}
	_write_deck_snapshot(next, id)

func _rename_deck() -> void:
	if not deck_mode or active_deck.is_empty():
		return
	var next = deck_snapshot.duplicate(true)
	next.decks[active_deck].name = deck_name.text.strip_edges()
	_write_deck_snapshot(next, active_deck)

func _add_deck_card() -> void:
	if not deck_mode or active_deck.is_empty() or not game.card_database.has(selected_id):
		return
	_change_deck_count("tabletop:" + selected_id, 1)

func _remove_deck_card() -> void:
	if not deck_mode or active_deck.is_empty():
		return
	var selected = deck_rows.get_selected_items()
	if not selected.is_empty():
		_change_deck_count(str(deck_rows.get_item_metadata(selected[0])), -1)

func _change_deck_count(key: String, delta: int) -> void:
	if not deck_mode or active_deck.is_empty():
		return
	var counts = _deck_counts()
	var quantity: int = int(counts.get(key, 0)) + delta
	if quantity < 0 or quantity > ProfileStore.MAX_COUNT:
		deck_notice.text = "Quantity out of range."
		return
	if delta > 0:
		if not key.begins_with("tabletop:") or not game.card_database.has(key.trim_prefix("tabletop:")):
			deck_notice.text = "Only typed tabletop cards can be added."
			return
		if deck_policy != "unrestricted":
			var problem: String = profile_store.check_deck_inventory(deck_policy)
			if not problem.is_empty():
				deck_notice.text = problem
				return
		if not DeckOwnership.permits_addition(deck_policy, key, quantity, _deck_owned()):
			deck_notice.text = "No additional owned copies available for " + key
			return
	var next = deck_snapshot.duplicate(true)
	if quantity == 0:
		next.decks[active_deck].counts.erase(key)
	else:
		next.decks[active_deck].counts[key] = quantity
	_write_deck_snapshot(next, active_deck)

func _refresh_deck_rows() -> void:
	var selected = deck_rows.get_selected_items()
	var previous = str(deck_rows.get_item_metadata(selected[0])) if not selected.is_empty() else ""
	deck_rows.clear()
	var counts = _deck_counts()
	var owned = _deck_owned()
	var shortages = {} if deck_policy == "unrestricted" else DeckOwnership.shortages(counts, owned)
	var keys = counts.keys()
	keys.sort()
	for key in keys:
		var id = str(key).trim_prefix("tabletop:")
		var title = str(key)
		if str(key).begins_with("tabletop:") and game.card_database.has(id):
			title = id + " " + str(game.card_database[id].name)
		var row_text = "%d × %s" % [counts[key], title]
		if shortages.has(key):
			row_text += " [short %d]" % shortages[key]
		var index = deck_rows.add_item(row_text)
		if shortages.has(key):
			deck_rows.set_item_custom_fg_color(index, Color(1.0, 0.65, 0.48))
		deck_rows.set_item_metadata(index, key)
		if key == previous:
			deck_rows.select(index)
	var composition = DeckComposition.summarize(counts, game)
	var rank_text = str(composition.known_rank)
	if composition.unknown_rank > 0:
		rank_text += " + ? (%d unresolved copies)" % composition.unknown_rank
	var types: PackedStringArray = []
	for kind in composition.types:
		types.append("%s %d" % [kind, composition.types[kind]])
	var clubs: PackedStringArray = []
	for club in composition.clubs:
		clubs.append("%s %d" % [club, composition.clubs[club]])
	deck_summary.text = "%d cards • Rank %s\n%s\n%s" % [composition.copies, rank_text, " / ".join(types), " / ".join(clubs)]
	if composition.unknown_definition > 0:
		deck_summary.text += "\n%d unknown definition copies" % composition.unknown_definition
	if deck_policy != "unrestricted":
		var missing = 0
		for quantity in shortages.values():
			missing += int(quantity)
		deck_summary.text += "\nOwnership: %d copies short (%d entries)" % [missing, shortages.size()] if missing > 0 else "\nOwnership: covered"
	deck_rules_report = ChampionshipDeck.validate(counts, game.catalogue.records)
	if not active_deck.is_empty():
		var rule_status = "meets checked rules" if deck_rules_report.status == "passes" else ("needs review" if deck_rules_report.status == "review" else "not ready")
		deck_summary.text += "\nChampionship: " + rule_status
	deck_summary.tooltip_text = deck_summary.text
	_update_deck_buttons()

func _show_deck_rules() -> void:
	if active_deck.is_empty():
		return
	deck_rules_dialog.get_node("Report").text = ChampionshipDeck.describe(deck_rules_report)
	deck_rules_dialog.popup_centered(Vector2i(560, 380))

func _update_deck_buttons() -> void:
	deck_rules_button.disabled = active_deck.is_empty()
	deck_create.disabled = deck_snapshot.is_empty()
	deck_rename.disabled = active_deck.is_empty()
	var key = "tabletop:" + selected_id
	var next_quantity = int(_deck_counts().get(key, 0)) + 1
	deck_add.disabled = active_deck.is_empty() or not game.card_database.has(selected_id) or next_quantity > ProfileStore.MAX_COUNT or not DeckOwnership.permits_addition(deck_policy, key, next_quantity, _deck_owned())
	deck_add.tooltip_text = "Ownership limit reached" if deck_policy != "unrestricted" and not DeckOwnership.permits_addition(deck_policy, key, next_quantity, _deck_owned()) else ""
	deck_remove.disabled = active_deck.is_empty() or deck_rows.get_selected_items().is_empty()

func _inspect_deck_row(index: int) -> void:
	var key = str(deck_rows.get_item_metadata(index))
	var id = key.trim_prefix("tabletop:")
	if key.begins_with("tabletop:") and game.card_database.has(id):
		search.text = id
		type_filter.select(0)
		refresh_list()

func run_deck_test() -> int:
	var failures: Array[String] = []
	var store = ProfileStore.new()
	store.root = "user://deck-test-" + Crypto.new().generate_random_bytes(12).hex_encode() + "/"
	attach_profiles(store)
	if store.active_id.is_empty():
		push_error("Deck fixture initialization failed")
		return 1
	_set_deck_mode()
	deck_name.text = "First draft"
	_create_deck()
	var first = active_deck
	if first.is_empty():
		push_error("Deck creation failed: " + deck_notice.text)
		return 1
	search.text = "1-001"
	refresh_list()
	_add_deck_card()
	_add_deck_card()
	var key = "tabletop:1-001"
	if _deck_counts().get(key, 0) != 2 or store.count("physical", key) != 0 or store.count("digital", key) != 0:
		failures.append("Deck quantity or inventory isolation")
	var summary = DeckComposition.summarize(_deck_counts(), game)
	if summary.copies != 2 or summary.known_rank != 2 or summary.unknown_rank != 0:
		failures.append("Composition calculation")
	if deck_rules_report.status != "fails" or not deck_summary.text.contains("Championship: not ready") or deck_rules_button.disabled:
		failures.append("Live Championship draft validation")
	var unknown = DeckComposition.summarize({"digital:1-001": 3, "tabletop:1-055": 2}, game)
	if unknown.unknown_rank != 5 or unknown.unknown_definition != 5:
		failures.append("Unknown definition/rank accounting")
	deck_rows.select(0)
	_remove_deck_card()
	if _deck_counts().get(key, 0) != 1:
		failures.append("Remove copy")
	deck_name.text = "Renamed draft"
	_rename_deck()
	deck_name.text = "Second draft"
	_create_deck()
	if active_deck == first or not _deck_counts().is_empty() or deck_snapshot.decks.size() != 2:
		failures.append("Multiple independent decks")
	var reopened = ProfileStore.new()
	reopened.root = store.root
	if not reopened.initialize().is_empty():
		failures.append("Profile reload")
	var saved: Dictionary = reopened.load_decks()
	if saved.snapshot.get("decks", {}).get(first, {}).get("name") != "Renamed draft" or saved.snapshot.get("decks", {}).get(first, {}).get("counts", {}).get(key, 0) != 1:
		failures.append("Deck persistence")
	var stale = deck_snapshot.duplicate(true)
	var next = stale.duplicate(true)
	next.decks[first].counts["digital:1-001"] = 2
	if not reopened.save_decks(stale, next).is_empty() or store.save_decks(stale, stale).is_empty():
		failures.append("Unknown key preservation or stale write rejection")
	profile_name.text = "Other collector"
	_create_profile()
	if store.active_id == "default" or not deck_snapshot.get("decks", {}).is_empty():
		failures.append("Deck profile isolation")
	for index in range(profile_selector.item_count):
		if profile_selector.get_item_metadata(index) == "default":
			_profile_selected(index)
			break
	if deck_snapshot.get("decks", {}).get(first, {}).get("counts", {}).get("digital:1-001", 0) != 2:
		failures.append("Deck profile reload")
	var bad = deck_snapshot.duplicate(true)
	bad.decks[first].counts[key] = -1
	if store.save_decks(deck_snapshot, bad).is_empty():
		failures.append("Invalid counts accepted")
	_set_collection_mode("")
	# Only delete explicitly known files in our disposable fixture.
	for entry in store.list_profiles():
		var directory = store.root.path_join(entry.profile_id)
		for filename in ["profile.json", "physical_collection.json", "digital_collection.json", "decks/index.json"]:
			for suffix in ["", ".bak"]:
				var path = directory.path_join(filename + suffix)
				if FileAccess.file_exists(path):
					DirAccess.remove_absolute(path)
		DirAccess.remove_absolute(directory.path_join("decks"))
		DirAccess.remove_absolute(directory)
	for suffix in ["", ".bak"]:
		var path = store.root.path_join("active_profile.json" + suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(store.root)
	for failure in failures:
		push_error(failure)
	print("LOL_DECKS profiles=2 failures=%d" % failures.size())
	return 0 if failures.is_empty() else 1

func run_deck_ownership_test() -> int:
	var failures: Array[String] = []
	var store = ProfileStore.new()
	store.root = "user://deck-ownership-test-" + Crypto.new().generate_random_bytes(12).hex_encode() + "/"
	attach_profiles(store)
	if store.active_id.is_empty():
		push_error("Deck ownership fixture initialization failed")
		return 1
	var key = "tabletop:1-001"
	if not store.add("physical", key, 2).is_empty() or not store.add("digital", key, 1).is_empty() or not store.add("digital", "digital:1-400", 9).is_empty():
		failures.append("Fixture inventory")
	_set_deck_mode()
	deck_name.text = "Ownership draft"
	_create_deck()
	var first = active_deck
	if first.is_empty():
		push_error("Deck fixture creation failed")
		return 1
	search.text = "1"
	refresh_list()
	if selected_id != "1-001" or cards.item_count != 1:
		failures.append("Exact card search")
	_add_deck_card()
	_add_deck_card()
	_add_deck_card()
	var original = deck_snapshot.duplicate(true)
	_set_deck_policy("physical")
	if deck_snapshot != original or store.load_decks().snapshot != original or not deck_add.disabled or not deck_summary.text.contains("1 copies short"):
		failures.append("Physical shortage or non-destructive switch")
	_add_deck_card()
	if deck_snapshot != original:
		failures.append("Over-cap addition accepted")
	_set_deck_policy("digital")
	if not deck_summary.text.contains("2 copies short") or deck_snapshot != original:
		failures.append("Digital shortage")
	search.text = "1-400"
	refresh_list()
	if cards.item_count != 0 or not deck_add.disabled:
		failures.append("Other edition or unowned card leaked into catalogue")
	deck_rows.select(0)
	_remove_deck_card()
	_remove_deck_card()
	if _deck_counts().get(key, 0) != 1 or not deck_summary.text.contains("Ownership: covered"):
		failures.append("Removal while over limit")
	_set_deck_policy("physical")
	search.text = "1-001"
	refresh_list()
	if deck_add.disabled:
		failures.append("Physical headroom not offered")
	_add_deck_card()
	_add_deck_card()
	if _deck_counts().get(key, 0) != 2:
		failures.append("Physical cap")
	_set_deck_policy("unrestricted")
	_add_deck_card()
	if _deck_counts().get(key, 0) != 3:
		failures.append("Unrestricted mode")
	if store.count("physical", key) != 2 or store.count("digital", key) != 1:
		failures.append("Deck consumed inventory")
	var before_switch = deck_snapshot.duplicate(true)
	_set_deck_policy("physical")
	profile_name.text = "Second collector"
	_create_profile()
	if store.active_id == "default" or not deck_snapshot.get("decks", {}).is_empty() or cards.item_count != 0:
		failures.append("Profile isolation")
	for index in range(profile_selector.item_count):
		if profile_selector.get_item_metadata(index) == "default":
			_profile_selected(index)
			break
	if deck_snapshot != before_switch or deck_policy != "physical" or not deck_summary.text.contains("1 copies short"):
		failures.append("Profile restoration")
	# External inventory mutations must not authorize a stale addition.
	_set_deck_policy("unrestricted")
	deck_rows.select(0)
	_remove_deck_card()
	_remove_deck_card()
	_set_deck_policy("physical")
	var other = ProfileStore.new()
	other.root = store.root
	if not other.initialize().is_empty() or not other.remove("physical", key, 1).is_empty():
		failures.append("External mutation fixture")
	var before_stale = deck_snapshot.duplicate(true)
	_add_deck_card()
	if deck_snapshot != before_stale or not deck_notice.text.contains("outside this session"):
		failures.append("Stale collection addition")
	_set_collection_mode("")
	for entry in store.list_profiles():
		var directory = store.root.path_join(entry.profile_id)
		for filename in ["profile.json", "physical_collection.json", "digital_collection.json", "decks/index.json"]:
			for suffix in ["", ".bak"]:
				var path = directory.path_join(filename + suffix)
				if FileAccess.file_exists(path):
					DirAccess.remove_absolute(path)
		DirAccess.remove_absolute(directory.path_join("decks"))
		DirAccess.remove_absolute(directory)
	for suffix in ["", ".bak"]:
		var path = store.root.path_join("active_profile.json" + suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(store.root)
	for failure in failures:
		push_error(failure)
	print("LOL_DECK_OWNERSHIP modes=3 failures=%d" % failures.size())
	return 0 if failures.is_empty() else 1
