local QBCore = exports['qb-core']:GetCoreObject()
local currentVehicle = nil
local isInVehicle = false

-- 制限対象外の車両クラスかどうかをチェック
local function isExemptVehicle(vehicle)
    if not DoesEntityExist(vehicle) then return false end
    
    local vehicleClass = GetVehicleClass(vehicle)
    return Config.ExemptVehicleClasses[vehicleClass] or false
end

-- 緊急車両かどうかをチェック
local function isEmergencyVehicle(vehicle)
    if not DoesEntityExist(vehicle) then return false end
    
    local vehicleClass = GetVehicleClass(vehicle)
    return Config.EmergencyVehicleClasses[vehicleClass] or false
end

-- 速度制限を取得
local function getSpeedLimit(vehicle)
    if isEmergencyVehicle(vehicle) then
        return Config.SpeedLimit.Emergency
    else
        return Config.SpeedLimit.Normal
    end
end

-- 速度制限通知
local function notifySpeedLimit(speedLimit)
    if Config.Notification.Enabled then
        lib.notify({
            title = '速度制限',
            description = string.format('この車両の速度制限は %d km/h です', speedLimit),
            type = 'info',
            position = Config.Notification.Position,
            duration = Config.Notification.Duration
        })
    end
end

-- 速度制限を適用
local function applySpeedLimit(vehicle, speedLimit)
    if not DoesEntityExist(vehicle) then return end
    
    -- km/h を m/s に変換してゲーム内速度に設定
    local maxSpeed = (speedLimit / 3.6)
    SetVehicleMaxSpeed(vehicle, maxSpeed)
    
    if Config.Debug then
        print(string.format('[DEBUG] Speed limit applied: %d km/h (%.2f m/s)', speedLimit, maxSpeed))
    end
end

-- 車両に乗った時の処理
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        
        if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
            if not isInVehicle or currentVehicle ~= vehicle then
                isInVehicle = true
                currentVehicle = vehicle
                
                -- 制限対象外の車両はスキップ
                if not isExemptVehicle(vehicle) then
                    local speedLimit = getSpeedLimit(vehicle)
                    applySpeedLimit(vehicle, speedLimit)
                    notifySpeedLimit(speedLimit)
                else
                    if Config.Debug then
                        local vehicleClass = GetVehicleClass(vehicle)
                        print(string.format('[DEBUG] Exempt vehicle detected (Class: %d) - No speed limit applied', vehicleClass))
                    end
                end
            end
        else
            if isInVehicle then
                isInVehicle = false
                currentVehicle = nil
            end
        end
        
        Wait(500)
    end
end)

-- 速度制限を常に監視
CreateThread(function()
    while true do
        if isInVehicle and currentVehicle and DoesEntityExist(currentVehicle) then
            -- 制限対象外の車両はスキップ
            if not isExemptVehicle(currentVehicle) then
                local speedLimit = getSpeedLimit(currentVehicle)
                applySpeedLimit(currentVehicle, speedLimit)
            end
        end
        
        Wait(1000)
    end
end)
