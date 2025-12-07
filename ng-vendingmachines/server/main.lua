local QBCore = exports['qb-core']:GetCoreObject()

-- データベーステーブルの作成
CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS ]]..Config.DatabaseTable..[[ (
            id INT AUTO_INCREMENT PRIMARY KEY,
            machine_id INT NOT NULL,
            item_name VARCHAR(50) NOT NULL,
            price INT NOT NULL,
            stock INT NOT NULL,
            UNIQUE(machine_id, item_name)
        )
    ]])
end)

-- キャッシュデータ
local vendingData = {}

-- 自販機データの初期化/読み込み
local function InitVendingMachines()
    -- データベースから自販機商品データの取得
    MySQL.query('SELECT * FROM ' .. Config.DatabaseTable, {}, function(results)
        if results and #results > 0 then
            -- 結果をキャッシュデータに変換
            for _, item in ipairs(results) do
                if not vendingData[item.machine_id] then
                    vendingData[item.machine_id] = {}
                end
                
                vendingData[item.machine_id][item.item_name] = {
                    price = item.price,
                    stock = item.stock
                }
            end
        end
        
        -- 初期データを設定（DBに存在しないアイテムの場合）
        for machineId, machine in pairs(Config.VendingMachines) do
            if not vendingData[machineId] then
                vendingData[machineId] = {}
                
                -- デフォルトアイテムを設定
                for _, defaultItem in ipairs(Config.DefaultItems) do
                    -- データベースに保存
                    MySQL.insert('INSERT INTO ' .. Config.DatabaseTable .. ' (machine_id, item_name, price, stock) VALUES (?, ?, ?, ?)',
                        {machineId, defaultItem.name, defaultItem.price, defaultItem.stock},
                        function() end
                    )
                    
                    -- キャッシュに保存
                    vendingData[machineId][defaultItem.name] = {
                        price = defaultItem.price,
                        stock = defaultItem.stock
                    }
                end
            end
        end
    end)
end

-- サーバー起動時に初期化
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    InitVendingMachines()
end)

-- 自販機データの取得（クライアント向け）
lib.callback.register('ng-vendingmachines:server:getMachineData', function(source, machineId)
    return vendingData[machineId] or {}
end)

-- 商品の購入処理
lib.callback.register('ng-vendingmachines:server:purchaseItem', function(source, machineId, itemName, amount, paymentType)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return false, 'プレイヤーが見つかりません' end
    if not vendingData[machineId] then return false, '自販機データが見つかりません' end
    if not vendingData[machineId][itemName] then return false, '商品が見つかりません' end
    
    local itemData = vendingData[machineId][itemName]
    
    -- 数量パラメータの確認
    amount = tonumber(amount) or 1
    if amount <= 0 then amount = 1 end
    
    -- 在庫チェック
    if itemData.stock < amount then
        return false, '在庫が足りません'
    end
    
    -- お金のチェック
    local price = itemData.price * amount
    local moneyType = paymentType or 'cash'
    
    if moneyType == 'cash' then
        local cash = Player.PlayerData.money['cash']
        if cash < price then
            return false, Config.Text.notEnoughMoney
        end
        Player.Functions.RemoveMoney('cash', price, '自販機購入: ' .. itemName)
    elseif moneyType == 'bank' then
        local bank = Player.PlayerData.money['bank']
        if bank < price then
            return false, '銀行残高が足りません'
        end
        Player.Functions.RemoveMoney('bank', price, '自販機購入: ' .. itemName)
    else
        return false, '支払い方法が無効です'
    end
    
    -- 在庫を減らす
    vendingData[machineId][itemName].stock = itemData.stock - amount
    
    -- DBアップデート
    MySQL.update('UPDATE ' .. Config.DatabaseTable .. ' SET stock = ? WHERE machine_id = ? AND item_name = ?',
        {vendingData[machineId][itemName].stock, machineId, itemName}
    )
    
    -- 設定された職業の金庫にお金を入れる
    local machineConfig = Config.VendingMachines[machineId]
    if machineConfig and machineConfig.jobs then
        -- 最初の職業をデフォルトの収入先とする
        local targetJob = nil
        for job, _ in pairs(machineConfig.jobs) do
            targetJob = job
            break
        end
        
        if targetJob then
            exports['qb-banking']:AddMoney(targetJob, price)
            if Config.Debug then
                print(targetJob .. ' の金庫に $' .. price .. ' 追加されました')
            end
        end
    end
    
    -- アイテムを与える
    Player.Functions.AddItem(itemName, amount)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], 'add', amount)
    
    -- メッセージ表示と成功を返す
    local itemLabel = QBCore.Shared.Items[itemName].label or itemName
    TriggerClientEvent('QBCore:Notify', src, string.format(Config.Text.purchased, itemLabel .. ' x' .. amount), 'success')
    
    return true, 'success'
end)

