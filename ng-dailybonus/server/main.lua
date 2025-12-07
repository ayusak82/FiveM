local QBCore = exports['qb-core']:GetCoreObject()

-- データベース初期化
local function InitializeDatabase()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS ng_dailybonus (
            id INT AUTO_INCREMENT PRIMARY KEY,
            citizenid VARCHAR(50) NOT NULL,
            bonus_type VARCHAR(100) NOT NULL,
            last_claimed TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_citizenid (citizenid),
            INDEX idx_bonus_type (bonus_type),
            UNIQUE KEY unique_claim (citizenid, bonus_type)
        )
    ]], {}, function(result)
        if Config.Debug then
            print('[ng-dailybonus] データベーステーブルを初期化しました')
        end
    end)
end

-- サーバー開始時にデータベースを初期化
CreateThread(function()
    Wait(5000) -- 他のリソースの読み込みを待つ
    InitializeDatabase()
    
    -- Discordロールキャッシュを初期化
    DiscordRoleCache = {}
end)

-- 重量チェック関数 (ox_inventory対応)
local function CheckPlayerWeight(src, rewards)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    -- ox_inventory を使用している場合の重量チェック
    local success, canCarry = pcall(function()
        return exports.ox_inventory:CanCarryWeight(src, 0) -- まず基本的な重量チェック
    end)
    
    if not success then
        -- ox_inventory が利用できない場合はqb-coreの重量システムを使用
        local currentWeight = Player.Functions.GetTotalWeight()
        local maxWeight = QBCore.Config.Player.MaxWeight
        local additionalWeight = 0
        
        for _, reward in pairs(rewards) do
            if reward.item ~= 'money' and QBCore.Shared.Items[reward.item] then
                local itemWeight = QBCore.Shared.Items[reward.item].weight or 0
                additionalWeight = additionalWeight + (itemWeight * reward.amount)
            end
        end
        
        local totalWeight = currentWeight + additionalWeight
        return totalWeight <= maxWeight, currentWeight, additionalWeight, maxWeight
    end
    
    -- ox_inventory での詳細な重量チェック
    local additionalWeight = 0
    for _, reward in pairs(rewards) do
        if reward.item ~= 'money' then
            local itemData = exports.ox_inventory:Items(reward.item)
            if itemData then
                local itemWeight = itemData.weight or 0
                additionalWeight = additionalWeight + (itemWeight * reward.amount)
            end
        end
    end
    
    local canCarryWeight = exports.ox_inventory:CanCarryWeight(src, additionalWeight)
    
    if Config.Debug then
        print('[ng-dailybonus] ox_inventory 重量チェック: 追加重量=' .. additionalWeight .. ', 運搬可能=' .. tostring(canCarryWeight))
    end
    
    return canCarryWeight, 0, additionalWeight, 0
end

-- Discord API経由でユーザーのロールを取得（Promise風の実装）
local function GetDiscordRoles(source, callback)
    local discordId = nil
    
    -- プレイヤーのDiscord IDを取得
    for _, id in pairs(GetPlayerIdentifiers(source)) do
        if string.find(id, "discord:") then
            discordId = string.gsub(id, "discord:", "")
            break
        end
    end
    
    if not discordId or not Config.Discord.enabled then
        if Config.Debug then
            print('[ng-dailybonus] Discord ID が見つからないか、Discord連携が無効です')
        end
        if callback then callback({}) end
        return {}
    end
    
    if Config.Debug then
        print('[ng-dailybonus] Discord ID: ' .. discordId)
    end
    
    -- キャッシュから取得を試行
    if DiscordRoleCache and DiscordRoleCache[discordId] then
        local cachedData = DiscordRoleCache[discordId]
        local currentTime = os.time()
        if (currentTime - cachedData.timestamp) < 300 then -- 5分間有効
            if Config.Debug then
                print('[ng-dailybonus] キャッシュからロール情報を取得: ' .. json.encode(cachedData.roles))
            end
            if callback then callback(cachedData.roles) end
            return cachedData.roles
        else
            -- キャッシュが古い場合は削除
            DiscordRoleCache[discordId] = nil
        end
    end
    
    -- Discord APIを使用してユーザーの情報を取得
    local guildId = Config.Discord.guildId
    local botToken = Config.Discord.botToken
    
    if not guildId or guildId == 'YOUR_DISCORD_GUILD_ID' or not botToken or botToken == 'YOUR_BOT_TOKEN' then
        if Config.Debug then
            print('[ng-dailybonus] Discord設定が正しく設定されていません')
        end
        if callback then callback({}) end
        return {}
    end
    
    -- Discord API URL
    local apiUrl = string.format('https://discord.com/api/v10/guilds/%s/members/%s', guildId, discordId)
    
    -- HTTP リクエストヘッダー
    local headers = {
        ['Authorization'] = 'Bot ' .. botToken,
        ['Content-Type'] = 'application/json'
    }
    
    -- HTTP リクエストを送信
    PerformHttpRequest(apiUrl, function(statusCode, response, headers)
        if statusCode == 200 then
            local success, data = pcall(json.decode, response)
            if success and data.roles then
                if Config.Debug then
                    print('[ng-dailybonus] Discord APIからロール取得成功: ' .. json.encode(data.roles))
                end
                -- ロール情報をキャッシュ
                if not DiscordRoleCache then
                    DiscordRoleCache = {}
                end
                DiscordRoleCache[discordId] = {
                    roles = data.roles,
                    timestamp = os.time()
                }
                if callback then callback(data.roles) end
                return data.roles
            else
                if Config.Debug then
                    print('[ng-dailybonus] Discord APIレスポンスの解析に失敗')
                end
            end
        else
            if Config.Debug then
                print('[ng-dailybonus] Discord API エラー: ' .. statusCode .. ' - ' .. tostring(response))
            end
        end
        if callback then callback({}) end
        return {}
    end, 'GET', '', headers)
