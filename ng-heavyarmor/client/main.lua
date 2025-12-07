local QBCore = exports['qb-core']:GetCoreObject()

-- 状態管理
local isEquipped = false
local originalPedModel = nil
local originalHealth = nil
local originalArmor = nil
local timeRemaining = 0
local timerThread = nil

-- 管理者権限チェック関数
local function isAdmin()
    return lib.callback.await('ng-heavyarmor:server:isAdmin', false)
end

-- デバッグログ
local function debugPrint(message)
    if Config.Debug then
        print('[ng-heavyarmor] ' .. message)
    end
end

-- 通知表示
local function showNotification(message, type)
    lib.notify({
        title = 'Heavy Armor',
        description = message,
        type = type or 'info',
        position = Config.UI.Position
    })
end

-- インベントリ無効化
local function disableInventory()
    if not Config.HeavyArmor.DisableInventory then return end
    
    CreateThread(function()
        while isEquipped do
            Wait(0)
            
            -- インベントリキーを無効化
            DisableControlAction(0, 289, true) -- I key (Inventory)
            DisableControlAction(0, 37, true)  -- TAB key
            
            -- ox_inventoryの場合
            if exports.ox_inventory then
                if IsControlJustPressed(0, 289) or IsControlJustPressed(0, 37) then
                    showNotification(Config.Notifications.InventoryDisabled, 'error')
                end
            end
        end
    end)
end

-- 重装備装着
local function equipHeavyArmor()
    if isEquipped then
        showNotification(Config.Notifications.AlreadyEquipped, 'error')
        return
    end

    -- プログレスバー表示
    if lib.progressBar({
        duration = Config.UI.EquipDuration,
        label = Config.Notifications.Equipping,
        useWhileDead = false,
        canCancel = false,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = {
            dict = 'anim@narcotics@trash',
            clip = 'drop_front'
        }
    }) then
        local playerPed = PlayerPedId()
        
        -- 元の状態を保存
        originalPedModel = GetEntityModel(playerPed)
        originalHealth = GetEntityHealth(playerPed)
        originalArmor = GetPedArmour(playerPed)
        
        debugPrint('Original Model: ' .. originalPedModel)
        debugPrint('Original Health: ' .. originalHealth)
        debugPrint('Original Armor: ' .. originalArmor)
        
        -- プレイヤー座標取得
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)
        
        -- 重装備モデル読み込み
        local modelHash = GetHashKey(Config.HeavyArmor.PedModel)
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do
            Wait(100)
        end
        
        -- モデル変更
        SetPlayerModel(PlayerId(), modelHash)
        SetModelAsNoLongerNeeded(modelHash)
        
        -- 新しいPedを取得
        Wait(100)
        playerPed = PlayerPedId()
        
        -- 座標とヘディングを復元
        SetEntityCoords(playerPed, coords.x, coords.y, coords.z, false, false, false, true)
        SetEntityHeading(playerPed, heading)
        
        -- 体力とアーマー設定
        SetEntityMaxHealth(playerPed, Config.HeavyArmor.MaxHealth)
        SetEntityHealth(playerPed, Config.HeavyArmor.MaxHealth)
        SetPlayerMaxArmour(PlayerId(), Config.HeavyArmor.MaxArmor) -- プレイヤーの最大アーマー値を設定
        Wait(100) -- 設定が反映されるまで待機
        SetPedArmour(playerPed, Config.HeavyArmor.MaxArmor)
        
        debugPrint('Health set to: ' .. Config.HeavyArmor.MaxHealth)
        debugPrint('Armor set to: ' .. Config.HeavyArmor.MaxArmor)
        
        -- 武器装備
        local weaponHash = GetHashKey(Config.HeavyArmor.Weapon)
        GiveWeaponToPed(playerPed, weaponHash, Config.HeavyArmor.Ammo, false, true)
        SetCurrentPedWeapon(playerPed, weaponHash, true)
        SetPedInfiniteAmmo(playerPed, true, weaponHash)
        
        -- 移動速度設定
        SetPedMoveRateOverride(playerPed, Config.HeavyArmor.MovementSpeed)
        
        -- 画面エフェクト
        if Config.HeavyArmor.EnableScreenEffect then
            StartScreenEffect(Config.HeavyArmor.ScreenEffect, 0, true)
        end
        
        -- 状態更新
        isEquipped = true
        timeRemaining = Config.HeavyArmor.Duration
        
        -- タイマー開始
        startTimer()
        
        -- ダメージハンドラー開始
        startDamageHandler()
        
        -- インベントリ無効化
        disableInventory()
        
        showNotification(Config.Notifications.Equipped, 'success')
        debugPrint('Heavy armor equipped with model: ' .. Config.HeavyArmor.PedModel)
    end
