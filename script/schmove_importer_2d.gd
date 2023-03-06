@icon("res://addons/schmove/ico/importer.png")
extends Node2D
class_name SchmoveImporter2D

## The node that gets inserted via this importer will be added as a child to the
## node at this path, if set.
@export_node_path("Node2D") var TargetInsertionPath

## TRANSITION ONLY: If not empty/null, this import will only be used when
## this scene was transitioned into via this keyword. For an example use case,
## imagine needing 4 clusters of importers used for a large room that can be entered
## via 4 doorways. East used when the scene is transitioned into with the keyword "east"
@export var TransitionKeyword: String = ""

## Used to filter out what exporters can be brought into this slot.
## If 0, nothing can be brought in
@export_flags_3d_navigation var AllowsGroups = 1

var _consumed: bool = false

func is_compatible(target: Node, keyword: String = "") -> bool:
	if _consumed:
		return false
	var exporter: SchmoveExporter2D = Schmove.get_exporter_node(target)
	if exporter == null:
		return false
	if TransitionKeyword != "" or keyword != "":
		if TransitionKeyword != keyword:
			return false
	if AllowsGroups == 0 or exporter.Group == 0:
		return false
	return  (exporter.Group & AllowsGroups) > 0
