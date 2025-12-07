-- ============================================
-- SERVER BLIP - ng-business
-- ============================================

-- Create blip
RegisterNetEvent('ng-business:server:createBlip', function(data)
    local source = source
    
    if not IsPlayerAceAllowed(source, 'command.admin') then
        ErrorPrint('Player', source, 'attempted to create blip without permission')
        return
    end
    
    DebugPrint('Creating blip:', data.label)
    
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    -- Insert into database
    local insertId = MySQL.insert.await([[
        INSERT INTO business_blips (label, coords, sprite, color, scale, created_by)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {
        data.label,
        json.encode(data.coords),
        data.sprite,
        data.color,
        data.scale,
        Player.PlayerData.citizenid
    })
    
    if insertId then
        -- Add to BusinessData
        BusinessData.blips[insertId] = {
            id = insertId,
            label = data.label,
            coords = vector3(data.coords.x, data.coords.y, data.coords.z),
            sprite = data.sprite,
            color = data.color,
            scale = data.scale
        }
        
        -- Notify all clients
        TriggerClientEvent('ng-business:client:updateBlips', -1, BusinessData.blips)
        TriggerClientEvent('okokNotify:Alert', source, 'Success', 'Blip created successfully', 5000, 'success', true)
        SuccessPrint('Blip created:', data.label, 'by', Player.PlayerData.citizenid)
    else
        TriggerClientEvent('okokNotify:Alert', source, 'Error', 'Failed to create blip', 5000, 'error', true)
        ErrorPrint('Failed to create blip:', data.label)
    end
end)

-- Delete blip
RegisterNetEvent('ng-business:server:deleteBlip', function(blipId)
    local source = source
    
    if not IsPlayerAceAllowed(source, 'command.admin') then
        ErrorPrint('Player', source, 'attempted to delete blip without permission')
        return
    end
    
    DebugPrint('Deleting blip:', blipId)
    
    local affectedRows = MySQL.update.await('DELETE FROM business_blips WHERE id = ?', {blipId})
    
    if affectedRows > 0 then
        BusinessData.blips[blipId] = nil
        TriggerClientEvent('ng-business:client:updateBlips', -1, BusinessData.blips)
        TriggerClientEvent('okokNotify:Alert', source, 'Success', 'Blip deleted successfully', 5000, 'success', true)
        SuccessPrint('Blip deleted:', blipId)
    else
        TriggerClientEvent('okokNotify:Alert', source, 'Error', 'Failed to delete blip', 5000, 'error', true)
        ErrorPrint('Failed to delete blip:', blipId)
    end
end)

DebugPrint('Blip module loaded')
