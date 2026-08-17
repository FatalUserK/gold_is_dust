local entity_id = GetUpdatedEntityID()

for _,comp in ipairs(EntityGetComponent(entity_id, "InventoryGuiComponent") or{}) do
    ComponentSetValue2(comp, "mActive", false)
end

for _,child in ipairs(EntityGetAllChildren(entity_id) or {}) do
    local name = EntityGetName(child)
    if name == "inventory_quick" or name == "inventory_full" then
        if #(EntityGetAllChildren(child) or {}) == 0 then EntityKill(child) end
    end
end