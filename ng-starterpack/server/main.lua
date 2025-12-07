local QBCore = exports['qb-core']:GetCoreObject()

-- プレイヤーがスターターパックを使用したかどうかを追跡するためのテーブル
local playersUsedPack = {}

-- テーブル作成
CreateThread(function()
    local success, error = pcall(function()
        MySQL.query.await([[
            CREATE TABLE IF NOT EXISTS `ng_starterpack` (
                `citizenid` VARCHAR(50) NOT NULL,
                `used` TINYINT(1) NOT NULL DEFAULT 0,
                PRIMARY KEY (`citizenid`)
            )
        ]])
    end)
    
    if not success then
        print('^1Error creating ng_starterpack table: ' .. error .. '^0')
    end
end)

-- スターターパックアイテム使用
QBCore.Functions.CreateUseableItem(Config.ItemName, function(source)
    local src = source
    TriggerClientEvent('ng-starterpack:client:useStarterPack', src)
end)

-- プレイヤーのパック使用状態をチェック
RegisterNetEvent('ng-starterpack:server:checkUsedStatus')
AddEventHandler('ng-starterpack:server:checkUsedStatus', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        local citizenid = Player.PlayerData.citizenid
        
        MySQL.query('SELECT used FROM ng_starterpack WHERE citizenid = ?', {citizenid}, function(result)
            if result and result[1] then
                playersUsedPack[citizenid] = result[1].used == 1
                TriggerClientEvent('ng-starterpack:client:setUsedStatus', src, playersUsedPack[citizenid])
            else
                playersUsedPack[citizenid] = false
                TriggerClientEvent('ng-starterpack:client:setUsedStatus', src, false)
            end
        end)
    end
end)

-- パックを付与
RegisterNetEvent('ng-starterpack:server:givePack')
AddEventHandler('ng-starterpack:server:givePack', function(packType)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- すでに使用したか確認
    if playersUsedPack[citizenid] then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'エラー',
            description = Config.AlreadyUsed,
            type = 'error'
        })
        return
    end
    
    -- アイテムを削除
    local hasItem = exports.ox_inventory:GetItem(src, Config.ItemName, nil, true) > 0
    if not hasItem then return end
    
    exports.ox_inventory:RemoveItem(src, Config.ItemName, 1)
    
    -- パックの種類に応じてアイテムを付与
    local packItems = packType == 'citizen' and Config.CitizenPack or Config.CriminalPack
    local canCarry = true
    
    -- 全てのアイテムが持てるか確認
    for _, item in ipairs(packItems) do
        if not exports.ox_inventory:CanCarryItem(src, item.name, item.amount) then
            canCarry = false
            break
        end
    end
    
    if not canCarry then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'エラー',
            description = Config.InventoryFull,
            type = 'error'
        })
        -- アイテムを返却
        exports.ox_inventory:AddItem(src, Config.ItemName, 1)
        return
    end
    
    -- アイテムを付与
    for _, item in ipairs(packItems) do
        if item.name == 'cash' then
            Player.Functions.AddMoney('cash', item.amount)
        else
            exports.ox_inventory:AddItem(src, item.name, item.amount)
        end
    end
    
    -- データベースを更新
    MySQL.insert('INSERT INTO ng_starterpack (citizenid, used) VALUES (?, ?) ON DUPLICATE KEY UPDATE used = ?', 
        {citizenid, 1, 1})
    
    -- 使用済みフラグを設定
    playersUsedPack[citizenid] = true
    TriggerClientEvent('ng-starterpack:client:setUsedStatus', src, true)
    
    -- 成功通知
    TriggerClientEvent('ox_lib:notify', src, {
        title = '成功',
        description = Config.SuccessMessage,
        type = 'success'
    })
end)