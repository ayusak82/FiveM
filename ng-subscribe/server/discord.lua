local QBCore = exports['qb-core']:GetCoreObject()
local discordRoleCache = {}
local lastRoleCheck = {}
local lastManualUpdate = {}

-- デバッグ用ログ関数
local function DebugLog(message)
    --print('^3[ng-subscribe]^7 ' .. message)
end

-- Discord Webhook送信関数
local function SendWebhook(webhookUrl, data)
    if webhookUrl == '' then return end
    PerformHttpRequest(webhookUrl, function(err, text, headers) end, 'POST', json.encode(data), { ['Content-Type'] = 'application/json' })
end

-- ログ送信関数
local function SendLog(type, data)
    if not Config.Discord.Webhooks[type] then return end

    local webhookData = {
        username = "NGSubscribe System",
        embeds = {
            {
                title = Config.WebhookMessages[type].title,
                description = string.format(Config.WebhookMessages[type].format, table.unpack(data)),
                color = Config.WebhookMessages[type].color,
                footer = {
                    text = os.date("記録日時: %Y年%m月%d日 %H:%M:%S")
                }
            }
        }
    }

    SendWebhook(Config.Discord.Webhooks[type], webhookData)
end

-- Discord IDの取得
local function GetDiscordId(source)
    local discordId = nil
    for _, identifier in pairs(GetPlayerIdentifiers(source)) do
        if string.find(identifier, "discord:") then
            discordId = string.gsub(identifier, "discord:", "")
            DebugLog('Discord ID found for player ' .. source .. ': ' .. discordId)
            break
        end
    end
    
    if not discordId then
        DebugLog('No Discord ID found for player ' .. source)
    end
    return discordId
end

-- DiscordロールのAPI取得
function FetchDiscordRoles(userId)
    if Config.Discord.BotToken == '' or Config.Discord.GuildId == '' then 
        DebugLog('Bot token or Guild ID is empty')
        return nil 
    end

    local roles = nil
    local p = promise.new()

    DebugLog('Fetching roles for user ' .. userId)

    PerformHttpRequest(
        ('https://discord.com/api/v10/guilds/%s/members/%s'):format(Config.Discord.GuildId, userId),
        function(err, data, headers)
            if err ~= 200 then
                DebugLog('Failed to fetch roles: Error ' .. tostring(err))
                p:resolve(nil)
                return
            end

            local decoded = json.decode(data)
            if decoded and decoded.roles then
                DebugLog('Successfully fetched roles: ' .. json.encode(decoded.roles))
                p:resolve(decoded.roles)
            else
                DebugLog('No roles found in response')
                p:resolve(nil)
            end
        end,
        'GET',
        '',
        {
            ['Authorization'] = 'Bot ' .. Config.Discord.BotToken,
            ['Content-Type'] = 'application/json'
        }
    )

    return Citizen.Await(p)
end

-- Discordロールの確認（キャッシュ付き）
local function GetDiscordRoles(source)
    local discordId = GetDiscordId(source)
    if not discordId then return nil end

    -- キャッシュチェック
    if discordRoleCache[discordId] and lastRoleCheck[discordId] then
        if (os.time() - lastRoleCheck[discordId]) < Config.Discord.LinkTimeout then
            DebugLog('Using cached roles for ' .. discordId)
            return discordRoleCache[discordId]
        end
    end

    -- Discord APIからロール取得
    local roles = FetchDiscordRoles(discordId)
    if roles then
        discordRoleCache[discordId] = roles
        lastRoleCheck[discordId] = os.time()
        DebugLog('Updated role cache for ' .. discordId)
    end

    return roles
end

-- 管理者権限チェック
local function IsPlayerAdmin(source)
    local roles = GetDiscordRoles(source)
    if not roles then return false end

    for _, role in ipairs(roles) do
        for _, adminRole in ipairs(Config.Discord.AdminRoles) do
            if role == adminRole then
                DebugLog('Admin role found for player ' .. source)
                return true
            end
        end
    end

    return false
