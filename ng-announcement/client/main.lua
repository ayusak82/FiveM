local QBCore = exports['qb-core']:GetCoreObject()

-- デバッグ出力関数
local function DebugPrint(...)
    if not Config.Debug then return end
    local args = {...}
    local message = ''
    for i = 1, #args do
        message = message .. tostring(args[i]) .. ' '
    end
    print('^3[ng-announcement DEBUG]^7 ' .. message)
end

-- 許可された職業かチェック
local function isAllowedJob(jobName)
    for _, allowedJob in ipairs(Config.AllowedJobs) do
        if allowedJob == jobName then
            return true
        end
    end
    return false
end

-- UI状態
local isUIOpen = false

-- UI を開く
local function openAnnouncementUI()
    if isUIOpen then return end
    
    local PlayerData = QBCore.Functions.GetPlayerData()
    if not PlayerData or not PlayerData.job then
        exports['okokNotify']:Alert('エラー', 'プレイヤーデータを取得できません', 5000, 'error', true)
        return
    end
    
    local jobName = PlayerData.job.name
    
    -- 許可された職業かチェック
    if not isAllowedJob(jobName) then
        exports['okokNotify']:Alert('エラー', 'あなたの職業ではお知らせを出せません', 5000, 'error', true)
        DebugPrint('Job not allowed:', jobName)
        return
    end
    
    local jobConfig = Config.Jobs[jobName] or Config.DefaultJob
    local charName = PlayerData.charinfo.firstname .. ' ' .. PlayerData.charinfo.lastname
    
    DebugPrint('Opening UI for job:', jobName, 'name:', charName)
    
    isUIOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openInput',
        job = jobName,
        jobLabel = jobConfig.label,
        jobColor = jobConfig.color,
        jobIcon = jobConfig.icon,
        playerName = charName,
        maxLength = Config.MaxLength
    })
end

-- UI を閉じる
local function closeAnnouncementUI()
    if not isUIOpen then return end
    
    isUIOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closeInput'
    })
    DebugPrint('UI closed')
end

-- お知らせを表示
local function showAnnouncement(data)
    DebugPrint('Showing announcement from:', data.jobLabel, data.playerName)
    
    SendNUIMessage({
        action = 'showAnnouncement',
        jobLabel = data.jobLabel,
        jobColor = data.jobColor,
        jobIcon = data.jobIcon,
        playerName = data.playerName,
        message = data.message,
        duration = Config.DisplayDuration
    })
end

-- NUI コールバック: 閉じる
RegisterNUICallback('close', function(_, cb)
    closeAnnouncementUI()
    cb('ok')
end)

-- NUI コールバック: 送信
RegisterNUICallback('submit', function(data, cb)
    if not data.message or data.message == '' then
        exports['okokNotify']:Alert('エラー', 'メッセージを入力してください', 3000, 'error', true)
        cb('error')
        return
    end
    
    if #data.message > Config.MaxLength then
        exports['okokNotify']:Alert('エラー', '文字数が制限を超えています', 3000, 'error', true)
        cb('error')
        return
    end
    
    DebugPrint('Submitting announcement:', data.message)
    
    closeAnnouncementUI()
    TriggerServerEvent('ng-announcement:server:sendAnnouncement', data.message)
    cb('ok')
end)

-- サーバーからのお知らせ受信
RegisterNetEvent('ng-announcement:client:receiveAnnouncement', function(data)
    DebugPrint('Received announcement from server')
    showAnnouncement(data)
end)

-- UI を開くイベント
RegisterNetEvent('ng-announcement:client:openUI', function()
    openAnnouncementUI()
end)

-- コマンド登録
RegisterCommand(Config.Command, function()
    openAnnouncementUI()
end, false)

-- Export: UI を開く（qb-radialmenu用）
exports('openAnnouncementUI', function()
    openAnnouncementUI()
end)

-- Export: 許可された職業かチェック
exports('isAllowedJob', function(jobName)
    return isAllowedJob(jobName)
end)

-- qb-radialmenu への登録
CreateThread(function()
    Wait(1000) -- リソース読み込み待ち
    
    local radialConfig = Config.RadialMenu
    
    -- qb-radialmenu が存在するかチェック
    if GetResourceState('qb-radialmenu') == 'started' then
        exports['qb-radialmenu']:AddOption({
            id = radialConfig.id,
            title = radialConfig.title,
            icon = radialConfig.icon,
            type = radialConfig.type,
            event = radialConfig.event,
            shouldClose = radialConfig.shouldClose
        }, radialConfig.id)
        DebugPrint('Registered to qb-radialmenu')
    else
        DebugPrint('qb-radialmenu not found, skipping registration')
    end
end)

-- リソース停止時のクリーンアップ
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if isUIOpen then
        closeAnnouncementUI()
    end
    
    -- qb-radialmenu から削除
    if GetResourceState('qb-radialmenu') == 'started' then
        exports['qb-radialmenu']:RemoveOption(Config.RadialMenu.id)
    end
end)
