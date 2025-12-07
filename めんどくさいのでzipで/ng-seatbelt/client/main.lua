local QBCore = exports['qb-core']:GetCoreObject()
local qbx = exports.qbx_core
local seatbeltOn = false
local warningPlaying = false

-- カスタム警告音を再生する関数
local function playCustomWarningSound()
    -- 音源の距離と音量を調整して警告音を再生
    local pos = GetEntityCoords(PlayerPedId())
    local volume = Config.WarningSoundVolume
    -- 3Dオーディオとして再生（音量を調整できる）
    PlaySoundFromCoord(-1, Config.WarningSoundFile, pos.x, pos.y, pos.z, Config.WarningSoundSet, false, 20, volume)
    -- または通常のフロントエンド音（音量調整は別の方法が必要）
    -- PlaySoundFrontend(-1, Config.WarningSoundFile, Config.WarningSoundSet, true)
end

-- 警告音を再生する関数
local function playSeatbeltWarning()
    if warningPlaying then return end
    
    warningPlaying = true
    
    CreateThread(function()
        while not seatbeltOn and cache.vehicle do
            local vehicle = cache.vehicle
            
            -- 車両クラスをチェック（バイク、自転車、ボートなどを除外）
            local vehicleClass = GetVehicleClass(vehicle)
            if vehicleClass == 8 or vehicleClass == 13 or vehicleClass == 14 then
                warningPlaying = false
                return
            end
            
            -- 最新のシートベルト状態を確認
            seatbeltOn = LocalPlayer.state.seatbelt or LocalPlayer.state.harness
            if seatbeltOn then
                warningPlaying = false
                return
            end
            
            local speed = GetEntitySpeed(vehicle) * 3.6 -- m/s から km/h に変換
            
            -- 一定速度以上で走行している場合のみ警告音を鳴らす
            if speed > Config.SpeedLimit then
                playCustomWarningSound()
                Wait(Config.WarningSoundInterval)
            else
                Wait(500)
            end
        end
        
        warningPlaying = false
    end)
end

-- 警告音をチェックするスレッド
CreateThread(function()
    while true do
        local sleep = 1000
        
        if cache.vehicle then
            local vehicle = cache.vehicle
            
            -- バイク、自転車、ボート以外の乗り物の場合
            local class = GetVehicleClass(vehicle)
            if class ~= 8 and class ~= 13 and class ~= 14 then
                sleep = 100
                
                -- 最新のシートベルト状態を取得
                seatbeltOn = LocalPlayer.state.seatbelt or LocalPlayer.state.harness
                
                -- シートベルトがついていない場合、警告音を鳴らす
                if not seatbeltOn then
                    playSeatbeltWarning()
                end
            end
        else
            -- 車両から降りた場合は警告を停止
            warningPlaying = false
        end
        
        Wait(sleep)
    end
end)

-- 外部のシートベルトスクリプトからのイベントを受け取る
RegisterNetEvent(Config.SeatbeltStateEvent, function()
    -- LocalPlayer.stateからシートベルトの状態を取得
    seatbeltOn = LocalPlayer.state.seatbelt or LocalPlayer.state.harness
    
    -- シートベルトが装着された場合は警告音を停止
    if seatbeltOn then
        warningPlaying = false
    end
end)

-- 初期状態の確認（シートベルトの状態を直接取得）
CreateThread(function()
    Wait(1000) -- サーバーからの状態が同期されるのを少し待つ
    seatbeltOn = LocalPlayer.state.seatbelt or LocalPlayer.state.harness
end)

-- プレイヤーがスポーンした時の初期化
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    seatbeltOn = false
    warningPlaying = false
end)

-- リソースが再起動された時の初期化
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    seatbeltOn = false
    warningPlaying = false
end)

-- リソースが停止された時のクリーンアップ
AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    warningPlaying = false
end)