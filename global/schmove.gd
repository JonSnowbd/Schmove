extends Node

## Ran on a deferred call after a scene switch via Schmove api
signal DeferredSceneTransition
signal StateUpdated
signal Logged(message: String, log_type: int)

const WipeCircle = preload("res://addons/schmove/material/circle_wipe.tres")
const WipeStickGlitch = preload("res://addons/schmove/material/stick_wipe.tres")
const ExporterGroup = "schmove_exporters"
const ImporterGroup = "schmove_importers"
const StaticGroup = "schmove_statics"

var _preloaded: Dictionary = {}
var _launched: Array[SchmoveExporter2D] = []
var _average_delta: Array[float] = []

var state: Dictionary = {
	"level": "",
	"data": {},
	"static_data": {},
	"jail": {},
}

func _ready():
	_average_delta.append(1.0/60.0)
func _process(delta):
	var scale = ProjectSettings.get_setting("application/schmove/time_mush", 0.1)
	if Engine.time_scale > scale and !$Curtain._running:
		_average_delta.append(delta)
		if len(_average_delta) > 10:
			_average_delta.pop_front()

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
var _t_stamp = 0


func _get_average_delta():
	var d = 0.0
	for delt in _average_delta:
		d+=delt
	return d / len(_average_delta)
func _emit_transition():
	DeferredSceneTransition.emit()

func _get_all_statics_in_tree() -> Array[SchmoveStatic2D]:
	var nodes =  get_tree().get_nodes_in_group(StaticGroup)
	var statics: Array[SchmoveStatic2D] = []
	for x in nodes:
		if x is SchmoveStatic2D:
			statics.append(x as SchmoveStatic2D)
	return statics
func _get_all_exporters_in_tree() -> Array[SchmoveExporter2D]:
	var nodes =  get_tree().get_nodes_in_group(ExporterGroup)
	var exports: Array[SchmoveExporter2D] = []
	for x in nodes:
		if x is SchmoveExporter2D:
			exports.append(x as SchmoveExporter2D)
	return exports
func _get_all_importers_in_tree() -> Array[SchmoveImporter2D]:
	var nodes =  get_tree().get_nodes_in_group(ImporterGroup)
	var imports: Array[SchmoveImporter2D] = []
	for x in nodes:
		if x is SchmoveImporter2D:
			imports.append(x as SchmoveImporter2D)
	return imports

## Schmove transitions are like a state machine, or imgui if you've used it.
## Begin a transition, use transition_* methods to customize, then finish
## with finish_transition or cancel with cancel_transition
func begin_transition(new_level_path: String):
	_t_level = new_level_path
	state["level"] = new_level_path
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
## you can launch everything in that "party" word with Schmove.transition_launch_jail("party")
func transition_launch_jail(keyword = ""):
	if state["jail"].has(keyword):
		for n in state["jail"][keyword]:
			_t_launched.append(n)
		state["jail"][keyword].clear()
		StateUpdated.emit()

## Semi expensive depending on scene depth, launches every node that has the given nickname.
func transition_launch_by_name(name: String):
	var exporters = _get_all_exporters_in_tree()
	var count = 0
	for ex in exporters:
		if ex.Nickname == name:
			count += 1
			transition_launch(ex)
	StateUpdated.emit()
	Logged.emit("Launch request '%s' finished, affected %s units" % [name, str(count)], 0)

func transition_shuffle():
	_t_shuffle = true
	StateUpdated.emit()

func save_state(user_path: String):
	var _j: Dictionary = state["jail"]
	for kw in _j.keys():
		for exp in _j[kw]:
			if exp is SchmoveExporter2D:
				if exp.Nickname != "" and !exp.IgnoreOnSave:
					exp.push_state()
					state["data"][exp.Nickname]["__jailed"] = kw
	var exporters = _get_all_exporters_in_tree()
	for exp in exporters:
		if exp.Nickname != "" and !exp.IgnoreOnSave:
			exp.push_state()
	var final_data = {
		"data": state["data"],
		"level": state["level"],
		"static_data": state["static_data"]
	}
	var f = FileAccess.open(user_path, FileAccess.WRITE)
	if f == null:
		push_error("Failed to open %s, error #%s" % [user_path, FileAccess.get_open_error()])
		return
	f.store_var(final_data, true)

