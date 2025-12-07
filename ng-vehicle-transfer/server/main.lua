local QBCore = exports['qb-core']:GetCoreObject()

-- データベーステーブル作成
CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `]] .. Config.TableName .. [[` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `citizenid` varchar(50) NOT NULL,
            `discordid` varchar(50) DEFAULT NULL,
            `vehicle_name` varchar(100) NOT NULL,
            `vehicle_plate` varchar(20) NOT NULL,
            `export_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `unique_citizenid` (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end)

-- 使用済みチェックのコールバック
QBCore.Functions.CreateCallback('ng-vehicle-transfer:checkUsed', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(true)
        return
    end
    
    local citizenid = Player.PlayerData.citizenid
    
    MySQL.scalar('SELECT COUNT(*) FROM `' .. Config.TableName .. '` WHERE citizenid = ?', {citizenid}, function(count)
        cb(count > 0)
    end)
end)

-- 車両エクスポート処理
RegisterNetEvent('ng-vehicle-transfer:exportVehicle', function(vehicleData)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        TriggerClientEvent('ng-vehicle-transfer:exportResult', src, false)
        return
    end
    
    local citizenid = Player.PlayerData.citizenid
    local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    
    -- Discord ID取得
    local discordId = nil
    local identifiers = GetPlayerIdentifiers(src)
    for _, identifier in pairs(identifiers) do
        if string.match(identifier, "discord:") then
            discordId = string.gsub(identifier, "discord:", "")
            break
        end
    end
    
    -- 再度使用済みチェック
    MySQL.scalar('SELECT COUNT(*) FROM `' .. Config.TableName .. '` WHERE citizenid = ?', {citizenid}, function(count)
        if count > 0 then
            TriggerClientEvent('ng-vehicle-transfer:exportResult', src, false)
            return
        end
        
        -- データベースに保存
        MySQL.insert('INSERT INTO `' .. Config.TableName .. '` (citizenid, discordid, vehicle_name, vehicle_plate) VALUES (?, ?, ?, ?)', {
            citizenid,
            discordId,
            vehicleData.name,
            vehicleData.plate
        }, function(insertId)
            if insertId then
                -- Discord webhook送信
                sendDiscordWebhook({
                    citizenid = citizenid,
                    discordid = discordId,
                    playerName = playerName,
                    vehicleName = vehicleData.name,
                    vehiclePlate = vehicleData.plate,
                    exportDate = os.date('%Y-%m-%d %H:%M:%S')
                })
                
                TriggerClientEvent('ng-vehicle-transfer:exportResult', src, true)
                print(string.format('[ng-vehicle-transfer] Player %s (%s) exported vehicle: %s (%s)', playerName, citizenid, vehicleData.name, vehicleData.plate))
            else
                TriggerClientEvent('ng-vehicle-transfer:exportResult', src, false)
            end
        end)
    end)
end)

-- Discord Webhook送信関数
function sendDiscordWebhook(data)
    if not Config.DiscordWebhook or Config.DiscordWebhook == "YOUR_DISCORD_WEBHOOK_URL_HERE" then
        return
    end
    
    local embed = {
        {
            title = Config.DiscordEmbed.title,
            color = Config.DiscordEmbed.color,
            fields = {
                {
                    name = "👤 プレイヤー情報",
                    value = string.format("**名前:** %s\n**Citizen ID:** %s\n**Discord ID:** %s", 
                        data.playerName,
                        data.citizenid,
                        data.discordid or "不明"
                    ),
                    inline = true
                },
                {
                    name = "🚗 車両情報",
                    value = string.format("**車両名:** %s\n**プレート:** %s", 
                        data.vehicleName,
                        data.vehiclePlate
                    ),
                    inline = true
                },
                {
                    name = "📅 エクスポート日時",
                    value = data.exportDate,
                    inline = false
                }
            },
            footer = {
                text = Config.DiscordEmbed.footer.text,
                icon_url = Config.DiscordEmbed.footer.icon_url
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }
    
    PerformHttpRequest(Config.DiscordWebhook, function(err, text, headers) end, 'POST', json.encode({
        username = "Vehicle Transfer System",
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end