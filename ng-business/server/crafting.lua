-- ============================================
-- SERVER CRAFTING - ng-business
-- ============================================

-- Create crafting station
RegisterNetEvent('ng-business:server:createCrafting', function(data)
    local source = source
    
    if not IsPlayerAceAllowed(source, 'command.admin') then
        ErrorPrint('Player', source, 'attempted to create crafting station without permission')
        return
    end
    
    DebugPrint('Creating crafting station:', data.crafting_id)
    
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    -- Check if crafting station already exists
    local existing = MySQL.scalar.await('SELECT id FROM business_crafting WHERE crafting_id = ?', {data.crafting_id})
    if existing then
        TriggerClientEvent('okokNotify:Alert', source, 'Error', 'Crafting ID already exists', 5000, 'error', true)
        ErrorPrint('Crafting ID already exists:', data.crafting_id)
        return
    end
    
    -- Insert into database
    local insertId = MySQL.insert.await([[
        INSERT INTO business_crafting (crafting_id, label, coords, jobs, min_grade, recipes, blip_enabled, blip_sprite, blip_color, blip_scale, created_by)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        data.crafting_id,
        data.label,
        json.encode(data.coords),
        json.encode(data.jobs),
        data.min_grade,
        json.encode(data.recipes),
        data.blip_enabled and 1 or 0,
        data.blip_sprite,
        data.blip_color,
        data.blip_scale,
        Player.PlayerData.citizenid
    })
    
    if insertId then
        -- Add to BusinessData
        BusinessData.crafting[data.crafting_id] = {
            id = data.crafting_id,
            label = data.label,
            coords = vector3(data.coords.x, data.coords.y, data.coords.z),
            jobs = data.jobs,
            minGrade = data.min_grade,
            recipes = data.recipes,
            blip = {
                enabled = data.blip_enabled,
                sprite = data.blip_sprite,
                color = data.blip_color,
                scale = data.blip_scale
            }
        }
        
        -- Notify all clients
        TriggerClientEvent('ng-business:client:updateCrafting', -1, BusinessData.crafting)
        TriggerClientEvent('okokNotify:Alert', source, 'Success', 'Crafting station created successfully', 5000, 'success', true)
        SuccessPrint('Crafting station created:', data.crafting_id, 'by', Player.PlayerData.citizenid)
    else
        TriggerClientEvent('okokNotify:Alert', source, 'Error', 'Failed to create crafting station', 5000, 'error', true)
        ErrorPrint('Failed to create crafting station:', data.crafting_id)
    end
end)

-- Craft item
RegisterNetEvent('ng-business:server:craftItem', function(stationId, itemName)
    local source = source
    local station = BusinessData.crafting[stationId]
    
    if not station then
        ErrorPrint('Crafting station not found:', stationId)
        return
    end
    
    -- Find recipe
    local recipe = nil
    for _, r in ipairs(station.recipes) do
        if r.item == itemName then
            recipe = r
            break
        end
    end
    
    if not recipe then
        TriggerClientEvent('okokNotify:Alert', source, 'Error', 'Recipe not found', 5000, 'error', true)
        ErrorPrint('Recipe not found:', itemName)
        return
    end
    
    DebugPrint('Player', source, 'attempting to craft:', itemName)
    
    -- Check ingredients
    local hasAllIngredients = true
    for _, ingredient in ipairs(recipe.ingredients) do
        local count = exports.ox_inventory:GetItemCount(source, ingredient.item)
        if count < ingredient.amount then
            hasAllIngredients = false
            TriggerClientEvent('okokNotify:Alert', source, 'Error', 'Missing ingredient: ' .. ingredient.item, 5000, 'error', true)
            DebugPrint('Player', source, 'missing ingredient:', ingredient.item)
            break
        end
    end
    
    if not hasAllIngredients then return end
    
    -- Check if player can carry the item
    if not exports.ox_inventory:CanCarryItem(source, recipe.item, recipe.amount) then
        TriggerClientEvent('okokNotify:Alert', source, 'Error', 'Inventory full', 5000, 'error', true)
        DebugPrint('Player', source, 'inventory full')
        return
    end
    
    -- Start crafting progress
    TriggerClientEvent('ng-business:client:startCrafting', source, recipe.craftTime, recipe.label)
    
    -- Wait for crafting to complete
    SetTimeout(recipe.craftTime, function()
        -- Remove ingredients
        for _, ingredient in ipairs(recipe.ingredients) do
            local success = exports.ox_inventory:RemoveItem(source, ingredient.item, ingredient.amount)
            if not success then
                TriggerClientEvent('okokNotify:Alert', source, 'Error', 'Failed to remove ingredient', 5000, 'error', true)
                ErrorPrint('Failed to remove ingredient:', ingredient.item, 'from player', source)
                return
            end
        end
        
        -- Add crafted item
        local success = exports.ox_inventory:AddItem(source, recipe.item, recipe.amount)
        if success then
            TriggerClientEvent('okokNotify:Alert', source, 'Success', 'Crafted ' .. recipe.label, 5000, 'success', true)
            SuccessPrint('Player', source, 'crafted:', recipe.item)
        else
            TriggerClientEvent('okokNotify:Alert', source, 'Error', 'Failed to craft item', 5000, 'error', true)
            ErrorPrint('Failed to add crafted item:', recipe.item, 'to player', source)
        end
    end)
end)

-- Delete crafting station
RegisterNetEvent('ng-business:server:deleteCrafting', function(craftingId)
    local source = source
    
    if not IsPlayerAceAllowed(source, 'command.admin') then
        ErrorPrint('Player', source, 'attempted to delete crafting station without permission')
        return
    end
    
    DebugPrint('Deleting crafting station:', craftingId)
    
    local affectedRows = MySQL.update.await('DELETE FROM business_crafting WHERE crafting_id = ?', {craftingId})
    
    if affectedRows > 0 then
        BusinessData.crafting[craftingId] = nil
        TriggerClientEvent('ng-business:client:updateCrafting', -1, BusinessData.crafting)
        TriggerClientEvent('okokNotify:Alert', source, 'Success', 'Crafting station deleted successfully', 5000, 'success', true)
        SuccessPrint('Crafting station deleted:', craftingId)
    else
        TriggerClientEvent('okokNotify:Alert', source, 'Error', 'Failed to delete crafting station', 5000, 'error', true)
        ErrorPrint('Failed to delete crafting station:', craftingId)
    end
end)

DebugPrint('Crafting module loaded')
