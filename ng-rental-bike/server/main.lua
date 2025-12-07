local QBCore = exports['qb-core']:GetCoreObject()

-- プレイヤーのレンタル状態を管理
local playerRentals = {}

-- プレイヤーがレンタル中かチェック
RegisterNetEvent('ng-rental-bike:server:checkRental', function()
    local src = source
    local hasRental = playerRentals[src] ~= nil
    TriggerClientEvent('ng-rental-bike:client:rentalStatus', src, hasRental)
end)

-- プレイヤーがバイクをレンタルしたことを記録
RegisterNetEvent('ng-rental-bike:server:setRental', function(bikeNetId, plate)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    playerRentals[src] = {
        bikeNetId = bikeNetId,
        plate = plate,
        timestamp = os.time()
    }
    
    -- 車両の鍵を付与
    if Config.GiveKeys then
        -- qb-vehiclekeysまたはqb-coreの鍵システムを使用
        TriggerClientEvent('vehiclekeys:client:SetOwner', src, plate)
        
        if Config.Debug then
            print(('[ng-rental-bike] Player %s received keys for bike (Plate: %s)'):format(src, plate))
        end
    end
    
    if Config.Debug then
        print(('[ng-rental-bike] Player %s rented bike (NetID: %s, Plate: %s)'):format(src, bikeNetId, plate))
    end
end)

-- プレイヤーのレンタルを解除
RegisterNetEvent('ng-rental-bike:server:removeRental', function()
    local src = source
    if playerRentals[src] then
        if Config.Debug then
            print(('[ng-rental-bike] Player %s rental removed'):format(src))
        end
        playerRentals[src] = nil
    end
end)

-- プレイヤー切断時のクリーンアップ
AddEventHandler('playerDropped', function(reason)
    local src = source
    if playerRentals[src] then
        local rental = playerRentals[src]
        -- クライアントにバイク削除を通知（他のプレイヤーに）
        TriggerClientEvent('ng-rental-bike:client:deleteDisconnectedBike', -1, rental.bikeNetId)
        playerRentals[src] = nil
        if Config.Debug then
            print(('[ng-rental-bike] Player %s disconnected, bike deleted'):format(src))
        end
    end
end)

-- リソース停止時のクリーンアップ
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- すべてのレンタル情報をクリア
    playerRentals = {}
    if Config.Debug then
        print('[ng-rental-bike] Resource stopped, all rentals cleared')
    end
end)
