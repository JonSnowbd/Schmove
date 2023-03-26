extends EditorInspectorPlugin

const widget = preload("res://addons/schmove/prefab/edit_group_widget.tscn")
const widget_type = preload("res://addons/schmove/editor_script/group_editor_widget.gd")

func _can_handle(object):
	return (object is SchmoveExporter2D) or (object is SchmoveImporter2D)

func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
	if name == "Group" or name == "AllowsGroups":
		var w = widget.instantiate() as widget_type
		w.hook(object, name)
		add_custom_control(w)
		return true
