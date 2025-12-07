local QBCore = exports['qb-core']:GetCoreObject()
local missionActive = false
local missionVehicle = nil
local vipPed = nil
local missionBlip = nil
local startTime = nil
local missionStage = 0 -- 0: なし, 1: 目的地へ, 2: 帰還中
local selectedVehicle = nil -- 選択された車両を保存

-- NPC生成
CreateThread(function()
    local npcModel = Config.NPC.model
    RequestModel(npcModel)
    while not HasModelLoaded(npcModel) do
        Wait(100)
    end
    
    local npc = CreatePed(4, npcModel, Config.NPC.coords.x, Config.NPC.coords.y, Config.NPC.coords.z - 1.0, Config.NPC.coords.w, false, true)
    FreezeEntityPosition(npc, true)
    SetEntityInvincible(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    TaskStartScenarioInPlace(npc, Config.NPC.scenario, 0, true)
    
    -- Blip作成
    if Config.Blip.enabled then
        local blip = AddBlipForCoord(Config.NPC.coords.x, Config.NPC.coords.y, Config.NPC.coords.z)
        SetBlipSprite(blip, Config.Blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.Blip.scale)
        SetBlipColour(blip, Config.Blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.Blip.label)
        EndTextCommandSetBlipName(blip)
    end
    
    -- ox_target の代わりに ox_lib の points を使用
    local point = lib.points.new({
        coords = vec3(Config.NPC.coords.x, Config.NPC.coords.y, Config.NPC.coords.z),
        distance = 2.5,
    })
    
    function point:onEnter()
        if not missionActive then
            lib.showTextUI('[E] VIP輸送ミッション', {
                position = Config.UI.position,
                icon = Config.UI.icon
            })
        end
    end
    
    function point:onExit()
        lib.hideTextUI()
    end
    
    function point:nearby()
        if not missionActive and IsControlJustReleased(0, 38) then -- E key
            OpenMissionMenu()
        end
    end
end)

-- ミッションメニュー
function OpenMissionMenu()
    local options = {}
    
    for i, vehicle in ipairs(Config.Vehicles) do
        table.insert(options, {
            title = vehicle.label,
            description = '無料',
            icon = 'helicopter',
            onSelect = function()
                selectedVehicle = vehicle.spawn
                TriggerServerEvent('ng-viptransport:requestMission')
            end
        })
    end
    
    lib.registerContext({
        id = 'vip_transport_menu',
        title = 'VIP輸送サービス',
        options = options
    })
    
    lib.showContext('vip_transport_menu')
end

-- ミッション開始（サーバーからの許可後に実行）
RegisterNetEvent('ng-viptransport:startMission', function()
    if not selectedVehicle then return end
    
    local vehicleModel = selectedVehicle
    selectedVehicle = nil
    
    lib.hideTextUI()
    
    -- 車両スポーン
    RequestModel(vehicleModel)
    while not HasModelLoaded(vehicleModel) do
        Wait(100)
    end
    
    local spawnCoords = Config.Locations.start.spawnPoint
    missionVehicle = CreateVehicle(vehicleModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w, true, false)
    SetEntityAsMissionEntity(missionVehicle, true, true)
    SetVehicleEngineOn(missionVehicle, true, true, false)
    
    -- 車両に乗り込む
    TaskWarpPedIntoVehicle(PlayerPedId(), missionVehicle, -1)
    
    missionActive = true
    missionStage = 1
    startTime = GetGameTimer()
    
    -- 通知
    lib.notify(Config.Notifications.missionStart)
    
    -- 目的地のBlip作成
    CreateDestinationBlip()
    
    -- タイマー開始
    CreateThread(TimerThread)
    
    -- 車両破壊チェック
    CreateThread(VehicleCheckThread)
    
    -- マーカー表示
    CreateThread(MarkerThread)
end)

-- 目的地Blip作成
function CreateDestinationBlip()
    if missionBlip then
        RemoveBlip(missionBlip)
    end
    
    local coords = Config.Locations.destination.coords
    missionBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(missionBlip, 94)
    SetBlipDisplay(missionBlip, 4)
    SetBlipScale(missionBlip, 1.0)
    SetBlipColour(missionBlip, 2)
    SetBlipRoute(missionBlip, true)
    SetBlipRouteColour(missionBlip, 2)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Locations.destination.label)
    EndTextCommandSetBlipName(missionBlip)
end

-- 帰還Blip作成
function CreateReturnBlip()
    if missionBlip then
        RemoveBlip(missionBlip)
    end
    
    local coords = Config.Locations.start.coords
    missionBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(missionBlip, 94)
    SetBlipDisplay(missionBlip, 4)
    SetBlipScale(missionBlip, 1.0)
    SetBlipColour(missionBlip, 47)
    SetBlipRoute(missionBlip, true)
    SetBlipRouteColour(missionBlip, 47)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Locations.start.label)
    EndTextCommandSetBlipName(missionBlip)
end

-- タイマースレッド
function TimerThread()
    while missionActive do
        Wait(1000)
        
        if not startTime then
            break
        end
        
        local elapsed = (GetGameTimer() - startTime) / 1000
        local remaining = Config.TimeLimit - elapsed
        
        if remaining <= 0 then
            FailMission('time')
            break
        end
        
        -- UI表示
        local minutes = math.floor(remaining / 60)
        local seconds = math.floor(remaining % 60)
        local timeText = string.format("残り時間: %02d:%02d", minutes, seconds)
        
        -- ステージ表示
        local stageText = ""
        if missionStage == 1 then
            stageText = "目的: サンディ飛行場へ向かう"
        elseif missionStage == 2 then
            stageText = "目的: LS国際空港へ帰還"
        end
        
        lib.showTextUI(timeText .. '\n' .. stageText, {
            position = 'right-center',
            icon = 'clock'
        })
    end
    
    lib.hideTextUI()
