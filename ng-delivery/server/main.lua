-- コアオブジェクトとデータベース初期化
local QBCore = exports['qb-core']:GetCoreObject()

-- 配達の報酬計算
local function CalculateDeliveryReward(difficulty, timeBonus)
    local config = Config.Difficulty[difficulty]
    local baseMoneyReward = math.random(Config.Rewards.Money.Min, Config.Rewards.Money.Max)
    local baseXpReward = math.random(Config.Rewards.Experience.Min, Config.Rewards.Experience.Max)
    
    -- 難易度と時間ボーナスによる調整
    local moneyReward = math.floor(baseMoneyReward * config.Multiplier * (1 + timeBonus * 0.5))
    local xpReward = math.floor(baseXpReward * config.Multiplier * (1 + timeBonus * 0.3))
    
    -- アイテム報酬の決定
    local itemReward = nil
    if math.random(1, 100) <= Config.Rewards.ItemChance then
        local randomItem = Config.Rewards.Items[math.random(#Config.Rewards.Items)]
        local amount = math.random(randomItem.amount.min, randomItem.amount.max)
        
        itemReward = {
            name = randomItem.name,
            amount = amount
        }
    end
    
    return {
        money = moneyReward,
        xp = xpReward,
        item = itemReward
    }
end

-- プレイヤーにアイテムを与える関数
local function GiveItemToPlayer(source, item, amount)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    -- インベントリの空きスペースチェック
    local canCarry = exports.ox_inventory:CanCarryItem(source, item, amount)
    if not canCarry then
        TriggerClientEvent('ox_lib:notify', source, {
            title = '配達システム',
            description = 'インベントリに空きがありません',
            type = Config.Notifications.Error
        })
        return false
    end
    
    -- アイテムの付与
    exports.ox_inventory:AddItem(source, item, amount)
    return true
end

-- プレイヤーにお金を与える関数
local function GiveMoneyToPlayer(source, amount, moneyType)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    Player.Functions.AddMoney(moneyType or 'cash', amount)
    return true
end

-- 配達統計の保存
local function SaveDeliveryStats(citizenid, deliveryCount, totalMoney)
    MySQL.Async.execute(
        'INSERT INTO player_delivery_stats (citizenid, deliveries_completed, total_earnings) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE deliveries_completed = deliveries_completed + ?, total_earnings = total_earnings + ?',
        {citizenid, deliveryCount, totalMoney, deliveryCount, totalMoney},
        function(rowsChanged)
            if Config.Debug then
                print("保存された統計: " .. citizenid .. " - " .. deliveryCount .. "配達, " .. totalMoney .. "稼ぎ")
            end
        end
    )
end

-- データベーステーブルの初期化
MySQL.ready(function()
    MySQL.Async.execute(
        [[
            CREATE TABLE IF NOT EXISTS player_delivery_stats (
                citizenid VARCHAR(50) PRIMARY KEY,
                deliveries_completed INT DEFAULT 0,
                total_earnings INT DEFAULT 0,
                last_delivery TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
            )
        ]],
        {},
        function()
            if Config.Debug then
                print("配達統計テーブルの初期化が完了しました")
            end
        end
    )
end)

-- 配達完了のイベントハンドラ
RegisterNetEvent('ng-delivery:server:CompleteDelivery', function(difficulty, timeBonus)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- 報酬の計算
    local rewards = CalculateDeliveryReward(difficulty, timeBonus)
    
    -- 経験値の付与
    if rewards.xp > 0 then
        -- QBCore経験値システムがある場合
        if Player.Functions.AddXp then
            Player.Functions.AddXp("delivery", rewards.xp)
        end
        
        TriggerClientEvent('ox_lib:notify', src, {
            title = '配達完了',
            description = rewards.xp .. 'XPを獲得しました',
            type = Config.Notifications.Success
        })
    end
    
    -- お金の付与
    if rewards.money > 0 then
        GiveMoneyToPlayer(src, rewards.money)
        
        TriggerClientEvent('ox_lib:notify', src, {
            title = '配達完了',
            description = rewards.money .. '円を獲得しました',
            type = Config.Notifications.Success
        })
    end
    
    -- アイテム報酬の付与
    if rewards.item then
        local success = GiveItemToPlayer(src, rewards.item.name, rewards.item.amount)
        
        if success then
            local itemLabel = QBCore.Shared.Items[rewards.item.name].label or rewards.item.name
            
            TriggerClientEvent('ox_lib:notify', src, {
                title = '配達完了',
                description = itemLabel .. 'を' .. rewards.item.amount .. '個獲得しました',
                type = Config.Notifications.Success
            })
        end
    end
end)

-- 配達失敗のイベントハンドラ
RegisterNetEvent('ng-delivery:server:FailDelivery', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- 失敗のペナルティ（オプション）
    local penalty = math.random(50, 200)
    
    -- プレイヤーの所持金をチェック
    local cash = Player.PlayerData.money.cash
    
    if cash >= penalty then
        GiveMoneyToPlayer(src, -penalty)
        
        TriggerClientEvent('ox_lib:notify', src, {
            title = '配達失敗',
            description = penalty .. '円のペナルティが課されました',
            type = Config.Notifications.Error
        })
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = '配達失敗',
            description = 'お金が足りないため、別のペナルティが課されるかもしれません',
            type = Config.Notifications.Error
        })
    end
end)

