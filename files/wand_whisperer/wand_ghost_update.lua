local entity_id = GetUpdatedEntityID()

local function kill()
	GameDropAllItems(entity_id) EntityKill(entity_id)
end

local function check()
	local x,y = EntityGetTransform(entity_id)
	if not DoesWorldExistAt(x,y,x,y) then kill() end

	local has_wand
	for _,child in ipairs(EntityGetAllChildren(entity_id) or {}) do
		if EntityGetName(child) == "inventory_quick" and EntityGetAllChildren(child) ~= nil then
			has_wand = true
		end
	end
	if not has_wand then kill() end
end

function kick(kicker)
	check()
	if EntityHasTag(kicker, "player_unit") then
		kill()
	end
end

check()