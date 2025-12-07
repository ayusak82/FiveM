-- QBCore初期化
QBCore = exports['qb-core']:GetCoreObject()

-- 管理者権限チェック関数
local function isAdmin(source)
    if not source then return false end
    return IsPlayerAceAllowed(source, 'command.admin')
end

-- 管理者権限チェックのコールバック登録
lib.callback.register('ng-dbstress:server:isAdmin', function(source)
    return isAdmin(source)
end)

-- テスト開始処理
lib.callback.register('ng-dbstress:server:startTest', function(source, testType, settings)
    if not isAdmin(source) then
        if Config.Debug then
            print('^3[ng-dbstress]^7 権限のないプレイヤーがテストを試行: ' .. source)
        end
        return { success = false, message = '管理者権限が必要です' }
    end
    
    -- テストログ作成
    local logId = CreateTestLog(source, testType, settings)
    if not logId then
        return { success = false, message = 'ログの作成に失敗しました' }
    end
    
    local testId = 'test_' .. logId .. '_' .. os.time()
    local stats = nil
    
    -- テストタイプに応じて実行
    if testType == 'insert' then
        stats = RunInsertTest(testId, settings, source)
    elseif testType == 'select' then
        stats = RunSelectTest(testId, settings, source)
    elseif testType == 'update' then
        stats = RunUpdateTest(testId, settings, source)
    elseif testType == 'delete' then
        stats = RunDeleteTest(testId, settings, source)
    elseif testType == 'join' then
        stats = RunJoinTest(testId, settings, source)
    elseif testType == 'transaction' then
        stats = RunTransactionTest(testId, settings, source)
    elseif testType == 'concurrent' then
        stats = RunConcurrentTest(testId, settings, source)
    elseif testType == 'all' then
        -- 全テスト実行
        return { success = true, testId = testId, logId = logId, isAllTests = true }
    else
        UpdateTestLog(logId, 'error')
        return { success = false, message = '不明なテストタイプです' }
    end
    
    if Config.Debug then
        print(string.format('^2[ng-dbstress]^7 テスト開始: %s (ID: %s, ログID: %d)', testType, testId, logId))
    end
    
    -- テスト完了監視
    CreateThread(function()
        while TestStates[testId] and TestStates[testId].running do
            Wait(1000)
        end
        
        Wait(1000) -- 統計情報の確定を待つ
        
        if TestStates[testId] and TestStates[testId].completed then
            -- テスト結果を保存
            SaveTestResult(logId, testType, stats)
            UpdateTestLog(logId, 'completed')
            
            -- クライアントに完了通知
            TriggerClientEvent('ng-dbstress:client:testCompleted', source, {
                testId = testId,
                logId = logId,
                stats = stats
            })
            
            if Config.Debug then
                print(string.format('^2[ng-dbstress]^7 テスト完了: %s (ID: %s)', testType, testId))
                print(string.format('  実行: %d, 成功: %d, 失敗: %d', stats.executed, stats.success, stats.failed))
                print(string.format('  平均応答時間: %.2fms', stats.avgTime))
            end
        else
            UpdateTestLog(logId, 'stopped')
            TriggerClientEvent('ng-dbstress:client:testStopped', source, testId)
            
            if Config.Debug then
                print(string.format('^3[ng-dbstress]^7 テスト停止: %s (ID: %s)', testType, testId))
            end
        end
        
        -- 状態クリーンアップ
        Wait(5000)
        TestStates[testId] = nil
    end)
    
    return { success = true, testId = testId, logId = logId }
end)

