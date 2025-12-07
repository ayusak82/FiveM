local QBCore = exports['qb-core']:GetCoreObject()

-- 次の再起動時間までの残り時間を計算する関数
local function GetNextRestartTime()
    local currentTime = os.date("*t")
    local currentMinutes = currentTime.hour * 60 + currentTime.min
    
    local nextRestartMinutes = nil
    local timeUntilNextRestart = nil
    
    -- すべての再起動時間をチェックして最も近いものを見つける
    for _, restartTime in ipairs(Config.ServerRestartTimes) do
        local hours, minutes = string.match(restartTime, "(%d+):(%d+)")
        hours, minutes = tonumber(hours), tonumber(minutes)
        
        local restartMinutes = hours * 60 + minutes
        local minutesUntilRestart = restartMinutes - currentMinutes
        
        if minutesUntilRestart < 0 then
            minutesUntilRestart = minutesUntilRestart + (24 * 60) -- 翌日の再起動時間
        end
        
        if nextRestartMinutes == nil or minutesUntilRestart < timeUntilNextRestart then
            nextRestartMinutes = restartMinutes
            timeUntilNextRestart = minutesUntilRestart
        end
    end
    
    local hoursUntilRestart = math.floor(timeUntilNextRestart / 60)
    local remainingMinutes = timeUntilNextRestart % 60
    
    -- 次回の再起動時間も計算
    local nextRestartHours = math.floor(nextRestartMinutes / 60)
    local nextRestartMins = nextRestartMinutes % 60
    local nextRestartTimeStr = string.format("%02d:%02d", nextRestartHours, nextRestartMins)
    
    return {
        countdown = string.format("%02d:%02d", hoursUntilRestart, remainingMinutes),
        nextTime = nextRestartTimeStr
    }
end

-- 電話番号をデータベースから取得する関数
local function GetPhoneNumber(citizenid)
    local phoneNumber = nil
    local result = MySQL.query.await('SELECT phone_number FROM phone_phones WHERE owner_id = ?', {citizenid})
    
    if result and #result > 0 then
        phoneNumber = result[1].phone_number
    end
    
    return phoneNumber or "不明"
end

-- ジョブIDから日本語表示名を取得する関数
local function GetJobDisplayName(jobName)
    for _, job in ipairs(Config.Jobs) do
        if job.jobName == jobName then
            return job.name
        end
    end
    return jobName -- 見つからない場合は元のjobNameを返す
end

-- クライアントからのデータリクエストを処理
RegisterNetEvent('ng-scoreboard:server:RequestData', function()
    local src = source
    local Players = QBCore.Functions.GetPlayers()
    local jobCounts = {}
    local playersList = {}
    
    -- ジョブの数を初期化（Config.Jobsの順番を保持）
    for _, job in ipairs(Config.Jobs) do
        jobCounts[job.jobName] = 0
    end
    
    -- プレイヤーとジョブ情報を収集
    for _, v in pairs(Players) do
        local Player = QBCore.Functions.GetPlayer(v)
        if Player then
            local jobName = Player.PlayerData.job.name
            local citizenid = Player.PlayerData.citizenid
            
            -- 電話番号を取得
            local phoneNumber = GetPhoneNumber(citizenid)
            
            -- データベースから最新の名前を取得
            local dbResult = MySQL.query.await('SELECT charinfo FROM players WHERE citizenid = ?', {citizenid})
            local displayName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
            
            if dbResult and #dbResult > 0 then
                local charinfo = json.decode(dbResult[1].charinfo)
                if charinfo and charinfo.firstname and charinfo.lastname then
                    displayName = charinfo.firstname .. " " .. charinfo.lastname
                end
            end
            
            -- ジョブ数をカウント
            if jobCounts[jobName] ~= nil then
                jobCounts[jobName] = jobCounts[jobName] + 1
            end
            
            -- プレイヤーリストに追加（CitizenIDと電話番号を含む）
            table.insert(playersList, {
                id = v,
                citizenid = citizenid,
                name = displayName,
                realName = displayName,
                hasCustomName = false,
                job = GetJobDisplayName(jobName), -- 日本語表示名を使用
                grade = Player.PlayerData.job.grade.name,
                phone = phoneNumber -- 電話番号を追加
            })
        end
    end
    
    -- ジョブカウントをConfig.Jobsの順番で整理された配列に変換
    local orderedJobCounts = {}
    for _, job in ipairs(Config.Jobs) do
        if jobCounts[job.jobName] > 0 then -- カウントが0より大きい場合のみ追加
            table.insert(orderedJobCounts, {
                name = job.name,
                jobName = job.jobName,
                count = jobCounts[job.jobName]
            })
        end
    end
    
    -- 次の再起動時間情報を取得
    local restartInfo = GetNextRestartTime()
    
    -- クライアントにデータを送信
    TriggerClientEvent('ng-scoreboard:client:UpdateData', src, {
        totalPlayers = #Players,
        maxPlayers = GetConvarInt('sv_maxclients', 64),
        restartInfo = restartInfo,
        jobCounts = orderedJobCounts, -- 順序付きの配列として送信
        playersList = playersList,
        robberies = Config.Robberies
    })
end)