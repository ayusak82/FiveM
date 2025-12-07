local QBCore = exports['qb-core']:GetCoreObject()

-- プレイヤーが所持している売却可能アイテムを取得
QBCore.Functions.CreateCallback('ng-sellbills:server:getSellableItems', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb({}) end
    
    local sellableItems = {}
    local items = Player.PlayerData.items
    
    if items then
        for k, v in pairs(items) do
            if v and Config.SellableItems[v.name] then
                local itemConfig = Config.SellableItems[v.name]
                
                -- QBCoreでは、amount または count のどちらかが使用されている可能性があります
                local count = v.amount
                if count == nil then count = v.count end
                if count == nil then count = 1 end -- デフォルト値を設定
                
                local worth = 0
                if itemConfig.priceType == 'fixed' then
                    worth = itemConfig.fixedPrice
                elseif itemConfig.priceType == 'metadata' and v.metadata and v.metadata[itemConfig.metadataKey] then
                    worth = tonumber(v.metadata[itemConfig.metadataKey]) or 0
                end
                
                if worth > 0 then
                    table.insert(sellableItems, {
                        slot = v.slot,
                        name = v.name,
                        count = count,
                        worth = worth,
                        metadata = v.metadata,
                        totalWorth = worth * count -- 総価値 = 価値 × 個数
                    })
                end
            end
        end
    end
    
    cb(sellableItems)
end)

-- アイテムの売却処理
RegisterNetEvent('ng-sellbills:server:sellItems', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- 全て売却する場合
    if data.all then
        local totalReceived = 0
        local totalWorth = 0
        local soldItems = {}
        
        for itemName, items in pairs(data.itemGroups) do
            local itemConfig = Config.SellableItems[itemName]
            if itemConfig then
                local itemWorth = 0
                local itemCount = 0
                
                -- アイテムの削除と価値計算
                for _, itemData in pairs(items) do
                    local item = Player.Functions.GetItemBySlot(itemData.slot)
                    if item and item.name == itemName then
                        local count = item.amount or item.count or 1
                        local worth = 0
                        
                        if itemConfig.priceType == 'fixed' then
                            worth = itemConfig.fixedPrice
                        elseif itemConfig.priceType == 'metadata' and item.metadata and item.metadata[itemConfig.metadataKey] then
                            worth = tonumber(item.metadata[itemConfig.metadataKey]) or 0
                        end
                        
                        if worth > 0 then
                            Player.Functions.RemoveItem(itemName, count, itemData.slot)
                            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], "remove")
                            
                            local itemTotalWorth = worth * count
                            itemWorth = itemWorth + itemTotalWorth
                            itemCount = itemCount + count
                        end
                    end
                end
                
                -- 支払い額を計算
                local payAmount = math.floor(itemWorth * itemConfig.sellPercentage)
                totalReceived = totalReceived + payAmount
                totalWorth = totalWorth + itemWorth
                
                if itemCount > 0 then
                    table.insert(soldItems, {
                        name = itemName,
                        label = itemConfig.label,
                        count = itemCount,
                        worth = itemWorth,
                        received = payAmount
                    })
                end
            end
        end
        
        -- 金額の支払い
        if totalReceived > 0 then
            Player.Functions.AddMoney("cash", totalReceived, "items-sold")
            
            -- 通知
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'アイテム売却',
                description = string.format('全てのアイテム（%s円分）を%s円で売却しました。', totalWorth, totalReceived),
                type = 'success'
            })
            
            -- ログ記録
            logSale(src, Player.PlayerData.citizenid, soldItems, "all")
        end
    else
        -- 特定のアイテムタイプのみ売却する場合
        local itemName = data.itemName
        local itemConfig = data.itemConfig
        local totalReceived = 0
        local totalWorth = 0
        local totalCount = 0
        
        -- アイテムの削除と価値計算
        for _, itemData in pairs(data.items) do
            local item = Player.Functions.GetItemBySlot(itemData.slot)
            if item and item.name == itemName then
                local count = item.amount or item.count or 1
                local worth = 0
                
                if itemConfig.priceType == 'fixed' then
                    worth = itemConfig.fixedPrice
                elseif itemConfig.priceType == 'metadata' and item.metadata and item.metadata[itemConfig.metadataKey] then
                    worth = tonumber(item.metadata[itemConfig.metadataKey]) or 0
                end
                
                if worth > 0 then
                    Player.Functions.RemoveItem(itemName, count, itemData.slot)
                    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], "remove")
                    
                    local itemTotalWorth = worth * count
                    totalWorth = totalWorth + itemTotalWorth
                    totalCount = totalCount + count
                end
            end
        end
        
        -- 支払い額を計算
        totalReceived = math.floor(totalWorth * itemConfig.sellPercentage)
        
        if totalReceived > 0 then
            Player.Functions.AddMoney("cash", totalReceived, "items-sold")
            
            -- 通知
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'アイテム売却',
                description = string.format(Config.Notifications.sellSuccess, totalWorth, itemConfig.label, totalReceived),
                type = 'success'
            })
            
            -- ログ記録
            logSale(src, Player.PlayerData.citizenid, {{
                name = itemName,
                label = itemConfig.label,
                count = totalCount,
                worth = totalWorth,
                received = totalReceived
            }}, "single")
        else
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'アイテム売却',
                description = Config.Notifications.noSellableItems,
                type = 'error'
            })
        end
    end
end)

-- 売却のログを記録する関数
function logSale(source, citizenid, soldItems, saleType)
    local playerName = GetPlayerName(source)
    print(string.format("[ng-sellbills] Player %s (CitizenID: %s) sold items (%s):", playerName, citizenid, saleType))
    
    for _, item in pairs(soldItems) do
        print(string.format("  - %s x%d (%s) - Worth: $%d, Received: $%d", 
            item.label, item.count, item.name, item.worth, item.received))
    end
end