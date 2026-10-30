class_name CardProspector #extends Card

enum eCardState {
	drawpile = 1,
	tableau  = 2,
	target   = 3,
	discard  = 4
}

@export var state    : eCardState         = eCardState.drawpile
@export var hiddenBy : PackedInt32Array
@export var layoutID : int
@export var slotDef  : SlotDef
