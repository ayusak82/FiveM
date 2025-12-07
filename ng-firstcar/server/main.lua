-- server/main.lua

local QBCore = exports['qb-core']:GetCoreObject()

-- プレート生成関数
local function GeneratePlate()
    local plate = ""
    for i = 1, Config.PlateLength do
        if i % 2 == 0 then
            plate = plate .. string.char(math.random(48, 57)) -- 数字
        else
            plate = plate .. string.char(math.random(65, 90)) -- 大文字
        end
    end
    return plate
end

-- プレイヤーが初回特典を受け取ったかチェック
local function HasPlayerClaimedFirstCar(citizenId)
    local result = MySQL.scalar.await('SELECT claimed FROM ' .. Config.DatabaseTable .. ' WHERE citizenid = ?', {citizenId})
    return result and result == 1
end

-- プレイヤーのレコードを作成または取得
local function EnsurePlayerRecord(citizenId)
    local exists = MySQL.scalar.await('SELECT 1 FROM ' .. Config.DatabaseTable .. ' WHERE citizenid = ?', {citizenId})
    if not exists then
        MySQL.insert.await('INSERT INTO ' .. Config.DatabaseTable .. ' (citizenid, claimed) VALUES (?, 0)', {citizenId})
        print("^ Created new record for player: " .. citizenId)
        return false
    end
    return HasPlayerClaimedFirstCar(citizenId)
end

-- 車両の所有権付与
local function GiveVehicle(source, citizenId, vehicleName, category)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end

    -- レコードが確実に存在することを確認
    if EnsurePlayerRecord(citizenId) then
        -- 既に受け取っている場合
        TriggerClientEvent('QBCore:Notify', source, Config.Messages.error.already_claimed, 'error')
        return false
    end

    local plate = GeneratePlate()
    
    -- デフォルトの車両プロップスを設定
    local props = {
        model = GetHashKey(vehicleName),
        plate = plate,
        fuel = 100,
        bodyHealth = 1000.0,
        engineHealth = 1000.0,
        tankHealth = 1000.0,
        dirtLevel = 0.0
    }

    -- トランザクション的な処理
    local success = MySQL.insert.await([[
        INSERT INTO player_vehicles 
            (license, citizenid, vehicle, plate, hash, mods, garage, fuel, engine, body, state) 
        VALUES 
            (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        Player.PlayerData.license,
        citizenId,
        vehicleName,
        plate,
        props.model,
        json.encode(props),
        Config.DefaultGarage,
        props.fuel,
        props.engineHealth,
        props.bodyHealth,
        1
    })

    if success then
        -- 初回特典を受け取ったことを記録
        local updateSuccess = MySQL.update.await('UPDATE ' .. Config.DatabaseTable .. ' SET claimed = 1, vehicle_model = ? WHERE citizenid = ?', {
            vehicleName, citizenId
        })
        
        print("^ Vehicle given to player: " .. citizenId .. ", update success: " .. tostring(updateSuccess))

        -- アイテムを削除
        Player.Functions.RemoveItem('vehicleticket', 1)
        
        TriggerClientEvent('QBCore:Notify', source, Config.Messages.success.vehicle_claimed, 'success')
        return true
    end

    return false
end

-- サーバーイベント: 初回起動時にDBテーブル作成＆チェック
CreateThread(function()
    -- テーブルが存在しない場合は作成
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS ]] .. Config.DatabaseTable .. [[ (
            id INT AUTO_INCREMENT PRIMARY KEY,
            citizenid VARCHAR(50) NOT NULL,
            claimed TINYINT DEFAULT 0,
            vehicle_model VARCHAR(50) DEFAULT NULL,
            claimed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY unique_citizen (citizenid)
        )
    ]], {}, function(result)
        print("^ Created or verified table: " .. Config.DatabaseTable)
    end)
end)

-- プレイヤーが接続した時の処理
RegisterNetEvent('QBCore:Server:PlayerLoaded', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        local citizenId = Player.PlayerData.citizenid
        -- プレイヤーのレコードを確認・作成
        EnsurePlayerRecord(citizenId)
        
        -- クライアントに状態を通知
        local claimed = HasPlayerClaimedFirstCar(citizenId)
        TriggerClientEvent('ng-firstcar:client:setClaimedStatus', src, claimed)
    end
end)

-- アイテム使用イベント (初回車両選択アイテム)
QBCore.Functions.CreateUseableItem('vehicleticket', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local citizenId = Player.PlayerData.citizenid
    
    -- レコードが確実に存在することを確認
    local claimed = EnsurePlayerRecord(citizenId)
    
    -- 既に車両を受け取っているかチェック
    if claimed then
        TriggerClientEvent('QBCore:Notify', source, Config.Messages.error.already_claimed, 'error')
        return
    end
    
    -- UIを開く
    TriggerClientEvent('ng-firstcar:client:openUI', source)
end)

-- 選択した車両を受け取るイベント
RegisterNetEvent('ng-firstcar:server:claimVehicle', function(selectedIndex)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenId = Player.PlayerData.citizenid
    
    -- レコードが確実に存在することを確認
    local claimed = EnsurePlayerRecord(citizenId)
    
    -- 既に車両を受け取っているかチェック
    if claimed then
        TriggerClientEvent('QBCore:Notify', src, Config.Messages.error.already_claimed, 'error')
        return
    end
    
    -- 選択した車両の情報を取得
    local vehicle = Config.VehicleOptions[selectedIndex]
    if not vehicle then
        TriggerClientEvent('QBCore:Notify', src, Config.Messages.error.no_selection, 'error')
        return
    end
    
    -- 車両を付与
    local success = GiveVehicle(src, citizenId, vehicle.model, vehicle.category)
    
    if not success then
        TriggerClientEvent('QBCore:Notify', src, Config.Messages.error.failed_to_give, 'error')
    end
end)

-- プレイヤーが初回特典を受け取ったかのチェックイベント
RegisterNetEvent('ng-firstcar:server:checkClaimed', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        local claimed = HasPlayerClaimedFirstCar(Player.PlayerData.citizenid)
        TriggerClientEvent('ng-firstcar:client:setClaimedStatus', src, claimed)
    end
end)

-- サーバー側のエクスポート関数
exports('HasPlayerClaimedFirstCar', HasPlayerClaimedFirstCar)