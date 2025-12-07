local QBCore = exports['qb-core']:GetCoreObject()

-- ローカル変数
local isUIOpen = false
local currentWorkStatus = {}
local managementData = {}
local selectedEmployee = nil
local selectedDate = nil
local isSessionRestored = false

-- 初期化
CreateThread(function()
    Wait(5000) -- QB-Coreの初期化を待つ
    
    -- NUIコールバック登録
    RegisterNUICallbacks()
    
    -- 定期的な状況更新
    StartStatusUpdateTimer()
    
    -- 初回の勤務状況チェック
    Wait(2000)
    TriggerServerEvent('ng-attendance:server:getWorkStatus')
    
    if Config.Debug then
        print('^2[ng-attendance]^7 クライアントが開始されました')
    end
end)

-- キーバインド登録
RegisterCommand('attendance', function()
    ToggleUI()
end, false)

-- キーマッピング
RegisterKeyMapping('attendance', '出退勤管理システム', 'keyboard', Config.UIKey)

-- UI表示/非表示
function ToggleUI()
    local PlayerData = QBCore.Functions.GetPlayerData()
    
    -- 権限チェック
    if not PlayerData or not PlayerData.job then
        ShowNotification(Config.GetText('no_permission'), 'error')
        return
    end

    -- 対応ジョブかチェック
    if not Config.IsJobEnabled(PlayerData.job.name) then
        ShowNotification('このジョブは出退勤管理に対応していません', 'error')
        return
    end

    if isUIOpen then
        CloseUI()
    else
        OpenUI()
    end
end

-- UI開く
function OpenUI()
    if isUIOpen then return end
    
    isUIOpen = true
    SetNuiFocus(true, true)
    
    -- 現在の勤務状況を取得
    TriggerServerEvent('ng-attendance:server:getWorkStatus')
    
    -- UIを表示
    SendNUIMessage({
        action = 'openUI',
        data = {
            playerData = QBCore.Functions.GetPlayerData(),
            config = {
                jobs = Config.Jobs,
                locale = Config.Locale
            }
        }
    })
    
    if Config.Debug then
        print('^2[ng-attendance]^7 UIを開きました')
    end
end

-- UI閉じる
function CloseUI()
    if not isUIOpen then return end
    
    isUIOpen = false
    SetNuiFocus(false, false)
    
    SendNUIMessage({
        action = 'closeUI'
    })
    
    if Config.Debug then
        print('^2[ng-attendance]^7 UIを閉じました')
    end
end

-- 定期的な状況更新
function StartStatusUpdateTimer()
    CreateThread(function()
        while true do
            Wait(Config.UpdateInterval)
            
            if isUIOpen then
                TriggerServerEvent('ng-attendance:server:getWorkStatus')
            end
        end
    end)
end

-- NUIコールバック登録
function RegisterNUICallbacks()
    -- UI閉じる
    RegisterNUICallback('closeUI', function(data, cb)
        CloseUI()
        cb('ok')
    end)
    
    -- 勤務状況取得
    RegisterNUICallback('getWorkStatus', function(data, cb)
        TriggerServerEvent('ng-attendance:server:getWorkStatus')
        cb('ok')
    end)
    
    -- 管理画面データ取得
    RegisterNUICallback('getManagementData', function(data, cb)
        if data.job then
            TriggerServerEvent('ng-attendance:server:getManagementData', data.job)
        end
        cb('ok')
    end)
    
    -- 従業員選択
    RegisterNUICallback('selectEmployee', function(data, cb)
        selectedEmployee = data.citizenid
        if Config.Debug then
            print('^2[ng-attendance]^7 従業員を選択しました: ' .. selectedEmployee)
        end
        cb('ok')
    end)
    
    -- 日付選択
    RegisterNUICallback('selectDate', function(data, cb)
        selectedDate = data.date
        if selectedEmployee and selectedDate then
            TriggerServerEvent('ng-attendance:server:getEmployeeRecords', selectedEmployee, selectedDate)
        end
        cb('ok')
    end)
    
    -- 月次記録取得
    RegisterNUICallback('getMonthlyRecords', function(data, cb)
        if selectedEmployee and data.year and data.month then
            TriggerServerEvent('ng-attendance:server:getMonthlyRecords', selectedEmployee, data.year, data.month)
        end
        cb('ok')
    end)
    
    -- 従業員検索
    RegisterNUICallback('searchEmployee', function(data, cb)
        -- クライアント側でフィルタリング（高速化のため）
        local query = data.query:lower()
        local filteredData = {}
        
        for _, employee in ipairs(managementData) do
            if string.find(employee.name:lower(), query) or 
               string.find(employee.citizenid:lower(), query) then
                table.insert(filteredData, employee)
            end
        end
        
        SendNUIMessage({
            action = 'updateEmployeeList',
            data = filteredData
        })
        
        cb('ok')
    end)
    
    -- デバッグ情報出力
    RegisterNUICallback('debugLog', function(data, cb)
        if Config.Debug then
            print('^3[ng-attendance NUI]^7 ' .. (data.message or 'デバッグメッセージ'))
        end
        cb('ok')
    end)
