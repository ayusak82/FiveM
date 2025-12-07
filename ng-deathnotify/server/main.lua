local QBCore = exports['qb-core']:GetCoreObject()

-- クールダウン管理
local cooldowns = {}
local notificationCooldowns = {}  -- 通知用のクールダウン
local COOLDOWN_TIME = 15000 -- 15秒
local NOTIFICATION_COOLDOWN = 5000 -- 5秒

-- クールダウンチェック
local function checkCooldown(source, type)
    local identifier = GetPlayerIdentifierByType(source, 'license')
    if not cooldowns[identifier] then
        cooldowns[identifier] = {}
    end
    if not notificationCooldowns[identifier] then
        notificationCooldowns[identifier] = {}
    end
    
    if cooldowns[identifier][type] and (GetGameTimer() - cooldowns[identifier][type]) < COOLDOWN_TIME then
        local remaining = math.ceil((COOLDOWN_TIME - (GetGameTimer() - cooldowns[identifier][type])) / 1000)
        
        -- 通知のクールダウンチェック
        if not notificationCooldowns[identifier][type] or 
           (GetGameTimer() - notificationCooldowns[identifier][type]) >= NOTIFICATION_COOLDOWN then
            notificationCooldowns[identifier][type] = GetGameTimer()
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'クールダウン',
                description = remaining .. '秒後に再度使用できます',
                type = 'error'
            })
        end
        
        return false
    end
    
    cooldowns[identifier][type] = GetGameTimer()
    return true
end

-- ps-dispatch通知送信（クライアント側で実行）
local function sendDispatchAlert(source, dispatchType)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local notifConfig = Config.Notifications[dispatchType]
    
    -- 各dispatchTypeに応じてjobsを指定
    local jobs
    if dispatchType == 'doctorCall' then
        jobs = {'doctor'}
    elseif dispatchType == 'jobTeleport' then
        jobs = {'ambulance'}  -- ambulanceのみに変更
    else  -- ambulanceCall
        jobs = {'ambulance', 'ems'}
    end
    
    -- クライアントに送信してps-dispatchを実行
    TriggerClientEvent('ng-deathnotify:client:sendDispatch', source, dispatchType, notifConfig, jobs)
end

-- 特定jobのテレポート処理
RegisterNetEvent('ng-deathnotify:server:jobTeleport', function(playerJob)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    
    if not Player then return end
    
    -- job確認
    if Player.PlayerData.job.name ~= playerJob then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'エラー',
            description = '権限がありません',
            type = 'error'
        })
        return
    end
    
    -- テレポート先確認
    local teleportData = Config.TeleportJobs[playerJob]
    if not teleportData then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'エラー',
            description = 'テレポート先が設定されていません',
            type = 'error'
        })
        return
    end
    
    -- クールダウンチェック
    if not checkCooldown(source, 'teleport') then return end
    
    -- テレポート実行（通知はクライアント側で完了後に送信）
    TriggerClientEvent('ng-deathnotify:client:doTeleport', source, teleportData.coords, true)
    
    -- ログ
    print(('ng-deathnotify: %s (%s) が %s にテレポートしました'):format(
        GetPlayerName(source),
        playerJob,
        teleportData.label
    ))
end)

-- Ambulance呼び出し
RegisterNetEvent('ng-deathnotify:server:callAmbulance', function()
    local source = source
    
    -- クールダウンチェック
    if not checkCooldown(source, 'ambulance') then return end
    
    -- dispatch通知
    sendDispatchAlert(source, 'ambulanceCall')
    
    -- 通知確認
    TriggerClientEvent('ng-deathnotify:client:notifySent', source, 'ambulance')
    
    -- ログ
    print(('ng-deathnotify: %s が救急医療を要請しました'):format(GetPlayerName(source)))
end)

-- Doctor呼び出し
RegisterNetEvent('ng-deathnotify:server:callDoctor', function()
    local source = source
    
    -- クールダウンチェック
    if not checkCooldown(source, 'doctor') then return end
    
    -- dispatch通知
    sendDispatchAlert(source, 'doctorCall')
    
    -- 通知確認
    TriggerClientEvent('ng-deathnotify:client:notifySent', source, 'doctor')
    
    -- ログ
    print(('ng-deathnotify: %s が個人医を要請しました'):format(GetPlayerName(source)))
end)

-- プレイヤー切断時のクールダウンクリア
AddEventHandler('playerDropped', function()
    local source = source
    local identifier = GetPlayerIdentifierByType(source, 'license')
    if identifier then
        if cooldowns[identifier] then
            cooldowns[identifier] = nil
        end
        if notificationCooldowns[identifier] then
            notificationCooldowns[identifier] = nil
        end
    end
end)

-- テレポート完了後の通知送信
RegisterNetEvent('ng-deathnotify:server:sendTeleportNotification', function()
    local source = source
    
    -- dispatch通知
    sendDispatchAlert(source, 'jobTeleport')
    
    -- 通知確認
    TriggerClientEvent('ng-deathnotify:client:notifySent', source, 'teleport')
end)