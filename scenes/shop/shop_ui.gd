extends Control

signal unit_selected
signal unit_bought(res : PlaceholderUnitResource)

var energy : int = 0:
	set(new):
		if new < 0:
			print("Attempted to write negative energy")
			return
		energy = new
		%EnergyLabel.text = str(new)
var selected_unit : PlaceholderUnitResource:
	set(new):
		selected_unit = new
		if new: unit_selected.emit()
		%ClickTileHint.visible = new != null


@onready var unit_card_1 : UnitCardButton = $MarginContainer/VBoxContainer/LowerUI/Units/MarginContainer/UnitCardContainer/UnitCard
@onready var unit_card_2 : UnitCardButton = $MarginContainer/VBoxContainer/LowerUI/Units/MarginContainer/UnitCardContainer/UnitCard2
@onready var unit_card_3 : UnitCardButton = $MarginContainer/VBoxContainer/LowerUI/Units/MarginContainer/UnitCardContainer/UnitCard3
@onready var unit_card_4 : UnitCardButton = $MarginContainer/VBoxContainer/LowerUI/Units/MarginContainer/UnitCardContainer/UnitCard4
@onready var unit_card_5 : UnitCardButton = $MarginContainer/VBoxContainer/LowerUI/Units/MarginContainer/UnitCardContainer/UnitCard5
@onready var unit_card_6 : UnitCardButton = $MarginContainer/VBoxContainer/LowerUI/Units/MarginContainer/UnitCardContainer/UnitCard6

@onready var unit_cards : Dictionary[UnitCardButton, PlaceholderUnitResource] = {
	unit_card_1 : null,
	unit_card_2 : null,
	unit_card_3 : null,
	unit_card_4 : null,
	unit_card_5 : null,
	unit_card_6 : null
}
@export var unit_resources : Array[PlaceholderUnitResource]


func _ready():
	unit_card_1.connect("pressed", unit_1_selected)
	unit_card_2.connect("pressed", unit_2_selected)
	unit_card_3.connect("pressed", unit_3_selected)
	unit_card_4.connect("pressed", unit_4_selected)
	unit_card_5.connect("pressed", unit_5_selected)
	unit_card_6.connect("pressed", unit_6_selected)
	
	open_shop(6) # debugging call

func open_shop(available_energy:int):
	# Call this to activate shop!!
	visible = true
	energy = available_energy
	# Make sure energy is set before units are refreshed!
	# unit cards need to know if their unit is affordable
	refresh_units()

func buy_unit():
	# Call this to buy the selected unit!
	# Ie, whatever system in place that connects the bought unit to the tile
	# will call this function to get that unit
	# currently unit cost is stored in the placeholder resource, so the actual
	# object containing unit data will also need to contain cost
	
	# This function is untested as of PR
	
	if !selected_unit:
		print("No unit selected!")
		return
	unit_bought.emit(selected_unit)
	
	# if you don't want to hide it immediately, replace
	# hide call with open_shop(energy - selected_unit.unit_cost)
	hide()

func select_unit(ures : PlaceholderUnitResource):
	if ures == null:return
	if ures.unit_cost > energy:
		print("Costs too much!")
		return
	%GenericStatsLabel.text = str(ures.generic_stat) # sample, replace with actual stats
	selected_unit = ures
	for key in unit_cards:
		key.disabled = false
	selected_unit = ures

func refresh_units():
	selected_unit = null
	%GenericStatsLabel.text = ""
	for key in unit_cards:
		var ures = unit_resources.pick_random()
		key.set_display(ures.texture, ures.unit_class, ures.unit_cost)
		unit_cards[key] = ures
		key.set_affordable(energy >= ures.unit_cost)

func unit_1_selected():
	select_unit(unit_cards[unit_card_1])

func unit_2_selected():
	select_unit(unit_cards[unit_card_2])

func unit_3_selected():
	select_unit(unit_cards[unit_card_3])

func unit_4_selected():
	select_unit(unit_cards[unit_card_4])

func unit_5_selected():
	select_unit(unit_cards[unit_card_5])

func unit_6_selected():
	select_unit(unit_cards[unit_card_6])


func _on_refresh_button_pressed():
	# if refreshing has a cost, try
	# open_shop(energy - refresh_cost)
	refresh_units()
