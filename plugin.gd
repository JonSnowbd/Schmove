@tool
extends EditorPlugin
class_name SchmoveEditorPlugin

const prop_editor = preload("res://addons/schmove/property_editor.gd")
var prop_editor_inst

func _schmove_initial_setting(path: String, initial_value, order: int):
	if !ProjectSettings.has_setting(path):
		ProjectSettings.set_setting(path, initial_value)
	ProjectSettings.set_initial_value(path, initial_value)
	ProjectSettings.set_order(path, order)

func _schmove_layer_setting(i: int):
	if !ProjectSettings.has_setting("layer_names/schmove/slot"+str(i)):
		ProjectSettings.set_setting("layer_names/schmove/slot"+str(i), "Slot "+str(i))
	ProjectSettings.set_initial_value("layer_names/schmove/slot"+str(i), "Slot "+str(i))
	ProjectSettings.set_order("layer_names/schmove/slot"+str(i), i*2)
	
	# And its color
	var default_color = Color(0.1, 0.1, 0.1, 1.0)
	if !ProjectSettings.has_setting("layer_names/schmove/slot"+str(i)+"_color"):
		ProjectSettings.set_setting("layer_names/schmove/slot"+str(i)+"_color", default_color)
	ProjectSettings.set_initial_value("layer_names/schmove/slot"+str(i)+"_color", default_color)
	ProjectSettings.set_order("layer_names/schmove/slot"+str(i)+"_color", (i*2)+1)

func _enter_tree():
	for i in range(12):
		_schmove_layer_setting(i+1)
	_schmove_initial_setting("application/schmove/time_mush", 0.1, 2)
	_schmove_initial_setting("application/schmove/time_mush_on_wipe_transition", true, 3)
	ProjectSettings.save()
	add_autoload_singleton("Schmove", "res://addons/schmove/global/schmove.tscn")
	print("Thank you for using Schmove, if you're stuck hit up https://github.com/JonSnowbd/Schmove")
	prop_editor_inst = prop_editor.new()
	add_inspector_plugin(prop_editor_inst)

func _exit_tree():
	remove_autoload_singleton("Schmove")
	remove_inspector_plugin(prop_editor_inst)
