local QBCore = exports['qb-core']:GetCoreObject()
local activeMissions = {} -- 実行中のミッションを管理

-- ミッション開始リクエスト
RegisterNetEvent('ng-viptransport:requestMission', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- 既にミッション中かチェック
    if activeMissions[src] then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'ミッション実行中',
            description = '既にミッションを実行中です',
            type = 'error'
        })
        return
    end
    
    -- 他のプレイヤーがミッション中かチェック
    for playerId, _ in pairs(activeMissions) do
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'ミッション使用中',
            description = '他のプレイヤーがミッションを実行中です',
            type = 'error'
        })
        return
    end
    
    -- ミッション開始許可
    activeMissions[src] = true
    TriggerClientEvent('ng-viptransport:startMission', src)
end)

-- ミッション完了処理
RegisterNetEvent('ng-viptransport:completeMission', function(elapsedTime)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- ミッション状態をクリア
    activeMissions[src] = nil
    
    -- 基本報酬
    local reward = Config.Rewards.base
    local bonusAmount = 0
    local bonusText = ""
    
    -- ボーナス計算
    for _, bonus in ipairs(Config.Rewards.bonus) do
        if elapsedTime <= bonus.time then
            bonusAmount = bonus.amount
            local minutes = math.floor(bonus.time / 60)
            bonusText = string.format(" (+ $%s ボーナス: %d分以内)", bonusAmount, minutes)
            break
        end
    end
    
    local totalReward = reward + bonusAmount
    
    -- 報酬付与
    Player.Functions.AddMoney('cash', totalReward, 'vip-transport-mission')
    
    -- 完了通知
    local minutes = math.floor(elapsedTime / 60)
    local seconds = math.floor(elapsedTime % 60)
    local timeText = string.format("%02d:%02d", minutes, seconds)
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = Config.Notifications.missionComplete.title,
        description = string.format('報酬: $%s%s\nクリアタイム: %s', totalReward, bonusText, timeText),
        type = Config.Notifications.missionComplete.type,
        duration = 7000
    })
    
    -- ログ出力（デバッグ用）
    print(string.format('[VIP Transport] Player %s completed mission in %s - Reward: $%s', 
        Player.PlayerData.citizenid, 
        timeText, 
        totalReward
    ))
end)

-- ミッション失敗処理
RegisterNetEvent('ng-viptransport:failMission', function()
    local src = source
    
    -- ミッション状態をクリア
    activeMissions[src] = nil
end)

-- ミッションキャンセル処理
RegisterNetEvent('ng-viptransport:cancelMission', function()
    local src = source
    
    -- ミッション状態をクリア
    if activeMissions[src] then
        activeMissions[src] = nil
        print(string.format('[VIP Transport] Player %s cancelled mission', src))
    end
end)

-- プレイヤー切断時のクリーンアップ
AddEventHandler('playerDropped', function()
    local src = source
    
    if activeMissions[src] then
        activeMissions[src] = nil
        print(string.format('[VIP Transport] Player %s disconnected during mission - Mission cleared', src))
    end
end)