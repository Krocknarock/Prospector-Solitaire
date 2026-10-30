class_name ScoreManager extends Node

enum eScoreEvent {
	draw      = 1,
	mine      = 2,
	maineGold = 3,
	gameWin   = 4,
	gameLoss  = 5
}

static var S : ScoreManager

static var SCORE_FROM_PREV_ROUND : int = 0
static var HIGH_SCORE : int = 0

@export var scoreBoard : ScoreBoard
@export var scoreRunL  : Label

var chain : int = 0
var scoreRun : int = 0
var score : int = 0

func _init() -> void:
	S = self
	#if pressKey("highScore"):
		#HIGH_SCORE = PlayerPrefs.GetInt("ProspectorHighScore")
	score += SCORE_FROM_PREV_ROUND
	SCORE_FROM_PREV_ROUND = 0

static func EVENT(evt : eScoreEvent, is_gold : bool) -> void:
	if S != null:
		S.Event(evt, is_gold)
	else:
		printerr("ScoreManager: S = null")

func Event(evt : eScoreEvent, is_gold : bool) -> void:
	match evt:
		eScoreEvent.draw, eScoreEvent.gameWin, eScoreEvent.gameLoss:
			chain = 0
			if is_gold:
				scoreRun *= 2
			score += scoreRun
			scoreRun = 0
		eScoreEvent.mine:
			chain += 1
			scoreRun += chain
			if is_gold:
				scoreRun *= 2
	
	match evt:
		eScoreEvent.gameWin:
			SCORE_FROM_PREV_ROUND = score
			print ("You won this round! Round scoe: " + str(score))
		eScoreEvent.gameLoss:
			if HIGH_SCORE < score:
				print ("You got the high score! High score: " + str(score))
				HIGH_SCORE = score
			else:
				print("Your final score for the game was: " + str(score))
		_:
			print("score: " + str(score) + " scoreRun: " + str(scoreRun) + " chain: " + str(chain))
			scoreBoard.text = str(score)
			scoreRunL.text = str(scoreRun)
