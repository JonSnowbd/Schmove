extends Container


@onready var _tree: Tree = $Split/Tabs/State/Tree
@onready var _log_scroll: ScrollContainer = $Split/Tabs/Log/Scroll
@onready var _log: VBoxContainer = $Split/Tabs/Log/Scroll/Padding/LogBox

@onready var _t_text: LineEdit = $Split/Toybox/Entries/Target
@onready var _kw_text: LineEdit = $Split/Toybox/Entries/Keyword

var label_settings

func _log_func(msg, i):
	var lab = Label.new()
	lab.text = "- "+msg
	lab.label_settings = label_settings
	if i == 1:
		lab.self_modulate = Color.DARK_GOLDENROD
	if i == 2:
		lab.self_modulate = Color.DARK_RED
	while _log.get_child_count() > 50:
		_log.remove_child(_log.get_child(0))
	_log.add_child(lab)
	_log_scroll.call_deferred("ensure_control_visible", lab)
func _update():
	pass

func _ready():
	label_settings = LabelSettings.new()
	label_settings.font_size = 10.0
	Schmove.Logged.connect(_log_func)
	
func _process(delta):
	pass


func _on_save_pressed():
	Schmove.save_state("user://_debug.json")
func _on_load_pressed():
	Schmove.load_state("user://_debug.json")

func _on_jail_pressed():
	Schmove.jail_by_name(_t_text.text, _kw_text.text)
	_t_text.text = ""
	_kw_text.text = ""
func _on_launch_pressed():
	Schmove.transition_launch_by_name(_t_text.text)
	_t_text.text = ""
	_kw_text.text = ""