end

-- 重装備解除
local function unequipHeavyArmor(silent)
    if not isEquipped then
        return
    end

    if not silent then
        -- プログレスバー表示
        lib.progressBar({
            duration = Config.UI.UnequipDuration,
            label = Config.Notifications.Unequipping,
            useWhileDead = false,
            canCancel = false,
            disable = {
                car = true,
                move = true,
                combat = true
            }
        })
    end
    
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    
    -- 武器削除
    RemoveAllPedWeapons(playerPed, true)
    SetPedInfiniteAmmo(playerPed, false, GetHashKey(Config.HeavyArmor.Weapon))
    
    -- 移動速度をリセット
    SetPedMoveRateOverride(playerPed, 1.0)
    
    -- 画面エフェクト解除
    if Config.HeavyArmor.EnableScreenEffect then
        StopScreenEffect(Config.HeavyArmor.ScreenEffect)
    end
    
    -- 元のモデルに戻す
    if originalPedModel then
        debugPrint('Restoring to original model: ' .. originalPedModel)
        
        -- 元のモデルを読み込み
        RequestModel(originalPedModel)
        local timeout = 0
        while not HasModelLoaded(originalPedModel) and timeout < 100 do
            Wait(100)
            timeout = timeout + 1
        end
        
        if HasModelLoaded(originalPedModel) then
            -- モデルを変更
            SetPlayerModel(PlayerId(), originalPedModel)
            SetModelAsNoLongerNeeded(originalPedModel)
            
            -- 少し待機してから新しいPedを取得
            Wait(200)
            playerPed = PlayerPedId()
            
            -- 座標とヘディングを復元
            SetEntityCoords(playerPed, coords.x, coords.y, coords.z, false, false, false, true)
            SetEntityHeading(playerPed, heading)
            
            -- エンティティが可視化されるまで待機と可視性を強制設定
            Wait(100)
            
            -- 複数回可視性を設定して確実に表示
            for i = 1, 5 do
                SetEntityVisible(playerPed, true, false)
                SetEntityAlpha(playerPed, 255, false)
                ResetEntityAlpha(playerPed)
                SetEntityCollision(playerPed, true, true)
                FreezeEntityPosition(playerPed, false)
                Wait(50)
            end
            
            -- QBCoreの外観を復元（reloadskin）
            Wait(500)
            TriggerEvent('qb-clothes:client:loadPlayerSkin')
            debugPrint('Player skin reloaded')
            
            -- reloadskin後にPedを再取得して可視性を再設定
            Wait(500)
            playerPed = PlayerPedId()
            
            -- カメラと可視性をリセット
            SetEntityVisible(playerPed, true, false)
            SetEntityAlpha(playerPed, 255, false)
            ResetEntityAlpha(playerPed)
            SetEntityCollision(playerPed, true, true)
            
            -- 一人称視点を強制的にリセット
            SetFollowPedCamViewMode(0)
            Wait(100)
            SetFollowPedCamViewMode(4)
            
            -- 再度可視性を設定
            for i = 1, 3 do
                SetEntityVisible(playerPed, true, false)
                NetworkSetEntityInvisibleToNetwork(playerPed, false)
                Wait(100)
            end
            
            debugPrint('Model restored successfully')
        else
            debugPrint('Failed to load original model, using reloadskin')
            -- フォールバック: QBCoreのreloadskinを使用
            Wait(500)
            TriggerEvent('qb-clothes:client:loadPlayerSkin')
            Wait(500)
            
            playerPed = PlayerPedId()
            SetEntityCoords(playerPed, coords.x, coords.y, coords.z, false, false, false, true)
            SetEntityHeading(playerPed, heading)
            
            -- 可視性を確保
            SetEntityVisible(playerPed, true, false)
            SetEntityAlpha(playerPed, 255, false)
            ResetEntityAlpha(playerPed)
            SetEntityCollision(playerPed, true, true)
            NetworkSetEntityInvisibleToNetwork(playerPed, false)
            
            -- カメラをリセット
            SetFollowPedCamViewMode(0)
            Wait(100)
            SetFollowPedCamViewMode(4)
            
            -- 再度可視性を設定
            for i = 1, 3 do
                SetEntityVisible(playerPed, true, false)
                Wait(100)
            end
            
            debugPrint('Player skin reloaded (fallback)')
        end
    end
    
    -- 体力とアーマーを復元
    Wait(100)
    playerPed = PlayerPedId()
    SetEntityMaxHealth(playerPed, 200)
    
    if originalHealth then
        local healthToSet = math.min(originalHealth, 200)
        if healthToSet < 100 then healthToSet = 100 end
        SetEntityHealth(playerPed, healthToSet)
        debugPrint('Health restored to: ' .. healthToSet)
    else
        SetEntityHealth(playerPed, 200)
    end
    
    if originalArmor then
        SetPedArmour(playerPed, math.min(originalArmor, 100))
        debugPrint('Armor restored to: ' .. originalArmor)
    end
    
    -- タイマー停止
    if timerThread then
        timerThread = nil
    end
    
    -- 状態リセット
    isEquipped = false
    originalPedModel = nil
    originalHealth = nil
    originalArmor = nil
    timeRemaining = 0
    
    if not silent then
        showNotification(Config.Notifications.Unequipped, 'info')
    end
    
    debugPrint('Heavy armor unequipped')
