local QBCore = exports['qb-core']:GetCoreObject()
local placedItems = {}
local itemIdCounter = 0

-- データベーステーブル作成
CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `ng_camping_items` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `owner` varchar(50) NOT NULL,
            `type` varchar(50) NOT NULL,
            `coords` longtext NOT NULL,
            `heading` float NOT NULL,
            `health` int(11) DEFAULT 100,
            `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    -- 既存アイテム読み込み
    loadItemsFromDatabase()
end)

-- データベースからアイテム読み込み
function loadItemsFromDatabase()
    MySQL.query('SELECT * FROM ' .. Config.Database.table, {}, function(result)
        if result then
            for _, row in pairs(result) do
                local coords = json.decode(row.coords)
                placedItems[row.id] = {
                    id = row.id,
                    owner = row.owner,
                    type = row.type,
                    coords = vector3(coords.x, coords.y, coords.z),
                    heading = row.heading,
                    health = row.health
                }
                
                if row.id > itemIdCounter then
                    itemIdCounter = row.id
                end
            end
            
            if Config.Debug then
                print('^2[NG-CAMPING]^7 ' .. #result .. '個のアイテムを読み込みました')
            end
        end
    end)
end

-- プレイヤー参加時に設置済みアイテムを送信
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    Wait(2000) -- クライアント読み込み待機
    TriggerClientEvent('ng-camping:client:loadItems', src, placedItems)
end)

-- アイテム設置処理
RegisterNetEvent('ng-camping:server:placeItem', function(itemType, coords, heading)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local itemConfig = Config.CampingItems[itemType]
    if not itemConfig then return end
    
    -- アイテム所持チェック（臨時で無効化）
    --[[
    local hasItem = exports.ox_inventory:GetItem(src, itemConfig.item, nil, true)
    if not hasItem or hasItem < 1 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = Config.Notifications.error.title,
            description = itemConfig.label .. 'を持っていません',
            type = Config.Notifications.error.type,
            duration = Config.Notifications.error.duration
        })
        return
    end
    --]]
    
    -- 設置数制限チェック
    local playerItems = 0
    for _, item in pairs(placedItems) do
        if item.owner == Player.PlayerData.citizenid then
            playerItems = playerItems + 1
        end
    end
    
    if playerItems >= Config.PlacementLimits.maxItemsPerPlayer then
        TriggerClientEvent('ox_lib:notify', src, {
            title = Config.Notifications.error.title,
            description = '設置限界数に達しています (' .. Config.PlacementLimits.maxItemsPerPlayer .. '個)',
            type = Config.Notifications.error.type,
            duration = Config.Notifications.error.duration
        })
        return
    end
    
    -- アイテム消費（臨時で無効化）
    --[[
    if not exports.ox_inventory:RemoveItem(src, itemConfig.item, 1) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = Config.Notifications.error.title,
            description = 'アイテムの消費に失敗しました',
            type = Config.Notifications.error.type,
            duration = Config.Notifications.error.duration
        })
        return
    end
    --]]
    
    -- 以下は変更なし（アイテムデータ作成部分）
    itemIdCounter = itemIdCounter + 1
    local itemData = {
        id = itemIdCounter,
        owner = Player.PlayerData.citizenid,
        type = itemType,
        coords = coords,
        heading = heading,
        health = itemConfig.health
    }
    
    -- データベースに保存
    MySQL.insert('INSERT INTO ' .. Config.Database.table .. ' (id, owner, type, coords, heading, health) VALUES (?, ?, ?, ?, ?, ?)', {
        itemData.id,
        itemData.owner,
        itemData.type,
        json.encode({x = coords.x, y = coords.y, z = coords.z}),
        itemData.heading,
        itemData.health
    }, function(insertId)
        if insertId then
            -- メモリに追加
            placedItems[itemData.id] = itemData
            
            -- 全プレイヤーに設置通知
            TriggerClientEvent('ng-camping:client:itemPlaced', -1, itemData)
            
            if Config.Debug then
                print('^2[NG-CAMPING]^7 ' .. GetPlayerName(src) .. ' が ' .. itemConfig.label .. ' を設置しました (ID: ' .. itemData.id .. ')')
            end
        else
            -- 失敗時はアイテムを返却（臨時で無効化）
            --exports.ox_inventory:AddItem(src, itemConfig.item, 1)
            TriggerClientEvent('ox_lib:notify', src, {
                title = Config.Notifications.error.title,
                description = '設置に失敗しました',
                type = Config.Notifications.error.type,
                duration = Config.Notifications.error.duration
            })
        end
    end)
end)

-- アイテム撤去処理
RegisterNetEvent('ng-camping:server:removeItem', function(itemId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local item = placedItems[itemId]
    if not item then
        TriggerClientEvent('ox_lib:notify', src, {
            title = Config.Notifications.error.title,
            description = 'アイテムが見つかりません',
            type = Config.Notifications.error.type,
            duration = Config.Notifications.error.duration
        })
        return
    end
    
    -- 所有者チェック
    if item.owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('ox_lib:notify', src, {
            title = Config.Notifications.error.title,
            description = '他の人のアイテムは撤去できません',
            type = Config.Notifications.error.type,
            duration = Config.Notifications.error.duration
        })
        return
    end
    
    local itemConfig = Config.CampingItems[item.type]
    if not itemConfig then return end
    
    -- データベースから削除
    MySQL.query('DELETE FROM ' .. Config.Database.table .. ' WHERE id = ?', {itemId}, function(affectedRows)
        if affectedRows > 0 then
            -- アイテム返却
            --exports.ox_inventory:AddItem(src, itemConfig.item, 1)
            
            -- メモリから削除
            placedItems[itemId] = nil
            
            -- 全プレイヤーに撤去通知
            TriggerClientEvent('ng-camping:client:itemRemoved', -1, itemId, item.type)
            
            if Config.Debug then
                print('^2[NG-CAMPING]^7 ' .. GetPlayerName(src) .. ' が ' .. itemConfig.label .. ' を撤去しました (ID: ' .. itemId .. ')')
            end
        else
            TriggerClientEvent('ox_lib:notify', src, {
                title = Config.Notifications.error.title,
                description = '撤去に失敗しました',
                type = Config.Notifications.error.type,
                duration = Config.Notifications.error.duration
            })
        end
    end)
end)

-- プレイヤー退出時の処理
RegisterNetEvent('QBCore:Server:OnPlayerUnload', function(src)
    -- 必要に応じて処理を追加
end)

-- 管理者コマンド: 全アイテム削除
QBCore.Commands.Add('ng-camping-clear', '全てのキャンプアイテムを削除 (管理者のみ)', {}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- 管理者権限チェック
    if not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('ox_lib:notify', src, {
            title = Config.Notifications.error.title,
            description = '権限がありません',
            type = Config.Notifications.error.type,
            duration = Config.Notifications.error.duration
        })
        return
    end
    
    -- データベースから全削除
    MySQL.query('DELETE FROM ' .. Config.Database.table, {}, function(affectedRows)
        -- メモリクリア
        for itemId, item in pairs(placedItems) do
            TriggerClientEvent('ng-camping:client:itemRemoved', -1, itemId, item.type)
        end
        placedItems = {}
        itemIdCounter = 0
        
        TriggerClientEvent('ox_lib:notify', src, {
            title = Config.Notifications.success.title,
            description = affectedRows .. '個のアイテムを削除しました',
            type = Config.Notifications.success.type,
            duration = Config.Notifications.success.duration
        })
        
        print('^2[NG-CAMPING]^7 管理者 ' .. GetPlayerName(src) .. ' が全アイテムを削除しました')
    end)
end)

-- 管理者コマンド: アイテム情報表示
QBCore.Commands.Add('ng-camping-info', 'キャンプアイテム情報を表示 (管理者のみ)', {}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- 管理者権限チェック
    if not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('ox_lib:notify', src, {
            title = Config.Notifications.error.title,
            description = '権限がありません',
            type = Config.Notifications.error.type,
            duration = Config.Notifications.error.duration
        })
        return
    end
    
    local totalItems = 0
    local itemsByType = {}
    
    for _, item in pairs(placedItems) do
        totalItems = totalItems + 1
        if not itemsByType[item.type] then
            itemsByType[item.type] = 0
        end
        itemsByType[item.type] = itemsByType[item.type] + 1
    end
    
    print('^2[NG-CAMPING INFO]^7')
    print('^3総アイテム数:^7 ' .. totalItems)
    for itemType, count in pairs(itemsByType) do
        print('^3' .. Config.CampingItems[itemType].label .. ':^7 ' .. count .. '個')
    end
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = Config.Notifications.info.title,
        description = '総アイテム数: ' .. totalItems .. '個 (詳細はコンソール確認)',
        type = Config.Notifications.info.type,
        duration = Config.Notifications.info.duration
    })
end)

-- リソース停止時の処理
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    
    if Config.Debug then
        print('^2[NG-CAMPING]^7 リソースが停止されました')
    end
end)

-- デバッグ用
if Config.Debug then
    print('^2[NG-CAMPING]^7 サーバースクリプトが開始されました')
end