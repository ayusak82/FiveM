local QBCore = exports['qb-core']:GetCoreObject()

-- デバッグ関数
local function DebugPrint(...)
    if not Config.Debug then return end
    local args = {...}
    local message = ''
    for i = 1, #args do
        message = message .. tostring(args[i]) .. ' '
    end
    print('^3[ng-sizepotion DEBUG]^7 ' .. message)
end

-- 変数
local isAffected = false
local currentEffect = nil
local currentScale = 1.0
local effectEndTime = 0
local cooldownEndTime = 0
local scaleThread = nil

-- 他プレイヤーのスケール情報を保存
local playerScales = {}

-- ベクトル正規化関数
local function NormalizeVector(vec)
    local len = math.sqrt(vec.x * vec.x + vec.y * vec.y + vec.z * vec.z)
    if len == 0 then return vector3(0, 0, 0) end
    return vector3(vec.x / len, vec.y / len, vec.z / len)
end

-- 地面のZ座標を取得
local function GetGroundZCoord(x, y, z)
    local found, groundZ = GetGroundZFor_3dCoord(x, y, z + 10.0, false)
    if found then
        return groundZ
    end
    return nil
end

-- スケール適用関数（SetEntityMatrixを使用）
local function ApplyScaleToEntity(ped, scale)
    if not DoesEntityExist(ped) then return end
    
    local forward, right, up, pos = GetEntityMatrix(ped)
    
    -- ベクトルを正規化してスケールを適用
    local forwardNorm = NormalizeVector(forward) * scale
    local rightNorm = NormalizeVector(right) * scale
    local upNorm = NormalizeVector(up) * scale
    
    -- 地面の高さを取得して、そこからオフセットを計算
    local groundZ = GetGroundZCoord(pos.x, pos.y, pos.z)
    local finalZ = pos.z
    
    if groundZ then
        -- スケールに応じたオフセットを計算
        local baseOffset = 0.9 * scale
        finalZ = groundZ + baseOffset
    end
    
    SetEntityMatrix(ped,
        forwardNorm.x, forwardNorm.y, forwardNorm.z,
        rightNorm.x, rightNorm.y, rightNorm.z,
        upNorm.x, upNorm.y, upNorm.z,
        pos.x, pos.y, finalZ
    )
end

-- パーティクルエフェクト再生
local function PlayParticleEffect(config)
    if not config.enabled then return end
    
    local ped = PlayerPedId()
    
    RequestNamedPtfxAsset(config.dict)
    local timeout = 0
    while not HasNamedPtfxAssetLoaded(config.dict) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end
    
    if HasNamedPtfxAssetLoaded(config.dict) then
        UseParticleFxAssetNextCall(config.dict)
        local effect = StartParticleFxLoopedOnEntity(
            config.name, ped,
            0.0, 0.0, 0.0,
            0.0, 0.0, 0.0,
            config.scale, false, false, false
        )
        
        SetTimeout(1000, function()
            StopParticleFxLooped(effect, false)
            RemoveNamedPtfxAsset(config.dict)
        end)
    end
end

-- サウンド再生
local function PlaySound(soundConfig)
    if not Config.Sounds.enabled then return end
    PlaySoundFrontend(-1, soundConfig.name, soundConfig.ref, true)
end

-- 自分のスケールをサーバーに送信
local function SyncScaleToServer(scale)
    if Config.Sync.enabled then
        TriggerServerEvent('ng-sizepotion:server:syncScale', scale)
    end
end

-- スケールループ開始（自分用）
local function StartScaleLoop(scale)
    if scaleThread then
        scaleThread = nil
    end
    
    currentScale = scale
    
    -- サーバーに同期
    SyncScaleToServer(scale)
    
    scaleThread = CreateThread(function()
        DebugPrint('Scale loop started, scale:', currentScale)
        
        while isAffected do
            local ped = PlayerPedId()
            
            if DoesEntityExist(ped) and not IsEntityDead(ped) then
                if not IsPedInAnyVehicle(ped, false) then
                    ApplyScaleToEntity(ped, currentScale)
                end
            end
            
            Wait(0)
        end
        
        DebugPrint('Scale loop ended')
    end)
