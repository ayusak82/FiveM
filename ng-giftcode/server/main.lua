local QBCore = exports['qb-core']:GetCoreObject()

-- デバッグ出力関数
local function debugPrint(message)
    if Config.Debug then
        print('^3[ng-giftcode]^7 ' .. message)
    end
end

-- 管理者権限チェック関数
local function isAdmin(source)
    if not source then return false end
    return IsPlayerAceAllowed(source, 'command.admin')
end

-- 管理者権限チェックのコールバック登録
lib.callback.register('ng-giftcode:server:isAdmin', function(source)
    return isAdmin(source)
end)

-- ランダムコード生成関数
local function generateRandomCode(length)
    local code = Config.CodeGeneration.Prefix or ''
    local chars = Config.CodeGeneration.AllowedCharacters
    
    for i = 1, length do
        local rand = math.random(1, #chars)
        code = code .. chars:sub(rand, rand)
    end
    
    return code
end

-- Discord Webhook送信関数
local function sendWebhook(title, description, color, fields)
    if not Config.Webhook.Enable or not Config.Webhook.URL or Config.Webhook.URL == '' then
        return
    end
    
    local embed = {
        {
            ['title'] = title,
            ['description'] = description,
            ['color'] = color or Config.Webhook.Color,
            ['fields'] = fields or {},
            ['footer'] = {
                ['text'] = os.date('%Y-%m-%d %H:%M:%S'),
            },
        }
    }
    
    PerformHttpRequest(Config.Webhook.URL, function(err, text, headers) end, 'POST', json.encode({
        username = Config.Webhook.BotName,
        avatar_url = Config.Webhook.BotAvatar,
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

-- ギフトコード作成
lib.callback.register('ng-giftcode:server:createCode', function(source, data)
    if not isAdmin(source) then
        debugPrint('Unauthorized code creation attempt by ' .. source)
        return { success = false, message = Config.Messages.Error.NoPermission }
    end
    
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        return { success = false, message = Config.Messages.Error.DatabaseError }
    end
    
    -- コード生成
    local code = (data.customCode and data.customCode ~= '') and data.customCode or generateRandomCode(Config.CodeGeneration.DefaultLength)
    
    -- 有効期限の計算
    local expireDate = nil
    if data.expireDays and tonumber(data.expireDays) > 0 then
        expireDate = os.date('%Y-%m-%d %H:%M:%S', os.time() + (tonumber(data.expireDays) * 24 * 60 * 60))
        debugPrint('Creating code with expire date: ' .. expireDate .. ' (Current time: ' .. os.date('%Y-%m-%d %H:%M:%S', os.time()) .. ')')
    end
    
    -- データベースに挿入
    local success = MySQL.insert.await('INSERT INTO giftcodes (code, items, money_type, money_amount, vehicle, max_uses, expire_date, one_per_player, allowed_identifiers, created_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        code,
        data.items and json.encode(data.items) or nil,
        data.moneyType,
        data.moneyAmount or 0,
        data.vehicle,
        data.maxUses or 1,
        expireDate,
        data.onePerPlayer and 1 or 0,
        data.allowedIdentifiers and json.encode(data.allowedIdentifiers) or nil,
        Player.PlayerData.citizenid
    })
    
    if success then
        debugPrint('Code created: ' .. code .. ' by ' .. Player.PlayerData.name)
        
        -- Webhook通知
        sendWebhook(
            '✅ ギフトコード作成',
            '新しいギフトコードが作成されました',
            3066993,
            {
                { name = 'コード', value = '`' .. code .. '`', inline = true },
                { name = '作成者', value = Player.PlayerData.name, inline = true },
                { name = '最大使用回数', value = tostring(data.maxUses or 1), inline = true },
                { name = '有効期限', value = expireDate or '無期限', inline = false },
            }
        )
        
        return { success = true, message = Config.Messages.Success.CodeCreated:format(code), code = code }
    else
        return { success = false, message = Config.Messages.Error.DatabaseError }
    end
end)

-- 一括コード生成
lib.callback.register('ng-giftcode:server:createBulkCodes', function(source, data)
    if not isAdmin(source) then
        return { success = false, message = Config.Messages.Error.NoPermission }
    end
    
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        return { success = false, message = Config.Messages.Error.DatabaseError }
    end
    
    local amount = tonumber(data.amount) or 1
    if amount < 1 or amount > 100 then
        return { success = false, message = '生成数は1～100の間で指定してください' }
    end
    
    local codes = {}
    local expireDate = nil
    
    if data.expireDays and tonumber(data.expireDays) > 0 then
        expireDate = os.date('%Y-%m-%d %H:%M:%S', os.time() + (tonumber(data.expireDays) * 24 * 60 * 60))
    end
    
    for i = 1, amount do
        local code = generateRandomCode(Config.CodeGeneration.DefaultLength)
        
        local success = MySQL.insert.await('INSERT INTO giftcodes (code, items, money_type, money_amount, vehicle, max_uses, expire_date, one_per_player, allowed_identifiers, created_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
            code,
            data.items and json.encode(data.items) or nil,
            data.moneyType,
            data.moneyAmount or 0,
            data.vehicle,
            data.maxUses or 1,
            expireDate,
            data.onePerPlayer and 1 or 0,
            data.allowedIdentifiers and json.encode(data.allowedIdentifiers) or nil,
            Player.PlayerData.citizenid
        })
        
        if success then
            table.insert(codes, code)
        end
    end
    
    if #codes > 0 then
        debugPrint('Bulk codes created: ' .. #codes .. ' codes by ' .. Player.PlayerData.name)
        
        -- Webhook通知
        sendWebhook(
            '✅ 一括ギフトコード作成',
            #codes .. '個のギフトコードが作成されました',
            3066993,
            {
                { name = '作成数', value = tostring(#codes), inline = true },
                { name = '作成者', value = Player.PlayerData.name, inline = true },
                { name = '最大使用回数', value = tostring(data.maxUses or 1), inline = true },
            }
        )
        
        return { success = true, message = #codes .. '個のコードを生成しました', codes = codes }
    else
        return { success = false, message = Config.Messages.Error.DatabaseError }
    end
end)

-- コード一覧取得
lib.callback.register('ng-giftcode:server:getCodes', function(source)
    if not isAdmin(source) then
        return nil
    end
    
    local codes = MySQL.query.await('SELECT * FROM giftcodes ORDER BY created_at DESC', {})
    
    if codes then
        for i, code in ipairs(codes) do
            if code.items then
                code.items = json.decode(code.items)
            end
            if code.allowed_identifiers then
                code.allowed_identifiers = json.decode(code.allowed_identifiers)
            end
        end
    end
    
    return codes
end)

-- コード詳細取得
lib.callback.register('ng-giftcode:server:getCodeDetails', function(source, code)
    if not isAdmin(source) then
        return nil
    end
    
    local codeData = MySQL.single.await('SELECT * FROM giftcodes WHERE code = ?', { code })
    
    if codeData then
        if codeData.items then
            codeData.items = json.decode(codeData.items)
        end
        if codeData.allowed_identifiers then
            codeData.allowed_identifiers = json.decode(codeData.allowed_identifiers)
        end
        
        -- 使用ログも取得
        local logs = MySQL.query.await('SELECT *, DATE_FORMAT(used_at, "%Y-%m-%d %H:%i:%s") as formatted_time FROM giftcode_logs WHERE code = ? ORDER BY used_at DESC', { code })
        
        -- ログの時間をフォーマット済みに置き換え
        if logs then
            for i, log in ipairs(logs) do
                log.used_at = log.formatted_time
                log.formatted_time = nil
            end
        end
        
        codeData.logs = logs or {}
    end
    
    return codeData
end)

-- コード無効化/有効化
lib.callback.register('ng-giftcode:server:toggleCode', function(source, code)
    if not isAdmin(source) then
        debugPrint('Toggle failed: No permission')
        return { success = false, message = Config.Messages.Error.NoPermission }
    end
    
    debugPrint('Toggling code: ' .. code)
    local codeData = MySQL.single.await('SELECT is_active FROM giftcodes WHERE code = ?', { code })
    
    if not codeData then
        debugPrint('Toggle failed: Code not found')
        return { success = false, message = Config.Messages.Error.InvalidCode }
    end
    
    local currentStatus = codeData.is_active
    -- boolean型をnumber型に変換
    if type(currentStatus) == 'boolean' then
        currentStatus = currentStatus and 1 or 0
    end
    local newStatus = currentStatus == 1 and 0 or 1
    debugPrint('Current status: ' .. tostring(codeData.is_active) .. ' (' .. currentStatus .. ') -> New status: ' .. tostring(newStatus))
    
    local affectedRows = MySQL.update.await('UPDATE giftcodes SET is_active = ? WHERE code = ?', {
        newStatus,
        code
    })
    
    debugPrint('Affected rows: ' .. tostring(affectedRows))
    
    if affectedRows ~= nil then
        local Player = QBCore.Functions.GetPlayer(source)
        local statusText = newStatus == 1 and '有効化' or '無効化'
        
        debugPrint('Code toggled successfully: ' .. code .. ' is now ' .. statusText)
        
        sendWebhook(
            (newStatus == 1 and '✅ ' or '❌ ') .. 'ギフトコード' .. statusText,
            'ギフトコードが' .. statusText .. 'されました',
            newStatus == 1 and 3066993 or 15158332,
            {
                { name = 'コード', value = '`' .. code .. '`', inline = true },
                { name = '操作者', value = Player and Player.PlayerData.name or 'Unknown', inline = true },
            }
        )
        
        return { success = true, message = 'コードを' .. statusText .. 'しました', newStatus = newStatus }
    else
        debugPrint('Toggle failed: Database error')
        return { success = false, message = Config.Messages.Error.DatabaseError }
    end
end)

-- コード編集
lib.callback.register('ng-giftcode:server:editCode', function(source, code, data)
    if not isAdmin(source) then
        return { success = false, message = Config.Messages.Error.NoPermission }
    end
    
    local expireDate = nil
    if data.expireDays and tonumber(data.expireDays) > 0 then
        expireDate = os.date('%Y-%m-%d %H:%M:%S', os.time() + (tonumber(data.expireDays) * 24 * 60 * 60))
    end
    
    local success = MySQL.update.await('UPDATE giftcodes SET items = ?, money_type = ?, money_amount = ?, vehicle = ?, max_uses = ?, expire_date = ?, one_per_player = ?, allowed_identifiers = ? WHERE code = ?', {
        data.items and json.encode(data.items) or nil,
        data.moneyType,
        data.moneyAmount or 0,
        data.vehicle,
        data.maxUses or 1,
        expireDate,
        data.onePerPlayer and 1 or 0,
        data.allowedIdentifiers and json.encode(data.allowedIdentifiers) or nil,
        code
    })
    
    if success then
        local Player = QBCore.Functions.GetPlayer(source)
        
        sendWebhook(
            '📝 ギフトコード編集',
            'ギフトコードが編集されました',
            15844367,
            {
                { name = 'コード', value = '`' .. code .. '`', inline = true },
                { name = '編集者', value = Player and Player.PlayerData.name or 'Unknown', inline = true },
            }
        )
        
        return { success = true, message = Config.Messages.Success.CodeEdited }
    else
        return { success = false, message = Config.Messages.Error.DatabaseError }
    end
end)

-- コード削除
lib.callback.register('ng-giftcode:server:deleteCode', function(source, code)
    if not isAdmin(source) then
        return { success = false, message = Config.Messages.Error.NoPermission }
    end
    
    local success = MySQL.query.await('DELETE FROM giftcodes WHERE code = ?', { code })
    
    if success then
        -- ログも削除
        MySQL.query.await('DELETE FROM giftcode_logs WHERE code = ?', { code })
        
        local Player = QBCore.Functions.GetPlayer(source)
        
        sendWebhook(
            '🗑️ ギフトコード削除',
            'ギフトコードが削除されました',
            15158332,
            {
                { name = 'コード', value = '`' .. code .. '`', inline = true },
                { name = '削除者', value = Player and Player.PlayerData.name or 'Unknown', inline = true },
            }
        )
        
        return { success = true, message = 'コードを削除しました' }
    else
        return { success = false, message = Config.Messages.Error.DatabaseError }
    end
end)

-- 統計情報取得
lib.callback.register('ng-giftcode:server:getStatistics', function(source)
    if not isAdmin(source) then
        return nil
    end
    
    local stats = {}
    
    -- 総コード数
    local totalCodes = MySQL.single.await('SELECT COUNT(*) as count FROM giftcodes', {})
    stats.totalCodes = totalCodes and totalCodes.count or 0
    
    -- 有効なコード数
    local activeCodes = MySQL.single.await('SELECT COUNT(*) as count FROM giftcodes WHERE is_active = 1', {})
    stats.activeCodes = activeCodes and activeCodes.count or 0
    
    -- 期限切れコード数
    local expiredCodes = MySQL.single.await('SELECT COUNT(*) as count FROM giftcodes WHERE expire_date IS NOT NULL AND expire_date < NOW()', {})
    stats.expiredCodes = expiredCodes and expiredCodes.count or 0
    
    -- 総使用回数
    local totalUses = MySQL.single.await('SELECT COUNT(*) as count FROM giftcode_logs', {})
    stats.totalUses = totalUses and totalUses.count or 0
    
    -- 今日の使用回数
    local todayUses = MySQL.single.await('SELECT COUNT(*) as count FROM giftcode_logs WHERE DATE(used_at) = CURDATE()', {})
    stats.todayUses = todayUses and todayUses.count or 0
    
    -- 今週の使用回数
    local weekUses = MySQL.single.await('SELECT COUNT(*) as count FROM giftcode_logs WHERE YEARWEEK(used_at) = YEARWEEK(NOW())', {})
    stats.weekUses = weekUses and weekUses.count or 0
    
    -- 最も使用されているコード
    local topCode = MySQL.single.await('SELECT code, COUNT(*) as uses FROM giftcode_logs GROUP BY code ORDER BY uses DESC LIMIT 1', {})
    stats.topCode = topCode or { code = 'なし', uses = 0 }
    
    return stats
end)

-- ギフトコード使用
lib.callback.register('ng-giftcode:server:useCode', function(source, code)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        return { success = false, message = Config.Messages.Error.DatabaseError }
    end
    
    -- コード取得
    local codeData = MySQL.single.await('SELECT * FROM giftcodes WHERE code = ?', { code })
    
    if not codeData then
        return { success = false, message = Config.Messages.Error.InvalidCode }
    end
    
    -- 有効性チェック
    debugPrint('Is active check: ' .. tostring(codeData.is_active))
    
    -- boolean型をnumber型に変換
    local isActive = codeData.is_active
    if type(isActive) == 'boolean' then
        isActive = isActive and 1 or 0
    end
    
    debugPrint('Is active (converted): ' .. tostring(isActive))
    
    if isActive == 0 then
        return { success = false, message = Config.Messages.Error.InactiveCode }
    end
    
    -- 有効期限チェック
    if codeData.expire_date then
        debugPrint('Checking expiration for code: ' .. code)
        debugPrint('Expire date from DB: ' .. tostring(codeData.expire_date))
        debugPrint('Current time: ' .. os.date('%Y-%m-%d %H:%M:%S', os.time()))
        
        -- MySQLの比較を使用
        local isExpired = MySQL.single.await('SELECT IF(expire_date < NOW(), 1, 0) as expired FROM giftcodes WHERE code = ?', { code })
        
        debugPrint('Is expired: ' .. tostring(isExpired and isExpired.expired or 'nil'))
        
        if isExpired and isExpired.expired == 1 then
            debugPrint('Code is expired')
            return { success = false, message = Config.Messages.Error.ExpiredCode }
        end
    end
    
    -- 使用回数チェック
    if codeData.current_uses >= codeData.max_uses then
        return { success = false, message = Config.Messages.Error.MaxUsesReached }
    end
    
    -- 1人1回制限チェック
    debugPrint('One per player check: ' .. tostring(codeData.one_per_player))
    
    -- boolean型をnumber型に変換
    local onePerPlayer = codeData.one_per_player
    if type(onePerPlayer) == 'boolean' then
        onePerPlayer = onePerPlayer and 1 or 0
    end
    
    debugPrint('One per player (converted): ' .. tostring(onePerPlayer))
    
    if onePerPlayer == 1 then
        local alreadyUsed = MySQL.single.await('SELECT id FROM giftcode_logs WHERE code = ? AND identifier = ?', {
            code,
            Player.PlayerData.citizenid
        })
        
        debugPrint('Already used check result: ' .. tostring(alreadyUsed and 'YES' or 'NO'))
        
        if alreadyUsed then
            return { success = false, message = Config.Messages.Error.AlreadyUsed }
        end
    end
    
    -- 許可リストチェック
    if codeData.allowed_identifiers then
        local allowedList = json.decode(codeData.allowed_identifiers)
        if allowedList and #allowedList > 0 then
            local isAllowed = false
            for _, identifier in ipairs(allowedList) do
                if identifier == Player.PlayerData.citizenid or identifier == Player.PlayerData.license then
                    isAllowed = true
                    break
                end
            end
            
            if not isAllowed then
                return { success = false, message = Config.Messages.Error.NotAllowed }
            end
        end
    end
    
    -- 報酬配布
    local rewards = {}
    
    -- お金
    if codeData.money_amount and codeData.money_amount > 0 then
        if codeData.money_type == 'cash' then
            Player.Functions.AddMoney('cash', codeData.money_amount)
            table.insert(rewards, '現金: $' .. codeData.money_amount)
        elseif codeData.money_type == 'bank' then
            Player.Functions.AddMoney('bank', codeData.money_amount)
            table.insert(rewards, '銀行: $' .. codeData.money_amount)
        elseif codeData.money_type == 'crypto' then
            Player.Functions.AddMoney('crypto', codeData.money_amount)
            table.insert(rewards, '暗号通貨: ' .. codeData.money_amount)
        end
    end
    
    -- アイテム
    if codeData.items then
        local items = json.decode(codeData.items)
        if items then
            for _, item in ipairs(items) do
                if exports.ox_inventory:CanCarryItem(source, item.name, item.amount) then
                    exports.ox_inventory:AddItem(source, item.name, item.amount)
                    table.insert(rewards, item.name .. ' x' .. item.amount)
                else
                    return { success = false, message = Config.Messages.Error.InventoryFull }
                end
            end
        end
    end
    
    -- 車両
    if codeData.vehicle and codeData.vehicle ~= '' then
        if Config.VehicleSpawn.SpawnInGarage then
            local plate = 'GIFT'..math.random(1000, 9999)
            MySQL.insert.await('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
                Player.PlayerData.license,
                Player.PlayerData.citizenid,
                codeData.vehicle,
                GetHashKey(codeData.vehicle),
                '{}',
                plate,
                'pillboxgarage',
                0
            })
            table.insert(rewards, '車両: ' .. codeData.vehicle)
        end
    end
    
    -- 使用回数更新
    MySQL.update.await('UPDATE giftcodes SET current_uses = current_uses + 1 WHERE code = ?', { code })
    
    -- ログ記録
    MySQL.insert.await('INSERT INTO giftcode_logs (code, identifier, player_name, license, rewards) VALUES (?, ?, ?, ?, ?)', {
        code,
        Player.PlayerData.citizenid,
        Player.PlayerData.name,
        Player.PlayerData.license,
        json.encode(rewards)
    })
    
    -- Webhook通知
    sendWebhook(
        '🎁 ギフトコード使用',
        'プレイヤーがギフトコードを使用しました',
        3066993,
        {
            { name = 'プレイヤー', value = Player.PlayerData.name, inline = true },
            { name = 'コード', value = '`' .. code .. '`', inline = true },
            { name = '報酬', value = table.concat(rewards, '\n'), inline = false },
        }
    )
    
    debugPrint('Code used: ' .. code .. ' by ' .. Player.PlayerData.name)
    
    return { success = true, message = Config.Messages.Success.CodeUsed, rewards = rewards }
end)

-- コマンド登録
if Config.Commands.AdminMenu then
    QBCore.Commands.Add(Config.Commands.AdminMenu, '管理者用ギフトコードメニューを開く', {}, false, function(source)
        if isAdmin(source) then
            TriggerClientEvent('ng-giftcode:client:openAdminMenu', source)
        else
            TriggerClientEvent('QBCore:Notify', source, Config.Messages.Error.NoPermission, 'error')
        end
    end, 'admin')
end

if Config.Commands.UseCode then
    QBCore.Commands.Add(Config.Commands.UseCode, 'ギフトコードを使用する', {{ name = 'code', help = 'ギフトコード' }}, true, function(source, args)
        local code = args[1]
        if not code then
            TriggerClientEvent('QBCore:Notify', source, 'コードを入力してください', 'error')
            return
        end
        
        TriggerClientEvent('ng-giftcode:client:useCode', source, code)
    end)
end

debugPrint('Server initialized successfully')
