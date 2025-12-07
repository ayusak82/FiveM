local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local isInJob = false
local currentJob = nil
local spawnedVehicle = nil
local spawnedNPC = nil
local originalBucket = 0
local currentDestinationIndex = 1
local unloadCount = 0
local startTime = 0
local timeLimit = 0
local timerThread = nil
local destinationBlip = nil
local routeBlip = nil

-- ============================================
-- 初期化
-- ============================================
CreateThread(function()
    while QBCore == nil do
        Wait(100)
    end
    
    PlayerData = QBCore.Functions.GetPlayerData()
    
    -- NPCスポーン
    SpawnNPC()
    
    if Config.Debug then
        print('[ng-cargo] Client initialized')
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
    CleanupJob()
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
    PlayerData = data
end)

-- ============================================
-- NPC スポーン
-- ============================================
function SpawnNPC()
    local model = Config.NPCLocation.model
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(100)
    end
    
    spawnedNPC = CreatePed(4, model, Config.NPCLocation.coords.x, Config.NPCLocation.coords.y, Config.NPCLocation.coords.z - 1.0, Config.NPCLocation.coords.w, false, true)
    FreezeEntityPosition(spawnedNPC, true)
    SetEntityInvincible(spawnedNPC, true)
    SetBlockingOfNonTemporaryEvents(spawnedNPC, true)
    TaskStartScenarioInPlace(spawnedNPC, Config.NPCLocation.scenario, 0, true)
    
    -- ox_target使用時
    exports.ox_target:addLocalEntity(spawnedNPC, {
        {
            name = 'ng_cargo_npc',
            icon = 'fas fa-plane',
            label = '貨物輸送の仕事',
            onSelect = function()
                OpenJobMenu()
            end
        }
    })
    
    -- Blip作成
    local blip = AddBlipForCoord(Config.NPCLocation.coords.x, Config.NPCLocation.coords.y, Config.NPCLocation.coords.z)
    SetBlipSprite(blip, 307)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, 5)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('貨物輸送')
    EndTextCommandSetBlipName(blip)
end

-- ============================================
-- ジョブメニュー
-- ============================================
function OpenJobMenu()
    if isInJob then
        ShowNotification(Config.Messages.already_in_job, 'error')
        return
    end
    
    -- 統計情報を取得
    QBCore.Functions.TriggerCallback('ng-cargo:server:getPlayerStats', function(stats)
        local menuOptions = {
            {
                title = '貨物輸送センター',
                description = 'Titanで貨物を配送する仕事です',
                icon = 'plane',
                disabled = true
            },
            {
                title = '━━━━━━━━━━━━━━━━━━',
                disabled = true
            },
            {
                title = '📊 あなたの統計',
                description = string.format('レベル: %d | 総配送: %d回 | 成功率: %d%%', 
                    stats.level or 1, 
                    stats.total_deliveries or 0,
                    stats.total_deliveries > 0 and math.floor((stats.successful_deliveries / stats.total_deliveries) * 100) or 0
                ),
                icon = 'chart-line',
                disabled = true
            },
            {
                title = '━━━━━━━━━━━━━━━━━━',
                disabled = true
            }
        }
        
        -- 難易度選択
        for difficulty, data in pairs(Config.Difficulties) do
            local levelBonus = GetLevelBonus(stats.level or 1)
            local estimatedReward = math.floor(data.baseReward * levelBonus)
            
            table.insert(menuOptions, {
                title = data.label,
                description = string.format(
                    '配送先: %d箇所 | 制限時間: %d分\n報酬: $%d (レベルボーナス: x%.1f)\n経験値: +%d',
                    data.destinations,
                    math.floor(data.timeLimit / 60),
                    estimatedReward,
                    levelBonus,
                    data.experience
                ),
                icon = difficulty == 'easy' and 'star' or (difficulty == 'normal' and 'star-half-alt' or 'fire'),
                iconColor = difficulty == 'easy' and 'green' or (difficulty == 'normal' and 'yellow' or 'red'),
                onSelect = function()
                    StartJob(difficulty, stats.level or 1)
                end
            })
        end
        
        table.insert(menuOptions, {
            title = '━━━━━━━━━━━━━━━━━━',
            disabled = true
        })
        
        table.insert(menuOptions, {
            title = '🏆 ランキングを見る',
            description = 'トップ配送者のランキング',
            icon = 'trophy',
            iconColor = 'gold',
            onSelect = function()
                TriggerServerEvent('ng-cargo:server:showRanking')
            end
        })
        
        lib.registerContext({
            id = 'ng_cargo_menu',
            title = '貨物輸送センター',
            options = menuOptions
        })
        
        lib.showContext('ng_cargo_menu')
    end)
