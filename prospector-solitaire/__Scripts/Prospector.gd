class_name Prospector extends Node

static var S : Prospector = null

@export var deckJSON        : JSON    = load("res://Resources/DeckJSON.tres")
@export var layoutJSON      : JSON    = load("res://Resources/Layout.tres")
@export var xOffset         : float   = 3.0
@export var yOffset         : float   = -2.5
@export var layoutCenter    : Vector3
@export var reloadDelay     : float   = 2.0
@export var gameOverText    : Label   = null
@export var roundResultText : Label   = null
@export var highScoreText   : Label   = null
@export var nextRoundButton : Button  = null

@export_category("Floating Score")
@export var fsPosMid     : Vector2 = Vector2(0.5, 0.9)
@export var fsPosRun     : Vector2 = Vector2(0.5, 0.75)
@export var fsPosMid2    : Vector2 = Vector2(0.4, 1.0)
@export var fsPosEnd     : Vector2 = Vector2(0.5, 0.95)

var fsRun : FloatingScore

var deck        : Deck                   = Deck.new()
var layout      : Layout                 = Layout.new()
var drawPile    : Array[Card]  = []
var layoutAchor : Node3D                 = null
var target      : Card
var tableau     : Array[Card]
var discardPile : Array[Card]

func _init() -> void:
	if S != null:
		push_error("Prospector is created")
		set_process(false)
		return
	S = self

func _ready() -> void:
	
	SetUpUIText()
	
	ScoreBoard.S.score(ScoreManager.S.score)
	
	randomize()
	deck.InitDeck(deckJSON.data, $"../_Deck")
	deck.cards.shuffle()
	#card.position = Vector3((cNum % 13) * 1.04, cNum / 13 * 1.5, 0)
	#for cNum in range(deck.cards.size()):
	#	deck.cards[cNum].position = Vector3((cNum % 13) * 1.04, cNum / 13 * 1.5, 0)
	layout.ReadLayout(layoutJSON)
	#drawPile = ConvertListCardsToListProspectors(deck.cards)
	drawPile = deck.cards
	
	LayoutGame()

func SetUpUIText() -> void:
	var highScore : int = ScoreManager.HIGH_SCORE
	var hScore : String = "High Score: " + str(highScore)
	highScoreText.text = hScore
	
	ShowResultsUI(false)

func ShowResultsUI(show : bool) -> void:
	gameOverText.visible    = show
	roundResultText.visible = show
	nextRoundButton.visible = show

#func ConvertListCardsToListProspectors(lCD : Array[Card]) -> Array[CardProspector]:
	#var lCP : Array[CardProspector] = []
	#var tCP : CardProspector
	#for tCD in lCD:
		#tCD.set_script("uid://mset4ihlau2l")
		#tCP = tCD as CardProspector
		#lCP.append(tCP)
	#return lCP

func Draw() -> Card:
	var cd : Card = drawPile[0]
	drawPile.remove_at(0)
	return cd

func LayoutGame() -> void:
	if layoutAchor == null:
		layoutAchor = $"../Layout"
	
	var cp : Card
	
	for tSD : SlotDef in layout.slotDefs:
		cp = Draw()
		cp.faceUp = tSD.faceUp
		if cp.back:
			cp.back.visible = not cp.faceUp
		#layoutAchor.add_child(cp)
		cp.reparent(layoutAchor)
		cp.position = Vector3(
			layout.multiplier.x * tSD.x,
			layout.multiplier.y * tSD.y,
			tSD.layerID
		)
		cp.layoutID = tSD.id
		cp.slotDef = tSD
		cp.state = Card.eCardState.tableau
		
		cp.is_gold = randf() < 0.1
		if cp.is_gold:
			cp.back.texture = deck.carbBackGold
			cp.modulate = Color.YELLOW
		tableau.append(cp)
	
	for tCP : Card in tableau:
		for hid : int in tCP.slotDef.hiddenBy:
			cp = FindCardByLayoutID(hid)
			if cp != null:
				tCP.hiddenBy.append(cp)
	
	MoveToTarget(Draw())
	UpdateDrawPile()

func FindCardByLayoutID(layoutID : int) -> Card:
	for tCP : Card in tableau:
		if tCP.layoutID == layoutID:
			return tCP
	return null

func SetTableauFaces() -> void:
	for cd : Card in tableau:
		var faceUp : bool = true
		for cover : Card in cd.hiddenBy:
			if cover.state == Card.eCardState.tableau:
				faceUp = false
		cd.is_face(faceUp)
		#print (faceUp)

