local nxml = dofile_once("mods/userk.things/luanxml/nxml.lua") ---@type nxml

local settings = dofile_once("mods/userk.things/config.lua")


local translations = ModTextFileGetContent("data/translations/common.csv")
translations = translations .. "\n" .. ModTextFileGetContent("mods/userk.things/files/standard.csv") .. "\n"
translations = translations:gsub("\r", ""):gsub("\n\n+", "\n")
ModTextFileSetContent("data/translations/common.csv", translations)

ModLuaFileAppend("data/scripts/perks/perk_list.lua", "mods/userk.things/files/perks_append.lua")
ModMagicNumbersFileAdd("mods/userk.things/files/magic_numbers.xml")


local hooks = {
	player_spawned = {},
	new_eid = {},
	player_changed = {},
	player_destroyed = {},
	pre_update = {},
	post_update = {},
}

local player
local player_poly_identity
function OnPlayerSpawned(p)
	player = p
	for _,func in ipairs(hooks.player_spawned) do
		func(p)
	end
end


local prev_max_eid = -1
local max_eid = -1
local check_entities = function()
	local old_player = player
	if not EntityGetIsAlive(player) then
		max_eid = prev_max_eid --rollback in case EntityGetIsAlive was outdated by 1 frame
		player = nil
	end

	local new_max = EntitiesGetMaxID()
	for i = max_eid + 1, new_max do
		if not player then
			if EntityHasTag(i, "player_unit") then
				player = i
				player_poly_identity = nil
			else
				for _,comp in ipairs(EntityGetComponent(i, "GameStatsComponent") or {}) do
					if ComponentGetTypeName(comp) == "GameStatsComponent" and ComponentGetValue2(comp, "is_player") then
						player = i
						player_poly_identity = {
							path = EntityGetFilename(i),
							name = ComponentGetValue2(comp, "name")
						}
						goto continue
					end
				end
			end
			::continue::
		end
		for _,func in ipairs(hooks.new_eid) do
			local varcomp_tree = {}
			for _,varcomp in ipairs(EntityGetComponent(i, "VariableStorageComponent") or {}) do
				local name = ComponentGetValue2(varcomp, "name")
				varcomp_tree[name] = varcomp_tree[name] or {}
				varcomp_tree[name][#varcomp_tree[name]+1] = varcomp
			end
			func(i, varcomp_tree)
		end
	end
	prev_max_eid = max_eid --we store prev max eid in case a rollback is necessary due to frame delay nonsense
	max_eid = new_max

	if old_player ~= player then
		if player ~= nil then
			for _,func in ipairs(hooks.player_changed) do
				func(player_poly_identity)
			end
		else
			for _,func in ipairs(hooks.player_destroyed) do
				func()
			end
		end
	end
end

local frame = 0
function OnWorldPreUpdate()
	frame = GameGetFrameNum()
	check_entities()

	for _,func in ipairs(hooks.pre_update) do
		func(frame)
	end
end
function OnWorldPostUpdate()
	--check_entities() --this seems to cause issues?

	for _,func in ipairs(hooks.post_update) do
		func(frame)
	end
end



if settings.spells_materialised then
	local spell_card_append_targets = {
		["data/entities/misc/custom_cards/action.xml"] = true,
		["data/entities/base_custom_card.xml"] = true,
	}

	dofile_once("data/scripts/gun/gun_actions.lua")
	---@diagnostic disable-next-line:undefined-global
	for _,action in pairs(actions) do
		if action.custom_xml_file then
			spell_card_append_targets[action.custom_xml_file] = true
		end
	end

	for path,_ in pairs(spell_card_append_targets) do
		for xml in nxml.edit_file(path) do
			if xml:first_of("AbilityComponent") then break end

			xml:add_child(nxml.new_element("LuaComponent", {
				_tags = "enabled_in_world,enabled_in_inventory,enabled_in_world",
				script_source_file = "mods/userk.things/files/spells_materialised/spell_append.lua",
				remove_after_executed = "1"
			}))
		end
	end

	for xml in nxml.edit_file("data/entities/player_base.xml") do
		for child in xml:each_of("Entity") do
			if child.attr.name == "arm_r" then
				child:add_child(nxml.new_element("LuaComponent", {
					script_shot = "mods/userk.things/files/spells_materialised/shoot_spell.lua"
				}))
			end
		end
	end
end



if settings.gold_is_dust then
	ModMaterialsFileAdd("mods/userk.things/files/materials/materials.xml")
	--if ModSettingGet("GID.vanilla_bloody then") then ModMaterialsFileAdd("mods/userk.things/files/materials/materials_extra_bloody.xml") end

	if ModIsEnabled("prospector-perk") then
		ModLuaFileAppend("mods/prospector-perk/files/perk/prospector.lua", "mods/userk.things/files/gold_is_dust/append_prospector.lua")
	end

	local list_of_nuggets = {
		"data/entities/items/pickup/goldnugget.xml",
		"data/entities/items/pickup/goldnugget_10.xml",
		"data/entities/items/pickup/goldnugget_50.xml",
		"data/entities/items/pickup/goldnugget_200.xml",
		"data/entities/items/pickup/goldnugget_1000.xml",
		"data/entities/items/pickup/goldnugget_10000.xml",
		"data/entities/items/pickup/goldnugget_200000.xml",
		"data/entities/items/pickup/goldnugget_x.xml",
	}

	local luacomp = nxml.new_element("LuaComponent", {
		script_source_file = "mods/userk.things/files/gold_is_dust/nugget_expire.lua",
		script_item_picked_up = "mods/userk.things/files/gold_is_dust/nugget_pickup.lua",
		execute_every_n_frame = "-1",
		execute_on_removed = "1"
	})

	for _, path in ipairs(list_of_nuggets) do
		for xml in nxml.edit_file(path) do xml:add_child(luacomp) end
	end


	for xml in nxml.edit_file("data/entities/player_base.xml") do
		xml:add_child(nxml.new_element("Entity", {name="userk.gold_collect"}, {
			nxml.new_element("InheritTransformComponent", {}, {
				nxml.new_element("Transform", {
					["position.y"]="6"
				})
			}),
			nxml.new_element("MaterialSuckerComponent", {
				material_type = "1",
				suck_tag = "[userk.gold]",
				barrel_size="100",
				num_cells_sucked_per_frame="50",
				["randomized_position.min_x"]="-5",
				["randomized_position.max_x"]="5",
				["randomized_position.min_y"]="-4",
				["randomized_position.max_y"]="-1",
			}),
			nxml.new_element("MaterialInventoryComponent"),
			nxml.new_element("LuaComponent", {
				script_source_file="mods/userk.things/files/gold_is_dust/collect_gold.lua"
			})
		}))
	end
end



if settings.status_icons then
	local ven_curse = {
		name = "$damage_hitfx_curse",
		description = "$userk.statusdesc.venomous_curse",
		icon_sprite_file = "mods/userk.things/files/status_icons/icons/venomous_curse.png",
		is_perk = "0"
	}

	local targets = {
		--THROWERS
		{
			path = "data/entities/misc/fireball_ray_enemy.xml",
			attr = {
				name = "$userk.statusname.fireball_thrower",
				description = "$userk.statusdesc.fireball_thrower",
				icon_sprite_file = "data/ui_gfx/status_indicators/fireball_ray.png",
				--display_above_head = 0, --defaults
				--display_in_hud = 1,
				is_perk = "0"
			}
		},
		{
			path = "data/entities/misc/lightning_ray_enemy.xml",
			attr = {
				name = "$userk.statusname.lightning_thrower",
				description = "$userk.statusdesc.lightning_thrower",
				icon_sprite_file = "mods/userk.things/files/status_icons/icons/lightning_thrower.png",
				is_perk = "0"
			}
		},
		{
			path = "data/entities/misc/tentacle_ray_enemy.xml",
			attr = {
				name = "$action_tentacle_ray",
				description = "$userk.statusdesc.tentacler",
				icon_sprite_file = "mods/userk.things/files/status_icons/icons/tentacler.png",
				is_perk = "0"
			}
		},

		--EXISTING STATUS EFFECTS
		{
			path = "data/entities/misc/effect_apply_wet.xml",
			attr = {
				name = "$status_wet",
				description = "$statusdesc_wet",
				icon_sprite_file = "data/ui_gfx/status_indicators/wet.png",
				display_above_head = "1",
				is_perk = "0"
			}
		},
		{
			path = "data/entities/misc/effect_apply_oiled.xml",
			attr = {
				name = "$status_oiled",
				description = "$statusdesc_oiled",
				icon_sprite_file = "data/ui_gfx/status_indicators/oiled.png",
				display_above_head = "1",
				is_perk = 0
			}
		},
		{
			path = "data/entities/misc/effect_apply_bloody.xml",
			attr = {
				name = "$status_bloody",
				description = "$statusdesc_bloody",
				icon_sprite_file = "data/ui_gfx/status_indicators/bloody.png",
				display_above_head = "1",
				is_perk = 0
			}
		},
		{
			path = "data/entities/misc/effect_apply_poison.xml",
			attr = {
				name = "$status_poisoned",
				description = "$statusdesc_poisoned",
				icon_sprite_file = "data/ui_gfx/status_indicators/poisoned.png",
				display_above_head = "1",
				is_perk = 0
			}
		},
		{
			path = "data/entities/misc/effect_apply_on_fire.xml",
			attr = {
				name = "$status_on_fire",
				description = "$statusdesc_on_fire",
				icon_sprite_file = "data/ui_gfx/status_indicators/on_fire.png",
				display_above_head = "1",
				is_perk = 0
			}
		},
		{
			path = "data/entities/misc/effect_charm_short.xml",
			attr = {
				name = "$status_charm",
				description = "$statusdesc_charm",
				icon_sprite_file = "data/ui_gfx/status_indicators/charm.png",
				display_above_head = "1",
				is_perk = 0
			}
		},

		--VENOMOUS CURSE
		{
			path = "data/entities/misc/curse_init.xml",
			attr = ven_curse
		},
		{
			path = "data/entities/misc/curse_strong_init.xml",
			attr = ven_curse
		},
		{
			path = "data/entities/misc/curse_stronger_init.xml",
			attr = ven_curse
		},

		--MISC
		{
			path = "data/entities/misc/effect_necromancy.xml",
			attr = {
				name = "$userk.statusname.necromancy",
				description = "$userk.statusdesc.necromancy",
				icon_sprite_file = "mods/userk.things/files/status_icons/icons/necromancy.png",
				is_perk = "0"
			}
		},
		{
			path = "data/entities/misc/gravity_field_enemy.xml",
			attr = {
				name = "$userk.statusname.gravity_field",
				description = "$userk.statusdesc.gravity_field",
				icon_sprite_file = "data/ui_gfx/status_indicators/gravity_field.png",
				is_perk = "0"
			}
		},
	}

	for _,target in ipairs(targets) do
		for xml in nxml.edit_file(target.path) do
			if not xml:first_of("UIIconComponent") then
				xml:add_child(nxml.new_element("UIIconComponent", target.attr))
			end
		end
	end


	--these have `is_perk="1"` which disables the timer, removes it.
	local not_perk_targets = {
		"data/entities/misc/curse_wither_projectile.xml",
		"data/entities/misc/curse_wither_explosion.xml",
		"data/entities/misc/curse_wither_melee.xml",
		"data/entities/misc/curse_wither_electricity.xml",
	}

	for _,target in ipairs(not_perk_targets) do
		for xml in nxml.edit_file(target) do
			local ui_icon_comp = xml:first_of("UIIconComponent")
			if ui_icon_comp then
				ui_icon_comp.attr.is_perk = "0"
			end
		end
	end


	if settings.meat_curse_status then --Antiheal status for meat curse
		for xml in nxml.edit_file("data/entities/misc/effect_no_heal_in_meat_biome.xml") do
			xml:add_child(nxml.new_element("LuaComponent", {
				script_biome_entered = "mods/userk.things/files/status_icons/meat_realm_curse.lua"
			}))
		end

		for xml in nxml.edit_file("data/entities/animals/boss_meat/boss_meat.xml") do
			xml:add_child(nxml.new_element("LuaComponent", {
				script_death = "mods/userk.things/files/status_icons/meat_boss_death.lua"
			}))
		end
	end
end



if settings.polymorph_gui then
	hooks.player_changed[#hooks.player_changed+1] = function(poly_data)
		if poly_data and not EntityGetFirstComponentIncludingDisabled(player, "InventoryGuiComponent") then
			EntityAddComponent2(player, "InventoryGuiComponent")
			EntityAddComponent2(player, "LuaComponent", {
				script_source_file = "mods/userk.things/files/misc/polymorphed_player.lua"
			})
		end
	end

	hooks.player_changed[#hooks.player_changed+1] = function(poly_data)
		if not poly_data then return end

		local polymorphs = {
			POLYMORPH = {
				icon = "mods/userk.things/files/status_icons/icons/polymorphed.png",
				name = "$userk.statusname.polymorph",
				desc = "$userk.statusdesc.polymorph",
			},
			POLYMORPH_RANDOM = {
				icon = "mods/userk.things/files/status_icons/icons/chaotic_polymorphed.png",
				name = "$userk.statusname.chaotic_polymorph",
				desc = "$userk.statusdesc.chaotic_polymorph",
			},
			POLYMORPH_UNSTABLE = {
				icon = "mods/userk.things/files/status_icons/icons/chaotic_polymorphed.png",
				name = "$userk.statusname.unstable_polymorph",
				desc = "$userk.statusdesc.unstable_polymorph",
			},
		}

		if settings.cessation_status then
			polymorphs.POLYMORPH_CESSATION = {
				icon = "mods/userk.things/files/status_icons/icons/cessated.png",
				name = "$userk.statusname.cessated",
				desc = "$userk.statusdesc.cessated",
			}
		end

		local rare_polymorph = {
			icon = "mods/userk.things/files/status_icons/icons/rare_chaotic_polymorphed.png",
			name = "$userk.statusname.rare_polymorph",
			desc = "$userk.statusdesc.rare_polymorph",
		}

		for _,value in pairs(PolymorphTableGet(true)) do
			if poly_data.path == value then polymorphs.POLYMORPH_RANDOM = rare_polymorph break end
		end --If an entity is in both pools, this will still be matched, I will presume this won't happen.

		for game_effect,data in pairs(polymorphs) do
			local ge_comp = GameGetGameEffect(player, game_effect)
			if ge_comp ~= 0 then
				local ge_entity = ComponentGetEntity(ge_comp)
				local is_perk = false
				if ComponentGetValue2(ge_comp, "frames") < 0 then is_perk = true end
				EntityAddComponent2(ge_entity, "UIIconComponent", {
					icon_sprite_file = data.icon,
					name = data.name,
					description = data.desc,
					is_perk = is_perk
				})
			end
		end
	end
end


if settings.switch_teams then
	hooks.new_eid[#hooks.new_eid+1] = function(entity_id, varcomps)
		if not GameHasFlagRun("userk.player_faction_changed") then return end
		local gen_comp = EntityGetFirstComponent(entity_id, "GenomeDataComponent")
		if not gen_comp then return end
		local current_player_faction = GlobalsGetValue("userk.player_faction") or "player"

		if varcomps["userk.changed_faction"] then
			ComponentSetValue2(gen_comp, "herd_id", current_player_faction)
		elseif current_player_faction ~= "player" and ComponentGetValue2(gen_comp, "herd_id") == "player" then
			ComponentSetValue2(gen_comp, "herd_id", current_player_faction)
			EntityAddComponent2(entity_id, "VariableStorageComponent", {
				name = "userk.changed_faction"
			})
		end
	end
end


--Accept your punishment. All of you.
--To create our gifts is sacrilege, no matter how furiously you forged away at the wettest waters.
--The hottest fires, the strongest stones, the most electrified matter.
--Consider this home turned forsaken tomb your warning to never try stealing our gifts again
--Lest you seek further punishment..