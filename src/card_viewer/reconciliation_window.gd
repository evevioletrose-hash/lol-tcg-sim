extends Window

var plan
var game
var selected: Dictionary = {}
var id_list: ItemList
var field_panel: VBoxContainer
var summary: Label
var apply_button: Button
var missing_button: Button
var clear_button: Button
var active_id: String = ""
var applied = false
signal records_saved

func setup(source, comparison) -> void:
	game = source
	plan = comparison
	title = "Reconcile spreadsheet / no changes selected"
	size = Vector2i(900, 610)
	transient = true
	exclusive = true
	close_requested.connect(queue_free)
	var root = MarginContainer.new()
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		root.add_theme_constant_override("margin_" + side, 12)
	var body = VBoxContainer.new()
	root.add_child(body)
	summary = Label.new()
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(summary)
	var split = HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(split)
	id_list = ItemList.new()
	id_list.custom_minimum_size.x = 220
	split.add_child(id_list)
	id_list.item_selected.connect(show_fields)
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(scroll)
	field_panel = VBoxContainer.new()
	field_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(field_panel)
	var controls = HBoxContainer.new()
	body.add_child(controls)
	missing_button = Button.new()
	missing_button.text = "Select blank-field fills"
	missing_button.pressed.connect(select_missing)
	controls.add_child(missing_button)
	clear_button = Button.new()
	clear_button.text = "Clear selection"
	clear_button.pressed.connect(clear_selection)
	controls.add_child(clear_button)
	apply_button = Button.new()
	apply_button.text = "Apply selected changes"
	apply_button.pressed.connect(confirm_apply)
	controls.add_child(apply_button)
	var cancel = Button.new()
	cancel.text = "Close / cancel"
	cancel.pressed.connect(queue_free)
	controls.add_child(cancel)
	var ids = plan.changes.keys()
	ids.sort()
	for id in ids:
		var index = id_list.add_item(id + " / " + str(plan.baseline[id].get("name", "")))
		id_list.set_item_metadata(index, id)
	if id_list.item_count > 0:
		id_list.select(0)
		show_fields(0)
	update_summary()
	popup_centered()

func update_summary() -> void:
	var fields = 0
	for id in selected:
		for field in selected[id]:
			if selected[id][field]:
				fields += 1
	summary.text = "%d incoming rows / %d changed cards / %d unchanged / %d fields selected" % [plan.rows.size(), plan.changes.size(), plan.unchanged, fields]
	if not plan.notes.is_empty():
		summary.text += "\n" + "; ".join(plan.notes)
	if not plan.errors.is_empty():
		summary.text += "\nImport blocked: " + "\n".join(plan.errors.slice(0, 8))
	summary.text += "\nUnchecked fields are preserved. Incoming blanks only erase a value if explicitly checked."
	apply_button.disabled = fields == 0 or not plan.errors.is_empty() or applied
	missing_button.disabled = not plan.errors.is_empty() or applied
	clear_button.disabled = applied

func show_fields(index: int) -> void:
	for child in field_panel.get_children():
		field_panel.remove_child(child)
		child.queue_free()
	active_id = str(id_list.get_item_metadata(index))
	for field in plan.changes[active_id]:
		var diff: Dictionary = plan.changes[active_id][field]
		var check = CheckBox.new()
		check.text = "Accept " + field.capitalize()
		check.button_pressed = selected.get(active_id, {}).get(field, false)
		check.disabled = applied
		check.toggled.connect(toggle_field.bind(active_id, field))
		field_panel.add_child(check)
		for pair in [["Local", diff.local], ["Incoming", diff.incoming]]:
			var label = Label.new()
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.text = pair[0] + ": " + ("(blank)" if plan.cell(pair[1]).is_empty() else plan.cell(pair[1]))
			field_panel.add_child(label)
		field_panel.add_child(HSeparator.new())

func toggle_field(checked: bool, id: String, field: String) -> void:
	if not selected.has(id):
		selected[id] = {}
	selected[id][field] = checked
	update_summary()

func select_missing() -> void:
	selected = plan.missing_choices()
	refresh_fields()

func clear_selection() -> void:
	selected.clear()
	refresh_fields()

func refresh_fields() -> void:
	var indices = id_list.get_selected_items()
	if not indices.is_empty():
		show_fields(indices[0])
	update_summary()

func confirm_apply() -> void:
	var dialog = ConfirmationDialog.new()
	dialog.title = "Apply selected fields?"
	dialog.dialog_text = "Only checked fields will be saved. Files are replaced individually; if a disk error occurs, earlier successful saves remain."
	add_child(dialog)
	dialog.confirmed.connect(apply_changes)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered()

func apply_changes() -> void:
	var result: Dictionary = plan.apply_selected(game.catalogue, selected)
	for id in result.saved:
		game.refresh_card_definition(id)
	records_saved.emit()
	applied = true
	refresh_fields()
	summary.text = "Saved %d card records." % result.saved.size()
	if not result.error.is_empty():
		summary.text += "\nStopped: " + result.error + "\nReimport to review remaining changes."
	else:
		summary.text += "\nClose this window to continue editing."
