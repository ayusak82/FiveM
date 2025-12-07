local QBCore = exports['qb-core']:GetCoreObject()
local isJetpackActive = false
local currentFuel = 100
local jetpackProp = nil
local playerPed = nil
local jetpackThrust = nil

-- ====================================
-- ジェットパック装着
-- ====================================
local function EquipJetpack()
    if isJetpackActive then
        lib.notify({
            title = 'ジェットパック',
            description = Config.Notifications.AlreadyEquipped,
            type = 'error'
        })
        return
    end

    playerPed = PlayerPedId()
    
    -- プログレスバー表示
    if lib.progressBar({
        duration = 3000,
        label = 'ジェットパックを装着中...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
        anim = {
            dict = 'anim@heists@box_carry@',
            clip = 'idle'
        },
    }) then
        -- ジェットパックプロップ作成
        local model = `p_parachute_s`
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(100)
        end

        jetpackProp = CreateObject(model, 0, 0, 0, true, true, true)
        -- 位置を調整（プレイヤーの背中に正しく装着）
        AttachEntityToEntity(jetpackProp, playerPed, GetPedBoneIndex(playerPed, 24818), 
            0.0, -0.15, 0.0,  -- X, Y, Z オフセット
            0.0, 0.0, 0.0,    -- 回転
            true, true, false, true, 1, true)
        
        isJetpackActive = true
        currentFuel = Config.MaxFuel
        
        lib.notify({
            title = 'ジェットパック',
            description = Config.Notifications.Equipped,
            type = 'success'
        })
        
        -- ジェットパック制御ループ開始
        CreateThread(function()
            JetpackControlLoop()
        end)
        
        -- 燃料消費ループ開始
        CreateThread(function()
            FuelConsumptionLoop()
        end)
        
        -- パーティクルエフェクトループ
        CreateThread(function()
            JetpackEffectsLoop()
        end)
    end
end

-- ====================================
-- ジェットパック解除
-- ====================================
local function UnequipJetpack()
    if not isJetpackActive then
        return
    end

    isJetpackActive = false
    
    if DoesEntityExist(jetpackProp) then
        DeleteEntity(jetpackProp)
        jetpackProp = nil
    end
    
    -- ラグドールを有効化
    SetPedCanRagdoll(playerPed, true)
    ClearPedTasksImmediately(playerPed)
    
    -- パーティクルをクリーンアップ
    if jetpackThrust then
        StopParticleFxLooped(jetpackThrust, 0)
        jetpackThrust = nil
    end
    
    lib.notify({
        title = 'ジェットパック',
        description = Config.Notifications.Unequipped,
        type = 'info'
    })
end

