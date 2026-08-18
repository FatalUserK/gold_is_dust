local entity_id = GetUpdatedEntityID()
local x,y = EntityGetTransform(entity_id)
local gen_comp = EntityGetFirstComponent(entity_id, "GenomeDataComponent")
local herd
if gen_comp then herd = ComponentGetValue2(gen_comp, "herd_id") end

local charm_chance = .02
local radius = 400

local function wand_is_valid(wand_entity)
	if wand_entity ~= EntityGetRootEntity(wand_entity) then return false end --dont charm held wands

	for _,c in ipairs(EntityGetAllChildren(wand_entity) or {}) do
		if EntityGetFirstComponentIncludingDisabled(c, "ItemActionComponent") ~= nil then
			return true
		end
	end

	return false
end

SetRandomSeed(GameGetFrameNum() - y, x)
for _,wand in ipairs(EntityGetWithTag("wand")) do
	if wand_is_valid(wand) and Random() <= charm_chance then
		local x,y = EntityGetTransform(wand)
		local ghost = EntityLoad("mods/userk.things/files/wand_whisperer/wand_ghost.xml", x, y)

		local itempickup = EntityGetFirstComponent(ghost, "ItemPickUpperComponent")
		if itempickup then
			ComponentSetValue2(itempickup, "only_pick_this_entity", wand)
			GamePickUpInventoryItem( ghost, wand, false )
		end

		-- check that we hold the item
		local has_item = false
		for _,item in ipairs(GameGetAllInventoryItems(ghost) or {}) do
			if item == wand then
				has_item = true
			end
		end

		-- if we don't have the item kill us for we are too dangerous to be left alive
		if not has_item then
			EntityKill(ghost)
		else
			local w_gen_comp = EntityGetFirstComponent(ghost, "GenomeDataComponent")
			if w_gen_comp then ComponentSetValue2(w_gen_comp, "herd_id", herd or "player") end

			local w_ai_comp = EntityGetFirstComponent(ghost, "AnimalAIComponent")
			if w_ai_comp then
				ComponentSetValue2(w_ai_comp, "mHomePosition", x, y)
			end
		end
	end
end