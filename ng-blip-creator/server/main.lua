local QBCore = exports['qb-core']:GetCoreObject()

-- データベーステーブル作成
local function CreateTable()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `ng_blips` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `name` varchar(255) NOT NULL,
            `sprite` int(11) NOT NULL DEFAULT 1,
            `color` int(11) NOT NULL DEFAULT 1,
            `scale` float NOT NULL DEFAULT 1.0,
            `x` float NOT NULL,
            `y` float NOT NULL,
            `z` float NOT NULL,
            `created_by` varchar(50) NOT NULL,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    print("^2[NG-Blip-Creator]^7 データベーステーブルが初期化されました")
end

-- リソース開始時にテーブル作成
CreateTable()

-- 権限チェック関数
local function HasPermission(source)
    -- コンソールは常に許可
    if source == 0 then return true end
    
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    -- ACE権限チェック（group.admin または qbcore.admin）
    if IsPlayerAceAllowed(source, "group.admin") or 
       IsPlayerAceAllowed(source, "qbcore.admin") or
       IsPlayerAceAllowed(source, "admin") then
        return true
    end
    
    -- 管理者ジョブチェック
    if Player.PlayerData.job and Player.PlayerData.job.name == 'admin' then
        return true
    end
    
    -- QBCore権限システムチェック
    if QBCore.Functions.HasPermission(source, Config.Permission.admin) or 
       QBCore.Functions.HasPermission(source, Config.Permission.moderator) or
       QBCore.Functions.HasPermission(source, "admin") or
       QBCore.Functions.HasPermission(source, "god") then
        return true
    end
    
    return false
end

-- すべてのブリップを取得
local function GetAllBlips()
    local result = MySQL.query.await('SELECT * FROM `ng_blips` ORDER BY `created_at` DESC')
    return result or {}
end

