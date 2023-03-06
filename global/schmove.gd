extends Node

## Ran on a deferred call after a scene switch via Schmove api
signal DeferredSceneTransition
signal StateUpdated
signal Logged(message: String, log_type: int)

const WipeCircle = preload("res://addons/schmove/material/circle_wipe.tres")
const WipeStickGlitch = preload("res://addons/schmove/material/stick_wipe.tres")

var _preloaded: Dictionary = {}
var _launched: Array[SchmoveExporter2D] = []
var _jail: Dictionary = {}

## If the target is a SchmoveExporter2D then the parent will be returned
## but if it isnt, then the node itself is returned. Used for convenience
func get_real_node(target: Node) -> Node:
	if target is SchmoveExporter2D:
		return target.get_parent()
	return target
## Convenience method that finds the exporter of a node, if one is to be found.
## if Target is an exporter itself, then it will be returned.
func get_exporter_node(target: Node) -> SchmoveExporter2D:
	if target is SchmoveExporter2D:
		return target
	for c in target.get_children():
		if c is SchmoveExporter2D:
			return c
	return null

## Allows you to preload a level into ram for very fast transitions.
## Do know that the preload is not local to a scene, but is in memory
## between loads, and preloading a level twice will not result in any negative
## effects, so preload as much as you want.
func preload_level(path: String):
	if _preloaded.has(path):
		return
	_preloaded[path] = true
	ResourceLoader.load_threaded_request(path)
	StateUpdated.emit()
	Logged.emit("Preload: "+path, 0)

## If you're making more levels than you have ram, you can flush
## this out at your judgement.
func preload_flush():
	_preloaded.clear()

var _t_level: String = ""
var _t_launched: Array[SchmoveExporter2D] = []
var _t_keyword: String = ""
var _t_using_wipe: bool = false
var _t_shuffle: bool = false

func _emit_transition():
	DeferredSceneTransition.emit()


func _get_all_exporters(node: Node, depth: int = 0) -> Array[SchmoveExporter2D]:
	var max_depth = ProjectSettings.get_setting("application/schmove/search_depth", 2)
	if depth > max_depth:
		return []
	var exports: Array[SchmoveExporter2D] = []
	if node is SchmoveExporter2D:
		exports.append(node)
	else:
		for c in node.get_children():
			exports.append_array(_get_all_exporters(c, depth+1))
	return exports

func _get_all_importers(node: Node, depth: int = 0) -> Array[SchmoveImporter2D]:
	var max_depth = ProjectSettings.get_setting("application/schmove/search_depth", 2)
	if depth > max_depth:
		return []
	var exports: Array[SchmoveImporter2D] = []
	if node is SchmoveImporter2D:
		exports.append(node)
	else:
		for c in node.get_children():
			exports.append_array(_get_all_importers(c, depth+1))
	return exports

## Schmove transitions are like a state machine, or imgui if you've used it.
## Begin a transition, use transition_* methods to customize, then finish
## with finish_transition or cancel with cancel_transition
func begin_transition(new_level_path: String):
	_t_level = new_level_path
	StateUpdated.emit()

## Importers can be locked behind a keyword. A target import slot is used only if
## their keywords match the transition keyword, IF either are set to anything but ""
func transition_keyword(key: String):
	_t_keyword = key
	StateUpdated.emit()

## Launches a node to be taken with the transition. Unlaunched, unimportant nodes
## will be deleted as is the normal behaviour for godot nodes.
## Unlaunched IMPORTANT nodes will be held in jail
## 
## Target can be a node that contains a SchmoveExporter2D as a child,
## or the SchmoveExporter2D itself.
func transition_launch(target: Node):
	var real = get_real_node(target)
	if real != null:
		real.get_parent().remove_child(real)
		_t_launched.append(get_exporter_node(real))
		StateUpdated.emit()
		return
	print("SCHMOVE: Failed to launch "+target.name+" as we could not find a SchmoveExporter2D in the children, and it itself is not a SchmoveExporter2D.")

## Launches every node that is in the given jail keyword. If you called Schmove.jail_node(x, "party")
## you can launch everything in that "party" word with this.
func transition_launch_jail(keyword = ""):
	if _jail.has(keyword):
		for n in _jail[keyword]:
			_t_launched.append(n)
		_jail[keyword].clear()
		StateUpdated.emit()

