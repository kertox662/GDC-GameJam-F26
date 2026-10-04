class_name UnitCardButton
extends Control
signal pressed

@onready var _button := $TextureButton
@onready var _text_rect := $TextureRect
@onready var _class_label := $VBoxContainer/ClassLabel
@onready var _cost_label := $VBoxContainer/CostLabel

var disabled : bool = false:
	set(new):
		disabled = new
		_button.disabled = new

func set_display(texture: Texture2D, unit_class: String, unit_cost: int):
	_text_rect.texture = texture
	_class_label.text = unit_class
	_cost_label.text = str(unit_cost)

func _ready():
	_button.connect("pressed", _on_pressed)

func _on_pressed():
	pressed.emit()
	# Note: when emit, shop ui enables all buttons, then the pressed one disables itself
	disabled = true

func set_affordable(is_affordable:bool):
	if is_affordable:
		disabled = false
		modulate = Color(1,1,1,1)
	else:
		disabled = true
		modulate = Color(1,1,1,1) * 0.5
