-- ============================================
-- SERVER STASH - ng-business
-- ============================================

-- Create stash
RegisterNetEvent('ng-business:server:createStash', function(data)
    local source = source
    
    if not IsPlayerAceAllowed(source, 'command.admin') then
        ErrorPrint('Player', source, 'attempted to create stash without permission')
        return
    end
    
    DebugPrint('Creating stash:', data.stash_id)
    
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    -- Check if stash already exists
    local existing = MySQL.scalar.await('SELECT id FROM business_stashes WHERE stash_id = ?', {data.stash_id})
    if existing then
        TriggerClientEvent('okokNotify:Alert', source, 'Error', 'Stash ID already exists', 5000, 'error', true)
        ErrorPrint('Stash ID already exists:', data.stash_id)
        return
    end
    
    -- Insert into database
    local insertId = MySQL.insert.await([[
        INSERT INTO business_stashes (stash_id, label, coords, slots, weight, jobs, min_grade, blip_enabled, blip_sprite, blip_color, blip_scale, created_by)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        data.stash_id,
        data.label,
        json.encode(data.coords),
        data.slots,
        data.weight,
        json.encode(data.jobs),
        data.min_grade,
        data.blip_enabled and 1 or 0,
        data.blip_sprite,
        data.blip_color,
        data.blip_scale,
        Player.PlayerData.citizenid
    })
    
    if insertId then
        -- Add to BusinessData
        BusinessData.stashes[data.stash_id] = {
            id = data.stash_id,
            label = data.label,
            coords = vector3(data.coords.x, data.coords.y, data.coords.z),
            slots = data.slots,
            weight = data.weight,
            jobs = data.jobs,
            minGrade = data.min_grade,
            blip = {
                enabled = data.blip_enabled,
                sprite = data.blip_sprite,
                color = data.blip_color,
                scale = data.blip_scale
            }
        }
        
        -- Register stash with ox_inventory
        exports.ox_inventory:RegisterStash(data.stash_id, data.label, data.slots, data.weight, false)
        
        -- Notify all clients
        TriggerClientEvent('ng-business:client:updateStashes', -1, BusinessData.stashes)
        TriggerClientEvent('okokNotify:Alert', source, 'Success', 'Stash created successfully', 5000, 'success', true)
        SuccessPrint('Stash created:', data.stash_id, 'by', Player.PlayerData.citizenid)
    else
        TriggerClientEvent('okokNotify:Alert', source, 'Error', 'Failed to create stash', 5000, 'error', true)
        ErrorPrint('Failed to create stash:', data.stash_id)
    end
end)

-- Open stash
RegisterNetEvent('ng-business:server:openStash', function(stashId)
    local source = source
    local stash = BusinessData.stashes[stashId]
    
    if not stash then
        ErrorPrint('Stash not found:', stashId)
        return
    end
    
    DebugPrint('Player', source, 'opening stash:', stashId)
    
    -- Register stash if not already registered
    exports.ox_inventory:RegisterStash(stashId, stash.label, stash.slots, stash.weight, false)
    
    -- Open stash for player
    exports.ox_inventory:forceOpenInventory(source, 'stash', stashId)
end)

-- Delete stash
RegisterNetEvent('ng-business:server:deleteStash', function(stashId)
    local source = source
    
    if not IsPlayerAceAllowed(source, 'command.admin') then
        ErrorPrint('Player', source, 'attempted to delete stash without permission')
        return
    end
    
    DebugPrint('Deleting stash:', stashId)
    
    local affectedRows = MySQL.update.await('DELETE FROM business_stashes WHERE stash_id = ?', {stashId})
    
    if affectedRows > 0 then
        BusinessData.stashes[stashId] = nil
        TriggerClientEvent('ng-business:client:updateStashes', -1, BusinessData.stashes)
        TriggerClientEvent('okokNotify:Alert', source, 'Success', 'Stash deleted successfully', 5000, 'success', true)
        SuccessPrint('Stash deleted:', stashId)
    else
        TriggerClientEvent('okokNotify:Alert', source, 'Error', 'Failed to delete stash', 5000, 'error', true)
        ErrorPrint('Failed to delete stash:', stashId)
    end
end)

DebugPrint('Stash module loaded')
