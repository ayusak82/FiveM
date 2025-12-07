local QBCore = exports['qb-core']:GetCoreObject()

-- プレート番号クリーンアップ関数
local function CleanPlate(plate)
    return string.gsub(plate or "", '%s+', '')
end

-- データベーステーブル作成
CreateThread(function()
    local success = MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `ng_nitro` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `plate` varchar(20) NOT NULL,
            `has_kit` tinyint(1) DEFAULT 0,
            `tanks` int(11) DEFAULT 0,
            `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
            `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `plate` (`plate`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    if Config.Debug then
        print('[ng-nitro] データベーステーブル作成完了:', success and 'true' or 'false')
    end
end)

-- ニトロデータ保存
local function SaveNitroData(plate, hasKit, tanks)
    if Config.Debug then
        print(('[ng-nitro] データ保存試行 - プレート: "%s", hasKit: %s, tanks: %s'):format(
            plate, hasKit and 'true' or 'false', tanks
        ))
    end
    
    local result = MySQL.insert.await('INSERT INTO ng_nitro (plate, has_kit, tanks) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE has_kit = ?, tanks = ?', {
        plate, hasKit and 1 or 0, tanks, hasKit and 1 or 0, tanks
    })
    
    if Config.Debug then
        print(('[ng-nitro] データ保存結果 - プレート: "%s", 結果ID: %s'):format(plate, result or 'nil'))
    end
    
    return result
end

-- ニトロキット取り付け用アイテム使用処理
QBCore.Functions.CreateUseableItem(Config.Items.installKit, function(source, item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Job制限チェック
    local playerJob = Player.PlayerData.job.name
    local hasPermission = false
    
    for _, allowedJob in pairs(Config.Permissions.allowedJobs) do
        if playerJob == allowedJob then
            hasPermission = true
            break
        end
    end
    
    if not hasPermission then
        TriggerClientEvent('QBCore:Notify', src, 'このアイテムはメカニック職のみ使用できます', 'error')
        return
    end
    
    local ped = GetPlayerPed(src)
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if not vehicle or vehicle == 0 then
        TriggerClientEvent('QBCore:Notify', src, '車両に乗っている必要があります', 'error')
        return
    end
    
    local plate = GetVehicleNumberPlateText(vehicle)
    local cleanPlate = CleanPlate(plate)
    
    if Config.Debug then
        print(('[ng-nitro] プレート番号詳細 - 生: "%s", クリーン後: "%s"'):format(plate or 'nil', cleanPlate))
    end
    
    -- 既存のニトロデータを確認
    local existingData = MySQL.single.await('SELECT has_kit FROM ng_nitro WHERE plate = ?', { cleanPlate })
    
    if existingData and (existingData.has_kit == 1 or existingData.has_kit == true) then
        TriggerClientEvent('QBCore:Notify', src, 'この車両には既にニトロキットが取り付けられています', 'error')
        return
    end
    
    -- アイテムを削除
    Player.Functions.RemoveItem(Config.Items.installKit, 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.Items.installKit], "remove")
    
    -- ニトロキット取り付け
    local saveResult = SaveNitroData(cleanPlate, true, 0)
    
    -- 少し待ってからデータベースから確認用に再取得
    Wait(100)
    local confirmData = MySQL.single.await('SELECT has_kit, tanks FROM ng_nitro WHERE plate = ?', { cleanPlate })
    
    if Config.Debug then
        print(('[ng-nitro] デバッグ - プレート: "%s", 保存結果: %s, 取り付け後データ: has_kit=%s, tanks=%s'):format(
            cleanPlate, 
            saveResult or 'nil',
            confirmData and confirmData.has_kit or 'nil', 
            confirmData and confirmData.tanks or 'nil'
        ))
    end
    
    -- データが正しく保存されていない場合はエラー
    if not confirmData or (confirmData.has_kit ~= 1 and confirmData.has_kit ~= true) then
        TriggerClientEvent('QBCore:Notify', src, 'データベースエラー: ニトロキットの取り付けに失敗しました', 'error')
        -- アイテムを返却
        Player.Functions.AddItem(Config.Items.installKit, 1)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.Items.installKit], "add")
        return
    end
    
    -- 全プレイヤーにニトロデータを送信（車両に乗っている全員に反映）
    local nitroData = {
        hasKit = true,
        tanks = 0
    }
    
    -- まずアイテム使用者に直接送信
    TriggerClientEvent('ng-nitro:client:setNitroData', src, cleanPlate, nitroData)
    if Config.Debug then
        print(('[ng-nitro] アイテム使用者 %s に直接ニトロデータを送信 - プレート: "%s"'):format(src, cleanPlate))
    end
    
    -- 該当車両に乗っている他のプレイヤーにもデータを送信
    local players = QBCore.Functions.GetPlayers()
    for _, playerId in pairs(players) do
        if playerId ~= src then -- アイテム使用者以外
            local playerPed = GetPlayerPed(playerId)
            local playerVehicle = GetVehiclePedIsIn(playerPed, false)
            if playerVehicle and playerVehicle ~= 0 then
                local playerPlate = CleanPlate(GetVehicleNumberPlateText(playerVehicle))
                if playerPlate == cleanPlate then
                    TriggerClientEvent('ng-nitro:client:setNitroData', playerId, cleanPlate, nitroData)
                    if Config.Debug then
                        print(('[ng-nitro] プレイヤー %s にニトロデータを送信 - プレート: "%s"'):format(playerId, cleanPlate))
                    end
                end
            end
        end
    end
    
    TriggerClientEvent('QBCore:Notify', src, 'ニトロキットが正常に取り付けられました', 'success')
    
    if Config.Debug then
        print(('[ng-nitro] キット取り付け - プレイヤー: %s, プレート: "%s"'):format(Player.PlayerData.name, cleanPlate))
    end
