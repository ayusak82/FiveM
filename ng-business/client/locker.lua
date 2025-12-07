-- ============================================
-- CLIENT LOCKER - ng-business
-- ============================================

local lockers = {}
local lockerBlips = {}
local LockerTargets = {}  -- ox_target用のターゲット管理

-- Load lockers from server
local function LoadLockers()
    local data = lib.callback.await('ng-business:server:getBusinessData', false)
    if data and data.lockers then
        lockers = data.lockers
        DebugPrint('Loaded', #lockers, 'lockers')
        
        -- Create blips
        for _, locker in pairs(lockers) do
            if locker.blip and locker.blip.enabled then
                local blip = AddBlipForCoord(locker.coords.x, locker.coords.y, locker.coords.z)
                SetBlipSprite(blip, locker.blip.sprite)
                SetBlipColour(blip, locker.blip.color)
                SetBlipScale(blip, locker.blip.scale)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(locker.label)
                EndTextCommandSetBlipName(blip)
                lockerBlips[locker.id] = blip
            end
        end
    end
end

-- Create locker event
RegisterNetEvent('ng-business:client:createLocker', function()
    local input = lib.inputDialog('ロッカー作成', {
        {type = 'input', label = 'ロッカーID', description = '一意の識別子（例: police_locker）', required = true},
        {type = 'input', label = '表示名', description = '表示名', required = true},
        {type = 'number', label = 'スロット数', description = 'スロット数', default = 30, min = 1, max = 100},
        {type = 'number', label = '最大重量', description = '最大重量', default = 50000, min = 1000},
        {type = 'input', label = 'ジョブ', description = 'カンマ区切り（例: police,ambulance）空欄で全員'},
        {type = 'number', label = '最低グレード', description = '最低必要グレード', default = 0, min = 0},
        {type = 'checkbox', label = '個人用ロッカー', description = '各プレイヤーが専用ロッカーを持つ', checked = true},
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
    
    local lockerData = {
        locker_id = input[1],
        label = input[2],
        coords = {x = coords.x, y = coords.y, z = coords.z},
        slots = input[3],
        weight = input[4],
        jobs = jobs,
        min_grade = input[6],
        personal = input[7],
        blip_enabled = input[8],
        blip_sprite = input[9],
        blip_color = input[10],
        blip_scale = input[11]
    }
    
    TriggerServerEvent('ng-business:server:createLocker', lockerData)
end)

-- Update lockers when created
RegisterNetEvent('ng-business:client:updateLockers', function(newLockers)
    -- Remove old blips
    for _, blip in pairs(lockerBlips) do
        RemoveBlip(blip)
    end
    lockerBlips = {}
    
    -- Remove old targets (ox_target対応)
    if Config.Target == "ox_target" then
        for targetName, targetData in pairs(LockerTargets) do
            if targetData.id then
                exports.ox_target:removeZone(targetData.id)
            end
            LockerTargets[targetName] = nil
        end
    else
        for targetName, _ in pairs(LockerTargets) do
            exports[Config.Target]:RemoveZone(targetName)
            LockerTargets[targetName] = nil
        end
    end
    
    -- Update lockers
    lockers = newLockers
    
    -- Create new blips and targets
    for _, locker in pairs(lockers) do
        if locker.blip and locker.blip.enabled then
            local blip = AddBlipForCoord(locker.coords.x, locker.coords.y, locker.coords.z)
            SetBlipSprite(blip, locker.blip.sprite)
            SetBlipColour(blip, locker.blip.color)
            SetBlipScale(blip, locker.blip.scale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(locker.label)
            EndTextCommandSetBlipName(blip)
            lockerBlips[locker.id] = blip
        end
        
        -- Create ox_target zone if enabled and using target mode
        if Config.InteractionType == "target" and Config.Target == "ox_target" then
            local targetName = "locker_" .. locker.id
            local targetId = exports.ox_target:addSphereZone({
                coords = vector3(locker.coords.x, locker.coords.y, locker.coords.z),
                radius = 1.5,
                debug = Config.Debug,
                options = {{
                    name = targetName,
                    type = "client",
                    event = "ng-business:client:openLockerTarget",
                    args = {lockerId = locker.id},
                    icon = "fa-solid fa-door-closed",
                    label = locker.label,
                    canInteract = function(entity)
                        return HasRequiredJob(locker.jobs, locker.minGrade)
                    end,
                    distance = 2.0
                }}
            })
            LockerTargets[targetName] = {
                id = targetId,
                lockerId = locker.id
            }
        end
    end
    
    SuccessPrint('Lockers updated')
end)

-- ox_target用のロッカーオープンイベント
RegisterNetEvent('ng-business:client:openLockerTarget', function(data)
    if data and data.lockerId then
        TriggerServerEvent('ng-business:server:openLocker', data.lockerId)
    end
end)

-- Main thread for locker interactions (marker mode only)
CreateThread(function()
    -- Wait for player to load
    while not QBCore.Functions.GetPlayerData().citizenid do
        Wait(1000)
    end
    
    -- Load lockers
    LoadLockers()
    
    -- Main loop
    local isShowingTextUI = false
    while true do
        local sleep = 1000
        
        -- markerモードの場合のみ実行
        if Config.InteractionType == "marker" then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local nearLocker = false
            
            for _, locker in pairs(lockers) do
                local distance = #(coords - locker.coords)
                
                if distance < 10.0 then
                    sleep = 0
                    DrawMarkerAtCoords(locker.coords)
                    
                    if distance < Config.UI.interactionDistance then
                    nearLocker = true
                    if HasRequiredJob(locker.jobs, locker.minGrade) then
                        if not isShowingTextUI then
                            local labelText = locker.label
                            if locker.personal then
                                labelText = labelText .. ' (個人用)'
                            end
                            
                            lib.showTextUI('[E] ' .. labelText, {
                                position = "left-center",
                                icon = 'lock',
                            })
                            isShowingTextUI = true
                        end
                        
                        if IsControlJustPressed(0, Config.InteractionKey) then
                            TriggerServerEvent('ng-business:server:openLocker', locker.id)
                        end
                    else
                        if not isShowingTextUI then
                            lib.showTextUI('[!] アクセス不可', {
                                position = "left-center",
                                icon = 'lock',
                            })
                            isShowingTextUI = true
                        end
                    end
                        break
                    end
                end
            end
            
            if not nearLocker and isShowingTextUI then
                lib.hideTextUI()
                isShowingTextUI = false
            end
        else
            -- targetモードの場合はスリープを長くする
            sleep = 1000
        end
        
        Wait(sleep)
    end
end)

DebugPrint('Locker module loaded')
