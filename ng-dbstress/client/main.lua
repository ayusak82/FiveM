-- QBCore初期化
local QBCore = exports['qb-core']:GetCoreObject()

-- グローバル変数
local currentTestId = nil
local isTestRunning = false
local currentMenu = nil

-- 管理者権限チェック関数
local function isAdmin()
    return lib.callback.await('ng-dbstress:server:isAdmin', false)
end

-- メインメニュー表示
local function openMainMenu()
    local options = {}
    
    -- 統計情報取得
    local stats = lib.callback.await('ng-dbstress:server:getStatistics', false)
    
    if stats then
        table.insert(options, {
            title = '📊 統計情報',
            description = string.format('総テスト数: %d | 完了: %d | 実行中: %d\n総クエリ数: %d | 平均応答時間: %.2fms',
                stats.totalTests, stats.completedTests, stats.runningTests, stats.totalQueries, stats.avgResponseTime),
            icon = 'chart-line',
            disabled = true
        })
        
        table.insert(options, {
            title = '────────────────',
            disabled = true
        })
    end
    
    -- テスト選択メニュー
    table.insert(options, {
        title = '🚀 負荷テストを開始',
        description = 'テストの種類を選択してください',
        icon = 'play',
        onSelect = function()
            openTestSelectionMenu()
        end
    })
    
    table.insert(options, {
        title = '📜 テスト履歴',
        description = '過去のテスト結果を表示',
        icon = 'history',
        onSelect = function()
            openTestHistoryMenu()
        end
    })
    
    table.insert(options, {
        title = '🧹 データクリーンアップ',
        description = 'テストデータを削除してリセット',
        icon = 'trash',
        onSelect = function()
            openCleanupConfirmation()
        end
    })
    
    lib.registerContext({
        id = 'ng_dbstress_main',
        title = '🗄️ DBストレステストツール',
        options = options
    })
    
    lib.showContext('ng_dbstress_main')
    currentMenu = 'main'
end

-- テスト選択メニュー
function openTestSelectionMenu()
    local options = {}
    
    for _, testType in ipairs(Config.TestTypes) do
        table.insert(options, {
            title = testType.label,
            description = testType.description,
            icon = 'flask',
            onSelect = function()
                openTestSettingsMenu(testType.id)
            end
        })
    end
    
    table.insert(options, {
        title = '⬅️ 戻る',
        icon = 'arrow-left',
        onSelect = function()
            openMainMenu()
        end
    })
    
    lib.registerContext({
        id = 'ng_dbstress_test_selection',
        title = '📝 テストタイプ選択',
        options = options
    })
    
    lib.showContext('ng_dbstress_test_selection')
    currentMenu = 'test_selection'
end

