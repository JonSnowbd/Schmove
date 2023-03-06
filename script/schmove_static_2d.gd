@icon("res://addons/schmove/ico/static.png")
extends Node
class_name SchmoveStatic2D

## Referring to a static object where the state will not need to traverse
## between scenes, but rather needs to persist or otherwise modify behaviour
## early in a scene load to give the illusion of a persistent world with very
## easy and simple tweaks. For example, a chest that was opened, remaining opened
## the next time the scene is loaded

signal ReceivedStaticState(message: String, payload)

func _enter_tree():
	get_parent().set_process_internal(false)
	get_parent().set_process(false)
	get_parent().set_block_signals(false)
	get_parent().set_scene_instance_load_placeholder(true)
	get_parent().queue_free()
