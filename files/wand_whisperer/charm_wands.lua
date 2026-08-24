local entity_id = GetUpdatedEntityID()
local x,y = EntityGetTransform(entity_id)
local gen_comp = EntityGetFirstComponent(entity_id, "GenomeDataComponent")
local herd
if gen_comp then herd = ComponentGetValue2(gen_comp, "herd_id") end

local charm_chance = .05
--local radius = 400

local function wand_is_valid(wand_entity)
	local root = EntityGetRootEntity(wand_entity)
	--dont charm wands helled by those with TWWE
	if (wand_entity ~= root and GameGetGameEffectCount(root, "EDIT_WANDS_EVERYWHERE") > 0)
	or EntityHasTag(wand_entity, "dont_charm") then return false end

	for _,varcomp in ipairs(EntityGetComponentIncludingDisabled(wand_entity, "VariableStorageComponent") or {}) do
		if ComponentGetValue2(varcomp, "name") == "userk.wand_whispered" and ComponentGetValue2(varcomp, "value_int") > GameGetFrameNum() then
			return false
		end
	end

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
				ComponentSetValue2(w_ai_comp, "mHomePosition", x, y-10)
			end

			EntityAddComponent2(wand, "VariableStorageComponent", {
				name = "userk.wand_whispered",
				value_int = GameGetFrameNum() + 3*60*60 --3m cd on wand being charmed
			})
		end
	end
end

function kick(kicker)
	if kicker == entity_id then
		local x,y = EntityGetTransform(kicker)
		for _,wand_ghost in ipairs(EntityGetInRadiusWithTag(x, y, 25, "wand_ghost")) do
			GameDropAllItems(wand_ghost)
			EntityInflictDamage(wand_ghost, .04, "DAMAGE_MELEE", "$damage_kick", "NONE", 0, 0, kicker, x, y, 10)
		end
	end
end