-- テスト設定メニュー
function openTestSettingsMenu(testType)
    local settings = {
        iterations = Config.DefaultSettings.iterations,
        interval = Config.DefaultSettings.interval,
        threads = Config.DefaultSettings.threads
    }
    
    local function updateAndShow()
        local options = {
            {
                title = '🔢 実行回数: ' .. settings.iterations,
                description = 'テストを実行する回数を設定',
                icon = 'hashtag',
                onSelect = function()
                    local iterOptions = {}
                    for _, opt in ipairs(Config.IterationOptions) do
                        table.insert(iterOptions, {
                            title = opt.label,
                            onSelect = function()
                                if opt.value == 'custom' then
                                    local input = lib.inputDialog('カスタム実行回数', {
                                        {type = 'number', label = '実行回数', description = '1～1000000', required = true, min = 1, max = 1000000}
                                    })
                                    if input then
                                        settings.iterations = input[1]
                                    end
                                else
                                    settings.iterations = opt.value
                                end
                                updateAndShow()
                            end
                        })
                    end
                    
                    lib.registerContext({
                        id = 'ng_dbstress_iterations',
                        title = '実行回数選択',
                        menu = 'ng_dbstress_settings',
                        options = iterOptions
                    })
                    lib.showContext('ng_dbstress_iterations')
                end
            },
            {
                title = '⏱️ 実行間隔: ' .. (settings.interval == 0 and '間隔なし' or settings.interval .. 'ms'),
                description = 'クエリ間の待機時間を設定',
                icon = 'clock',
                onSelect = function()
                    local intervalOptions = {}
                    for _, opt in ipairs(Config.IntervalOptions) do
                        table.insert(intervalOptions, {
                            title = opt.label,
                            onSelect = function()
                                if opt.value == 'custom' then
                                    local input = lib.inputDialog('カスタム間隔', {
                                        {type = 'number', label = '間隔(ミリ秒)', description = '0～10000', required = true, min = 0, max = 10000}
                                    })
                                    if input then
                                        settings.interval = input[1]
                                    end
                                else
                                    settings.interval = opt.value
                                end
                                updateAndShow()
                            end
                        })
                    end
                    
                    lib.registerContext({
                        id = 'ng_dbstress_interval',
                        title = '実行間隔選択',
                        menu = 'ng_dbstress_settings',
                        options = intervalOptions
                    })
                    lib.showContext('ng_dbstress_interval')
                end
            },
            {
                title = '🔀 同時実行数: ' .. settings.threads,
                description = '同時に実行するスレッド数を設定',
                icon = 'layer-group',
                onSelect = function()
                    local threadOptions = {}
                    for _, opt in ipairs(Config.ThreadOptions) do
                        table.insert(threadOptions, {
                            title = opt.label,
                            onSelect = function()
                                if opt.value == 'custom' then
                                    local input = lib.inputDialog('カスタムスレッド数', {
                                        {type = 'number', label = 'スレッド数', description = '1～200', required = true, min = 1, max = 200}
                                    })
                                    if input then
                                        settings.threads = input[1]
                                    end
                                else
                                    settings.threads = opt.value
                                end
                                updateAndShow()
                            end
                        })
                    end
                    
                    lib.registerContext({
                        id = 'ng_dbstress_threads',
                        title = '同時実行数選択',
                        menu = 'ng_dbstress_settings',
                        options = threadOptions
                    })
                    lib.showContext('ng_dbstress_threads')
                end
            },
            {
                title = '────────────────',
                disabled = true
            },
            {
                title = '✅ テスト開始',
                description = '設定した内容でテストを実行',
                icon = 'play-circle',
                onSelect = function()
                    startTest(testType, settings)
                end
            },
            {
                title = '⬅️ 戻る',
                icon = 'arrow-left',
                onSelect = function()
                    openTestSelectionMenu()
                end
            }
        }
        
        lib.registerContext({
            id = 'ng_dbstress_settings',
            title = '⚙️ テスト設定',
            options = options
        })
        
        lib.showContext('ng_dbstress_settings')
        currentMenu = 'settings'
    end
    
    updateAndShow()
end

-- テスト開始処理
function startTest(testType, settings)
    if isTestRunning then
        lib.notify(Config.Notifications.testError)
        return
    end
    
    -- 確認ダイアログ
    local alert = lib.alertDialog({
        header = '⚠️ 確認',
        content = string.format('このテストはデータベースに高負荷をかけます。\n\nテスト: %s\n実行回数: %d\n間隔: %dms\nスレッド数: %d\n\n本当に実行しますか?',
            testType, settings.iterations, settings.interval, settings.threads),
        centered = true,
        cancel = true
    })
    
    if alert ~= 'confirm' then return end
    
    isTestRunning = true
    
    -- プログレスバー表示
    lib.progressCircle({
        duration = 1000,
        label = 'テストを開始しています...',
        position = 'bottom',
        useWhileDead = false,
        canCancel = false
    })
    
    -- サーバーにテスト開始リクエスト
    local result = lib.callback.await('ng-dbstress:server:startTest', false, testType, settings)
    
    if result and result.success then
        currentTestId = result.testId
        
        lib.notify(Config.Notifications.testStarted)
        
        if result.isAllTests then
            -- 全テスト実行の場合
            TriggerServerEvent('ng-dbstress:server:runAllTests', settings)
        end
        
        -- テスト実行中メニューを表示
        openTestRunningMenu(testType)
    else
        isTestRunning = false
        local errorNotif = Config.Notifications.testError
        errorNotif.description = result.message or 'テストの開始に失敗しました'
        lib.notify(errorNotif)
    end
