@icon("res://addons/schmove/ico/exporter.png")
extends Node
class_name SchmoveExporter2D

## Exporter is used as a child of an object you want to
## have 'jailed' or otherwise transported during scene
## switches made via the Schmove API

## When its brought back into existance by re-entering the
## scene it was left in.
signal OnRehydrated

## When its brought from one scene into another.
signal OnTransported

## Same as subscribing the same method to both OnRehydrated and OnTransported.
## Basically if you want the entity to do stuff when its inited into a new scene
## you use this.
signal OnSchmoveReinit

## When its put into temporary holding.
signal OnJailed

## Used to determine what Importers this Exporter can be put into when
## Switching scenes.
@export_flags_3d_navigation var Group = 1

## Important means it cannot be permanently lost without explicitly
## being requested to do so via code. Important exported objects are always
## Sent along in a transition
@export var Important: bool = false

## Smart means that if a node is rehydrated into a scene via a transition
## (eg, you left behind an exporter by moving into a new scene, then move back
## into that scene), it will be placed back into the position it was jailed at
## rather than placed into its relevant slot
@export var Smart: bool = false

## The nickname, if not null or empty, can be used to summon, move, jail,
## or rehydrate any entity via code. 
## 
## For example Schmove.jail("player") to jail the player into
## holding no matter where it is.
@export var Nickname: String = ""

## REQUIRES NICKNAME: If true remembers when it has been spawned, so when transitioning back to a scene,
## will disable the spawn before it _ready()s if it already exists in some capacity, eg in jail or launching.
@export var Unique: bool = false

func _ready():
	if Unique:
		if Nickname == "":
			print("SCHMOVE Warning: Unique Entity "+name+" had no nickname, defaulting to the Node's name")
			Nickname = name
			return
		if Schmove.unique_available(Nickname):
			Schmove.unique_register(Nickname, self)
		else:
			get_parent().set_process(false)
			get_parent().queue_free()

## Jails the node(parent), placing it into a holding array, to be re introduced
## at any time in any other scene, persisting across scene changes.
##
## Optionally takes a keyword to be rehydrated with, without a direct reference
## to this node.
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
