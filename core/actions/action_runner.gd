class_name ActionRunner
extends RefCounted

static func run(action: Action) -> ActionResult:
	if not Authority.can_perform(action):
		return ActionResult.new(false)
	return action.execute()