end

-- テスト実行中メニュー
function openTestRunningMenu(testType)
    local options = {
        {
            title = '⏳ テスト実行中...',
            description = 'テストタイプ: ' .. testType,
            icon = 'spinner',
            iconAnimation = 'spin',
            disabled = true
        },
        {
            title = '────────────────',
            disabled = true
        },
        {
            title = '⏹️ テストを停止',
            description = '実行中のテストを強制停止',
            icon = 'stop-circle',
            onSelect = function()
                stopTest()
            end
        }
    }
    
    lib.registerContext({
        id = 'ng_dbstress_running',
        title = '🔄 テスト実行中',
        options = options
    })
    
    lib.showContext('ng_dbstress_running')
    currentMenu = 'running'
end

-- テスト停止処理
function stopTest()
    if not currentTestId then return end
    
    local alert = lib.alertDialog({
        header = '⚠️ 確認',
        content = 'テストを停止しますか?\n\n※実行中の処理は完了まで継続されます',
        centered = true,
        cancel = true
    })
    
    if alert ~= 'confirm' then return end
    
    local result = lib.callback.await('ng-dbstress:server:stopTest', false, currentTestId)
    
    if result and result.success then
        lib.notify(Config.Notifications.testStopped)
    end
end

-- テスト履歴メニュー
function openTestHistoryMenu()
    local history = lib.callback.await('ng-dbstress:server:getTestHistory', false, 20)
    
    if not history or #history == 0 then
        lib.notify({
            title = 'テスト履歴',
            description = '履歴がありません',
            type = 'info'
        })
        openMainMenu()
        return
    end
    
    local options = {}
    
    for _, record in ipairs(history) do
        local statusIcon = '✅'
        if record.status == 'running' then
            statusIcon = '⏳'
        elseif record.status == 'stopped' then
            statusIcon = '⏹️'
        elseif record.status == 'error' then
            statusIcon = '❌'
        end
        
        local description = string.format('%s | 実行者: %s\n実行: %d | 成功: %d | 失敗: %d',
            record.started_at or 'N/A',
            record.player_name or 'Unknown',
            record.queries_executed or 0,
            record.queries_success or 0,
            record.queries_failed or 0
        )
        
        if record.avg_response_time then
            description = description .. string.format('\n平均応答時間: %.2fms', record.avg_response_time)
        end
        
        table.insert(options, {
            title = statusIcon .. ' ' .. (record.test_type or 'unknown'),
            description = description,
            icon = 'file-alt'
        })
    end
    
    table.insert(options, {
        title = '⬅️ 戻る',
        icon = 'arrow-left',
        onSelect = function()
            openMainMenu()
        end
    })
    
    lib.registerContext({
        id = 'ng_dbstress_history',
        title = '📜 テスト履歴',
        options = options
    })
    
    lib.showContext('ng_dbstress_history')
    currentMenu = 'history'
end

-- クリーンアップ確認
function openCleanupConfirmation()
    local alert = lib.alertDialog({
        header = '⚠️ 警告',
        content = 'すべてのテストデータと履歴を削除します。\n\nこの操作は元に戻せません。\n本当に実行しますか?',
        centered = true,
        cancel = true
    })
    
    if alert ~= 'confirm' then
        openMainMenu()
        return
    end
    
    lib.progressCircle({
        duration = 2000,
        label = 'データをクリーンアップ中...',
        position = 'bottom',
        useWhileDead = false,
        canCancel = false
    })
    
    local result = lib.callback.await('ng-dbstress:server:cleanupData', false)
    
    if result and result.success then
        lib.notify({
            title = 'クリーンアップ',
            description = 'データを正常にクリーンアップしました',
            type = 'success'
        })
    else
        lib.notify({
            title = 'エラー',
            description = 'クリーンアップに失敗しました',
            type = 'error'
        })
    end
    
    openMainMenu()