end

-- 他プレイヤーのスケールを適用するループ
CreateThread(function()
    while true do
        for serverId, scaleData in pairs(playerScales) do
            if serverId ~= GetPlayerServerId(PlayerId()) then
                local player = GetPlayerFromServerId(serverId)
                if player ~= -1 then
                    local ped = GetPlayerPed(player)
                    if DoesEntityExist(ped) and not IsPedInAnyVehicle(ped, false) then
                        ApplyScaleToEntity(ped, scaleData.scale)
                    end
                end
            end
        end
        Wait(0)
    end
end)

-- 効果終了タイマー
local function StartEffectTimer(duration)
    effectEndTime = GetGameTimer() + (duration * 1000)
    
    CreateThread(function()
        while isAffected and GetGameTimer() < effectEndTime do
            Wait(1000)
            
            local ped = PlayerPedId()
            
            if Config.Restrictions.cancelOnDeath and IsEntityDead(ped) then
                DebugPrint('Player died, removing effect')
                RemoveEffect()
                return
            end
            
            if Config.Restrictions.cancelOnVehicleEnter and IsPedInAnyVehicle(ped, false) then
                DebugPrint('Player entered vehicle, removing effect')
                RemoveEffect()
                return
            end
        end
        
        if isAffected then
            DebugPrint('Effect duration ended')
            RemoveEffect()
        end
    end)
end

-- 効果の適用
local function ApplyEffect(potionType)
    local potionConfig = Config.Potions[potionType]
    if not potionConfig then return end
    
    isAffected = true
    currentEffect = potionType
    
    local scale = math.max(Config.Restrictions.minScale, math.min(Config.Restrictions.maxScale, potionConfig.scale))
    
    DebugPrint('Applying effect:', potionType, 'Scale:', scale, 'Duration:', potionConfig.duration)
    
    PlayParticleEffect(potionConfig.particles)
    PlaySound(Config.Sounds.onUse)
    
    if potionConfig.effects.speedBoost ~= 1.0 then
        SetRunSprintMultiplierForPlayer(PlayerId(), potionConfig.effects.speedBoost)
    end
    
    StartScaleLoop(scale)
    StartEffectTimer(potionConfig.duration)
end

-- 効果の解除
function RemoveEffect()
    if not isAffected then return end
    
    local potionConfig = Config.Potions[currentEffect]
    
    DebugPrint('Removing effect:', currentEffect)
    
    isAffected = false
    
    -- サーバーに通常スケールを同期
    SyncScaleToServer(1.0)
    
    Wait(50)
    
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    PlaySound(Config.Sounds.onEnd)
    
    local notifyKey = currentEffect == 'shrink' and 'shrinkEnd' or 'growEnd'
    exports['okokNotify']:Alert('サイズ変更', Config.Notifications[notifyKey], 5000, 'info', true)
    
    if potionConfig then
        cooldownEndTime = GetGameTimer() + (potionConfig.cooldown * 1000)
    end
    
    currentEffect = nil
    currentScale = 1.0
    scaleThread = nil
end

-- 薬を使用
local function UsePotion(potionType)
    local potionConfig = Config.Potions[potionType]
    if not potionConfig then return end
    
    local ped = PlayerPedId()
    
    if not Config.Restrictions.allowInVehicle and IsPedInAnyVehicle(ped, false) then
        exports['okokNotify']:Alert('エラー', Config.Notifications.cannotUseInVehicle, 5000, 'error', true)
        return
    end
    
    if isAffected then
        exports['okokNotify']:Alert('エラー', Config.Notifications.alreadyAffected, 5000, 'warning', true)
        return
    end
    
    local currentTime = GetGameTimer()
    if currentTime < cooldownEndTime then
        local remaining = math.ceil((cooldownEndTime - currentTime) / 1000)
        exports['okokNotify']:Alert('エラー', string.format(Config.Notifications.cooldownActive, remaining), 5000, 'warning', true)
        return
    end
    
    if lib.progressBar({
        duration = potionConfig.useTime,
        label = '薬を飲んでいます...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = {
            dict = potionConfig.animation.dict,
            clip = potionConfig.animation.anim
        }
    }) then
        TriggerServerEvent('ng-sizepotion:server:usePotion', potionType)
    else
        exports['okokNotify']:Alert('キャンセル', '使用をキャンセルしました', 3000, 'info', false)
    end
