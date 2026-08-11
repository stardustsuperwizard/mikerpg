extends Area3D

@export var prototype_id: String = ""

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	var inventory: Inventory = body.get_node_or_null("Inventory")
	if inventory == null:
		return
	if inventory.create_and_add_item(prototype_id):
		queue_free()
