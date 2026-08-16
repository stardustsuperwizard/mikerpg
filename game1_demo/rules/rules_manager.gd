extends Node

var provider: RulesProvider = LiteRulesProvider.new()

func attack(attacker: Actor, target: Actor) -> ActionResult:
	return provider.resolve_attack(attacker, target)

# Door open/lock legality is generic game logic, not an RPG-ruleset variant
# (unlike combat resolution), so it's resolved directly here rather than
# through RulesProvider.
func open(_actor: Actor, door: Door) -> ActionResult:
	if door.is_open():
		return ActionResult.new(false, &"already_open")
	if door.is_locked():
		return ActionResult.new(false, &"locked")
	door.set_open(true)
	return ActionResult.new(true, &"opened")
