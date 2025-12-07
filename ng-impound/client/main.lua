local QBCore = exports['qb-core']:GetCoreObject()

-- 権限チェック関数
local function hasPermission()
    if not Config.Command.jobRestricted then
        return true
    end
    
    local PlayerData = QBCore.Functions.GetPlayerData()
    if not PlayerData.job then
        return false
    end
    
    for _, job in pairs(Config.Command.allowedJobs) do
        if PlayerData.job.name == job then
            return true
        end
    end
    
    return false
end

-- 最寄りの車両を取得する関数
local function getClosestVehicle()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local vehicles = GetGamePool('CVehicle')
    local closestVehicle = nil
    local closestDistance = Config.Vehicle.searchRadius
    
    for _, vehicle in pairs(vehicles) do
        local vehicleCoords = GetEntityCoords(vehicle)
        local distance = #(playerCoords - vehicleCoords)
        
        if distance < closestDistance then
            closestVehicle = vehicle
            closestDistance = distance
        end
    end
    
    return closestVehicle, closestDistance
end

-- 車両が乗車中かチェックする関数
local function isVehicleOccupied(vehicle)
    local maxSeats = GetVehicleMaxNumberOfPassengers(vehicle)
    
    -- ドライバー席をチェック
    if GetPedInVehicleSeat(vehicle, -1) ~= 0 then
        return true
    end
    
    -- 乗客席をチェック
    for i = 0, maxSeats - 1 do
        if GetPedInVehicleSeat(vehicle, i) ~= 0 then
            return true
        end
    end
    
    return false
end

-- 緊急車両かチェックする関数
local function isEmergencyVehicle(vehicle)
    local vehicleClass = GetVehicleClass(vehicle)
    -- クラス18は緊急車両
    return vehicleClass == 18
end

-- 車両をインパウンドする関数
local function impoundVehicle()
    if Config.Debug then
        print('[ng-impound] インパウンドコマンド実行開始')
    end
    
    -- 権限チェック
    if not hasPermission() then
        lib.notify({
            title = Config.Notifications.noPermission.title,
            description = Config.Notifications.noPermission.description,
            type = Config.Notifications.noPermission.type,
            duration = Config.Notifications.noPermission.duration
        })
        return
    end
    
    -- 最寄りの車両を取得
    local vehicle, distance = getClosestVehicle()
    
    if not vehicle then
        lib.notify({
            title = Config.Notifications.noVehicle.title,
            description = Config.Notifications.noVehicle.description,
            type = Config.Notifications.noVehicle.type,
            duration = Config.Notifications.noVehicle.duration
        })
        return
    end
    
    if Config.Debug then
        print(string.format('[ng-impound] 車両発見: %s (距離: %.2fm)', GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)), distance))
    end
    
    -- 乗車中チェック
    if not Config.Vehicle.allowOccupied and isVehicleOccupied(vehicle) then
        lib.notify({
            title = Config.Notifications.occupied.title,
            description = Config.Notifications.occupied.description,
            type = Config.Notifications.occupied.type,
            duration = Config.Notifications.occupied.duration
        })
        return
    end
    
    -- 緊急車両チェック（設定で除外する場合）
    if Config.Vehicle.excludeEmergency and isEmergencyVehicle(vehicle) then
        lib.notify({
            title = Config.Notifications.emergencyVehicle.title,
            description = Config.Notifications.emergencyVehicle.description,
            type = Config.Notifications.emergencyVehicle.type,
            duration = Config.Notifications.emergencyVehicle.duration
        })
        return
    end
    
    -- 車両情報を取得
    local plate = GetVehicleNumberPlateText(vehicle):gsub("%s+", "")
    local model = GetEntityModel(vehicle)
    local modelName = GetDisplayNameFromVehicleModel(model)
    local vehicleCoords = GetEntityCoords(vehicle)
    local vehicleHeading = GetEntityHeading(vehicle)
    
    if Config.Debug then
        print(string.format('[ng-impound] 車両プレート: %s, モデル: %s', plate, modelName))
    end
    
    -- サーバーに車両インパウンドを要求
    TriggerServerEvent('ng-impound:server:impoundVehicle', {
        plate = plate,
        model = model,
        modelName = modelName,
        coords = vehicleCoords,
        heading = vehicleHeading,
        netId = NetworkGetNetworkIdFromEntity(vehicle)
    })
end

-- コマンド登録
RegisterCommand(Config.Command.name, function()
    impoundVehicle()
end, false)

-- サーバーからの車両削除要求を受信
RegisterNetEvent('ng-impound:client:deleteVehicle', function(netId)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    
    if DoesEntityExist(vehicle) then
        if Config.Debug then
            print(string.format('[ng-impound] 車両削除: NetID %d', netId))
        end
        
        -- 車両を削除
        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteEntity(vehicle)
        
        -- 成功通知
        lib.notify({
            title = Config.Notifications.success.title,
            description = Config.Notifications.success.description,
            type = Config.Notifications.success.type,
            duration = Config.Notifications.success.duration
        })
    end
end)

-- プレイヤーデータ更新時の処理
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    if Config.Debug then
        print('[ng-impound] プレイヤーロード完了')
    end
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    if Config.Debug then
        print(string.format('[ng-impound] 職業更新: %s', JobInfo.name))
    end
end)