end

-- ============================================
-- ジョブ開始
-- ============================================
function StartJob(difficulty, playerLevel)
    if isInJob then return end
    
    QBCore.Functions.TriggerCallback('ng-cargo:server:startJob', function(success, jobData)
        if not success then
            ShowNotification('ジョブの開始に失敗しました', 'error')
            return
        end
        
        isInJob = true
        currentJob = jobData
        currentDestinationIndex = 1
        unloadCount = 0
        startTime = GetGameTimer()
        timeLimit = jobData.timeLimit
        
        -- 車両スポーン
        SpawnVehicle()
        
        -- ランダムイベント
        if jobData.randomEvent then
            ShowNotification(string.format(Config.Messages.random_event, jobData.randomEvent.name), 'info', 7000)
            Wait(1000)
            ShowNotification(jobData.randomEvent.description, 'success', 7000)
        end
        
        ShowNotification(Config.Messages.job_started, 'success')
        
        -- 最初の目的地を設定
        SetDestination(currentJob.destinations[currentDestinationIndex])
        
        -- タイマー開始
        StartTimer()
        
        -- 車両破壊監視
        CreateThread(function()
            while isInJob do
                Wait(1000)
                if spawnedVehicle and DoesEntityExist(spawnedVehicle) then
                    if IsEntityDead(spawnedVehicle) or GetEntityHealth(spawnedVehicle) < 100 then
                        FailJob('vehicle_destroyed')
                        break
                    end
                end
            end
        end)
        
        -- プレイヤー死亡監視
        CreateThread(function()
            while isInJob do
                Wait(1000)
                local ped = PlayerPedId()
                if IsEntityDead(ped) or IsPedDeadOrDying(ped, true) then
                    if Config.Debug then
                        print('[ng-cargo] Player died during job')
                    end
                    
                    -- 即座にジョブ状態をクリア
                    isInJob = false
                    
                    -- UIとBlipを即座にクリーンアップ
                    HideTimer()
                    lib.hideTextUI()
                    
                    if destinationBlip then
                        RemoveBlip(destinationBlip)
                        destinationBlip = nil
                    end
                    if routeBlip then
                        RemoveBlip(routeBlip)
                        routeBlip = nil
                    end
                    
                    -- リスポーン後の処理を別スレッドで実行
                    CreateThread(function()
                        -- プレイヤーが生き返るまで待つ
                        while IsEntityDead(PlayerPedId()) or IsPedDeadOrDying(PlayerPedId(), true) do
                            Wait(1000)
                        end
                        
                        if Config.Debug then
                            print('[ng-cargo] Player respawned, starting cleanup')
                        end
                        
                        -- リスポーンアニメーション完了を待つ
                        Wait(Config.DeathSettings.teleportDelay or 2000)
                        
                        -- プレイヤーのコントロールを確実に有効化
                        local playerPed = PlayerPedId()
                        ClearPedTasksImmediately(playerPed)
                        SetEntityInvincible(playerPed, false)
                        FreezeEntityPosition(playerPed, false)
                        SetPlayerControl(PlayerId(), true, 0)
                        
                        -- 車両削除
                        if spawnedVehicle and DoesEntityExist(spawnedVehicle) then
                            DeleteEntity(spawnedVehicle)
                            spawnedVehicle = nil
                        end
                        
                        -- ジョブデータクリア
                        currentJob = nil
                        currentDestinationIndex = 1
                        unloadCount = 0
                        startTime = 0
                        timeLimit = 0
                        
                        -- ジョブ失敗をサーバーに通知（死亡フラグ付き）
                        TriggerServerEvent('ng-cargo:server:failJob', true)
                        
                        -- テレポート処理
                        if Config.DeathSettings.teleportOnDeath then
                            if Config.DeathSettings.skipIfEMSOnline then
                                -- EMSチェック
                                QBCore.Functions.TriggerCallback('ng-cargo:server:checkEMSCount', function(emsCount)
                                    local shouldTeleport = emsCount < (Config.DeathSettings.minEMSCount or 1)
                                    
                                    if Config.Debug then
                                        print(string.format('[ng-cargo] EMS count: %d, Teleport: %s', emsCount, tostring(shouldTeleport)))
                                    end
                                    
                                    if shouldTeleport then
                                        -- テレポート実行
                                        Wait(500) -- 少し待機
                                        local coords = Config.NPCLocation.coords
                                        SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, true)
                                        SetEntityHeading(PlayerPedId(), coords.w)
                                        
                                        if Config.Debug then
                                            print('[ng-cargo] Player teleported to job location')
                                        end
                                        
                                        ShowNotification('リスポーンしました。ジョブは失敗となりました。', 'error', 5000)
                                    else
                                        ShowNotification('ジョブは失敗となりました。EMSが対応できます。', 'info', 5000)
                                    end
                                    
                                    -- バケットを0にリセット
                                    TriggerServerEvent('ng-cargo:server:resetBucketToDeath')
                                end)
                            else
                                -- EMS関係なくテレポート
                                Wait(500) -- 少し待機
                                local coords = Config.NPCLocation.coords
                                SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, true)
                                SetEntityHeading(PlayerPedId(), coords.w)
                                
                                if Config.Debug then
                                    print('[ng-cargo] Player teleported to job location')
                                end
                                
                                -- バケットを0にリセット
                                TriggerServerEvent('ng-cargo:server:resetBucketToDeath')
                                
                                ShowNotification('リスポーンしました。ジョブは失敗となりました。', 'error', 5000)
                            end
                        else
                            -- テレポートなしの場合もバケットはリセット
                            TriggerServerEvent('ng-cargo:server:resetBucketToDeath')
                            ShowNotification('ジョブは失敗となりました。', 'error', 5000)
                            
                            if Config.Debug then
                                print('[ng-cargo] Teleport disabled, only bucket reset')
                            end
                        end
                        
                        if Config.Debug then
                            print('[ng-cargo] Death cleanup completed')
                        end
                    end)
                    
                    break
                end
            end
        end)
        
        -- 切断監視
        AddEventHandler('onResourceStop', function(resourceName)
            if GetCurrentResourceName() == resourceName and isInJob then
                TriggerServerEvent('ng-cargo:server:cancelJob', 'disconnect')
            end
        end)
        
    end, difficulty, playerLevel)