-- 新しいアイテムを自販機に追加する
lib.callback.register('ng-vendingmachines:server:addNewItem', function(source, machineId, itemName, price, stock)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return false, 'プレイヤーが見つかりません' end
    
    -- 権限チェック
    local hasPermission = false
    local playerJob = Player.PlayerData.job.name
    local playerGrade = Player.PlayerData.job.grade.level
    
    if Config.VendingMachines[machineId] and Config.VendingMachines[machineId].jobs then
        for job, minGrade in pairs(Config.VendingMachines[machineId].jobs) do
            if job == playerJob and playerGrade >= minGrade then
                hasPermission = true
                break
            end
        end
    end
    
    if not hasPermission then
        return false, Config.Text.noPerms
    end
    
    -- アイテムが存在するか確認
    if not QBCore.Shared.Items[itemName] then
        return false, 'アイテムが存在しません'
    end
    
    -- 既に同じアイテムが登録されているか確認
    if vendingData[machineId] and vendingData[machineId][itemName] then
        return false, 'このアイテムは既に登録されています'
    end
    
    -- プレイヤーのアイテムを取得
    local playerItem = Player.Functions.GetItemByName(itemName)
    
    -- 在庫として必要なアイテムをプレイヤーが持っているか確認
    if not playerItem then
        return false, '必要なアイテムを所持していません'
    end
    
    -- アイテム数量のフィールドをチェック（amount または count）
    local itemCount = playerItem.amount or playerItem.count or 0
    
    if itemCount < stock then
        return false, '必要な数のアイテムを所持していません'
    end
    
    -- アイテムを消費
    Player.Functions.RemoveItem(itemName, stock)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], 'remove', stock)
    
    -- キャッシュに追加
    if not vendingData[machineId] then
        vendingData[machineId] = {}
    end
    
    vendingData[machineId][itemName] = {
        price = price,
        stock = stock
    }
    
    -- データベースに追加
    MySQL.insert('INSERT INTO ' .. Config.DatabaseTable .. ' (machine_id, item_name, price, stock) VALUES (?, ?, ?, ?)',
        {machineId, itemName, price, stock}
    )
    
    -- 通知
    local itemLabel = QBCore.Shared.Items[itemName].label or itemName
    TriggerClientEvent('QBCore:Notify', src, itemLabel .. 'を自販機に追加しました', 'success')
    
    return true, 'success'
end)

-- アイテムを自販機から削除する
lib.callback.register('ng-vendingmachines:server:removeItem', function(source, machineId, itemName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return false, 'プレイヤーが見つかりません' end
    
    -- 権限チェック
    local hasPermission = false
    local playerJob = Player.PlayerData.job.name
    local playerGrade = Player.PlayerData.job.grade.level
    
    if Config.VendingMachines[machineId] and Config.VendingMachines[machineId].jobs then
        for job, minGrade in pairs(Config.VendingMachines[machineId].jobs) do
            if job == playerJob and playerGrade >= minGrade then
                hasPermission = true
                break
            end
        end
    end
    
    if not hasPermission then
        return false, Config.Text.noPerms
    end
    
    -- アイテムが存在するか確認
    if not vendingData[machineId] or not vendingData[machineId][itemName] then
        return false, 'このアイテムは登録されていません'
    end
    
    -- 残りの在庫をプレイヤーに返却
    local remainingStock = vendingData[machineId][itemName].stock
    if remainingStock > 0 then
        Player.Functions.AddItem(itemName, remainingStock)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], 'add', remainingStock)
    end
    
    -- キャッシュから削除
    vendingData[machineId][itemName] = nil
    
    -- データベースから削除
    MySQL.query('DELETE FROM ' .. Config.DatabaseTable .. ' WHERE machine_id = ? AND item_name = ?',
        {machineId, itemName}
    )
    
    -- 通知
    local itemLabel = QBCore.Shared.Items[itemName].label or itemName
    TriggerClientEvent('QBCore:Notify', src, itemLabel .. 'を自販機から削除しました', 'success')
    
    return true, 'success'
end)

-- 自販機の在庫補充（権限チェック含む）
lib.callback.register('ng-vendingmachines:server:restockItem', function(source, machineId, itemName, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return false, 'プレイヤーが見つかりません' end
    if not vendingData[machineId] then return false, '自販機データが見つかりません' end
    if not vendingData[machineId][itemName] then return false, '商品が見つかりません' end
    
    -- 権限チェック
    local hasPermission = false
    local playerJob = Player.PlayerData.job.name
    local playerGrade = Player.PlayerData.job.grade.level
    
    if Config.VendingMachines[machineId] and Config.VendingMachines[machineId].jobs then
        for job, minGrade in pairs(Config.VendingMachines[machineId].jobs) do
            if job == playerJob and playerGrade >= minGrade then
                hasPermission = true
                break
            end
        end
    end
    
    if not hasPermission then
        return false, Config.Text.noPerms
    end
    
    -- 補充するアイテムをプレイヤーが持っているか確認
    if Player.Functions.GetItemByName(itemName) and Player.Functions.GetItemByName(itemName).amount >= amount then
        -- アイテムを消費
        Player.Functions.RemoveItem(itemName, amount)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], 'remove', amount)
        
        -- 在庫を増やす
        vendingData[machineId][itemName].stock = vendingData[machineId][itemName].stock + amount
        
        -- DBアップデート
        MySQL.update('UPDATE ' .. Config.DatabaseTable .. ' SET stock = ? WHERE machine_id = ? AND item_name = ?',
            {vendingData[machineId][itemName].stock, machineId, itemName}
        )
        
        -- 通知
        local itemLabel = QBCore.Shared.Items[itemName].label or itemName
        TriggerClientEvent('QBCore:Notify', src, string.format(Config.Text.stockAdded, itemLabel), 'success')
        
        return true, 'success'
    else
        return false, 'アイテムが足りません'
    end
