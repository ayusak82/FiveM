local QBCore = exports['qb-core']:GetCoreObject()
local isThermalActive = false
local isChecking = false

-- サーマルビジョンの切り替え
local function ToggleThermalVision(debugMode)
    isThermalActive = not isThermalActive
    
    if isThermalActive then
        SetSeethrough(true)
        
        -- サーバーに状態を送信
        TriggerServerEvent('ng-thermalvision:server:updateStatus', true)
        
        if debugMode then
            lib.notify(Config.Notifications.debugEnabled)
        else
            lib.notify(Config.Notifications.enabled)
        end
    else
        SetSeethrough(false)
        
        -- サーバーに状態を送信
        TriggerServerEvent('ng-thermalvision:server:updateStatus', false)
        
        if debugMode then
            lib.notify(Config.Notifications.debugDisabled)
        else
            lib.notify(Config.Notifications.disabled)
        end
    end
end

-- アイテム所持チェック（ox_inventory用）
local function HasThermalItemOx()
    if GetResourceState('ox_inventory') == 'started' then
        local hasItem = exports.ox_inventory:Search('count', Config.ThermalItem)
        return hasItem > 0
    end
    return false
end

-- アイテム所持チェック（qb-core用）
local function HasThermalItemQB()
    local Player = QBCore.Functions.GetPlayerData()
    if Player and Player.items then
        for _, item in pairs(Player.items) do
            if item and item.name == Config.ThermalItem then
                return true
            end
        end
    end
    return false
end

-- 統合アイテムチェック
local function HasThermalItem()
    if GetResourceState('ox_inventory') == 'started' then
        return HasThermalItemOx()
    else
        return HasThermalItemQB()
    end
end

-- サーバーからのアイテム使用イベント（qb-inventory用）
RegisterNetEvent('ng-thermalvision:client:useItem', function()
    local hasItem = HasThermalItem()
    
    if not hasItem then
        lib.notify(Config.Notifications.noItem)
        return
    end
    
    ToggleThermalVision(false)
end)

-- ox_inventory用のexport
exports('useThermalGoggles', function(data, slot)
    local hasItem = HasThermalItem()
    
    if not hasItem then
        lib.notify(Config.Notifications.noItem)
        return
    end
    
    ToggleThermalVision(false)
end)

-- 自動オフ機能（アイテムを持っていない場合）
if Config.ThermalSettings.autoDisable then
    CreateThread(function()
        while true do
            Wait(2000)
            
            if isThermalActive and not isChecking then
                isChecking = true
                local hasItem = HasThermalItem()
                
                if not hasItem then
                    isThermalActive = false
                    SetSeethrough(false)
                    TriggerServerEvent('ng-thermalvision:server:updateStatus', false)
                    lib.notify(Config.Notifications.disabled)
                end
                
                isChecking = false
            end
        end
    end)
end

-- 3Dテキスト描画関数
local function Draw3DText(coords, text)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local dist = #(vector3(px, py, pz) - vector3(coords.x, coords.y, coords.z))
    
    local scale = (1 / dist) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov
    
    if onScreen then
        SetTextScale(0.0 * scale, 0.5 * scale)
        SetTextFont(0)
        SetTextProportional(1)
        SetTextColour(255, 0, 0, 215)
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

-- 他のプレイヤーのサーマル状態を保存
local activeThermalPlayers = {}

-- サーバーからサーマル状態を受信
RegisterNetEvent('ng-thermalvision:client:updatePlayerStatus', function(playerId, isActive)
    activeThermalPlayers[playerId] = isActive
end)

-- 3Dテキスト表示スレッド
CreateThread(function()
    while true do
        Wait(0)
        
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        -- 全プレイヤーをチェック
        for playerId, isActive in pairs(activeThermalPlayers) do
            if isActive then
                local targetPed = GetPlayerPed(GetPlayerFromServerId(playerId))
                
                if targetPed and targetPed ~= 0 and targetPed ~= playerPed then
                    local targetCoords = GetEntityCoords(targetPed)
                    local distance = #(playerCoords - targetCoords)
                    
                    -- 100m以内なら表示
                    if distance <= 100.0 then
                        local headCoords = GetPedBoneCoords(targetPed, 31086, 0.0, 0.0, 0.0) -- 頭の座標
                        headCoords = vector3(headCoords.x, headCoords.y, headCoords.z + 0.5) -- 少し上に表示
                        
                        Draw3DText(headCoords, "🔴 サーマル使用中")
                    end
                end
            end
        end
    end
end)

-- デバッグモード用コマンド
if Config.DebugMode then
    RegisterCommand('thermal', function()
        ToggleThermalVision(true)
    end, false)
end

-- リソース停止時の処理
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if isThermalActive then
        SetSeethrough(false)
        isThermalActive = false
        TriggerServerEvent('ng-thermalvision:server:updateStatus', false)
    end
end)

-- リソース起動時にサーバーから状態を取得
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    activeThermalPlayers = {}
    TriggerServerEvent('ng-thermalvision:server:requestAllStatus')
end)