end

-- 同期的にDiscordロールを取得する関数
local function GetDiscordRolesSync(source)
    local discordId = nil
    
    -- プレイヤーのDiscord IDを取得
    for _, id in pairs(GetPlayerIdentifiers(source)) do
        if string.find(id, "discord:") then
            discordId = string.gsub(id, "discord:", "")
            break
        end
    end
    
    if not discordId or not Config.Discord.enabled then
        return {}
    end
    
    -- キャッシュから取得
    if DiscordRoleCache and DiscordRoleCache[discordId] then
        local cachedData = DiscordRoleCache[discordId]
        local currentTime = os.time()
        if (currentTime - cachedData.timestamp) < 300 then -- 5分間有効
            if Config.Debug then
                print('[ng-dailybonus] 同期的にキャッシュからロール取得: ' .. json.encode(cachedData.roles))
            end
            return cachedData.roles
        end
    end
    
    return {}
end

-- プレイヤーが特定のロールを持っているかチェック
local function HasDiscordRole(source, roleId)
    if not Config.Discord.enabled then
        if Config.Debug then
            print('[ng-dailybonus] Discord連携が無効のため、ロールチェックをスキップ')
        end
        return false
    end
    
    local userRoles = GetDiscordRolesSync(source)
    
    if not userRoles or #userRoles == 0 then
        if Config.Debug then
            print('[ng-dailybonus] ユーザーのロール情報が取得できませんでした（キャッシュなし）')
        end
        return false
    end
    
    for _, userRole in pairs(userRoles) do
        if tostring(userRole) == tostring(roleId) then
            if Config.Debug then
                print('[ng-dailybonus] ロール ' .. roleId .. ' を所持しています')
            end
            return true
        end
    end
    
    if Config.Debug then
        print('[ng-dailybonus] ロール ' .. roleId .. ' を所持していません')
        print('[ng-dailybonus] 所持ロール: ' .. json.encode(userRoles))
    end
    
    return false
end

-- クールダウンチェック
local function CheckCooldown(citizenid, bonusType)
    local result = MySQL.Sync.fetchAll('SELECT UNIX_TIMESTAMP(last_claimed) as timestamp FROM ng_dailybonus WHERE citizenid = ? AND bonus_type = ?', {
        citizenid, bonusType
    })
    
    if #result == 0 then
        return true -- 初回なので受け取り可能
    end
    
    local lastClaimedTimestamp = result[1].timestamp
    local currentTime = os.time()
    
    if not lastClaimedTimestamp then
        if Config.Debug then
            print('[ng-dailybonus] タイムスタンプが取得できませんでした')
        end
        return true -- タイムスタンプが取得できない場合は受け取り可能とする
    end
    
    -- 数値として扱う（UNIX_TIMESTAMP関数を使用）
    local lastClaimedTime = tonumber(lastClaimedTimestamp)
    if not lastClaimedTime then
        if Config.Debug then
            print('[ng-dailybonus] タイムスタンプの変換に失敗: ' .. tostring(lastClaimedTimestamp))
        end
        return true
    end
    
    local cooldownTime = 24 * 60 * 60 -- 24時間（秒）
    local timeDiff = currentTime - lastClaimedTime
    
    if Config.Debug then
        print('[ng-dailybonus] クールダウンチェック: citizenid=' .. citizenid .. ', bonusType=' .. bonusType)
        print('[ng-dailybonus] 現在時刻: ' .. currentTime .. ', 最終受け取り: ' .. lastClaimedTime .. ', 差分: ' .. timeDiff .. '秒')
        print('[ng-dailybonus] 受け取り可能: ' .. tostring(timeDiff >= cooldownTime))
    end
    
    return timeDiff >= cooldownTime
