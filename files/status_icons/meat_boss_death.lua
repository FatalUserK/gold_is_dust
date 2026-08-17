function death(damage_type, message, attacker, drop_items)
	for _,e in ipairs(EntityGetWithTag("no_heal_in_meat_biome")) do
		for _,ui_icon_comp in ipairs(EntityGetComponent(e, "UIIconComponent") or {}) do
			if ComponentGetValue2(ui_icon_comp, "name") == "$userk.statusname.meat_curse" then
				EntityRemoveComponent(e, ui_icon_comp)
				return
			end
		end
	end
end