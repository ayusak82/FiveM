local QBCore = exports['qb-core']:GetCoreObject()
local thermalBlockActive = false
local thermalBlockTimer = nil

-- タイマー関数
local function setTimeout(callback, ms)
    local timerId = 0
    CreateThread(function()
        timerId = GetGameTimer() + ms
        Wait(ms)
        if GetGameTimer() >= timerId then
            callback()
        end
    end)
    return timerId
end

local function clearTimeout(timerId)
    if timerId ~= nil then
        timerId = 0
    end
end

-- サーマルビジョンからの隠蔽状態を設定する関数
local function SetThermalBlockState(state)
    if Config.Debug then
        print('サーマルブロック状態:', state)
    end
    
    thermalBlockActive = state
    local ped = PlayerPedId()
    
    -- サーマルビジョンでのプレイヤーの可視性を設定
    if state then
        -- サーマルビジョンで熱シグニチャを無効化する複数の方法を組み合わせる
        
        -- 方法1: 熱シグネチャを完全に無効化
        SetPedHeatscaleOverride(ped, 0)
        SeethroughSetHeatscale(0, 0)
        
        -- 方法2: サーマルカメラで検出対象外に設定
        SetEntityCanBeDamaged(ped, false)  -- ダメージ受け付けない状態は熱検出にも影響
        
        -- 方法3: 切断されたPedとしてマーク（熱をもたない）
        FreezeEntityPosition(ped, true)  -- 一時的に固定（熱シグネチャへの影響あり）
        Wait(10)
        FreezeEntityPosition(ped, false)
    else
        -- 通常の状態に戻す
        SetPedHeatscaleOverride(ped, 1.0)
        SeethroughSetHeatscale(1, 1)
        SetEntityCanBeDamaged(ped, true)
    end
    
    if state then
        -- 通知を表示
        lib.notify({
            title = Config.Notifications.ItemUsed.title,
            description = string.format(Config.Notifications.ItemUsed.description, Config.EffectDuration),
            type = Config.Notifications.ItemUsed.type
        })
        
        -- アニメーション再生
        lib.requestAnimDict(Config.EmoteDictionary)
        TaskPlayAnim(ped, Config.EmoteDictionary, Config.EmoteName, 8.0, -8.0, -1, 0, 0, false, false, false)
        Wait(1000)
        ClearPedTasks(ped)
        
        -- サーバー側のタイマーを開始
        local success = lib.callback.await('ng-thermal:server:startTimer', false)
        
        -- クライアント側タイマーもセット（バックアップとして）
        if thermalBlockTimer then
            clearTimeout(thermalBlockTimer)
            thermalBlockTimer = nil
        end
        
        thermalBlockTimer = setTimeout(function()
            SetThermalBlockState(false)
        end, Config.EffectDuration * 1000)
    else
        -- 効果終了の通知
        lib.notify({
            title = Config.Notifications.ItemExpired.title,
            description = Config.Notifications.ItemExpired.description,
            type = Config.Notifications.ItemExpired.type
        })
    end
end

-- サーマル効果の終了処理
local function EndThermalBlock()
    SetThermalBlockState(false)
    if Config.Debug then
        print('サーマルブロック効果が終了しました')
    end
end

-- アイテム使用時のコールバック
local function UseItem(data, slot)
    -- アイテムの使用制限チェック
    if #Config.RestrictedJobs > 0 then
        local playerJob = QBCore.Functions.GetPlayerData().job.name
        local allowed = false
        
        for _, job in ipairs(Config.RestrictedJobs) do
            if playerJob == job then
                allowed = true
                break
            end
        end
        
        if not allowed then
            lib.notify({
                title = 'エラー',
                description = 'このアイテムを使用する権限がありません',
                type = 'error'
            })
            return
        end
    end
    
    -- すでに効果が発動している場合は使用できない
    if thermalBlockActive then
        lib.notify({
            title = 'エラー',
            description = 'すでにサーマル遮断効果が有効です',
            type = 'error'
        })
        return
    end
    
    -- アイテムの消費
    if exports.ox_inventory:removeItem(slot) then
        SetThermalBlockState(true)
    end
end

-- ox_inventoryのアイテム使用イベントを登録
exports('thermal_blocker', UseItem)

-- エフェクト終了イベント
RegisterNetEvent('ng-thermal:client:endEffect', function()
    EndThermalBlock()
end)

-- サーマルブロックの効果を継続的に適用するループ
CreateThread(function()
    while true do
        Wait(100)  -- より頻繁にチェック（100ミリ秒ごと）
        
        if thermalBlockActive then
            local ped = PlayerPedId()
            
            -- すべての方法を繰り返し適用
            SetPedHeatscaleOverride(ped, 0)
            SeethroughSetHeatscale(0, 0)
            
            -- サーマルカメラが使用中かどうかをチェック
            if IsSeethroughActive() then
                -- サーマル使用中は追加の対策
                SeethroughSetMaxThickness(0.0)  -- サーマルの透過性を最小に
                SeethroughSetFadeStartDistance(0.0)  -- サーマルの距離を最小に
                SeethroughSetFadeEndDistance(0.1)  -- 表示範囲を極小に
            end
        end
    end
end)

-- 管理者用テストコマンド
RegisterCommand(Config.AdminCommand, function()
    -- サーバーサイドで権限チェックを行う
    local isAdmin = lib.callback.await('ng-thermal:server:checkAdmin', false)
    if isAdmin then
        SetThermalBlockState(not thermalBlockActive)
    else
        lib.notify({
            title = 'エラー',
            description = '管理者のみがこのコマンドを使用できます',
            type = 'error'
        })
    end
end, false)

-- リソース再起動時に効果をリセット
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() and thermalBlockActive then
        local ped = PlayerPedId()
        
        -- すべての効果をリセット
        SetPedHeatscaleOverride(ped, 1.0)
        SeethroughSetHeatscale(1, 1)
        SetEntityCanBeDamaged(ped, true)
        
        -- サーマル設定を元に戻す（可能であれば）
        if IsSeethroughActive() then
            SeethroughSetMaxThickness(Config.DefaultThermalSettings.MaxThickness or 10.0)
            SeethroughSetFadeStartDistance(Config.DefaultThermalSettings.FadeStart or 100.0)
            SeethroughSetFadeEndDistance(Config.DefaultThermalSettings.FadeEnd or 500.0)
        end
    end
end)