func load_state(user_path: String):
	var f = FileAccess.open(user_path, FileAccess.READ)
	if f == null:
		push_error("Failed to open %s, error #%s" % [user_path, FileAccess.get_open_error()])
		return
	var dict: Dictionary = f.get_var(true)
	var level = load(dict["level"])
	get_tree().change_scene_to_packed(level)
	await get_tree().process_frame
	
	state = {
		"jail": {},
		"level": dict["level"],
		"data": dict["data"],
		"static_data": dict["static_data"]
	}
	for kw in dict["data"].keys():
		print(dict["data"][kw])
		if dict["data"][kw].has("__prefab"):
			var prefab = load(dict["data"][kw]["__prefab"])
			var instance = prefab.instantiate()
			get_tree().current_scene.add_child(instance)
			var exporter = get_exporter_node(instance)
			if exporter is SchmoveExporter2D:
				exporter.pull_state()

func transition_wipe(shader: ShaderMaterial, duration: float):
	var tex: Image = get_viewport().get_texture().get_image()
	$Curtain.prime_transition(shader, duration, ImageTexture.create_from_image(tex))
	_t_using_wipe = true
	StateUpdated.emit()

## Schmove transitions are like a state machine, or imgui if you've used it.
## Begin a transition, use transition_* methods to customize, then finish
## with finish_transition or cancel with cancel_transition
func finish_transition():
	_t_stamp = Time.get_ticks_msec()
		
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
		
	# Sync all the static states before we move over.
	var static_list = _get_all_statics_in_tree()
	for stc in static_list:
		stc.push_state()

	var exporter_list = _get_all_exporters_in_tree()
	for exporter in exporter_list:
		if exporter.Important == SchmoveExporter2D.ImportanceType.None:
			continue
		if !_t_launched.has(exporter):
			if exporter.Important == SchmoveExporter2D.ImportanceType.Launch:
				transition_launch(exporter)
			if exporter.Important == SchmoveExporter2D.ImportanceType.Jail:
				jail_node(exporter, "schmove_limbo")
	
	get_tree().change_scene_to_packed(target_level)

## Schmove transitions are like a state machine, or imgui if you've used it.
## Begin a transition, use transition_* methods to customize, then finish
## with finish_transition or cancel with cancel_transition
func cancel_transition():
	_t_level = ""
	_t_launched.clear()
	_t_keyword = ""
	_t_using_wipe = false
	_t_shuffle = false
	_t_stamp = 0
	StateUpdated.emit()

## Removes a node from the tree, outside of any scene, temporarily stored until
## you want to do something with it, eg kill it, restore it, or transition it
func jail_node(target: Node, keyword: String = ""):
	var real_node: Node = get_real_node(target)
	var exporter = get_exporter_node(target)
	if !state["jail"].has(keyword):
		state["jail"][keyword] = []
	if real_node == null or exporter == null:
		print("SCHMOVE: Jailed node did not have an exporter, or was not an exporter.")
		return
	var parent = real_node.get_parent()
	if parent != null:
		parent.remove_child(real_node)
	state["jail"][keyword].append(exporter as SchmoveExporter2D)
	exporter.call_deferred("_emit_jailed")
	Logged.emit("Jailed %s" % real_node.name, 0)

func jail_by_name(name: String, keyword: String = ""):
	var exporters = _get_all_exporters_in_tree()
	var count = 0
	for exp in exporters:
		if exp.Nickname == name:
			count += 1
			jail_node(exp, keyword)
	Logged.emit("Jail request '%s' finished, affected %s units" % [name, str(count)], 0)
