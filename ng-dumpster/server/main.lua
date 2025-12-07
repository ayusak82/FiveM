local QBCore = exports['qb-core']:GetCoreObject()

-- サーバー側クールダウン管理（座標+モデルハッシュベース）
local dumpsterCooldowns = {}

-- クールダウンチェック関数
local function IsDumpsterOnCooldown(dumpsterId)
    if dumpsterCooldowns[dumpsterId] then
        local currentTime = os.time()
        if currentTime < dumpsterCooldowns[dumpsterId] then
            return true, dumpsterCooldowns[dumpsterId] - currentTime
        else
            -- 期限切れのクールダウンを削除
            dumpsterCooldowns[dumpsterId] = nil
            return false, 0
        end
    end
    return false, 0
end

-- クールダウンを設定
local function SetDumpsterCooldown(dumpsterId)
    local currentTime = os.time()
    dumpsterCooldowns[dumpsterId] = currentTime + (Config.Cooldown / 1000)
end

-- 報酬を計算する関数（修正版）
local function CalculateReward()
    local rand = math.random(1, 100)
    
    -- 何も見つからない判定
    if rand <= Config.Rewards.nothingChance then
        return 'nothing', nil
    end
    
    -- 現金報酬判定
    if Config.Rewards.cash.enabled then
        local cashRand = math.random(1, 100)
        if cashRand <= Config.Rewards.cash.chance then
            local amount = math.random(Config.Rewards.cash.min, Config.Rewards.cash.max)
            return 'cash', {amount = amount}
        end
    end
    
    -- アイテム報酬判定（確率に基づいて1つ選択）
    local totalWeight = 0
    local weightedItems = {}
    
    -- 重み付けテーブルを作成
    for _, item in ipairs(Config.Rewards.items) do
        totalWeight = totalWeight + item.chance
        table.insert(weightedItems, {
            item = item,
            weight = totalWeight
        })
    end
    
    -- 重み付け抽選
    if totalWeight > 0 then
        local itemRand = math.random(1, totalWeight)
        for _, weighted in ipairs(weightedItems) do
            if itemRand <= weighted.weight then
                local amount = math.random(weighted.item.min, weighted.item.max)
                return 'item', {name = weighted.item.name, amount = amount}
            end
        end
    end
    
    -- 何も当たらなかった場合
    return 'nothing', nil
end

-- クールダウンチェックイベント
RegisterNetEvent('ng-dumpster:server:CheckCooldown', function(dumpsterId)
    local src = source
    
    if not dumpsterId or dumpsterId == "" then
        TriggerClientEvent('ng-dumpster:client:CooldownResponse', src, false, '不正なリクエスト')
        return
    end
    
    local onCooldown, remainingTime = IsDumpsterOnCooldown(dumpsterId)
    
    if onCooldown then
        local minutes = math.floor(remainingTime / 60)
        local seconds = remainingTime % 60
        local timeText = string.format('%d分%d秒', minutes, seconds)
        TriggerClientEvent('ng-dumpster:client:CooldownResponse', src, false, timeText)
    else
        TriggerClientEvent('ng-dumpster:client:CooldownResponse', src, true)
    end
end)

-- 報酬取得イベント（修正版）
RegisterNetEvent('ng-dumpster:server:GetReward', function(dumpsterId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    if not dumpsterId or dumpsterId == "" then
        print('[ng-dumpster] エラー: ダンプスターIDが無効です')
        return
    end
    
    -- サーバー側でクールダウン再チェック
    local onCooldown, remainingTime = IsDumpsterOnCooldown(dumpsterId)
    if onCooldown then
        local minutes = math.floor(remainingTime / 60)
        local seconds = remainingTime % 60
        TriggerClientEvent('ng-dumpster:client:RewardNotify', src, 'cooldown', {
            time = string.format('%d分%d秒', minutes, seconds)
        })
        return
    end
    
    -- クールダウンを設定
    SetDumpsterCooldown(dumpsterId)
    
    -- 報酬計算
    local rewardType, rewardData = CalculateReward()
    
    if rewardType == 'item' then
        -- アイテム付与
        local itemData = QBCore.Shared.Items[rewardData.name]
        if itemData then
            Player.Functions.AddItem(rewardData.name, rewardData.amount)
            TriggerClientEvent('inventory:client:ItemBox', src, itemData, 'add', rewardData.amount)
            TriggerClientEvent('ng-dumpster:client:RewardNotify', src, 'item', {
                label = itemData.label,
                amount = rewardData.amount
            })
        else
            TriggerClientEvent('ng-dumpster:client:RewardNotify', src, 'nothing')
        end
    elseif rewardType == 'cash' then
        -- 現金付与
        Player.Functions.AddMoney('cash', rewardData.amount, 'dumpster-search')
        TriggerClientEvent('ng-dumpster:client:RewardNotify', src, 'cash', {
            amount = rewardData.amount
        })
    else
        -- 何も見つからなかった
        TriggerClientEvent('ng-dumpster:client:RewardNotify', src, 'nothing')
    end
end)

-- クールダウンクリーンアップ（メモリ管理）
CreateThread(function()
    while true do
        Wait(300000) -- 5分ごと
        local currentTime = os.time()
        local cleaned = 0
        
        for dumpsterId, expireTime in pairs(dumpsterCooldowns) do
            if currentTime >= expireTime then
                dumpsterCooldowns[dumpsterId] = nil
                cleaned = cleaned + 1
            end
        end
        
        if cleaned > 0 then
            print(string.format('[ng-dumpster] クールダウンクリーンアップ: %d件削除', cleaned))
        end
    end
end)
