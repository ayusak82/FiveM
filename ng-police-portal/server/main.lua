local QBCore = exports['qb-core']:GetCoreObject()

-- サーバー起動時のメッセージ
CreateThread(function()
    print('^2[ng-police-portal]^7 Police Teleport Portal System loaded successfully!')
    print('^3[ng-police-portal]^7 Version: 1.0.0 by NCCGr')
    print('^3[ng-police-portal]^7 Portals loaded: ' .. #Config.Portals)
end)

-- 権限チェック関数（サーバーサイド）
local function HasPolicePermission(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    for _, job in pairs(Config.PoliceJobs) do
        if Player.PlayerData.job.name == job then
            return true
        end
    end
    return false
end

-- テレポート権限チェック（セキュリティ強化）
RegisterNetEvent('ng-police-portal:server:checkPermission', function()
    local src = source
    local hasPermission = HasPolicePermission(src)
    
    TriggerClientEvent('ng-police-portal:client:permissionResult', src, hasPermission)
    
    if Config.Debug then
        local Player = QBCore.Functions.GetPlayer(src)
        local playerName = Player and Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname or 'Unknown'
        print('^3[ng-police-portal Debug]^7 Permission check for ' .. playerName .. ': ' .. tostring(hasPermission))
    end
end)

-- テレポートログ記録
RegisterNetEvent('ng-police-portal:server:logTeleport', function(portalName, destinationName)
    local src = source
    
    -- 権限チェック
    if not HasPolicePermission(src) then
        print('^1[ng-police-portal]^7 Unauthorized teleport attempt by ID: ' .. src)
        return
    end
    
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    local citizenId = Player.PlayerData.citizenid
    local timestamp = os.date('%Y-%m-%d %H:%M:%S')
    
    -- コンソールログ
    print('^3[ng-police-portal]^7 Teleport Log:')
    print('^3  Player:^7 ' .. playerName .. ' (' .. citizenId .. ')')
    print('^3  From:^7 ' .. portalName)
    print('^3  To:^7 ' .. destinationName)
    print('^3  Time:^7 ' .. timestamp)
    
    -- 将来的にデータベースログも追加可能
    -- MySQL.insert('INSERT INTO police_portal_logs (citizenid, player_name, portal_name, destination_name, timestamp) VALUES (?, ?, ?, ?, ?)', {
    --     citizenId, playerName, portalName, destinationName, timestamp
    -- })
end)

-- 管理者用コマンド：ポータル情報表示
QBCore.Commands.Add('portalinfo', 'ポータル情報を表示', {}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    -- 管理者権限チェック
    if Player.PlayerData.job.name ~= 'admin' and not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('QBCore:Notify', src, '管理者のみ使用可能です', 'error')
        return
    end
    
    TriggerClientEvent('QBCore:Notify', src, 'ポータル情報がコンソールに出力されました', 'success')
    
    print('^2[ng-police-portal]^7 Portal Information:')
    for i, portal in pairs(Config.Portals) do
        print('^3Portal ' .. i .. ':^7 ' .. portal.name)
        print('^3  Location:^7 ' .. portal.coords)
        print('^3  Destinations:^7 ' .. #portal.destinations)
        for j, dest in pairs(portal.destinations) do
            print('^3    ' .. j .. '.^7 ' .. dest.name .. ' - ' .. dest.coords)
        end
        print('')
    end
end, 'admin')

-- 管理者用コマンド：プレイヤーをポータルにテレポート
QBCore.Commands.Add('gotoportal', 'ポータルにテレポート', {{name = 'id', help = 'ポータルID (1-' .. #Config.Portals .. ')'}}, true, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local portalId = tonumber(args[1])
    
    -- 管理者権限チェック
    if Player.PlayerData.job.name ~= 'admin' and not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('QBCore:Notify', src, '管理者のみ使用可能です', 'error')
        return
    end
    
    -- ポータルIDチェック
    if not portalId or portalId < 1 or portalId > #Config.Portals then
        TriggerClientEvent('QBCore:Notify', src, '無効なポータルIDです (1-' .. #Config.Portals .. ')', 'error')
        return
    end
    
    local portal = Config.Portals[portalId]
    TriggerClientEvent('ng-police-portal:client:adminTeleport', src, portal.coords, portal.name)
    
    if Config.Debug then
        print('^3[ng-police-portal]^7 Admin teleport: ' .. Player.PlayerData.charinfo.firstname .. ' to ' .. portal.name)
    end
end, 'admin')

-- 統計情報の取得
RegisterNetEvent('ng-police-portal:server:getStats', function()
    local src = source
    
    if not HasPolicePermission(src) then
        return
    end
    
    local stats = {
        totalPortals = #Config.Portals,
        totalDestinations = 0
    }
    
    for _, portal in pairs(Config.Portals) do
        stats.totalDestinations = stats.totalDestinations + #portal.destinations
    end
    
    TriggerClientEvent('ng-police-portal:client:receiveStats', src, stats)
end)

-- エラーハンドリング
AddEventHandler('playerDropped', function(reason)
    local src = source
    if Config.Debug then
        print('^3[ng-police-portal]^7 Player ' .. src .. ' disconnected: ' .. reason)
    end
end)

-- リソース停止時のクリーンアップ
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print('^1[ng-police-portal]^7 Resource stopped - cleaning up...')
    end
end)