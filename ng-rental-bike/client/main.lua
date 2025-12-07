local QBCore = exports['qb-core']:GetCoreObject()

-- プレイヤーの状態管理
local currentRentalBike = nil
local dismountTimer = nil
local rentalZones = {}
local isInVehicle = false

-- 通知表示関数
local function ShowNotification(message, type)
    lib.notify({
        description = message,
        type = type or 'info',
        position = 'top'
    })
end

-- 3Dテキスト描画関数
local function Draw3DText(coords, text)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z)
    local camCoords = GetGameplayCamCoords()
    local dist = #(camCoords - coords)
    
    local scale = (1 / dist) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov * Config.TextScale
    
    if onScreen then
        SetTextScale(0.0, scale)
        SetTextFont(Config.TextFont)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- マーカー描画関数
local function DrawMarker3D(coords)
    DrawMarker(
        Config.MarkerType,
        coords.x, coords.y, coords.z - 1.0,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        Config.MarkerSize.x, Config.MarkerSize.y, Config.MarkerSize.z,
        Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, Config.MarkerColor.a,
        Config.MarkerBobUpDown,
        false,
        2,
        false,
        nil,
        nil,
        false
    )
end

-- バイクモデルの読み込み
local function LoadModel(model)
    local modelHash = GetHashKey(model)
    
    if not IsModelInCdimage(modelHash) then
        if Config.Debug then
            print(('[ng-rental-bike] Model %s not found'):format(model))
        end
        return false
    end
    
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 10000 do
        Wait(100)
        timeout = timeout + 100
    end
    
    if not HasModelLoaded(modelHash) then
        if Config.Debug then
            print(('[ng-rental-bike] Failed to load model %s'):format(model))
        end
        return false
    end
    
    return true
end

-- タイマーのキャンセル
local function CancelDismountTimer()
    if dismountTimer then
        dismountTimer = nil
        ShowNotification(Config.Notifications.timer_cancelled, 'success')
        if Config.Debug then
            print('[ng-rental-bike] Dismount timer cancelled')
        end
    end
end

-- 降車タイマーの開始
local function StartDismountTimer()
    if dismountTimer then return end
    
    ShowNotification(Config.Notifications.dismount_warning, 'info')
    
    local timerInstance = {}
    dismountTimer = timerInstance
    local startTime = GetGameTimer()
    
    CreateThread(function()
        while dismountTimer == timerInstance and currentRentalBike do
            Wait(1000)
            
            -- バイクが存在しない場合は終了
            if not DoesEntityExist(currentRentalBike) then
                currentRentalBike = nil
                dismountTimer = nil
                if Config.Debug then
                    print('[ng-rental-bike] Bike no longer exists, timer stopped')
                end
                break
            end
            
            local elapsedTime = (GetGameTimer() - startTime) / 1000
            
            if elapsedTime >= Config.DismountTimer then
                if currentRentalBike and DoesEntityExist(currentRentalBike) then
                    DeleteEntity(currentRentalBike)
                    ShowNotification(Config.Notifications.bike_deleted, 'error')
                    TriggerServerEvent('ng-rental-bike:server:removeRental')
                end
                currentRentalBike = nil
                dismountTimer = nil
                if Config.Debug then
                    print('[ng-rental-bike] Bike deleted after timer')
                end
                break
            end
        end
    end)
end

-- レンタルバイクの削除
local function DeleteRentalBike()
    if currentRentalBike and DoesEntityExist(currentRentalBike) then
        DeleteEntity(currentRentalBike)
        if Config.Debug then
            print('[ng-rental-bike] Rental bike deleted')
        end
    end
    currentRentalBike = nil
    dismountTimer = nil
    TriggerServerEvent('ng-rental-bike:server:removeRental')
end

-- バイクのレンタル
local function RentBike(bikeModel, spawnCoords)
    -- 既にレンタル中かチェック
    if currentRentalBike and DoesEntityExist(currentRentalBike) then
        ShowNotification(Config.Notifications.already_rented, 'error')
        return
    end
    
    -- モデルの読み込み
    if not LoadModel(bikeModel) then
        ShowNotification(Config.Notifications.rental_failed, 'error')
        return
    end
    
    -- バイクのスポーン
    local bike = CreateVehicle(
        GetHashKey(bikeModel),
        spawnCoords.x,
        spawnCoords.y,
        spawnCoords.z,
        spawnCoords.w,
        true,
        false
    )
    
    if not DoesEntityExist(bike) then
        ShowNotification(Config.Notifications.rental_failed, 'error')
        SetModelAsNoLongerNeeded(GetHashKey(bikeModel))
        return
    end
    
    -- バイクの設定
    SetVehicleHasBeenOwnedByPlayer(bike, true)
    SetEntityAsMissionEntity(bike, true, true)
    SetVehicleEngineOn(bike, true, true, false)
    SetVehicleOnGroundProperly(bike)
    
    -- プレイヤーを乗車させる
    local ped = PlayerPedId()
    TaskWarpPedIntoVehicle(ped, bike, -1)
    
    -- 状態の更新
    currentRentalBike = bike
    isInVehicle = true
    dismountTimer = nil
    local bikeNetId = NetworkGetNetworkIdFromEntity(bike)
    local plate = GetVehicleNumberPlateText(bike)
    
    -- サーバーにレンタル情報を送信（鍵の付与含む）
    TriggerServerEvent('ng-rental-bike:server:setRental', bikeNetId, plate)
    
    ShowNotification(Config.Notifications.rental_success, 'success')
    
    -- モデルのアンロード
    SetModelAsNoLongerNeeded(GetHashKey(bikeModel))
    
    if Config.Debug then
        print(('[ng-rental-bike] Bike spawned: %s (NetID: %s)'):format(bikeModel, bikeNetId))
    end
