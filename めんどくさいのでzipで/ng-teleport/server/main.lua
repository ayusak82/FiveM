local QBCore = exports['qb-core']:GetCoreObject()

-- クールダウンの保存用テーブル
local cooldowns = {}

-- プレイヤー情報の取得
local function GetPlayerInfo(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return nil end
    
    return {
        name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        job = Player.PlayerData.job.label,
        citizenid = Player.PlayerData.citizenid
    }
end

-- 座標のフォーマット
local function FormatCoords(coords)
    if not coords then return "N/A" end
    return string.format('%.2f, %.2f, %.2f', coords.x, coords.y, coords.z)
end

-- Webhookへの送信
local function SendToDiscord(embed)
    if not Config.DiscordWebhook.url or Config.DiscordWebhook.url == '' then return end
    
    PerformHttpRequest(Config.DiscordWebhook.url, function(err, text, headers) end, 'POST', json.encode({
        username = Config.DiscordWebhook.botName,
        embeds = { embed }
    }), { ['Content-Type'] = 'application/json' })
end

-- 成功ログの送信
local function LogSuccess(source, data)
    local playerInfo = GetPlayerInfo(source)
    if not playerInfo then return end
    
    local embed = {
        color = Config.DiscordWebhook.colors.success,
        title = "テレポート使用ログ",
        description = string.format("プレイヤー: %s\nCitizenID: %s\n職業: %s", 
            playerInfo.name, playerInfo.citizenid, playerInfo.job),
        fields = {
            {
                name = "テレポート元",
                value = FormatCoords(data.from),
                inline = true
            },
            {
                name = "テレポート先",
                value = FormatCoords(data.to),
                inline = true
            }
        },
        footer = {
            text = os.date("%Y-%m-%d %H:%M:%S")
        }
    }
    
    SendToDiscord(embed)
end

-- エラーログの送信
local function LogError(source, data)
    local playerInfo = GetPlayerInfo(source)
    if not playerInfo then return end
    
    local errorMessage
    if data.type == 'health' then
        errorMessage = string.format("必要HP: %d%%, 現在HP: %d%%", 
            data.required, data.current)
    elseif data.type == 'blacklist' then
        errorMessage = string.format("ブラックリストゾーン: %s", data.zone)
    elseif data.type == 'cooldown' then
        errorMessage = string.format("クールダウン中（残り: %d分）", data.remaining)
    end
    
    local embed = {
        color = Config.DiscordWebhook.colors.error,
        title = "テレポートエラーログ",
        description = string.format("プレイヤー: %s\nCitizenID: %s\n職業: %s", 
            playerInfo.name, playerInfo.citizenid, playerInfo.job),
        fields = {
            {
                name = "エラー種別",
                value = data.type,
                inline = true
            },
            {
                name = "エラー詳細",
                value = errorMessage,
                inline = true
            }
        },
        footer = {
            text = os.date("%Y-%m-%d %H:%M:%S")
        }
    }
    
    SendToDiscord(embed)
end

-- クールダウンのチェック
lib.callback.register('ng-teleport:server:CheckCooldown', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local citizenid = Player.PlayerData.citizenid
    local currentTime = os.time()
    
    -- クールダウンチェック
    if cooldowns[citizenid] then
        local timePassed = (currentTime - cooldowns[citizenid]) / 60  -- 分単位に変換
        if timePassed < Config.Cooldown then
            -- エラーログ
            LogError(source, {
                type = 'cooldown',
                remaining = math.ceil(Config.Cooldown - timePassed)
            })
            
            -- クライアントへ通知
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'エラー',
                description = string.format('クールダウン中です（残り約%d分）', 
                    math.ceil(Config.Cooldown - timePassed)),
                type = 'error'
            })
            return false
        end
    end
    
    -- クールダウンを設定
    cooldowns[citizenid] = currentTime
    return true
end)

-- テレポート成功ログイベント
RegisterNetEvent('ng-teleport:server:LogSuccess', function(data)
    LogSuccess(source, data)
end)

-- テレポートエラーログイベント
RegisterNetEvent('ng-teleport:server:LogError', function(data)
    LogError(source, data)
end)