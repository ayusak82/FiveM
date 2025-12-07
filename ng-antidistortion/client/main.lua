local QBCore = exports['qb-core']:GetCoreObject()
local onCooldown = false

-- クールダウン管理
RegisterNetEvent('ng-antidistortion:client:setCooldown', function()
    onCooldown = true
    SetTimeout(Config.Cooldown * 1000, function()
        onCooldown = false
    end)
end)

-- クールダウン残り時間取得
RegisterNetEvent('ng-antidistortion:client:notifyCooldown', function(remainingTime)
    lib.notify({
        title = Config.Notifications.cooldown.title,
        description = string.format(Config.Notifications.cooldown.description, remainingTime),
        type = Config.Notifications.cooldown.type,
        duration = Config.Notifications.cooldown.duration
    })
end)

-- ゆがみ対策実行
local function ExecuteAntiDistortion()
    local ped = PlayerPedId()
    
    -- 車両搭乗チェック
    if IsPedInAnyVehicle(ped, false) then
        lib.notify(Config.Notifications.inVehicle)
        return
    end
    
    -- クールダウンチェック
    if onCooldown then
        TriggerServerEvent('ng-antidistortion:server:checkCooldown')
        return
    end
    
    -- サーバーにクールダウン開始を通知
    TriggerServerEvent('ng-antidistortion:server:startCooldown')
    
    -- 実行中通知
    lib.notify(Config.Notifications.executing)
    
    -- 現在の座標と向きを保存
    local originalCoords = GetEntityCoords(ped)
    local originalHeading = GetEntityHeading(ped)
    
    -- 無敵モード有効化
    if Config.GodMode then
        SetEntityInvincible(ped, true)
    end
    
    -- フェードアウト
    if Config.UseFade then
        DoScreenFadeOut(Config.FadeTime)
        Wait(Config.FadeTime)
    end
    
    -- 海にテレポート
    SetEntityCoords(ped, Config.OceanCoords.x, Config.OceanCoords.y, Config.OceanCoords.z, false, false, false, false)
    SetEntityHeading(ped, Config.OceanCoords.w)
    
    -- フェードイン
    if Config.UseFade then
        Wait(500)
        DoScreenFadeIn(Config.FadeTime)
    end
    
    -- カウントダウン表示（海で待機中）
    local countdownSeconds = Config.WaitTime / 1000
    for i = countdownSeconds, 1, -1 do
        lib.notify({
            title = 'ゆがみ対策',
            description = string.format('元の位置に戻ります: %d秒', i),
            type = 'info',
            duration = 1000
        })
        Wait(1000)
    end
    
    -- フェードアウト
    if Config.UseFade then
        DoScreenFadeOut(Config.FadeTime)
        Wait(Config.FadeTime)
    end
    
    -- 元の位置に戻る
    SetEntityCoords(ped, originalCoords.x, originalCoords.y, originalCoords.z, false, false, false, false)
    SetEntityHeading(ped, originalHeading)
    
    -- フェードイン
    if Config.UseFade then
        Wait(500)
        DoScreenFadeIn(Config.FadeTime)
    end
    
    -- 無敵モード解除
    if Config.GodMode then
        SetEntityInvincible(ped, false)
    end
    
    -- 完了通知
    lib.notify(Config.Notifications.complete)
end

-- コマンド登録
RegisterCommand(Config.Command, function()
    ExecuteAntiDistortion()
end, false)