end

-- ============================================
-- 車両スポーン
-- ============================================
function SpawnVehicle()
    local model = Config.VehicleSpawn.model
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(100)
    end
    
    spawnedVehicle = CreateVehicle(
        model,
        Config.VehicleSpawn.coords.x,
        Config.VehicleSpawn.coords.y,
        Config.VehicleSpawn.coords.z,
        Config.VehicleSpawn.coords.w,
        true,
        false
    )
    
    SetVehicleNumberPlateText(spawnedVehicle, 'CARGO' .. math.random(100, 999))
    SetEntityAsMissionEntity(spawnedVehicle, true, true)
    SetVehicleFuelLevel(spawnedVehicle, 100.0)
    DecorSetFloat(spawnedVehicle, '_FUEL_LEVEL', 100.0)
    SetVehicleEngineOn(spawnedVehicle, true, true, false)
    
    -- 車両の鍵を付与 (qb-core)
    local plate = GetVehicleNumberPlateText(spawnedVehicle)
    TriggerEvent("vehiclekeys:client:SetOwner", plate)
    
    -- 車両にマーカー
    local blip = AddBlipForEntity(spawnedVehicle)
    SetBlipSprite(blip, 307)
    SetBlipColour(blip, 5)
    SetBlipScale(blip, 0.8)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('配送車両 (Titan)')
    EndTextCommandSetBlipName(blip)
    
    if Config.Debug then
        print('[ng-cargo] Vehicle spawned:', spawnedVehicle)
        print('[ng-cargo] Vehicle plate:', plate)
    end
end

