class_name Authority
extends RefCounted

# Trivial today: no networking exists yet, so every Action is authorized.
# This is the seam the LAN dedicated-server work will give real teeth to,
# checking the requesting peer against the target Actor's owner_id.
static func can_perform(_action: Action) -> bool:
	return true
