local QBCore = exports['qb-core']:GetCoreObject()

-- データベース関数の読み込み
require 'server.database'

-- ルーム内プレイヤー管理用テーブル
local RoomPlayers = {}
for _, room in ipairs(Config.Rooms) do
    RoomPlayers[room.id] = {}
end

-- ルームの現在のプレイヤー数を取得
local function GetRoomPlayerCount(roomId)
    if not RoomPlayers[roomId] then
        return 0
    end
    
    local count = 0
    for _ in pairs(RoomPlayers[roomId]) do
        count = count + 1
    end
    
    return count
end

-- プレイヤーのインベントリ重量チェック関数
local function CanPlayerReceiveItems(src, itemsToReceive)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    -- ox_inventoryの重量情報を取得
    local inventory = exports.ox_inventory:GetInventory(src, false)
    if not inventory then return false end
    
    local currentWeight = inventory.weight or 0
    local maxWeight = inventory.maxWeight or 120000 -- デフォルト値
    
    -- 受け取り予定のアイテムの総重量を計算
    local totalItemWeight = 0
    for _, item in ipairs(itemsToReceive) do
        local itemData = exports.ox_inventory:Items(item.name)
        if itemData and itemData.weight then
            totalItemWeight = totalItemWeight + (itemData.weight * item.amount)
        end
    end
    
    -- 重量オーバーチェック
    if (currentWeight + totalItemWeight) > maxWeight then
        return false, {
            currentWeight = currentWeight,
            maxWeight = maxWeight,
            itemWeight = totalItemWeight,
            availableSpace = maxWeight - currentWeight
        }
    end
    
    return true, nil
end

-- アイテム追加可能かチェック（個別チェック用）
local function CanAddSingleItem(src, itemName, amount)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    -- ox_inventoryの重量情報を取得
    local inventory = exports.ox_inventory:GetInventory(src, false)
    if not inventory then return true end
    
    local currentWeight = inventory.weight or 0
    local maxWeight = inventory.maxWeight or 120000
    
    local itemData = exports.ox_inventory:Items(itemName)
    if not itemData or not itemData.weight then return true end
    
    local itemWeight = itemData.weight * amount
    
    return (currentWeight + itemWeight) <= maxWeight
end

-- 利用可能なルーム一覧を取得
lib.callback.register('ng-recycling:server:getAvailableRooms', function()
    local availableRooms = {}
    
    for _, room in ipairs(Config.Rooms) do
        local playerCount = GetRoomPlayerCount(room.id)
        local isAvailable = playerCount < room.maxPlayers
        
        table.insert(availableRooms, {
            id = room.id,
            label = room.label,
            playerCount = playerCount,
            maxPlayers = room.maxPlayers,
            isAvailable = isAvailable
        })
    end
    
    return availableRooms
end)

-- ルーティングバケットの設定とルームへのプレイヤー追加
RegisterNetEvent('ng-recycling:server:enterRoom', function(roomId)
    local src = source
    local room = nil
    
    -- 指定されたルームIDが有効かチェック
    for _, roomData in ipairs(Config.Rooms) do
        if roomData.id == roomId then
            room = roomData
            break
        end
    end
    
    if not room then
        TriggerClientEvent('QBCore:Notify', src, '無効なルームIDです', 'error')
        return
    end
    
    -- ルームに空きがあるかチェック
    local playerCount = GetRoomPlayerCount(roomId)
    if playerCount >= room.maxPlayers then
        TriggerClientEvent('QBCore:Notify', src, 'ルームが満員です', 'error')
        return
    end
    
    -- プレイヤーをルームに追加
    RoomPlayers[roomId][src] = true
    
    -- ルーティングバケット設定
    SetPlayerRoutingBucket(src, room.routingBucket)
    
    -- ルーム内の他のプレイヤーに通知
    for playerId in pairs(RoomPlayers[roomId]) do
        if playerId ~= src then
            TriggerClientEvent('QBCore:Notify', playerId, '新しいプレイヤーがルームに入りました', 'info')
        end
    end
    
    -- クライアントに成功通知
    TriggerClientEvent('ng-recycling:client:roomEntered', src, roomId)
end)

