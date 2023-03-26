extends CanvasLayer

var _dur: float = -1.0
var _timer: float = -1.0
var _from: Texture2D = null
var _running = false
var _scale = 0.0

func _ready():
	visible = false

func prime_transition(material: ShaderMaterial, duration: float, from: Texture2D):
	_scale = Engine.time_scale
	if material != null:
		$TextureRect.material = material
	_dur = duration
	_timer = duration
	$TextureRect.texture = from

func run_transition():
	visible = true
	_running = true
	
func _process(delta):
	var should_mush = ProjectSettings.get_setting("application/schmove/time_mush_on_wipe_transition", true)
	if _running:
		_timer -= Schmove._get_average_delta()
		var prog = 1.0-(_timer / _dur)
		if should_mush:
			var mush = ProjectSettings.get_setting("application/schmove/time_mush", 0.1)
			Engine.time_scale = lerp(mush, _scale, prog)
		$TextureRect.material.set_shader_parameter("progress", prog)
	
	if _running and _timer <= 0.0:
		visible = false
		_running = false
		_dur = -1.0
		_timer = -1.0
		Engine.time_scale = _scale
		$TextureRect.texture = null
		return