end

-- 解毒剤を使用
local function UseAntidote()
    if not Config.Antidote.enabled then return end
    
    if not isAffected then
        exports['okokNotify']:Alert('情報', '効果を受けていません', 3000, 'info', false)
        return
    end
    
    if lib.progressBar({
        duration = Config.Antidote.useTime,
        label = '解毒剤を飲んでいます...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = {
            dict = Config.Antidote.animation.dict,
            clip = Config.Antidote.animation.anim
        }
    }) then
        TriggerServerEvent('ng-sizepotion:server:useAntidote')
    else
        exports['okokNotify']:Alert('キャンセル', '使用をキャンセルしました', 3000, 'info', false)
    end
end

-- サーバーからの効果適用イベント
RegisterNetEvent('ng-sizepotion:client:applyEffect', function(potionType)
    local notifyKey = potionType == 'shrink' and 'shrinkStart' or 'growStart'
    exports['okokNotify']:Alert('サイズ変更', Config.Notifications[notifyKey], 5000, 'success', true)
    ApplyEffect(potionType)
end)

-- サーバーからの解毒剤効果イベント
RegisterNetEvent('ng-sizepotion:client:applyAntidote', function()
    exports['okokNotify']:Alert('解毒剤', Config.Notifications.antidoteUsed, 5000, 'success', true)
    RemoveEffect()
end)

-- サーバーからの薬使用トリガー
RegisterNetEvent('ng-sizepotion:client:usePotion', function(potionType)
    UsePotion(potionType)
end)

-- サーバーからの解毒剤使用トリガー
RegisterNetEvent('ng-sizepotion:client:useAntidote', function()
    UseAntidote()
end)

-- 他プレイヤーのスケール同期を受信
RegisterNetEvent('ng-sizepotion:client:updatePlayerScale', function(serverId, scale)
    if serverId ~= GetPlayerServerId(PlayerId()) then
        if scale == 1.0 then
            playerScales[serverId] = nil
        else
            playerScales[serverId] = { scale = scale }
        end
        DebugPrint('Received scale update for player:', serverId, 'Scale:', scale)
    end
end)

-- 全プレイヤーのスケール情報を受信（初回同期用）
RegisterNetEvent('ng-sizepotion:client:syncAllScales', function(scales)
    local myServerId = GetPlayerServerId(PlayerId())
    for serverId, scale in pairs(scales) do
        if serverId ~= myServerId then
            if scale == 1.0 then
                playerScales[serverId] = nil
            else
                playerScales[serverId] = { scale = scale }
            end
        end
    end
    DebugPrint('Synced all player scales')
end)

-- プレイヤーがサーバーから離脱した時
RegisterNetEvent('ng-sizepotion:client:playerDropped', function(serverId)
    playerScales[serverId] = nil
end)

-- リソース停止時のクリーンアップ
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if isAffected then
        isAffected = false
        SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    end
end)

-- プレイヤーロード時
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    DebugPrint('Player loaded, requesting scale sync')
    isAffected = false
    currentEffect = nil
    currentScale = 1.0
    
    -- サーバーから全プレイヤーのスケール情報を取得
    TriggerServerEvent('ng-sizepotion:server:requestScaleSync')
end)

-- プレイヤーアンロード時
RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    if isAffected then
        isAffected = false
        SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
        SyncScaleToServer(1.0)
    end
end)

-- 死亡時のハンドリング
AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkEntityDamage' then
        local victim = args[1]
        local isDead = args[4]
        
        if victim == PlayerPedId() and isDead and Config.Restrictions.cancelOnDeath then
            if isAffected then
                RemoveEffect()
            end
        end
    end
end)

DebugPrint('Client script loaded')
