extends Node

var provider: RulesProvider = LiteRulesProvider.new()

func attack(attacker: Actor, target: Actor) -> void:
	provider.resolve_attack(attacker, target)
