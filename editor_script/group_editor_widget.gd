@tool
extends VBoxContainer

var context = null

func _handle_tick(value, bit):
	if value: # If ticked add the flag
		if context is SchmoveExporter2D:
			context.Group |= bit
		if context is SchmoveImporter2D:
			context.AllowsGroups |= bit
	else: # Else remove the flag
		if context is SchmoveExporter2D:
			context.Group &= ~bit
		if context is SchmoveImporter2D:
			context.AllowsGroups &= ~bit

func hook(object, label):
	context = object
	$Label.text = label
	if context is SchmoveExporter2D:
		$Label.tooltip_text = "The group that this entity belongs to, used to determine what importers this can go into."
	else:
		$Label.tooltip_text = "The groups that will be allowed to be placed into this slot"
	for i in range(12):
		var slot_name = ProjectSettings.get_setting("layer_names/schmove/slot"+str(i+1), "Unknown")
		var slot_col = ProjectSettings.get_setting("layer_names/schmove/slot"+str(i+1)+"_color", Color(0.1,0.1,0.1,1.0))
		var checkContainer: PanelContainer = $Flow.get_node("GroupCheck"+str(i+1))
		var check: CheckBox = checkContainer.get_node("CheckBox") as CheckBox
		checkContainer.self_modulate = slot_col
		check.tooltip_text = slot_name
		if object is SchmoveExporter2D:
			check.button_pressed = object.Group & (1 << (i+1))
		if object is SchmoveImporter2D:
			check.button_pressed = object.AllowsGroups & (1 << (i+1))
		check.toggled.connect(_handle_tick.bind(1 << (i+1)))
