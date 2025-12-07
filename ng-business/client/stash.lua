-- ============================================
-- CLIENT STASH - ng-business
-- ============================================

local stashes = {}
local stashBlips = {}
local StashTargets = {}  -- ox_target用のターゲット管理

-- Load stashes from server
local function LoadStashes()
    local data = lib.callback.await('ng-business:server:getBusinessData', false)
    if data and data.stashes then
        stashes = data.stashes
        DebugPrint('Loaded', #stashes, 'stashes')
        
        -- Create blips
        for _, stash in pairs(stashes) do
            if stash.blip and stash.blip.enabled then
                local blip = AddBlipForCoord(stash.coords.x, stash.coords.y, stash.coords.z)
                SetBlipSprite(blip, stash.blip.sprite)
                SetBlipColour(blip, stash.blip.color)
                SetBlipScale(blip, stash.blip.scale)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(stash.label)
                EndTextCommandSetBlipName(blip)
                stashBlips[stash.id] = blip
            end
        end
    end
end

-- Create stash event
RegisterNetEvent('ng-business:client:createStash', function()
    -- 座標取得方法を選択
    local coordMethod = lib.alertDialog({
        header = '座標取得方法',
        content = 'どの方法で座標を取得しますか？',
        centered = true,
        cancel = true,
        labels = {
            cancel = 'キャンセル',
            confirm = Config.Laser.enabled and 'レーザーを使用' or '現在位置'
        }
    })
    
    if not coordMethod then return end
    
    local function createStashWithCoords(coords)
        local input = lib.inputDialog('スタッシュ作成', {
            {type = 'input', label = 'スタッシュID', description = '一意の識別子（例: police_storage）', required = true},
            {type = 'input', label = '表示名', description = '表示名', required = true},
            {type = 'number', label = 'スロット数', description = 'スロット数', default = 50, min = 1, max = 100},
            {type = 'number', label = '最大重量', description = '最大重量', default = 100000, min = 1000},
            {type = 'input', label = 'ジョブ', description = 'カンマ区切り（例: police,ambulance）空欄で全員'},
            {type = 'number', label = '最低グレード', description = '最低必要グレード', default = 0, min = 0},
            {type = 'checkbox', label = 'ブリップを有効化', checked = true},
            {type = 'number', label = 'ブリップスプライト', description = 'ブリップアイコンID', default = 50},
            {type = 'number', label = 'ブリップカラー', description = 'ブリップカラーID', default = 3},
            {type = 'number', label = 'ブリップスケール', description = 'ブリップサイズ', default = 0.7, min = 0.1, max = 2.0},
        })
        
        if not input then return end
    
        local jobs = {}
        if input[5] and input[5] ~= '' then
            for job in string.gmatch(input[5], '([^,]+)') do
                table.insert(jobs, job:match("^%s*(.-)%s*$"))  -- Trim whitespace
            end
        end
        
        local stashData = {
            stash_id = input[1],
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
        
        TriggerServerEvent('ng-business:server:createStash', stashData)
    end
    
    -- レーザーを使用する場合
    if coordMethod == 'confirm' and Config.Laser.enabled then
        StartLaser(function(coords)
            createStashWithCoords(coords)
        end)
    else
        -- 現在位置を使用
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        createStashWithCoords(coords)
    end
end)

-- Update stashes when created
RegisterNetEvent('ng-business:client:updateStashes', function(newStashes)
    -- Remove old blips
    for _, blip in pairs(stashBlips) do
        RemoveBlip(blip)
    end
    stashBlips = {}
    
    -- Remove old targets (ox_target対応)
    if Config.Target == "ox_target" then
        for targetName, targetData in pairs(StashTargets) do
            if targetData.id then
                exports.ox_target:removeZone(targetData.id)
            end
            StashTargets[targetName] = nil
        end
    else
        for targetName, _ in pairs(StashTargets) do
            exports[Config.Target]:RemoveZone(targetName)
            StashTargets[targetName] = nil
        end
    end
    
    -- Update stashes
    stashes = newStashes
    
    -- Create new blips and targets
    for _, stash in pairs(stashes) do
        if stash.blip and stash.blip.enabled then
            local blip = AddBlipForCoord(stash.coords.x, stash.coords.y, stash.coords.z)
            SetBlipSprite(blip, stash.blip.sprite)
            SetBlipColour(blip, stash.blip.color)
            SetBlipScale(blip, stash.blip.scale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(stash.label)
            EndTextCommandSetBlipName(blip)
            stashBlips[stash.id] = blip
        end
        
        -- Create ox_target zone if enabled and using target mode
        if Config.InteractionType == "target" and Config.Target == "ox_target" then
            local targetName = "stash_" .. stash.id
            local targetId = exports.ox_target:addSphereZone({
                coords = vector3(stash.coords.x, stash.coords.y, stash.coords.z),
                radius = 1.5,
                debug = Config.Debug,
                options = {{
                    name = targetName,
                    type = "client",
                    event = "ng-business:client:openStashTarget",
                    args = {stashId = stash.id},
                    icon = "fa-solid fa-box",
                    label = stash.label,
                    canInteract = function(entity)
                        return HasRequiredJob(stash.jobs, stash.minGrade)
                    end,
                    distance = 2.0
                }}
            })
            StashTargets[targetName] = {
                id = targetId,
                stashId = stash.id
            }
        end
    end
    
    SuccessPrint('Stashes updated')
end)

-- ox_target用のスタッシュオープンイベント
RegisterNetEvent('ng-business:client:openStashTarget', function(data)
    if data and data.stashId then
        TriggerServerEvent('ng-business:server:openStash', data.stashId)
    end
end)

-- Main thread for stash interactions (marker mode only)
CreateThread(function()
    -- Wait for player to load
    while not QBCore.Functions.GetPlayerData().citizenid do
        Wait(1000)
    end
    
    -- Load stashes
    LoadStashes()
    
    -- Main loop
    local isShowingTextUI = false
    while true do
        local sleep = 1000
        
        -- markerモードの場合のみ実行
        if Config.InteractionType == "marker" then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local nearStash = false
            
            for _, stash in pairs(stashes) do
                local distance = #(coords - stash.coords)
                
                if distance < 10.0 then
                    sleep = 0
                    DrawMarkerAtCoords(stash.coords)
                    
                    if distance < Config.UI.interactionDistance then
                        nearStash = true
                        if HasRequiredJob(stash.jobs, stash.minGrade) then
                            if not isShowingTextUI then
                                lib.showTextUI('[E] ' .. stash.label, {
                                    position = "left-center",
                                    icon = 'box',
                                })
                                isShowingTextUI = true
                            end
                            
                            if IsControlJustPressed(0, Config.InteractionKey) then
                                TriggerServerEvent('ng-business:server:openStash', stash.id)
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
            
            if not nearStash and isShowingTextUI then
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

DebugPrint('Stash module loaded')
