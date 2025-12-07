local QBCore = exports['qb-core']:GetCoreObject()

-- Database initialization
local function CreateJobsTable()
    return MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `ng_multijobs` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `citizenid` varchar(50) NOT NULL,
            `job` varchar(50) NOT NULL,
            `grade` int(11) NOT NULL DEFAULT 0,
            `is_duty` tinyint(1) NOT NULL DEFAULT 0,
            PRIMARY KEY (`id`),
            UNIQUE KEY `unique_citizen_job` (`citizenid`, `job`),
            KEY `citizenid` (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end

-- Initialize database on server start
CreateThread(function()
    Config.Debug_Print('Initializing ng-multijob...')
    local success = pcall(CreateJobsTable)
    if not success then
        Config.Debug_Print('Failed to create database table')
        return
    end
    Config.Debug_Print('Database initialization completed')
end)

-- Helper Functions
local function GetPlayerByCitizenId(citizenid)
    local players = QBCore.Functions.GetQBPlayers()
    for _, player in pairs(players) do
        if player.PlayerData.citizenid == citizenid then
            return player
        end
    end
    return nil
end

local function IsPlayerAdmin(source)
    if IsPlayerAceAllowed(source, 'command') then
        return true
    end
    return false
end

local function IsPlayerJobBoss(source, job)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local playerJob = Player.PlayerData.job
    return playerJob.name == job and playerJob.isboss
end

-- Get player jobs
local function GetPlayerJobs(citizenid)
    if not citizenid then return {} end

    local result = MySQL.query.await('SELECT * FROM ng_multijobs WHERE citizenid = ?', {citizenid})
    return result or {}
end

-- Get job label
local function GetJobLabel(job)
    if not job or not QBCore.Shared.Jobs[job] then return job end
    return QBCore.Shared.Jobs[job].label or job
end

-- Get grade label
local function GetGradeLabel(job, grade)
    if not job or not QBCore.Shared.Jobs[job] then return 'Unknown Grade' end
    
    local gradeData = QBCore.Shared.Jobs[job].grades[tostring(grade)]
    if not gradeData then return 'Grade ' .. grade end
    
    return gradeData.name or ('Grade ' .. grade)
end

-- Check if can add job
local function CanAddJob(citizenid, job)
    if not citizenid or not job then return false, 'invalid_input' end

    local jobs = GetPlayerJobs(citizenid)
    
    -- Check if already has job
    for _, jobData in ipairs(jobs) do
        if jobData.job == job then
            return false, 'already_has_job'
        end
    end
    
    -- Check whitelist job
    local hasWhitelistJob = false
    for _, jobData in ipairs(jobs) do
        if Config.WhitelistJobs[jobData.job] then
            hasWhitelistJob = true
            break
        end
    end
    
    if Config.WhitelistJobs[job] and hasWhitelistJob then
        return false, 'already_has_whitelist_job'
    end
    
    -- Count jobs (excluding civilian job)
    local jobCount = 0
    for _, jobData in ipairs(jobs) do
        if jobData.job ~= Config.DefaultJob then
            jobCount = jobCount + 1
        end
    end
    
    -- Check max jobs
    if jobCount >= Config.MaxJobs then
        return false, 'max_jobs_reached'
    end
    
    return true, nil
end

-- Add job
local function AddJob(citizenid, job, grade)
    if not citizenid or not job then return false, 'invalid_input' end
    
    local canAdd, reason = CanAddJob(citizenid, job)
    if not canAdd then
        return false, reason
    end
    
    local success = MySQL.insert.await('INSERT INTO ng_multijobs (citizenid, job, grade, is_duty) VALUES (?, ?, ?, ?)', {
        citizenid, job, grade, 0
    })
    
    return success ~= false, success == false and 'database_error' or nil
end

-- Switch Job
local function SwitchJob(source, citizenid, job)
    if not source or not citizenid or not job then return false end

    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end

    local jobs = GetPlayerJobs(citizenid)
    local jobData = nil

    for _, data in ipairs(jobs) do
        if data.job == job then
            jobData = data
            break
        end
    end

    if not jobData then return false end

    MySQL.update.await('UPDATE ng_multijobs SET is_duty = 0 WHERE citizenid = ?', {citizenid})
    MySQL.update.await('UPDATE ng_multijobs SET is_duty = 1 WHERE citizenid = ? AND job = ?', {
        citizenid, job
    })

    Player.Functions.SetJob(job, jobData.grade)
    
    return true
end

-- Remove job
local function RemoveJob(citizenid, job)
    if not citizenid or not job then return false, 'invalid_input' end
    if job == Config.DefaultJob then
        return false, 'cannot_remove_default_job'
    end
    
    local Player = GetPlayerByCitizenId(citizenid)
    if Player and Player.PlayerData.job.name == job then
        -- If player is currently in the job being removed, switch to default job
        SwitchJob(Player.PlayerData.source, citizenid, Config.DefaultJob)
    end
    
    local affected = MySQL.update.await('DELETE FROM ng_multijobs WHERE citizenid = ? AND job = ?', {
        citizenid, job
    })
    
    return affected > 0, affected == 0 and 'job_not_found' or nil
end

-- Admin Functions
lib.callback.register('ng-multijob:server:GetOnlinePlayers', function(source)
    if not IsPlayerAdmin(source) then return {} end

    local players = {}
    for _, player in pairs(QBCore.Functions.GetQBPlayers()) do
        players[#players + 1] = {
            source = player.PlayerData.source,
            citizenid = player.PlayerData.citizenid,
            name = ('%s %s'):format(
                player.PlayerData.charinfo.firstname,
                player.PlayerData.charinfo.lastname
            ),
            job = player.PlayerData.job.name,
            grade = player.PlayerData.job.grade.level
        }
    end
    return players
end)

-- Add this callback after other callback registrations
lib.callback.register('ng-multijob:server:GetPlayerJobs', function(source, identifier)
    if not IsPlayerAdmin(source) then return nil end
    
    local targetPlayer = nil
    local targetCitizenId = nil
    
    -- Check if input is server ID
    if tonumber(identifier) then
        targetPlayer = QBCore.Functions.GetPlayer(tonumber(identifier))
        if targetPlayer then
            targetCitizenId = targetPlayer.PlayerData.citizenid
        end
    else
        -- Treat as citizenid
        targetCitizenId = identifier
        targetPlayer = GetPlayerByCitizenId(targetCitizenId)
    end
    
    if not targetCitizenId then
        return nil
    end
    
    local jobs = GetPlayerJobs(targetCitizenId)
    local playerName = targetPlayer and 
        ('%s %s'):format(targetPlayer.PlayerData.charinfo.firstname, targetPlayer.PlayerData.charinfo.lastname) or 
        targetCitizenId
    
    return {
        jobs = jobs,
        citizenid = targetCitizenId,
        name = playerName,
        currentJob = targetPlayer and targetPlayer.PlayerData.job or nil
    }
end)

-- Events
RegisterNetEvent('ng-multijob:server:AdminAddJob', function(targetCitizenId, job, grade)
    local src = source
    if not IsPlayerAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = '失敗',
            description = Config.Notifications.error.no_permission,
            type = 'error'
        })
        return
    end

    local success, reason = AddJob(targetCitizenId, job, grade)
    if not success then
        TriggerClientEvent('ox_lib:notify', src, {
            title = '失敗',
            description = Config.Notifications.error[reason] or 'エラーが発生しました',
            type = 'error'
        })
        return
    end

    -- Get target player if online
    local targetPlayer = GetPlayerByCitizenId(targetCitizenId)
    local targetName = targetPlayer and 
        ('%s %s'):format(targetPlayer.PlayerData.charinfo.firstname, targetPlayer.PlayerData.charinfo.lastname) or 
        targetCitizenId

    -- Notify admin
    TriggerClientEvent('ox_lib:notify', src, {
        title = '成功',
        description = string.format(Config.Notifications.success.job_added_other, targetName),
        type = 'success'
    })

    -- Update target's job list if online
    if targetPlayer then
        local jobs = GetPlayerJobs(targetCitizenId)
        TriggerClientEvent('ng-multijob:client:UpdateJobs', targetPlayer.PlayerData.source, jobs)
    end
