class_name Deck extends Resource

var jsn : JSON

var suitClub    : CompressedTexture2D = load("uid://bbfa8n11k7cxg")
var suitDiamond : CompressedTexture2D = load("uid://cb21gmrm2hoi7")
var suitHeart   : CompressedTexture2D = load("uid://c4ixlaiosqsew")
var suitSpade   : CompressedTexture2D = load("uid://bbvohr8wgio7")

var faceSprites : Dictionary = {
	"FaceCard_11C" : load("uid://bd4fdlfisccdr"),#11C
	"FaceCard_11D" : load("uid://lsih4heb1l1q"),#11D
	"FaceCard_11H" : load("uid://chjwo7q7qpld0"),#11H
	"FaceCard_11S" : load("uid://b0kvtiyyitvjj"),#11S
	"FaceCard_12C" : load("uid://cvlkmuviukye7"),#12C
	"FaceCard_12D" : load("uid://8bqvq35ojvid"),#12D
	"FaceCard_12H" : load("uid://cxhle1m3unkdb"),#12H
	"FaceCard_12S" : load("uid://nyuhj608y1v4"),#12S
	"FaceCard_13C" : load("uid://b3bj6jufjj1q4"),#13C
	"FaceCard_13D" : load("uid://bbowyr1ut6tym"),#13D
	"FaceCard_13H" : load("uid://htmcpeobaukk"),#13H
	"FaceCard_13S" : load("uid://c4tiwxklulm6n")#13S
}

var rankSprites    : Array[Texture2D] = _slice_texture("uid://bk72ql1sk24mk")

var cardBack       : CompressedTexture2D = load("uid://6f00qchp3e7w")
var carbBackGold   : CompressedTexture2D = load("uid://coy2dr85c5uwp")
var cardFront      : CompressedTexture2D = load("uid://dr4gyfw8b54i0")
var cardFrontGold  : CompressedTexture2D = load("uid://ccm8r8gwgvc3e")

var prefabCart      : PackedScene
var pathPrefabCart  : String = "uid://cypfhh34de8ft"
var prefabSprite    : PackedScene
var prefabSpriteUID : String = "uid://vscjna4jcdb"

var cardNames  : PackedStringArray
var cards      : Array[Card]
var decorators : Array[Decorator]
var cardDefs   : Array[CardDefinition]
var deckAchor  : Node3D = null
var dictSuits  : Dictionary

var _tGO : Sprite3D = null

var startFaceUp : bool = true

func reset() -> void:
	jsn = null
	cardNames.clear()
	cards.clear()
	decorators.clear()
	cardDefs.clear()
	deckAchor = null
	dictSuits.clear()
	_tGO = null

func _slice_texture(img_path : String) -> Array[Texture2D]:
	var img : Image = load(img_path)
	if img == null:
		push_error("Deck._slice_texture: not load image")
	
	var total_wight : float = img.get_width()
	var height : int = int(img.get_height())
	var count  : int = int(total_wight / height)
	var tile_w : int = int(total_wight / count)
	
	var textures : Array[Texture2D]
	for i in range(count):
		var x : float = i * tile_w
		var sub_img : Image = img.get_region(Rect2i(int(x), 0, tile_w, height))
		var tex : ImageTexture = ImageTexture.create_from_image(sub_img)
		textures.append(tex)
	
	return textures

func InitDeck(deckDict : Dictionary, deck : Marker3D) -> void:
	deckAchor = deck
	
	prefabCart   = load(pathPrefabCart)
	prefabSprite = load(prefabSpriteUID)
	
	dictSuits = {
		"C" = suitClub,
		"D" = suitDiamond,
		"H" = suitHeart,
		"S" = suitSpade
	}
	ReadDeck(deckDict)
	
	MakeCards()

