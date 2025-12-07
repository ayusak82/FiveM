local QBCore = exports['qb-core']:GetCoreObject()
local punishedPlayers = {} -- 懲罰中のプレイヤーを管理

-- 管理者権限チェック関数
local function isAdmin(source)
    if not source then return false end
    return IsPlayerAceAllowed(source, 'command.admin')
end

-- 管理者権限チェックのコールバック登録
lib.callback.register('ng-hell-punishment:server:isAdmin', function(source)
    return isAdmin(source)
end)

-- 懲罰開始コマンド
RegisterCommand(Config.StartCommand, function(source, args)
    if not isAdmin(source) then
        TriggerClientEvent('ox_lib:notify', source, {
            title = '権限エラー',
            description = Config.Notifications.noPermission,
            type = 'error'
        })
        return
    end

    local targetId = tonumber(args[1])
    if not targetId then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'エラー',
            description = '使用方法: /' .. Config.StartCommand .. ' [プレイヤーID]',
            type = 'error'
        })
        return
    end

    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'エラー',
            description = Config.Notifications.targetNotFound,
            type = 'error'
        })
        return
    end

    if punishedPlayers[targetId] then
        TriggerClientEvent('ox_lib:notify', source, {
            title = '警告',
            description = Config.Notifications.alreadyInPunishment,
            type = 'warning'
        })
        return
    end

    -- 懲罰開始
    punishedPlayers[targetId] = true
    TriggerClientEvent('ng-hell-punishment:client:startPunishment', targetId)

    TriggerClientEvent('ox_lib:notify', source, {
        title = '懲罰システム',
        description = 'プレイヤー ' .. targetId .. ' の懲罰を開始しました',
        type = 'success'
    })

    TriggerClientEvent('ox_lib:notify', targetId, {
        title = '懲罰',
        description = Config.Notifications.punishmentStarted,
        type = 'error',
        duration = 5000
    })
end)

-- 懲罰終了コマンド
RegisterCommand(Config.StopCommand, function(source, args)
    if not isAdmin(source) then
        TriggerClientEvent('ox_lib:notify', source, {
            title = '権限エラー',
            description = Config.Notifications.noPermission,
            type = 'error'
        })
        return
    end

    local targetId = tonumber(args[1])
    if not targetId then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'エラー',
            description = '使用方法: /' .. Config.StopCommand .. ' [プレイヤーID]',
            type = 'error'
        })
        return
    end

    if not punishedPlayers[targetId] then
        TriggerClientEvent('ox_lib:notify', source, {
            title = '警告',
            description = Config.Notifications.notInPunishment,
            type = 'warning'
        })
        return
    end

    -- 懲罰終了
    punishedPlayers[targetId] = nil
    TriggerClientEvent('ng-hell-punishment:client:stopPunishment', targetId)

    TriggerClientEvent('ox_lib:notify', source, {
        title = '懲罰システム',
        description = 'プレイヤー ' .. targetId .. ' の懲罰を終了しました',
        type = 'success'
    })

    TriggerClientEvent('ox_lib:notify', targetId, {
        title = '懲罰終了',
        description = Config.Notifications.punishmentStopped,
        type = 'success'
    })
end)

-- プレイヤーが切断した時の処理
AddEventHandler('playerDropped', function()
    local source = source
    if punishedPlayers[source] then
        punishedPlayers[source] = nil
    end
end)

-- デバッグ用
if Config.Debug then
    print('[ng-hell-punishment] Server script loaded successfully')
end