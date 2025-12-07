local QBCore = exports['qb-core']:GetCoreObject()

-- アクティブセッション管理（複数ジョブ対応）
local activeSessions = {} -- [citizenid][job] = sessionData
local isServerReady = false

-- 権限チェック関数（サーバーサイドで実装）
local function HasUIPermission(source)
    local Player = QBCore.Functions.GetPlayer(source)
    return Player ~= nil and Player.PlayerData.job ~= nil
end

local function HasManagementPermission(source, job)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player or not Player.PlayerData.job then return false end
    
    local playerJob = Player.PlayerData.job.name
    local playerJobData = Player.PlayerData.job
    
    -- 複数ジョブ対応：プレイヤーが複数のジョブを持っている場合もチェック
    -- メインジョブでのアクセス
    if playerJob == job and playerJobData.isboss == true then
        return true
    end
    
    -- セカンダリジョブでのアクセス（QB-Coreの拡張機能を使用している場合）
    if Player.PlayerData.jobs then
        for _, jobData in pairs(Player.PlayerData.jobs) do
            if jobData.name == job and jobData.isboss == true then
                return true
            end
        end
    end
    
    return false
end

-- プレイヤーの現在のジョブリストを取得
local function GetPlayerJobs(Player)
    local jobs = {}
    
    -- メインジョブ
    if Player.PlayerData.job and Config.IsJobEnabled(Player.PlayerData.job.name) then
        jobs[Player.PlayerData.job.name] = {
            name = Player.PlayerData.job.name,
            grade = Player.PlayerData.job.grade.name,
            onduty = Player.PlayerData.job.onduty,
            isboss = Player.PlayerData.job.isboss or false
        }
    end
    
    -- セカンダリジョブ（QB-Coreの拡張機能）
    if Player.PlayerData.jobs then
        for jobName, jobData in pairs(Player.PlayerData.jobs) do
            if Config.IsJobEnabled(jobName) then
                jobs[jobName] = {
                    name = jobName,
                    grade = jobData.grade and jobData.grade.name or '0',
                    onduty = jobData.onduty or false,
                    isboss = jobData.isboss or false
                }
            end
        end
    end
    
    return jobs
end

-- 初期化
CreateThread(function()
    Wait(5000) -- QB-Coreの初期化を待つ
    InitializeDatabase()
    
    -- スクリプト再起動時のセッション復旧処理
    Wait(2000) -- データベース初期化を待つ
    RestoreActiveSessions()
    
    StartAutoSaveTimer()
    isServerReady = true
    
    if Config.Debug then
        print('^2[ng-attendance]^7 サーバーが開始されました（複数ジョブ対応版）')
    end
end)

-- データベース初期化（複数ジョブ対応構造）
function InitializeDatabase()
    -- 日別出退勤サマリーテーブル（1日1ジョブ1レコード）
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `ng_attendance_daily` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `citizenid` varchar(50) NOT NULL,
            `job` varchar(50) NOT NULL,
            `job_grade` varchar(50) NOT NULL,
            `date` date NOT NULL,
            `first_clock_in` datetime DEFAULT NULL,
            `last_clock_out` datetime DEFAULT NULL,
            `total_minutes` int(11) DEFAULT 0,
            `session_count` int(11) DEFAULT 0,
            `is_active` tinyint(1) DEFAULT 0,
            `last_update` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `unique_daily_job` (`citizenid`, `date`, `job`),
            KEY `citizenid` (`citizenid`),
            KEY `job` (`job`),
            KEY `date` (`date`),
            KEY `is_active` (`is_active`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]], {}, function(success)
        if success then
            if Config.Debug then
                print('^2[ng-attendance]^7 日別サマリーテーブルを作成しました（複数ジョブ対応）')
            end
        else
            print('^1[ng-attendance]^7 日別サマリーテーブルの作成に失敗しました')
        end
    end)

    -- 月別サマリーテーブル（1ヶ月1ジョブ1レコード）
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `ng_attendance_monthly` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `citizenid` varchar(50) NOT NULL,
            `job` varchar(50) NOT NULL,
            `year` int(4) NOT NULL,
            `month` int(2) NOT NULL,
            `total_minutes` int(11) DEFAULT 0,
            `total_days` int(11) DEFAULT 0,
            `avg_daily_minutes` decimal(8,2) DEFAULT 0,
            `last_update` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `unique_monthly_job` (`citizenid`, `year`, `month`, `job`),
            KEY `citizenid` (`citizenid`),
            KEY `job` (`job`),
            KEY `year_month` (`year`, `month`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]], {})

    -- アクティブセッションテーブル（複数ジョブ対応）
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `ng_attendance_sessions` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `citizenid` varchar(50) NOT NULL,
            `job` varchar(50) NOT NULL,
            `job_grade` varchar(50) NOT NULL,
            `clock_in` datetime NOT NULL,
            `daily_minutes` int(11) DEFAULT 0,
            `session_start` datetime NOT NULL,
            `server_id` varchar(50) DEFAULT 'default',
            `last_ping` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `unique_session` (`citizenid`, `job`),
            KEY `citizenid` (`citizenid`),
            KEY `job` (`job`),
            KEY `server_id` (`server_id`),
            KEY `last_ping` (`last_ping`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]], {})

    if Config.Debug then
        print('^2[ng-attendance]^7 複数ジョブ対応データベース構造を初期化しました')
    end
