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
@export_flags_3d_navigation var Group = 1

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

## If true, then the Exporter's _ready() call will place this entity into the scene following expected logic
@export var InsertOnSpawn: bool = false

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
## for example if
## you're sending units on a mission, launch all the units in the send-off zone,
## then scene transition via Schmove, and you wont accidentally send your whole army.
func launch():
	Schmove.transition_launch(self)

func _emit_transport():
	OnTransported.emit()
func _emit_jailed():
	OnJailed.emit()