end

-- メニューオープンイベント
RegisterNetEvent('ng-dbstress:client:openMenu', function()
    CreateThread(function()
        if not isAdmin() then
            lib.notify(Config.Notifications.noPermission)
            return
        end
        
        openMainMenu()
    end)
end)

-- 進捗更新イベント
RegisterNetEvent('ng-dbstress:client:updateProgress', function(data)
    if currentMenu == 'running' then
        local options = {
            {
                title = '⏳ テスト実行中...',
                description = string.format('進捗: %d / %d (%d%%)', data.current, data.total, data.percentage),
                icon = 'spinner',
                iconAnimation = 'spin',
                disabled = true
            },
            {
                title = '────────────────',
                disabled = true
            },
            {
                title = '⏹️ テストを停止',
                description = '実行中のテストを強制停止',
                icon = 'stop-circle',
                onSelect = function()
                    stopTest()
                end
            }
        }
        
        lib.registerContext({
            id = 'ng_dbstress_running',
            title = '🔄 テスト実行中',
            options = options
        })
    end
end)

-- テスト完了イベント
RegisterNetEvent('ng-dbstress:client:testCompleted', function(data)
    isTestRunning = false
    currentTestId = nil
    
    local notif = Config.Notifications.testCompleted
    notif.description = string.format('実行: %d | 成功: %d | 失敗: %d\n平均応答時間: %.2fms',
        data.stats.executed, data.stats.success, data.stats.failed, data.stats.avgTime)
    lib.notify(notif)
    
    if currentMenu == 'running' then
        openMainMenu()
    end
end)

-- テスト停止イベント
RegisterNetEvent('ng-dbstress:client:testStopped', function(testId)
    isTestRunning = false
    currentTestId = nil
    
    if currentMenu == 'running' then
        openMainMenu()
    end
end)

-- 全テスト進捗イベント
RegisterNetEvent('ng-dbstress:client:allTestsProgress', function(data)
    if currentMenu == 'running' then
        local options = {
            {
                title = '⏳ 全テスト実行中...',
                description = string.format('現在のテスト: %s\n進捗: %d / %d', data.currentTest, data.testNumber, data.totalTests),
                icon = 'spinner',
                iconAnimation = 'spin',
                disabled = true
            },
            {
                title = '────────────────',
                disabled = true
            },
            {
                title = '⏹️ テストを停止',
                description = '実行中のテストを強制停止',
                icon = 'stop-circle',
                onSelect = function()
                    stopTest()
                end
            }
        }
        
        lib.registerContext({
            id = 'ng_dbstress_running',
            title = '🔄 全テスト実行中',
            options = options
        })
    end
end)

-- 全テスト完了イベント
RegisterNetEvent('ng-dbstress:client:allTestsCompleted', function(results)
    isTestRunning = false
    currentTestId = nil
    
    local totalExecuted = 0
    local totalSuccess = 0
    local totalFailed = 0
    
    for _, result in ipairs(results) do
        totalExecuted = totalExecuted + result.stats.executed
        totalSuccess = totalSuccess + result.stats.success
        totalFailed = totalFailed + result.stats.failed
    end
    
    lib.notify({
        title = '全テスト完了',
        description = string.format('全テストが完了しました\n\n総実行: %d | 成功: %d | 失敗: %d',
            totalExecuted, totalSuccess, totalFailed),
        type = 'success',
        duration = 8000
    })
    
    if currentMenu == 'running' then
        openMainMenu()
    end
end)

-- デバッグ用コマンド（開発時のみ）
if Config.Debug then
    RegisterCommand('dbstress_debug', function()
        print('Current Test ID:', currentTestId)
        print('Is Test Running:', isTestRunning)
        print('Current Menu:', currentMenu)
    end, false)
end
