local QBCore = exports['qb-core']:GetCoreObject()

-- 権限チェック関数
local function hasPermission(source)
    if not Config.Command.jobRestricted then
        return true
    end
    
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player or not Player.PlayerData.job then
        return false
    end
    
    for _, job in pairs(Config.Command.allowedJobs) do
        if Player.PlayerData.job.name == job then
            return true
        end
    end
    
    return false
end

-- 車両所有者を取得する関数
local function getVehicleOwner(plate)
    local result = MySQL.query.await('SELECT citizenid FROM player_vehicles WHERE plate = ?', {plate})
    
    if result and result[1] then
        return result[1].citizenid
    end
    
    return nil
end

-- 車両をガレージに格納する関数
local function storeVehicleInGarage(plate, citizenid, vehicleData)
    -- まず車両がすでにガレージにあるかチェック
    local existingVehicle = MySQL.query.await('SELECT * FROM player_vehicles WHERE plate = ?', {plate})
    
    if existingVehicle and existingVehicle[1] then
        -- 既存の車両をガレージに格納状態に更新（jg-advancedgarages対応）
        MySQL.update('UPDATE player_vehicles SET state = ?, garage = ?, in_garage = ? WHERE plate = ?', {
            1, -- state = 1 (ガレージ内)
            'impoundlot', -- デフォルトガレージ
            1, -- in_garage = 1 (jg-advancedgarages用)
            plate
        })
        
        if Config.Debug then
            print(string.format('[ng-impound] 既存車両をガレージに格納: %s (in_garage=1)', plate))
        end
        
        -- jg-advancedgaragesのキャッシュ更新（Export関数がある場合）
        local success, result = pcall(function()
            exports['jg-advancedgarages']:UpdateVehicleState(plate, 1)
        end)
        
        if not success and Config.Debug then
            print('[ng-impound] jg-advancedgarages Export関数が見つかりません（通常の動作）')
        end
        
        return true
    else
        -- 車両が見つからない場合は新規作成（NPCの車両等）
        if Config.Debug then
            print(string.format('[ng-impound] NPCまたは未登録車両: %s', plate))
        end
        
        -- NPCの車両はインパウンドできないとする場合
        return false
    end
end

-- 車両インパウンド処理
RegisterNetEvent('ng-impound:server:impoundVehicle', function(vehicleData)
    local src = source
    
    if Config.Debug then
        print(string.format('[ng-impound] インパウンド要求受信: Player %d, Plate %s', src, vehicleData.plate))
    end
    
    -- 権限チェック
    if not hasPermission(src) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = Config.Notifications.noPermission.title,
            description = Config.Notifications.noPermission.description,
            type = Config.Notifications.noPermission.type,
            duration = Config.Notifications.noPermission.duration
        })
        return
    end
    
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then
        return
    end
    
    -- 車両所有者を取得
    local ownerCitizenId = getVehicleOwner(vehicleData.plate)
    
    if Config.Vehicle.requirePlayerVehicle and not ownerCitizenId then
        TriggerClientEvent('ox_lib:notify', src, {
            title = Config.Notifications.notOwner.title,
            description = Config.Notifications.notOwner.description,
            type = Config.Notifications.notOwner.type,
            duration = Config.Notifications.notOwner.duration
        })
        return
    end
    
    -- 車両をガレージに格納
    local success = false
    
    if ownerCitizenId then
        -- プレイヤーの車両の場合
        success = storeVehicleInGarage(vehicleData.plate, ownerCitizenId, vehicleData)
        
        if Config.Debug then
            print(string.format('[ng-impound] プレイヤー車両処理結果: %s', success and "成功" or "失敗"))
        end
    else
        -- NPCの車両や未登録車両の場合（警察なので強制削除可能）
        success = true
        
        if Config.Debug then
            print(string.format('[ng-impound] NPC車両を強制削除: %s', vehicleData.plate))
        end
    end
    
    if success then
        -- クライアントに車両削除を指示
        TriggerClientEvent('ng-impound:client:deleteVehicle', src, vehicleData.netId)
        
        -- ログ記録
        local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
        local logMessage = string.format('[車両インパウンド] %s (ID: %d) が車両 %s (プレート: %s) をインパウンドしました', 
            playerName, src, vehicleData.modelName, vehicleData.plate)
        
        print(logMessage)
        
        -- 必要に応じてDiscordログやデータベースに記録
        -- TriggerEvent('qb-log:server:CreateLog', 'vehicleimpound', 'Vehicle Impounded', 'blue', logMessage)
        
        if Config.Debug then
            print(string.format('[ng-impound] インパウンド成功: %s', vehicleData.plate))
        end
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = Config.Notifications.notOwner.title,
            description = Config.Notifications.notOwner.description,
            type = Config.Notifications.notOwner.type,
            duration = Config.Notifications.notOwner.duration
        })
        
        if Config.Debug then
            print(string.format('[ng-impound] インパウンド失敗: %s', vehicleData.plate))
        end
    end
end)

-- サーバー起動時の処理
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print('^2[ng-impound]^7 車両インパウンドシステムが開始されました')
        
        if Config.Debug then
            print('^3[ng-impound]^7 デバッグモードが有効です')
        end
    end
end)

-- サーバー停止時の処理
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print('^1[ng-impound]^7 車両インパウンドシステムが停止されました')
    end
end)

-- プレイヤー接続時の処理
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    
    if Config.Debug then
        print(string.format('[ng-impound] プレイヤー接続: %d', src))
    end
end)