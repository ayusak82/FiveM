local QBCore = exports['qb-core']:GetCoreObject()

-- ============================================
-- グローバル変数
-- ============================================

-- スポーン済み車両の管理
SpawnedVehicles = {}

-- ============================================
-- ユーティリティ関数
-- ============================================

-- 管理者権限チェック関数
local function isAdmin(source)
    if not source then return false end
    return IsPlayerAceAllowed(source, 'command.admin')
end

-- 管理者権限チェックのコールバック登録
lib.callback.register('ng-vehiclecard:server:isAdmin', function(source)
    return isAdmin(source)
end)

-- プレイヤーの所持金チェック
local function hasMoney(source, amount)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    return Player.Functions.GetMoney('cash') >= amount or Player.Functions.GetMoney('bank') >= amount
end

-- プレイヤーからお金を削除
local function removeMoney(source, amount)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    if Player.Functions.GetMoney('cash') >= amount then
        Player.Functions.RemoveMoney('cash', amount)
        return true
    elseif Player.Functions.GetMoney('bank') >= amount then
        Player.Functions.RemoveMoney('bank', amount)
        return true
    end
    return false
end

-- ============================================
-- 車両カード使用処理
-- ============================================

-- 車両スポーン処理
lib.callback.register('ng-vehiclecard:server:spawnVehicle', function(source, cardSlot, cardData)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false, 'error_general' end
    
    local metadata = cardData.metadata
    if not metadata or not metadata.vehicle then
        return false, 'error_general'
    end
    
    -- 既にスポーン済みチェック
    local cardId = metadata.cardId or string.format('%s_%s', Player.PlayerData.citizenid, cardSlot)
    if SpawnedVehicles[cardId] then
        return false, 'already_spawned'
    end
    
    -- 使用回数チェック
    local currentUses = metadata.uses or Config.DefaultUses
    if currentUses <= 0 then
        return false, 'card_broken'
    end
    
    -- 使用回数を減らす
    local newUses = currentUses - 1
    metadata.uses = newUses
    
    -- カードIDを設定（初回のみ）
    if not metadata.cardId then
        metadata.cardId = cardId
    end
    
    -- 使用回数が0になった場合
    if newUses <= 0 then
        -- 壊れた車両カードに変更
        exports.ox_inventory:RemoveItem(source, 'vehicle_card', 1, metadata, cardSlot)
        exports.ox_inventory:AddItem(source, 'vehicle_card_broken', 1, {
            vehicle = metadata.vehicle,
            label = metadata.label,
            description = '壊れた車両カード'
        })
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'システム',
            description = Locale.card_broken,
            type = 'error'
        })
    else
        -- メタデータを更新
        exports.ox_inventory:SetMetadata(source, cardSlot, metadata)
    end
    
    -- 車両スポーン情報を保存
    SpawnedVehicles[cardId] = {
        source = source,
        vehicle = metadata.vehicle,
        slot = cardSlot,
        spawnTime = os.time()
    }
    
    return true, 'vehicle_spawned', cardId
end)

-- 車両格納処理
lib.callback.register('ng-vehiclecard:server:storeVehicle', function(source, vehicleNetId, cardId)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false, 'error_general' end
    
    -- スポーン情報チェック
    if not SpawnedVehicles[cardId] then
        return false, 'not_your_vehicle'
    end
    
    local vehicleData = SpawnedVehicles[cardId]
    if vehicleData.source ~= source then
        return false, 'not_your_vehicle'
    end
    
    -- スポーン情報を削除
    SpawnedVehicles[cardId] = nil
    
    return true, 'vehicle_stored'
end)

-- 車両削除（ネットワーク経由）
RegisterNetEvent('ng-vehiclecard:server:deleteVehicle', function(vehicleNetId)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if DoesEntityExist(vehicle) then
        DeleteEntity(vehicle)
    end
end)

-- ============================================
-- 自動デスポーンシステム
-- ============================================

