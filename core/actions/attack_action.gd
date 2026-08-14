class_name AttackAction
extends Action

var target: Actor

func _init(p_actor: Actor, p_target: Actor) -> void:
	super._init(p_actor)
	target = p_target

func execute() -> ActionResult:
	Rules.attack(actor, target)
	return ActionResult.new()