-- 全テスト実行処理
RegisterNetEvent('ng-dbstress:server:runAllTests', function(settings)
    local source = source
    
    if not isAdmin(source) then
        return
    end
    
    local testTypes = {'insert', 'select', 'update', 'delete', 'join', 'transaction', 'concurrent'}
    local results = {}
    
    CreateThread(function()
        for index, testType in ipairs(testTypes) do
            -- 各テストのログID作成
            local logId = CreateTestLog(source, testType, settings)
            if logId then
                local testId = 'test_' .. logId .. '_' .. os.time()
                local stats = nil
                
                -- テスト実行
                TriggerClientEvent('ng-dbstress:client:allTestsProgress', source, {
                    currentTest = testType,
                    testNumber = index,
                    totalTests = #testTypes
                })
                
                if testType == 'insert' then
                    stats = RunInsertTest(testId, settings, source)
                elseif testType == 'select' then
                    stats = RunSelectTest(testId, settings, source)
                elseif testType == 'update' then
                    stats = RunUpdateTest(testId, settings, source)
                elseif testType == 'delete' then
                    stats = RunDeleteTest(testId, settings, source)
                elseif testType == 'join' then
                    stats = RunJoinTest(testId, settings, source)
                elseif testType == 'transaction' then
                    stats = RunTransactionTest(testId, settings, source)
                elseif testType == 'concurrent' then
                    stats = RunConcurrentTest(testId, settings, source)
                end
                
                -- テスト完了まで待機
                while TestStates[testId] and TestStates[testId].running do
                    Wait(1000)
                end
                
                Wait(1000)
                
                -- 結果保存
                if TestStates[testId] and TestStates[testId].completed then
                    SaveTestResult(logId, testType, stats)
                    UpdateTestLog(logId, 'completed')
                    table.insert(results, {
                        testType = testType,
                        stats = stats
                    })
                else
                    UpdateTestLog(logId, 'stopped')
                end
                
                TestStates[testId] = nil
                
                -- 次のテストまで少し待機
                Wait(2000)
            end
        end
        
        -- 全テスト完了通知
        TriggerClientEvent('ng-dbstress:client:allTestsCompleted', source, results)
        
        if Config.Debug then
            print('^2[ng-dbstress]^7 全テストが完了しました')
        end
    end)
end)

-- テスト停止処理
lib.callback.register('ng-dbstress:server:stopTest', function(source, testId)
    if not isAdmin(source) then
        return { success = false, message = '管理者権限が必要です' }
    end
    
    local stopped = StopTest(testId)
    
    if Config.Debug and stopped then
        print(string.format('^3[ng-dbstress]^7 テスト停止リクエスト: %s', testId))
    end
    
    return { success = stopped }
end)

-- データクリーンアップ処理
lib.callback.register('ng-dbstress:server:cleanupData', function(source)
    if not isAdmin(source) then
        return { success = false, message = '管理者権限が必要です' }
    end
    
    local success = CleanupTestData()
    
    if Config.Debug then
        print('^2[ng-dbstress]^7 データクリーンアップ実行: ' .. tostring(success))
    end
    
    return { success = success }
end)

-- 統計情報取得処理
lib.callback.register('ng-dbstress:server:getStatistics', function(source)
    if not isAdmin(source) then
        return nil
    end
    
    return GetTestStatistics()
end)

-- テスト履歴取得処理
lib.callback.register('ng-dbstress:server:getTestHistory', function(source, limit)
    if not isAdmin(source) then
        return nil
    end
    
    limit = limit or 10
    
    local history = MySQL.query.await([[
        SELECT 
            l.id,
            l.test_type,
            l.player_name,
            l.iterations,
            l.threads,
            l.interval_ms,
            l.status,
            l.started_at,
            l.completed_at,
            r.queries_executed,
            r.queries_success,
            r.queries_failed,
            r.avg_response_time,
            r.total_time
        FROM `ng_dbstress_logs` l
        LEFT JOIN `ng_dbstress_results` r ON l.id = r.log_id
        ORDER BY l.started_at DESC
        LIMIT ?
    ]], { limit })
    
    return history or {}
end)

-- コマンド登録
QBCore.Commands.Add(Config.Command, '管理者向けDBストレステストメニューを開く', {}, false, function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    if not isAdmin(source) then
        TriggerClientEvent('ox_lib:notify', source, Config.Notifications.noPermission)
        return
    end
    
    TriggerClientEvent('ng-dbstress:client:openMenu', source)
end, 'admin')

-- リソース起動メッセージ
CreateThread(function()
    Wait(1000)
    print('^2========================================^7')
    print('^2[ng-dbstress]^7 DBストレステストツール 起動完了')
    print('^2[ng-dbstress]^7 作成者: NCCGr')
    print('^2[ng-dbstress]^7 コマンド: /' .. Config.Command)
    print('^2[ng-dbstress]^7 バージョン: 1.0.0')
    print('^2========================================^7')
end)

-- リソース停止時の処理
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- 実行中のテストをすべて停止
    for testId, state in pairs(TestStates) do
        if state.running then
            StopTest(testId)
        end
    end
    
    if Config.Debug then
        print('^3[ng-dbstress]^7 リソースを停止しました')
    end
end)