end

-- 残り時間を計算
local function GetRemainingTime(citizenid, bonusType)
    local result = MySQL.Sync.fetchAll('SELECT UNIX_TIMESTAMP(last_claimed) as timestamp FROM ng_dailybonus WHERE citizenid = ? AND bonus_type = ?', {
        citizenid, bonusType
    })
    
    if #result == 0 then
        return 0 -- 初回なので残り時間なし
    end
    
    local lastClaimedTimestamp = result[1].timestamp
    local currentTime = os.time()
    
    if not lastClaimedTimestamp then
        return 0 -- タイムスタンプが取得できない場合は残り時間なし
    end
    
    local lastClaimedTime = tonumber(lastClaimedTimestamp)
    if not lastClaimedTime then
        return 0 -- タイムスタンプの変換に失敗した場合は残り時間なし
    end
    
    local cooldownTime = 24 * 60 * 60 -- 24時間（秒）
    local remainingTime = cooldownTime - (currentTime - lastClaimedTime)
    
    return math.max(0, remainingTime)
end

-- 時間を読みやすい形式に変換
local function FormatTime(seconds)
    if seconds <= 0 then
        return "受け取り可能"
    end
    
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    
    if hours > 0 then
        return string.format("%d時間%d分", hours, minutes)
    else
        return string.format("%d分", minutes)
    end
end

