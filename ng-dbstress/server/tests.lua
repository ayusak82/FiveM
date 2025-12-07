-- 負荷テスト実行関数群

-- グローバルテスト状態管理
TestStates = {}

-- ランダム文字列生成
local function generateRandomString(length)
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
    local result = ''
    for i = 1, length do
        local rand = math.random(1, #chars)
        result = result .. chars:sub(rand, rand)
    end
    return result
end

-- ランダムJSON生成
local function generateRandomJson()
    return json.encode({
        id = math.random(1, 100000),
        data = generateRandomString(50),
        timestamp = os.time(),
        nested = {
            value1 = math.random(1, 1000),
            value2 = generateRandomString(20),
            array = {math.random(), math.random(), math.random()}
        }
    })
end

-- 実行時間計測
local function measureTime(func)
    local startTime = os.clock()
    local success, result = pcall(func)
    local endTime = os.clock()
    local duration = (endTime - startTime) * 1000 -- ミリ秒
    return success, result, duration
end

-- 統計情報更新
local function updateStats(stats, success, duration, error)
    stats.executed = stats.executed + 1
    
    if success then
        stats.success = stats.success + 1
        stats.totalTime = stats.totalTime + duration
        
        if stats.minTime == 0 or duration < stats.minTime then
            stats.minTime = duration
        end
        if duration > stats.maxTime then
            stats.maxTime = duration
        end
    else
        stats.failed = stats.failed + 1
        if error then
            table.insert(stats.errors, error)
        end
    end
    
    stats.avgTime = stats.totalTime / stats.success
end

-- INSERT テスト
function RunInsertTest(testId, settings, source)
    local stats = {
        executed = 0,
        success = 0,
        failed = 0,
        totalTime = 0,
        minTime = 0,
        maxTime = 0,
        avgTime = 0,
        errors = {}
    }
    
    TestStates[testId] = { running = true, stats = stats }
    
    CreateThread(function()
        for i = 1, settings.iterations do
            if not TestStates[testId] or not TestStates[testId].running then
                break
            end
            
            local success, result, duration = measureTime(function()
                return MySQL.insert.await([[
                    INSERT INTO `ng_dbstress_test` 
                    (`test_string`, `test_int`, `test_float`, `test_json`) 
                    VALUES (?, ?, ?, ?)
                ]], {
                    generateRandomString(Config.TestData.stringLength),
                    math.random(1, 100000),
                    math.random() * 1000,
                    generateRandomJson()
                })
            end)
            
            updateStats(stats, success, duration, result)
            
            -- 進捗通知（10%ごと）
            if i % math.max(1, math.floor(settings.iterations / 10)) == 0 then
                TriggerClientEvent('ng-dbstress:client:updateProgress', source, {
                    current = i,
                    total = settings.iterations,
                    percentage = math.floor((i / settings.iterations) * 100)
                })
            end
            
            if settings.interval > 0 then
                Wait(settings.interval)
            end
        end
        
        TestStates[testId].running = false
        TestStates[testId].completed = true
    end)
    
    return stats
end

-- SELECT テスト
function RunSelectTest(testId, settings, source)
    local stats = {
        executed = 0,
        success = 0,
        failed = 0,
        totalTime = 0,
        minTime = 0,
        maxTime = 0,
        avgTime = 0,
        errors = {}
    }
    
    TestStates[testId] = { running = true, stats = stats }
    
    CreateThread(function()
        for i = 1, settings.iterations do
            if not TestStates[testId] or not TestStates[testId].running then
                break
            end
            
            local success, result, duration = measureTime(function()
                return MySQL.query.await('SELECT * FROM `ng_dbstress_test` ORDER BY RAND() LIMIT 100')
            end)
            
            updateStats(stats, success, duration, result)
            
            if i % math.max(1, math.floor(settings.iterations / 10)) == 0 then
                TriggerClientEvent('ng-dbstress:client:updateProgress', source, {
                    current = i,
                    total = settings.iterations,
                    percentage = math.floor((i / settings.iterations) * 100)
                })
            end
            
            if settings.interval > 0 then
                Wait(settings.interval)
            end
        end
        
        TestStates[testId].running = false
        TestStates[testId].completed = true
    end)
    
    return stats
end

-- UPDATE テスト
function RunUpdateTest(testId, settings, source)
    local stats = {
        executed = 0,
        success = 0,
        failed = 0,
        totalTime = 0,
        minTime = 0,
        maxTime = 0,
        avgTime = 0,
        errors = {}
    }
    
    TestStates[testId] = { running = true, stats = stats }
    
    CreateThread(function()
        for i = 1, settings.iterations do
            if not TestStates[testId] or not TestStates[testId].running then
                break
            end
            
            local success, result, duration = measureTime(function()
                return MySQL.update.await([[
                    UPDATE `ng_dbstress_test` 
                    SET `test_string` = ?, `test_int` = ?, `test_float` = ?, `test_json` = ? 
                    WHERE `id` = (SELECT `id` FROM (SELECT `id` FROM `ng_dbstress_test` ORDER BY RAND() LIMIT 1) as temp)
                ]], {
                    generateRandomString(Config.TestData.stringLength),
                    math.random(1, 100000),
                    math.random() * 1000,
                    generateRandomJson()
                })
            end)
            
            updateStats(stats, success, duration, result)
            
            if i % math.max(1, math.floor(settings.iterations / 10)) == 0 then
                TriggerClientEvent('ng-dbstress:client:updateProgress', source, {
                    current = i,
                    total = settings.iterations,
                    percentage = math.floor((i / settings.iterations) * 100)
                })
            end
            
            if settings.interval > 0 then
                Wait(settings.interval)
            end
        end
        
        TestStates[testId].running = false
        TestStates[testId].completed = true
    end)
    
    return stats
end

-- DELETE テスト
function RunDeleteTest(testId, settings, source)
    local stats = {
        executed = 0,
        success = 0,
        failed = 0,
        totalTime = 0,
        minTime = 0,
        maxTime = 0,
        avgTime = 0,
        errors = {}
    }
    
    TestStates[testId] = { running = true, stats = stats }
    
    CreateThread(function()
        -- 削除用のデータを事前に大量挿入
        for j = 1, settings.iterations do
            MySQL.insert.await([[
                INSERT INTO `ng_dbstress_test` 
                (`test_string`, `test_int`, `test_float`) 
                VALUES (?, ?, ?)
            ]], {
                'DELETE_TEST_' .. j,
                j,
                math.random() * 100
            })
        end
        
        Wait(500)
        
        for i = 1, settings.iterations do
            if not TestStates[testId] or not TestStates[testId].running then
                break
            end
            
            local success, result, duration = measureTime(function()
                return MySQL.query.await([[
                    DELETE FROM `ng_dbstress_test` 
                    WHERE `id` = (SELECT `id` FROM (SELECT `id` FROM `ng_dbstress_test` WHERE `test_string` LIKE 'DELETE_TEST_%' LIMIT 1) as temp)
                ]])
            end)
            
            updateStats(stats, success, duration, result)
            
            if i % math.max(1, math.floor(settings.iterations / 10)) == 0 then
                TriggerClientEvent('ng-dbstress:client:updateProgress', source, {
                    current = i,
                    total = settings.iterations,
                    percentage = math.floor((i / settings.iterations) * 100)
                })
            end
            
            if settings.interval > 0 then
                Wait(settings.interval)
            end
        end
        
        TestStates[testId].running = false
        TestStates[testId].completed = true
    end)
    
    return stats
end

-- JOIN テスト（重いクエリ）
function RunJoinTest(testId, settings, source)
    local stats = {
        executed = 0,
        success = 0,
        failed = 0,
        totalTime = 0,
        minTime = 0,
        maxTime = 0,
        avgTime = 0,
        errors = {}
    }
    
    TestStates[testId] = { running = true, stats = stats }
    
    CreateThread(function()
        for i = 1, settings.iterations do
            if not TestStates[testId] or not TestStates[testId].running then
                break
            end
            
            local success, result, duration = measureTime(function()
                return MySQL.query.await([[
                    SELECT 
                        t1.*, 
                        t2.test_string as related_string,
                        COUNT(t3.id) as related_count
                    FROM `ng_dbstress_test` t1
                    LEFT JOIN `ng_dbstress_test` t2 ON t1.test_int = t2.test_int
                    LEFT JOIN `ng_dbstress_test` t3 ON t2.id = t3.id
                    WHERE t1.test_int > ?
                    GROUP BY t1.id, t2.test_string
                    ORDER BY t1.created_at DESC
                    LIMIT 50
                ]], { math.random(1, 50000) })
            end)
            
            updateStats(stats, success, duration, result)
            
            if i % math.max(1, math.floor(settings.iterations / 10)) == 0 then
                TriggerClientEvent('ng-dbstress:client:updateProgress', source, {
                    current = i,
                    total = settings.iterations,
                    percentage = math.floor((i / settings.iterations) * 100)
                })
            end
            
            if settings.interval > 0 then
                Wait(settings.interval)
            end
        end
        
        TestStates[testId].running = false
        TestStates[testId].completed = true
    end)
    
    return stats
end

-- トランザクション テスト
function RunTransactionTest(testId, settings, source)
    local stats = {
        executed = 0,
        success = 0,
        failed = 0,
        totalTime = 0,
        minTime = 0,
        maxTime = 0,
        avgTime = 0,
        errors = {}
    }
    
    TestStates[testId] = { running = true, stats = stats }
    
    CreateThread(function()
        for i = 1, settings.iterations do
            if not TestStates[testId] or not TestStates[testId].running then
                break
            end
            
            local success, result, duration = measureTime(function()
                return MySQL.transaction.await({
                    { query = 'INSERT INTO `ng_dbstress_test` (`test_string`, `test_int`) VALUES (?, ?)', values = { 'TRANS_' .. i, i } },
                    { query = 'UPDATE `ng_dbstress_test` SET `test_float` = ? WHERE `test_string` = ?', values = { math.random() * 100, 'TRANS_' .. i } },
                    { query = 'SELECT * FROM `ng_dbstress_test` WHERE `test_string` = ?', values = { 'TRANS_' .. i } }
                })
            end)
            
            updateStats(stats, success, duration, result)
            
            if i % math.max(1, math.floor(settings.iterations / 10)) == 0 then
                TriggerClientEvent('ng-dbstress:client:updateProgress', source, {
                    current = i,
                    total = settings.iterations,
                    percentage = math.floor((i / settings.iterations) * 100)
                })
            end
            
            if settings.interval > 0 then
                Wait(settings.interval)
            end
        end
        
        TestStates[testId].running = false
        TestStates[testId].completed = true
    end)
    
    return stats
end

-- 同時実行テスト
function RunConcurrentTest(testId, settings, source)
    local stats = {
        executed = 0,
        success = 0,
        failed = 0,
        totalTime = 0,
        minTime = 0,
        maxTime = 0,
        avgTime = 0,
        errors = {}
    }
    
    TestStates[testId] = { running = true, stats = stats }
    
    local iterationsPerThread = math.floor(settings.iterations / settings.threads)
    local completedThreads = 0
    
    for thread = 1, settings.threads do
        CreateThread(function()
            for i = 1, iterationsPerThread do
                if not TestStates[testId] or not TestStates[testId].running then
                    break
                end
                
                -- ランダムにクエリタイプを選択
                local queryType = math.random(1, 4)
                local success, result, duration
                
                if queryType == 1 then
                    -- INSERT
                    success, result, duration = measureTime(function()
                        return MySQL.insert.await('INSERT INTO `ng_dbstress_test` (`test_string`, `test_int`) VALUES (?, ?)', 
                            { 'CONCURRENT_' .. thread .. '_' .. i, math.random(1, 10000) })
                    end)
                elseif queryType == 2 then
                    -- SELECT
                    success, result, duration = measureTime(function()
                        return MySQL.query.await('SELECT * FROM `ng_dbstress_test` ORDER BY RAND() LIMIT 10')
                    end)
                elseif queryType == 3 then
                    -- UPDATE
                    success, result, duration = measureTime(function()
                        return MySQL.update.await('UPDATE `ng_dbstress_test` SET `test_int` = ? WHERE `id` = (SELECT `id` FROM (SELECT `id` FROM `ng_dbstress_test` ORDER BY RAND() LIMIT 1) as temp)', 
                            { math.random(1, 10000) })
                    end)
                else
                    -- DELETE
                    success, result, duration = measureTime(function()
                        return MySQL.query.await('DELETE FROM `ng_dbstress_test` WHERE `test_string` LIKE "CONCURRENT_%" LIMIT 1')
                    end)
                end
                
                updateStats(stats, success, duration, result)
                
                if settings.interval > 0 then
                    Wait(settings.interval)
                end
            end
            
            completedThreads = completedThreads + 1
            
            if completedThreads >= settings.threads then
                TestStates[testId].running = false
                TestStates[testId].completed = true
            end
        end)
    end
    
    -- 進捗モニタリング
    CreateThread(function()
        local lastProgress = 0
        while TestStates[testId] and TestStates[testId].running do
            local currentProgress = math.floor((stats.executed / settings.iterations) * 100)
            if currentProgress ~= lastProgress and currentProgress % 10 == 0 then
                TriggerClientEvent('ng-dbstress:client:updateProgress', source, {
                    current = stats.executed,
                    total = settings.iterations,
                    percentage = currentProgress
                })
                lastProgress = currentProgress
            end
            Wait(1000)
        end
    end)
    
    return stats
end

-- テスト停止
function StopTest(testId)
    if TestStates[testId] then
        TestStates[testId].running = false
        return true
    end
    return false
end

-- テスト状態取得
function GetTestState(testId)
    return TestStates[testId]
end
