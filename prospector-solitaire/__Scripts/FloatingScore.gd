class_name FloatingScore extends Label

enum eFSState{
	idle   = 1,
	pre    = 2,
	active = 3,
	post   = 4
}

var state : eFSState = eFSState.idle

var _score : int = 0
var scoreString : String

var bezierPts : Array[Vector2]
var fontSizes : Array[float]

var timeStart : float = -1.0
var timeDuration : float = 1.0
var easingCurve : String = Easing.InOut

var reportingFinishTo : Node = null

var rectTrans : Rect2
var txt : String

func score(s : int) -> void:
	scoreString = str(s)
	_score = s
	text = scoreString

func Init(ePts : Array[Vector2], eTimeS : float = 0.0, eTimeD : float = 1.0) -> void:
	position = Vector2.ZERO
	
	bezierPts = ePts.duplicate()
	
	if ePts.size() == 1:
		position = ePts[0]
		return
	
	if eTimeS == 0:
		eTimeS = Time.get_ticks_msec() / 1000.0
		timeStart = eTimeS
		timeDuration = eTimeD
	
	state = eFSState.pre

func FSCallback(fs : FloatingScore) -> void:
	_score += fs._score

@warning_ignore("unassigned_variable")
func _process(delta: float) -> void:
	if state == eFSState.idle:
		return
	var u : float = ((Time.get_ticks_msec() / 1000.0) - timeStart) / timeDuration
	var uC : float = Easing.Ease(u, easingCurve)
	if u < 0:
		state = eFSState.pre
		visible = false
	else:
		if u >= 1:
			uC = 1
			state = eFSState.post
			if reportingFinishTo != null:
				reportingFinishTo.FSCallback(self)
				queue_free()
			else:
				state = eFSState.idle
		else:
			state = eFSState.active
			visible = true
		
		var pos : Vector2 = Utils.Bezier_v2(uC, bezierPts)
		position = pos
		
		if fontSizes.size() > 0:
			var _size : int = roundi(Utils.BezierImpl_f(uC, fontSizes))
			add_theme_font_size_override("font_size", _size)
