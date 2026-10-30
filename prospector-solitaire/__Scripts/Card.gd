class_name Card extends Sprite3D

var suit      : String
var rank      : int
var color     : Color = Color.BLACK
var colS      : String = "Black"

var decoGOs   : Array[Sprite3D]
var pipGOs    : Array[Node3D] = []
var back      : Sprite3D
var def       : CardDefinition

var faceUp  : bool = true
var is_gold : bool = false

# # # # # # # CardProspector # # # # # # # #

enum eCardState {
	drawpile = 1,
	tableau  = 2,
	target   = 3,
	discard  = 4
}

@export var state    : eCardState         = eCardState.drawpile
@export var hiddenBy : Array[Card]
@export var layoutID : int
@export var slotDef  : SlotDef

func _ready() -> void:
	scale *= 0.5

@warning_ignore("unassigned_variable")
func _on_static_body_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		#print ("Clicked: " + name)
		Prospector.S.CardClicked(self)

func is_face(b : bool) -> void:
	faceUp = b
	back.visible = not b