end

-- サーバーイベント: 勤務状況受信（複数ジョブ対応）
RegisterNetEvent('ng-attendance:client:receiveWorkStatus', function(workStatus)
    currentWorkStatus = workStatus
    
    if isUIOpen then
        SendNUIMessage({
            action = 'updateWorkStatus',
            data = workStatus
        })
    end
    
    if Config.Debug then
        local activeJobCount = 0
        if workStatus.activeJobs then
            for _ in pairs(workStatus.activeJobs) do
                activeJobCount = activeJobCount + 1
            end
        end
        print('^2[ng-attendance]^7 勤務状況を更新しました: ' .. activeJobCount .. '個のジョブがアクティブ')
    end
end)

-- サーバーイベント: 管理画面データ受信
RegisterNetEvent('ng-attendance:client:receiveManagementData', function(employees)
    managementData = employees
    
    if isUIOpen then
        SendNUIMessage({
            action = 'updateManagementData',
            data = employees
        })
    end
    
    if Config.Debug then
        print('^2[ng-attendance]^7 管理画面データを受信しました: ' .. #employees .. '件')
    end
end)

-- サーバーイベント: 従業員記録受信
RegisterNetEvent('ng-attendance:client:receiveEmployeeRecords', function(records)
    if isUIOpen then
        SendNUIMessage({
            action = 'updateEmployeeRecords',
            data = records
        })
    end
    
    if Config.Debug then
        print('^2[ng-attendance]^7 従業員記録を受信しました: ' .. #records .. '件')
    end
end)

-- サーバーイベント: 月次記録受信
RegisterNetEvent('ng-attendance:client:receiveMonthlyRecords', function(monthlyData)
    if isUIOpen then
        SendNUIMessage({
            action = 'updateMonthlyRecords',
            data = monthlyData
        })
    end
end)

-- サーバーイベント: 勤務開始通知
RegisterNetEvent('ng-attendance:client:workStarted', function(data)
    if Config.Notifications.workStart then
        ShowNotification(Config.GetText('work_start') .. ' (' .. data.job .. ')', 'success')
    end
    
    if Config.Debug then
        print('^2[ng-attendance]^7 勤務開始: ' .. data.job .. ' at ' .. data.clockIn)
    end
end)

-- サーバーイベント: 勤務終了通知
RegisterNetEvent('ng-attendance:client:workEnded', function(data)
    if Config.Notifications.workEnd then
        local hours = math.floor(data.totalMinutes / 60)
        local minutes = data.totalMinutes % 60
        local dailyHours = math.floor(data.dailyTotal / 60)
        local dailyMinutes = data.dailyTotal % 60
        
        ShowNotification(
            Config.GetText('work_end') .. '\n' ..
            'セッション: ' .. hours .. '時間' .. minutes .. '分\n' ..
            '本日合計: ' .. dailyHours .. '時間' .. dailyMinutes .. '分',
            'success'
        )
    end
    
    if Config.Debug then
        print('^2[ng-attendance]^7 勤務終了: ' .. data.job .. ' セッション: ' .. data.totalMinutes .. '分, 本日合計: ' .. data.dailyTotal .. '分')
    end
end)

-- サーバーイベント: セッション復旧通知
RegisterNetEvent('ng-attendance:client:sessionRestored', function(data)
    isSessionRestored = true
    
    if Config.Notifications.workStart then
        ShowNotification('勤務セッションが復旧されました (' .. data.job .. ')', 'info')
    end
    
    if Config.Debug then
        print('^3[ng-attendance]^7 セッション復旧: ' .. data.job .. ' 開始時刻: ' .. data.clockIn)
    end
    
    -- UIが開いていれば状況を更新
    if isUIOpen then
        TriggerServerEvent('ng-attendance:server:getWorkStatus')
    end
end)

-- サーバーイベント: 通知表示
RegisterNetEvent('ng-attendance:client:showNotification', function(message, type)
    ShowNotification(message, type)
end)

-- 通知表示
function ShowNotification(message, type)
    type = type or 'info'
    
    -- ox_lib使用
    if GetResourceState('ox_lib') == 'started' then
        lib.notify({
            title = Config.GetText('ui_title'),
            description = message,
            type = type,
            duration = 5000
        })
    -- QB-Core通知
    elseif QBCore and QBCore.Functions and QBCore.Functions.Notify then
        QBCore.Functions.Notify(message, type, 5000)
    -- 基本的な通知
    else
        SetNotificationTextEntry('STRING')
        AddTextComponentString(message)
        DrawNotification(false, false)
    end
end

-- ジョブ変更時の処理
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    -- UIが開いている場合は更新
    if isUIOpen then
        -- 新しいジョブが対応していない場合はUIを閉じる
        if not Config.IsJobEnabled(job.name) then
            CloseUI()
            ShowNotification('ジョブが変更されたため、出退勤管理を終了しました', 'info')
        else
            -- 勤務状況を更新
            Wait(2000) -- ジョブ変更処理を待つ
            TriggerServerEvent('ng-attendance:server:getWorkStatus')
        end
    end
end)

-- プレイヤーデータ更新時の処理
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(3000) -- 初期化を待つ
    
    -- 勤務状況をチェック
    TriggerServerEvent('ng-attendance:server:getWorkStatus')
    
    if Config.Debug then
        print('^2[ng-attendance]^7 プレイヤーデータが読み込まれました')
    end
end)