-- ブリップを作成
local function CreateBlip(data, source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- 最大ブリップ数チェック
    local currentCount = MySQL.scalar.await('SELECT COUNT(*) FROM `ng_blips`')
    if currentCount >= Config.Blips.maxBlips then
        TriggerClientEvent('ng-blip-creator:client:notify', source, Config.Notifications.error.maxBlipsReached, 'error')
        return false
    end
    
    -- データ検証
    if not data.name or data.name == '' then
        TriggerClientEvent('ng-blip-creator:client:notify', source, Config.Notifications.error.invalidData, 'error')
        return false
    end
    
    -- ブリップを挿入
    local insertId = MySQL.insert.await([[
        INSERT INTO `ng_blips` (`name`, `sprite`, `color`, `scale`, `x`, `y`, `z`, `created_by`) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        data.name,
        data.sprite or Config.Blips.defaultSprite,
        data.color or Config.Blips.defaultColor,
        data.scale or Config.Blips.defaultScale,
        data.x,
        data.y,
        data.z,
        citizenid
    })
    
    if insertId then
        data.id = insertId
        data.created_by = citizenid
        
        -- すべてのクライアントにブリップを追加
        TriggerClientEvent('ng-blip-creator:client:addBlip', -1, data)
        TriggerClientEvent('ng-blip-creator:client:notify', source, Config.Notifications.success.blipCreated, 'success')
        
        print(string.format("^2[NG-Blip-Creator]^7 新しいブリップが作成されました: %s (ID: %d)", data.name, insertId))
        return true
    end
    
    return false
end

-- ブリップを更新
local function UpdateBlip(data, source)
    if not data.id then
        TriggerClientEvent('ng-blip-creator:client:notify', source, Config.Notifications.error.invalidData, 'error')
        return false
    end
    
    -- データ検証
    if not data.name or data.name == '' then
        TriggerClientEvent('ng-blip-creator:client:notify', source, Config.Notifications.error.invalidData, 'error')
        return false
    end
    
    local affectedRows = MySQL.update.await([[
        UPDATE `ng_blips` 
        SET `name` = ?, `sprite` = ?, `color` = ?, `scale` = ?, `x` = ?, `y` = ?, `z` = ?
        WHERE `id` = ?
    ]], {
        data.name,
        data.sprite,
        data.color,
        data.scale,
        data.x,
        data.y,
        data.z,
        data.id
    })
    
    if affectedRows > 0 then
        -- すべてのクライアントのブリップリストを更新
        local blips = GetAllBlips()
        TriggerClientEvent('ng-blip-creator:client:updateBlips', -1, blips)
        TriggerClientEvent('ng-blip-creator:client:notify', source, Config.Notifications.success.blipUpdated, 'success')
        
        print(string.format("^2[NG-Blip-Creator]^7 ブリップが更新されました: %s (ID: %d)", data.name, data.id))
        return true
    else
        TriggerClientEvent('ng-blip-creator:client:notify', source, Config.Notifications.error.blipNotFound, 'error')
        return false
    end
end

-- ブリップを削除
local function DeleteBlip(blipId, source)
    if not blipId then
        TriggerClientEvent('ng-blip-creator:client:notify', source, Config.Notifications.error.invalidData, 'error')
        return false
    end
    
    -- ブリップ情報を取得（ログ用）
    local blipInfo = MySQL.single.await('SELECT `name` FROM `ng_blips` WHERE `id` = ?', {blipId})
    
    local affectedRows = MySQL.update.await('DELETE FROM `ng_blips` WHERE `id` = ?', {blipId})
    
    if affectedRows > 0 then
        -- すべてのクライアントからブリップを削除
        TriggerClientEvent('ng-blip-creator:client:removeBlip', -1, blipId)
        TriggerClientEvent('ng-blip-creator:client:notify', source, Config.Notifications.success.blipDeleted, 'success')
        
        local blipName = blipInfo and blipInfo.name or "不明"
        print(string.format("^2[NG-Blip-Creator]^7 ブリップが削除されました: %s (ID: %d)", blipName, blipId))
        return true
    else
        TriggerClientEvent('ng-blip-creator:client:notify', source, Config.Notifications.error.blipNotFound, 'error')
        return false
    end
end

-- サーバーイベント

-- プレイヤー接続時にブリップをロード
RegisterNetEvent('ng-blip-creator:server:loadBlips', function()
    local source = source
    local blips = GetAllBlips()
    TriggerClientEvent('ng-blip-creator:client:updateBlips', source, blips)
end)

-- ブリップリストを取得
RegisterNetEvent('ng-blip-creator:server:getBlips', function()
    local source = source
    
    if not HasPermission(source) then
        TriggerClientEvent('ng-blip-creator:client:notify', source, Config.Notifications.error.noPermission, 'error')
        return
    end
    
    local blips = GetAllBlips()
    TriggerClientEvent('ng-blip-creator:client:openBlipList', source, blips)
end)

-- ブリップを作成
RegisterNetEvent('ng-blip-creator:server:createBlip', function(data)
    local source = source
    
    if not HasPermission(source) then
        TriggerClientEvent('ng-blip-creator:client:notify', source, Config.Notifications.error.noPermission, 'error')
        return
    end
    
    CreateBlip(data, source)
end)

-- ブリップを更新
RegisterNetEvent('ng-blip-creator:server:updateBlip', function(data)
    local source = source
    
    if not HasPermission(source) then
        TriggerClientEvent('ng-blip-creator:client:notify', source, Config.Notifications.error.noPermission, 'error')
        return
    end
    
    UpdateBlip(data, source)
end)

-- ブリップを削除
RegisterNetEvent('ng-blip-creator:server:deleteBlip', function(blipId)
    local source = source
    
    if not HasPermission(source) then
        TriggerClientEvent('ng-blip-creator:client:notify', source, Config.Notifications.error.noPermission, 'error')
        return
    end
    
    DeleteBlip(blipId, source)
end)

-- 管理者コマンド：すべてのブリップを削除
RegisterCommand('ng-blips-clear', function(source, args, rawCommand)
    if source == 0 or HasPermission(source) then
        MySQL.update.await('DELETE FROM `ng_blips`')
        TriggerClientEvent('ng-blip-creator:client:updateBlips', -1, {})
        
        if source == 0 then
            print("^2[NG-Blip-Creator]^7 すべてのブリップが削除されました（コンソール実行）")
        else
            TriggerClientEvent('ng-blip-creator:client:notify', source, 'すべてのブリップが削除されました', 'success')
            local Player = QBCore.Functions.GetPlayer(source)
            local playerName = Player and Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname or "不明"
            print(string.format("^2[NG-Blip-Creator]^7 すべてのブリップが削除されました（実行者: %s）", playerName))
        end
    else
        TriggerClientEvent('ng-blip-creator:client:notify', source, Config.Notifications.error.noPermission, 'error')
    end
end, false)

-- 管理者コマンド：ブリップ統計を表示
RegisterCommand('ng-blips-stats', function(source, args, rawCommand)
    if source == 0 or HasPermission(source) then
        local totalBlips = MySQL.scalar.await('SELECT COUNT(*) FROM `ng_blips`')
        local recentBlips = MySQL.scalar.await('SELECT COUNT(*) FROM `ng_blips` WHERE `created_at` >= DATE_SUB(NOW(), INTERVAL 24 HOUR)')
        
        local statsMessage = string.format(
            "^2[NG-Blip-Creator 統計]^7\n総ブリップ数: %d/%d\n過去24時間の作成数: %d",
            totalBlips, Config.Blips.maxBlips, recentBlips
        )
        
        if source == 0 then
            print(statsMessage)
        else
            TriggerClientEvent('ng-blip-creator:client:notify', source, 
                string.format("総ブリップ数: %d/%d | 過去24時間: %d個", totalBlips, Config.Blips.maxBlips, recentBlips), 
                'info')
        end
    else
        TriggerClientEvent('ng-blip-creator:client:notify', source, Config.Notifications.error.noPermission, 'error')
    end
end, false)

-- エクスポート関数

-- 外部スクリプト用：ブリップを追加
exports('CreateBlip', function(data)
    if not data or not data.name or not data.x or not data.y or not data.z then
        return false
    end
    
    local insertId = MySQL.insert.await([[
        INSERT INTO `ng_blips` (`name`, `sprite`, `color`, `scale`, `x`, `y`, `z`, `created_by`) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        data.name,
        data.sprite or Config.Blips.defaultSprite,
        data.color or Config.Blips.defaultColor,
        data.scale or Config.Blips.defaultScale,
        data.x,
        data.y,
        data.z,
        data.created_by or 'system'
    })
    
    if insertId then
        data.id = insertId
        TriggerClientEvent('ng-blip-creator:client:addBlip', -1, data)
        return insertId
    end
    
    return false
end)

-- 外部スクリプト用：ブリップを削除
exports('DeleteBlip', function(blipId)
    if not blipId then return false end
    
    local affectedRows = MySQL.update.await('DELETE FROM `ng_blips` WHERE `id` = ?', {blipId})
    
    if affectedRows > 0 then
        TriggerClientEvent('ng-blip-creator:client:removeBlip', -1, blipId)
        return true
    end
    
    return false
end)

-- 外部スクリプト用：すべてのブリップを取得
exports('GetAllBlips', function()
    return GetAllBlips()
end)

print("^2[NG-Blip-Creator]^7 サーバーが正常に開始されました")