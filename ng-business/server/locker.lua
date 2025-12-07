-- ============================================
-- SERVER LOCKER - ng-business
-- ============================================

-- Create locker
RegisterNetEvent('ng-business:server:createLocker', function(data)
    local source = source
    
    if not IsPlayerAceAllowed(source, 'command.admin') then
        ErrorPrint('Player', source, 'attempted to create locker without permission')
        return
    end
    
    DebugPrint('Creating locker:', data.locker_id)
    
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    -- Check if locker already exists
    local existing = MySQL.scalar.await('SELECT id FROM business_lockers WHERE locker_id = ?', {data.locker_id})
    if existing then
        TriggerClientEvent('okokNotify:Alert', source, 'Error', 'Locker ID already exists', 5000, 'error', true)
        ErrorPrint('Locker ID already exists:', data.locker_id)
        return
    end
    
    -- Insert into database
    local insertId = MySQL.insert.await([[
        INSERT INTO business_lockers (locker_id, label, coords, slots, weight, jobs, min_grade, personal, blip_enabled, blip_sprite, blip_color, blip_scale, created_by)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        data.locker_id,
        data.label,
        json.encode(data.coords),
        data.slots,
        data.weight,
        json.encode(data.jobs),
        data.min_grade,
        data.personal and 1 or 0,
        data.blip_enabled and 1 or 0,
        data.blip_sprite,
        data.blip_color,
        data.blip_scale,
        Player.PlayerData.citizenid
    })
    
    if insertId then
        -- Add to BusinessData
        BusinessData.lockers[data.locker_id] = {
            id = data.locker_id,
            label = data.label,
            coords = vector3(data.coords.x, data.coords.y, data.coords.z),
            slots = data.slots,
            weight = data.weight,
            jobs = data.jobs,
            minGrade = data.min_grade,
            personal = data.personal,
            blip = {
                enabled = data.blip_enabled,
                sprite = data.blip_sprite,
                color = data.blip_color,
                scale = data.blip_scale
            }
        }
        
        -- Notify all clients
        TriggerClientEvent('ng-business:client:updateLockers', -1, BusinessData.lockers)
        TriggerClientEvent('okokNotify:Alert', source, 'Success', 'Locker created successfully', 5000, 'success', true)
        SuccessPrint('Locker created:', data.locker_id, 'by', Player.PlayerData.citizenid)
    else
        TriggerClientEvent('okokNotify:Alert', source, 'Error', 'Failed to create locker', 5000, 'error', true)
        ErrorPrint('Failed to create locker:', data.locker_id)
    end
end)

-- Open locker
RegisterNetEvent('ng-business:server:openLocker', function(lockerId)
    local source = source
    local locker = BusinessData.lockers[lockerId]
    
    if not locker then
        ErrorPrint('Locker not found:', lockerId)
        return
    end
    
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local stashId = lockerId
    
    -- If personal locker, append player identifier
    if locker.personal then
        stashId = lockerId .. '_' .. Player.PlayerData.citizenid
    end
    
    DebugPrint('Player', source, 'opening locker:', stashId)
    
    -- Register locker if not already registered
    exports.ox_inventory:RegisterStash(stashId, locker.label, locker.slots, locker.weight, locker.personal and Player.PlayerData.citizenid or false)
    
    -- Open locker for player
    exports.ox_inventory:forceOpenInventory(source, 'stash', stashId)
end)

-- Delete locker
RegisterNetEvent('ng-business:server:deleteLocker', function(lockerId)
    local source = source
    
    if not IsPlayerAceAllowed(source, 'command.admin') then
        ErrorPrint('Player', source, 'attempted to delete locker without permission')
        return
    end
    
    DebugPrint('Deleting locker:', lockerId)
    
    local affectedRows = MySQL.update.await('DELETE FROM business_lockers WHERE locker_id = ?', {lockerId})
    
    if affectedRows > 0 then
        BusinessData.lockers[lockerId] = nil
        TriggerClientEvent('ng-business:client:updateLockers', -1, BusinessData.lockers)
        TriggerClientEvent('okokNotify:Alert', source, 'Success', 'Locker deleted successfully', 5000, 'success', true)
        SuccessPrint('Locker deleted:', lockerId)
    else
        TriggerClientEvent('okokNotify:Alert', source, 'Error', 'Failed to delete locker', 5000, 'error', true)
        ErrorPrint('Failed to delete locker:', lockerId)
    end
end)

DebugPrint('Locker module loaded')
