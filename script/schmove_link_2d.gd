@icon("res://addons/schmove/ico/link.png")
extends Node2D
class_name SchmoveLink2D

## Links are not necessary, but can be used to easily let schmove handle things
## such as screen transition shaders, export targets, and preloading the levels.

@export_file("*.tscn") var Destination
@export var Keyword: String = ""
@export var AutomaticLaunches: Array[String] = []
@export var ShuffleOnTransition: bool = false

## If <= 0.0  then no wipe will be used
@export var WipeDuration: float = 0.0
## Optional, if one is not provided a circle tube wipe will be used
@export var WipeType: ShaderMaterial = Schmove.WipeCircle

func _ready():
	if Destination != null:
		Schmove.preload_level(Destination)

## Activates the transition.
func travel():
	if Destination == null:
		print("SCHMOVE: Level link "+name+" has a null destination and tried to travel.")
		return
	Schmove.begin_transition(Destination)
	if ShuffleOnTransition:
		Schmove.transition_shuffle()
	for n in AutomaticLaunches:
		Schmove.transition_launch_by_name(n)
	if WipeDuration > 0.0:
		if WipeType == null:
			Schmove.transition_wipe(Schmove.WipeCircle, WipeDuration)
		else:
			Schmove.transition_wipe(WipeType, WipeDuration)
	if Keyword != "":
		Schmove.transition_keyword(Keyword)
	Schmove.finish_transition()
