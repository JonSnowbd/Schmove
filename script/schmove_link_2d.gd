@icon("res://addons/schmove/ico/link.png")
extends Node2D
class_name SchmoveLink2D

## Links are not necessary, but can be used to easily let schmove handle things
## such as screen transition shaders, export targets, and preloading the levels.

@export_file("*.tscn") var Destination
@export var Keyword: String = ""

func _ready():
	if Destination != null:
		Schmove.preload_level(Destination)

## Activates the transition.
func travel():
	Schmove.begin_transition(Destination)
	Schmove.transition_wipe(null, 0.8)
	Schmove.finish_transition()
