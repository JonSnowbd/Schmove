@icon("res://addons/schmove/ico/world.png")
extends Node2D
class_name SchmoveWorld2D

func _ready():
	if Schmove._t_level == null or Schmove._t_level == "":
		return
	var importer_list = Schmove._get_all_importers_in_tree()
	
	if Schmove._t_shuffle:
		importer_list.shuffle()
		Schmove._t_launched.shuffle()
	
	# Find the launchers a home
	for launched in Schmove._t_launched:
		# ungrouped nodes are just brought over with no modification.
		if launched.Group == 0:
			var real = Schmove.get_real_node(launched)
			add_child(real)
			launched.call_deferred("_emit_transport")
			continue
		var found = false
		for importer in importer_list:
			if importer.is_compatible(launched):
				var target_destination
				if importer.TargetInsertionPath != null:
					target_destination = importer.get_node(importer.TargetInsertionPath)
				else:
					target_destination = importer.get_parent()
				var real = Schmove.get_real_node(launched)
				target_destination.add_child(real)
				real.set_deferred("global_position", importer.global_position)
				importer._consumed = true
				found = true
				launched.call_deferred("_emit_transport")
				break
		if !found:
			Schmove.jail_node(launched, "schmove_limbo")
			print("SCHMOVE: Failed to find a suitable home for <"+launched.Nickname+">, sent to jail.")
	
	# Then use cancel to clear the statemachine.
	var end_stamp = Time.get_ticks_msec()
	print("SCHMOVE: Successful transition, took "+str(end_stamp-Schmove._t_stamp)+"ms.")
	Schmove.cancel_transition()