end

-- スクリプト再起動時のアクティブセッション復旧（複数ジョブ対応）
function RestoreActiveSessions()
    if Config.Debug then
        print('^3[ng-attendance]^7 アクティブセッションの復旧を開始します（複数ジョブ対応）...')
    end
    
    -- 古いセッション（30分以上更新されていない）を自動終了
    MySQL.Async.execute([[
        DELETE FROM ng_attendance_sessions 
        WHERE last_ping < DATE_SUB(NOW(), INTERVAL 30 MINUTE)
    ]], {}, function(affectedRows)
        if Config.Debug and affectedRows > 0 then
            print('^3[ng-attendance]^7 古いセッション ' .. affectedRows .. '件を削除しました')
        end
    end)
    
    Wait(1000)
    
    -- 現在のサーバーIDを生成（一意性を保証）
    local serverId = 'srv_' .. math.random(10000, 99999) .. '_' .. os.time()
    
    -- 既存のアクティブセッションを取得
    MySQL.Async.fetchAll('SELECT * FROM ng_attendance_sessions', {}, function(sessions)
        if #sessions == 0 then
            if Config.Debug then
                print('^2[ng-attendance]^7 復旧するセッションはありません')
            end
            return
        end
        
        local restoredCount = 0
        local autoEndedCount = 0
        
        for _, session in ipairs(sessions) do
            local Player = QBCore.Functions.GetPlayerByCitizenId(session.citizenid)
            
            if Player then
                -- プレイヤーがオンラインの場合：セッションを復旧
                local src = Player.PlayerData.source
                local playerJobs = GetPlayerJobs(Player)
                
                -- 該当するジョブが勤務中か確認
                if playerJobs[session.job] and playerJobs[session.job].onduty then
                    -- メモリ内セッションを復旧
                    if not activeSessions[session.citizenid] then
                        activeSessions[session.citizenid] = {}
                    end
                    
                    activeSessions[session.citizenid][session.job] = {
                        job = session.job,
                        jobGrade = session.job_grade,
                        clockIn = session.clock_in,
                        sessionStart = session.session_start,
                        dailyMinutes = session.daily_minutes,
                        source = src
                    }
                    
                    -- サーバーIDを更新
                    MySQL.Async.execute('UPDATE ng_attendance_sessions SET server_id = ?, last_ping = NOW() WHERE citizenid = ? AND job = ?', {
                        serverId, session.citizenid, session.job
                    })
                    
                    restoredCount = restoredCount + 1
                    
                    if Config.Debug then
                        print('^2[ng-attendance]^7 セッション復旧: ' .. session.citizenid .. ' (' .. session.job .. ')')
                    end
                    
                    -- クライアントに復旧通知
                    TriggerClientEvent('ng-attendance:client:sessionRestored', src, {
                        job = session.job,
                        clockIn = session.clock_in
                    })
                else
                    -- ジョブが変更されているか勤務中でない場合：セッションを終了
                    ForceEndWorkSession(session.citizenid, session.job, session, 'job_change')
                    autoEndedCount = autoEndedCount + 1
                end
            else
                -- プレイヤーがオフラインの場合：セッションを終了
                ForceEndWorkSession(session.citizenid, session.job, session, 'offline')
                autoEndedCount = autoEndedCount + 1
            end
        end
        
        if Config.Debug then
            print('^2[ng-attendance]^7 セッション復旧完了: 復旧 ' .. restoredCount .. '件, 自動終了 ' .. autoEndedCount .. '件')
        end
    end)
end

-- 強制的にセッションを終了（復旧時やクリーンアップ用）
function ForceEndWorkSession(citizenid, job, sessionData, reason)
    local clockOut = os.date('%Y-%m-%d %H:%M:%S')
    local today = os.date('%Y-%m-%d')
    local sessionMinutes = CalculateWorkMinutes(sessionData.session_start, clockOut)
    local newTotalMinutes = sessionData.daily_minutes + sessionMinutes
    
    -- 日別記録を更新
    MySQL.Async.execute([[
        UPDATE ng_attendance_daily 
        SET last_clock_out = ?, total_minutes = ?, is_active = 0, last_update = NOW()
        WHERE citizenid = ? AND date = ? AND job = ?
    ]], {clockOut, newTotalMinutes, citizenid, today, job})
    
    -- 月別サマリーを更新
    UpdateMonthlySummary(citizenid, job, newTotalMinutes)
    
    -- アクティブセッションを削除
    MySQL.Async.execute('DELETE FROM ng_attendance_sessions WHERE citizenid = ? AND job = ?', {citizenid, job})
    
    -- メモリからも削除
    if activeSessions[citizenid] then
        activeSessions[citizenid][job] = nil
        if next(activeSessions[citizenid]) == nil then
            activeSessions[citizenid] = nil
        end
    end
    
    if Config.Debug then
        print('^3[ng-attendance]^7 強制終了: ' .. citizenid .. ' (' .. job .. ') - 理由: ' .. reason .. ' (' .. sessionMinutes .. '分)')
    end
