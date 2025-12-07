-- ============================================
-- CLIENT BLIP - ng-business
-- ============================================

local customBlips = {}
local blipHandles = {}

-- Load custom blips from server
local function LoadCustomBlips()
    local data = lib.callback.await('ng-business:server:getBusinessData', false)
    if data and data.blips then
        customBlips = data.blips
        DebugPrint('Loaded', #customBlips, 'custom blips')
        
        -- Create blips
        for _, blipData in pairs(customBlips) do
            local blip = AddBlipForCoord(blipData.coords.x, blipData.coords.y, blipData.coords.z)
            SetBlipSprite(blip, blipData.sprite)
            SetBlipColour(blip, blipData.color)
            SetBlipScale(blip, blipData.scale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(blipData.label)
            EndTextCommandSetBlipName(blip)
            blipHandles[blipData.id] = blip
        end
    end
end

-- Create blip event
RegisterNetEvent('ng-business:client:createBlip', function()
    local input = lib.inputDialog('ブリップ作成', {
        {type = 'input', label = '表示名', description = 'ブリップ名', required = true},
        {type = 'number', label = 'スプライト', description = 'ブリップアイコンID（FiveMドキュメント参照）', default = 1, min = 1},
        {type = 'number', label = 'カラー', description = 'ブリップカラーID', default = 0, min = 0},
        {type = 'number', label = 'スケール', description = 'ブリップサイズ', default = 0.8, min = 0.1, max = 2.0},
    })
    
    if not input then return end
    
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    local blipData = {
        label = input[1],
        coords = {x = coords.x, y = coords.y, z = coords.z},
        sprite = input[2],
        color = input[3],
        scale = input[4]
    }
    
    TriggerServerEvent('ng-business:server:createBlip', blipData)
end)

-- Update blips when created
RegisterNetEvent('ng-business:client:updateBlips', function(newBlips)
    -- Remove old blips
    for _, blip in pairs(blipHandles) do
        RemoveBlip(blip)
    end
    blipHandles = {}
    
    -- Update blips
    customBlips = newBlips
    
    -- Create new blips
    for _, blipData in pairs(customBlips) do
        local blip = AddBlipForCoord(blipData.coords.x, blipData.coords.y, blipData.coords.z)
        SetBlipSprite(blip, blipData.sprite)
        SetBlipColour(blip, blipData.color)
        SetBlipScale(blip, blipData.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(blipData.label)
        EndTextCommandSetBlipName(blip)
        blipHandles[blipData.id] = blip
    end
    
    SuccessPrint('Blips updated')
end)

-- Initialize blips
CreateThread(function()
    -- Wait for player to load
    while not QBCore.Functions.GetPlayerData().citizenid do
        Wait(1000)
    end
    
    -- Load custom blips
    LoadCustomBlips()
end)

DebugPrint('Blip module loaded')