end)

-- ニトロボトル取り付け用アイテム使用処理
QBCore.Functions.CreateUseableItem(Config.Items.nitrousBottle, function(source, item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local ped = GetPlayerPed(src)
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if not vehicle or vehicle == 0 then
        TriggerClientEvent('QBCore:Notify', src, '車両に乗っている必要があります', 'error')
        return
    end
    
    local plate = GetVehicleNumberPlateText(vehicle)
    local cleanPlate = CleanPlate(plate)
    
    -- 既存のニトロデータを確認
    local result = MySQL.single.await('SELECT has_kit, tanks FROM ng_nitro WHERE plate = ?', { cleanPlate })
    
    if not result or (result.has_kit ~= 1 and result.has_kit ~= true) then
        TriggerClientEvent('QBCore:Notify', src, 'この車両にはニトロキットが取り付けられていません', 'error')
        return
    end
    
    local currentTanks = result.tanks or 0
    local newTanks = math.min(currentTanks + Config.Nitro.tanksPerBottle, Config.Nitro.maxTanks)
    
    if newTanks == currentTanks then
        TriggerClientEvent('QBCore:Notify', src, 'タンクは既に最大容量です', 'error')
        return
    end
    
    -- アイテムを削除
    Player.Functions.RemoveItem(Config.Items.nitrousBottle, 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.Items.nitrousBottle], "remove")
    
    -- タンク数更新
    MySQL.update('UPDATE ng_nitro SET tanks = ? WHERE plate = ?', { newTanks, cleanPlate })
    
    -- 全プレイヤーにニトロデータを送信（車両に乗っている全員に反映）
    local nitroData = {
        hasKit = true,
        tanks = newTanks
    }
    
    -- 該当車両に乗っている全プレイヤーにデータを送信
    local players = QBCore.Functions.GetPlayers()
    for _, playerId in pairs(players) do
        local playerPed = GetPlayerPed(playerId)
        local playerVehicle = GetVehiclePedIsIn(playerPed, false)
        if playerVehicle and playerVehicle ~= 0 then
            local playerPlate = CleanPlate(GetVehicleNumberPlateText(playerVehicle))
            if playerPlate == cleanPlate then
                TriggerClientEvent('ng-nitro:client:setNitroData', playerId, cleanPlate, nitroData)
            end
        end
    end
    
    local addedTanks = newTanks - currentTanks
    TriggerClientEvent('QBCore:Notify', src, ('ニトロタンクが%d個追加されました (合計: %d/%d)'):format(addedTanks, newTanks, Config.Nitro.maxTanks), 'success')
    
    if Config.Debug then
        print(('[ng-nitro] タンク追加 - プレイヤー: %s, プレート: %s, 追加数: %d, 合計: %d'):format(Player.PlayerData.name, cleanPlate, addedTanks, newTanks))
    end
end)

-- 管理者用ニトロ削除コマンド（念のため残しておく）
QBCore.Commands.Add('removenitro', '車両からニトロを削除します', {}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('QBCore:Notify', src, 'このコマンドを使用する権限がありません', 'error')
        return
    end
    
    local ped = GetPlayerPed(src)
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if not vehicle or vehicle == 0 then
        TriggerClientEvent('QBCore:Notify', src, '車両に乗っている必要があります', 'error')
        return
    end
    
    local plate = GetVehicleNumberPlateText(vehicle)
    local cleanPlate = CleanPlate(plate)
    
    -- ニトロデータ削除
    MySQL.query('DELETE FROM ng_nitro WHERE plate = ?', { cleanPlate })
    
    -- 全プレイヤーからニトロデータを削除（車両に乗っている全員に反映）
    local players = QBCore.Functions.GetPlayers()
    for _, playerId in pairs(players) do
        local playerPed = GetPlayerPed(playerId)
        local playerVehicle = GetVehiclePedIsIn(playerPed, false)
        if playerVehicle and playerVehicle ~= 0 then
            local playerPlate = CleanPlate(GetVehicleNumberPlateText(playerVehicle))
            if playerPlate == cleanPlate then
                TriggerClientEvent('ng-nitro:client:removeNitroData', playerId, cleanPlate)
            end
        end
    end
    
    TriggerClientEvent('QBCore:Notify', src, 'ニトロが正常に削除されました', 'success')
    
    if Config.Debug then
        print(('[ng-nitro] ニトロ削除 - プレイヤー: %s, プレート: %s'):format(Player.PlayerData.name, cleanPlate))
    end
end, 'admin')