## Semi expensive depending on scene depth, launches every node that has the given nickname.
func transition_launch_by_name(name: String):
	var scene = get_tree().current_scene
	var exporters = _get_all_exporters(scene)
	for ex in exporters:
		if ex.Nickname == name:
			print("Launching via nickname")
			transition_launch(ex)
	StateUpdated.emit()

func transition_shuffle():
	_t_shuffle = true
	StateUpdated.emit()

func transition_wipe(shader: ShaderMaterial, duration: float):
	var tex: Image = get_viewport().get_texture().get_image()
	$Curtain.prime_transition(shader, duration, ImageTexture.create_from_image(tex))
	_t_using_wipe = true
	StateUpdated.emit()

## Schmove transitions are like a state machine, or imgui if you've used it.
## Begin a transition, use transition_* methods to customize, then finish
## with finish_transition or cancel with cancel_transition
func finish_transition():
	var start_stamp = Time.get_ticks_msec()
		
	if _t_using_wipe:
		$Curtain.run_transition()
	
	# Handle loading the next level, or using the cached version
	var target_level
	if _preloaded.has(_t_level):
		# If its still just a confirmation, switch it out with the real deal
		if _preloaded[_t_level] is bool:
			_preloaded[_t_level] = ResourceLoader.load_threaded_get(_t_level)
		target_level = _preloaded[_t_level]
	else:
		target_level = load(_t_level)
	
	var target_instance = target_level.instantiate()
	var old_instance = get_tree().current_scene
	
	var exporter_list = _get_all_exporters(old_instance)
	var importer_list = _get_all_importers(target_instance)
	
	for exporter in exporter_list:
		if exporter.Important == SchmoveExporter2D.ImportanceType.None:
			continue
		if !_t_launched.has(exporter):
			if exporter.Important == SchmoveExporter2D.ImportanceType.Launch:
				transition_launch(exporter)
			if exporter.Important == SchmoveExporter2D.ImportanceType.Jail:
				jail_node(exporter, "schmove_limbo")
	
	if _t_shuffle:
		importer_list.shuffle()
		_t_launched.shuffle()
	
	# Find the launchers a home
	for launched in _t_launched:
		# ungrouped nodes are just brought over with no modification.
		if launched.Group == 0:
			print("inserting "+launched.get_parent().name)
			var real = get_real_node(launched)
			target_instance.add_child(real)
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
				var real = get_real_node(launched)
				target_destination.add_child(real)
				real.set_deferred("global_position", importer.global_position)
				importer._consumed = true
				found = true
				launched.call_deferred("_emit_transport")
				break
		if !found:
			jail_node(launched, "schmove_limbo")
			print("SCHMOVE: Failed to find a suitable home for <"+launched.Nickname+">, sent to jail.")
	
	get_tree().root.call_deferred("add_child", target_instance)
	get_tree().set_deferred("current_scene", target_instance)
	call_deferred("_emit_transition")
	old_instance.queue_free()
	
	# Then use cancel to clear the statemachine.
	cancel_transition()
	
	var end_stamp = Time.get_ticks_msec()
	print("SCHMOVE: Successful transition, took "+str(end_stamp-start_stamp)+"ms.")

## Schmove transitions are like a state machine, or imgui if you've used it.
## Begin a transition, use transition_* methods to customize, then finish
## with finish_transition or cancel with cancel_transition
func cancel_transition():
	_t_level = ""
	_t_launched.clear()
	_t_keyword = ""
	_t_using_wipe = false
	_t_shuffle = false

## Removes a node from the tree, outside of any scene, temporarily stored until
## you want to do something with it, eg kill it, restore it, or transition it
func jail_node(target: Node, keyword: String = ""):
	var real_node: Node = get_real_node(target)
	var exporter = get_exporter_node(target)
	if !_jail.has(keyword):
		_jail[keyword] = []
	if real_node == null or exporter == null:
		print("SCHMOVE: Jailed node did not have an exporter, or was not an exporter.")
		return
	real_node.get_parent().remove_child(real_node)
	_jail[keyword].append(exporter as SchmoveExporter2D)
	exporter.call_deferred("_emit_jailed")

## Semi expensive depending on scene search depth and how you layout your nodes
func jail_by_name(name: String, keyword: String = ""):
	var exporters = _get_all_exporters(get_tree().current_scene)
	for exp in exporters:
		if exp.Nickname == name:
			jail_node(exp, keyword)