-- ルーティングバケットのリセットとルームからのプレイヤー削除
RegisterNetEvent('ng-recycling:server:exitRoom', function(roomId)
    local src = source
    
    -- プレイヤーをルームから削除
    if roomId and RoomPlayers[roomId] then
        RoomPlayers[roomId][src] = nil
        
        -- ルーム内の他のプレイヤーに通知
        for playerId in pairs(RoomPlayers[roomId]) do
            TriggerClientEvent('QBCore:Notify', playerId, 'プレイヤーがルームから退出しました', 'info')
        end
    end
    
    -- ルーティングバケットをリセット
    SetPlayerRoutingBucket(src, 0)
end)

-- プレイヤー切断時のクリーンアップ
AddEventHandler('playerDropped', function()
    local src = source
    
    -- プレイヤーが所属していたルームを探して削除
    for roomId, players in pairs(RoomPlayers) do
        if players[src] then
            RoomPlayers[roomId][src] = nil
            break
        end
    end
end)

-- 荷物納品時の報酬（重量チェック付き + 経験値システム）
RegisterNetEvent('ng-recycling:server:rewardDelivery', function(deliveredCount, allCompleted)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        TriggerClientEvent('QBCore:Notify', src, 'プレイヤー情報が見つかりません', 'error')
        return
    end
    
    -- プレイヤーのレベルデータを取得
    local recyclingData = GetPlayerRecyclingData(Player.PlayerData.citizenid)
    local currentLevel = recyclingData.level
    local currentExp = recyclingData.experience
    
    -- レベルボーナスを取得
    local collectionBonus = GetCollectionBonus(currentLevel)
    
    -- 受け取り予定のアイテムリストを作成
    local itemsToReceive = {}
    local rewardItems = {}
    
    for _, item in ipairs(Config.Rewards.items) do
        -- チャンス計算
        if math.random(1, 100) <= item.chance then
            local amount = math.random(item.min, item.max)
            
            -- レベルボーナスを適用
            amount = math.floor(amount * collectionBonus)
            
            -- すべて完了したらボーナス
            if allCompleted then
                amount = math.floor(amount * 1.2)
            end
            
            -- アイテムを確認
            local itemInfo = exports.ox_inventory:Items(item.name)
            if itemInfo then
                table.insert(itemsToReceive, {name = item.name, amount = amount})
                table.insert(rewardItems, {name = item.name, amount = amount, info = itemInfo})
            end
        end
    end
    
    -- 重量チェック
    local canReceive, weightInfo = CanPlayerReceiveItems(src, itemsToReceive)
    
    if not canReceive then
        -- 重量オーバーの場合の処理
        local currentWeightKg = math.floor(weightInfo.currentWeight / 1000 * 100) / 100
        local maxWeightKg = math.floor(weightInfo.maxWeight / 1000 * 100) / 100
        local itemWeightKg = math.floor(weightInfo.itemWeight / 1000 * 100) / 100
        local availableSpaceKg = math.floor(weightInfo.availableSpace / 1000 * 100) / 100
        
        TriggerClientEvent('QBCore:Notify', src, 
            '重量オーバーです！ 現在: ' .. currentWeightKg .. 'kg/' .. maxWeightKg .. 'kg\n' ..
            '報酬重量: ' .. itemWeightKg .. 'kg (空き: ' .. availableSpaceKg .. 'kg)\n' ..
            'インベントリを整理してから再度納品してください', 'error', 8000)
        
        -- 重量オーバーで受け取れない場合は現金報酬のみ
        local moneyReward = math.random(Config.Rewards.money.min, Config.Rewards.money.max) * deliveredCount
        if allCompleted then
            moneyReward = moneyReward * 1.5
        end
        
        if moneyReward > 0 then
            moneyReward = math.floor(moneyReward)
            Player.Functions.AddMoney('cash', moneyReward)
            TriggerClientEvent('QBCore:Notify', src, '現金報酬のみ受け取りました: $' .. moneyReward, 'info')
        else
            TriggerClientEvent('QBCore:Notify', src, '重量オーバーのため報酬を受け取れませんでした', 'error')
        end
        
        return
    end
    
    -- 重量に問題がない場合は通常の報酬処理
    -- 現金報酬
    local moneyReward = math.random(Config.Rewards.money.min, Config.Rewards.money.max) * deliveredCount
    if allCompleted then
        moneyReward = moneyReward * 1.5 -- 全て完了したらボーナス
    end
    
    moneyReward = math.floor(moneyReward)
    if moneyReward > 0 then
        Player.Functions.AddMoney('cash', moneyReward)
    end
    
    -- アイテム報酬
    local rewardMessage = ""
    if moneyReward > 0 then
        rewardMessage = "受け取った報酬: $" .. moneyReward
    end
    local addedItems = false
    
    -- アイテムを個別に追加（さらなる安全チェック）
    for _, reward in ipairs(rewardItems) do
        if CanAddSingleItem(src, reward.name, reward.amount) then
            local success = exports.ox_inventory:AddItem(src, reward.name, reward.amount)
            if success then
                -- 報酬メッセージに追加
                if rewardMessage == "" then
                    rewardMessage = reward.info.label .. " x" .. reward.amount
                elseif addedItems then
                    rewardMessage = rewardMessage .. ", " .. reward.info.label .. " x" .. reward.amount
                else
                    rewardMessage = rewardMessage .. " と " .. reward.info.label .. " x" .. reward.amount
                    addedItems = true
                end
            else
                -- アイテム追加に失敗した場合
                TriggerClientEvent('QBCore:Notify', src, 
                    reward.info.label .. " x" .. reward.amount .. " の追加に失敗しました", 'error')
            end
        else
            -- 個別アイテムが重量オーバーの場合
            TriggerClientEvent('QBCore:Notify', src, 
                reward.info.label .. " x" .. reward.amount .. " は重量オーバーで受け取れませんでした", 'error')
        end
    end
    
    -- 報酬通知
    if rewardMessage ~= "" then
        TriggerClientEvent('QBCore:Notify', src, rewardMessage, 'success')
    end
    
    -- 経験値を付与（1回の納品で基本経験値）
    local baseExp = 15 * deliveredCount
    if allCompleted then
        baseExp = baseExp * 1.5 -- 全完了ボーナス
    end
    baseExp = math.floor(baseExp)
    
    currentExp = currentExp + baseExp
    local requiredExp = GetRequiredExperience(currentLevel)
    local leveledUp = false
    
    -- レベルアップチェック
    while currentExp >= requiredExp and currentLevel < 50 do
        currentLevel = currentLevel + 1
        currentExp = currentExp - requiredExp
        requiredExp = GetRequiredExperience(currentLevel)
        leveledUp = true
    end
    
    -- 最大レベル到達時の経験値調整
    if currentLevel >= 50 then
        currentExp = 0
    end
    
    -- データベースを更新
    UpdatePlayerExperience(Player.PlayerData.citizenid, currentExp, currentLevel)
    
    -- 経験値とレベルアップ通知
    if leveledUp then
        TriggerClientEvent('QBCore:Notify', src, 
            '🎉 レベルアップ! Lv.' .. currentLevel .. '\n' ..
            '採取量ボーナス: ' .. math.floor(GetCollectionBonus(currentLevel) * 100) .. '%\n' ..
            '取得速度向上: ' .. math.floor(GetSpeedBonus(currentLevel) * 100) .. '%', 
            'success', 7000)
    else
        TriggerClientEvent('QBCore:Notify', src, 
            '経験値 +' .. baseExp .. ' (Lv.' .. currentLevel .. ' ' .. currentExp .. '/' .. requiredExp .. ')', 
            'info', 3000)
    end
    
    -- クライアントにレベル情報を送信
    TriggerClientEvent('ng-recycling:client:updateLevel', src, currentLevel, currentExp, requiredExp)
end)

-- 重量チェック用コールバック（クライアントから呼び出し可能）
lib.callback.register('ng-recycling:server:checkWeight', function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    -- ox_inventoryの重量情報を取得
    local inventory = exports.ox_inventory:GetInventory(src, false)
    if not inventory then return false end
    
    local currentWeight = inventory.weight or 0
    local maxWeight = inventory.maxWeight or 120000
    
    return {
        current = currentWeight,
        max = maxWeight,
        percentage = math.floor((currentWeight / maxWeight) * 100),
        canReceiveMore = currentWeight < maxWeight
    }
end)

-- プレイヤーのレベル情報を取得
lib.callback.register('ng-recycling:server:getPlayerLevel', function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return nil end
    
    local recyclingData = GetPlayerRecyclingData(Player.PlayerData.citizenid)
    local requiredExp = GetRequiredExperience(recyclingData.level)
    local speedBonus = GetSpeedBonus(recyclingData.level)
    local collectionBonus = GetCollectionBonus(recyclingData.level)
    
    return {
        level = recyclingData.level,
        experience = recyclingData.experience,
        requiredExp = requiredExp,
        speedBonus = speedBonus,
        collectionBonus = collectionBonus
    }
end)