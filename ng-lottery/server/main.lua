local QBCore = exports['qb-core']:GetCoreObject()

-- アイテム使用登録（qb-coreのUseable Item）
QBCore.Functions.CreateUseableItem(Config.LotteryItem, function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    -- インベントリシステムを確認
    local hasItem = false
    local itemCount = 0
    
    -- ox_inventoryを使用している場合
    if GetResourceState('ox_inventory') == 'started' then
        itemCount = exports.ox_inventory:Search(source, 'count', Config.LotteryItem)
        hasItem = itemCount > 0
    else
        -- qb-inventoryを使用している場合
        local playerItems = Player.Functions.GetItemByName(Config.LotteryItem)
        if playerItems then
            hasItem = true
            itemCount = playerItems.amount or 0
        end
    end
    
    if hasItem and itemCount > 0 then
        -- クライアントイベントを発火（アイテム削除はplayLotteryで行う）
        TriggerClientEvent('ng-lottery:client:useLotteryItem', source)
        
        if Config.Debug then
            print('^2[ng-lottery] Player ' .. source .. ' opened lottery UI^0')
        end
    else
        -- 通知システムを確認して送信
        if GetResourceState('ox_lib') == 'started' then
            TriggerClientEvent('ox_lib:notify', source, {
                title = '宝くじ',
                description = '宝くじチケットがありません',
                type = 'error'
            })
        else
            TriggerClientEvent('QBCore:Notify', source, '宝くじチケットがありません', 'error')
        end
    end
end)

-- 宝くじ結果処理（アイテム削除も含む）
QBCore.Functions.CreateCallback('ng-lottery:server:playLottery', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then 
        cb({success = false, message = 'プレイヤーデータが見つかりません'})
        return 
    end
    
    -- まずアイテムを削除
    local removed = false
    
    if GetResourceState('ox_inventory') == 'started' then
        removed = exports.ox_inventory:RemoveItem(source, Config.LotteryItem, 1)
    else
        removed = Player.Functions.RemoveItem(Config.LotteryItem, 1)
    end
    
    if not removed then
        cb({success = false, message = '宝くじチケットがありません'})
        return
    end
    
    -- qb-inventoryの場合は通知を更新
    if GetResourceState('ox_inventory') ~= 'started' then
        TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[Config.LotteryItem], "remove", 1)
    end
    
    -- ランダムな報酬額を生成
    local winAmount = math.random(Config.Rewards.minAmount, Config.Rewards.maxAmount)
    
    -- お金を追加
    Player.Functions.AddMoney('cash', winAmount, 'lottery-win')
    
    -- 残りのチケット数を確認
    local hasMoreTickets = false
    local ticketCount = 0
    
    if GetResourceState('ox_inventory') == 'started' then
        ticketCount = exports.ox_inventory:Search(source, 'count', Config.LotteryItem)
    else
        local item = Player.Functions.GetItemByName(Config.LotteryItem)
        if item then
            ticketCount = item.amount or 0
        end
    end
    
    hasMoreTickets = ticketCount > 0
    
    -- ログ記録
    if Config.Debug then
        print(string.format('^2[ng-lottery] Player %s (ID: %s) won $%d (Tickets remaining: %d)^0', 
            GetPlayerName(source), 
            source, 
            winAmount,
            ticketCount
        ))
    end
    
    -- Discord Webhook用のイベント（必要に応じて）
    TriggerEvent('ng-lottery:server:log', {
        player = source,
        identifier = Player.PlayerData.citizenid,
        amount = winAmount,
        timestamp = os.time()
    })
    
    cb({
        success = true,
        amount = winAmount,
        hasMoreTickets = hasMoreTickets,
        ticketCount = ticketCount
    })
end)

-- ログイベント（他のログシステムと連携可能）
RegisterNetEvent('ng-lottery:server:log', function(data)
    -- ここに独自のログ処理を追加可能
    if Config.Debug then
        print('^3[ng-lottery] Log Event:^0')
        print(json.encode(data, {indent = true}))
    end
end)