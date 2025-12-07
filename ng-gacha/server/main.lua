--[[
    ng-gacha - Server Side
    Author: NCCGr
    Contact: Discord: ayusak
]]

local QBCore = exports['qb-core']:GetCoreObject()

-- Debug Functions
local function DebugPrint(...)
    if not Config.Debug then return end
    local args = {...}
    local message = ''
    for i = 1, #args do
        message = message .. tostring(args[i]) .. ' '
    end
    print('^3[ng-gacha:DEBUG]^7 ' .. message)
end

local function ErrorPrint(...)
    local args = {...}
    local message = ''
    for i = 1, #args do
        message = message .. tostring(args[i]) .. ' '
    end
    print('^1[ng-gacha:ERROR]^7 ' .. message)
end

local function SuccessPrint(...)
    if not Config.Debug then return end
    local args = {...}
    local message = ''
    for i = 1, #args do
        message = message .. tostring(args[i]) .. ' '
    end
    print('^2[ng-gacha:SUCCESS]^7 ' .. message)
end

-- Get Player Identifier
local function GetIdentifier(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return nil end
    return Player.PlayerData.citizenid
end

-- Get Item Label from QBCore
local function GetItemLabel(itemName)
    local item = QBCore.Shared.Items[itemName]
    if item then
        return item.label
    end
    return itemName
end

-- Initialize Database Tables
local function InitializeDatabase()
    DebugPrint('Initializing database tables...')
    
    -- Main gacha table
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `ng_gacha` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `creator_identifier` VARCHAR(50) NOT NULL,
            `creator_name` VARCHAR(100) DEFAULT 'Unknown',
            `name` VARCHAR(100) NOT NULL,
            `description` TEXT,
            `price` INT NOT NULL DEFAULT 500,
            `price_type` VARCHAR(20) NOT NULL DEFAULT 'money',
            `color_theme` VARCHAR(20) NOT NULL DEFAULT 'cyan',
            `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
            `total_pulls` INT NOT NULL DEFAULT 0,
            `total_revenue` BIGINT NOT NULL DEFAULT 0,
            `pity_count` INT NOT NULL DEFAULT 100,
            `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
            `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX `idx_creator` (`creator_identifier`),
            INDEX `idx_active` (`is_active`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
    
    -- Gacha items/prizes table
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `ng_gacha_items` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `gacha_id` INT NOT NULL,
            `item_name` VARCHAR(50) NOT NULL,
            `item_count` INT NOT NULL DEFAULT 1,
            `rarity` VARCHAR(20) NOT NULL DEFAULT 'common',
            `probability` DECIMAL(6,3) NOT NULL,
            `is_jackpot` BOOLEAN NOT NULL DEFAULT FALSE,
            `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (`gacha_id`) REFERENCES `ng_gacha`(`id`) ON DELETE CASCADE,
            INDEX `idx_gacha` (`gacha_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
    
    -- Gacha history table
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `ng_gacha_history` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `gacha_id` INT NOT NULL,
            `player_identifier` VARCHAR(50) NOT NULL,
            `player_name` VARCHAR(100) DEFAULT 'Unknown',
            `item_name` VARCHAR(50) NOT NULL,
            `item_count` INT NOT NULL DEFAULT 1,
            `rarity` VARCHAR(20) NOT NULL,
            `is_jackpot` BOOLEAN NOT NULL DEFAULT FALSE,
            `pulled_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (`gacha_id`) REFERENCES `ng_gacha`(`id`) ON DELETE CASCADE,
            INDEX `idx_gacha` (`gacha_id`),
            INDEX `idx_player` (`player_identifier`),
            INDEX `idx_pulled` (`pulled_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
    
    -- Pity counter table
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `ng_gacha_pity` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `gacha_id` INT NOT NULL,
            `player_identifier` VARCHAR(50) NOT NULL,
            `count` INT NOT NULL DEFAULT 0,
            `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            UNIQUE KEY `unique_gacha_player` (`gacha_id`, `player_identifier`),
            FOREIGN KEY (`gacha_id`) REFERENCES `ng_gacha`(`id`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
    
    SuccessPrint('Database tables initialized')
end

-- Discord Webhook
local function SendDiscordLog(title, description, color)
    if not Config.Discord.enabled or not Config.Discord.webhook or Config.Discord.webhook == '' then
        return
    end
    
    local embed = {
        {
            title = title,
            description = description,
            color = color or 3447003,
            footer = {
                text = os.date('%Y-%m-%d %H:%M:%S')
            }
        }
    }
    
    PerformHttpRequest(Config.Discord.webhook, function(err, text, headers) end, 'POST', json.encode({
        username = Config.Discord.botName,
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

-- Get Gacha Data with Prizes
local function GetGachaData(gachaId)
    local gacha = MySQL.single.await('SELECT * FROM `ng_gacha` WHERE `id` = ? AND `is_active` = TRUE', { gachaId })
    
    if not gacha then
        return nil
    end
    
    local prizes = MySQL.query.await('SELECT * FROM `ng_gacha_items` WHERE `gacha_id` = ? ORDER BY `probability` ASC', { gachaId })
    
    -- Get item labels from QBCore
    for _, prize in ipairs(prizes) do
        prize.item_label = GetItemLabel(prize.item_name)
    end
    
    gacha.prizes = prizes
    
    return gacha
end

-- Get Player's Pity Count
local function GetPityCount(gachaId, identifier)
    local result = MySQL.single.await('SELECT `count` FROM `ng_gacha_pity` WHERE `gacha_id` = ? AND `player_identifier` = ?', {
        gachaId, identifier
    })
    
    return result and result.count or 0
end

-- Update Player's Pity Count
local function UpdatePityCount(gachaId, identifier, count)
    MySQL.query.await([[
        INSERT INTO `ng_gacha_pity` (`gacha_id`, `player_identifier`, `count`)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE `count` = ?
    ]], { gachaId, identifier, count, count })
end

-- Reset Player's Pity Count
local function ResetPityCount(gachaId, identifier)
    MySQL.update.await('UPDATE `ng_gacha_pity` SET `count` = 0 WHERE `gacha_id` = ? AND `player_identifier` = ?', {
        gachaId, identifier
    })
end

-- Pull Single Item from Gacha
local function PullSingleItem(prizes, pityCount, pityMax, forceLegendary)
    -- If pity reached, force legendary
    if forceLegendary or (pityMax > 0 and pityCount >= pityMax) then
        for _, prize in ipairs(prizes) do
            if prize.rarity == 'legendary' or prize.is_jackpot then
                return prize, true
            end
        end
    end
    
    -- Normal probability pull
    local rand = math.random() * 100
    local cumulative = 0
    
    for _, prize in ipairs(prizes) do
        cumulative = cumulative + prize.probability
        if rand <= cumulative then
            return prize, false
        end
    end
    
    -- Fallback to first prize (should not happen if probabilities sum to 100)
    return prizes[1], false
end

-- Check if player has item (QBCore)
local function HasItem(source, itemName, amount)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local item = Player.Functions.GetItemByName(itemName)
    if not item then return false end
    
    return item.amount >= (amount or 1)
end

-- Remove item from player (QBCore)
local function RemoveItem(source, itemName, amount)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    return Player.Functions.RemoveItem(itemName, amount or 1)
end

-- Add item to player (QBCore)
local function AddItem(source, itemName, amount, metadata)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    return Player.Functions.AddItem(itemName, amount or 1, nil, metadata)
end

-- Process Payment
local function ProcessPayment(source, priceType, price)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false, 'Player not found' end
    
    if priceType == 'money' then
        if Player.PlayerData.money.cash >= price then
            Player.Functions.RemoveMoney('cash', price, 'gacha-pull')
            return true
        else
            return false, '現金が足りません'
        end
    elseif priceType == 'bank' then
        if Player.PlayerData.money.bank >= price then
            Player.Functions.RemoveMoney('bank', price, 'gacha-pull')
            return true
        else
            return false, '銀行残高が足りません'
        end
    elseif priceType == 'coin' then
        if HasItem(source, Config.GachaCoinItem, price) then
            RemoveItem(source, Config.GachaCoinItem, price)
            return true
        else
            return false, 'ガチャコインが足りません'
        end
    end
    
    return false, '無効な支払い方法です'
end

-- Add Revenue to Creator
local function AddRevenueToCreator(gachaId, amount, priceType)
    -- Update gacha revenue
    MySQL.update.await('UPDATE `ng_gacha` SET `total_revenue` = `total_revenue` + ? WHERE `id` = ?', {
        amount, gachaId
    })
end

-- Record Pull History
local function RecordHistory(gachaId, identifier, playerName, itemName, itemCount, rarity, isJackpot)
    MySQL.insert.await([[
        INSERT INTO `ng_gacha_history` (`gacha_id`, `player_identifier`, `player_name`, `item_name`, `item_count`, `rarity`, `is_jackpot`)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], { gachaId, identifier, playerName, itemName, itemCount, rarity, isJackpot })
end

-- QBCore Item Use Handlers
QBCore.Functions.CreateUseableItem(Config.GachaTicketItem, function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    DebugPrint('Gacha ticket used by', source)
    TriggerClientEvent('ng-gacha:client:useGachaTicket', source)
end)

QBCore.Functions.CreateUseableItem('gacha_machine', function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    DebugPrint('Gacha machine used by', source, 'item:', json.encode(item))
    TriggerClientEvent('ng-gacha:client:useGachaMachine', source, item)
end)

-- Callbacks
lib.callback.register('ng-gacha:server:getGachaData', function(source, gachaId)
    local identifier = GetIdentifier(source)
    if not identifier then
        return { success = false, error = 'Player not found' }
    end
    
    local gacha = GetGachaData(gachaId)
    if not gacha then
        return { success = false, error = 'ガチャが見つかりません' }
    end
    
    -- Get player's pity count
    gacha.current_pity = GetPityCount(gachaId, identifier)
    
    return { success = true, gacha = gacha }
end)

lib.callback.register('ng-gacha:server:pullGacha', function(source, gachaId, count)
    local identifier = GetIdentifier(source)
    local Player = QBCore.Functions.GetPlayer(source)
    
    if not identifier or not Player then
        return { success = false, error = 'Player not found' }
    end
    
    local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    
    DebugPrint('Pull request from', identifier, 'gacha:', gachaId, 'count:', count)
    
    -- Validate count
    count = math.min(count, Config.MultiPull.count)
    count = math.max(count, 1)
    
    -- Get gacha data
    local gacha = GetGachaData(gachaId)
    if not gacha then
        return { success = false, error = 'ガチャが見つかりません' }
    end
    
    if not gacha.prizes or #gacha.prizes == 0 then
        return { success = false, error = '景品がありません' }
    end
    
    -- Calculate total price
    local totalPrice = gacha.price * count
    if count == Config.MultiPull.count and Config.MultiPull.discount > 0 then
        totalPrice = math.floor(totalPrice * (1 - Config.MultiPull.discount / 100))
    end
    
    -- Process payment
    local paymentSuccess, paymentError = ProcessPayment(source, gacha.price_type, totalPrice)
    if not paymentSuccess then
        return { success = false, error = paymentError }
    end
    
    -- Get current pity count
    local currentPity = GetPityCount(gachaId, identifier)
    
    -- Pull items
    local pulledItems = {}
    
    for i = 1, count do
        currentPity = currentPity + 1
        local forceLegendary = gacha.pity_count > 0 and currentPity >= gacha.pity_count
        
        local prize, isPityWin = PullSingleItem(gacha.prizes, currentPity, gacha.pity_count, forceLegendary)
        
        if prize then
            -- Add item to player
            local itemLabel = GetItemLabel(prize.item_name)
            local added = AddItem(source, prize.item_name, prize.item_count)
            
            if not added then
                TriggerClientEvent('ng-gacha:client:notify', source, '警告', '持ち物がいっぱいです。一部のアイテムを受け取れませんでした。', 'warning')
            end
            
            table.insert(pulledItems, {
                item_name = prize.item_name,
                item_label = itemLabel,
                item_count = prize.item_count,
                rarity = prize.rarity,
                is_jackpot = prize.is_jackpot or false
            })
            
            -- Record history
            RecordHistory(gachaId, identifier, playerName, prize.item_name, prize.item_count, prize.rarity, prize.is_jackpot or false)
            
            -- Reset pity if legendary/jackpot
            if prize.rarity == 'legendary' or prize.is_jackpot or isPityWin then
                currentPity = 0
                
                -- Discord log for jackpot
                if Config.Discord.logJackpot and prize.is_jackpot then
                    SendDiscordLog(
                        '🎉 ジャックポット!',
                        string.format('**%s** が **%s** で **%s x%d** を獲得しました！',
                            playerName, gacha.name, itemLabel, prize.item_count),
                        16766720 -- Gold color
                    )
                end
            end
        end
    end
    
    -- Update pity count
    UpdatePityCount(gachaId, identifier, currentPity)
    
    -- Update gacha statistics
    MySQL.update.await('UPDATE `ng_gacha` SET `total_pulls` = `total_pulls` + ? WHERE `id` = ?', {
        count, gachaId
    })
    
    -- Add revenue to creator
    AddRevenueToCreator(gachaId, totalPrice, gacha.price_type)
    
    SuccessPrint('Player', identifier, 'pulled', count, 'times from gacha', gachaId)
    
    return {
        success = true,
        items = pulledItems,
        pityCount = currentPity
    }
end)

lib.callback.register('ng-gacha:server:canCreateGacha', function(source)
    local identifier = GetIdentifier(source)
    if not identifier then
        return { success = false, error = 'Player not found' }
    end
    
    -- Check gacha ticket
    if not HasItem(source, Config.GachaTicketItem, 1) then
        return { success = false, error = 'ガチャチケットを持っていません' }
    end
    
    -- Check gacha count limit
    local count = MySQL.scalar.await('SELECT COUNT(*) FROM `ng_gacha` WHERE `creator_identifier` = ?', { identifier })
    if count and count >= Config.Limits.maxGachaPerPlayer then
        return { success = false, error = '作成できるガチャの上限に達しています (' .. Config.Limits.maxGachaPerPlayer .. '個)' }
    end
    
    return { success = true }
end)

lib.callback.register('ng-gacha:server:createGacha', function(source, data)
    local identifier = GetIdentifier(source)
    local Player = QBCore.Functions.GetPlayer(source)
    
    if not identifier or not Player then
        return { success = false, error = 'Player not found' }
    end
    
    local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    
    DebugPrint('Create gacha request from', identifier, 'name:', data.name)
    
    -- Validate
    if not data.name or data.name == '' then
        return { success = false, error = 'ガチャ名を入力してください' }
    end
    
    if not data.prizes or #data.prizes == 0 then
        return { success = false, error = '景品を追加してください' }
    end
    
    if #data.prizes > Config.DefaultGachaSettings.maxPrizesPerGacha then
        return { success = false, error = '景品は最大' .. Config.DefaultGachaSettings.maxPrizesPerGacha .. '個までです' }
    end
    
    -- Validate price
    local price = tonumber(data.price) or Config.DefaultGachaSettings.price
    if price < Config.Limits.minPrice or price > Config.Limits.maxPrice then
        return { success = false, error = '料金は' .. Config.Limits.minPrice .. '〜' .. Config.Limits.maxPrice .. 'の範囲で設定してください' }
    end
    
    -- Validate probability total
    local totalProb = 0
    for _, prize in ipairs(data.prizes) do
        totalProb = totalProb + (tonumber(prize.probability) or 0)
    end
    
    if math.abs(totalProb - 100) > 0.1 then
        return { success = false, error = '確率の合計が100%になるように調整してください (現在: ' .. string.format('%.1f', totalProb) .. '%)' }
    end
    
    -- Check and remove gacha ticket
    if not HasItem(source, Config.GachaTicketItem, 1) then
        return { success = false, error = 'ガチャチケットを持っていません' }
    end
    
    RemoveItem(source, Config.GachaTicketItem, 1)
    
    -- Create gacha
    local gachaId = MySQL.insert.await([[
        INSERT INTO `ng_gacha` (`creator_identifier`, `creator_name`, `name`, `description`, `price`, `price_type`, `color_theme`, `pity_count`)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        identifier,
        playerName,
        data.name,
        data.description or '',
        price,
        data.priceType or 'money',
        data.colorTheme or 'cyan',
        tonumber(data.pityCount) or 100
    })
    
    if not gachaId then
        -- Refund ticket
        AddItem(source, Config.GachaTicketItem, 1)
        return { success = false, error = 'ガチャの作成に失敗しました' }
    end
    
    -- Add prizes
    for _, prize in ipairs(data.prizes) do
        MySQL.insert.await([[
            INSERT INTO `ng_gacha_items` (`gacha_id`, `item_name`, `item_count`, `rarity`, `probability`, `is_jackpot`)
            VALUES (?, ?, ?, ?, ?, ?)
        ]], {
            gachaId,
            prize.itemName,
            tonumber(prize.itemCount) or 1,
            prize.rarity or 'common',
            tonumber(prize.probability) or 0,
            prize.isJackpot and 1 or 0
        })
    end
    
    -- Create gacha machine item for player
    local gachaItemInfo = {
        gacha_id = gachaId,
        gacha_name = data.name,
        creator = playerName,
        created_at = os.date('%Y-%m-%d %H:%M:%S')
    }
    
    AddItem(source, 'gacha_machine', 1, gachaItemInfo)
    
    SuccessPrint('Gacha created:', gachaId, 'by', identifier)
    
    -- Discord log
    if Config.Discord.logCreation then
        SendDiscordLog(
            '🎰 新しいガチャ作成',
            string.format('**%s** が新しいガチャ「**%s**」を作成しました\n料金: %s / 回\n景品数: %d',
                playerName, data.name, price, #data.prizes),
            3447003 -- Blue color
        )
    end
    
    return { success = true, gachaId = gachaId }
end)

lib.callback.register('ng-gacha:server:getHistory', function(source, gachaId)
    local identifier = GetIdentifier(source)
    if not identifier then
        return { success = false, history = {} }
    end
    
    local history = MySQL.query.await([[
        SELECT `item_name`, `item_count`, `rarity`, `is_jackpot`, `pulled_at`
        FROM `ng_gacha_history`
        WHERE `gacha_id` = ? AND `player_identifier` = ?
        ORDER BY `pulled_at` DESC
        LIMIT 50
    ]], { gachaId, identifier })
    
    -- Get item labels
    for _, record in ipairs(history or {}) do
        record.item_label = GetItemLabel(record.item_name)
    end
    
    return { success = true, history = history or {} }
end)

-- Get player's created gachas
lib.callback.register('ng-gacha:server:getMyGachas', function(source)
    local identifier = GetIdentifier(source)
    if not identifier then
        return { success = false, gachas = {} }
    end
    
    local gachas = MySQL.query.await([[
        SELECT `id`, `name`, `price`, `price_type`, `total_pulls`, `total_revenue`, `is_active`, `created_at`
        FROM `ng_gacha`
        WHERE `creator_identifier` = ?
        ORDER BY `created_at` DESC
    ]], { identifier })
    
    return { success = true, gachas = gachas or {} }
end)

-- Initialize on resource start
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        InitializeDatabase()
        SuccessPrint('ng-gacha server initialized')
    end
end)

-- Commands (Admin)
QBCore.Commands.Add('gachareload', 'ガチャシステムをリロード (Admin)', {}, false, function(source)
    InitializeDatabase()
    TriggerClientEvent('ng-gacha:client:notify', source, '成功', 'ガチャシステムをリロードしました', 'success')
end, 'admin')

QBCore.Commands.Add('giveticket', 'ガチャチケットを付与 (Admin)', {
    { name = 'id', help = 'Player ID' },
    { name = 'amount', help = 'Amount' }
}, true, function(source, args)
    local targetId = tonumber(args[1])
    local amount = tonumber(args[2]) or 1
    
    if not targetId then
        TriggerClientEvent('ng-gacha:client:notify', source, 'エラー', 'プレイヤーIDを指定してください', 'error')
        return
    end
    
    local Target = QBCore.Functions.GetPlayer(targetId)
    if not Target then
        TriggerClientEvent('ng-gacha:client:notify', source, 'エラー', 'プレイヤーが見つかりません', 'error')
        return
    end
    
    AddItem(targetId, Config.GachaTicketItem, amount)
    TriggerClientEvent('ng-gacha:client:notify', source, '成功', 'ガチャチケットを付与しました', 'success')
    TriggerClientEvent('ng-gacha:client:notify', targetId, '受け取り', 'ガチャチケット x' .. amount .. ' を受け取りました', 'success')
end, 'admin')

QBCore.Commands.Add('givecoin', 'ガチャコインを付与 (Admin)', {
    { name = 'id', help = 'Player ID' },
    { name = 'amount', help = 'Amount' }
}, true, function(source, args)
    local targetId = tonumber(args[1])
    local amount = tonumber(args[2]) or 1
    
    if not targetId then
        TriggerClientEvent('ng-gacha:client:notify', source, 'エラー', 'プレイヤーIDを指定してください', 'error')
        return
    end
    
    local Target = QBCore.Functions.GetPlayer(targetId)
    if not Target then
        TriggerClientEvent('ng-gacha:client:notify', source, 'エラー', 'プレイヤーが見つかりません', 'error')
        return
    end
    
    AddItem(targetId, Config.GachaCoinItem, amount)
    TriggerClientEvent('ng-gacha:client:notify', source, '成功', 'ガチャコインを付与しました', 'success')
    TriggerClientEvent('ng-gacha:client:notify', targetId, '受け取り', 'ガチャコイン x' .. amount .. ' を受け取りました', 'success')
end, 'admin')
