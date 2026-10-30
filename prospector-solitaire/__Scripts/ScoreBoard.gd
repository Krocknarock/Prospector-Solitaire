class_name ScoreBoard extends Label

static var S : ScoreBoard

@export var prefabFloatingScore : PackedScene

var _score : int = 0
var _scoreString : String

func score(s : int) -> void:
	_score = s
	scoreString(str(s))

func scoreString(s : String) -> void:
	_scoreString = s
	text = _scoreString

func _init() -> void:
	S = self

func FSCallback(fs : FloatingScore) -> void:
	score(_score + fs._score)

func CreateFloatingScore(amt : int, pts : Array[Vector2]) -> FloatingScore:
	var go : FloatingScore = prefabFloatingScore.instantiate()
	add_child(go)
	go.score(amt)
	go.reportingFinishTo = self
	go.Init(pts)
	return go
