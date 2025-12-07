local QBCore = exports['qb-core']:GetCoreObject()
local sellCooldown = {}

-- 各アイテムのクールダウンを初期化
for itemName, itemConfig in pairs(Config.SellableItems) do
    sellCooldown[itemName] = 0
end

-- NPCの生成
CreateThread(function()
    for k, v in pairs(Config.NPCs) do
        -- NPCの生成
        RequestModel(GetHashKey(v.model))
        while not HasModelLoaded(GetHashKey(v.model)) do
            Wait(1)
        end
        
        local npc = CreatePed(4, GetHashKey(v.model), v.coords.x, v.coords.y, v.coords.z - 1.0, v.coords.w, false, true)
        FreezeEntityPosition(npc, true)
        SetEntityInvincible(npc, true)
        SetBlockingOfNonTemporaryEvents(npc, true)
        
        if v.scenario then
            TaskStartScenarioInPlace(npc, v.scenario, 0, true)
        end
        
        -- ターゲットオプションの追加
        exports['qb-target']:AddTargetEntity(npc, {
            options = {
                {
                    type = "client",
                    event = "ng-sellbills:client:checkSellableItems",
                    icon = "fas fa-hand-holding-usd",
                    label = "アイテムを売る",
                },
            },
            distance = 2.0
        })
        
        -- ブリップの生成（設定で有効な場合）
        if v.blip and v.blip.enabled then
            local blip = AddBlipForCoord(v.coords.x, v.coords.y, v.coords.z)
            SetBlipSprite(blip, v.blip.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, v.blip.scale)
            SetBlipColour(blip, v.blip.color)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(v.blip.label)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

-- クールダウンタイマー
CreateThread(function()
    while true do
        for itemName, cooldown in pairs(sellCooldown) do
            if cooldown > 0 then
                sellCooldown[itemName] = cooldown - 1
            end
        end
        Wait(60000) -- 1分ごとにチェック
    end
end)

-- 売却可能アイテムのチェック
RegisterNetEvent('ng-sellbills:client:checkSellableItems', function()
    -- インベントリから売却可能アイテムをチェック
    QBCore.Functions.TriggerCallback('ng-sellbills:server:getSellableItems', function(sellableItems)
        if #sellableItems > 0 then
            -- 売却可能アイテムがあれば売却ダイアログを表示
            OpenSellDialog(sellableItems)
        else
            lib.notify({
                title = 'アイテム売却',
                description = Config.Notifications.noSellableItems,
                type = 'error'
            })
        end
    end)
end)

-- 売却ダイアログの表示
function OpenSellDialog(sellableItems)
    local options = {}
    
    -- アイテムタイプごとにグループ化
    local itemGroups = {}
    for _, item in pairs(sellableItems) do
        if not itemGroups[item.name] then
            itemGroups[item.name] = {}
        end
        table.insert(itemGroups[item.name], item)
    end
    
    -- 各アイテムタイプのオプションを作成
    for itemName, items in pairs(itemGroups) do
        local itemConfig = Config.SellableItems[itemName]
        if itemConfig then
            -- クールダウンチェック
            if sellCooldown[itemName] and sellCooldown[itemName] > 0 then
                table.insert(options, {
                    title = string.format('%s (クールダウン中)', itemConfig.label),
                    description = string.format('あと%s分待機', sellCooldown[itemName]),
                    icon = itemConfig.icon,
                    disabled = true
                })
            else
                local totalWorth = 0
                local totalCount = 0
                
                -- 総価値と総数を計算
                for _, item in pairs(items) do
                    local worth = CalculateItemWorth(item, itemConfig)
                    local count = tonumber(item.count) or 1
                    totalWorth = totalWorth + (worth * count)
                    totalCount = totalCount + count
                end
                
                -- 販売額を計算
                local sellAmount = math.floor(totalWorth * itemConfig.sellPercentage)
                
                table.insert(options, {
                    title = string.format('%s', itemConfig.label),
                    description = string.format('数量: %s (総額: %s円)', totalCount, totalWorth),
                    icon = itemConfig.icon,
                    metadata = {
                        {label = '総価値', value = string.format('%s円', totalWorth)},
                        {label = '受取額', value = string.format('%s円', sellAmount)},
                        {label = '売却率', value = string.format('%s%%', itemConfig.sellPercentage * 100)}
                    },
                    onSelect = function()
                        ConfirmSell({itemName = itemName, items = items, totalWorth = totalWorth, itemConfig = itemConfig})
                    end
                })
            end
        end
    end
    
    -- 全て売却するオプションを追加
    if #options > 0 then
        local grandTotal = 0
        local grandSellAmount = 0
        local canSellAll = true
        
        for itemName, items in pairs(itemGroups) do
            local itemConfig = Config.SellableItems[itemName]
            if itemConfig and (not sellCooldown[itemName] or sellCooldown[itemName] <= 0) then
                local totalWorth = 0
                for _, item in pairs(items) do
                    local worth = CalculateItemWorth(item, itemConfig)
                    local count = tonumber(item.count) or 1
                    totalWorth = totalWorth + (worth * count)
                end
                grandTotal = grandTotal + totalWorth
                grandSellAmount = grandSellAmount + math.floor(totalWorth * itemConfig.sellPercentage)
            else
                canSellAll = false
            end
        end
        
        if canSellAll and grandTotal > 0 then
            table.insert(options, {
                title = '全て売却',
                description = string.format('総額: %s円 (受取額: %s円)', grandTotal, grandSellAmount),
                icon = 'money-check-alt',
                onSelect = function()
                    ConfirmSell({all = true, itemGroups = itemGroups, totalWorth = grandTotal})
                end
            })
        end
    end
    
    lib.registerContext({
        id = 'sellitems_menu',
        title = 'アイテム売却',
        options = options,
        onExit = function()
            lib.notify({
                title = 'アイテム売却',
                description = Config.Notifications.cancelSale,
                type = 'info'
            })
        end
    })
    
    lib.showContext('sellitems_menu')
end

-- アイテムの価値を計算する関数
function CalculateItemWorth(item, itemConfig)
    if itemConfig.priceType == 'fixed' then
        return itemConfig.fixedPrice
    elseif itemConfig.priceType == 'metadata' and item.metadata and item.metadata[itemConfig.metadataKey] then
        return tonumber(item.metadata[itemConfig.metadataKey]) or 0
    else
        return 0
    end
end

-- 売却確認ダイアログ
function ConfirmSell(data)
    local confirmMsg = ''
    
    if data.all then
        local totalWorth = tonumber(data.totalWorth) or 0
        local totalSellAmount = 0
        
        -- 全アイテムの売却額を計算
        for itemName, items in pairs(data.itemGroups) do
            local itemConfig = Config.SellableItems[itemName]
            if itemConfig then
                local itemTotalWorth = 0
                for _, item in pairs(items) do
                    local worth = CalculateItemWorth(item, itemConfig)
                    local count = tonumber(item.count) or 1
                    itemTotalWorth = itemTotalWorth + (worth * count)
                end
                totalSellAmount = totalSellAmount + math.floor(itemTotalWorth * itemConfig.sellPercentage)
            end
        end
        
        confirmMsg = string.format('全てのアイテム（%s円分）を%s円で売却しますか？', totalWorth, totalSellAmount)
    else
        local itemConfig = data.itemConfig
        local totalWorth = tonumber(data.totalWorth) or 0
        local sellAmount = math.floor(totalWorth * itemConfig.sellPercentage)
        confirmMsg = string.format('%s（%s円分）を%s円で売却しますか？', itemConfig.label, totalWorth, sellAmount)
    end
    
    local alert = lib.alertDialog({
        header = '売却確認',
        content = confirmMsg,
        centered = true,
        cancel = true
    })
    
    if alert == 'confirm' then
        TriggerServerEvent('ng-sellbills:server:sellItems', data)
        
        -- クールダウンを設定
        if data.all then
            for itemName, _ in pairs(data.itemGroups) do
                local itemConfig = Config.SellableItems[itemName]
                if itemConfig then
                    sellCooldown[itemName] = itemConfig.cooldown
                end
            end
        else
            sellCooldown[data.itemName] = data.itemConfig.cooldown
        end
    else
        lib.notify({
            title = 'アイテム売却',
            description = Config.Notifications.cancelSale,
            type = 'info'
        })
    end
end