end)

RegisterNetEvent('ng-multijob:server:AdminRemoveJob', function(targetCitizenId, job)
    local src = source
    if not IsPlayerAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = '失敗',
            description = Config.Notifications.error.no_permission,
            type = 'error'
        })
        return
    end

    local success, reason = RemoveJob(targetCitizenId, job)
    if not success then
        TriggerClientEvent('ox_lib:notify', src, {
            title = '失敗',
            description = Config.Notifications.error[reason] or 'エラーが発生しました',
            type = 'error'
        })
        return
    end

    -- Get target player if online
    local targetPlayer = GetPlayerByCitizenId(targetCitizenId)
    local targetName = targetPlayer and 
        ('%s %s'):format(targetPlayer.PlayerData.charinfo.firstname, targetPlayer.PlayerData.charinfo.lastname) or 
        targetCitizenId

    -- Notify admin
    TriggerClientEvent('ox_lib:notify', src, {
        title = '成功',
        description = string.format(Config.Notifications.success.job_removed_other, targetName),
        type = 'success'
    })

    -- Update target's job list if online
    if targetPlayer then
        local jobs = GetPlayerJobs(targetCitizenId)
        TriggerClientEvent('ng-multijob:client:UpdateJobs', targetPlayer.PlayerData.source, jobs)
    end