end

-- 車両チェックスレッド
function VehicleCheckThread()
    while missionActive do
        Wait(1000)
        
        if not DoesEntityExist(missionVehicle) or IsEntityDead(missionVehicle) then
            FailMission('vehicle')
            break
        end
    end
end

-- マーカースレッド
function MarkerThread()
    while missionActive do
        Wait(0)
        
        local playerCoords = GetEntityCoords(PlayerPedId())
        
        if missionStage == 1 then
            -- 目的地マーカー
            local destCoords = Config.Locations.destination.landingZone
            local distance = #(playerCoords - destCoords)
            
            DrawMarker(
                Config.Markers.destination.type,
                destCoords.x, destCoords.y, destCoords.z,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                Config.Markers.destination.scale.x,
                Config.Markers.destination.scale.y,
                Config.Markers.destination.scale.z,
                Config.Markers.destination.color.r,
                Config.Markers.destination.color.g,
                Config.Markers.destination.color.b,
                Config.Markers.destination.color.a,
                false, true, 2, false, nil, nil, false
            )
            
            -- 着陸判定
            if distance < 15.0 and GetEntityHeightAboveGround(missionVehicle) < 3.0 then
                SpawnVIP()
            end
            
        elseif missionStage == 2 then
            -- 帰還マーカー
            local returnCoords = Config.Locations.start.coords
            local distance = #(playerCoords - returnCoords)
            
            DrawMarker(
                Config.Markers.returnPoint.type,
                returnCoords.x, returnCoords.y, returnCoords.z,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                Config.Markers.returnPoint.scale.x,
                Config.Markers.returnPoint.scale.y,
                Config.Markers.returnPoint.scale.z,
                Config.Markers.returnPoint.color.r,
                Config.Markers.returnPoint.color.g,
                Config.Markers.returnPoint.color.b,
                Config.Markers.returnPoint.color.a,
                false, true, 2, false, nil, nil, false
            )
            
            -- 着陸判定
            if distance < 15.0 and GetEntityHeightAboveGround(missionVehicle) < 3.0 then
                CompleteMission()
            end
        end
    end
end

-- VIP生成
function SpawnVIP()
    if missionStage ~= 1 then return end
    
    missionStage = 0
    
    local vipModel = Config.VIP.model
    RequestModel(vipModel)
    while not HasModelLoaded(vipModel) do
        Wait(100)
    end
    
    local spawnCoords = Config.Locations.destination.landingZone
    vipPed = CreatePed(4, vipModel, spawnCoords.x + 5.0, spawnCoords.y, spawnCoords.z, 0.0, true, false)
    SetEntityAsMissionEntity(vipPed, true, true)
    
    Wait(1000)
    
    -- VIPを車両に乗せる
    local seats = GetVehicleMaxNumberOfPassengers(missionVehicle)
    TaskEnterVehicle(vipPed, missionVehicle, 10000, seats - 1, 1.0, 1, 0)
    
    Wait(5000)
    
    -- 通知
    lib.notify(Config.Notifications.vipPickedUp)
    
    missionStage = 2
    CreateReturnBlip()
end

-- ミッション完了
function CompleteMission()
    if not missionActive then return end
    
    missionActive = false
    lib.hideTextUI()
    
    -- 経過時間計算
    local elapsed = (GetGameTimer() - startTime) / 1000
    
    -- サーバーに通知
    TriggerServerEvent('ng-viptransport:completeMission', elapsed)
    
    -- クリーンアップ
    CleanupMission()
end

-- ミッション失敗
function FailMission(reason)
    if not missionActive then return end
    
    missionActive = false
    lib.hideTextUI()
    
    -- サーバーに失敗を通知
    TriggerServerEvent('ng-viptransport:failMission')
    
    if reason == 'vehicle' then
        lib.notify(Config.Notifications.vehicleDestroyed)
    elseif reason == 'time' then
        lib.notify(Config.Notifications.timeUp)
    else
        lib.notify(Config.Notifications.missionFailed)
    end
    
    CleanupMission()
end

-- ミッションキャンセルコマンド
RegisterCommand('cancelvip', function()
    if not missionActive then
        lib.notify({
            title = 'エラー',
            description = 'ミッションを実行していません',
            type = 'error'
        })
        return
    end
    
    -- 確認ダイアログ
    local alert = lib.alertDialog({
        header = 'ミッションキャンセル',
        content = '本当にミッションをキャンセルしますか？\n報酬は受け取れません。',
        centered = true,
        cancel = true,
        labels = {
            confirm = 'はい',
            cancel = 'いいえ'
        }
    })
    
    if alert == 'confirm' then
        CancelMission()
    end
end, false)

-- ミッションキャンセル処理
function CancelMission()
    if not missionActive then return end
    
    missionActive = false
    lib.hideTextUI()
    
    -- サーバーに通知
    TriggerServerEvent('ng-viptransport:cancelMission')
    
    -- 通知
    lib.notify({
        title = 'ミッションキャンセル',
        description = 'ミッションをキャンセルしました',
        type = 'info'
    })
    
    -- クリーンアップ
    CleanupMission()
end

-- クリーンアップ
function CleanupMission()
    if DoesEntityExist(missionVehicle) then
        DeleteEntity(missionVehicle)
    end
    
    if DoesEntityExist(vipPed) then
        DeleteEntity(vipPed)
    end
    
    if missionBlip then
        RemoveBlip(missionBlip)
        missionBlip = nil
    end
    
    missionVehicle = nil
    vipPed = nil
    missionStage = 0
    startTime = nil
end

-- リソース停止時のクリーンアップ
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    CleanupMission()
    lib.hideTextUI()
end)