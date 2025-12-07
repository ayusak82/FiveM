-- データベース初期化処理

-- テーブル作成関数
local function createTables()
    -- メインテストテーブル
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `ng_dbstress_test` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `test_string` VARCHAR(255) NOT NULL,
            `test_int` INT NOT NULL DEFAULT 0,
            `test_float` FLOAT NOT NULL DEFAULT 0.0,
            `test_json` LONGTEXT NULL,
            `test_blob` BLOB NULL,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX `idx_test_int` (`test_int`),
            INDEX `idx_created_at` (`created_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    -- テスト実行ログテーブル
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `ng_dbstress_logs` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `test_type` VARCHAR(50) NOT NULL,
            `player_id` VARCHAR(50) NOT NULL,
            `player_name` VARCHAR(100) NOT NULL,
            `iterations` INT NOT NULL DEFAULT 0,
            `threads` INT NOT NULL DEFAULT 1,
            `interval_ms` INT NOT NULL DEFAULT 0,
            `status` ENUM('running', 'completed', 'stopped', 'error') DEFAULT 'running',
            `started_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            `completed_at` TIMESTAMP NULL,
            INDEX `idx_test_type` (`test_type`),
            INDEX `idx_player_id` (`player_id`),
            INDEX `idx_status` (`status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    -- テスト結果テーブル
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `ng_dbstress_results` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `log_id` INT NOT NULL,
            `query_type` VARCHAR(50) NOT NULL,
            `queries_executed` INT NOT NULL DEFAULT 0,
            `queries_success` INT NOT NULL DEFAULT 0,
            `queries_failed` INT NOT NULL DEFAULT 0,
            `avg_response_time` FLOAT NOT NULL DEFAULT 0.0,
            `min_response_time` FLOAT NOT NULL DEFAULT 0.0,
            `max_response_time` FLOAT NOT NULL DEFAULT 0.0,
            `total_time` FLOAT NOT NULL DEFAULT 0.0,
            `error_messages` LONGTEXT NULL,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (`log_id`) REFERENCES `ng_dbstress_logs`(`id`) ON DELETE CASCADE,
            INDEX `idx_log_id` (`log_id`),
            INDEX `idx_query_type` (`query_type`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    if Config.Debug then
        print('^2[ng-dbstress]^7 データベーステーブルを初期化しました')
    end
end

-- サンプルデータ挿入関数
local function insertSampleData()
    local count = MySQL.scalar.await('SELECT COUNT(*) FROM `ng_dbstress_test`')
    
    if count == 0 then
        for i = 1, 100 do
            local jsonData = json.encode({
                id = i,
                data = 'sample_' .. i,
                nested = {
                    value1 = math.random(1, 1000),
                    value2 = 'test_' .. i
                }
            })
            
            MySQL.insert.await([[
                INSERT INTO `ng_dbstress_test` 
                (`test_string`, `test_int`, `test_float`, `test_json`) 
                VALUES (?, ?, ?, ?)
            ]], {
                'Sample Data ' .. i,
                math.random(1, 1000),
                math.random() * 100,
                jsonData
            })
        end
        
        if Config.Debug then
            print('^2[ng-dbstress]^7 サンプルデータを100件挿入しました')
        end
    end
end

-- データベース初期化
CreateThread(function()
    createTables()
    Wait(1000)
    insertSampleData()
end)

-- テストデータクリーンアップ関数
function CleanupTestData()
    MySQL.query.await('TRUNCATE TABLE `ng_dbstress_results`')
    MySQL.query.await('TRUNCATE TABLE `ng_dbstress_logs`')
    MySQL.query.await('TRUNCATE TABLE `ng_dbstress_test`')
    
    -- サンプルデータを再挿入
    insertSampleData()
    
    if Config.Debug then
        print('^2[ng-dbstress]^7 テストデータをクリーンアップしました')
    end
    
    return true
end

-- テストログ作成関数
function CreateTestLog(source, testType, settings)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return nil end
    
    local result = MySQL.insert.await([[
        INSERT INTO `ng_dbstress_logs` 
        (`test_type`, `player_id`, `player_name`, `iterations`, `threads`, `interval_ms`, `status`) 
        VALUES (?, ?, ?, ?, ?, ?, 'running')
    ]], {
        testType,
        Player.PlayerData.citizenid,
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        settings.iterations,
        settings.threads,
        settings.interval
    })
    
    return result
end

-- テストログ更新関数
function UpdateTestLog(logId, status)
    MySQL.update.await([[
        UPDATE `ng_dbstress_logs` 
        SET `status` = ?, `completed_at` = CURRENT_TIMESTAMP 
        WHERE `id` = ?
    ]], { status, logId })
end

-- テスト結果保存関数
function SaveTestResult(logId, queryType, stats)
    local errorMessages = nil
    if stats.errors and #stats.errors > 0 then
        errorMessages = json.encode(stats.errors)
    end
    
    MySQL.insert.await([[
        INSERT INTO `ng_dbstress_results` 
        (`log_id`, `query_type`, `queries_executed`, `queries_success`, `queries_failed`, 
         `avg_response_time`, `min_response_time`, `max_response_time`, `total_time`, `error_messages`) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        logId,
        queryType,
        stats.executed or 0,
        stats.success or 0,
        stats.failed or 0,
        stats.avgTime or 0.0,
        stats.minTime or 0.0,
        stats.maxTime or 0.0,
        stats.totalTime or 0.0,
        errorMessages
    })
end

-- 統計情報取得関数
function GetTestStatistics()
    local totalTests = MySQL.scalar.await('SELECT COUNT(*) FROM `ng_dbstress_logs`') or 0
    local completedTests = MySQL.scalar.await('SELECT COUNT(*) FROM `ng_dbstress_logs` WHERE `status` = "completed"') or 0
    local runningTests = MySQL.scalar.await('SELECT COUNT(*) FROM `ng_dbstress_logs` WHERE `status` = "running"') or 0
    local totalQueries = MySQL.scalar.await('SELECT SUM(`queries_executed`) FROM `ng_dbstress_results`') or 0
    local avgResponseTime = MySQL.scalar.await('SELECT AVG(`avg_response_time`) FROM `ng_dbstress_results`') or 0.0
    
    return {
        totalTests = totalTests,
        completedTests = completedTests,
        runningTests = runningTests,
        totalQueries = totalQueries,
        avgResponseTime = math.floor(avgResponseTime * 100) / 100
    }
end