if Config.AutoDespawn.enabled then
    CreateThread(function()
        while true do
            Wait(Config.AutoDespawn.checkInterval * 1000)
            
            local currentTime = os.time()
            local playersToCheck = {}
            
            -- オンラインプレイヤーの座標を取得
            for _, playerId in ipairs(GetPlayers()) do
                local ped = GetPlayerPed(playerId)
                if ped and DoesEntityExist(ped) then
                    playersToCheck[tonumber(playerId)] = GetEntityCoords(ped)
                end
            end
            
            -- スポーン済み車両をチェック
            for cardId, data in pairs(SpawnedVehicles) do
                local timeDiff = currentTime - data.spawnTime
                
                -- 時間条件チェック（5分以上）
                if timeDiff >= Config.AutoDespawn.time then
                    local playerCoords = playersToCheck[data.source]
                    
                    if playerCoords then
                        -- 距離条件をクライアントに確認
                        TriggerClientEvent('ng-vehiclecard:client:checkVehicleDistance', data.source, cardId, Config.AutoDespawn.distance)
                    else
                        -- プレイヤーがオフライン
                        SpawnedVehicles[cardId] = nil
                        TriggerClientEvent('ng-vehiclecard:client:despawnVehicle', -1, cardId)
                    end
                end
            end
        end
    end)
end

-- 自動デスポーン実行
RegisterNetEvent('ng-vehiclecard:server:autoDespawn', function(cardId)
    if SpawnedVehicles[cardId] then
        local vehicleData = SpawnedVehicles[cardId]
        SpawnedVehicles[cardId] = nil
        
        TriggerClientEvent('ox_lib:notify', vehicleData.source, {
            title = 'システム',
            description = Locale.vehicle_despawned,
            type = 'info'
        })
        
        TriggerClientEvent('ng-vehiclecard:client:despawnVehicle', -1, cardId)
    end
end)

-- ============================================
-- ショップ購入処理
-- ============================================

lib.callback.register('ng-vehiclecard:server:buyVehicleCard', function(source, vehicleData)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false, 'error_general' end
    
    -- 在庫チェック（ox_inventoryの場合）
    local canCarry = exports.ox_inventory:CanCarryItem(source, 'vehicle_card', 1)
    if not canCarry then
        return false, 'shop_full_inventory'
    end
    
    -- 金額チェック
    if not hasMoney(source, vehicleData.price) then
        return false, 'shop_no_money'
    end
    
    -- 支払い処理
    if not removeMoney(source, vehicleData.price) then
        return false, 'shop_no_money'
    end
    
    -- メタデータ作成
    local metadata = {
        vehicle = vehicleData.model,
        uses = vehicleData.uses,
        max_uses = vehicleData.uses,
        label = string.format('車両カード (%s)', vehicleData.label),
        description = string.format('使用回数: %d/%d', vehicleData.uses, vehicleData.uses)
    }
    
    -- アイテム付与
    exports.ox_inventory:AddItem(source, 'vehicle_card', 1, metadata)
    
    return true, 'shop_success'
end)

-- ============================================
-- プレイヤー切断時の処理
-- ============================================

AddEventHandler('playerDropped', function()
    local source = source
    
    -- このプレイヤーのスポーン車両を削除
    for cardId, data in pairs(SpawnedVehicles) do
        if data.source == source then
            SpawnedVehicles[cardId] = nil
            TriggerClientEvent('ng-vehiclecard:client:despawnVehicle', -1, cardId)
        end
    end
end)

-- ============================================
-- デバッグコマンド（開発用）
-- ============================================

if GetConvar('ng_vehiclecard_debug', 'false') == 'true' then
    RegisterCommand('vcdebug', function(source, args)
        if not isAdmin(source) then return end
        
        print('=== Spawned Vehicles Debug ===')
        for cardId, data in pairs(SpawnedVehicles) do
            print(string.format('CardID: %s | Source: %s | Vehicle: %s | Time: %s', 
                cardId, data.source, data.vehicle, os.date('%Y-%m-%d %H:%M:%S', data.spawnTime)))
        end
        print('=============================')
    end, true)
end

print('^2[ng-vehiclecard]^7 Server script loaded successfully')