end

-- プレイヤー参加時の処理
RegisterNetEvent('QBCore:Server:PlayerLoaded', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- サーバー準備完了を待つ
    while not isServerReady do
        Wait(1000)
    end

    -- 既存のアクティブセッションをチェック
    CheckExistingSession(Player.PlayerData.citizenid, src)
end)

-- プレイヤー退出時の処理（自動退勤）
RegisterNetEvent('QBCore:Server:OnPlayerUnload', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- プレイヤーがログアウトした時点で全ジョブの自動退勤
    local citizenid = Player.PlayerData.citizenid
    if activeSessions[citizenid] then
        for job, sessionData in pairs(activeSessions[citizenid]) do
            EndWorkSession(citizenid, job, true)
        end
        
        if Config.Debug then
            print('^3[ng-attendance]^7 プレイヤーログアウトによる自動退勤: ' .. citizenid)
        end
    end
end)

-- プレイヤー切断時の処理（追加の安全策）
AddEventHandler('playerDropped', function(reason)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid
    if activeSessions[citizenid] then
        for job, sessionData in pairs(activeSessions[citizenid]) do
            EndWorkSession(citizenid, job, true)
        end
        
        if Config.Debug then
            print('^3[ng-attendance]^7 プレイヤー切断による自動退勤: ' .. citizenid .. ' (理由: ' .. reason .. ')')
        end
    end
end)

-- ジョブ変更時の処理（複数ジョブ対応）
RegisterNetEvent('QBCore:Server:OnJobUpdate', function(source, job)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid
    
    -- 新しいジョブリストを取得
    local newJobs = GetPlayerJobs(Player)
    
    -- 現在のアクティブセッションをチェック
    if activeSessions[citizenid] then
        for jobName, sessionData in pairs(activeSessions[citizenid]) do
            -- 新しいジョブリストにないか、勤務中でない場合はセッションを終了
            if not newJobs[jobName] or not newJobs[jobName].onduty then
                EndWorkSession(citizenid, jobName, false)
            end
        end
    end

    -- 新しいジョブで勤務開始が必要かチェック
    for jobName, jobData in pairs(newJobs) do
        if jobData.onduty then
            -- 既にセッションがない場合のみ開始
            if not activeSessions[citizenid] or not activeSessions[citizenid][jobName] then
                Wait(1000) -- ジョブ変更処理を待つ
                StartWorkSession(citizenid, jobName, jobData.grade, source)
            end
        end
    end
end)

-- 勤務開始（複数ジョブ対応版）
function StartWorkSession(citizenid, job, jobGrade, source)
    if activeSessions[citizenid] and activeSessions[citizenid][job] then
        if Config.Debug then
            print('^3[ng-attendance]^7 ' .. citizenid .. ' の ' .. job .. ' はすでに勤務中です')
        end
        return false
    end

    local now = os.date('%Y-%m-%d %H:%M:%S')
    local today = os.date('%Y-%m-%d')
    
    -- 今日のこのジョブの勤務記録を取得または作成
    MySQL.Async.fetchAll('SELECT * FROM ng_attendance_daily WHERE citizenid = ? AND date = ? AND job = ?', {
        citizenid, today, job
    }, function(result)
        local dailyRecord = result[1]
        local isFirstSession = not dailyRecord
        
        if isFirstSession then
            -- 今日初回の勤務開始
            MySQL.Async.execute([[
                INSERT INTO ng_attendance_daily (citizenid, job, job_grade, date, first_clock_in, session_count, is_active)
                VALUES (?, ?, ?, ?, ?, 1, 1)
            ]], {citizenid, job, jobGrade, today, now})
        else
            -- 追加セッション
            MySQL.Async.execute([[
                UPDATE ng_attendance_daily 
                SET session_count = session_count + 1, is_active = 1, last_update = NOW()
                WHERE citizenid = ? AND date = ? AND job = ?
            ]], {citizenid, today, job})
        end
        
        -- アクティブセッションを作成
        local serverId = 'srv_' .. math.random(10000, 99999)
        MySQL.Async.execute([[
            INSERT INTO ng_attendance_sessions (citizenid, job, job_grade, clock_in, session_start, daily_minutes, server_id)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE 
            job_grade = VALUES(job_grade), 
            clock_in = VALUES(clock_in), session_start = VALUES(session_start),
            daily_minutes = VALUES(daily_minutes), server_id = VALUES(server_id), last_ping = NOW()
        ]], {citizenid, job, jobGrade, now, now, dailyRecord and dailyRecord.total_minutes or 0, serverId})
        
        -- メモリ内セッション管理
        if not activeSessions[citizenid] then
            activeSessions[citizenid] = {}
        end
        
        activeSessions[citizenid][job] = {
            job = job,
            jobGrade = jobGrade,
            clockIn = now,
            sessionStart = now,
            dailyMinutes = dailyRecord and dailyRecord.total_minutes or 0,
            source = source
        }
        
        if Config.Debug then
            print('^2[ng-attendance]^7 ' .. citizenid .. ' が ' .. job .. ' で勤務を開始しました')
        end

        -- クライアントに通知
        if source then
            TriggerClientEvent('ng-attendance:client:workStarted', source, {
                job = job,
                clockIn = now
            })
        end
    end)

    return true
