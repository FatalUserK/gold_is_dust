dofile_once("mods/userk.things/files/utilities.lua")

local modid = "userk.things"


local perk_replacements = {
	GOLD_IS_FOREVER = { --makes gold decay into special gold dust
		id = "USERK.GOLD_IS_DUST",
		ui_name = "$userk.gold_is_dust.perkname",
		ui_description = "$userk.gold_is_dust.perkdesc",
		perk_icon = "mods/userk.things/files/gold_is_dust/perk.png",
		ui_icon = "mods/userk.things/files/gold_is_dust/icon.png",
		author = "UserK",
		origin = modid,
		stackable = false,
		func = function()
			GameAddFlagRun("userk.gold_is_dust.perk")
		end,
		func_remove = function()
			GameRemoveFlagRun("userk.gold_is_dust.perk")
		end,
	},
	ABILITY_ACTIONS_MATERIALIZED = { --works with most spells now, not just a specific selection of bomb spells
		--id = "USERK.SPELLS_MATERIALISED",
		ui_name = "$userk.spells_materialised.perkname",
		ui_description = "$userk.spells_materialised.perkdesc",
		perk_icon = "mods/userk.things/files/spells_materialised/perk.png",
		ui_icon = "mods/userk.things/files/spells_materialised/icon.png",
	},
	EXTRA_MANA = { --buff mana slightly, change 50% decrease in capacity to flat decrease 1-3 plus 10% of current capacity rounded down
		ui_description = "$userk.extra_mana.perkdesc",
		func = function(perk, taker, perk_name)
			local wand = GetHeldWand(taker)
			if not wand then return end
			local x,y = EntityGetTransform(wand)

			local ability_comp = EntityGetFirstComponentIncludingDisabled(wand, "AbilityComponent")
			if not ability_comp then return end

			local mana_max = ComponentGetValue2(ability_comp, "mana_max")
			local mana_charge = ComponentGetValue2(ability_comp, "mana_charge_speed")
			local full_capacity = ComponentObjectGetValue2(ability_comp, "gun_config", "deck_capacity") --include ACs
			local capacity = EntityGetWandCapacity(wand) --do not include ACs
			local always_cast_count = math.max(0, full_capacity - capacity)

			local perk_x,perk_y =  EntityGetTransform(perk)
			SetRandomSeed(perk_x, perk_y)

			--lesser of (multiply by 1.3-1.5 OR add 100-500) plus random 100-500
			mana_max = math.min(mana_max * Randomf(1.3, 1.5), mana_max + Random(100, 500))   + Random(100, 200)
			mana_max = math.floor(math.min(mana_max, 50000)) --max of 50k

			--lesser of (multiply by 2-3.5 OR add 80-400) plus random 30-60
			mana_charge = math.min(mana_charge * Randomf(2, 3.5), mana_charge + Random(80, 400))   + Random(30, 60)
			mana_charge = math.floor(math.min(mana_charge, 20000)) --max of 20k

			capacity = math.max(capacity - Random(1, 3) - math.floor(capacity*.1), 1) --remove 1-3 AND one more for every 10 slots it has


			ComponentSetValue2(ability_comp, "mana_max", mana_max)
			ComponentSetValue2(ability_comp, "mana_charge_speed", mana_charge)
			ComponentObjectSetValue2(ability_comp, "gun_config", "deck_capacity", capacity + always_cast_count)


			--idk nonsense i stole from the original function
			local c = EntityGetAllChildren(wand)
			if (c ~= nil) and (#c > capacity + always_cast_count) then
				for i=always_cast_count+1,#c do
					local spell = c[i]
					local comp2 = EntityGetFirstComponentIncludingDisabled(spell, "ItemActionComponent")

					if (comp2 ~= nil) and (i > capacity + always_cast_count) then

						EntityRemoveFromParent(spell)
						EntitySetTransform(spell, x, y, 0)

						--fixed tag stuff to properly enabled/disable correct tags (rather than just hard enable all components)
						for _,component in ipairs(EntityGetAllComponents(spell)) do
							if ComponentHasTag(component, "enabled_in_world") then
								EntitySetComponentIsEnabled(spell, component, true)
							else
								EntitySetComponentIsEnabled(spell, component, false)
							end
						end
					end
				end
			end
		end
	},
	EXTRA_SLOTS = { --buffed to make held wand guaranteed plus 2-3 slots (may scrap (actually this kinda is nice qol))
		func = function(perk, taker, perk_name)
			local x, y = EntityGetTransform(perk)
			local held_wand = GetHeldWand(taker)
			for i,entity_id in ipairs(EntityGetInRadiusWithTag(x, y, 24, "wand")) do
				local ability_comp = EntityGetFirstComponentIncludingDisabled(entity_id, "AbilityComponent")
				if ability_comp then
					local full_capacity = tonumber(ComponentObjectGetValue2(ability_comp, "gun_config", "deck_capacity"))
					local capacity = EntityGetWandCapacity(entity_id)
					local always_casts = full_capacity - capacity

					local increase = Random(1,3) --if in inventory, increase by 1-3
					if entity_id == held_wand and increase == 1 then increase = 2 end --if held wand, set min value to 2.
					if EntityGetRootEntity(entity_id) == taker then
						capacity = math.min(capacity + increase, math.max(25, capacity))
						ComponentObjectSetValue2(ability_comp, "gun_config", "deck_capacity", capacity + always_casts)
					end
				end
			end
		end
	},
	MORE_LOVE = {
		id = "USERK.SWITCH_TEAMS",
		ui_name = "$userk.switch_teams.perkname",
		ui_description = "$userk.switch_teams.perkdesc",
		perk_icon = "mods/userk.things/files/switch_teams/perk.png",
		ui_icon = "mods/userk.things/files/switch_teams/icon.png",
		author = "UserK",
		origin = modid,
		stackable = true,
		stackable_is_rare = true,
		func = function(perk, taker, perk_name, count)
			local factions = {
				"slimes",
				"robot",
				"fungus", --not great in vanilla but is with NE or Apotheosis I imagine.
				"orcs",
				"mage",
				"ghost",
			}
			if ModIsEnabled("Apotheosis") then
				table.insert(factions, "ant")
			end
			local gen_comp = EntityGetFirstComponent(taker, "GenomeDataComponent")
			if not gen_comp then return end

			local curr_herd = ComponentGetValue2(gen_comp, "herd_id")
			if curr_herd ~= "player" then
				for i,herd in ipairs(factions) do
					if herd == curr_herd then table.remove(factions, i) break end
				end
			end

			local x,y = EntityGetTransform(perk)
			if not x then x,y = GameGetFrameNum(),count end
			SetRandomSeed(x,y)
			local herd = factions[Random(1, #factions)]
			local decor = "mods/userk.things/files/switch_teams/herd_decor/"..herd..".png"
			decor = ModDoesFileExist(decor) and decor or ""
			GamePrintImportant(
				GameTextGet("$userk.switch_teams.log_title", "$userk.switch_teams.herd."..herd),
				GameTextGet("$userk.switch_teams.log_desc", "$userk.switch_teams.herd."..herd), decor
			)

			ComponentSetValue2(gen_comp, "herd_id", "userk."..herd)
			GlobalsSetValue("userk.player_faction", "userk."..herd)
			GameAddFlagRun("userk.player_faction_changed")
			for _,eid in ipairs(EntityGetInRadius(0, 0, math.huge)) do
				local e_gen_comp = EntityGetFirstComponentIncludingDisabled(eid, "GenomeDataComponent")
				if e_gen_comp then
					local faction_changed
					for _,varcomp in ipairs(EntityGetComponent(eid, "VariableStorageComponent") or {}) do
						if ComponentGetValue2(varcomp, "name") == "userk.changed_faction" then
							ComponentSetValue2(e_gen_comp, "herd_id", "userk."..herd)
							faction_changed = true
						end
					end
					if not faction_changed and ComponentGetValue2(e_gen_comp, "herd_id") == "player" then
						EntityAddComponent2(eid, "VariableStorageComponent", {
							name = "userk.changed_faction"
						})
					end
				end
			end
		end,
		func_remove = function(holder)
			local gen_comp = EntityGetFirstComponent(holder, "GenomeDataComponent")
			if not gen_comp then return end
			ComponentSetValue2(gen_comp, "herd_id", "player")
			GlobalsSetValue("userk.player_faction", "player")
		end,
	},
}

local new_perks = {
	{
		id = "USERK.WAND_WHISPERER",
		ui_name = "$userk.wand_whisperer.perkname",
		ui_description = "$userk.wand_whisperer.perkdesc",
		perk_icon = "mods/userk.things/files/wand_whisperer/perk.png",
		ui_icon = "mods/userk.things/files/wand_whisperer/icon.png",
		author = "UserK",
		origin = modid,
		remove_other_perks = {"EDIT_WANDS_EVERYWHERE"},
		game_effect = "EDIT_WANDS_EVERYWHERE",
		stackable = false,
		func = function(perk, taker, perk_name)
			EntityAddComponent2(taker, "LuaComponent", {
				script_source_file = "mods/userk.things/files/wand_whisperer/charm_wands.lua",
				execute_every_n_frame = 80,
			})
		end,
		func_remove = function(perk_holder)
			for _,luacomp in ipairs(EntityGetComponent(perk_holder, "LuaComponent") or {}) do
				if ComponentGetValue2(luacomp, "script_source_file") == "mods/userk.things/files/wand_whisperer/charm_wands.lua" then
					EntityRemoveComponent(perk_holder, luacomp) return
				end
			end
		end,
	},
}

---@diagnostic disable-next-line:lowercase-global
perk_list = perk_list

for index, perk in ipairs(perk_list) do
	if perk_replacements[perk.id] and not perk_replacements[perk.id]._disabled	 then
		for k,v in pairs(perk_replacements[perk.id]) do
			perk_list[index][k] = v
		end
	end
end

for _,perk in ipairs(new_perks) do
	table.insert(perk_list, perk)
end