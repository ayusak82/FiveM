-- メインサーバーロジック

-- データベーステーブルの初期化
local function InitializeDatabase()
    print('^3[ng-discord-job-sync]^7 Initializing database tables...')

    -- player_discordテーブルを作成（複数キャラクター対応: UNIQUE制約を削除）
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `player_discord` (
            `citizenid` varchar(50) NOT NULL,
            `discord_id` varchar(50) NOT NULL,
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`citizenid`),
            KEY `discord_id` (`discord_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]], {})

    -- player_job_rolesテーブルを作成（付与されているロールを記録）
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `player_job_roles` (
            `citizenid` varchar(50) NOT NULL,
            `role_id` varchar(50) NOT NULL,
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`citizenid`, `role_id`),
            KEY `citizenid` (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]], {})

    print('^2[ng-discord-job-sync]^7 Database tables initialized successfully')
end

-- デバッグ出力関数
local function DebugPrint(...)
    if not Config.Debug then
        return
    end
    local args = { ... }
    local message = ''
    for i = 1, #args do
        message = message .. tostring(args[i]) .. ' '
    end
    print('^3[DEBUG]^7 ' .. message)
end

local function ErrorPrint(...)
    local args = { ... }
    local message = ''
    for i = 1, #args do
        message = message .. tostring(args[i]) .. ' '
    end
    print('^1[ERROR]^7 ' .. message)
end

local function SuccessPrint(...)
    if not Config.Debug then
        return
    end
    local args = { ... }
    local message = ''
    for i = 1, #args do
        message = message .. tostring(args[i]) .. ' '
    end
    print('^2[SUCCESS]^7 ' .. message)
end

local function WarnPrint(...)
    if not Config.Debug then
        return
    end
    local args = { ... }
    local message = ''
    for i = 1, #args do
        message = message .. tostring(args[i]) .. ' '
    end
    print('^5[WARNING]^7 ' .. message)
end

-- 現在のジョブロール状態を保存（citizenid -> {job, roleId}）
local playerJobRoles = {}

-- テーブルの要素数を取得するヘルパー関数
local function TableCount(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- player_discordテーブルからcitizenidとdiscord IDのマッピングを取得
local function GetPlayerDiscordMapping()
    DebugPrint('Fetching player Discord mapping from database')

    local result = MySQL.query.await('SELECT `citizenid`, `discord_id` FROM `player_discord`', {})

    if not result then
        ErrorPrint('Failed to fetch Discord mapping from database')
        return {}
    end

    local mapping = {}
    for _, row in ipairs(result) do
        mapping[row.citizenid] = row.discord_id
        DebugPrint('Mapped citizenid', row.citizenid, 'to Discord ID', row.discord_id)
    end

    DebugPrint('Successfully mapped', TableCount(mapping), 'players with Discord')
    return mapping
end

-- データベースから保存されているロール情報を取得
local function LoadPlayerJobRolesFromDB(citizenid)
    local result = MySQL.query.await('SELECT `role_id` FROM `player_job_roles` WHERE `citizenid` = ?', { citizenid })

    if not result then
        return {}
    end

    local roleIds = {}
    for _, row in ipairs(result) do
        roleIds[row.role_id] = true
    end

    DebugPrint('Loaded', TableCount(roleIds), 'saved roles for', citizenid, 'from database')
    return roleIds
end

-- データベースにロール情報を保存
local function SavePlayerJobRolesToDB(citizenid, roleIds)
    -- 既存のロールをすべて削除
    MySQL.query.await('DELETE FROM `player_job_roles` WHERE `citizenid` = ?', { citizenid })

    -- 新しいロールを保存
    if TableCount(roleIds) > 0 then
        for roleId, _ in pairs(roleIds) do
            MySQL.insert.await('INSERT INTO `player_job_roles` (`citizenid`, `role_id`) VALUES (?, ?)',
                { citizenid, roleId })
        end
        DebugPrint('Saved', TableCount(roleIds), 'roles for', citizenid, 'to database')
    else
        DebugPrint('No roles to save for', citizenid)
    end
end

-- オンラインプレイヤーのDiscordマッピングを更新
local function UpdatePlayerDiscordMapping(source, citizenid)
    local identifiers = GetPlayerIdentifiers(source)
    if not identifiers then
        return
    end

    local discordId = nil
    for _, identifier in pairs(identifiers) do
        if string.find(identifier, 'discord:') then
            discordId = string.gsub(identifier, 'discord:', '')
            break
        end
    end

    if not discordId then
        WarnPrint('No Discord identifier found for player:', citizenid)
        return
    end

    -- player_discordテーブルに保存または更新
    MySQL.insert.await(
        'INSERT INTO `player_discord` (`citizenid`, `discord_id`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `discord_id` = VALUES(`discord_id`)',
        { citizenid, discordId })

    DebugPrint('Updated Discord mapping for', citizenid, ':', discordId)
    return discordId
end

-- ng_multijobsテーブルからすべてのジョブデータを取得
local function GetAllJobsFromDatabase()
    DebugPrint('Fetching all jobs from ng_multijobs table')

    local result = MySQL.query.await('SELECT `citizenid`, `job`, `grade` FROM `ng_multijobs`', {})

    if not result then
        ErrorPrint('Failed to fetch jobs from database')
        return {}
    end

    DebugPrint('Retrieved', #result, 'job entries from database')
    return result
end

-- ジョブに対応するロールIDを取得
local function GetRoleIdForJob(job, grade)
    DebugPrint('GetRoleIdForJob called - Job:', job, 'Grade:', grade)
    
    if not Config.JobRoles[job] then
        DebugPrint('No role mapping found for job:', job)
        return nil
    end
    
    -- グレードチェック
    if Config.MinGradeForRole[job] then
        if grade < Config.MinGradeForRole[job] then
            DebugPrint('Grade', grade, 'is below minimum', Config.MinGradeForRole[job], 'for job', job)
            return nil
        end
    end
    
    local roleId = Config.JobRoles[job]
    DebugPrint('Role ID for job', job, ':', roleId)
    return roleId
end

-- プレイヤーの複数ジョブロールを同期（複数キャラクター対応）
local function SyncPlayerJobRoles(citizenid, discordId, jobs)
    if not discordId then
        WarnPrint('No Discord ID for citizenid:', citizenid)
        return
    end

    if not jobs or #jobs == 0 then
        WarnPrint('No jobs for citizenid:', citizenid)
        return
    end

    DebugPrint('Syncing', #jobs, 'job roles for', citizenid, 'Discord:', discordId)

    -- 新しいロールIDのセットを作成
    local newRoleIds = {}
    for i, jobData in ipairs(jobs) do
        DebugPrint('Processing job', i, '/', #jobs, '- Job:', jobData.job, 'Grade:', jobData.grade)
        local roleId = GetRoleIdForJob(jobData.job, jobData.grade)
        if roleId then
            newRoleIds[roleId] = true
            DebugPrint('Added role', roleId, 'for job', jobData.job)
        else
            WarnPrint('No role ID returned for job:', jobData.job, 'grade:', jobData.grade)
        end
    end
    
    DebugPrint('Total new role IDs collected:', TableCount(newRoleIds))

    -- 古いロールデータを取得（データベースから）
    local oldRoleIds = LoadPlayerJobRolesFromDB(citizenid)
    
    DebugPrint('Old roles for', citizenid, ':', TableCount(oldRoleIds))
    for roleId, _ in pairs(oldRoleIds) do
        DebugPrint('  - Old role:', roleId)
    end
    
    DebugPrint('New roles for', citizenid, ':', TableCount(newRoleIds))
    for roleId, _ in pairs(newRoleIds) do
        DebugPrint('  - New role:', roleId)
    end

    -- 削除すべきロールを特定して削除
    local removedCount = 0
    for oldRoleId, _ in pairs(oldRoleIds) do
        if not newRoleIds[oldRoleId] then
            DebugPrint('Removing old role', oldRoleId, 'from', citizenid)
            RemoveDiscordRole(discordId, oldRoleId)
            removedCount = removedCount + 1
        else
            DebugPrint('Keeping role', oldRoleId, 'for', citizenid)
        end
    end
    
    if removedCount == 0 and TableCount(oldRoleIds) > 0 then
        DebugPrint('No roles removed for', citizenid)
    end

    -- 追加すべきロールを特定して追加（変更があった場合のみ）
    local addedCount = 0
    for newRoleId, _ in pairs(newRoleIds) do
        if not oldRoleIds[newRoleId] then
            DebugPrint('Adding new role', newRoleId, 'to', citizenid)
            AddDiscordRole(discordId, newRoleId)
            addedCount = addedCount + 1
        else
            DebugPrint('Role', newRoleId, 'already exists for', citizenid, '(skipping)')
        end
    end
    
    if addedCount == 0 and TableCount(newRoleIds) > 0 then
        DebugPrint('No new roles to add for', citizenid)
    end

    -- 新しいロールデータを保存（メモリとデータベース）
    playerJobRoles[citizenid] = newRoleIds
    SavePlayerJobRolesToDB(citizenid, newRoleIds)
    DebugPrint('Updated role data for', citizenid, '- Total roles:', TableCount(newRoleIds))
end

-- すべてのプレイヤーのジョブロールを同期（複数キャラクター対応）
local function SyncAllPlayerJobRoles()
    DebugPrint('Starting job role synchronization (multi-character support)')

    -- オンラインプレイヤーのDiscordマッピングを更新
    DebugPrint('Updating Discord mapping for online players during sync')
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local source = tonumber(playerId)
        local Player = exports['qb-core']:GetPlayer(source)

        if Player and Player.PlayerData and Player.PlayerData.citizenid then
            local citizenid = Player.PlayerData.citizenid
            UpdatePlayerDiscordMapping(source, citizenid)
        end
    end

    -- Discord IDマッピングを取得
    local discordMapping = GetPlayerDiscordMapping()
    if not discordMapping or TableCount(discordMapping) == 0 then
        ErrorPrint('No Discord mapping found')
        return
    end

    -- データベースからすべてのジョブを取得
    local allJobs = GetAllJobsFromDatabase()
    if not allJobs or #allJobs == 0 then
        WarnPrint('No jobs found in database')
        return
    end

    -- citizenidごとにジョブをグループ化
    local jobsByCitizenId = {}
    for _, jobData in ipairs(allJobs) do
        local citizenid = jobData.citizenid
        if not jobsByCitizenId[citizenid] then
            jobsByCitizenId[citizenid] = {}
        end
        table.insert(jobsByCitizenId[citizenid], jobData)
    end

    -- Discord IDごとにすべてのキャラクターのジョブを集約（複数キャラクター対応）
    local jobsByDiscordId = {}
    for citizenid, discordId in pairs(discordMapping) do
        if not jobsByDiscordId[discordId] then
            jobsByDiscordId[discordId] = {}
        end
        local jobs = jobsByCitizenId[citizenid] or {}
        for _, job in ipairs(jobs) do
            table.insert(jobsByDiscordId[discordId], job)
        end
    end

    DebugPrint('Players with Discord:', TableCount(discordMapping))
    DebugPrint('Unique Discord IDs:', TableCount(jobsByDiscordId))
    DebugPrint('Unique citizenids with jobs:', TableCount(jobsByCitizenId))

    -- Discord IDごとに統合されたロールを同期（バッチ処理）
    local syncCount = 0
    local totalRoles = 0
    local batchCount = 0

    for discordId, allCharacterJobs in pairs(jobsByDiscordId) do
        if #allCharacterJobs > 0 then
            -- このDiscord IDの全キャラクターのジョブから必要なロールを収集
            local combinedRoleIds = {}
            for _, jobData in ipairs(allCharacterJobs) do
                local roleId = GetRoleIdForJob(jobData.job, jobData.grade)
                if roleId then
                    combinedRoleIds[roleId] = true
                end
            end

            DebugPrint('Discord ID', discordId, 'has', #allCharacterJobs, 'total jobs across all characters, resulting in', TableCount(combinedRoleIds), 'unique roles')

            -- このDiscord IDに紐付く最初のcitizenidを取得（ロール管理用）
            local primaryCitizenid = nil
            for citizenid, mappedDiscordId in pairs(discordMapping) do
                if mappedDiscordId == discordId then
                    primaryCitizenid = citizenid
                    break
                end
            end

            if primaryCitizenid then
                -- 古いロールを取得
                local oldRoleIds = LoadPlayerJobRolesFromDB(primaryCitizenid)

                -- 削除すべきロールを削除
                for oldRoleId, _ in pairs(oldRoleIds) do
                    if not combinedRoleIds[oldRoleId] then
                        DebugPrint('Removing old role', oldRoleId, 'from Discord ID', discordId)
                        RemoveDiscordRole(discordId, oldRoleId)
                    end
                end

                -- 追加すべきロールを追加
                for newRoleId, _ in pairs(combinedRoleIds) do
                    if not oldRoleIds[newRoleId] then
                        DebugPrint('Adding new role', newRoleId, 'to Discord ID', discordId)
                        AddDiscordRole(discordId, newRoleId)
                    end
                end

                -- ロールデータを保存
                playerJobRoles[primaryCitizenid] = combinedRoleIds
                SavePlayerJobRolesToDB(primaryCitizenid, combinedRoleIds)

                syncCount = syncCount + 1
                totalRoles = totalRoles + TableCount(combinedRoleIds)
            end
        end

        -- バッチ処理: 指定人数ごとに待機
        batchCount = batchCount + 1
        if batchCount >= Config.BatchSize then
            DebugPrint('Batch limit reached (', batchCount, 'Discord IDs), waiting', Config.BatchDelay, 'ms')
            Citizen.Wait(Config.BatchDelay)
            batchCount = 0
        end
    end

    SuccessPrint('Synchronized', syncCount, 'Discord IDs with', totalRoles, 'total unique roles (multi-character support)')
end

-- プレイヤーがロードされた時の処理（個別同期）
RegisterNetEvent('QBCore:Server:PlayerLoaded', function()
    local source = source
    DebugPrint('Player loaded:', source)

    -- 少し待ってから同期（データが完全にロードされるまで）
    Citizen.SetTimeout(5000, function()
        local Player = exports['qb-core']:GetPlayer(source)
        if not Player then
            return
        end

        local citizenid = Player.PlayerData.citizenid
        if not citizenid then
            return
        end

        -- Discordマッピングを更新
        local discordId = UpdatePlayerDiscordMapping(source, citizenid)
        if not discordId then
            return
        end

        -- すべてのジョブデータを取得
        local jobs = MySQL.query.await('SELECT `job`, `grade` FROM `ng_multijobs` WHERE `citizenid` = ?',
            { citizenid })

        if jobs and #jobs > 0 then
            DebugPrint('Syncing newly loaded player:', citizenid, 'with', #jobs, 'jobs')
            SyncPlayerJobRoles(citizenid, discordId, jobs)
        end
    end)
end)

-- 起動時にオンラインプレイヤーのDiscordマッピングを更新
local function UpdateAllOnlinePlayersMapping()
    DebugPrint('Updating Discord mapping for all online players')

    local players = GetPlayers()
    local updateCount = 0

    for _, playerId in ipairs(players) do
        local source = tonumber(playerId)
        local Player = exports['qb-core']:GetPlayer(source)

        if Player and Player.PlayerData and Player.PlayerData.citizenid then
            local citizenid = Player.PlayerData.citizenid
            local discordId = UpdatePlayerDiscordMapping(source, citizenid)
            if discordId then
                updateCount = updateCount + 1
            end
        end
    end

    SuccessPrint('Updated Discord mapping for', updateCount, 'online players')
end

-- スクリプト起動時の初期化
Citizen.CreateThread(function()
    -- データベーステーブルを初期化
    InitializeDatabase()

    -- 起動時に少し待つ
    Citizen.Wait(10000)

    -- オンラインプレイヤーのマッピングを更新
    UpdateAllOnlinePlayersMapping()

    -- 少し待ってから最初の同期を実行
    Citizen.Wait(5000)

    SuccessPrint('Job role sync system started - Interval:', Config.SyncInterval, 'ms')

    while true do
        SyncAllPlayerJobRoles()
        Citizen.Wait(Config.SyncInterval)
    end
end)

-- 手動同期コマンド（管理者用）
RegisterCommand('syncjobroles', function(source, args)
    if source == 0 or IsPlayerAceAllowed(source, 'command.admin') then
        DebugPrint('Manual sync triggered by:', source)
        SyncAllPlayerJobRoles()
        if source ~= 0 then
            TriggerClientEvent('ox_lib:notify', source, {
                type = 'success',
                description = 'Job roles synchronized'
            })
        else
            print('^2[SUCCESS]^7 Job roles synchronized')
        end
    else
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'No permission'
        })
    end
end)

print('^2[ng-discord-job-sync]^7 Script loaded successfully')