-- 配達ジョブ完了のイベントハンドラ
RegisterNetEvent('ng-delivery:server:FinishDeliveryJob', function(deliveryCount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- 最低1つ以上のパッケージを配達していることを確認
    if deliveryCount <= 0 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = '配達システム',
            description = '配達したパッケージがありません。報酬は受け取れません',
            type = Config.Notifications.Error
        })
        return
    end
    
    -- ボーナス報酬の計算 - 配達数に応じてボーナスを増加
    local bonusMultiplier = math.min(deliveryCount * 0.1, 0.5) -- 最大50%ボーナス
    local baseReward = deliveryCount * 100
    local bonusReward = math.floor(baseReward * (1 + bonusMultiplier))
    
    -- ボーナス報酬の付与
    GiveMoneyToPlayer(src, bonusReward)
    
    -- 統計の保存
    SaveDeliveryStats(Player.PlayerData.citizenid, deliveryCount, bonusReward)
    
    -- 配達完了の通知
    TriggerClientEvent('ox_lib:notify', src, {
        title = '配達ジョブ完了',
        description = '合計' .. deliveryCount .. '個のパッケージを配達し、拠点に戻りました！\nボーナス報酬: ' .. bonusReward .. '円',
        type = Config.Notifications.Success
    })
end)

-- コマンド登録
QBCore.Commands.Add('deliverystats', 'あなたの配達統計を確認', {}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    MySQL.Async.fetchAll(
        'SELECT * FROM player_delivery_stats WHERE citizenid = ?',
        {Player.PlayerData.citizenid},
        function(results)
            if results and results[1] then
                local stats = results[1]
                local lastDelivery = stats.last_delivery or "まだ配達していません"
                
                TriggerClientEvent('ox_lib:notify', src, {
                    title = '配達統計',
                    description = '完了した配達: ' .. stats.deliveries_completed .. '\n合計収入: ' .. stats.total_earnings .. '円',
                    type = Config.Notifications.Info,
                    duration = 7000
                })
            else
                TriggerClientEvent('ox_lib:notify', src, {
                    title = '配達統計',
                    description = 'まだ配達の記録がありません',
                    type = Config.Notifications.Info
                })
            end
        end
    )
end)

-- プレイヤーのトップ配達者リストを取得するコマンド
QBCore.Commands.Add('deliverytop', 'トップ配達者リストを表示', {}, false, function(source, args)
    local src = source
    
    MySQL.Async.fetchAll(
        'SELECT p.charinfo, ds.deliveries_completed, ds.total_earnings FROM player_delivery_stats ds JOIN players p ON p.citizenid = ds.citizenid ORDER BY ds.deliveries_completed DESC LIMIT 5',
        {},
        function(results)
            if results and #results > 0 then
                -- プレイヤーにトップリストを表示するための通知
                local message = "【トップ配達者】\n"
                
                for i, result in ipairs(results) do
                    local charInfo = json.decode(result.charinfo)
                    local name = charInfo.firstname .. " " .. charInfo.lastname
                    
                    message = message .. i .. ". " .. name .. " - " .. result.deliveries_completed .. "配達, " .. result.total_earnings .. "円\n"
                end
                
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'トップ配達者',
                    description = message,
                    type = Config.Notifications.Info,
                    duration = 10000
                })
            else
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'トップ配達者',
                    description = 'まだデータがありません',
                    type = Config.Notifications.Info
                })
            end
        end
    )
end)

-- qb-vehiclekeysのサポート
RegisterNetEvent('qb-vehiclekeys:server:AcquireVehicleKeys', function(plate)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- プレイヤーに車両の鍵を与える
    if Config.Debug then
        print('[ng-delivery] サーバー: プレイヤーID ' .. src .. ' に車両鍵が付与されました: ' .. plate)
    end
    
    -- qb-vehiclekeysのイベントを使用（サポートされている場合）
    local hasEvent = pcall(function()
        TriggerClientEvent('qb-vehiclekeys:client:AddKeys', src, plate)
    end)
    
    -- イベントが見つからなかった場合のフォールバック
    if not hasEvent then
        TriggerClientEvent('vehiclekeys:client:SetOwner', src, plate)
    end
end)

-- リソース開始メッセージ
print('[ng-delivery] 配達システムが正常に起動しました')