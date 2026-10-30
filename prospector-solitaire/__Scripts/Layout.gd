class_name Layout extends Resource

@export var jsonLayout : JSON
@export var multiplier : Vector2
@export var slotDefs : Array[SlotDef]
@export var drawPile : SlotDef
@export var discardPile : SlotDef
@export var sortingLayerNames : PackedStringArray = [
	"Row0",
	"Row1",
	"Row2",
	"Row3",
	"Discard",
	"Draw"
]

func ReadLayout(jsonDict : JSON) -> void:
	multiplier.x = float(jsonDict.data["meta"]["multiplier"]["x"])
	multiplier.y = float(jsonDict.data["meta"]["multiplier"]["y"])
	
	var tSD : SlotDef
	var slot : Array = jsonDict.data["slots"]
	
	for i in range(slot.size()):
		tSD = SlotDef.new()
		if slot[i].has("type"):
			tSD.type = slot[i]["type"]
		else:
			tSD.type = "slot"
		tSD.x = float(slot[i]["x"])
		tSD.y = float(slot[i]["y"])
		tSD.layerID = int(slot[i]["layer"])
		tSD.layerName = sortingLayerNames[tSD.layerID]
		match tSD.type:
			"slot":
				tSD.faceUp = slot[i]["faceup"]
				tSD.id = int(slot[i]["id"])
				if slot[i].has("hiddenby"):
					for h in slot[i]["hiddenby"]:
						tSD.hiddenBy.append(int(h))
				slotDefs.append(tSD)
			"drawpile":
				tSD.stagger.x = float(slot[i]["xstagger"])
				drawPile = tSD
			"discardpile":
				discardPile = tSD