end

-- プランの確認と付与
local function CheckAndAssignPlan(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then 
        DebugLog('Player not found for source ' .. source)
        return 
    end

    DebugLog('Checking subscription for ' .. Player.PlayerData.citizenid)

    -- 現在の月のサブスクリプション確認
    local currentSub = MySQL.single.await([[
        SELECT * FROM player_subscriptions 
        WHERE citizen_id = ? 
        AND activated = 1
        AND DATE_FORMAT(created_at, '%Y-%m') = DATE_FORMAT(NOW(), '%Y-%m')
    ]], {
        Player.PlayerData.citizenid
    })

    if currentSub then 
        DebugLog('Player already has active subscription for this month')
        return 
    end

    -- Discordロール取得
    local roles = GetDiscordRoles(source)
    if not roles then 
        DebugLog('No Discord roles found')
        return 
    end

    -- プラン決定（最高レベルのプランを選択）
    local selectedPlan = nil
    local highestLevel = 0

    for _, roleId in pairs(roles) do
        local planName = Config.Discord.Roles[tostring(roleId)]
        if planName and Config.Plans[planName] then
            local planLevel = Config.Plans[planName].level
            if planLevel > highestLevel then
                selectedPlan = planName
                highestLevel = planLevel
                DebugLog('Found higher level plan: ' .. planName)
            end
        end
    end

    if selectedPlan then
        DebugLog('Selected plan for player: ' .. selectedPlan)

        -- 前月のサブスクリプションを無効化
        MySQL.update.await('UPDATE player_subscriptions SET activated = 0 WHERE citizen_id = ?', {
            Player.PlayerData.citizenid
        })

        -- 新しいサブスクリプションを追加
        local success = MySQL.insert.await([[
            INSERT INTO player_subscriptions 
                (citizen_id, plan_name, activated, rewards_claimed, vehicle_claimed, expires_at) 
            VALUES 
                (?, ?, 1, 0, 0, DATE_ADD(NOW(), INTERVAL 1 MONTH))
        ]], {
            Player.PlayerData.citizenid,
            selectedPlan
        })

        if success then
            DebugLog('Successfully assigned subscription')
            
            -- プレイヤーに通知
            TriggerClientEvent('QBCore:Notify', source, '新しいサブスクリプションが付与されました: ' .. Config.Plans[selectedPlan].label, 'success')
            
            -- Webhook送信
            SendLog('subscriptions', {
                Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                Player.PlayerData.citizenid,
                selectedPlan,
                'Discord Role自動付与'
            })
        else
            DebugLog('Failed to assign subscription')
        end
    else
        DebugLog('No eligible plan found for player')
    end
end

-- プレイヤーがロードされた時のチェック
RegisterNetEvent('QBCore:Server:PlayerLoaded', function()
    local source = source
    DebugLog('Player loaded event triggered for source: ' .. source)
    Wait(5000) -- プレイヤーデータの読み込みを待機
    CheckAndAssignPlan(source)
end)

-- 定期チェックの追加（毎月1日0時）
CreateThread(function()
    while true do
        Wait(60 * 60 * 1000) -- 1時間ごとにチェック
        local currentDay = tonumber(os.date('%d'))
        local currentHour = tonumber(os.date('%H'))
        
        if currentDay == 1 and currentHour == 0 then
            DebugLog('Running monthly subscription check')
            for _, playerId in ipairs(GetPlayers()) do
                CheckAndAssignPlan(tonumber(playerId))
            end
        end
    end
end)

-- キャッシュクリア用の定期実行
CreateThread(function()
    while true do
        Wait(30 * 60 * 1000) -- 30分ごとに変更
        discordRoleCache = {}
        lastRoleCheck = {}
        DebugLog('Cleared Discord role cache (30min interval)')
    end
end)

-- エクスポート
exports('IsPlayerAdmin', IsPlayerAdmin)
exports('SendLog', SendLog)
exports('GetDiscordRoles', GetDiscordRoles)

-- 特定のプレイヤーのサブスクリプションを強制更新
local function ForceUpdateSubscription(source, targetId)
    if not IsPlayerAdmin(source) then
        TriggerClientEvent('QBCore:Notify', source, '管理者権限がありません', 'error')
        return false
    end

    local target = nil
    if targetId then
        -- 特定のプレイヤーの更新
        target = QBCore.Functions.GetPlayer(targetId)
        if not target then
            TriggerClientEvent('QBCore:Notify', source, '指定されたプレイヤーが見つかりません', 'error')
            return false
        end
        DebugLog('Force updating subscription for player: ' .. target.PlayerData.citizenid)
        CheckAndAssignPlan(targetId)
    else
        -- 全プレイヤーの更新
        DebugLog('Force updating subscriptions for all players')
        local players = QBCore.Functions.GetQBPlayers()
        for _, player in pairs(players) do
            CheckAndAssignPlan(player.PlayerData.source)
        end
    end

    TriggerClientEvent('QBCore:Notify', source, 'サブスクリプションを強制更新しました', 'success')
    return true
end

-- コマンド登録
QBCore.Commands.Add('forcesubs', '全プレイヤーのサブスクリプションを強制更新', {}, false, function(source)
    ForceUpdateSubscription(source, nil)
end, 'admin')

QBCore.Commands.Add('forceplayersubs', '特定プレイヤーのサブスクリプションを強制更新', {{name = 'id', help = 'プレイヤーID'}}, false, function(source, args)
    if not args[1] then
        TriggerClientEvent('QBCore:Notify', source, 'プレイヤーIDを指定してください', 'error')
        return
    end
    local targetId = tonumber(args[1])
    ForceUpdateSubscription(source, targetId)
end, 'admin')

-- 特定プレイヤーのディスコードロールキャッシュをクリア
local function ClearPlayerRoleCache(source)
    local discordId = GetDiscordId(source)
    if discordId then
        discordRoleCache[discordId] = nil
        lastRoleCheck[discordId] = nil
        DebugLog('Cleared Discord role cache for player ' .. source .. ' (' .. discordId .. ')')
        return true
    end
    return false
end

-- 特定プレイヤーのサブスクリプションを手動で更新
local function ManuallyUpdateSubscription(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then 
        DebugLog('Player not found for source ' .. source)
        return false
    end

    -- クールダウンチェック
    local citizenId = Player.PlayerData.citizenid
    if lastManualUpdate[citizenId] then
        local timeElapsed = os.time() - lastManualUpdate[citizenId]
        local cooldownInSeconds = Config.Discord.ManualUpdateCooldown * 60
        
        if timeElapsed < cooldownInSeconds then
            local remainingTime = math.ceil((cooldownInSeconds - timeElapsed) / 60)
            TriggerClientEvent('QBCore:Notify', source, '更新は ' .. remainingTime .. ' 分後に再試行できます', 'error')
            return false
        end
    end

    -- ディスコードロールキャッシュをクリア
    ClearPlayerRoleCache(source)
    
    -- サブスクリプションを確認・付与
    CheckAndAssignPlan(source)
    
    -- 最終更新時間を記録
    lastManualUpdate[citizenId] = os.time()
    
    return true
end

-- エクスポート関数を追加
exports('ClearPlayerRoleCache', ClearPlayerRoleCache)
exports('ManuallyUpdateSubscription', ManuallyUpdateSubscription)

-- プレイヤーが手動で更新するコマンドを追加
QBCore.Commands.Add('updatesubs', 'サブスクリプションを手動で更新', {}, false, function(source)
    local success = ManuallyUpdateSubscription(source)
    if success then
        TriggerClientEvent('QBCore:Notify', source, 'サブスクリプション情報を更新しました', 'success')
    else
        TriggerClientEvent('QBCore:Notify', source, '更新に失敗しました', 'error')
    end
end)