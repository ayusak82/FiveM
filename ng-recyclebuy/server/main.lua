local QBCore = exports['qb-core']:GetCoreObject()

-- デバッグ出力関数
local function DebugPrint(...)
    if not Config.Debug then return end
    local args = {...}
    local message = ''
    for i = 1, #args do
        message = message .. tostring(args[i]) .. ' '
    end
    print('^3[DEBUG]^7 ' .. message)
end

-- エラー出力関数
local function ErrorPrint(...)
    local args = {...}
    local message = ''
    for i = 1, #args do
        message = message .. tostring(args[i]) .. ' '
    end
    print('^1[ERROR]^7 ' .. message)
end

-- 成功出力関数
local function SuccessPrint(...)
    if not Config.Debug then return end
    local args = {...}
    local message = ''
    for i = 1, #args do
        message = message .. tostring(args[i]) .. ' '
    end
    print('^2[SUCCESS]^7 ' .. message)
end

-- アイテム売却処理
QBCore.Functions.CreateCallback('ng-recyclebuy:server:sellItem', function(source, cb, itemName, amount, price)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        ErrorPrint('Player not found:', src)
        cb(false, 'プレイヤーが見つかりません')
        return
    end
    
    DebugPrint('Player', src, 'attempting to sell', amount, 'x', itemName, 'at price', price)
    
    -- アイテムが設定に存在するか確認
    if not Config.RecycleItems[itemName] then
        ErrorPrint('Item not in recycle list:', itemName)
        cb(false, 'このアイテムは買い取れません')
        return
    end
    
    -- 価格が正しいか確認（不正防止）
    if Config.RecycleItems[itemName] ~= price then
        ErrorPrint('Price mismatch for', itemName, '- Expected:', Config.RecycleItems[itemName], 'Got:', price)
        cb(false, '価格が一致しません')
        return
    end
    
    -- プレイヤーがアイテムを持っているか確認
    local itemCount = exports.ox_inventory:GetItemCount(src, itemName)
    
    if itemCount < amount then
        ErrorPrint('Player', src, 'does not have enough', itemName, '- Has:', itemCount, 'Needs:', amount)
        cb(false, 'アイテムが不足しています')
        return
    end
    
    -- アイテムを削除
    local removed = exports.ox_inventory:RemoveItem(src, itemName, amount)
    
    if not removed then
        ErrorPrint('Failed to remove item', itemName, 'from player', src)
        cb(false, 'アイテムの削除に失敗しました')
        return
    end
    
    -- 合計金額を計算
    local totalPrice = price * amount
    
    -- プレイヤーに現金を追加
    Player.Functions.AddMoney('cash', totalPrice, 'recycle-sell')
    
    SuccessPrint('Player', src, 'sold', amount, 'x', itemName, 'for $', totalPrice)
    
    -- アイテムのラベルを取得
    local itemData = exports.ox_inventory:Items(itemName)
    local itemLabel = itemData and itemData.label or itemName
    
    cb(true, itemLabel)
end)

-- リソース起動時のメッセージ
CreateThread(function()
    print('^2[ng-recyclebuy]^7 Recycle Buy script started successfully')
    print('^2[ng-recyclebuy]^7 Author: NCCGr | Contact: Discord - ayusak')
end)