end)

-- Boss Functions
RegisterNetEvent('ng-multijob:server:BossAddJob', function(targetIdentifier, grade)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Check if player is boss
    if not IsPlayerJobBoss(src, Player.PlayerData.job.name) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = '失敗',
            description = Config.Notifications.error.not_boss,
            type = 'error'
        })
        return
    end
    
    local job = Player.PlayerData.job.name
    local targetPlayer = nil
    local targetCitizenId = nil
    
    -- Check if input is server ID
    if tonumber(targetIdentifier) then
        targetPlayer = QBCore.Functions.GetPlayer(tonumber(targetIdentifier))
        if targetPlayer then
            targetCitizenId = targetPlayer.PlayerData.citizenid
        end
    else
        -- Treat as citizenid
        targetCitizenId = targetIdentifier
        targetPlayer = GetPlayerByCitizenId(targetCitizenId)
    end
    
    if not targetCitizenId then
        TriggerClientEvent('ox_lib:notify', src, {
            title = '失敗',
            description = Config.Notifications.error.player_not_found,
            type = 'error'
        })
        return
    end
    
    local success, reason = AddJob(targetCitizenId, job, grade)
    if not success then
        TriggerClientEvent('ox_lib:notify', src, {
            title = '失敗',
            description = Config.Notifications.error[reason] or 'エラーが発生しました',
            type = 'error'
        })
        return
    end
    
    -- Get target name
    local targetName = targetPlayer and 
        ('%s %s'):format(targetPlayer.PlayerData.charinfo.firstname, targetPlayer.PlayerData.charinfo.lastname) or 
        targetCitizenId
    
    -- Notify boss
    TriggerClientEvent('ox_lib:notify', src, {
        title = '成功',
        description = string.format(Config.Notifications.success.job_added_by_boss, targetName),
        type = 'success'
    })
    
    -- Update target's job list if online
    if targetPlayer then
        local jobs = GetPlayerJobs(targetCitizenId)
        TriggerClientEvent('ng-multijob:client:UpdateJobs', targetPlayer.PlayerData.source, jobs)
    end
end)

RegisterNetEvent('ng-multijob:server:CheckAdmin', function()
    local src = source
    local isAdmin = IsPlayerAdmin(src)
    TriggerClientEvent('ng-multijob:client:SetAdmin', src, isAdmin)
end)

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function(Player)
    -- プレイヤーがキャラクター選択を完了しているか確認
    Wait(1000) -- キャラクター選択処理の完了を待機
    
    local player = QBCore.Functions.GetPlayer(source)
    if not player then
        return -- キャラクター選択が完了していない場合は処理を終了
    end
    
    local citizenid = player.PlayerData.citizenid
    local jobs = GetPlayerJobs(citizenid)
    
    if #jobs == 0 then
        AddJob(citizenid, Config.DefaultJob, Config.DefaultGrade)
        jobs = GetPlayerJobs(citizenid)
    end
    
    TriggerClientEvent('ng-multijob:client:UpdateJobs', player.PlayerData.source, jobs)
end)

RegisterNetEvent('ng-multijob:server:GetJobs', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local jobs = GetPlayerJobs(Player.PlayerData.citizenid)
    if #jobs == 0 then
        local success = AddJob(Player.PlayerData.citizenid, Config.DefaultJob, Config.DefaultGrade)
        if success then
            jobs = GetPlayerJobs(Player.PlayerData.citizenid)
        end
    end
    
    TriggerClientEvent('ng-multijob:client:UpdateJobs', src, jobs)
end)

RegisterNetEvent('ng-multijob:server:AddJob', function(job, grade)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local success, reason = AddJob(Player.PlayerData.citizenid, job, grade)
    if not success then
        TriggerClientEvent('ox_lib:notify', src, {
            title = '失敗',
            description = Config.Notifications.error[reason] or 'エラーが発生しました',
            type = 'error'
        })
        return
    end
    
    local jobs = GetPlayerJobs(Player.PlayerData.citizenid)
    TriggerClientEvent('ng-multijob:client:UpdateJobs', src, jobs)
    TriggerClientEvent('ox_lib:notify', src, {
        title = '成功',
        description = Config.Notifications.success.job_added,
        type = 'success'
    })
end)

