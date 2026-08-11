extends Node

func attack(attacker: Node, target: Node) -> void:
	if not target.has_method("take_damage"):
		return
	var damage := randi_range(1, 6)
	target.take_damage(damage)