end)

-- 自販機の価格変更（権限チェック含む）
lib.callback.register('ng-vendingmachines:server:updatePrice', function(source, machineId, itemName, newPrice)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return false, 'プレイヤーが見つかりません' end
    if not vendingData[machineId] then return false, '自販機データが見つかりません' end
    if not vendingData[machineId][itemName] then return false, '商品が見つかりません' end
    
    -- 新しい価格が正しいか確認
    if type(newPrice) ~= 'number' or newPrice < 0 then
        return false, '価格が正しくありません'
    end
    
    -- 権限チェック
    local hasPermission = false
    local playerJob = Player.PlayerData.job.name
    local playerGrade = Player.PlayerData.job.grade.level
    
    if Config.VendingMachines[machineId] and Config.VendingMachines[machineId].jobs then
        for job, minGrade in pairs(Config.VendingMachines[machineId].jobs) do
            if job == playerJob and playerGrade >= minGrade then
                hasPermission = true
                break
            end
        end
    end
    
    if not hasPermission then
        return false, Config.Text.noPerms
    end
    
    -- 価格を更新
    vendingData[machineId][itemName].price = newPrice
    
    -- DBアップデート
    MySQL.update('UPDATE ' .. Config.DatabaseTable .. ' SET price = ? WHERE machine_id = ? AND item_name = ?',
        {newPrice, machineId, itemName}
    )
    
    -- 通知
    local itemLabel = QBCore.Shared.Items[itemName].label or itemName
    TriggerClientEvent('QBCore:Notify', src, string.format(Config.Text.priceChanged, itemLabel), 'success')
    
    return true, 'success'
end)

-- 新しい自販機の追加（管理者コマンド用）
QBCore.Commands.Add('addvendingmachine', '新しい自販機を追加します（管理者専用）', {}, false, function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    if not Player.PlayerData.job.name or Player.PlayerData.job.grade.level < 3 then -- 上級管理職のみ
        TriggerClientEvent('QBCore:Notify', src, '権限がありません', 'error')
        return
    end
    
    TriggerClientEvent('ng-vendingmachines:client:createNewMachine', src)
end, 'admin') -- 管理者権限のみ実行可能

-- 新しい自販機をサーバーに追加
RegisterNetEvent('ng-vendingmachines:server:addNewMachine', function(machineData)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player or Player.PlayerData.job.grade.level < 3 then -- 上級管理職のみ
        TriggerClientEvent('QBCore:Notify', src, '権限がありません', 'error')
        return
    end
    
    -- 次の自販機IDを決定
    local nextId = 1
    for id, _ in pairs(Config.VendingMachines) do
        if id >= nextId then
            nextId = id + 1
        end
    end
    
    -- Configに追加
    Config.VendingMachines[nextId] = machineData
    
    -- デフォルトアイテムをデータベースに追加
    for _, defaultItem in ipairs(Config.DefaultItems) do
        -- データベースに保存
        MySQL.insert('INSERT INTO ' .. Config.DatabaseTable .. ' (machine_id, item_name, price, stock) VALUES (?, ?, ?, ?)',
            {nextId, defaultItem.name, defaultItem.price, defaultItem.stock},
            function() end
        )
        
        -- キャッシュに保存
        if not vendingData[nextId] then
            vendingData[nextId] = {}
        end
        
        vendingData[nextId][defaultItem.name] = {
            price = defaultItem.price,
            stock = defaultItem.stock
        }
    end
    
    -- 全クライアントに新しい自販機情報を送信
    TriggerClientEvent('ng-vendingmachines:client:updateVendingMachines', -1, Config.VendingMachines)
    
    -- 通知
    TriggerClientEvent('QBCore:Notify', src, Config.Text.machineRegistered, 'success')
end)

-- クライアントに自販機情報を更新
RegisterNetEvent('ng-vendingmachines:client:updateVendingMachines', function()
    TriggerClientEvent('ng-vendingmachines:client:updateVendingMachines', -1, Config.VendingMachines)
end)