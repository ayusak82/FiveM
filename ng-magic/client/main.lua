local QBCore = exports['qb-core']:GetCoreObject()
local cooldowns = {}
local activeEffects = {}

-- 管理者権限チェック関数
local function isAdmin()
    return lib.callback.await('ng-magic:server:isAdmin', false)
end

-- クールダウンチェック
local function isOnCooldown(spellId)
    if cooldowns[spellId] then
        local timeLeft = cooldowns[spellId] - GetGameTimer()
        if timeLeft > 0 then
            return true, math.ceil(timeLeft / 1000)
        else
            cooldowns[spellId] = nil
        end
    end
    return false, 0
end

-- クールダウン設定
local function setCooldown(spellId, duration)
    cooldowns[spellId] = GetGameTimer() + duration
end

-- ヒールマジック
local function castHeal(spell)
    local ped = PlayerPedId()
    local currentHealth = GetEntityHealth(ped)
    local maxHealth = GetEntityMaxHealth(ped)
    local newHealth = math.min(currentHealth + spell.healAmount, maxHealth)
    
    SetEntityHealth(ped, newHealth)
    
    -- エフェクト
    CreateThread(function()
        local coords = GetEntityCoords(ped)
        UseParticleFxAssetNextCall("core")
        StartParticleFxNonLoopedAtCoord("ent_sht_steam", coords.x, coords.y, coords.z + 1.0, 0.0, 0.0, 0.0, 1.0, false, false, false)
    end)
end

-- テレポート
local function castTeleport(spell)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local radians = math.rad(heading)
    
    local newX = coords.x + (math.sin(radians) * -spell.distance)
    local newY = coords.y + (math.cos(radians) * -spell.distance)
    
    -- 地面の高さを取得
    local foundGround, groundZ = GetGroundZFor_3dCoord(newX, newY, coords.z + 10.0, false)
    local newZ = foundGround and groundZ or coords.z
    
    -- エフェクト(出発地点)
    UseParticleFxAssetNextCall("core")
    StartParticleFxNonLoopedAtCoord("ent_dst_smoke", coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 1.0, false, false, false)
    
    Wait(100)
    SetEntityCoords(ped, newX, newY, newZ, false, false, false, false)
    
    -- エフェクト(到着地点)
    UseParticleFxAssetNextCall("core")
    StartParticleFxNonLoopedAtCoord("ent_dst_smoke", newX, newY, newZ, 0.0, 0.0, 0.0, 1.0, false, false, false)
end

-- ファイアボール
local function castFireball(spell)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local radians = math.rad(heading)
    
    CreateThread(function()
        for i = 1, 10 do
            local distance = i * 2.0
            local x = coords.x + (math.sin(radians) * -distance)
            local y = coords.y + (math.cos(radians) * -distance)
            local z = coords.z
            
            UseParticleFxAssetNextCall("core")
            StartParticleFxNonLoopedAtCoord("exp_grd_bzgas_smoke", x, y, z, 0.0, 0.0, 0.0, 1.0, false, false, false)
            
            Wait(50)
        end
    end)
end

-- 透明化
local function castInvisible(spell)
    local ped = PlayerPedId()
    
    if activeEffects['invisible'] then
        lib.notify(Config.Notifications.cooldown)
        return
    end
    
    activeEffects['invisible'] = true
    SetEntityVisible(ped, false, false)
    SetEntityAlpha(ped, 0, false)
    
    CreateThread(function()
        Wait(spell.duration)
        SetEntityVisible(ped, true, false)
        ResetEntityAlpha(ped)
        activeEffects['invisible'] = nil
        lib.notify({
            title = '魔法システム',
            description = 'インビジブルの効果が切れました',
            type = 'inform',
            duration = 3000
        })
    end)
end

-- スピードブースト
local function castSpeed(spell)
    local ped = PlayerPedId()
    
    if activeEffects['speed'] then
        lib.notify(Config.Notifications.cooldown)
        return
    end
    
    activeEffects['speed'] = true
    SetRunSprintMultiplierForPlayer(PlayerId(), spell.speedMultiplier)
    SetSwimMultiplierForPlayer(PlayerId(), spell.speedMultiplier)
    
    CreateThread(function()
        Wait(spell.duration)
        SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
        SetSwimMultiplierForPlayer(PlayerId(), 1.0)
        activeEffects['speed'] = nil
        lib.notify({
            title = '魔法システム',
            description = 'スピードブーストの効果が切れました',
            type = 'inform',
            duration = 3000
        })
    end)
end

