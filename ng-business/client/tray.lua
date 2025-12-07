-- ============================================
-- CLIENT TRAY - ng-business
-- ============================================

local trays = {}
local trayBlips = {}
local TrayTargets = {}  -- ox_target用のターゲット管理

-- Load trays from server
local function LoadTrays()
    local data = lib.callback.await('ng-business:server:getBusinessData', false)
    if data and data.trays then
        trays = data.trays
        DebugPrint('Loaded', #trays, 'trays')
        
        -- Create blips
        for _, tray in pairs(trays) do
            if tray.blip and tray.blip.enabled then
                local blip = AddBlipForCoord(tray.coords.x, tray.coords.y, tray.coords.z)
                SetBlipSprite(blip, tray.blip.sprite)
                SetBlipColour(blip, tray.blip.color)
                SetBlipScale(blip, tray.blip.scale)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(tray.label)
                EndTextCommandSetBlipName(blip)
                trayBlips[tray.id] = blip
            end
        end
    end
end

-- Create tray event
RegisterNetEvent('ng-business:client:createTray', function()
    local input = lib.inputDialog('トレイ作成', {
        {type = 'input', label = 'トレイID', description = '一意の識別子（例: burgershot_tray）', required = true},
        {type = 'input', label = '表示名', description = '表示名', required = true},
        {type = 'number', label = 'スロット数', description = 'スロット数', default = 10, min = 1, max = 50},
        {type = 'number', label = '最大重量', description = '最大重量', default = 10000, min = 1000},
        {type = 'input', label = 'ジョブ', description = 'アイテムを追加できるジョブ（カンマ区切り）空欄で全員'},
        {type = 'number', label = '最低グレード', description = '最低必要グレード', default = 0, min = 0},
        {type = 'checkbox', label = 'ブリップを有効化', checked = false},
        {type = 'number', label = 'ブリップスプライト', description = 'ブリップアイコンID', default = 50},
        {type = 'number', label = 'ブリップカラー', description = 'ブリップカラーID', default = 3},
        {type = 'number', label = 'ブリップスケール', description = 'ブリップサイズ', default = 0.7, min = 0.1, max = 2.0},
    })
    
    if not input then return end
    
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    local jobs = {}
    if input[5] and input[5] ~= '' then
        for job in string.gmatch(input[5], '([^,]+)') do
            table.insert(jobs, job:match("^%s*(.-)%s*$"))
        end
    end
    
    local trayData = {
        tray_id = input[1],
        label = input[2],
        coords = {x = coords.x, y = coords.y, z = coords.z},
        slots = input[3],
        weight = input[4],
        jobs = jobs,
        min_grade = input[6],
        blip_enabled = input[7],
        blip_sprite = input[8],
        blip_color = input[9],
        blip_scale = input[10]
    }
    
    TriggerServerEvent('ng-business:server:createTray', trayData)
end)

-- Update trays when created
RegisterNetEvent('ng-business:client:updateTrays', function(newTrays)
    -- Remove old blips
    for _, blip in pairs(trayBlips) do
        RemoveBlip(blip)
    end
    trayBlips = {}
    
    -- Remove old targets (ox_target対応)
    if Config.Target == "ox_target" then
        for targetName, targetData in pairs(TrayTargets) do
            if targetData.id then
                exports.ox_target:removeZone(targetData.id)
            end
            TrayTargets[targetName] = nil
        end
    else
        for targetName, _ in pairs(TrayTargets) do
            exports[Config.Target]:RemoveZone(targetName)
            TrayTargets[targetName] = nil
        end
    end
    
    -- Update trays
    trays = newTrays
    
    -- Create new blips and targets
    for _, tray in pairs(trays) do
        if tray.blip and tray.blip.enabled then
            local blip = AddBlipForCoord(tray.coords.x, tray.coords.y, tray.coords.z)
            SetBlipSprite(blip, tray.blip.sprite)
            SetBlipColour(blip, tray.blip.color)
            SetBlipScale(blip, tray.blip.scale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(tray.label)
            EndTextCommandSetBlipName(blip)
            trayBlips[tray.id] = blip
        end
        
        -- Create ox_target zone if enabled and using target mode
        if Config.InteractionType == "target" and Config.Target == "ox_target" then
            local targetName = "tray_" .. tray.id
            local targetId = exports.ox_target:addSphereZone({
                coords = vector3(tray.coords.x, tray.coords.y, tray.coords.z),
                radius = 1.5,
                debug = Config.Debug,
                options = {{
                    name = targetName,
                    type = "client",
                    event = "ng-business:client:openTrayTarget",
                    args = {trayId = tray.id},
                    icon = "fa-solid fa-table",
                    label = tray.label,
                    distance = 2.0
                }}
            })
            TrayTargets[targetName] = {
                id = targetId,
                trayId = tray.id
            }
        end
    end
    
    SuccessPrint('Trays updated')
end)

-- ox_target用のトレイオープンイベント
RegisterNetEvent('ng-business:client:openTrayTarget', function(data)
    if data and data.trayId then
        TriggerServerEvent('ng-business:server:openTray', data.trayId)
    end
end)

-- Main thread for tray interactions (marker mode only)
CreateThread(function()
    -- Wait for player to load
    while not QBCore.Functions.GetPlayerData().citizenid do
        Wait(1000)
    end
    
    -- Load trays
    LoadTrays()
    
    -- Main loop
    local isShowingTextUI = false
    while true do
        local sleep = 1000
        
        -- markerモードの場合のみ実行
        if Config.InteractionType == "marker" then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local nearTray = false
            
            for _, tray in pairs(trays) do
                local distance = #(coords - tray.coords)
                
                if distance < 10.0 then
                    sleep = 0
                    DrawMarkerAtCoords(tray.coords)
                    
                    if distance < Config.UI.interactionDistance then
                        nearTray = true
                        if not isShowingTextUI then
                            lib.showTextUI('[E] ' .. tray.label, {
                                position = "left-center",
                            icon = 'table',
                        })
                        isShowingTextUI = true
                    end
                    
                        if IsControlJustPressed(0, Config.InteractionKey) then
                            TriggerServerEvent('ng-business:server:openTray', tray.id)
                        end
                        break
                    end
                end
            end
            
            if not nearTray and isShowingTextUI then
                lib.hideTextUI()
                isShowingTextUI = false
            end
        else
            -- targetモードの場合はスリープを長くする
            sleep = 1000
        end
        
        if not nearTray and isShowingTextUI then
            lib.hideTextUI()
            isShowingTextUI = false
        end
        
        Wait(sleep)
    end
end)

DebugPrint('Tray module loaded')
