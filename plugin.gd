@tool
extends EditorPlugin
class_name SchmoveEditorPlugin


func _schmove_initial_setting(path: String, initial_value, order: int):
	if !ProjectSettings.has_setting(path):
		ProjectSettings.set_setting(path, initial_value)
	ProjectSettings.set_initial_value(path, initial_value)
	ProjectSettings.set_order(path, order)

func _schmove_layer_setting(i: int):
	if !ProjectSettings.has_setting("layer_names/schmove/slot"+str(i)):
		ProjectSettings.set_setting("layer_names/schmove/slot"+str(i), "Slot "+str(i))
	else:
		var val = str(ProjectSettings.get_setting("layer_names/schmove/slot"+str(i)))
		ProjectSettings.set_setting("layer_names/3d_navigation/layer_"+str(i), val)
	ProjectSettings.set_initial_value("layer_names/schmove/slot"+str(i), "Slot "+str(i))
	ProjectSettings.set_order("layer_names/schmove/slot"+str(i), i)

func _enter_tree():
	# Todo: Find out how to custom name flags.
	for i in range(32):
		_schmove_layer_setting(i+1)
	_schmove_initial_setting("application/schmove/search_depth", 3, 1)
	_schmove_initial_setting("application/schmove/time_mush", 0.1, 2)
	_schmove_initial_setting("application/schmove/time_mush_on_wipe_transition", true, 3)
	ProjectSettings.save()
	# ProjectSettings.connect("property_list_changed", self._schmove_on_changed_settings)
	add_autoload_singleton("Schmove", "res://addons/schmove/global/schmove.tscn")
	print("Thank you for using Schmove, if you're stuck hit up https://github.com/JonSnowbd/Schmove")

func _exit_tree():
	remove_autoload_singleton("Schmove")
