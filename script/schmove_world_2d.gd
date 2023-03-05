@icon("res://addons/schmove/ico/world.png")
extends Node2D
class_name SchmoveWorld2D

@export_category("Optional Details")

@export
var LevelName = "Level Name"

var is_saturated: bool = false
var export_nodes: Array[SchmoveExporter2D] = []

func register_exporter(exporter: SchmoveExporter2D):
	export_nodes.append(exporter)