-- 利用可能なボーナスを取得（非同期対応）
RegisterNetEvent('ng-dailybonus:server:getAvailableBonuses', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- まずDiscordロールを非同期で取得
    GetDiscordRoles(src, function(userRoles)
        local availableBonuses = {}
        
        -- 基本ボーナスをチェック
        if Config.BasicBonus.enabled then
            local canClaim = CheckCooldown(citizenid, 'basic')
            local remainingTime = GetRemainingTime(citizenid, 'basic')
            
            table.insert(availableBonuses, {
                id = 'basic',
                name = Config.BasicBonus.name,
                description = Config.BasicBonus.description,
                rewards = Config.BasicBonus.rewards,
                canClaim = canClaim,
                remainingTime = FormatTime(remainingTime),
                remainingSeconds = remainingTime
            })
        end
        
        -- ロール別ボーナスをチェック
        for i, roleBonus in pairs(Config.RoleBonuses) do
            -- プレイヤーが該当ロールを持っているかチェック
            local hasRole = false
            
            if userRoles and #userRoles > 0 then
                for _, userRole in pairs(userRoles) do
                    if tostring(userRole) == tostring(roleBonus.roleId) then
                        hasRole = true
                        break
                    end
                end
            end
            
            if hasRole then
                local bonusId = 'role_' .. i
                local canClaim = CheckCooldown(citizenid, bonusId)
                local remainingTime = GetRemainingTime(citizenid, bonusId)
                
                table.insert(availableBonuses, {
                    id = bonusId,
                    name = roleBonus.name,
                    description = roleBonus.description,
                    rewards = roleBonus.rewards,
                    canClaim = canClaim,
                    remainingTime = FormatTime(remainingTime),
                    remainingSeconds = remainingTime
                })
                
                if Config.Debug then
                    print('[ng-dailybonus] ロールボーナス追加: ' .. roleBonus.name .. ' (ロールID: ' .. roleBonus.roleId .. ')')
                end
            end
        end
        
        if Config.Debug then
            print('[ng-dailybonus] 利用可能ボーナス数: ' .. #availableBonuses)
        end
        
        TriggerClientEvent('ng-dailybonus:client:receiveAvailableBonuses', src, availableBonuses)
    end)
end)

-- ボーナス受け取り処理
RegisterNetEvent('ng-dailybonus:server:claimBonus', function(bonusId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local bonusConfig = nil
    
    -- ボーナス設定を取得
    if bonusId == 'basic' then
        bonusConfig = Config.BasicBonus
    elseif string.find(bonusId, 'role_') then
        local roleIndex = string.match(bonusId, 'role_(%d+)')
        if roleIndex then
            roleIndex = tonumber(roleIndex)
            if roleIndex and Config.RoleBonuses[roleIndex] then
                -- ロール権限を再確認
                local hasRole = HasDiscordRole(src, Config.RoleBonuses[roleIndex].roleId)
                if hasRole then
                    bonusConfig = Config.RoleBonuses[roleIndex]
                else
                    TriggerClientEvent('ox_lib:notify', src, {
                        title = Config.Notifications.error.title,
                        description = 'このボーナスを受け取る権限がありません',
                        type = Config.Notifications.error.type,
                        duration = Config.Notifications.error.duration
                    })
                    return
                end
            end
        end
    end
    
    if not bonusConfig then
        TriggerClientEvent('ox_lib:notify', src, {
            title = Config.Notifications.error.title,
            description = '無効なボーナスです',
            type = Config.Notifications.error.type,
            duration = Config.Notifications.error.duration
        })
        return
    end
    
    -- クールダウンチェック（再度確認）
    if not CheckCooldown(citizenid, bonusId) then
        local remainingTime = GetRemainingTime(citizenid, bonusId)
        TriggerClientEvent('ox_lib:notify', src, {
            title = Config.Notifications.cooldown.title,
            description = 'あと ' .. FormatTime(remainingTime) .. ' 待ってください',
            type = Config.Notifications.cooldown.type,
            duration = Config.Notifications.cooldown.duration
        })
        return
    end
    
    -- 重量チェック
    local canCarry, currentWeight, additionalWeight, maxWeight = CheckPlayerWeight(src, bonusConfig.rewards)
    if not canCarry then
        TriggerClientEvent('ox_lib:notify', src, {
            title = Config.Notifications.error.title,
            description = string.format('インベントリの容量が不足しています (現在: %.1fkg, 追加: %.1fkg, 最大: %.1fkg)', 
                currentWeight / 1000, additionalWeight / 1000, maxWeight / 1000),
            type = Config.Notifications.error.type,
            duration = Config.Notifications.error.duration
        })
        return
    end
    
    -- データベースに記録（アイテム付与前に記録してダブル受け取りを防ぐ）
    MySQL.Async.execute('INSERT INTO ng_dailybonus (citizenid, bonus_type, last_claimed) VALUES (?, ?, NOW()) ON DUPLICATE KEY UPDATE last_claimed = NOW()', {
        citizenid, bonusId
    }, function(result)
        if result then
            -- アイテムを付与
            local rewardText = {}
            for _, reward in pairs(bonusConfig.rewards) do
                if reward.item == 'money' then
                    Player.Functions.AddMoney('cash', reward.amount)
                    table.insert(rewardText, reward.label .. ' x' .. reward.amount)
                else
                    -- ox_inventory を使用してアイテムを追加
                    local success = exports.ox_inventory:AddItem(src, reward.item, reward.amount)
                    if success then
                        table.insert(rewardText, reward.label .. ' x' .. reward.amount)
                        if Config.Debug then
                            print('[ng-dailybonus] アイテム追加成功: ' .. reward.item .. ' x' .. reward.amount)
                        end
                    else
                        if Config.Debug then
                            print('[ng-dailybonus] アイテム追加失敗: ' .. reward.item .. ' x' .. reward.amount)
                        end
                    end
                end
            end
            
            -- 成功通知
            TriggerClientEvent('ox_lib:notify', src, {
                title = Config.Notifications.success.title,
                description = '受け取った報酬: ' .. table.concat(rewardText, ', '),
                type = Config.Notifications.success.type,
                duration = Config.Notifications.success.duration
            })
            
            if Config.Debug then
                print('[ng-dailybonus] ' .. GetPlayerName(src) .. ' がボーナス ' .. bonusId .. ' を受け取りました')
            end
        else
            TriggerClientEvent('ox_lib:notify', src, {
                title = Config.Notifications.error.title,
                description = 'データベースエラーが発生しました',
                type = Config.Notifications.error.type,
                duration = Config.Notifications.error.duration
            })
        end
    end)
end)

-- プレイヤーがサーバーに参加した時の処理
RegisterNetEvent('QBCore:Server:PlayerLoaded', function()
    local src = source
    if Config.Debug then
        print('[ng-dailybonus] プレイヤー ' .. GetPlayerName(src) .. ' が参加しました')
    end
end)

-- デバッグ用コマンド（管理者のみ）
QBCore.Commands.Add('resetdailybonus', 'デイリーボーナスをリセット（管理者のみ）', {}, false, function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    -- 管理者権限チェック
    if not QBCore.Functions.HasPermission(source, 'admin') then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'エラー',
            description = '権限がありません',
            type = 'error',
            duration = 3000
        })
        return
    end
    
    local citizenid = Player.PlayerData.citizenid
    MySQL.Async.execute('DELETE FROM ng_dailybonus WHERE citizenid = ?', {citizenid}, function()
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'デイリーボーナス',
            description = 'ボーナスをリセットしました',
            type = 'success',
            duration = 3000
        })
    end)
