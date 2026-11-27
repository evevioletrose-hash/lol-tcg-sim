extends Control

# This workshop inspects definitions. It does not create a match or run powers.
var game: Game
var preview: Card
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
	if not collection_kind.is_empty() and query.is_valid_int() and query.length() <= 3 and int(query) > 0:
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
		return
	if selection_index < 0:
		selection_index = 0
	cards.select(selection_index)
	_on_card_selected(selection_index)

func clear_preview() -> void:
	if is_instance_valid(preview):
		preview.free()
	preview = null
	selected_id = ""

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
	if data.type == Game.Card_Types.Place:
		lines.append("")
		lines.append("Place preview not implemented yet.")
	else:
		preview = game.spawn_card(id, preview_holder)
		if is_instance_valid(preview):
			preview.set_anchors_preset(Control.PRESET_TOP_LEFT)
			preview.position = Vector2.ZERO
			preview.size = Vector2(333, 442)
			preview.get_node("Button").mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.text = "\n".join(lines)
	if not collection_kind.is_empty():
		_update_collection_selection()

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
		if data.type == Game.Card_Types.Place:
			if preview != null:
				failures.append(id + ": unexpected Place scene")
		elif preview == null:
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
	elif projected.type == Game.Card_Types.Place:
		status.text += "\nPlace preview not implemented yet."
	else:
		preview = game.spawn_card_definition(projected, preview_holder)
		if is_instance_valid(preview):
			preview.set_anchors_preset(Control.PRESET_TOP_LEFT)
			preview.position = Vector2.ZERO
			preview.size = Vector2(333, 442)
			preview.get_node("Button").mouse_filter = Control.MOUSE_FILTER_IGNORE
			preview.rank_ui.text = "?" if draft.rank == null or draft.rank == "" else str(draft.rank)

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
	if not collection_kind.is_empty():
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
	for label in ["Card Workshop", "Physical collection", "In-game collection"]:
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
	_set_collection_mode(["", "physical", "digital"][index])

# Keep the physical regression exercising the same shared browser.
func _set_physical_mode(enabled: bool) -> void:
	_set_collection_mode("physical" if enabled else "")

func _set_collection_mode(kind: String) -> void:
	if not kind in ["", "physical", "digital"]:
		return
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
