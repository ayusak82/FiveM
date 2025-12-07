-- ============================================
-- CLIENT JOB - ng-business
-- ============================================

local jobs = {}
local bossMenuBlips = {}

-- Load jobs from server
local function LoadJobs()
    local data = lib.callback.await('ng-business:server:getBusinessData', false)
    if data and data.jobs then
        jobs = data.jobs
        DebugPrint('Loaded', #jobs, 'jobs')
        
        -- Create boss menu blips
        for _, job in pairs(jobs) do
            if job.bossMenuCoords then
                local blip = AddBlipForCoord(job.bossMenuCoords.x, job.bossMenuCoords.y, job.bossMenuCoords.z)
                SetBlipSprite(blip, 478)
                SetBlipColour(blip, 5)
                SetBlipScale(blip, 0.7)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(job.label .. ' - Boss Menu')
                EndTextCommandSetBlipName(blip)
                bossMenuBlips[job.jobName] = blip
            end
        end
    end
end

-- Create job event
RegisterNetEvent('ng-business:client:createJob', function()
    local input = lib.inputDialog('ジョブ作成', {
        {type = 'input', label = 'ジョブ名', description = '内部ジョブ名（例: police）', required = true},
        {type = 'input', label = '表示名', description = '表示名（例: ロスサントス警察署）', required = true},
        {type = 'checkbox', label = 'ボスメニュー位置を追加', description = '現在地にボスメニューを作成', checked = false},
    })
    
    if not input then return end
    
    local jobData = {
        job_name = input[1],
        label = input[2],
        boss_menu_coords = nil
    }
    
    if input[3] then
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        jobData.boss_menu_coords = {x = coords.x, y = coords.y, z = coords.z}
    end
    
    TriggerServerEvent('ng-business:server:createJob', jobData)
end)

-- Update jobs when created
RegisterNetEvent('ng-business:client:updateJobs', function(newJobs)
    -- Remove old blips
    for _, blip in pairs(bossMenuBlips) do
        RemoveBlip(blip)
    end
    bossMenuBlips = {}
    
    -- Update jobs
    jobs = newJobs
    
    -- Create new blips
    for _, job in pairs(jobs) do
        if job.bossMenuCoords then
            local blip = AddBlipForCoord(job.bossMenuCoords.x, job.bossMenuCoords.y, job.bossMenuCoords.z)
            SetBlipSprite(blip, 478)
            SetBlipColour(blip, 5)
            SetBlipScale(blip, 0.7)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(job.label .. ' - Boss Menu')
            EndTextCommandSetBlipName(blip)
            bossMenuBlips[job.jobName] = blip
        end
    end
    
    SuccessPrint('Jobs updated')
end)

-- Open boss menu
RegisterNetEvent('ng-business:client:openBossMenu', function(data)
    local options = {
        {
            title = 'スタッシュ管理',
            description = data.job.label .. 'のスタッシュを表示・管理',
            icon = 'box',
            disabled = #data.stashes == 0,
            onSelect = function()
                -- Show stashes list
                local stashOptions = {}
                for _, stash in ipairs(data.stashes) do
                    table.insert(stashOptions, {
                        title = stash.label,
                        description = 'スロット: ' .. stash.slots .. ' | 重量: ' .. stash.weight,
                        icon = 'box'
                    })
                end
                
                lib.registerContext({
                    id = 'boss_stashes',
                    title = 'スタッシュ',
                    menu = 'boss_menu',
                    options = stashOptions
                })
                
                lib.showContext('boss_stashes')
            end
        },
        {
            title = 'トレイ管理',
            description = data.job.label .. 'のトレイを表示・管理',
            icon = 'table',
            disabled = #data.trays == 0,
            onSelect = function()
                -- Show trays list
                local trayOptions = {}
                for _, tray in ipairs(data.trays) do
                    table.insert(trayOptions, {
                        title = tray.label,
                        description = 'スロット: ' .. tray.slots .. ' | 重量: ' .. tray.weight,
                        icon = 'table'
                    })
                end
                
                lib.registerContext({
                    id = 'boss_trays',
                    title = 'トレイ',
                    menu = 'boss_menu',
                    options = trayOptions
                })
                
                lib.showContext('boss_trays')
            end
        },
        {
            title = 'クラフトステーション管理',
            description = data.job.label .. 'のクラフトステーションを表示・管理',
            icon = 'hammer',
            disabled = #data.crafting == 0,
            onSelect = function()
                -- Show crafting stations list
                local craftingOptions = {}
                for _, station in ipairs(data.crafting) do
                    table.insert(craftingOptions, {
                        title = station.label,
                        description = 'レシピ数: ' .. #station.recipes,
                        icon = 'hammer'
                    })
                end
                
                lib.registerContext({
                    id = 'boss_crafting',
                    title = 'クラフトステーション',
                    menu = 'boss_menu',
                    options = craftingOptions
                })
                
                lib.showContext('boss_crafting')
            end
        },
        {
            title = 'ロッカー管理',
            description = data.job.label .. 'のロッカーを表示・管理',
            icon = 'lock',
            disabled = #data.lockers == 0,
            onSelect = function()
                -- Show lockers list
                local lockerOptions = {}
                for _, locker in ipairs(data.lockers) do
                    table.insert(lockerOptions, {
                        title = locker.label,
                        description = 'スロット: ' .. locker.slots .. ' | 個人用: ' .. (locker.personal and 'はい' or 'いいえ'),
                        icon = 'lock'
                    })
                end
                
                lib.registerContext({
                    id = 'boss_lockers',
                    title = 'ロッカー',
                    menu = 'boss_menu',
                    options = lockerOptions
                })
                
                lib.showContext('boss_lockers')
            end
        }
    }
    
    lib.registerContext({
        id = 'boss_menu',
        title = data.job.label .. ' - ボスメニュー',
        options = options
    })
    
    lib.showContext('boss_menu')
end)

-- Main thread for boss menu interactions
CreateThread(function()
    -- Wait for player to load
    while not QBCore.Functions.GetPlayerData().citizenid do
        Wait(1000)
    end
    
    -- Load jobs
    LoadJobs()
    
    -- Main loop
    local isShowingTextUI = false
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local nearBossMenu = false
        
        for _, job in pairs(jobs) do
            if job.bossMenuCoords then
                local distance = #(coords - job.bossMenuCoords)
                
                if distance < 10.0 then
                    sleep = 0
                    DrawMarkerAtCoords(job.bossMenuCoords)
                    
                    if distance < Config.UI.interactionDistance then
                        nearBossMenu = true
                        if not isShowingTextUI then
                            lib.showTextUI('[E] ' .. job.label .. ' - ボスメニュー', {
                                position = "left-center",
                                icon = 'briefcase',
                            })
                            isShowingTextUI = true
                        end
                        
                        if IsControlJustPressed(0, Config.InteractionKey) then
                            TriggerServerEvent('ng-business:server:openBossMenu', job.jobName)
                        end
                        break
                    end
                end
            end
        end
        
        if not nearBossMenu and isShowingTextUI then
            lib.hideTextUI()
            isShowingTextUI = false
        end
        
        Wait(sleep)
    end
end)

DebugPrint('Job module loaded')
