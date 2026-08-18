local entity_id = GetUpdatedEntityID()

function damage_received(damage, message, attacker, is_fatal, projectile)
	if message == "$damage_kick" then GameDropAllItems(entity_id) EntityKill(entity_id) end
end