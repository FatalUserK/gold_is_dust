local e = GetUpdatedEntityID()

function biome_entered( new_biome_name, old_biome_name )
	if new_biome_name == "$biome_meat" and GlobalsGetValue("BOSS_MEAT_DEAD", "0") == "0" then
		if EntityGetFirstComponent(e, "UIIconComponent") then return end

		EntityAddComponent2(e, "UIIconComponent", {
			name = "$userk.statusname.meat_curse",
			description = "$userk.statusdesc.meat_curse",
			icon_sprite_file = "mods/userk.things/files/status_icons/icons/antiheal.png",
			is_perk = true
		})
	else
		for _,ui_icon_comp in ipairs(EntityGetComponent(e, "UIIconComponent") or {}) do
			if ComponentGetValue2(ui_icon_comp, "name") == "$userk.statusname.meat_curse" then
				EntityRemoveComponent(e, ui_icon_comp)
				return
			end
		end
	end
end