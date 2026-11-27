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
	var ids = game.catalogue.records.keys() if archivist else game.card_database.keys()
	ids.sort()
	var query = search.text.strip_edges().to_lower()
	var filter_id = type_filter.get_selected_id()
	var selection_index = -1
	for id in ids:
		var raw: Dictionary = game.catalogue.records[id]
		var typed = game.card_database.has(id)
		var kind = game.get_card_type(str(raw.get("type", "")))
		if filter_id == INCOMPLETE_FILTER:
			if typed:
				continue
		elif filter_id > 0 and (not typed or kind != filter_id - 1):
			continue
		var searchable = "%s %s %s %s %s" % [id, raw.name, raw.club, raw.text, raw.phase]
		if not query.is_empty() and not searchable.to_lower().contains(query):
			continue
		var display_name = "" if raw.name == null else str(raw.name)
		if display_name.is_empty():
			display_name = "(unnamed)"
		if not typed:
			display_name += " [incomplete]"
		var index = cards.add_item("%s  %s" % [id, display_name])
		cards.set_item_metadata(index, id)
		if id == previous_id:
			selection_index = index
	count_label.text = "%d / %d cards" % [cards.item_count, ids.size()]
	if cards.item_count == 0:
		clear_preview()
		details.text = "No matching cards."
		if archivist:
			draft.clear()
			editor_panel.hide()
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
	$Margin/Layout/Title.text = "Dance Off / Card Archivist"
	$Margin/Layout/Body.split_offset = 270
	details.hide()
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
	filling = false
	update_draft()

func _choice_changed(index: int, field: String) -> void:
	_set_draft_field(str(inputs[field].get_item_metadata(index)), field)

func _effect_changed() -> void:
	_set_draft_field(inputs["text"].text, "text")

func _set_draft_field(value: String, field: String) -> void:
	if filling or draft.is_empty():
		return
	draft[field] = value
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
	_set_draft_field("Items", "type")
	_set_draft_field("2", "rank")
	if not is_dirty() or preview == null or game.card_database.has(id):
		failures.append("Draft preview or isolation failed")
	_set_draft_field("bad", "rank")
	if not save_button.disabled:
		failures.append("Invalid rank accepted")
	revert_draft()
	if is_dirty() or draft != original:
		failures.append("Revert failed")
	_set_draft_field("Items", "type")
	_set_draft_field("2", "rank")
	save_draft()
	if is_dirty() or not game.card_database.has(id) or game.catalogue.read_json(path) != game.catalogue.records[id]:
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