-- ニトロ状態確認コマンド
QBCore.Commands.Add('checknitro', '車両のニトロ状態を確認します', {}, false, function(source, args)
    local src = source
    local ped = GetPlayerPed(src)
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if not vehicle or vehicle == 0 then
        TriggerClientEvent('QBCore:Notify', src, '車両に乗っている必要があります', 'error')
        return
    end
    
    local plate = GetVehicleNumberPlateText(vehicle)
    local cleanPlate = CleanPlate(plate)
    local result = MySQL.single.await('SELECT has_kit, tanks FROM ng_nitro WHERE plate = ?', { cleanPlate })
    
    if not result or (result.has_kit ~= 1 and result.has_kit ~= true) then
        TriggerClientEvent('QBCore:Notify', src, 'この車両にはニトロキットが取り付けられていません', 'inform')
        return
    end
    
    local tanks = result.tanks or 0
    TriggerClientEvent('QBCore:Notify', src, ('ニトロ状態: キット装着済み | タンク: %d/%d'):format(tanks, Config.Nitro.maxTanks), 'primary')
end)

-- ニトロタンク使用
RegisterNetEvent('ng-nitro:server:useTank', function(plate)
    local src = source
    local cleanPlate = CleanPlate(plate)
    
    local result = MySQL.single.await('SELECT has_kit, tanks FROM ng_nitro WHERE plate = ?', { cleanPlate })
    
    if not result or (result.has_kit ~= 1 and result.has_kit ~= true) or result.tanks <= 0 then
        return
    end
    
    local newTanks = math.max(0, result.tanks - Config.Nitro.tankUsagePerBoost)
    MySQL.update('UPDATE ng_nitro SET tanks = ? WHERE plate = ?', { newTanks, cleanPlate })
    
    -- 更新されたデータをクライアントに送信
    local nitroData = {
        hasKit = true,
        tanks = newTanks
    }
    
    TriggerClientEvent('ng-nitro:client:setNitroData', src, cleanPlate, nitroData)
    
    if Config.Debug then
        local Player = QBCore.Functions.GetPlayer(src)
        print(('[ng-nitro] タンク使用 - プレイヤー: %s, プレート: %s, 残りタンク: %d'):format(Player.PlayerData.name, cleanPlate, newTanks))
    end
end)

-- 車両乗車時にニトロデータを送信
RegisterNetEvent('ng-nitro:server:requestNitroData', function(plate)
    local src = source
    local cleanPlate = CleanPlate(plate)
    
    if Config.Debug then
        print(('[ng-nitro] ニトロデータ要求 - プレイヤー: %s, 受信プレート: "%s", クリーン後: "%s"'):format(src, plate or 'nil', cleanPlate))
    end
    
    local result = MySQL.single.await('SELECT has_kit, tanks FROM ng_nitro WHERE plate = ?', { cleanPlate })
    
    if Config.Debug then
        print(('[ng-nitro] データベース結果 - プレート: "%s", has_kit: %s, tanks: %s'):format(
            cleanPlate,
            result and result.has_kit or 'nil',
            result and result.tanks or 'nil'
        ))
    end
    
    if result and (result.has_kit == 1 or result.has_kit == true) then
        local nitroData = {
            hasKit = true,
            tanks = result.tanks or 0
        }
        
        TriggerClientEvent('ng-nitro:client:setNitroData', src, cleanPlate, nitroData)
        
        if Config.Debug then
            print(('[ng-nitro] ニトロデータ送信完了 - プレイヤー: %s, プレート: "%s", hasKit: true, tanks: %d'):format(
                src, cleanPlate, nitroData.tanks
            ))
        end
    else
        if Config.Debug then
            print(('[ng-nitro] ニトロキット未装着 - プレート: "%s", has_kit値: %s (型: %s)'):format(
                cleanPlate,
                tostring(result and result.has_kit or 'nil'),
                type(result and result.has_kit or 'nil')
            ))
        end
    end
end)