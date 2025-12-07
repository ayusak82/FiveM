local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = QBCore.Functions.GetPlayerData()

-- ローカル変数
local vehicleNitroData = {}
local isNitroActive = false
local nitroCooldown = false
local currentVehicle = nil
local lastNotificationTime = 0

-- プレート番号クリーンアップ関数
local function CleanPlate(plate)
    return string.gsub(plate or "", '%s+', '')
end

-- プレイヤーデータ更新
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    PlayerData = val
end)

-- ニトロデータ受信
RegisterNetEvent('ng-nitro:client:setNitroData')
AddEventHandler('ng-nitro:client:setNitroData', function(plate, data)
    vehicleNitroData[plate] = data
    
    if Config.Debug then
        print(('[ng-nitro] クライアント - ニトロデータ受信: プレート=%s, hasKit=%s, tanks=%s'):format(
            plate, 
            data.hasKit and 'true' or 'false', 
            data.tanks or 'nil'
        ))
    end
    
    if Config.UI.showNotifications then
        lib.notify({
            title = 'ニトロシステム',
            description = 'ニトロデータが更新されました',
            type = 'success'
        })
    end
end)

-- ニトロ削除通知
RegisterNetEvent('ng-nitro:client:removeNitroData', function(plate)
    vehicleNitroData[plate] = nil
    if Config.UI.showNotifications then
        lib.notify({
            title = 'ニトロシステム',
            description = 'ニトロが削除されました',
            type = 'inform'
        })
    end
end)

-- ニトロブースト実行（エフェクト削除済み）
local function ActivateNitro()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if not vehicle or vehicle == 0 then return end
    if GetPedInVehicleSeat(vehicle, -1) ~= ped then return end
    if isNitroActive or nitroCooldown then return end
    
    local plate = CleanPlate(GetVehicleNumberPlateText(vehicle))
    local nitroData = vehicleNitroData[plate]
    local currentTime = GetGameTimer()
    
    if Config.Debug then
        print(('[ng-nitro] ニトロ発動試行 - プレート: "%s", データ存在: %s'):format(
            plate, 
            nitroData and 'true' or 'false'
        ))
    end
    
    -- 通知制限機能
    local function showNotification(message, type)
        if Config.UI.showNotifications and (currentTime - lastNotificationTime) >= Config.UI.notificationCooldown then
            lib.notify({
                title = 'ニトロシステム',
                description = message,
                type = type
            })
            lastNotificationTime = currentTime
        end
    end
    
    if not nitroData or not nitroData.hasKit then
        showNotification('この車両にはニトロキットが取り付けられていません', 'error')
        return
    end
    
    if nitroData.tanks <= 0 then
        showNotification('ニトロタンクが空です', 'error')
        return
    end
    
    -- ニトロ発動
    isNitroActive = true
    
    -- 車両にブースト力を適用
    local forwardVector = GetEntityForwardVector(vehicle)
    local force = vector3(
        forwardVector.x * Config.Nitro.boostForce,
        forwardVector.y * Config.Nitro.boostForce,
        forwardVector.z * Config.Nitro.boostForce * 0.1
    )
    
    ApplyForceToEntity(vehicle, 1, force.x, force.y, force.z, 0.0, 0.0, 0.0, 0, 0, 1, 1, 0, 1)
    
    -- サーバーにタンク消費を通知
    TriggerServerEvent('ng-nitro:server:useTank', plate)
    
    -- ブースト持続時間後に停止
    SetTimeout(Config.Nitro.boostDuration, function()
        isNitroActive = false
        
        -- クールダウン開始
        nitroCooldown = true
        SetTimeout(Config.Nitro.boostCooldown, function()
            nitroCooldown = false
        end)
    end)
end

-- キー入力処理と車両乗車監視
CreateThread(function()
    local lastVehicle = nil
    local isShiftPressed = false
    
    while true do
        Wait(0)
        
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        
        if vehicle and vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
            -- 新しい車両に乗った場合、ニトロデータを要求
            if vehicle ~= lastVehicle then
                local plate = CleanPlate(GetVehicleNumberPlateText(vehicle))
                TriggerServerEvent('ng-nitro:server:requestNitroData', plate)
                lastVehicle = vehicle
                
                if Config.Debug then
                    print(('[ng-nitro] 新しい車両に乗車 - プレート: "%s", データ要求送信'):format(plate))
                end
            end
            
            currentVehicle = vehicle
            
            -- 左シフトキー監視（キーが押された瞬間のみ実行）
            if IsControlPressed(0, 21) then -- Left Shift
                if not isShiftPressed then
                    isShiftPressed = true
                    ActivateNitro()
                end
            else
                isShiftPressed = false
            end
        else
            if lastVehicle then
                lastVehicle = nil
            end
            currentVehicle = nil
            isShiftPressed = false
        end
    end
end)

-- HUD表示
CreateThread(function()
    while true do
        Wait(1000)
        
        if Config.UI.showHUD and currentVehicle then
            local plate = GetVehicleNumberPlateText(currentVehicle):gsub('%s+', '')
            local nitroData = vehicleNitroData[plate]
            
            if nitroData and nitroData.hasKit then
                local hudData = {
                    tanks = nitroData.tanks,
                    maxTanks = Config.Nitro.maxTanks,
                    cooldown = nitroCooldown,
                    active = isNitroActive
                }
                
                SendNUIMessage({
                    type = 'updateNitroHUD',
                    data = hudData
                })
            end
        end
    end
end)

-- 車両退出時のクリーンアップ
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        -- エフェクト関連の処理は削除済み
    end
end)

-- デバッグ用コマンド（クライアント側データ確認）
RegisterCommand('debugnitro', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle and vehicle ~= 0 then
        local plate = CleanPlate(GetVehicleNumberPlateText(vehicle))
        local nitroData = vehicleNitroData[plate]
        
        print(('[ng-nitro] デバッグ - 現在の車両プレート: "%s"'):format(plate))
        print(('[ng-nitro] デバッグ - ニトロデータ存在: %s'):format(nitroData and 'true' or 'false'))
        
        if nitroData then
            print(('[ng-nitro] デバッグ - hasKit: %s, tanks: %s'):format(
                nitroData.hasKit and 'true' or 'false',
                nitroData.tanks or 'nil'
            ))
        end
        
        -- 全データを表示
        local count = 0
        for storedPlate, storedData in pairs(vehicleNitroData) do
            count = count + 1
            print(('[ng-nitro] デバッグ - 保存データ[%d]: プレート="%s", hasKit=%s, tanks=%s'):format(
                count,
                storedPlate,
                storedData.hasKit and 'true' or 'false',
                storedData.tanks or 'nil'
            ))
        end
        print(('[ng-nitro] デバッグ - 保存されているデータ総数: %d'):format(count))
    else
        print('[ng-nitro] デバッグ - 車両に乗っていません')
    end
end, false)

-- テーブル長さ取得用関数
function table.length(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end