-- 勤務状態変更時の処理（ox_lib使用）
if GetResourceState('ox_lib') == 'started' then
    RegisterNetEvent('QBCore:Client:SetDuty', function(duty)
        if Config.Debug then
            print('^2[ng-attendance]^7 勤務状態が変更されました: ' .. tostring(duty))
        end
        
        -- 少し待ってから状況を更新
        SetTimeout(2000, function()
            TriggerServerEvent('ng-attendance:server:getWorkStatus')
            if isUIOpen then
                TriggerServerEvent('ng-attendance:server:getWorkStatus')
            end
        end)
    end)
end

-- リソース停止時の処理
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if isUIOpen then
            CloseUI()
        end
    end
end)

-- ヘルパー関数: 時間フォーマット
function FormatTime(minutes)
    local hours = math.floor(minutes / 60)
    local mins = minutes % 60
    return string.format('%d時間%d分', hours, mins)
end

-- ヘルパー関数: 日付フォーマット
function FormatDate(dateString)
    local year, month, day = dateString:match('(%d+)-(%d+)-(%d+)')
    return string.format('%04d/%02d/%02d', tonumber(year), tonumber(month), tonumber(day))
end

-- ヘルパー関数: 日時フォーマット
function FormatDateTime(dateTimeString)
    local year, month, day, hour, min, sec = dateTimeString:match('(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)')
    return string.format('%04d/%02d/%02d %02d:%02d:%02d', 
        tonumber(year), tonumber(month), tonumber(day),
        tonumber(hour), tonumber(min), tonumber(sec))
end

-- エクスポート関数
exports('IsUIOpen', function()
    return isUIOpen
end)

exports('GetCurrentWorkStatus', function()
    return currentWorkStatus
end)

exports('OpenAttendanceUI', function()
    OpenUI()
end)

exports('CloseAttendanceUI', function()
    CloseUI()
end)

exports('IsSessionRestored', function()
    return isSessionRestored
end)