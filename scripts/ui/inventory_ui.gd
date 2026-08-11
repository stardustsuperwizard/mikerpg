extends CanvasLayer

@onready var ctrl_inventory: CtrlInventory = $Panel/VBoxContainer/CtrlInventory

func _ready() -> void:
	visible = false
	var player := get_tree().get_first_node_in_group("players")
	if player:
		ctrl_inventory.inventory = player.get_node("Inventory")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		visible = not visible