end

-- タイマー開始
function startTimer()
    if timerThread then return end
    
    CreateThread(function()
        timerThread = true
        
        while isEquipped and timeRemaining > 0 do
            Wait(1000)
            timeRemaining = timeRemaining - 1
            
            -- 残り時間表示（30秒刻み、または最後の10秒）
            if timeRemaining % 30 == 0 or timeRemaining <= 10 then
                local message = string.format(Config.Notifications.TimeRemaining, timeRemaining)
                showNotification(message, 'info')
            end
            
            debugPrint('Time remaining: ' .. timeRemaining)
        end
        
        -- 時間切れ
        if isEquipped and timeRemaining <= 0 then
            showNotification(Config.Notifications.TimeExpired, 'warning')
            unequipHeavyArmor(true)
        end
        
        timerThread = nil
    end)
end

-- ダメージハンドラー
function startDamageHandler()
    CreateThread(function()
        local playerPed = PlayerPedId()
        local playerId = PlayerId()
        local lastHealthCheck = GetGameTimer()
        
        while isEquipped do
            Wait(0)
            
            playerPed = PlayerPedId()
            playerId = PlayerId()
            
            -- ダメージ軽減を常時適用
            SetPlayerWeaponDamageModifier(playerId, Config.HeavyArmor.DamageMultiplier)
            SetPlayerMeleeWeaponDamageModifier(playerId, Config.HeavyArmor.DamageMultiplier)
            SetPlayerVehicleDamageModifier(playerId, Config.HeavyArmor.DamageMultiplier)
            
            -- 爆発ダメージ耐性を追加
            SetPedCanBeTargetedWhenInjured(playerPed, false)
            SetEntityProofs(playerPed, false, false, true, false, false, false, false, false) -- 爆発ダメージ無効化
            
            -- クリティカルヒットとラグドール無効化
            SetPedSuffersCriticalHits(playerPed, false)
            SetPedCanRagdoll(playerPed, false)
            
            -- ヘッドショット保護（完全無効化）
            if Config.HeavyArmor.HeadshotProtection then
                -- ヘッドショットによるダメージ増加を無効化
                SetPedSuffersCriticalHits(playerPed, false)
            end
            
            -- 体力とアーマーの高速回復（0.1秒ごとにチェック）
            local currentTime = GetGameTimer()
            if currentTime - lastHealthCheck >= 100 then
                local currentHealth = GetEntityHealth(playerPed)
                local currentArmor = GetPedArmour(playerPed)
                
                -- 最大値を下回っている場合は高速回復
                if currentHealth < Config.HeavyArmor.MaxHealth and currentHealth > 0 then
                    -- 0.1秒ごとに100回復 = 1秒あたり1000回復
                    SetEntityHealth(playerPed, math.min(currentHealth + 100, Config.HeavyArmor.MaxHealth))
                end
                
                if currentArmor < Config.HeavyArmor.MaxArmor then
                    -- 0.1秒ごとに50回復 = 1秒あたり500回復
                    SetPedArmour(playerPed, math.min(currentArmor + 50, Config.HeavyArmor.MaxArmor))
                end
                
                lastHealthCheck = currentTime
            end
        end
        
        -- ダメージハンドラー終了時にリセット
        playerPed = PlayerPedId()
        playerId = PlayerId()
        SetPlayerWeaponDamageModifier(playerId, 1.0)
        SetPlayerMeleeWeaponDamageModifier(playerId, 1.0)
        SetPlayerVehicleDamageModifier(playerId, 1.0)
        SetPedSuffersCriticalHits(playerPed, true)
        SetPedCanRagdoll(playerPed, true)
        SetPedCanBeTargetedWhenInjured(playerPed, true)
        SetEntityProofs(playerPed, false, false, false, false, false, false, false, false)
        
        debugPrint('Damage handler stopped')
    end)