-- スーパージャンプ
local function castJump(spell)
    if activeEffects['jump'] then
        lib.notify(Config.Notifications.cooldown)
        return
    end
    
    activeEffects['jump'] = true
    SetSuperJumpThisFrame(PlayerId())
    
    CreateThread(function()
        local endTime = GetGameTimer() + spell.duration
        while GetGameTimer() < endTime do
            SetSuperJumpThisFrame(PlayerId())
            Wait(0)
        end
        activeEffects['jump'] = nil
        lib.notify({
            title = '魔法システム',
            description = 'スーパージャンプの効果が切れました',
            type = 'inform',
            duration = 3000
        })
    end)
end

-- ナイトビジョン
local function castNightVision(spell)
    if activeEffects['night_vision'] then
        lib.notify(Config.Notifications.cooldown)
        return
    end
    
    activeEffects['night_vision'] = true
    SetNightvision(true)
    
    CreateThread(function()
        Wait(spell.duration)
        SetNightvision(false)
        activeEffects['night_vision'] = nil
        lib.notify({
            title = '魔法システム',
            description = 'ナイトビジョンの効果が切れました',
            type = 'inform',
            duration = 3000
        })
    end)
end

-- マジックアーマー
local function castArmor(spell)
    local ped = PlayerPedId()
    local currentArmor = GetPedArmour(ped)
    local newArmor = math.min(currentArmor + spell.armorAmount, 100)
    
    SetPedArmour(ped, newArmor)
    
    -- エフェクト
    CreateThread(function()
        local coords = GetEntityCoords(ped)
        UseParticleFxAssetNextCall("core")
        StartParticleFxNonLoopedAtCoord("ent_sht_steam", coords.x, coords.y, coords.z + 1.0, 0.0, 0.0, 0.0, 1.0, false, false, false)
    end)
end

-- 魔法を使用
local function useMagic(spell)
    local onCooldown, timeLeft = isOnCooldown(spell.id)
    
    if onCooldown then
        local notification = Config.Notifications.cooldown
        lib.notify({
            title = notification.title,
            description = string.format(notification.description, timeLeft),
            type = notification.type,
            duration = notification.duration
        })
        return
    end
    
    -- 管理者専用チェック
    if spell.adminOnly then
        local admin = isAdmin()
        if not admin then
            lib.notify(Config.Notifications.adminOnly)
            return
        end
    end
    
    -- 魔法を実行
    if spell.id == 'heal' then
        castHeal(spell)
    elseif spell.id == 'teleport' then
        castTeleport(spell)
    elseif spell.id == 'fireball' then
        castFireball(spell)
    elseif spell.id == 'invisible' then
        castInvisible(spell)
    elseif spell.id == 'speed' then
        castSpeed(spell)
    elseif spell.id == 'jump' then
        castJump(spell)
    elseif spell.id == 'night_vision' then
        castNightVision(spell)
    elseif spell.id == 'armor' then
        castArmor(spell)
    end
    
    -- クールダウン設定
    setCooldown(spell.id, spell.cooldown)
    
    -- 成功通知
    local notification = Config.Notifications.success
    lib.notify({
        title = notification.title,
        description = string.format(notification.description, spell.label),
        type = notification.type,
        duration = notification.duration
    })
end

-- 魔法メニューを開く
local function openMagicMenu()
    -- 権限チェック
    if Config.AdminOnly then
        local admin = isAdmin()
        if not admin then
            lib.notify(Config.Notifications.noPermission)
            return
        end
    end
    
    local options = {}
    
    for _, spell in ipairs(Config.Spells) do
        local onCooldown, timeLeft = isOnCooldown(spell.id)
        local description = spell.description
        
        if onCooldown then
            description = description .. string.format(" (クールダウン: %d秒)", timeLeft)
        end
        
        table.insert(options, {
            title = spell.label,
            description = description,
            icon = spell.icon,
            disabled = onCooldown,
            onSelect = function()
                useMagic(spell)
            end
        })
    end
    
    lib.registerContext({
        id = 'magic_menu',
        title = '魔法一覧',
        options = options
    })
    
    lib.showContext('magic_menu')
end

-- コマンド登録
RegisterCommand(Config.Command, function()
    openMagicMenu()
end, false)

-- リソース停止時のクリーンアップ
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    local ped = PlayerPedId()
    
    -- すべてのエフェクトを解除
    if activeEffects['invisible'] then
        SetEntityVisible(ped, true, false)
        ResetEntityAlpha(ped)
    end
    
    if activeEffects['speed'] then
        SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
        SetSwimMultiplierForPlayer(PlayerId(), 1.0)
    end
    
    if activeEffects['night_vision'] then
        SetNightvision(false)
    end
end)