-- ====================================
-- ジェットパック制御ループ
-- ====================================
function JetpackControlLoop()
    -- パーティクルアセットをロード
    RequestNamedPtfxAsset("core")
    while not HasNamedPtfxAssetLoaded("core") do
        Wait(100)
    end
    
    while isJetpackActive do
        Wait(0)
        
        if currentFuel <= 0 then
            lib.notify({
                title = 'ジェットパック',
                description = Config.Notifications.NoFuel,
                type = 'error'
            })
            UnequipJetpack()
            break
        end
        
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local playerHeading = GetEntityHeading(playerPed)
        
        -- 落下状態を無効化
        SetPedCanRagdoll(playerPed, false)
        
        -- 重力を打ち消す
        local velocity = GetEntityVelocity(playerPed)
        SetEntityVelocity(playerPed, velocity.x, velocity.y, 0.0)
        
        -- 高度制限チェック
        local groundZ = GetHeightmapBottomZForPosition(playerCoords.x, playerCoords.y)
        local currentHeight = playerCoords.z - groundZ
        
        local isThrusting = false
        
        -- 上昇 (W key)
        if IsControlPressed(0, Config.Keys.MoveUp) then
            if currentHeight < Config.MaxHeight then
                local velocity = GetEntityVelocity(playerPed)
                SetEntityVelocity(playerPed, velocity.x, velocity.y, Config.Speed.Up)
                isThrusting = true
            else
                lib.notify({
                    title = 'ジェットパック',
                    description = Config.Notifications.MaxHeight,
                    type = 'warning',
                    duration = 1000
                })
            end
        end
        
        -- 下降 (S key)
        if IsControlPressed(0, Config.Keys.MoveDown) then
            local velocity = GetEntityVelocity(playerPed)
            SetEntityVelocity(playerPed, velocity.x, velocity.y, -Config.Speed.Down)
        end
        
        -- 前進 (Shift)
        if IsControlPressed(0, 21) then -- Left Shift
            local forwardVector = GetEntityForwardVector(playerPed)
            local velocity = GetEntityVelocity(playerPed)
            SetEntityVelocity(playerPed, 
                forwardVector.x * Config.Speed.Forward, 
                forwardVector.y * Config.Speed.Forward, 
                velocity.z
            )
            isThrusting = true
        end
        
        -- 後退 (Ctrl)
        if IsControlPressed(0, 36) then -- Left Ctrl
            local forwardVector = GetEntityForwardVector(playerPed)
            local velocity = GetEntityVelocity(playerPed)
            SetEntityVelocity(playerPed, 
                -forwardVector.x * Config.Speed.Backward, 
                -forwardVector.y * Config.Speed.Backward, 
                velocity.z
            )
        end
        
        -- 左旋回 (A key)
        if IsControlPressed(0, Config.Keys.TurnLeft) then
            SetEntityHeading(playerPed, playerHeading + 3.0)
        end
        
        -- 右旋回 (D key)
        if IsControlPressed(0, Config.Keys.TurnRight) then
            SetEntityHeading(playerPed, playerHeading - 3.0)
        end
        
        -- 飛行アニメーション（Iron Manスタイル）
        if isThrusting then
            if not IsEntityPlayingAnim(playerPed, 'swimming@swim_underwater', 'swim_dive', 3) then
                RequestAnimDict('swimming@swim_underwater')
                while not HasAnimDictLoaded('swimming@swim_underwater') do
                    Wait(100)
                end
                TaskPlayAnim(playerPed, 'swimming@swim_underwater', 'swim_dive', 8.0, -8.0, -1, 1, 0, false, false, false)
            end
        else
            -- ホバリングアニメーション
            if not IsEntityPlayingAnim(playerPed, 'amb@world_human_stand_impatient@male@no_sign@base', 'base', 3) then
                RequestAnimDict('amb@world_human_stand_impatient@male@no_sign@base')
                while not HasAnimDictLoaded('amb@world_human_stand_impatient@male@no_sign@base') do
                    Wait(100)
                end
                TaskPlayAnim(playerPed, 'amb@world_human_stand_impatient@male@no_sign@base', 'base', 8.0, -8.0, -1, 1, 0, false, false, false)
            end
        end
        
        -- 燃料表示（HUD）- よりかっこよく
        DrawAdvancedText(0.905, 0.965, 0.005, 0.0028, 0.6, "FUEL", 255, 255, 255, 255, 4, 0)
        DrawAdvancedText(0.905, 0.990, 0.005, 0.0028, 0.8, string.format("%.0f%%", currentFuel), 0, 255, 0, 255, 4, 0)
        
        -- 燃料バー
        DrawRect(0.905, 0.990, 0.05, 0.008, 0, 0, 0, 150)
        DrawRect(0.905 - (0.025 - (0.05 * currentFuel / 100) / 2), 0.990, 0.05 * currentFuel / 100, 0.006, 0, 255, 0, 255)
    end
    
    -- ループ終了時にラグドール解除
    SetPedCanRagdoll(playerPed, true)
    RemoveNamedPtfxAsset("core")
end

-- ====================================
-- ジェットパックエフェクトループ
-- ====================================
function JetpackEffectsLoop()
    while isJetpackActive do
        Wait(0)
        
        if Config.Effects.EnableParticles then
            local isMoving = IsControlPressed(0, Config.Keys.MoveUp) or 
                           IsControlPressed(0, 21) or
                           IsControlPressed(0, 36)
            
            if isMoving then
                -- 炎のエフェクト
                UseParticleFxAssetNextCall("core")
                StartNetworkedParticleFxNonLoopedOnEntity(
                    "exp_grd_bzgas_smoke",
                    jetpackProp,
                    0.0, 0.0, -0.5,
                    0.0, 0.0, 0.0,
                    0.5,
                    false, false, false
                )
                
                Wait(100)
            end
        end
    end
end

-- ====================================
-- 燃料消費ループ
-- ====================================
function FuelConsumptionLoop()
    while isJetpackActive do
        Wait(1000)
        
        if currentFuel > 0 then
            currentFuel = currentFuel - Config.FuelConsumption
            if currentFuel < 0 then
                currentFuel = 0
            end
        end
    end
end

-- ====================================
-- 高度なテキスト描画関数
-- ====================================
function DrawAdvancedText(x, y, w, h, scale, text, r, g, b, a, font, jus)
    SetTextFont(font)
    SetTextProportional(0)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextJustification(jus)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x - 0.1 + w, y - 0.02 + h)
end

-- ====================================
-- アイテム使用イベント
-- ====================================
RegisterNetEvent('ng-jetpack:client:useJetpack', function()
    if isJetpackActive then
        UnequipJetpack()
    else
        EquipJetpack()
    end
end)

-- ====================================
-- デバッグコマンド
-- ====================================
if Config.Debug then
    RegisterCommand(Config.DebugCommand, function()
        if isJetpackActive then
            UnequipJetpack()
        else
            EquipJetpack()
        end
    end, false)
end

-- ====================================
-- リソース停止時のクリーンアップ
-- ====================================
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if isJetpackActive then
        UnequipJetpack()
    end
end)