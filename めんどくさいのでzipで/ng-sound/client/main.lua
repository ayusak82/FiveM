local QBCore = exports['qb-core']:GetCoreObject()

-- 回復を適用する関数
local function ApplyRecovery(recoveryData)
    if not recoveryData then return end
    
    local ped = PlayerPedId()
    local Player = QBCore.Functions.GetPlayerData()
    
    -- 即時回復または減少の場合
    if recoveryData.isInstant then
        SetTimeout(recoveryData.time, function()
            -- HP変更
            if recoveryData.health ~= 0 then
                local newHealth = GetEntityHealth(ped) + recoveryData.health
                if newHealth > 200 then newHealth = 200 end
                if newHealth < 1 then newHealth = 0 end
                SetEntityHealth(ped, newHealth)
            end
            
            -- アーマー変更
            if recoveryData.armour ~= 0 then
                local newArmour = GetPedArmour(ped) + recoveryData.armour
                if newArmour > 100 then newArmour = 100 end
                if newArmour < 0 then newArmour = 0 end
                SetPedArmour(ped, newArmour)
            end
            
            -- 食料と水分の変更
            if recoveryData.food ~= 0 or recoveryData.water ~= 0 then
                TriggerServerEvent('ng-sound:server:updateMetadata', recoveryData.food, recoveryData.water)
            end
        end)
    
    -- 徐々に回復または減少する場合
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
                    if newHealth > 200 then newHealth = 200 end
                    if newHealth < 1 then newHealth = 0 end
                    SetEntityHealth(ped, newHealth)
                end
                
                -- アーマー変更
                if armourPerTick ~= 0 then
                    local newArmour = GetPedArmour(ped) + armourPerTick
                    if newArmour > 100 then newArmour = 100 end
                    if newArmour < 0 then newArmour = 0 end
                    SetPedArmour(ped, newArmour)
                end
                
                -- 食料と水分の変更
                if foodPerTick ~= 0 or waterPerTick ~= 0 then
                    TriggerServerEvent('ng-sound:server:updateMetadata', foodPerTick, waterPerTick)
                end
                
                ticks = ticks + 1
                Wait(recoveryData.gradualTick)
            end
            isRecovering = false
        end)
    end
end

-- アニメーションを再生する関数
local function PlayAnimation(animData)
    if not animData then return end
    
    local ped = PlayerPedId()
    
    -- アニメーション辞書の読み込み
    if not HasAnimDictLoaded(animData.dict) then
        RequestAnimDict(animData.dict)
        while not HasAnimDictLoaded(animData.dict) do
            Wait(0)
        end
    end
    
    -- アニメーションの再生
    TaskPlayAnim(ped, animData.dict, animData.anim, 8.0, -8.0, animData.duration, animData.flag, 0, false, false, false)
    
    -- 一定時間後にアニメーション辞書を解放
    SetTimeout(animData.duration, function()
        RemoveAnimDict(animData.dict)
    end)
end

-- エフェクトを適用する関数
local function ApplyEffect(effectData)
    if not effectData or not effectData.type then return end
    
    local ped = PlayerPedId()
    
    SetTimeout(effectData.delay, function()
        if effectData.type == 'suicide' then
            SetEntityHealth(ped, 0)
        elseif effectData.type == 'fire' then
            -- 炎上エフェクトの開始
            StartEntityFire(ped)
            
            -- 一定時間後に炎を消す
            SetTimeout(effectData.duration, function()
                StopEntityFire(ped)
            end)
        end
    end)
end

-- アイテム使用イベント
RegisterNetEvent('ng-sound:useItem', function(data)
    local itemName = data.name
    if not Config.Items[itemName] then return end
    
    -- アニメーションの再生（もし設定されていれば）
    if Config.Items[itemName].animation then
        PlayAnimation(Config.Items[itemName].animation)
    end
    
    -- サーバーイベントをトリガー
    TriggerServerEvent('ng-sound:server:useItem', itemName)
    
    -- エフェクトの適用（もし設定されていれば）
    if Config.Items[itemName].effect then
        ApplyEffect(Config.Items[itemName].effect)
    end
    
    -- 回復の適用（もし設定されていれば）
    if Config.Items[itemName].recovery then
        ApplyRecovery(Config.Items[itemName].recovery)
    end
end)

-- サウンドを再生する関数
local function PlaySound(soundData, coords)
    if not soundData then 
        print('サウンドデータがありません')
        return 
    end
    
    print('再生開始: ' .. json.encode(soundData))
    
    -- ユニークなIDを生成（プレイヤーID + タイムスタンプ）
    local soundId = 'sound_' .. GetPlayerServerId(PlayerId()) .. '_' .. GetGameTimer()
    
    -- 設定された遅延後に音声を再生
    SetTimeout(soundData.soundDelay or 0, function()
        TriggerServerEvent('ng-sound:server:playSound', soundId, soundData, coords)
    end)
end

-- アイテム使用時のイベントハンドラー
RegisterNetEvent('ng-sound:client:playSound', function(itemName)
    print('イベント受信: ' .. itemName)
    local soundData = Config.Items[itemName]
    if not soundData then 
        print('設定が見つかりません: ' .. itemName)
        return 
    end
    
    -- プレイヤーの現在位置を取得
    local coords = GetEntityCoords(PlayerPedId())
    
    -- サウンドを再生
    PlaySound(soundData, coords)
end)

-- 他プレイヤーからのサウンド再生イベント
RegisterNetEvent('ng-sound:client:playSoundFromCoord', function(itemName, coords)
    print('他プレイヤーからのイベント受信: ' .. itemName)
    local soundData = Config.Items[itemName]
    if not soundData then return end
    
    PlaySound(soundData, coords)
end)