func CardClicked(cd : Card) -> void:
	match cd.state:
		Card.eCardState.target:
			pass
		Card.eCardState.drawpile:
			MoveToDiscard(target)
			MoveToTarget(Draw())
			UpdateDrawPile()
			ScoreManager.EVENT(ScoreManager.eScoreEvent.draw, cd.is_gold)
			FloatingScoreHandler(ScoreManager.eScoreEvent.draw)
		Card.eCardState.tableau:
			var validMatch : bool = true
			if !cd.faceUp:
				validMatch = false
			if !AdjacentRank(cd, target):
				validMatch = false
			if !validMatch:
				return
			tableau.erase(cd)
			MoveToTarget(cd)
			SetTableauFaces()
			
			ScoreManager.EVENT(ScoreManager.eScoreEvent.mine, cd.is_gold)
			
			FloatingScoreHandler(ScoreManager.eScoreEvent.mine)
	CheckForGameOver()

func FloatingScoreHandler(evt : ScoreManager.eScoreEvent) -> void:
	var fsPts : Array[Vector2]
	match evt:
		ScoreManager.eScoreEvent.draw, ScoreManager.eScoreEvent.gameWin, ScoreManager.eScoreEvent.gameLoss:
			if fsRun != null:
				fsPts.append(fsPosRun)
				fsPts.append(fsPosMid2)
				fsPts.append(fsPosEnd)
				fsRun.reportingFinishTo = ScoreBoard.S
				fsRun.fontSizes = [28, 36, 4]
				fsRun = null
		ScoreManager.eScoreEvent.mine:
			var fs : FloatingScore
			var p0 : Vector2 = get_viewport().get_mouse_position()
			#p0.x /= get_window().size.x
			#p0.y /= get_window().size.y
			fsPts.append(p0)
			fsPts.append(fsPosMid)
			fsPts.append(fsPosRun)
			fs = ScoreBoard.S.CreateFloatingScore(ScoreManager.S.scoreRun, fsPts)
			fs.fontSizes = [4, 50, 28]
			if fsRun == null:
				fsRun = fs
				fsRun.reportingFinishTo = fsRun

func CheckForGameOver() -> void:
	if tableau.size() == 0:
		GameOver(true)
		return
	if drawPile.size() > 0:
		return
	for cd : Card in tableau:
		if AdjacentRank(cd, target):
			return
	
	GameOver(false)

func GameOver(won : bool) -> void:
	if won:
		gameOverText.text = "Round over"
		roundResultText.text = "You won this round!\nRound Score: " + str(ScoreManager.S.score)
		ShowResultsUI(true)
		#print ("Game over. You Won! :)")
		ScoreManager.EVENT(ScoreManager.eScoreEvent.gameWin, false)
		FloatingScoreHandler(ScoreManager.eScoreEvent.gameWin)
	else:
		gameOverText.text = "Game Over"
		if ScoreManager.HIGH_SCORE < ScoreManager.S.score:
			roundResultText.text = "You got the high score!\nHigh Score: " + str(ScoreManager.S.score)
		else:
			roundResultText.text = "Your final score was: " + str(ScoreManager.S.score)
		ShowResultsUI(true)
		#print("Game over. You Lost. :(")
		ScoreManager.EVENT(ScoreManager.eScoreEvent.gameLoss, false)
		FloatingScoreHandler(ScoreManager.eScoreEvent.gameLoss)
	#await get_tree().create_timer(reloadDelay).timeout
	

func next_round() -> void:
	S = null
	#Deck.reset()
	get_tree().reload_current_scene()

func AdjacentRank(c0 : Card, c1 : Card) -> bool:
	if !c0.faceUp || !c1.faceUp:
		return false
	if abs(c0.rank - c1.rank) == 1:
		return true
	if c0.rank == 1 && c1.rank == 13:
		return true
	if c0.rank == 13 && c1.rank == 1:
		return(true)
	return false
func MoveToDiscard(cd : Card) -> void:
	cd.state = Card.eCardState.discard
	if cd.get_parent() == null:
		layoutAchor.add_child(cd)
	discardPile.append(cd)
	cd.position = Vector3(
		layout.multiplier.x * layout.discardPile.x,
		layout.multiplier.y * layout.discardPile.y,
		layout.discardPile.layerID - 0.5
	)
	cd.is_face(true)

func MoveToTarget(cd : Card) -> void:
	if target != null:
		MoveToDiscard(target)
	target = cd
	cd.state = Card.eCardState.target
	if cd.get_parent() == null:
		layoutAchor.add_child(cd)
	cd.position = Vector3(
		layout.multiplier.x * layout.discardPile.x,
		layout.multiplier.y * layout.discardPile.y,
		layout.discardPile.layerID
	)
	cd.is_face(true)

func UpdateDrawPile() -> void:
	var cd : Card
	for i in range(drawPile.size()):
		cd = drawPile[i]
		if cd.get_parent() == null:
			layoutAchor.add_child(cd)
		var dpStagger : Vector2 = layout.drawPile.stagger
		cd.position = Vector3(
			layout.multiplier.x * (layout.drawPile.x + i * dpStagger.x) - 0.5,
			layout.multiplier.y * (layout.drawPile.y + i * dpStagger.y),
			layout.drawPile.layerID + 0.1 * i
		)
		cd.is_face(false)
		cd.state = Card.eCardState.drawpile
