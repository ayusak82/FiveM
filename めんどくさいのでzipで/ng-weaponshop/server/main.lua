local QBCore = exports['qb-core']:GetCoreObject()

-- アイテム購入のコールバック
QBCore.Functions.CreateCallback('ng-weaponshop:server:buyItem', function(source, cb, itemData, paymentMethod)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then 
        cb(false, '不明なエラーが発生しました')
        return
    end
    
    -- 選択されたアイテムの情報を取得
    local item = nil
    for _, v in pairs(Config.Items) do
        if v.name == itemData.name then
            item = v
            break
        end
    end
    
    if not item then
        cb(false, 'アイテムが見つかりませんでした')
        return
    end
    
    -- お金のチェック
    local canPay = false
    if paymentMethod == 'cash' then
        canPay = Player.Functions.RemoveMoney('cash', item.price, "weaponshop-purchase")
    elseif paymentMethod == 'bank' then
        canPay = Player.Functions.RemoveMoney('bank', item.price, "weaponshop-purchase")
    end
    
    if not canPay then
        cb(false, '支払いに必要な金額が不足しています')
        return
    end
    
    -- アイテム付与
    if item.type == 'weapon' then
        -- 武器の場合
        if Player.Functions.AddItem(item.name, 1) then
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item.name], 'add')
            cb(true, item.label .. 'を購入しました')
        else
            -- アイテム付与に失敗した場合はお金を返却
            if paymentMethod == 'cash' then
                Player.Functions.AddMoney('cash', item.price, "weaponshop-refund")
            elseif paymentMethod == 'bank' then
                Player.Functions.AddMoney('bank', item.price, "weaponshop-refund")
            end
            cb(false, 'インベントリがいっぱいです')
        end
    else
        -- 通常アイテム（弾薬など）の場合
        if Player.Functions.AddItem(item.name, 1) then
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item.name], 'add')
            cb(true, item.label .. 'を購入しました')
        else
            -- アイテム付与に失敗した場合はお金を返却
            if paymentMethod == 'cash' then
                Player.Functions.AddMoney('cash', item.price, "weaponshop-refund")
            elseif paymentMethod == 'bank' then
                Player.Functions.AddMoney('bank', item.price, "weaponshop-refund")
            end
            cb(false, 'インベントリがいっぱいです')
        end
    end
end)

-- 複数アイテム購入のコールバック
QBCore.Functions.CreateCallback('ng-weaponshop:server:buyItems', function(source, cb, itemsData, paymentMethod)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then 
        cb(false, '不明なエラーが発生しました')
        return
    end
    
    -- 合計金額を計算
    local totalPrice = 0
    local itemsToGive = {}
    
    for _, cartItem in ipairs(itemsData) do
        -- 選択されたアイテムの情報を取得
        local item = nil
        for _, v in pairs(Config.Items) do
            if v.name == cartItem.name then
                item = v
                break
            end
        end
        
        if not item then
            cb(false, 'アイテムが見つかりませんでした')
            return
        end
        
        -- 数量分の価格を加算
        totalPrice = totalPrice + (item.price * cartItem.quantity)
        
        -- 付与するアイテム情報を保存
        table.insert(itemsToGive, {
            name = item.name,
            label = item.label,
            type = item.type,
            quantity = cartItem.quantity
        })
    end
    
    -- お金のチェック
    local canPay = false
    if paymentMethod == 'cash' then
        canPay = Player.Functions.RemoveMoney('cash', totalPrice, "weaponshop-purchase")
    elseif paymentMethod == 'bank' then
        canPay = Player.Functions.RemoveMoney('bank', totalPrice, "weaponshop-purchase")
    end
    
    if not canPay then
        cb(false, '支払いに必要な金額が不足しています')
        return
    end
    
    -- アイテム付与
    local success = true
    local failedItems = {}
    
    for _, itemInfo in ipairs(itemsToGive) do
        if not Player.Functions.AddItem(itemInfo.name, itemInfo.quantity) then
            table.insert(failedItems, itemInfo.label)
            success = false
        else
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemInfo.name], 'add')
        end
    end
    
    if success then
        cb(true, '購入が完了しました')
    else
        -- 一部アイテムの付与に失敗した場合、お金を返却
        if paymentMethod == 'cash' then
            Player.Functions.AddMoney('cash', totalPrice, "weaponshop-refund")
        elseif paymentMethod == 'bank' then
            Player.Functions.AddMoney('bank', totalPrice, "weaponshop-refund")
        end
        cb(false, 'インベントリがいっぱいです')
    end
end)

-- サーバー起動時のログ
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    
    -- サーバーコンソールに起動メッセージを表示
    print('^2[ng-weaponshop]^7 武器ショップスクリプトが起動しました')
end)

-- 武器ライセンスの確認（オプション機能）
QBCore.Functions.CreateCallback('ng-weaponshop:server:hasWeaponLicense', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    
    if not Player then 
        cb(false) 
        return 
    end
    
    local licenseItem = Player.Functions.GetItemByName("weapon_license")
    cb(licenseItem ~= nil)
end)