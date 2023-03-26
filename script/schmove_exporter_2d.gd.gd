@icon("res://addons/schmove/ico/exporter.png")
extends Node
class_name SchmoveExporter2D

enum ImportanceType {
	None,
	Launch,
	Jail
}

## Exporter is used as a child of an object you want to
## have 'jailed' or otherwise transported during scene
## switches made via the Schmove API

## When its brought from one scene into another.
signal OnTransported

## When its put into temporary holding.
signal OnJailed

## Used to determine what Importers this Exporter can be put into when
## Switching scenes.
@export var Group = 1

## Important means it has an implicit behaviour when not launched during a transition.
## Important.Jail will jail on unlaunched transition, and Important.Launch will 
## always transfer an entity between the scenes
@export var Important: ImportanceType = ImportanceType.None

## The nickname, if not null or empty, can be used to launch or jail,
## any entity via code. 
## 
## For example Schmove.jail_by_name("player") to jail the player into
## holding no matter where it is.
@export var Nickname: String = ""

## Used to rehydrate a save file. If this entity has a unique nickname, and this is set,
## then when a savefile is recreated this prefab will be instantiated and fed
## the corresponding save data.
@export_file("*.tscn") var TargetPrefab

## if this object is to be encoded, and has additional encodable children that
## need to be managed too, list them in this array.
@export var AdditionalDataObjects: Array[NodePath] = []

## If true, this object will be ignored on encode/decode for saving and loading.
@export var IgnoreOnSave: bool = false

func _init():
	add_to_group(Schmove.ExporterGroup, true)

func _notification(what):
	if what == NOTIFICATION_PARENTED:
		get_parent().set_meta("schmove_exporter", self)

## Jails the node(parent), placing it into a holding array, to be re introduced
## at any time in any other scene, persisting across scene changes.
##
## Optionally takes a keyword to be interacted with, without a direct reference
## to the group of nodes. For example, jailing a bunch of units under "dead_units"
## lets you have a pool of exported nodes to resurrect/check for respawn
func jail(keyword = ""):
	Schmove.jail_node(self, keyword)

## Launches the entity into a different temp holding that will be explicitly
## used for the next(preferably very immediate) transition. Use this for things
## like only some entities being used in the next transition.
## 
## for example if you're sending units on a mission, launch all the units in the send-off zone,
## then scene transition via Schmove, and you wont accidentally send your whole army.
func launch():
	Schmove.transition_launch(self)

func _emit_transport():
	OnTransported.emit()
func _emit_jailed():
	OnJailed.emit()

func pull_state():
	if IgnoreOnSave:
		return
	if Nickname == "":
		push_error("Attempted to decode a non-unique nickname")
		return
	if !Schmove.state["data"].has(Nickname):
		push_warning("Failed to find decode data during pull_state for %s" % Nickname)
		return
	var dat: Dictionary = Schmove.state["data"][Nickname]
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
func push_state():
	if IgnoreOnSave:
		return
	if Nickname == "":
		push_error("Attempted to encode a non-unique nickname")
		return
	var parent = get_parent()
	var parent_data = {}
	if parent.has_method("schmove_encode"):
		parent_data = parent.schmove_encode()
	parent_data["__prefab"] = str(TargetPrefab)
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
		Schmove.state["data"][Nickname] = final_data
	else:
		Schmove.state["data"][Nickname] = parent_data
