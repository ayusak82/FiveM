local QBCore = exports['qb-core']:GetCoreObject()
local isPunished = false
local originalCoords = nil
local explosionLoop = false
local deathLoop = false

-- 管理者権限チェック関数
local function isAdmin()
    return lib.callback.await('ng-hell-punishment:server:isAdmin', false)
end

-- 爆発ループ
local function startExplosionLoop()
    explosionLoop = true
    CreateThread(function()
        while explosionLoop do
            if isPunished then
                local playerPed = PlayerPedId()
                local coords = GetEntityCoords(playerPed)
                
                -- プレイヤーの座標で爆発を起こす
                AddExplosion(
                    coords.x, 
                    coords.y, 
                    coords.z, 
                    Config.Explosion.type, 
                    Config.Explosion.damageScale, 
                    Config.Explosion.isAudible, 
                    Config.Explosion.isInvisible, 
                    0.0
                )
                
                if Config.Debug then
                    print('[ng-hell-punishment] Explosion triggered at: ' .. coords.x .. ', ' .. coords.y .. ', ' .. coords.z)
                end
            end
            
            Wait(Config.Explosion.interval)
        end
    end)
end

-- 死亡監視ループ
local function startDeathLoop()
    deathLoop = true
    CreateThread(function()
        while deathLoop do
            local playerPed = PlayerPedId()
            
            if IsEntityDead(playerPed) then
                -- 死亡を検知
                if Config.Debug then
                    print('[ng-hell-punishment] Player died, waiting for respawn...')
                end
                
                Wait(Config.RespawnDelay)
                
                if not isPunished then
                    break
                end

                -- 蘇生処理
                local coords = Config.PunishmentLocation
                
                -- プレイヤーを蘇生
                NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, coords.w, true, false)
                SetEntityCoords(playerPed, coords.x, coords.y, coords.z, false, false, false, true)
                SetEntityHeading(playerPed, coords.w)
                SetPlayerInvincible(PlayerId(), false)
                ClearPedTasksImmediately(playerPed)
                
                -- 体力を全回復
                SetEntityHealth(playerPed, 200)
                
                -- フリーズ
                FreezeEntityPosition(playerPed, true)
                
                -- 武器を削除
                RemoveAllPedWeapons(playerPed, true)

                if Config.Debug then
                    print('[ng-hell-punishment] Player respawned at punishment location')
                end
            end
            
            Wait(500)
        end
    end)
end

-- 懲罰開始イベント
RegisterNetEvent('ng-hell-punishment:client:startPunishment', function()
    if isPunished then return end
    
    isPunished = true
    local playerPed = PlayerPedId()
    
    -- 現在の座標を保存
    originalCoords = GetEntityCoords(playerPed)
    
    -- 懲罰場所にテレポート
    local coords = Config.PunishmentLocation
    SetEntityCoords(playerPed, coords.x, coords.y, coords.z, false, false, false, true)
    SetEntityHeading(playerPed, coords.w)
    
    -- フリーズ
    FreezeEntityPosition(playerPed, true)
    
    -- 武器を削除
    RemoveAllPedWeapons(playerPed, true)
    
    -- 爆発ループを開始
    Wait(1000)
    startExplosionLoop()
    
    -- 死亡監視ループを開始
    startDeathLoop()
    
    if Config.Debug then
        print('[ng-hell-punishment] Punishment started')
    end
end)

-- 懲罰終了イベント
RegisterNetEvent('ng-hell-punishment:client:stopPunishment', function()
    if not isPunished then return end
    
    isPunished = false
    explosionLoop = false
    deathLoop = false
    local playerPed = PlayerPedId()
    
    -- フリーズ解除
    FreezeEntityPosition(playerPed, false)
    
    -- 元の場所に戻す（保存されている場合）
    if originalCoords then
        -- 死亡している場合は蘇生してから戻す
        if IsEntityDead(playerPed) then
            NetworkResurrectLocalPlayer(originalCoords.x, originalCoords.y, originalCoords.z, 0.0, true, false)
        end
        
        SetEntityCoords(playerPed, originalCoords.x, originalCoords.y, originalCoords.z, false, false, false, true)
        SetEntityHealth(playerPed, 200)
    end
    
    originalCoords = nil
    
    if Config.Debug then
        print('[ng-hell-punishment] Punishment stopped')
    end
end)

-- リソース停止時のクリーンアップ
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if isPunished then
        local playerPed = PlayerPedId()
        FreezeEntityPosition(playerPed, false)
        explosionLoop = false
        deathLoop = false
    end
end)

-- デバッグ用
if Config.Debug then
    print('[ng-hell-punishment] Client script loaded successfully')
end