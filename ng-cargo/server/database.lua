local QBCore = exports['qb-core']:GetCoreObject()

-- ============================================
-- データベース初期化
-- ============================================
CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS cargo_stats (
            identifier VARCHAR(50) PRIMARY KEY,
            total_deliveries INT DEFAULT 0,
            successful_deliveries INT DEFAULT 0,
            total_earned INT DEFAULT 0,
            experience INT DEFAULT 0,
            level INT DEFAULT 1,
            best_time INT DEFAULT 0,
            last_delivery TIMESTAMP NULL DEFAULT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ]])
    
    if Config.Debug then
        print('[ng-cargo] Database table initialized')
    end
end)

-- ============================================
-- プレイヤー統計取得
-- ============================================
function GetPlayerStats(citizenid, cb)
    MySQL.query('SELECT * FROM cargo_stats WHERE identifier = ?', {citizenid}, function(result)
        if result and result[1] then
            cb(result[1])
        else
            -- 新規プレイヤー: 初期データ作成
            MySQL.insert('INSERT INTO cargo_stats (identifier, level) VALUES (?, 1)', {citizenid}, function(id)
                cb({
                    identifier = citizenid,
                    total_deliveries = 0,
                    successful_deliveries = 0,
                    total_earned = 0,
                    experience = 0,
                    level = 1,
                    best_time = 0,
                    last_delivery = nil
                })
            end)
        end
    end)
end