end, 'admin')

-- Discord ロールキャッシュをクリアするコマンド（管理者のみ）
QBCore.Commands.Add('cleardiscordcache', 'Discordロールキャッシュをクリア（管理者のみ）', {}, false, function(source)
    if not QBCore.Functions.HasPermission(source, 'admin') then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'エラー',
            description = '権限がありません',
            type = 'error',
            duration = 3000
        })
        return
    end
    
    DiscordRoleCache = {}
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'デイリーボーナス',
        description = 'Discordロールキャッシュをクリアしました',
        type = 'success',
        duration = 3000
    })
    
    if Config.Debug then
        print('[ng-dailybonus] 管理者 ' .. source .. ' がDiscordロールキャッシュをクリアしました')
    end
end, 'admin')

-- ===== EXPORTS =====

-- 外部スクリプトから利用可能なボーナス情報を取得
exports('GetAvailableBonuses', function(source, callback)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then 
        if callback then callback({}) end
        return {}
    end
    
    local citizenid = Player.PlayerData.citizenid
    
    GetDiscordRoles(source, function(userRoles)
        local availableBonuses = {}
        
        -- 基本ボーナスをチェック
        if Config.BasicBonus.enabled then
            local canClaim = CheckCooldown(citizenid, 'basic')
            local remainingTime = GetRemainingTime(citizenid, 'basic')
            
            table.insert(availableBonuses, {
                id = 'basic',
                name = Config.BasicBonus.name,
                description = Config.BasicBonus.description,
                rewards = Config.BasicBonus.rewards,
                canClaim = canClaim,
                remainingTime = FormatTime(remainingTime),
                remainingSeconds = remainingTime
            })
        end
        
        -- ロール別ボーナスをチェック
        for i, roleBonus in pairs(Config.RoleBonuses) do
            local hasRole = false
            if userRoles and #userRoles > 0 then
                for _, userRole in pairs(userRoles) do
                    if tostring(userRole) == tostring(roleBonus.roleId) then
                        hasRole = true
                        break
                    end
                end
            end
            
            if hasRole then
                local bonusId = 'role_' .. i
                local canClaim = CheckCooldown(citizenid, bonusId)
                local remainingTime = GetRemainingTime(citizenid, bonusId)
                
                table.insert(availableBonuses, {
                    id = bonusId,
                    name = roleBonus.name,
                    description = roleBonus.description,
                    rewards = roleBonus.rewards,
                    canClaim = canClaim,
                    remainingTime = FormatTime(remainingTime),
                    remainingSeconds = remainingTime
                })
            end
        end
        
        if callback then callback(availableBonuses) end
    end)
end)

-- 外部スクリプトからボーナスを受け取らせる
exports('ClaimBonus', function(source, bonusId)
    TriggerEvent('ng-dailybonus:server:claimBonus', source, bonusId)
end)

-- 外部スクリプトからクールダウンをチェック
exports('CheckCooldown', function(source, bonusType)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local citizenid = Player.PlayerData.citizenid
    return CheckCooldown(citizenid, bonusType)
end)

-- 外部スクリプトから残り時間を取得
exports('GetRemainingTime', function(source, bonusType)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return 0 end
    
    local citizenid = Player.PlayerData.citizenid
    return GetRemainingTime(citizenid, bonusType)
end)

-- 外部スクリプトからDiscordロールをチェック
exports('HasDiscordRole', function(source, roleId)
    return HasDiscordRole(source, roleId)
end)

-- 外部スクリプトからメニューを開く（サーバー側）
exports('OpenDailyBonusMenu', function(source)
    TriggerEvent('ng-dailybonus:server:getAvailableBonuses', source)
end)

-- ===== EVENTS =====

-- 外部スクリプトからメニューを開くイベント
RegisterNetEvent('ng-dailybonus:server:openMenu', function()
    local src = source
    TriggerEvent('ng-dailybonus:server:getAvailableBonuses', src)
end)

-- 外部スクリプトから特定のボーナス情報を取得するイベント
RegisterNetEvent('ng-dailybonus:server:getBonusInfo', function(bonusId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local bonusInfo = {
        id = bonusId,
        canClaim = CheckCooldown(citizenid, bonusId),
        remainingTime = GetRemainingTime(citizenid, bonusId),
        remainingTimeFormatted = FormatTime(GetRemainingTime(citizenid, bonusId))
    }
    
    TriggerClientEvent('ng-dailybonus:client:receiveBonusInfo', src, bonusInfo)
end)