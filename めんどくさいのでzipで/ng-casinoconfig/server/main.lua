local QBCore = exports['qb-core']:GetCoreObject()

-- 設定更新イベント
RegisterNetEvent('ng-casinoconfig:server:updateConfig', function(configContent, constContent, preset)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    -- 権限チェック
    if not Player then return end
    
    local jobName = Player.PlayerData.job.name
    local jobGrade = Player.PlayerData.job.grade.level
    
    local hasPermission = false
    if Config.AuthorizedJobs[jobName] and jobGrade >= Config.AuthorizedJobs[jobName] then
        hasPermission = true
    end
    
    if not hasPermission then
        TriggerClientEvent('ox_lib:notify', src, Config.Notify.NoPermission)
        return
    end
    
    -- rcore_casinoのエクスポート関数を呼び出す
    local success = exports[Config.TargetResourceName]:UpdateConfig(configContent, constContent)
    
    if success then
        -- 全プレイヤーに通知
        local players = QBCore.Functions.GetPlayers()
        for _, playerid in ipairs(players) do
            TriggerClientEvent('ox_lib:notify', playerid, Config.Notify.Success)
        end
        
        -- ログ記録
        local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
        local message = playerName .. ' (' .. Player.PlayerData.license .. ') がカジノ設定を ' .. 
                       (Config.Presets[preset] or preset) .. ' に更新しました'
        print(message)
    else
        TriggerClientEvent('ox_lib:notify', src, Config.Notify.Error)
    end
end)

-- サーバー起動時のログ
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    print('^2' .. GetCurrentResourceName() .. '^7: カジノ設定マネージャーが起動しました')
    
    -- 必要なリソースの確認
    local missingResource = false
    
    if GetResourceState(Config.TargetResourceName) ~= 'started' then
        print('^1エラー: ' .. Config.TargetResourceName .. ' が見つかりませんでした^7')
        missingResource = true
    end
    
    if missingResource then
        print('^1警告: いくつかの必要なリソースが見つかりませんでした。スクリプトが正しく動作しない可能性があります。^7')
    end
end)

-- 設定読み込み用のカスタムコールバックイベント
QBCore.Functions.CreateCallback('ng-casinoconfig:server:getPresetContent', function(source, cb, preset)
    local resourceName = GetCurrentResourceName()
    local configPath = ('configs/%s.lua'):format(preset)
    local constPath = ('consts/%s.lua'):format(preset)
    
    -- 設定ファイルを読み込む
    local configContent = LoadResourceFile(resourceName, configPath)
    local constContent = LoadResourceFile(resourceName, constPath)
    
    if not configContent then
        cb(false)
        return
    end
    
    cb(configContent, constContent)
end)