end

-- 勤務終了（複数ジョブ対応版）
function EndWorkSession(citizenid, job, isDisconnect)
    if not activeSessions[citizenid] or not activeSessions[citizenid][job] then
        return false
    end
    
    local session = activeSessions[citizenid][job]
    local clockOut = os.date('%Y-%m-%d %H:%M:%S')
    local today = os.date('%Y-%m-%d')
    local sessionMinutes = CalculateWorkMinutes(session.sessionStart, clockOut)
    local newTotalMinutes = session.dailyMinutes + sessionMinutes
    
    -- 日別記録を更新
    MySQL.Async.execute([[
        UPDATE ng_attendance_daily 
        SET last_clock_out = ?, total_minutes = ?, is_active = 0, last_update = NOW()
        WHERE citizenid = ? AND date = ? AND job = ?
    ]], {clockOut, newTotalMinutes, citizenid, today, job})
    
    -- 月別サマリーを更新
    UpdateMonthlySummary(citizenid, job, newTotalMinutes)
    
    -- アクティブセッションを削除
    MySQL.Async.execute('DELETE FROM ng_attendance_sessions WHERE citizenid = ? AND job = ?', {citizenid, job})
    
    -- クライアントに通知
    if session.source and not isDisconnect then
        TriggerClientEvent('ng-attendance:client:workEnded', session.source, {
            job = job,
            clockOut = clockOut,
            totalMinutes = sessionMinutes,
            dailyTotal = newTotalMinutes
        })
    end

    -- メモリから削除
    activeSessions[citizenid][job] = nil
    if next(activeSessions[citizenid]) == nil then
        activeSessions[citizenid] = nil
    end
    
    if Config.Debug then
        local disconnectText = isDisconnect and ' (ログアウト)' or ''
        print('^2[ng-attendance]^7 ' .. citizenid .. 'の ' .. job .. ' 勤務終了' .. disconnectText .. ' - セッション: ' .. sessionMinutes .. '分, 日別合計: ' .. newTotalMinutes .. '分')
    end
    
    return true
end

-- 月別サマリー更新（複数ジョブ対応）
function UpdateMonthlySummary(citizenid, job, dailyTotalMinutes)
    local year = tonumber(os.date('%Y'))
    local month = tonumber(os.date('%m'))
    
    MySQL.Async.execute([[
        INSERT INTO ng_attendance_monthly (citizenid, job, year, month, total_minutes, total_days, avg_daily_minutes)
        SELECT ?, ?, ?, ?, 
               SUM(total_minutes) as total_minutes,
               COUNT(*) as total_days,
               AVG(total_minutes) as avg_daily_minutes
        FROM ng_attendance_daily 
        WHERE citizenid = ? AND job = ? AND YEAR(date) = ? AND MONTH(date) = ?
        ON DUPLICATE KEY UPDATE 
        total_minutes = VALUES(total_minutes),
        total_days = VALUES(total_days),
        avg_daily_minutes = VALUES(avg_daily_minutes),
        last_update = NOW()
    ]], {citizenid, job, year, month, citizenid, job, year, month})
end

-- 既存セッションのチェック（複数ジョブ対応）
function CheckExistingSession(citizenid, source)
    MySQL.Async.fetchAll('SELECT * FROM ng_attendance_sessions WHERE citizenid = ?', {citizenid}, function(result)
        if #result == 0 then return end
        
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return end
        
        local playerJobs = GetPlayerJobs(Player)
        
        for _, session in ipairs(result) do
            -- プレイヤーの現在のジョブ状態を確認
            if playerJobs[session.job] and playerJobs[session.job].onduty then
                if not activeSessions[citizenid] then
                    activeSessions[citizenid] = {}
                end
                
                activeSessions[citizenid][session.job] = {
                    job = session.job,
                    jobGrade = session.job_grade,
                    clockIn = session.clock_in,
                    sessionStart = session.session_start,
                    dailyMinutes = session.daily_minutes,
                    source = source
                }
                
                -- セッションの最終更新を記録
                MySQL.Async.execute('UPDATE ng_attendance_sessions SET last_ping = NOW() WHERE citizenid = ? AND job = ?', {citizenid, session.job})
                
                if Config.Debug then
                    print('^3[ng-attendance]^7 ' .. citizenid .. ' の ' .. session.job .. ' セッションを復元しました')
                end
                
                -- クライアントに復旧通知
                TriggerClientEvent('ng-attendance:client:sessionRestored', source, {
                    job = session.job,
                    clockIn = session.clock_in
                })
            else
                -- ジョブ状態が合わない場合はセッションを終了
                ForceEndWorkSession(citizenid, session.job, session, 'job_mismatch')
            end
        end
    end)
end

