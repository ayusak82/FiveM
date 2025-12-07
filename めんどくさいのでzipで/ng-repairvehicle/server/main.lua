local QBCore = exports['qb-core']:GetCoreObject()

-- Discord Webhook送信関数
local function SendDiscordLog(player, plate, cost, vehicleInfo, isAdmin, targetPlayer)
    if not Config.Webhook.enabled or Config.Webhook.url == '' then return end

    local embedData = {
        {
            ["title"] = isAdmin and Config.Webhook.title.admin or Config.Webhook.title.normal,
            ["color"] = isAdmin and Config.Webhook.color.admin or Config.Webhook.color.normal,
            ["footer"] = {
                ["text"] = Config.Webhook.footer
            },
            ["fields"] = {
                {
                    ["name"] = "プレイヤー名",
                    ["value"] = player.PlayerData.name,
                    ["inline"] = true
                },
                {
                    ["name"] = "プレート",
                    ["value"] = plate,
                    ["inline"] = true
                },
                {
                    ["name"] = "返却費用",
                    ["value"] = string.format("$%s", cost or 0),
                    ["inline"] = true
                },
                {
                    ["name"] = "CitizenID",
                    ["value"] = player.PlayerData.citizenid,
                    ["inline"] = true
                }
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }

    -- Admin操作の場合
    if isAdmin and targetPlayer then
        table.insert(embedData[1].fields, {
            ["name"] = "操作タイプ",
            ["value"] = "Admin返却",
            ["inline"] = true
        })
        table.insert(embedData[1].fields, {
            ["name"] = "対象プレイヤー",
            ["value"] = targetPlayer.PlayerData.name,
            ["inline"] = true
        })
    end

    -- 車両の詳細情報がある場合は追加
    if vehicleInfo then
        table.insert(embedData[1].fields, {
            ["name"] = "エンジン損傷",
            ["value"] = string.format("%.1f%%", vehicleInfo.engineDamage),
            ["inline"] = true
        })
        table.insert(embedData[1].fields, {
            ["name"] = "ボディ損傷",
            ["value"] = string.format("%.1f%%", vehicleInfo.bodyDamage),
            ["inline"] = true
        })
    end

    PerformHttpRequest(Config.Webhook.url, function(err, text, headers) end, 'POST', json.encode({
        username = Config.Webhook.name,
        embeds = embedData
    }), { ['Content-Type'] = 'application/json' })
end

-- プレイヤーのCitizenID取得
lib.callback.register('ng-repairvehicle:server:getPlayerCitizenId', function(source, targetServerId)
    local targetPlayer = QBCore.Functions.GetPlayer(targetServerId)
    if not targetPlayer then return nil end
    
    return targetPlayer.PlayerData.citizenid
end)

-- Admin権限チェック
lib.callback.register('ng-repairvehicle:server:isAdmin', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    return QBCore.Functions.HasPermission(source, 'admin') or QBCore.Functions.HasPermission(source, 'god')
end)

-- 車両の所有者チェック
lib.callback.register('ng-repairvehicle:server:checkOwner', function(source, plate, targetCitizenId)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end

    -- Admin用の所有者チェック
    if targetCitizenId then
        local result = MySQL.scalar.await('SELECT 1 FROM player_vehicles WHERE plate = ? AND citizenid = ?', {
            plate,
            targetCitizenId
        })
        return result ~= nil
    end

    -- 通常の所有者チェック
    local result = MySQL.scalar.await('SELECT 1 FROM player_vehicles WHERE plate = ? AND citizenid = ?', {
        plate,
        Player.PlayerData.citizenid
    })

    return result ~= nil
end)

-- 車両をガレージに戻す
lib.callback.register('ng-repairvehicle:server:returnVehicle', function(source, plate, cost, vehicleInfo, targetCitizenId, isAdminCommand)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end

    local isAdmin = QBCore.Functions.HasPermission(source, 'admin') or QBCore.Functions.HasPermission(source, 'god')
    local targetPlayer = nil

    -- Admin操作でない場合は支払い処理
    if not isAdmin or not isAdminCommand then
        -- 所持金チェック
        if Player.PlayerData.money.cash < cost and Player.PlayerData.money.bank < cost then
            return false
        end
        
        -- 支払い処理（現金→口座の順で確認）
        if Player.PlayerData.money.cash >= cost then
            Player.Functions.RemoveMoney('cash', cost, '車両返却費用')
        else
            Player.Functions.RemoveMoney('bank', cost, '車両返却費用')
        end
    end

    -- Admin操作の場合は対象プレイヤーを取得
    if targetCitizenId then
        targetPlayer = QBCore.Functions.GetPlayerByCitizenId(targetCitizenId)
    end

    -- engine, bodyを100%に更新
    MySQL.update('UPDATE player_vehicles SET engine = ?, body = ? WHERE plate = ?', {
        1000,
        1000,
        plate
    })

    -- 車両のstateを1に更新
    MySQL.update('UPDATE player_vehicles SET state = ? WHERE plate = ?', {
        1,
        plate
    })

    -- ログを記録
    TriggerEvent('qb-log:server:CreateLog', 'vehicle', '車両返却', 'green', string.format('%s が車両(%s)をガレージに返却しました。料金: $%s', 
        Player.PlayerData.name, plate, cost))

    -- Discord Webhookにログを送信
    SendDiscordLog(Player, plate, cost, vehicleInfo, isAdminCommand, targetPlayer)

    return true
end)

-- Export登録
exports('ReturnVehicle', function(source, plate)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end

    -- 所有者チェック
    local isOwner = MySQL.scalar.await('SELECT citizenid FROM player_vehicles WHERE plate = ? AND citizenid = ?', {
        plate,
        Player.PlayerData.citizenid
    })

    if not isOwner then return false end

    -- engine, bodyを100%に更新
    MySQL.update('UPDATE player_vehicles SET engine = ?, body = ? WHERE plate = ?', {
        1000,
        1000,
        plate
    })

    -- 車両のstateを1に更新
    MySQL.update('UPDATE player_vehicles SET state = ? WHERE plate = ?', {
        1,
        plate
    })

    -- ログを記録
    TriggerEvent('qb-log:server:CreateLog', 'vehicle', '車両返却(Export)', 'green', string.format('%s が車両(%s)をガレージに返却しました。', 
        Player.PlayerData.name, plate))
        
    -- Discord Webhookにログを送信
    SendDiscordLog(Player, plate)

    return true
end)