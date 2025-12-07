local QBCore = exports['qb-core']:GetCoreObject()

-- ============================================
-- グローバル変数
-- ============================================

local spawnedVehicles = {}  -- cardId -> vehicleEntity

-- ============================================
-- ユーティリティ関数
-- ============================================

-- 管理者権限チェック関数
local function isAdmin()
    return lib.callback.await('ng-vehiclecard:server:isAdmin', false)
end

-- プレイヤーの前方座標を取得
local function GetForwardCoords(distance)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local x = coords.x + math.sin(math.rad(-heading)) * distance
    local y = coords.y + math.cos(math.rad(-heading)) * distance
    return vector3(x, y, coords.z)
end

-- スポーン位置の障害物チェック
local function IsSpawnPointClear(coords, radius)
    local vehicles = GetGamePool('CVehicle')
    
    for _, vehicle in ipairs(vehicles) do
        local vehCoords = GetEntityCoords(vehicle)
        local distance = #(coords - vehCoords)
        
        if distance < radius then
            return false
        end
    end
    
    return true
end

-- 地面の高さを取得
local function GetGroundZ(x, y, z)
    local _, groundZ = GetGroundZFor_3dCoord(x, y, z, false)
    return groundZ
end

-- ============================================
-- 車両スポーン処理
-- ============================================

local function spawnVehicleCard(itemSlot, itemData)
    local metadata = itemData.metadata
    if not metadata or not metadata.vehicle then
        lib.notify({
            title = 'エラー',
            description = Locale.error_general,
            type = 'error'
        })
        return
    end
    
    local vehicleModel = metadata.vehicle
    local cardId = metadata.cardId
    
    -- 既にスポーン済みの場合は格納処理
    if cardId and spawnedVehicles[cardId] then
        storeVehicleCard(cardId)
        return
    end
    
    -- スポーン位置を計算
    local spawnCoords = GetForwardCoords(Config.SpawnDistance)
    spawnCoords = vector3(spawnCoords.x, spawnCoords.y, GetGroundZ(spawnCoords.x, spawnCoords.y, spawnCoords.z + 5.0))
    
    -- 障害物チェック
    if not IsSpawnPointClear(spawnCoords, 3.0) then
        lib.notify({
            title = 'エラー',
            description = Locale.no_space,
            type = 'error'
        })
        return
    end
    
    -- サーバー側でスポーン処理
    local success, message, returnedCardId = lib.callback.await('ng-vehiclecard:server:spawnVehicle', false, itemSlot, itemData)
    
    if not success then
        lib.notify({
            title = 'エラー',
            description = Locale[message] or Locale.error_spawn,
            type = 'error'
        })
        return
    end
    
    -- 車両モデルをロード
    local modelHash = GetHashKey(vehicleModel)
    RequestModel(modelHash)
    
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 5000 do
        Wait(100)
        timeout = timeout + 100
    end
    
    if not HasModelLoaded(modelHash) then
        lib.notify({
            title = 'エラー',
            description = Locale.error_spawn,
            type = 'error'
        })
        return
    end
    
    -- 車両をスポーン
    local playerPed = PlayerPedId()
    local heading = GetEntityHeading(playerPed)
    
    local vehicle = CreateVehicle(modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, heading, true, false)
    
    if not DoesEntityExist(vehicle) then
        lib.notify({
            title = 'エラー',
            description = Locale.error_spawn,
            type = 'error'
        })
        SetModelAsNoLongerNeeded(modelHash)
        return
    end
    
    -- 車両の初期設定
    SetVehicleOnGroundProperly(vehicle)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehRadioStation(vehicle, 'OFF')
    SetVehicleEngineOn(vehicle, false, false, true)
    
    -- 車両キーを付与
    local plate = GetVehicleNumberPlateText(vehicle)
    TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plate)
    
    -- スポーン情報を保存
    spawnedVehicles[returnedCardId] = vehicle
    
    -- モデルのクリーンアップ
    SetModelAsNoLongerNeeded(modelHash)
    
    -- 通知
    lib.notify({
        title = 'システム',
        description = Locale.vehicle_spawned,
        type = 'success'
    })
end

-- ============================================
-- 車両格納処理
-- ============================================

function storeVehicleCard(cardId)
    local vehicle = spawnedVehicles[cardId]
    
    if not vehicle or not DoesEntityExist(vehicle) then
        lib.notify({
            title = 'エラー',
            description = Locale.no_vehicle_nearby,
            type = 'error'
        })
        spawnedVehicles[cardId] = nil
        return
    end
    
    -- 距離チェック
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local vehicleCoords = GetEntityCoords(vehicle)
    local distance = #(playerCoords - vehicleCoords)
    
    if distance > Config.StoreDistance then
        lib.notify({
            title = 'エラー',
            description = Locale.too_far,
            type = 'error'
        })
        return
    end
    
    -- サーバー側で格納処理
    local vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)
    local success, message = lib.callback.await('ng-vehiclecard:server:storeVehicle', false, vehicleNetId, cardId)
    
    if not success then
        lib.notify({
            title = 'エラー',
            description = Locale[message] or Locale.error_store,
            type = 'error'
        })
        return
    end
    
    -- 車両を削除
    SetEntityAsMissionEntity(vehicle, false, true)
    DeleteEntity(vehicle)
    
    -- スポーン情報を削除
    spawnedVehicles[cardId] = nil
    
    -- 通知
    lib.notify({
        title = 'システム',
        description = Locale.vehicle_stored,
        type = 'success'
    })
end

-- ============================================
-- アイテム使用イベント
-- ============================================

RegisterNetEvent('ng-vehiclecard:client:useVehicleCard', function(itemSlot, itemData)
    spawnVehicleCard(itemSlot, itemData)
end)

-- ============================================
-- 自動デスポーン関連
-- ============================================

-- 車両との距離チェック
RegisterNetEvent('ng-vehiclecard:client:checkVehicleDistance', function(cardId, maxDistance)
    local vehicle = spawnedVehicles[cardId]
    
    if not vehicle or not DoesEntityExist(vehicle) then
        TriggerServerEvent('ng-vehiclecard:server:autoDespawn', cardId)
        spawnedVehicles[cardId] = nil
        return
    end
    
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local vehicleCoords = GetEntityCoords(vehicle)
    local distance = #(playerCoords - vehicleCoords)
    
    -- 距離が離れすぎている場合
    if distance > maxDistance then
        TriggerServerEvent('ng-vehiclecard:server:autoDespawn', cardId)
    end
end)

-- 車両デスポーン実行
RegisterNetEvent('ng-vehiclecard:client:despawnVehicle', function(cardId)
    local vehicle = spawnedVehicles[cardId]
    
    if vehicle and DoesEntityExist(vehicle) then
        SetEntityAsMissionEntity(vehicle, false, true)
        DeleteEntity(vehicle)
    end
    
    spawnedVehicles[cardId] = nil
end)

-- ============================================
-- リソース停止時のクリーンアップ
-- ============================================

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- スポーン済み車両を全て削除
    for cardId, vehicle in pairs(spawnedVehicles) do
        if DoesEntityExist(vehicle) then
            SetEntityAsMissionEntity(vehicle, false, true)
            DeleteEntity(vehicle)
        end
    end
    
    spawnedVehicles = {}
end)

print('^2[ng-vehiclecard]^7 Client script loaded successfully')
