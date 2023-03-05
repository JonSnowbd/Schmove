@tool
extends EditorPlugin
class_name SchmoveEditorPlugin

func _schmove_layer_setting(i: int):
	if !ProjectSettings.has_setting("layer_names/schmove/slot"+str(i)):
		ProjectSettings.set_setting("layer_names/schmove/slot"+str(i), "Slot "+str(i))
		ProjectSettings.set_initial_value("layer_names/schmove/slot"+str(i), "Slot "+str(i))
		ProjectSettings.set_order("layer_names/schmove/slot"+str(i), i)
	else:
		var val = str(ProjectSettings.get_setting("layer_names/schmove/slot"+str(i)))
		ProjectSettings.set_setting("layer_names/3d_navigation/layer_"+str(i), val)

func _schmove_layer_reprobe(i: int):
	if !ProjectSettings.has_setting("layer_names/schmove/slot"+str(i)):
		return
	var cur = str(ProjectSettings.get_setting("layer_names/3d_navigation/layer_"+str(i)))
	var sch = str(ProjectSettings.get_setting("layer_names/schmove/slot"+str(i)))
	if cur != sch:
		ProjectSettings.set_setting("layer_names/3d_navigation/layer_"+str(i), sch)

func _schmove_on_changed_settings():
	for i in range(32):
		_schmove_layer_reprobe(i+1)


var connection
func _enter_tree():
	# Todo: Find out how to custom name flags.
	for i in range(32):
		_schmove_layer_setting(i+1)
	ProjectSettings.save()
	# ProjectSettings.connect("property_list_changed", self._schmove_on_changed_settings)
	add_autoload_singleton("Schmove", "res://addons/schmove/global/schmove.tscn")
	print("Thank you for using Schmove, if you're stuck on our features, hit up https://test.com")

func _exit_tree():
	remove_autoload_singleton("Schmove")
