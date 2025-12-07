local QBCore = exports['qb-core']:GetCoreObject()
local isInTransition = false

-- 入場シーケンス開始（暗転のみ）
function StartEntranceSequence()
    if isInTransition then return end
    
    isInTransition = true
    local playerPed = PlayerPedId()
    
    -- プレイヤーを固定
    FreezeEntityPosition(playerPed, true)
    SetPlayerControl(PlayerId(), false, 0)
    
    -- フェードアウト
    DoScreenFadeOut(1000)
    Wait(1000)
    
    -- プレイヤーを地下基地に移動
    SetEntityCoords(playerPed, Config.UndergroundBase.coords.x, Config.UndergroundBase.coords.y, Config.UndergroundBase.coords.z)
    SetEntityHeading(playerPed, Config.UndergroundBase.heading)
    
    -- 基地状態を設定
    SetInBaseState(true)
    
    -- 少し待機
    Wait(1000)
    
    -- フェードイン
    DoScreenFadeIn(1000)
    Wait(500)
    
    -- プレイヤー制御復帰
    FreezeEntityPosition(playerPed, false)
    SetPlayerControl(PlayerId(), true, 0)
    isInTransition = false
    
    -- 通知
    lib.notify({
        title = '地下基地',
        description = '地下基地に入場しました',
        type = 'success'
    })
    
    -- ウェルカムメッセージ
    ShowWelcomeMessage()
end

-- 退場シーケンス開始（暗転のみ）
function StartExitSequence()
    if isInTransition then return end
    
    isInTransition = true
    local playerPed = PlayerPedId()
    
    -- プレイヤーを固定
    FreezeEntityPosition(playerPed, true)
    SetPlayerControl(PlayerId(), false, 0)
    
    -- フェードアウト
    DoScreenFadeOut(1000)
    Wait(1000)
    
    -- プレイヤーを地上に移動
    SetEntityCoords(playerPed, Config.EntranceLocation.coords.x, Config.EntranceLocation.coords.y, Config.EntranceLocation.coords.z)
    SetEntityHeading(playerPed, Config.EntranceLocation.heading)
    
    -- 基地状態をリセット
    SetInBaseState(false)
    
    -- 少し待機
    Wait(500)
    
    -- フェードイン
    DoScreenFadeIn(1000)
    Wait(500)
    
    -- プレイヤー制御復帰
    FreezeEntityPosition(playerPed, false)
    SetPlayerControl(PlayerId(), true, 0)
    isInTransition = false
    
    lib.notify({
        title = '地上復帰',
        description = '地上に戻りました',
        type = 'success'
    })
end

-- ウェルカメッセージ表示
function ShowWelcomeMessage()
    lib.alertDialog({
        header = '地下基地へようこそ',
        content = '化学物質精製と機械部品組み立ての作業が可能です。\n\n各作業ステーションでox_targetを使用してください。\n\nスタミナに注意して作業してください。',
        centered = true,
        cancel = false,
        labels = {
            confirm = '了解'
        }
    })
end

-- 移行中かチェック  
function IsInTransition()
    return isInTransition
end

-- 緊急時リセット
function EmergencyReset()
    if isInTransition then
        local playerPed = PlayerPedId()
        
        -- プレイヤー制御復帰
        FreezeEntityPosition(playerPed, false)
        SetPlayerControl(PlayerId(), true, 0)
        isInTransition = false
        
        -- フェードイン（念のため）
        DoScreenFadeIn(500)
        
        if Config.Debug then
            print('Emergency transition reset executed')
        end
    end
end

-- デバッグコマンド
if Config.Debug then
    RegisterCommand('ng_transition_reset', function()
        EmergencyReset()
        print('Transition system reset')
    end)
    
    RegisterCommand('ng_transition_test', function()
        StartEntranceSequence()
    end)
    
    RegisterCommand('ng_transition_status', function()
        print('In Transition: ' .. tostring(isInTransition))
    end)
end

-- リソース停止時のクリーンアップ
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        EmergencyReset()
    end
end)