end

-- プレイヤーの乗車状態をチェック
CreateThread(function()
    while true do
        Wait(500) -- より頻繁にチェック
        
        if currentRentalBike then
            -- バイクが存在するかチェック
            if not DoesEntityExist(currentRentalBike) then
                if Config.Debug then
                    print('[ng-rental-bike] Rental bike entity no longer exists')
                end
                currentRentalBike = nil
                isInVehicle = false
                dismountTimer = nil
                TriggerServerEvent('ng-rental-bike:server:removeRental')
            else
                local ped = PlayerPedId()
                local vehicle = GetVehiclePedIsIn(ped, false)
                
                -- 現在レンタルバイクに乗っているか
                if vehicle == currentRentalBike then
                    if not isInVehicle then
                        isInVehicle = true
                        CancelDismountTimer()
                        if Config.Debug then
                            print('[ng-rental-bike] Player mounted rental bike')
                        end
                    end
                else
                    if isInVehicle then
                        isInVehicle = false
                        StartDismountTimer()
                        if Config.Debug then
                            print('[ng-rental-bike] Player dismounted from rental bike')
                        end
                    end
                end
            end
        else
            isInVehicle = false
            dismountTimer = nil
        end
    end
end)

-- レンタルゾーンの作成
local function CreateRentalZone(pointData)
    local zone = lib.zones.sphere({
        coords = pointData.coords,
        radius = pointData.radius,
        debug = Config.Debug,
        onExit = function()
            lib.hideTextUI()
        end,
        inside = function()
            if IsControlJustPressed(0, 38) then -- E key
                lib.hideTextUI()
                RentBike(pointData.bikeModel, pointData.spawnCoords)
            end
        end
    })
    
    -- マーカーと3Dテキストの描画スレッドを作成
    CreateThread(function()
        while true do
            Wait(0)
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - pointData.coords)
            
            -- 描画距離内の場合のみ描画
            if distance < 50.0 then
                -- マーカーを描画
                if Config.ShowMarker then
                    DrawMarker3D(pointData.coords)
                end
                
                -- 3Dテキストを描画
                if Config.Show3DText then
                    Draw3DText(pointData.coords, "🚲 レンタルバイク\n~b~[E]~w~ で借りる")
                end
            end
        end
    end)
    
    return zone
end

-- すべてのレンタルゾーンを初期化
local function InitializeZones()
    for i, point in ipairs(Config.RentalPoints) do
        local zone = CreateRentalZone(point)
        table.insert(rentalZones, zone)
        if Config.Debug then
            print(('[ng-rental-bike] Zone created: %s'):format(point.name))
        end
    end
end

-- 切断されたプレイヤーのバイクを削除
RegisterNetEvent('ng-rental-bike:client:deleteDisconnectedBike', function(bikeNetId)
    local bike = NetworkGetEntityFromNetworkId(bikeNetId)
    if DoesEntityExist(bike) then
        DeleteEntity(bike)
        if Config.Debug then
            print(('[ng-rental-bike] Deleted disconnected player bike (NetID: %s)'):format(bikeNetId))
        end
    end
end)

-- QBCore プレイヤーアンロード時のクリーンアップ
RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    DeleteRentalBike()
    if Config.Debug then
        print('[ng-rental-bike] Player unloaded, rental bike deleted')
    end
end)

-- リソース停止時のクリーンアップ
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- レンタルバイクの削除
    DeleteRentalBike()
    
    -- すべてのゾーンを削除
    for _, zone in ipairs(rentalZones) do
        zone:remove()
    end
    rentalZones = {}
    
    -- TextUIを非表示
    lib.hideTextUI()
    
    if Config.Debug then
        print('[ng-rental-bike] Resource stopped, cleanup complete')
    end
end)

-- リソース開始時の初期化
CreateThread(function()
    InitializeZones()
    if Config.Debug then
        print('[ng-rental-bike] Client initialized')
    end
end)