end

-- コマンド登録
RegisterCommand(Config.Command.Name, function()
    if Config.Command.AdminOnly then
        if not isAdmin() then
            showNotification(Config.Notifications.NoPermission, 'error')
            return
        end
    end
    
    if isEquipped then
        unequipHeavyArmor(false)
    else
        equipHeavyArmor()
    end
end, false)

-- プレイヤー死亡時の処理
CreateThread(function()
    while true do
        Wait(1000)
        if isEquipped then
            local playerPed = PlayerPedId()
            -- 実際に死亡している場合のみ解除
            if IsEntityDead(playerPed) or IsPedDeadOrDying(playerPed, true) or GetEntityHealth(playerPed) <= 100 then
                debugPrint('Player died, unequipping heavy armor')
                
                -- タイマー停止
                if timerThread then
                    timerThread = nil
                end
                
                -- 画面エフェクト解除
                if Config.HeavyArmor.EnableScreenEffect then
                    StopScreenEffect(Config.HeavyArmor.ScreenEffect)
                end
                
                -- 状態リセット（モデルは復活時に自動的にQBCoreが復元）
                isEquipped = false
                timeRemaining = 0
                
                -- 武器削除
                RemoveAllPedWeapons(playerPed, true)
                
                debugPrint('Heavy armor state cleared, model will restore on respawn')
                
                -- originalPedModelは復活後に使用するため保持
            end
        end
    end
end)

-- リソース停止時の処理
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName and isEquipped then
        unequipHeavyArmor(true)
    end
end)

-- QBCore 死亡/復活イベント
RegisterNetEvent('hospital:client:Revive', function()
    debugPrint('Player revived')
    
    -- 復活時に元の外観を復元
    if originalPedModel then
        Wait(1000) -- QBCoreの処理を待つ
        
        debugPrint('Restoring player appearance after revive')
        
        -- QBCoreの外観システムを使用して復元
        TriggerEvent('qb-clothes:client:loadPlayerSkin')
        
        Wait(500)
        
        local playerPed = PlayerPedId()
        
        -- 可視性を確実に設定
        for i = 1, 5 do
            SetEntityVisible(playerPed, true, false)
            SetEntityAlpha(playerPed, 255, false)
            ResetEntityAlpha(playerPed)
            SetEntityCollision(playerPed, true, true)
            FreezeEntityPosition(playerPed, false)
            Wait(50)
        end
        
        -- 状態を完全にリセット
        originalPedModel = nil
        originalHealth = nil
        originalArmor = nil
        
        debugPrint('Player appearance restored')
    end
end)

RegisterNetEvent('hospital:client:SetDeadState', function(isDead)
    if isDead and isEquipped then
        debugPrint('Player set to dead state')
        -- 死亡時の処理は別のスレッドで処理
    end
end)

debugPrint('Client script loaded')
