local QBCore = exports['qb-core']:GetCoreObject()

-- アニメーションを再生
local function PlayAnimation(animData)
    if not animData then return end
    
    local ped = PlayerPedId()
    
    if not HasAnimDictLoaded(animData.dict) then
        RequestAnimDict(animData.dict)
        while not HasAnimDictLoaded(animData.dict) do
            Wait(0)
        end
    end
    
    TaskPlayAnim(ped, animData.dict, animData.anim, 8.0, -8.0, animData.duration, animData.flag, 0, false, false, false)
    
    SetTimeout(animData.duration, function()
        RemoveAnimDict(animData.dict)
    end)
end

-- 回復効果を適用
local function ApplyRecovery(recoveryData)
    if not recoveryData then return end
    
    local ped = PlayerPedId()
    
    -- 即時回復の場合
    if recoveryData.isInstant then
        SetTimeout(recoveryData.time, function()
            -- HP変更
            if recoveryData.health ~= 0 then
                local newHealth = GetEntityHealth(ped) + recoveryData.health
                newHealth = math.min(200, math.max(1, newHealth))
                SetEntityHealth(ped, newHealth)
            end
            
            -- アーマー変更
            if recoveryData.armour ~= 0 then
                local newArmour = GetPedArmour(ped) + recoveryData.armour
                newArmour = math.min(100, math.max(0, newArmour))
                SetPedArmour(ped, newArmour)
            end
            
            -- 食料と水分の変更
            if recoveryData.food ~= 0 or recoveryData.water ~= 0 then
                TriggerServerEvent('ng-itemeditor:server:updateMetadata', recoveryData.food, recoveryData.water)
            end
        end)
    
    -- 徐々に回復する場合
    else
        local ticksCount = math.floor(recoveryData.time / recoveryData.gradualTick)
        local healthPerTick = recoveryData.health / ticksCount
        local armourPerTick = recoveryData.armour / ticksCount
        local foodPerTick = recoveryData.food / ticksCount
        local waterPerTick = recoveryData.water / ticksCount
        
        local ticks = 0
        local isRecovering = true
        
        CreateThread(function()
            while isRecovering and ticks < ticksCount do
                -- HP変更
                if healthPerTick ~= 0 then
                    local newHealth = GetEntityHealth(ped) + healthPerTick
                    newHealth = math.min(200, math.max(1, newHealth))
                    SetEntityHealth(ped, newHealth)
                end
                
                -- アーマー変更
                if armourPerTick ~= 0 then
                    local newArmour = GetPedArmour(ped) + armourPerTick
                    newArmour = math.min(100, math.max(0, newArmour))
                    SetPedArmour(ped, newArmour)
                end
                
                -- 食料と水分の変更
                if foodPerTick ~= 0 or waterPerTick ~= 0 then
                    TriggerServerEvent('ng-itemeditor:server:updateMetadata', foodPerTick, waterPerTick)
                end
                
                ticks = ticks + 1
                Wait(recoveryData.gradualTick)
            end
            isRecovering = false
        end)
    end
end

-- エフェクトを適用
local function ApplyEffect(effectData)
    if not effectData or not effectData.type then return end
    
    local ped = PlayerPedId()
    
    SetTimeout(effectData.delay, function()
        if effectData.type == 'suicide' then
            SetEntityHealth(ped, 0)
        elseif effectData.type == 'fire' then
            StartEntityFire(ped)
            SetTimeout(effectData.duration, function()
                StopEntityFire(ped)
            end)
        end
    end)
end

-- サウンドを再生
local function PlaySound(soundData, coords)
    if not soundData or not soundData.url then return end
    
    -- サウンドIDを生成
    local soundId = 'sound_' .. GetPlayerServerId(PlayerId()) .. '_' .. GetGameTimer()
    
    SetTimeout(soundData.soundDelay or 0, function()
        local volume = soundData.volume or 0.3
        local maxDistance = soundData.maxDistance or 10.0
        local loop = soundData.loop or false
        
        exports.xsound:PlayUrlPos(soundId, soundData.url, volume, coords, loop)
        exports.xsound:Distance(soundId, maxDistance)
    end)
end

-- アイテム効果適用イベント
RegisterNetEvent('ng-itemeditor:client:applyEffects', function(itemName, config)
    -- アニメーション
    if config.animation then
        PlayAnimation(config.animation)
    end
    
    -- エフェクト
    if config.effect then
        ApplyEffect(config.effect)
    end
    
    -- 回復効果
    if config.recovery then
        ApplyRecovery(config.recovery)
    end
    
    -- サウンド
    if config.sound then
        local coords = GetEntityCoords(PlayerPedId())
        PlaySound(config.sound, coords)
    end
end)

-- 他プレイヤーのサウンド再生イベント
RegisterNetEvent('ng-itemeditor:client:playSoundFromCoord', function(itemName, coords, config)
    if not config or not config.sound then return end
    PlaySound(config.sound, coords)
end)

-- ox_inventoryのhookを追加
exports('usableItem', function(data, slot)
    TriggerServerEvent('ng-itemeditor:server:useItem', data.name)
end)