-- 勤務時間計算
function CalculateWorkMinutes(clockIn, clockOut)
    local function parseDateTime(dateTimeStr)
        local year, month, day, hour, min, sec = dateTimeStr:match('(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)')
        return os.time({
            year = tonumber(year),
            month = tonumber(month),
            day = tonumber(day),
            hour = tonumber(hour),
            min = tonumber(min),
            sec = tonumber(sec)
        })
    end
    
    local startTime = parseDateTime(clockIn)
    local endTime = parseDateTime(clockOut)
    
    return math.floor((endTime - startTime) / 60)
end

-- 自動保存タイマー（複数ジョブ対応版）
function StartAutoSaveTimer()
    CreateThread(function()
        while true do
            Wait(Config.SaveInterval)
            
            -- アクティブセッションの進行状況を更新
            for citizenid, jobSessions in pairs(activeSessions) do
                for job, session in pairs(jobSessions) do
                    local currentMinutes = CalculateWorkMinutes(session.sessionStart, os.date('%Y-%m-%d %H:%M:%S'))
                    local newTotal = session.dailyMinutes + currentMinutes
                    
                    -- データベースを定期的に更新（負荷分散）
                    MySQL.Async.execute([[
                        UPDATE ng_attendance_sessions 
                        SET daily_minutes = ?, last_ping = NOW() 
                        WHERE citizenid = ? AND job = ?
                    ]], {session.dailyMinutes, citizenid, job})
                    
                    -- 日別記録も更新
                    MySQL.Async.execute([[
                        UPDATE ng_attendance_daily 
                        SET total_minutes = ?, last_update = NOW()
                        WHERE citizenid = ? AND date = ? AND job = ? AND is_active = 1
                    ]], {newTotal, citizenid, os.date('%Y-%m-%d'), job})
                end
            end
            
            if Config.Debug and next(activeSessions) then
                local sessionCount = 0
                for citizenid, jobSessions in pairs(activeSessions) do
                    for job, session in pairs(jobSessions) do
                        sessionCount = sessionCount + 1
                    end
                end
                print('^2[ng-attendance]^7 アクティブセッションを更新しました (' .. sessionCount .. '件)')
            end
        end
    end)
end