-- ============================================
-- プレイヤー統計更新
-- ============================================
function UpdatePlayerStats(source, success, earned, experience, completionTime, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    GetPlayerStats(citizenid, function(currentStats)
        -- 新しい統計計算
        local newTotalDeliveries = currentStats.total_deliveries + 1
        local newSuccessfulDeliveries = currentStats.successful_deliveries + (success and 1 or 0)
        local newTotalEarned = currentStats.total_earned + earned
        local newExperience = currentStats.experience + experience
        
        -- レベル計算
        local newLevel = math.floor(newExperience / Config.LevelSystem.experiencePerLevel) + 1
        if newLevel > Config.LevelSystem.maxLevel then
            newLevel = Config.LevelSystem.maxLevel
        end
        
        -- 最速記録更新
        local newBestTime = currentStats.best_time
        if success and (currentStats.best_time == 0 or completionTime < currentStats.best_time) then
            newBestTime = completionTime
        end
        
        -- データベース更新
        MySQL.update([[
            UPDATE cargo_stats SET
                total_deliveries = ?,
                successful_deliveries = ?,
                total_earned = ?,
                experience = ?,
                level = ?,
                best_time = ?,
                last_delivery = NOW()
            WHERE identifier = ?
        ]], {
            newTotalDeliveries,
            newSuccessfulDeliveries,
            newTotalEarned,
            newExperience,
            newLevel,
            newBestTime,
            citizenid
        }, function(affectedRows)
            if Config.Debug then
                print(string.format('[ng-cargo] Stats updated for %s: Level %d, XP %d', citizenid, newLevel, newExperience))
            end
            
            -- 更新後の統計を返す
            if cb then
                cb({
                    identifier = citizenid,
                    total_deliveries = newTotalDeliveries,
                    successful_deliveries = newSuccessfulDeliveries,
                    total_earned = newTotalEarned,
                    experience = newExperience,
                    level = newLevel,
                    best_time = newBestTime
                })
            end
        end)
    end)
end

-- ============================================
-- ランキング取得
-- ============================================
function GetRankings(cb)
    local rankings = {}
    local completed = 0
    local totalCategories = #Config.Ranking.categories
    
    for _, category in ipairs(Config.Ranking.categories) do
        local column = category.column
        local categoryId = category.id
        
        -- 特殊ケース: 最速記録は0を除外
        local whereClause = ''
        if categoryId == 'time' then
            whereClause = 'WHERE best_time > 0'
        end
        
        MySQL.query(string.format([[
            SELECT 
                cs.identifier,
                cs.%s as value,
                p.charinfo
            FROM cargo_stats cs
            LEFT JOIN players p ON cs.identifier = p.citizenid
            %s
            ORDER BY cs.%s DESC
            LIMIT ?
        ]], column, whereClause, column), {Config.Ranking.topCount}, function(result)
            local categoryRanking = {}
            
            if result then
                for i, row in ipairs(result) do
                    local charinfo = row.charinfo and json.decode(row.charinfo) or {}
                    local name = string.format('%s %s', charinfo.firstname or 'Unknown', charinfo.lastname or 'Player')
                    
                    table.insert(categoryRanking, {
                        rank = i,
                        identifier = row.identifier,
                        name = name,
                        value = row.value
                    })
                end
            end
            
            rankings[categoryId] = categoryRanking
            completed = completed + 1
            
            -- 全カテゴリ完了したらコールバック
            if completed >= totalCategories then
                cb(rankings)
            end
        end)
    end
end

-- ============================================
-- プレイヤー統計リセット
-- ============================================
function ResetPlayerStats(citizenid, cb)
    MySQL.update([[
        UPDATE cargo_stats SET
            total_deliveries = 0,
            successful_deliveries = 0,
            total_earned = 0,
            experience = 0,
            level = 1,
            best_time = 0,
            last_delivery = NULL
        WHERE identifier = ?
    ]], {citizenid}, function(affectedRows)
        if Config.Debug then
            print(string.format('[ng-cargo] Stats reset for %s', citizenid))
        end
        
        if cb then
            cb(affectedRows > 0)
        end
    end)
end

-- ============================================
-- 全プレイヤー統計取得 (管理用)
-- ============================================
function GetAllPlayerStats(cb)
    MySQL.query([[
        SELECT 
            cs.*,
            p.charinfo
        FROM cargo_stats cs
        LEFT JOIN players p ON cs.identifier = p.citizenid
        ORDER BY cs.level DESC, cs.experience DESC
    ]], {}, function(result)
        local stats = {}
        
        if result then
            for _, row in ipairs(result) do
                local charinfo = row.charinfo and json.decode(row.charinfo) or {}
                local name = string.format('%s %s', charinfo.firstname or 'Unknown', charinfo.lastname or 'Player')
                
                table.insert(stats, {
                    identifier = row.identifier,
                    name = name,
                    total_deliveries = row.total_deliveries,
                    successful_deliveries = row.successful_deliveries,
                    total_earned = row.total_earned,
                    experience = row.experience,
                    level = row.level,
                    best_time = row.best_time,
                    last_delivery = row.last_delivery,
                    success_rate = row.total_deliveries > 0 and math.floor((row.successful_deliveries / row.total_deliveries) * 100) or 0
                })
            end
        end
        
        cb(stats)
    end)
end

-- ============================================
-- トップ配送者取得 (簡易版)
-- ============================================
function GetTopDeliverers(limit, cb)
    MySQL.query([[
        SELECT 
            cs.identifier,
            cs.total_deliveries,
            cs.successful_deliveries,
            cs.level,
            p.charinfo
        FROM cargo_stats cs
        LEFT JOIN players p ON cs.identifier = p.citizenid
        ORDER BY cs.successful_deliveries DESC
        LIMIT ?
    ]], {limit or 10}, function(result)
        local topPlayers = {}
        
        if result then
            for i, row in ipairs(result) do
                local charinfo = row.charinfo and json.decode(row.charinfo) or {}
                local name = string.format('%s %s', charinfo.firstname or 'Unknown', charinfo.lastname or 'Player')
                
                table.insert(topPlayers, {
                    rank = i,
                    identifier = row.identifier,
                    name = name,
                    deliveries = row.successful_deliveries,
                    level = row.level
                })
            end
        end
        
        cb(topPlayers)
    end)
end

-- ============================================
-- 経験値追加 (個別)
-- ============================================
function AddExperience(citizenid, amount, cb)
    GetPlayerStats(citizenid, function(stats)
        local newExperience = stats.experience + amount
        local newLevel = math.floor(newExperience / Config.LevelSystem.experiencePerLevel) + 1
        
        if newLevel > Config.LevelSystem.maxLevel then
            newLevel = Config.LevelSystem.maxLevel
        end
        
        MySQL.update([[
            UPDATE cargo_stats SET
                experience = ?,
                level = ?
            WHERE identifier = ?
        ]], {newExperience, newLevel, citizenid}, function(affectedRows)
            if cb then
                cb({
                    oldLevel = stats.level,
                    newLevel = newLevel,
                    experience = newExperience,
                    leveledUp = newLevel > stats.level
                })
            end
        end)
    end)
end

-- ============================================
-- レベルごとのプレイヤー数取得
-- ============================================
function GetLevelDistribution(cb)
    MySQL.query([[
        SELECT 
            level,
            COUNT(*) as count
        FROM cargo_stats
        GROUP BY level
        ORDER BY level ASC
    ]], {}, function(result)
        local distribution = {}
        
        if result then
            for _, row in ipairs(result) do
                distribution[row.level] = row.count
            end
        end
        
        cb(distribution)
    end)
end

-- ============================================
-- 統計サマリー取得 (全体)
-- ============================================
function GetGlobalStats(cb)
    MySQL.query([[
        SELECT 
            COUNT(*) as total_players,
            SUM(total_deliveries) as total_deliveries,
            SUM(successful_deliveries) as successful_deliveries,
            SUM(total_earned) as total_earned,
            AVG(level) as avg_level,
            MAX(level) as max_level,
            MIN(best_time) as global_best_time
        FROM cargo_stats
        WHERE total_deliveries > 0
    ]], {}, function(result)
        if result and result[1] then
            local stats = result[1]
            cb({
                total_players = stats.total_players or 0,
                total_deliveries = stats.total_deliveries or 0,
                successful_deliveries = stats.successful_deliveries or 0,
                total_earned = stats.total_earned or 0,
                avg_level = math.floor(stats.avg_level or 1),
                max_level = stats.max_level or 1,
                global_best_time = stats.global_best_time or 0,
                success_rate = stats.total_deliveries > 0 and math.floor((stats.successful_deliveries / stats.total_deliveries) * 100) or 0
            })
        else
            cb({
                total_players = 0,
                total_deliveries = 0,
                successful_deliveries = 0,
                total_earned = 0,
                avg_level = 1,
                max_level = 1,
                global_best_time = 0,
                success_rate = 0
            })
        end
    end)
end

-- ============================================
-- デバッグ: ランダムデータ生成 (テスト用)
-- ============================================
if Config.Debug then
    RegisterCommand('cargogeneratedata', function(source, args, rawCommand)
        local count = tonumber(args[1]) or 10
        
        for i = 1, count do
            local fakeId = 'TEST' .. math.random(10000, 99999)
            
            MySQL.insert([[
                INSERT INTO cargo_stats 
                (identifier, total_deliveries, successful_deliveries, total_earned, experience, level, best_time)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE identifier = identifier
            ]], {
                fakeId,
                math.random(5, 100),
                math.random(3, 95),
                math.random(50000, 1000000),
                math.random(0, 10000),
                math.random(1, 50),
                math.random(300, 1200)
            })
        end
        
        print(string.format('[ng-cargo] Generated %d test records', count))
    end, true)
end