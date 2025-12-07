-- ============================================
-- SERVER TRAY - ng-business
-- ============================================

-- Create tray
RegisterNetEvent('ng-business:server:createTray', function(data)
    local source = source
    
    if not IsPlayerAceAllowed(source, 'command.admin') then
        ErrorPrint('Player', source, 'attempted to create tray without permission')
        return
    end
    
    DebugPrint('Creating tray:', data.tray_id)
    
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    -- Check if tray already exists
    local existing = MySQL.scalar.await('SELECT id FROM business_trays WHERE tray_id = ?', {data.tray_id})
    if existing then
        TriggerClientEvent('okokNotify:Alert', source, 'Error', 'Tray ID already exists', 5000, 'error', true)
        ErrorPrint('Tray ID already exists:', data.tray_id)
        return
    end
    
    -- Insert into database
    local insertId = MySQL.insert.await([[
        INSERT INTO business_trays (tray_id, label, coords, slots, weight, jobs, min_grade, blip_enabled, blip_sprite, blip_color, blip_scale, created_by)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        data.tray_id,
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
        BusinessData.trays[data.tray_id] = {
            id = data.tray_id,
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
        
        -- Register tray with ox_inventory
        exports.ox_inventory:RegisterStash(data.tray_id, data.label, data.slots, data.weight, false)
        
        -- Notify all clients
        TriggerClientEvent('ng-business:client:updateTrays', -1, BusinessData.trays)
        TriggerClientEvent('okokNotify:Alert', source, 'Success', 'Tray created successfully', 5000, 'success', true)
        SuccessPrint('Tray created:', data.tray_id, 'by', Player.PlayerData.citizenid)
    else
        TriggerClientEvent('okokNotify:Alert', source, 'Error', 'Failed to create tray', 5000, 'error', true)
        ErrorPrint('Failed to create tray:', data.tray_id)
    end
end)

-- Open tray
RegisterNetEvent('ng-business:server:openTray', function(trayId)
    local source = source
    local tray = BusinessData.trays[trayId]
    
    if not tray then
        ErrorPrint('Tray not found:', trayId)
        return
    end
    
    DebugPrint('Player', source, 'opening tray:', trayId)
    
    -- Register tray if not already registered
    exports.ox_inventory:RegisterStash(trayId, tray.label, tray.slots, tray.weight, false)
    
    -- Open tray for player
    exports.ox_inventory:forceOpenInventory(source, 'stash', trayId)
end)

-- Delete tray
RegisterNetEvent('ng-business:server:deleteTray', function(trayId)
    local source = source
    
    if not IsPlayerAceAllowed(source, 'command.admin') then
        ErrorPrint('Player', source, 'attempted to delete tray without permission')
        return
    end
    
    DebugPrint('Deleting tray:', trayId)
    
    local affectedRows = MySQL.update.await('DELETE FROM business_trays WHERE tray_id = ?', {trayId})
    
    if affectedRows > 0 then
        BusinessData.trays[trayId] = nil
        TriggerClientEvent('ng-business:client:updateTrays', -1, BusinessData.trays)
        TriggerClientEvent('okokNotify:Alert', source, 'Success', 'Tray deleted successfully', 5000, 'success', true)
        SuccessPrint('Tray deleted:', trayId)
    else
        TriggerClientEvent('okokNotify:Alert', source, 'Error', 'Failed to delete tray', 5000, 'error', true)
        ErrorPrint('Failed to delete tray:', trayId)
    end
end)

DebugPrint('Tray module loaded')
