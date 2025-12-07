local QBCore = exports['qb-core']:GetCoreObject()

-- サーマル使用中のプレイヤーを管理
local activeThermalPlayers = {}

-- アイテム使用可能登録（qb-core/qb-inventory用）
QBCore.Functions.CreateUseableItem(Config.ThermalItem, function(source, item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- アイテム所持確認
    local hasItem = Player.Functions.GetItemByName(Config.ThermalItem)
    
    if hasItem then
        -- クライアント側の処理をトリガー
        TriggerClientEvent('ng-thermalvision:client:useItem', src)
    end
end)

-- サーマル状態の更新を受信
RegisterNetEvent('ng-thermalvision:server:updateStatus', function(isActive)
    local src = source
    
    -- プレイヤーの状態を更新
    activeThermalPlayers[src] = isActive
    
    -- 全クライアントに状態を送信
    TriggerClientEvent('ng-thermalvision:client:updatePlayerStatus', -1, src, isActive)
    
    if Config.DebugMode then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            print('^2[ng-thermalvision]^7 プレイヤー ' .. Player.PlayerData.name .. ' (' .. src .. ') のサーマル状態: ' .. tostring(isActive))
        end
    end
end)

-- プレイヤー切断時の処理
AddEventHandler('playerDropped', function()
    local src = source
    
    if activeThermalPlayers[src] then
        activeThermalPlayers[src] = nil
        TriggerClientEvent('ng-thermalvision:client:updatePlayerStatus', -1, src, false)
        
        if Config.DebugMode then
            print('^2[ng-thermalvision]^7 プレイヤー ' .. src .. ' が切断しました（サーマル状態をクリア）')
        end
    end
end)

-- 新規プレイヤー接続時に現在のサーマル状態を送信
RegisterNetEvent('ng-thermalvision:server:requestAllStatus', function()
    local src = source
    
    for playerId, isActive in pairs(activeThermalPlayers) do
        if isActive then
            TriggerClientEvent('ng-thermalvision:client:updatePlayerStatus', src, playerId, isActive)
        end
    end
end)

-- リソース起動時
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- サーマル状態をリセット
    activeThermalPlayers = {}
    
    if Config.DebugMode then
        print('^2[ng-thermalvision]^7 デバッグモードが有効です')
        print('^2[ng-thermalvision]^7 使用アイテム: ' .. Config.ThermalItem)
        
        -- ox_inventoryの状態を確認
        if GetResourceState('ox_inventory') == 'started' then
            print('^2[ng-thermalvision]^7 ox_inventory: 検出されました（exportが必要です）')
        else
            print('^2[ng-thermalvision]^7 qb-inventory使用中（CreateUseableItemで動作）')
        end
    end
end)

-- デバッグ用コマンド（管理者のみ）
if Config.DebugMode then
    QBCore.Commands.Add('thermalstatus', '現在サーマルを使用中のプレイヤーを表示', {}, false, function(source, args)
        local src = source
        local count = 0
        
        print('^2[ng-thermalvision]^7 ===== サーマル使用中のプレイヤー =====')
        for playerId, isActive in pairs(activeThermalPlayers) do
            if isActive then
                local Player = QBCore.Functions.GetPlayer(playerId)
                if Player then
                    print('^2[ng-thermalvision]^7 プレイヤー: ' .. Player.PlayerData.name .. ' (ID: ' .. playerId .. ')')
                    count = count + 1
                end
            end
        end
        print('^2[ng-thermalvision]^7 合計: ' .. count .. '人')
        
        TriggerClientEvent('QBCore:Notify', src, count .. '人がサーマルを使用中です', 'success')
    end, 'admin')
end