local QBCore = exports['qb-core']:GetCoreObject()
local campfires = {}
local campfireIdCounter = 0

-- 焚火を設置するイベントハンドラ
RegisterNetEvent('ng-campfire:server:placeCampfire')
AddEventHandler('ng-campfire:server:placeCampfire', function(coords, heading)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- アイテム要件の確認
    if Config.RequireItem and Config.RemoveItemOnUse then
        local item = Player.Functions.GetItemByName(Config.RequiredItem)
        if not item then
            TriggerClientEvent('ox_lib:notify', src, {
                title = '焚火',
                description = Config.RequiredItem .. 'が必要です',
                type = 'error'
            })
            return
        end
        
        -- アイテムを消費
        Player.Functions.RemoveItem(Config.RequiredItem, 1)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.RequiredItem], "remove")
    end
    
    -- 新しい焚火IDを生成
    campfireIdCounter = campfireIdCounter + 1
    local campfireId = campfireIdCounter
    
    -- 焚火情報を保存
    campfires[campfireId] = {
        coords = coords,
        owner = src,
        heading = heading
    }
    
    -- すべてのクライアントに焚火設置を通知
    TriggerClientEvent('ng-campfire:client:placeCampfire', -1, campfireId, coords, heading)
end)

-- 焚火を削除するイベントハンドラ
RegisterNetEvent('ng-campfire:server:removeCampfire')
AddEventHandler('ng-campfire:server:removeCampfire', function(campfireId)
    local src = source
    
    if campfires[campfireId] then
        -- 所有者チェック（オプション）
        if src ~= -1 and campfires[campfireId].owner ~= src then
            local Player = QBCore.Functions.GetPlayer(src)
            if Player.PlayerData.job.name ~= "police" then
                TriggerClientEvent('ox_lib:notify', src, {
                    title = '焚火',
                    description = '他人の焚火は片付けられません',
                    type = 'error'
                })
                return
            end
        end
        
        -- 焚火を削除
        TriggerClientEvent('ng-campfire:client:removeCampfire', -1, campfireId)
        campfires[campfireId] = nil
    end
end)

-- ストレス軽減イベントハンドラ
RegisterNetEvent('ng-campfire:server:reduceStress')
AddEventHandler('ng-campfire:server:reduceStress', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        -- qb-stressが有効かどうかを確認
        local stressEnabled = false
        local resourceState = GetResourceState('qb-stress')
        if resourceState == 'started' then
            stressEnabled = true
        end
        
        if stressEnabled then
            -- ストレス値を減少
            TriggerClientEvent('hud:client:UpdateStress', src, -Config.StressReductionAmount)
        end
    end
end)

-- プレイヤー切断時のクリーンアップ
AddEventHandler('playerDropped', function()
    local src = source
    
    -- プレイヤーが所有する焚火を探して削除
    for campfireId, campfire in pairs(campfires) do
        if campfire.owner == src then
            TriggerClientEvent('ng-campfire:client:removeCampfire', -1, campfireId)
            campfires[campfireId] = nil
        end
    end
end)

-- Export関数: 焚火を設置する
exports('PlaceCampfire', function(source, coords, heading)
    if source and coords and heading then
        local Player = QBCore.Functions.GetPlayer(source)
        
        if not Player then return false end
        
        -- 新しい焚火IDを生成
        campfireIdCounter = campfireIdCounter + 1
        local campfireId = campfireIdCounter
        
        -- 焚火情報を保存
        campfires[campfireId] = {
            coords = coords,
            owner = source,
            heading = heading
        }
        
        -- すべてのクライアントに焚火設置を通知
        TriggerClientEvent('ng-campfire:client:placeCampfire', -1, campfireId, coords, heading)
        
        return campfireId
    end
    return false
end)

-- Export関数: 焚火を削除する
exports('RemoveCampfire', function(campfireId)
    if campfires[campfireId] then
        TriggerClientEvent('ng-campfire:client:removeCampfire', -1, campfireId)
        campfires[campfireId] = nil
        return true
    end
    return false
end)

-- Export関数: プレイヤーが所有する焚火を取得
exports('GetPlayerCampfires', function(source)
    local playerCampfires = {}
    for id, campfire in pairs(campfires) do
        if campfire.owner == source then
            playerCampfires[id] = campfire
        end
    end
    return playerCampfires
end)

-- ox_inventoryに追加する場合のサンプルコード（コメントアウト）
--[[
-- ox_inventoryにアイテムを追加するサンプル
-- items.lua に追加:
['campfire_kit'] = {
    label = '焚火キット',
    weight = 1000,
    stack = true,
    close = true,
    description = '焚火を設置するためのキット',
    client = {
        event = 'ng-campfire:client:placeFromItem'
    }
},

-- server.lua での処理（アイテム消費する場合）:
-- ox.inventory:RegisterUsableItem('campfire_kit', function(source, item, data)
--     local Player = QBCore.Functions.GetPlayer(source)
--     if Player then
--         TriggerClientEvent('ng-campfire:client:placeFromItem', source)
--     end
-- end)
]]