-- ============================================
-- 目的地設定
-- ============================================
function SetDestination(destination)
    -- 古いBlip削除
    if destinationBlip then
        RemoveBlip(destinationBlip)
    end
    if routeBlip then
        RemoveBlip(routeBlip)
    end
    
    -- 新しいBlip作成
    destinationBlip = AddBlipForCoord(destination.coords.x, destination.coords.y, destination.coords.z)
    SetBlipSprite(destinationBlip, Config.UI.blip.sprite)
    SetBlipDisplay(destinationBlip, 4)
    SetBlipScale(destinationBlip, Config.UI.blip.scale)
    SetBlipColour(destinationBlip, Config.UI.blip.color)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(string.format('%s (%d/%d)', destination.name, currentDestinationIndex, #currentJob.destinations))
    EndTextCommandSetBlipName(destinationBlip)
    
    -- GPS設定
    SetNewWaypoint(destination.coords.x, destination.coords.y)
    
    ShowNotification(string.format('目的地: %s (%d/%d)', destination.name, currentDestinationIndex, #currentJob.destinations), 'info')
    
    -- 到着監視
    CreateThread(function()
        while isInJob and currentDestinationIndex <= #currentJob.destinations do
            Wait(1000)
            local playerCoords = GetEntityCoords(PlayerPedId())
            local dist = #(playerCoords - destination.coords)
            
            if dist < 50.0 then
                OnArriveDestination(destination)
                break
            end
        end
    end)
end

-- ============================================
-- 目的地到着
-- ============================================
function OnArriveDestination(destination)
    ShowNotification(Config.Messages.arrive_destination, 'success')
    unloadCount = 0
    
    -- 荷下ろしポイント作成
    CreateThread(function()
        local unloadNeeded = currentJob.unloadCount
        if currentJob.randomEvent and currentJob.randomEvent.extraUnloads then
            unloadNeeded = unloadNeeded + currentJob.randomEvent.extraUnloads
        end
        
        while isInJob and unloadCount < unloadNeeded do
            Wait(0)
            local playerCoords = GetEntityCoords(PlayerPedId())
            local dist = #(playerCoords - destination.coords)
            
            if dist < 30.0 then
                DrawMarker(
                    1, 
                    destination.coords.x, 
                    destination.coords.y, 
                    destination.coords.z - 1.0,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    3.0, 3.0, 1.0,
                    255, 255, 0, 100,
                    false, true, 2, false, nil, nil, false
                )
                
                if dist < 3.0 then
                    lib.showTextUI('[E] 荷物を降ろす (' .. unloadCount .. '/' .. unloadNeeded .. ')', {
                        position = "left-center",
                        icon = 'box',
                    })
                    
                    if IsControlJustPressed(0, 38) then -- E key
                        lib.hideTextUI()
                        UnloadCargo(unloadNeeded)
                    end
                else
                    lib.hideTextUI()
                end
            end
        end
        
        lib.hideTextUI()
    end)
end

-- ============================================
-- 荷下ろし
-- ============================================
function UnloadCargo(totalUnloads)
    local ped = PlayerPedId()
    
    -- アニメーション
    RequestAnimDict(Config.UnloadSettings.animation.dict)
    while not HasAnimDictLoaded(Config.UnloadSettings.animation.dict) do
        Wait(100)
    end
    
    TaskPlayAnim(ped, Config.UnloadSettings.animation.dict, Config.UnloadSettings.animation.anim, 8.0, 8.0, -1, Config.UnloadSettings.animation.flags, 0, false, false, false)
    
    if lib.progressBar({
        duration = Config.UnloadSettings.duration,
        label = Config.UnloadSettings.progressBar.label,
        useWhileDead = Config.UnloadSettings.progressBar.useWhileDead,
        canCancel = Config.UnloadSettings.progressBar.canCancel,
        disable = {
            move = true,
            car = true,
            combat = true
        }
    }) then
        ClearPedTasks(ped)
        unloadCount = unloadCount + 1
        
        ShowNotification(string.format(Config.Messages.unload_complete .. ' (%d/%d)', unloadCount, totalUnloads), 'success')
        
        -- 全て完了したら次の目的地へ
        if unloadCount >= totalUnloads then
            currentDestinationIndex = currentDestinationIndex + 1
            
            if currentDestinationIndex <= #currentJob.destinations then
                -- 次の目的地へ
                Wait(2000)
                SetDestination(currentJob.destinations[currentDestinationIndex])
            else
                -- 全配送完了、帰還
                StartReturn()
            end
        end
    else
        ClearPedTasks(ped)
    end
end

-- ============================================
-- 帰還開始
-- ============================================
function StartReturn()
    ShowNotification(Config.Messages.return_to_base, 'info', 7000)
    
    -- Blip削除
    if destinationBlip then
        RemoveBlip(destinationBlip)
        destinationBlip = nil
    end
    
    -- 帰還地点のBlip
    local returnBlip = AddBlipForCoord(Config.ReturnLocation.x, Config.ReturnLocation.y, Config.ReturnLocation.z)
    SetBlipSprite(returnBlip, 1)
    SetBlipDisplay(returnBlip, 4)
    SetBlipScale(returnBlip, 1.0)
    SetBlipColour(returnBlip, 2)
    SetBlipRoute(returnBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('空港に帰還')
    EndTextCommandSetBlipName(returnBlip)
    
    SetNewWaypoint(Config.ReturnLocation.x, Config.ReturnLocation.y)
    
    -- 帰還監視
    CreateThread(function()
        while isInJob do
            Wait(1000)
            local playerCoords = GetEntityCoords(PlayerPedId())
            local dist = #(playerCoords - Config.ReturnLocation)
            
            if dist < Config.ReturnRadius then
                RemoveBlip(returnBlip)
                CompleteJob()
                break
            end
        end
    end)
end

-- ============================================
-- ジョブ完了
-- ============================================
function CompleteJob()
    if not isInJob then return end
    
    local completionTime = math.floor((GetGameTimer() - startTime) / 1000)
    
    TriggerServerEvent('ng-cargo:server:completeJob', completionTime)
    
    CleanupJob()
end

-- ============================================
-- ジョブ失敗
-- ============================================
function FailJob(reason)
    if not isInJob then return end
    
    local message = Config.Messages[reason] or Config.Messages.job_failed
    ShowNotification(message, 'error')
    
    TriggerServerEvent('ng-cargo:server:failJob')
    
    CleanupJob()
end

-- ============================================
-- クリーンアップ
-- ============================================
function CleanupJob()
    isInJob = false
    currentJob = nil
    currentDestinationIndex = 1
    unloadCount = 0
    startTime = 0
    timeLimit = 0
    
    -- タイマー停止
    if timerThread then
        timerThread = nil
    end
    
    -- UI非表示
    HideTimer()
    lib.hideTextUI()
    
    -- 車両削除
    if spawnedVehicle and DoesEntityExist(spawnedVehicle) then
        DeleteEntity(spawnedVehicle)
        spawnedVehicle = nil
    end
    
    -- Blip削除
    if destinationBlip then
        RemoveBlip(destinationBlip)
        destinationBlip = nil
    end
    if routeBlip then
        RemoveBlip(routeBlip)
        routeBlip = nil
    end
    
    -- バケットリセット
    TriggerServerEvent('ng-cargo:server:resetBucket')
end

-- ============================================
-- レベルボーナス計算
-- ============================================
function GetLevelBonus(level)
    local bonus = 1.0
    local levels = {}
    
    -- Config.Rewards.levelBonusのキーをテーブルに格納してソート
    for lvl, _ in pairs(Config.Rewards.levelBonus) do
        table.insert(levels, lvl)
    end
    table.sort(levels)
    
    -- プレイヤーレベル以下で最大のボーナスを取得
    for _, lvl in ipairs(levels) do
        if level >= lvl then
            bonus = Config.Rewards.levelBonus[lvl]
        else
            break
        end
    end
    
    return bonus
end

-- ============================================
-- イベント: ジョブキャンセル (サーバーから)
-- ============================================
RegisterNetEvent('ng-cargo:client:cancelJob', function()
    if isInJob then
        ShowNotification(Config.Messages.job_cancelled, 'error')
        CleanupJob()
    end
end)

-- ============================================
-- イベント: ジョブ完了通知
-- ============================================
RegisterNetEvent('ng-cargo:client:jobCompleted', function(data)
    ShowJobCompleteStats(data)
end)

-- ============================================
-- 通知ヘルパー
-- ============================================
function ShowNotification(message, type, duration)
    lib.notify({
        title = '貨物輸送',
        description = message,
        type = type or 'info',
        duration = duration or Config.UI.notificationDuration
    })
end

-- ============================================
-- リソース停止時のクリーンアップ
-- ============================================
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if spawnedNPC and DoesEntityExist(spawnedNPC) then
        DeleteEntity(spawnedNPC)
    end
    
    CleanupJob()
end)