RegisterNetEvent('ng-multijob:server:RemoveJob', function(job)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local success, reason = RemoveJob(Player.PlayerData.citizenid, job)
    if not success then
        TriggerClientEvent('ox_lib:notify', src, {
            title = '失敗',
            description = Config.Notifications.error[reason] or 'エラーが発生しました',
            type = 'error'
        })
        return
    end
    
    local jobs = GetPlayerJobs(Player.PlayerData.citizenid)
    TriggerClientEvent('ng-multijob:client:UpdateJobs', src, jobs)
    TriggerClientEvent('ox_lib:notify', src, {
        title = '成功',
        description = Config.Notifications.success.job_removed,
        type = 'success'
    })
end)

RegisterNetEvent('ng-multijob:server:SwitchJob', function(job)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local success = SwitchJob(src, Player.PlayerData.citizenid, job)
    if success then
        local jobs = GetPlayerJobs(Player.PlayerData.citizenid)
        TriggerClientEvent('ng-multijob:client:UpdateJobs', src, jobs)
        TriggerClientEvent('ox_lib:notify', src, {
            title = '成功',
            description = Config.Notifications.success.job_switched,
            type = 'success'
        })
    end
end)

-- Add this with other server events
RegisterNetEvent('ng-multijob:server:AdminSwitchJob', function(targetCitizenId, job)
    local src = source
    if not IsPlayerAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = '失敗',
            description = Config.Notifications.error.no_permission,
            type = 'error'
        })
        return
    end

    -- Get target player
    local targetPlayer = GetPlayerByCitizenId(targetCitizenId)
    if not targetPlayer then
        TriggerClientEvent('ox_lib:notify', src, {
            title = '失敗',
            description = Config.Notifications.error.player_not_found,
            type = 'error'
        })
        return
    end

    -- Switch job
    local success = SwitchJob(targetPlayer.PlayerData.source, targetCitizenId, job)
    if success then
        -- Get target name
        local targetName = ('%s %s'):format(
            targetPlayer.PlayerData.charinfo.firstname,
            targetPlayer.PlayerData.charinfo.lastname
        )

        local jobLabel = QBCore.Shared.Jobs[job] and QBCore.Shared.Jobs[job].label or job

        -- Notify admin
        TriggerClientEvent('ox_lib:notify', src, {
            title = '成功',
            description = string.format('"%s"の職業を"%s"に変更しました', targetName, jobLabel),
            type = 'success'
        })

        -- Notify target
        TriggerClientEvent('ox_lib:notify', targetPlayer.PlayerData.source, {
            title = '通知',
            description = string.format('管理者によって職業が"%s"に変更されました', jobLabel),
            type = 'info'
        })
    end
end)

RegisterNetEvent('ng-multijob:server:BossFireEmployee', function(targetCitizenId, job)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- ボス権限の確認
    if not IsPlayerJobBoss(src, job) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = '失敗',
            description = Config.Notifications.error.not_boss,
            type = 'error'
        })
        return
    end
    
    -- 対象プレイヤーの取得
    local targetPlayer = GetPlayerByCitizenId(targetCitizenId)
    
    -- 職業の削除
    local success, reason = RemoveJob(targetCitizenId, job)
    if not success then
        TriggerClientEvent('ox_lib:notify', src, {
            title = '失敗',
            description = Config.Notifications.error[reason] or 'エラーが発生しました',
            type = 'error'
        })
        return
    end
    
    -- 解雇した側への通知
    local targetName = targetPlayer and 
        ('%s %s'):format(targetPlayer.PlayerData.charinfo.firstname, targetPlayer.PlayerData.charinfo.lastname) or 
        targetCitizenId
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = '成功',
        description = string.format('%sを解雇しました', targetName),
        type = 'success'
    })
    
    -- 解雇された側への通知
    if targetPlayer then
        local jobs = GetPlayerJobs(targetCitizenId)
        TriggerClientEvent('ng-multijob:client:UpdateJobs', targetPlayer.PlayerData.source, jobs)
        
        -- もし現在その職業に就いている場合は、デフォルト職業に切り替え
        if targetPlayer.PlayerData.job.name == job then
            SwitchJob(targetPlayer.PlayerData.source, targetCitizenId, Config.DefaultJob)
        end
        
        TriggerClientEvent('ox_lib:notify', targetPlayer.PlayerData.source, {
            title = '通知',
            description = string.format('%sから解雇されました', GetJobLabel(job)),
            type = 'error'
        })
    end
end)

-- Exports
exports('GetPlayerJobs', GetPlayerJobs)
exports('AddJob', AddJob)
exports('RemoveJob', RemoveJob)
exports('SwitchJob', SwitchJob)