-- 定期的なクリーンアップ（1時間ごと）
CreateThread(function()
    while true do
        Wait(3600000) -- 1時間
        
        -- 古いセッションを自動終了
        MySQL.Async.fetchAll([[
            SELECT * FROM ng_attendance_sessions 
            WHERE last_ping < DATE_SUB(NOW(), INTERVAL 1 HOUR)
        ]], {}, function(oldSessions)
            for _, session in ipairs(oldSessions) do
                ForceEndWorkSession(session.citizenid, session.job, session, 'timeout')
            end
            
            if #oldSessions > 0 and Config.Debug then
                print('^3[ng-attendance]^7 タイムアウトにより ' .. #oldSessions .. '件のセッションを終了しました')
            end
        end)
    end
end)

-- クライアントイベント: 勤務状況取得（複数ジョブ対応）
RegisterNetEvent('ng-attendance:server:getWorkStatus', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- 権限チェック
    if not HasUIPermission(src) then
        TriggerClientEvent('ng-attendance:client:showNotification', src, Config.GetText('no_permission'), 'error')
        return
    end

    local citizenid = Player.PlayerData.citizenid
    local activeSessions_player = activeSessions[citizenid] or {}
    
    -- 複数ジョブの勤務状況を返す
    local workStatus = {
        activeJobs = {},
        totalActiveSessions = 0,
        currentJob = Player.PlayerData.job.name,
        currentGrade = Player.PlayerData.job.grade.name,
        onDuty = Player.PlayerData.job.onduty,
        isBoss = Player.PlayerData.job.isboss or false,
        availableJobs = GetPlayerJobs(Player)
    }
    
    for job, session in pairs(activeSessions_player) do
        workStatus.activeJobs[job] = {
            job = session.job,
            jobGrade = session.jobGrade,
            clockIn = session.clockIn,
            isWorking = true
        }
        workStatus.totalActiveSessions = workStatus.totalActiveSessions + 1
    end
    
    TriggerClientEvent('ng-attendance:client:receiveWorkStatus', src, workStatus)
end)

-- クライアントイベント: 管理画面データ取得（月ごと総出勤時間対応版）
-- クライアントイベント: 管理画面データ取得（月ごと総出勤時間対応版）
RegisterNetEvent('ng-attendance:server:getManagementData', function(job)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- jobが"all"の場合は全従業員を取得（管理者権限が必要）
    local isRequestingAll = job == "all"
    
    -- 権限チェック（通常の権限チェックまたは管理者権限）
    if not isRequestingAll and not HasManagementPermission(src, job) then
        TriggerClientEvent('ng-attendance:client:showNotification', src, Config.GetText('no_permission'), 'error')
        return
    elseif isRequestingAll then
        -- 全従業員を見る場合は、いずれかのジョブでボス権限を持っているか確認
        local hasAnyBossPermission = false
        local playerJobs = GetPlayerJobs(Player)
        for jobName, jobData in pairs(playerJobs) do
            if jobData.isboss and Config.IsJobEnabled(jobName) then
                hasAnyBossPermission = true
                break
            end
        end
        
        if not hasAnyBossPermission then
            TriggerClientEvent('ng-attendance:client:showNotification', src, Config.GetText('no_permission'), 'error')
            return
        end
    end

    -- 月別サマリーから効率的に取得（過去数ヶ月のデータを含む）
    local currentYear = tonumber(os.date('%Y'))
    local currentMonth = tonumber(os.date('%m'))
    
    -- 過去何ヶ月分のデータを取得するか（設定可能）
    local monthsToShow = 3 -- デフォルトは3ヶ月
    
    -- 取得する月のリストを作成
    local monthsList = {}
    local tempYear = currentYear
    local tempMonth = currentMonth
    
    for i = 0, monthsToShow - 1 do
        table.insert(monthsList, {year = tempYear, month = tempMonth})
        tempMonth = tempMonth - 1
        if tempMonth < 1 then
            tempMonth = 12
            tempYear = tempYear - 1
        end
    end
    
    -- SQLクエリを動的に構築
    local query
    local params = {}
    
    if isRequestingAll then
        -- 全従業員の場合（複数月のデータを結合）
        local whereConditions = {}
        for _, monthData in ipairs(monthsList) do
            table.insert(whereConditions, "(m.year = ? AND m.month = ?)")
            table.insert(params, monthData.year)
            table.insert(params, monthData.month)
        end
        
        query = [[
            SELECT DISTINCT
                m.citizenid,
                m.job,
                m.year,
                m.month,
                m.total_minutes,
                m.total_days,
                d.date as last_worked
            FROM ng_attendance_monthly m
            LEFT JOIN (
                SELECT citizenid, job, MAX(date) as date
                FROM ng_attendance_daily 
                GROUP BY citizenid, job
            ) d ON m.citizenid = d.citizenid AND m.job = d.job
            WHERE ]] .. table.concat(whereConditions, " OR ") .. [[
            ORDER BY m.citizenid, m.year DESC, m.month DESC
        ]]
    else
        -- 特定のジョブの場合（複数月のデータを結合）
        local whereConditions = {}
        table.insert(params, job) -- for the subquery
        table.insert(params, job) -- for the main query
        
        for _, monthData in ipairs(monthsList) do
            table.insert(whereConditions, "(m.year = ? AND m.month = ?)")
            table.insert(params, monthData.year)
            table.insert(params, monthData.month)
        end
        
        query = [[
            SELECT 
                m.citizenid,
                m.job,
                m.year,
                m.month,
                m.total_minutes,
                m.total_days,
                d.date as last_worked
            FROM ng_attendance_monthly m
            LEFT JOIN (
                SELECT citizenid, MAX(date) as date
                FROM ng_attendance_daily 
                WHERE job = ?
                GROUP BY citizenid
            ) d ON m.citizenid = d.citizenid
            WHERE m.job = ? AND (]] .. table.concat(whereConditions, " OR ") .. [[)
            ORDER BY m.citizenid, m.year DESC, m.month DESC
        ]]
    end
    
    MySQL.Async.fetchAll(query, params, function(records)
        local employees = {}
        local processedCount = 0
        local citizenProcessed = {} -- 重複を避けるため
        
        if #records == 0 then
            TriggerClientEvent('ng-attendance:client:receiveManagementData', src, employees)
            return
        end
        
        -- レコードをcitizenidごとにグループ化
        local groupedRecords = {}
        for _, record in ipairs(records) do
            if not groupedRecords[record.citizenid] then
                groupedRecords[record.citizenid] = {}
            end
            table.insert(groupedRecords[record.citizenid], record)
        end
        
        -- 各citizenidのデータを処理
        for citizenid, citizenRecords in pairs(groupedRecords) do
            -- プレイヤー情報を取得
            MySQL.Async.fetchAll('SELECT * FROM players WHERE citizenid = ?', {citizenid}, function(playerData)
                processedCount = processedCount + 1
                
                if playerData[1] then
                    local charinfo = json.decode(playerData[1].charinfo)
                    
                    local employeeData = {
                        citizenid = citizenid,
                        name = charinfo.firstname .. ' ' .. charinfo.lastname,
                        lastWorked = nil,
                        totalMinutes = 0,
                        totalDays = 0,
                        totalHours = 0,
                        monthlyBreakdown = {}, -- 月ごとの内訳を追加
                        jobs = {}
                    }
                    
                    -- 各レコードを処理
                    for _, record in ipairs(citizenRecords) do
                        -- 合計を更新
                        employeeData.totalMinutes = employeeData.totalMinutes + record.total_minutes
                        employeeData.totalDays = math.max(employeeData.totalDays, record.total_days)
                        
                        -- 月ごとの内訳を作成
                        local monthKey = string.format("%04d-%02d", record.year, record.month)
                        if not employeeData.monthlyBreakdown[monthKey] then
                            employeeData.monthlyBreakdown[monthKey] = {
                                year = record.year,
                                month = record.month,
                                totalMinutes = 0,
                                totalHours = 0,
                                totalDays = 0,
                                jobs = {}
                            }
                        end
                        
                        -- 月ごとの時間を集計
                        employeeData.monthlyBreakdown[monthKey].totalMinutes = 
                            employeeData.monthlyBreakdown[monthKey].totalMinutes + record.total_minutes
                        employeeData.monthlyBreakdown[monthKey].totalHours = 
                            math.floor(employeeData.monthlyBreakdown[monthKey].totalMinutes / 60)
                        employeeData.monthlyBreakdown[monthKey].totalDays = 
                            math.max(employeeData.monthlyBreakdown[monthKey].totalDays, record.total_days)
                        
                        -- ジョブごとの内訳
                        if not employeeData.monthlyBreakdown[monthKey].jobs[record.job] then
                            employeeData.monthlyBreakdown[monthKey].jobs[record.job] = {
                                minutes = 0,
                                days = 0
                            }
                        end
                        employeeData.monthlyBreakdown[monthKey].jobs[record.job].minutes = 
                            employeeData.monthlyBreakdown[monthKey].jobs[record.job].minutes + record.total_minutes
                        employeeData.monthlyBreakdown[monthKey].jobs[record.job].days = record.total_days
                        
                        -- 最新の勤務日を更新
                        if not employeeData.lastWorked or 
                           (record.last_worked and record.last_worked > employeeData.lastWorked) then
                            employeeData.lastWorked = record.last_worked
                        end
                        
                        -- ジョブ情報を追加（全従業員表示の場合）
                        if isRequestingAll then
                            local jobFound = false
                            for _, job in ipairs(employeeData.jobs) do
                                if job == record.job then
                                    jobFound = true
                                    break
                                end
                            end
                            if not jobFound then
                                table.insert(employeeData.jobs, record.job)
                            end
                        end
                    end
                    
                    -- 時間を計算
                    employeeData.totalHours = math.floor(employeeData.totalMinutes / 60)
                    
                    -- jobsを文字列に変換（JavaScriptの既存コードとの互換性のため）
                    if #employeeData.jobs > 0 then
                        employeeData.jobsList = table.concat(employeeData.jobs, ", ")
                    end
                    
                    table.insert(employees, employeeData)
                end
                
                -- すべての処理が完了したらクライアントに送信
                if processedCount == table_length(groupedRecords) then
                    -- totalHoursでソート（降順）
                    table.sort(employees, function(a, b)
                        return a.totalHours > b.totalHours
                    end)
                    
                    TriggerClientEvent('ng-attendance:client:receiveManagementData', src, employees)
                end
            end)
        end
    end)
end)

-- ヘルパー関数：テーブルの長さを取得
function table_length(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- クライアントイベント: 従業員の勤務記録取得（全ジョブ対応版）
RegisterNetEvent('ng-attendance:server:getEmployeeRecords', function(citizenid, date, requestedJob)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- requestedJobが"all"の場合は全ジョブの記録を取得
    local isRequestingAll = requestedJob == "all"
    
    -- 権限チェック
    if not isRequestingAll and requestedJob and not HasManagementPermission(src, requestedJob) then
        TriggerClientEvent('ng-attendance:client:showNotification', src, Config.GetText('no_permission'), 'error')
        return
    elseif isRequestingAll then
        -- 全ジョブを見る場合は、いずれかのジョブでボス権限を持っているか確認
        local hasAnyBossPermission = false
        local playerJobs = GetPlayerJobs(Player)
        for jobName, jobData in pairs(playerJobs) do
            if jobData.isboss and Config.IsJobEnabled(jobName) then
                hasAnyBossPermission = true
                break
            end
        end
        
        if not hasAnyBossPermission then
            TriggerClientEvent('ng-attendance:client:showNotification', src, Config.GetText('no_permission'), 'error')
            return
        end
    end

    -- SQLクエリを動的に構築
    local query
    local params
    
    if isRequestingAll then
        -- 全ジョブの記録を取得
        query = 'SELECT * FROM ng_attendance_daily WHERE citizenid = ? AND date = ? ORDER BY first_clock_in ASC'
        params = {citizenid, date}
    elseif requestedJob then
        -- 特定ジョブの記録を取得
        query = 'SELECT * FROM ng_attendance_daily WHERE citizenid = ? AND date = ? AND job = ?'
        params = {citizenid, date, requestedJob}
    else
        -- 従来の動作（権限のあるジョブのみ）
        query = 'SELECT * FROM ng_attendance_daily WHERE citizenid = ? AND date = ?'
        params = {citizenid, date}
    end
    
    MySQL.Async.fetchAll(query, params, function(records)
        if #records == 0 then
            TriggerClientEvent('ng-attendance:client:receiveEmployeeRecords', src, {})
            return
        end
        
        local formattedRecords = {}
        local hasPermission = false
        
        for _, record in ipairs(records) do
            -- 各ジョブの権限チェック（全ジョブ表示モードでない場合）
            if isRequestingAll or HasManagementPermission(src, record.job) then
                hasPermission = true
                
                table.insert(formattedRecords, {
                    job = record.job,
                    clock_in = record.first_clock_in,
                    clock_out = record.last_clock_out,
                    total_minutes = record.total_minutes,
                    job_grade = record.job_grade,
                    session_count = record.session_count
                })
            end
        end
        
        if not hasPermission and not isRequestingAll then
            TriggerClientEvent('ng-attendance:client:showNotification', src, Config.GetText('no_permission'), 'error')
            return
        end
        
        TriggerClientEvent('ng-attendance:client:receiveEmployeeRecords', src, formattedRecords)
    end)
end)

-- クライアントイベント: 従業員の月次記録取得（月ごとの詳細対応版）
RegisterNetEvent('ng-attendance:server:getMonthlyRecords', function(citizenid, year, month, requestedJob)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- requestedJobが"all"の場合は全ジョブの記録を取得
    local isRequestingAll = requestedJob == "all"
    
    -- 権限チェック（全ジョブ表示の場合）
    if isRequestingAll then
        local hasAnyBossPermission = false
        local playerJobs = GetPlayerJobs(Player)
        for jobName, jobData in pairs(playerJobs) do
            if jobData.isboss and Config.IsJobEnabled(jobName) then
                hasAnyBossPermission = true
                break
            end
        end
        
        if not hasAnyBossPermission then
            TriggerClientEvent('ng-attendance:client:showNotification', src, Config.GetText('no_permission'), 'error')
            return
        end
    end

    -- 日別記録から該当月のデータを取得
    local startDate = string.format('%04d-%02d-01', year, month)
    local endDate = string.format('%04d-%02d-%02d', year, month, os.date('*t', os.time{year=year, month=month+1, day=0}).day)

    local query
    local params
    
    if isRequestingAll then
        query = [[
            SELECT date, job, total_minutes
            FROM ng_attendance_daily 
            WHERE citizenid = ? AND date BETWEEN ? AND ?
            ORDER BY date ASC, job ASC
        ]]
        params = {citizenid, startDate, endDate}
    elseif requestedJob then
        query = [[
            SELECT date, job, total_minutes
            FROM ng_attendance_daily 
            WHERE citizenid = ? AND date BETWEEN ? AND ? AND job = ?
            ORDER BY date ASC
        ]]
        params = {citizenid, startDate, endDate, requestedJob}
    else
        query = [[
            SELECT date, job, total_minutes
            FROM ng_attendance_daily 
            WHERE citizenid = ? AND date BETWEEN ? AND ?
            ORDER BY date ASC, job ASC
        ]]
        params = {citizenid, startDate, endDate}
    end

    MySQL.Async.fetchAll(query, params, function(records)
        local monthlyData = {}
        local hasPermission = false
        
        for _, record in ipairs(records) do
            if isRequestingAll or HasManagementPermission(src, record.job) then
                hasPermission = true
                if not monthlyData[record.date] then
                    monthlyData[record.date] = {
                        jobs = {},
                        totalMinutes = 0
                    }
                end
                monthlyData[record.date].jobs[record.job] = {
                    minutes = record.total_minutes
                }
                monthlyData[record.date].totalMinutes = monthlyData[record.date].totalMinutes + record.total_minutes
            end
        end
        
        if not hasPermission and not isRequestingAll then
            TriggerClientEvent('ng-attendance:client:showNotification', src, Config.GetText('no_permission'), 'error')
            return
        end
        
        TriggerClientEvent('ng-attendance:client:receiveMonthlyRecords', src, monthlyData)
    end)
end)

-- プレイヤーの勤務状態変更を監視（複数ジョブ対応）
CreateThread(function()
    while true do
        Wait(Config.UpdateInterval)
        
        if isServerReady then
            local players = QBCore.Functions.GetQBPlayers()
            for src, Player in pairs(players) do
                if Player and Player.PlayerData then
                    local citizenid = Player.PlayerData.citizenid
                    local playerJobs = GetPlayerJobs(Player)
                    
                    -- 現在のアクティブセッションと比較
                    local currentSessions = activeSessions[citizenid] or {}
                    
                    -- 勤務中のジョブをチェック
                    for jobName, jobData in pairs(playerJobs) do
                        if jobData.onduty and not currentSessions[jobName] then
                            -- 勤務開始
                            StartWorkSession(citizenid, jobName, jobData.grade, src)
                        elseif not jobData.onduty and currentSessions[jobName] then
                            -- 勤務終了
                            EndWorkSession(citizenid, jobName, false)
                        end
                    end
                    
                    -- 削除されたジョブのセッションを終了
                    for jobName, sessionData in pairs(currentSessions) do
                        if not playerJobs[jobName] or not playerJobs[jobName].onduty then
                            EndWorkSession(citizenid, jobName, false)
                        end
                    end
                end
            end
        end
    end
end)

-- リソース停止時の処理
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        -- すべてのアクティブセッションを終了
        for citizenid, jobSessions in pairs(activeSessions) do
            for job, session in pairs(jobSessions) do
                EndWorkSession(citizenid, job, true)
            end
        end
        
        if Config.Debug then
            print('^3[ng-attendance]^7 リソース停止時にすべてのセッションを終了しました')
        end
    end
end)
