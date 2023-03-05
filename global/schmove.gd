extends Node

const WipeCircle = preload("res://addons/schmove/material/circle_wipe.tres")

var _uniques: Dictionary = {}
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

## If you're making more levels than you have ram, you can flush
## this out at your judgement.
func preload_flush():
	_preloaded.clear()

var _t_level: String = ""
var _t_nodes: Array[SchmoveExporter2D] = []
var _t_launchers: Array[SchmoveExporter2D] = []
var _t_importers: Array[SchmoveImporter2D] = []
var _t_keyword: String = ""
var _using_wipe: bool = false

func _t_dig(node: Node):
	if node is SchmoveImporter2D: 
		return
	for c in node.get_children():
		if c is SchmoveExporter2D:
			_t_nodes.append(c)
		else:
			_t_dig(c)
func _i_dig(node: Node):
	for c in node.get_children():
		if c is SchmoveImporter2D:
			_t_importers.append(c)
		else:
			_i_dig(c)

## Schmove transitions are like a state machine, or imgui if you've used it.
## Begin a transition, use transition_* methods to customize, then finish
## with finish_transition or cancel with cancel_transition
func begin_transition(new_level_path: String):
	_t_level = new_level_path
	

## Importers can be locked behind a keyword. A target import slot is used only if
## their keywords match the transition keyword, IF either are set to anything but ""
func transition_keyword(key: String):
	_t_keyword = key

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
		_t_launchers.append(get_exporter_node(real))
		return
	print("SCHMOVE: Failed to launch "+target.name+" as we could not find a SchmoveExporter2D in the children, and it itself is not a SchmoveExporter2D.")

func transition_wipe(shader: ShaderMaterial, duration: float):
	$Curtain.prime_transition(shader, duration)
	_using_wipe = true

## Schmove transitions are like a state machine, or imgui if you've used it.
## Begin a transition, use transition_* methods to customize, then finish
## with finish_transition or cancel with cancel_transition
func finish_transition():
	var start_stamp = Time.get_ticks_msec()
		
	if _using_wipe:
		var tex: Image = get_viewport().get_texture().get_image()
		$Curtain.run_transition(ImageTexture.create_from_image(tex))
	
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
	
	# Find all the schmovers
	_t_dig(old_instance)
	_i_dig(target_instance)
	for ent in _t_nodes:
		if !ent.Important:
			continue
		jail_node(ent, "schmove_limbo")
	
	# Find the launchers a home
	for launched in _t_launchers:
		for importer in _t_importers:
			if importer.TransitionKeyword != "" or _t_keyword != "":
				if importer.TransitionKeyword != _t_keyword:
					continue
			if importer._consumed:
				continue
			if importer.is_compatible(launched):
				var real = get_real_node(launched)
				importer.get_parent().add_child(real)
				real.set_deferred("global_position", importer.global_position)
				importer._consumed = true
				break
	
	get_tree().root.call_deferred("add_child", target_instance)
	get_tree().set_deferred("current_scene", target_instance)
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
	_t_nodes.clear()
	_t_launchers.clear()
	_t_importers.clear()
	_t_keyword = ""
	_using_wipe = false

func unique_register(nick: String, target: Node):
	if !_uniques.has(nick):
		_uniques[nick] = target
func unique_available(nick: String) -> bool:
	if _uniques.has(nick):
		return false
	return true

## Removes a node from the tree, outside of any scene, temporarily stored until
## you want to do something with it, eg kill it, restore it, transition it,
## or flat out just leave it in jail so it doesnt 'respawn' if it is a unique exporter.
func jail_node(target: Node, keyword: String = ""):
	var real_node: Node = null
	if target is SchmoveExporter2D:
		_t_launchers.append(target as SchmoveExporter2D)
		real_node = target.get_parent()
		real_node.get_parent().remove_child(real_node)
	else:
		for c in target.get_children():
			if c is SchmoveExporter2D:
				_t_launchers.append(c)
				real_node = c.get_parent()
				real_node.get_parent().remove_child(real_node)
	if real_node == null:
		print("SCHMOVE: Failed to jail "+target.name+" as we could not find a SchmoveExporter2D in the children, and it itself is not a SchmoveExporter2D.")
		return
	if _jail.has(keyword):
		_jail[keyword].append(real_node)
