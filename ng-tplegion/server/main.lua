local QBCore = exports['qb-core']:GetCoreObject()

-- クールダウン管理
local playerCooldowns = {}

-- データベーステーブル作成
CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `]] .. Config.DatabaseTable .. [[` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `citizenid` varchar(50) NOT NULL,
            `player_name` varchar(100) NOT NULL,
            `discord_id` varchar(100) NOT NULL,
            `from_coords` longtext NOT NULL,
            `to_coords` longtext NOT NULL,
            `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    if Config.Logging.console then
        print('^2[ng-tplegion]^7 データベーステーブルが正常に作成されました')
    end
end)

-- 権限チェック関数
local function hasPermission(source)
    if not Config.Command.restricted then
        return true
    end
    
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    for _, group in pairs(Config.AdminGroups) do
        if QBCore.Functions.HasPermission(source, group) then
            return true
        end
    end
    
    return false
end

-- クールダウンチェック関数
local function isOnCooldown(source)
    local currentTime = os.time()
    if playerCooldowns[source] and (currentTime - playerCooldowns[source]) < Config.Cooldown then
        return true
    end
    return false
end

-- Discord Webhook送信関数
local function sendToDiscord(playerName, citizenId, discordId, reason, fromCoords, toCoords, screenshotUrl)
    if not Config.Discord.enabled or not Config.Discord.webhook then return end
    
    local embed = {
        {
            ['title'] = '🚨 緊急テレポート実行',
            ['color'] = Config.Discord.color,
            ['fields'] = {
                {
                    ['name'] = 'プレイヤー名',
                    ['value'] = playerName,
                    ['inline'] = true
                },
                {
                    ['name'] = 'Citizen ID',
                    ['value'] = citizenId,
                    ['inline'] = true
                },
                {
                    ['name'] = 'Discord ID',
                    ['value'] = discordId and '<@' .. discordId .. '>' or 'unknown',
                    ['inline'] = true
                },
                {
                    ['name'] = 'テレポート理由',
                    ['value'] = reason,
                    ['inline'] = false
                },
                {
                    ['name'] = 'テレポート前の座標',
                    ['value'] = string.format('X: %.2f, Y: %.2f, Z: %.2f', fromCoords.x, fromCoords.y, fromCoords.z),
                    ['inline'] = false
                },
                {
                    ['name'] = 'テレポート先の座標',
                    ['value'] = string.format('X: %.2f, Y: %.2f, Z: %.2f', toCoords.x, toCoords.y, toCoords.z),
                    ['inline'] = false
                }
            },
            ['footer'] = {
                ['text'] = Config.Discord.footer
            },
            ['timestamp'] = os.date('!%Y-%m-%dT%H:%M:%S')
        }
    }
    
    -- スクリーンショットがある場合は画像として追加
    if screenshotUrl then
        embed[1]['image'] = {
            ['url'] = screenshotUrl
        }
    end
    
    PerformHttpRequest(Config.Discord.webhook, function(err, text, headers) end, 'POST', json.encode({
        username = Config.Discord.botName,
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

-- Discord ID取得関数
local function getDiscordId(source)
    local identifiers = GetPlayerIdentifiers(source)
    for _, identifier in pairs(identifiers) do
        if string.match(identifier, 'discord:') then
            return string.gsub(identifier, 'discord:', '')
        end
    end
    return 'unknown'
end

-- ログ保存関数
local function saveLog(source, fromCoords, toCoords, reason, screenshotUrl)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    local citizenId = Player.PlayerData.citizenid
    local discordId = getDiscordId(source)
    
    if Config.Logging.console then
        print(string.format('^3[ng-tplegion]^7 %s (%s) がテレポートコマンドを使用しました - 理由: %s', playerName, citizenId, reason))
    end
    
    -- データベースに保存
    MySQL.query('SHOW COLUMNS FROM `' .. Config.DatabaseTable .. '` LIKE "reason"', {}, function(result)
        if not result or #result == 0 then
            -- reasonとscreenshot_urlカラムが存在しない場合、追加
            MySQL.query('ALTER TABLE `' .. Config.DatabaseTable .. '` ADD COLUMN `reason` TEXT', {}, function()
                MySQL.query('ALTER TABLE `' .. Config.DatabaseTable .. '` ADD COLUMN `screenshot_url` TEXT', {}, function()
                    -- カラム追加後にデータ挿入
                    MySQL.insert('INSERT INTO `' .. Config.DatabaseTable .. '` (citizenid, player_name, discord_id, from_coords, to_coords, reason, screenshot_url) VALUES (?, ?, ?, ?, ?, ?, ?)', {
                        citizenId,
                        playerName,
                        discordId,
                        json.encode(fromCoords),
                        json.encode(toCoords),
                        reason or '',
                        screenshotUrl or ''
                    }, function(insertId)
                        if Config.Logging.console then
                            print('^2[ng-tplegion]^7 データベースにログが保存されました (ID: ' .. insertId .. ')')
                        end
                    end)
                end)
            end)
        else
            -- カラムが既に存在する場合、直接挿入
            MySQL.insert('INSERT INTO `' .. Config.DatabaseTable .. '` (citizenid, player_name, discord_id, from_coords, to_coords, reason, screenshot_url) VALUES (?, ?, ?, ?, ?, ?, ?)', {
                citizenId,
                playerName,
                discordId,
                json.encode(fromCoords),
                json.encode(toCoords),
                reason or '',
                screenshotUrl or ''
            }, function(insertId)
                if Config.Logging.console then
                    print('^2[ng-tplegion]^7 データベースにログが保存されました (ID: ' .. insertId .. ')')
                end
            end)
        end
    end)
    
    -- Discord通知送信
    sendToDiscord(playerName, citizenId, discordId, reason, fromCoords, toCoords, screenshotUrl)
end

-- テレポート要求イベント
RegisterNetEvent('ng-tplegion:server:requestTeleport', function(reason, screenshotUrl)
    local source = source
    
    -- 権限チェック
    if not hasPermission(source) then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = Config.Notifications.noPermission
        })
        return
    end
    
    -- クールダウンチェック
    if isOnCooldown(source) then
        local remainingTime = Config.Cooldown - (os.time() - playerCooldowns[source])
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'warning',
            description = Config.Notifications.cooldown .. ' (' .. remainingTime .. '秒)'
        })
        return
    end
    
    -- 理由チェック
    if not reason or reason == '' then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = Config.Notifications.reasonRequired
        })
        return
    end
    
    -- プレイヤー座標取得
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local ped = GetPlayerPed(source)
    local currentCoords = GetEntityCoords(ped)
    local fromCoords = {
        x = currentCoords.x,
        y = currentCoords.y,
        z = currentCoords.z
    }
    
    local toCoords = {
        x = Config.TeleportLocation.x,
        y = Config.TeleportLocation.y,
        z = Config.TeleportLocation.z,
        w = Config.TeleportLocation.w
    }
    
    -- テレポート実行
    TriggerClientEvent('ng-tplegion:client:teleport', source, toCoords)
    
    -- ログ保存（理由とスクリーンショット含む）
    saveLog(source, fromCoords, toCoords, reason, screenshotUrl)
    
    -- クールダウン設定
    playerCooldowns[source] = os.time()
    
    -- 成功通知
    TriggerClientEvent('ox_lib:notify', source, {
        type = 'success',
        description = Config.Notifications.success
    })
end)

-- プレイヤー切断時クールダウンクリア
AddEventHandler('playerDropped', function()
    local source = source
    if playerCooldowns[source] then
        playerCooldowns[source] = nil
    end
end)