func ReadDeck(deckDict : Dictionary) -> void:
	#print (deckJSONText["decorators"][0])
	decorators = []
	var deco : Decorator
	for i in range(deckDict["decorators"].size()):
		deco = Decorator.new()
		deco.type  = deckDict["decorators"][i]["type"]
		deco.flip  = deckDict["decorators"][i]["flip"] == 1
		deco.scale = deckDict["decorators"][i]["scale"]
		deco.loc.x = deckDict["decorators"][i]["x"]
		deco.loc.y = deckDict["decorators"][i]["y"]
		deco.loc.z = deckDict["decorators"][i]["z"]
		decorators.push_back(deco)
	
	cardDefs = []
	for i in range(deckDict["cards"].size()):
		var cDef : CardDefinition = CardDefinition.new()
		cDef.rank = int(deckDict["cards"][i]["rank"])
		if deckDict["cards"][i].has("pips"):
			for j in range(deckDict["cards"][i]["pips"].size()):
				deco = Decorator.new()
				deco.type = "pip"
				deco.flip = deckDict["cards"][i]["pips"][j]["flip"] == 1
				deco.loc.x = float(deckDict["cards"][i]["pips"][j]["x"])
				deco.loc.y = float(deckDict["cards"][i]["pips"][j]["y"])
				deco.loc.z = float(deckDict["cards"][i]["pips"][j]["z"])
				if deckDict["cards"][i]["pips"][j].has("scale"):
					deco.scale = float(deckDict["cards"][i]["pips"][j]["scale"])
				cDef.pips.push_back(deco)
		if deckDict["cards"][i].has("face"):
			cDef.face = deckDict["cards"][i]["face"]
		cardDefs.push_back(cDef)
	

func GetCardDefinitionBYRank(rank : int) -> CardDefinition:
	for cd in cardDefs:
		if cd.rank == rank:
			return cd
	
	return null

func MakeCards() -> void:
	var letters : PackedStringArray = [
		"C",
		"D",
		"H",
		"S"
	]
	for s in letters:
		for i in range(13):
			cardNames.append(s+str(i+1))
	
	for i in range(cardNames.size()):
		cards.append(MakeCard(i))

func MakeCard(cNum : int) -> Sprite3D:
	var card : Sprite3D = prefabCart.instantiate()
	deckAchor.add_child(card)
	@warning_ignore("integer_division")
	card.position = Vector3((cNum % 13) * 1.04, cNum / 13 * 1.5, 0)
	card.texture = cardFront
	#card.sorting_offset += 0.1 * cNum
	
	card.name = cardNames[cNum]
	var n : String = str(card.name)
	card.suit = n[0]
	card.rank = int(n.substr(1))
	if card.suit == "D" || card.suit == "H":
		card.colS = "Red"
		card.color = Color.RED
	card.def = GetCardDefinitionBYRank(card.rank)
	
	AddDecorators(card)
	AddPips(card)
	AddFace(card)
	AddBack(card)
	
	return card

func AddDecorators(card : Sprite3D) -> void:
	if card.rank > 10:
		return
	for deco in decorators:
		if deco.type == "suit":
			_tGO = prefabSprite.instantiate()
			_tGO.texture = dictSuits[card.suit]
		else:
			_tGO = prefabSprite.instantiate()
			_tGO.texture = rankSprites[card.rank]
			_tGO.modulate = card.color
		_tGO.sorting_offset = 0.1
		card.add_child(_tGO)
		_tGO.position = deco.loc
		#if deco.flip:
		#	_tGO.rotation_degrees.z = 180
		if deco.scale != 1:
			_tGO.scale_object_local(Vector3.ONE * deco.scale)
		_tGO.name = deco.type
		card.decoGOs.append(_tGO)

func AddPips(card : Sprite3D) -> void:
	for pip in card.def.pips:
		_tGO = prefabSprite.instantiate()
		card.add_child(_tGO)
		_tGO.position = pip.loc
		#if pip.flip:
		#	_tGO.rotation_degrees.z = 180
		if pip.scale != 1:
			_tGO.scale = Vector3.ONE * pip.scale
		_tGO.name = "pip"
		_tGO.texture = dictSuits[card.suit]
		_tGO.sorting_offset = 0.1
		card.pipGOs.append(_tGO)

func AddFace(card : Sprite3D) -> void:
	if card.def.face == "":
		return
	
	var face : String = card.def.face + card.suit
	card.texture = faceSprites[face]
	#Размер карт
	card.pixel_size *= 1.24

func AddBack(card : Sprite3D) -> void:
	_tGO = prefabSprite.instantiate()
	_tGO.texture = cardBack
	card.add_child(_tGO)
	card.faceUp = startFaceUp
	_tGO.sorting_offset = 0.2
	_tGO.visible = not startFaceUp
	card.back = _tGO
