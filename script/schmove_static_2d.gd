@tool
@icon("res://addons/schmove/ico/static.png")
extends Node
class_name SchmoveStatic2D

signal Decoded
signal Encoded

## Referring to a static object where the state will not need to traverse
## between scenes, but rather needs to persist or otherwise modify behaviour
## early in a scene load to give the illusion of a persistent world with very
## easy and simple tweaks. For example, a chest that was opened, remaining opened
## the next time the scene is loaded


## A simple id to refer to this static object. Make sure this is unique to where
## you want it to replicate the state! Said simply; if you want the same chest 
## in multiple levels, you can use the same nickname here, otherwise try to
## keep it unique.
@export var Nickname: String = ""

## Automatically decode Schmove state on enter tree, and encode data to 
## Schmove storage on exit tree
@export var AutoEncode: bool = true

## if this object is to be encoded, and has additional encodable children that
## need to be managed too, list them in this array.
@export var AdditionalDataObjects: Array[NodePath] = []

func _init():
	add_to_group(Schmove.StaticGroup)

func _ready():
	if AutoEncode and Schmove.state["static_data"].has(Nickname):
		pull_state()

func pull_state():
	if Nickname == "":
		push_error("Attempted to decode a non-unique nickname")
		return
	if !Schmove.state["static_data"].has(Nickname):
		push_warning("Failed to find decode data during pull_state for %s" % Nickname)
		return
	var dat: Dictionary = Schmove.state["static_data"][Nickname]
	var parent = get_parent()
	if dat.has("!root!"):
		var root = dat["!root!"]
		if parent.has_method("schmove_decode"):
			parent.schmove_decode(root)
		if len(AdditionalDataObjects) > 0:
			for x in AdditionalDataObjects:
				var target = get_node_or_null(x)
				if target == null:
					push_warning("Attempted to get null node while encoding state: %s" % str(x))
					continue
				if target.has_method("schmove_decode") and dat.has(target.name):
					target.schmove_decode(dat[target.name])
	else:
		if parent.has_method("schmove_decode"):
			parent.schmove_decode(dat)
	Decoded.emit()
func push_state():
	if Nickname == "":
		push_error("Attempted to encode a non-unique nickname")
		return
	var parent = get_parent()
	var parent_data = {}
	if parent.has_method("schmove_encode"):
		parent_data = parent.schmove_encode()
	if len(AdditionalDataObjects) > 0:
		var final_data = {}
		for x in AdditionalDataObjects:
			var data = {}
			var node = get_node_or_null(x)
			if node == null:
				push_warning("Attempted to get null node while encoding state: %s" % str(x))
				continue
			if node.has_method("schmove_encode"):
				data = node.schmove_encode()
			final_data[node.name] = data
		final_data["!root!"] = parent_data
		Schmove.state["static_data"][Nickname] = final_data
	else:
		Schmove.state["static_data"][Nickname] = parent_data
	Encoded.emit()
