local QBCore = exports['qb-core']:GetCoreObject()

-- デバッグ出力関数
local function DebugPrint(...)
    if not Config.Debug then return end
    local args = {...}
    local message = ''
    for i = 1, #args do
        message = message .. tostring(args[i]) .. ' '
    end
    print('^3[ng-announcement DEBUG]^7 ' .. message)
end

-- 許可された職業かチェック
local function isAllowedJob(jobName)
    for _, allowedJob in ipairs(Config.AllowedJobs) do
        if allowedJob == jobName then
            return true
        end
    end
    return false
end

-- クールダウン管理
local playerCooldowns = {}

-- クールダウンチェック
local function isOnCooldown(source)
    local identifier = QBCore.Functions.GetIdentifier(source, 'license')
    if not identifier then return false end
    
    local currentTime = os.time()
    if playerCooldowns[identifier] and (currentTime - playerCooldowns[identifier]) < Config.Cooldown then
        local remaining = Config.Cooldown - (currentTime - playerCooldowns[identifier])
        return true, remaining
    end
    return false, 0
end

-- クールダウン設定
local function setCooldown(source)
    local identifier = QBCore.Functions.GetIdentifier(source, 'license')
    if identifier then
        playerCooldowns[identifier] = os.time()
    end
end

-- お知らせ送信イベント
RegisterNetEvent('ng-announcement:server:sendAnnouncement', function(message)
    local source = source
    
    -- プレイヤーデータ取得
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        TriggerClientEvent('okokNotify:Alert', source, 'エラー', 'プレイヤーデータを取得できません', 5000, 'error', true)
        return
    end
    
    -- 職業チェック
    local jobName = Player.PlayerData.job.name
    if not isAllowedJob(jobName) then
        TriggerClientEvent('okokNotify:Alert', source, 'エラー', 'あなたの職業ではお知らせを出せません', 5000, 'error', true)
        DebugPrint('Player', source, 'attempted announcement with disallowed job:', jobName)
        return
    end
    
    -- クールダウンチェック
    local onCooldown, remaining = isOnCooldown(source)
    if onCooldown then
        TriggerClientEvent('okokNotify:Alert', source, 'クールダウン', 'あと ' .. remaining .. ' 秒お待ちください', 3000, 'warning', true)
        DebugPrint('Player', source, 'is on cooldown. Remaining:', remaining, 'seconds')
        return
    end
    
    -- メッセージ検証
    if not message or message == '' then
        TriggerClientEvent('okokNotify:Alert', source, 'エラー', 'メッセージを入力してください', 3000, 'error', true)
        return
    end
    
    if #message > Config.MaxLength then
        TriggerClientEvent('okokNotify:Alert', source, 'エラー', '文字数が制限を超えています', 3000, 'error', true)
        return
    end
    
    -- 職業情報取得
    local jobConfig = Config.Jobs[jobName] or Config.DefaultJob
    local charName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    
    DebugPrint('Announcement from', charName, '(' .. jobName .. '):', message)
    
    -- お知らせデータ作成
    local announcementData = {
        jobName = jobName,
        jobLabel = jobConfig.label,
        jobColor = jobConfig.color,
        jobIcon = jobConfig.icon,
        playerName = charName,
        message = message
    }
    
    -- 全プレイヤーに送信
    TriggerClientEvent('ng-announcement:client:receiveAnnouncement', -1, announcementData)
    
    -- クールダウン設定
    setCooldown(source)
    
    -- 送信者に通知
    TriggerClientEvent('okokNotify:Alert', source, '送信完了', 'お知らせを送信しました', 3000, 'success', true)
    
    DebugPrint('Announcement sent to all players')
end)

-- クールダウンリセット（管理者用）
RegisterNetEvent('ng-announcement:server:resetCooldown', function(targetId)
    local source = source
    
    -- 管理者チェック
    if not IsPlayerAceAllowed(source, 'command.admin') then
        TriggerClientEvent('okokNotify:Alert', source, 'エラー', '権限がありません', 3000, 'error', true)
        return
    end
    
    local targetSource = tonumber(targetId) or source
    local identifier = QBCore.Functions.GetIdentifier(targetSource, 'license')
    
    if identifier and playerCooldowns[identifier] then
        playerCooldowns[identifier] = nil
        TriggerClientEvent('okokNotify:Alert', source, '成功', 'クールダウンをリセットしました', 3000, 'success', true)
        DebugPrint('Cooldown reset for player', targetSource, 'by admin', source)
    end
end)

-- Export: サーバーからお知らせを送信
exports('sendAnnouncement', function(jobName, playerName, message)
    local jobConfig = Config.Jobs[jobName] or Config.DefaultJob
    
    local announcementData = {
        jobName = jobName,
        jobLabel = jobConfig.label,
        jobColor = jobConfig.color,
        jobIcon = jobConfig.icon,
        playerName = playerName,
        message = message
    }
    
    TriggerClientEvent('ng-announcement:client:receiveAnnouncement', -1, announcementData)
    DebugPrint('Announcement sent via export:', playerName, '(' .. jobName .. '):', message)
end)

-- Export: 許可された職業かチェック
exports('isAllowedJob', function(jobName)
    return isAllowedJob(jobName)
end)
