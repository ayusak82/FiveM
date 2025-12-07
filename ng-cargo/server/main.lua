local QBCore = exports['qb-core']:GetCoreObject()
ActiveJobs = {} -- [source] = jobData
local playerBuckets = {} -- [source] = originalBucket

-- 乱数生成器の初期化
math.randomseed(os.time())

-- ============================================
-- ジョブ開始
-- ============================================
QBCore.Functions.CreateCallback('ng-cargo:server:startJob', function(source, cb, difficulty, playerLevel)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        cb(false, nil)
        return
    end
    
    -- 既にジョブ中か確認
    if ActiveJobs[src] then
        cb(false, nil)
        return
    end
    
    -- 難易度データ取得
    local difficultyData = Config.Difficulties[difficulty]
    if not difficultyData then
        cb(false, nil)
        return
    end
    
    -- ランダムに目的地を選択
    local selectedDestinations = SelectRandomDestinations(difficultyData.destinations)
    
    -- ランダムイベント判定
    local randomEvent = nil
    if Config.RandomEvents.enabled then
        local roll = math.random(100)
        if Config.Debug then
            print(string.format('[ng-cargo] Random event roll: %d/%d', roll, Config.RandomEvents.chance))
        end
        
        if roll <= Config.RandomEvents.chance then
            local eventIndex = math.random(#Config.RandomEvents.events)
            randomEvent = Config.RandomEvents.events[eventIndex]
            
            if Config.Debug then
                print(string.format('[ng-cargo] Random event triggered: %s (index: %d)', randomEvent.name, eventIndex))
            end
        else
            if Config.Debug then
                print('[ng-cargo] No random event triggered')
            end
        end
    end
    
    -- 時間制限調整 (ランダムイベント)
    local timeLimit = difficultyData.timeLimit
    if randomEvent and randomEvent.timeReduction then
        timeLimit = timeLimit - randomEvent.timeReduction
    end
    
    -- 荷下ろし回数
    local unloadCount = difficultyData.unloadCount
    
    -- ジョブデータ作成
    local jobData = {
        difficulty = difficulty,
        destinations = selectedDestinations,
        timeLimit = timeLimit,
        baseReward = difficultyData.baseReward,
        experience = difficultyData.experience,
        timeBonus = difficultyData.timeBonus,
        unloadCount = unloadCount,
        randomEvent = randomEvent,
        startTime = os.time(),
        playerLevel = playerLevel
    }
    
    ActiveJobs[src] = jobData
    
    -- ルーティングバケット設定
    if Config.RoutingBucket.enabled then
        local originalBucket = GetPlayerRoutingBucket(src)
        playerBuckets[src] = originalBucket
        
        local newBucket = Config.RoutingBucket.startBucket + src
        SetPlayerRoutingBucket(src, newBucket)
        SetRoutingBucketPopulationEnabled(newBucket, false)
        
        if Config.Debug then
            print(string.format('[ng-cargo] Player %d moved to bucket %d', src, newBucket))
        end
    end
    
    cb(true, jobData)
end)

-- ============================================
-- 目的地をランダム選択
-- ============================================
function SelectRandomDestinations(count)
    local available = {}
    for i, dest in ipairs(Config.Destinations) do
        table.insert(available, {
            name = dest.name,
            coords = dest.coords,
            difficulty = dest.difficulty,
            distance = dest.distance
        })
    end
    
    -- シャッフル
    for i = #available, 2, -1 do
        local j = math.random(i)
        available[i], available[j] = available[j], available[i]
    end
    
    -- 指定数だけ選択
    local selected = {}
    for i = 1, math.min(count, #available) do
        table.insert(selected, available[i])
    end
    
    return selected
end

-- ============================================
-- ジョブ完了
-- ============================================
RegisterNetEvent('ng-cargo:server:completeJob', function(completionTime)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local jobData = ActiveJobs[src]
    if not jobData then return end
    
    -- 経験値計算（先に計算）
    local experience = jobData.experience
    if jobData.randomEvent and jobData.randomEvent.experienceMultiplier then
        local oldExp = experience
        experience = math.floor(experience * jobData.randomEvent.experienceMultiplier)
        
        if Config.Debug then
            print(string.format('[ng-cargo] Experience multiplier: %.1fx (%d -> %d)', 
                jobData.randomEvent.experienceMultiplier, oldExp, experience))
        end
    end
    
    -- プレイヤーの現在の統計を取得してレベルを計算
    GetPlayerStats(Player.PlayerData.citizenid, function(currentStats)
        -- 経験値追加後の新しいレベルを計算
        local newExperience = currentStats.experience + experience
        local newLevel = math.floor(newExperience / Config.LevelSystem.experiencePerLevel) + 1
        if newLevel > Config.LevelSystem.maxLevel then
            newLevel = Config.LevelSystem.maxLevel
        end
        
        if Config.Debug then
            print(string.format('[ng-cargo] Current level: %d, New level after XP: %d', currentStats.level, newLevel))
        end
        
        -- 【重要】経験値追加後の新しいレベルでレベルボーナスを計算
        local levelBonus = GetLevelBonusMultiplier(newLevel)
        
        -- 基本報酬計算
        local baseReward = jobData.baseReward
        local timeBonus = 0
        local eventBonus = 0
        
        -- 複数目的地ボーナス
        local destinationMultiplier = 1.0
        local destinationCount = #jobData.destinations
        
        if destinationCount == 1 then
            destinationMultiplier = 1.0
        elseif destinationCount == 2 then
            destinationMultiplier = 1.5
        elseif destinationCount >= 3 then
            destinationMultiplier = 2.0
        end
        
        baseReward = math.floor(baseReward * destinationMultiplier)
        
        -- 時間ボーナス
        if completionTime < jobData.timeLimit then
            local timeRatio = completionTime / jobData.timeLimit
            if timeRatio < 0.7 then -- 70%以内に完了
                timeBonus = jobData.timeBonus
            end
        end
        
        -- ランダムイベントボーナス
        if jobData.randomEvent then
            local eventMultiplier = jobData.randomEvent.rewardMultiplier or 1.0
            eventBonus = math.floor(baseReward * (eventMultiplier - 1.0))
            baseReward = math.floor(baseReward * eventMultiplier)
            
            if Config.Debug then
                print(string.format('[ng-cargo] Event: %s, Multiplier: %.1fx, Bonus: $%d', 
                    jobData.randomEvent.name, eventMultiplier, eventBonus))
            end
        end
        
        -- レベルボーナス適用して最終報酬計算
        local totalReward = math.floor((baseReward + timeBonus) * levelBonus)
        
        if Config.Debug then
            print(string.format('[ng-cargo] Final reward calculation: Base=%d, Time=%d, Event=%d, Level=%.1fx, Total=%d', 
                baseReward, timeBonus, eventBonus, levelBonus, totalReward))
        end
        
        -- 報酬付与: 現金
        Player.Functions.AddMoney('cash', totalReward, 'cargo-delivery')
        
        -- 報酬付与: アイテム (Configから)
        if Config.Rewards.items then
            for _, itemData in ipairs(Config.Rewards.items) do
                if itemData.type == 'item' then
                    -- アイテムを付与
                    local itemAmount = itemData.amount
                    
                    -- 配送先数によるボーナスを適用
                    itemAmount = math.floor(itemAmount * destinationMultiplier)
                    
                    -- レベルボーナスをアイテムにも適用
                    itemAmount = math.floor(itemAmount * levelBonus)
                    
                    -- アイテム追加
                    local success = Player.Functions.AddItem(itemData.name, itemAmount, false, false)
                    
                    if success then
                        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemData.name], "add", itemAmount)
                        
                        if Config.Debug then
                            print(string.format('[ng-cargo] Added item: %s x%d to player %d', itemData.name, itemAmount, src))
                        end
                    else
                        if Config.Debug then
                            print(string.format('[ng-cargo] Failed to add item: %s to player %d', itemData.name, src))
                        end
                    end
                end
            end
        end
        
        -- データベース更新
        UpdatePlayerStats(src, true, totalReward, experience, completionTime, function(stats)
        -- 統計データ
        local responseData = {
            totalReward = totalReward,
            baseReward = baseReward,
            timeBonus = timeBonus,
            eventBonus = eventBonus,
            levelBonus = levelBonus,
            destinationMultiplier = destinationMultiplier,
            randomEvent = jobData.randomEvent, -- ランダムイベント情報を追加
            experience = experience,
            completionTime = completionTime,
            currentLevel = stats.level,
            currentExp = stats.experience % Config.LevelSystem.experiencePerLevel,
            totalDeliveries = stats.total_deliveries,
            successRate = math.floor((stats.successful_deliveries / stats.total_deliveries) * 100),
            bestTime = stats.best_time,
            newBestTime = false
        }
        
        -- 【修正】レベルアップチェック
        -- 現在のジョブ開始時のレベル
        local oldLevel = jobData.playerLevel
        -- データベース更新後の新しいレベル
        local newLevel = stats.level
        
        if Config.Debug then
            print(string.format('[ng-cargo] Level check - Old: %d, New: %d, XP: %d', oldLevel, newLevel, stats.experience))
        end
        
        if newLevel > oldLevel then
            responseData.levelUp = true
            responseData.oldLevel = oldLevel
            responseData.newLevel = newLevel
            
            -- 【修正】レベルアップ報酬 - 上がったレベル全てに対して報酬を付与
            local totalLevelReward = 0
            for level = oldLevel + 1, newLevel do
                local levelReward = Config.LevelSystem.levelUpRewards[level]
                if levelReward then
                    Player.Functions.AddMoney('cash', levelReward.money, 'cargo-levelup')
                    totalLevelReward = totalLevelReward + levelReward.money
                    
                    TriggerClientEvent('ox_lib:notify', src, {
                        title = '🎊 レベルアップ!',
                        description = string.format('レベル%d達成! %s', level, levelReward.message),
                        type = 'success',
                        duration = 7000
                    })
                    
                    if Config.Debug then
                        print(string.format('[ng-cargo] Level %d reward given: $%d', level, levelReward.money))
                    end
                end
            end
            
            if totalLevelReward > 0 then
                responseData.levelUpReward = totalLevelReward
            end
        end
        
        -- 最速記録更新チェック
        if stats.best_time == 0 or completionTime < stats.best_time then
            responseData.newBestTime = true
        end
        
        -- 完了通知
        TriggerClientEvent('ox_lib:notify', src, {
            title = '貨物輸送',
            description = Config.Messages.job_completed,
            type = 'success',
            duration = 5000
        })
        
        -- 統計表示
        TriggerClientEvent('ng-cargo:client:jobCompleted', src, responseData)
        
        -- クリーンアップ
        CleanupPlayerJob(src)
    end)
    end) -- GetPlayerStatsのコールバックを閉じる
end)

-- ============================================
-- ジョブ失敗
-- ============================================
RegisterNetEvent('ng-cargo:server:failJob', function(isDeath)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local jobData = ActiveJobs[src]
    if not jobData then return end
    
    -- データベース更新 (失敗記録)
    UpdatePlayerStats(src, false, 0, 0, 0, function(stats)
        if not isDeath then
            -- 通常の失敗時のみ通知（死亡時はクライアント側で通知）
            TriggerClientEvent('ox_lib:notify', src, {
                title = '貨物輸送',
                description = Config.Messages.job_failed,
                type = 'error',
                duration = 5000
            })
            
            -- クリーンアップ（通常の失敗時）
            CleanupPlayerJob(src)
        else
            -- 死亡時はActiveJobsとバケットのみクリア（クライアントは既にクリーンアップ済み）
            ActiveJobs[src] = nil
            
            -- バケットは死亡時専用のリセット処理で行うため、ここでは元のバケット情報だけ保持
            if Config.Debug then
                print(string.format('[ng-cargo] Player %d failed job (death), waiting for bucket reset', src))
            end
        end
    end)
end)

-- ============================================
-- ジョブキャンセル
-- ============================================
RegisterNetEvent('ng-cargo:server:cancelJob', function(source, reason)
    -- sourceがnilの場合は、第一引数をsourceとして扱う
    local src = source
    if type(source) == 'number' and not reason then
        src = source
        reason = 'manual'
    elseif type(source) == 'string' then
        -- TriggerEventから呼ばれた場合
        src = tonumber(source) or src
        reason = reason or 'manual'
    end
    
    if not ActiveJobs[src] then 
        if Config.Debug then
            print(string.format('[ng-cargo] Cancel failed: No active job for player %d', src))
        end
        return 
    end
    
    -- 切断以外の場合は通知
    if reason ~= 'disconnect' then
        TriggerClientEvent('ox_lib:notify', src, {
            title = '貨物輸送',
            description = Config.Messages.job_cancelled,
            type = 'info',
            duration = 5000
        })
    end
    
    -- クリーンアップ
    CleanupPlayerJob(src)
    
    if Config.Debug then
        print(string.format('[ng-cargo] Job cancelled for player %d (reason: %s)', src, reason))
    end
end)

-- ============================================
-- バケットリセット
-- ============================================
RegisterNetEvent('ng-cargo:server:resetBucket', function()
    local src = source
    
    if Config.RoutingBucket.enabled and playerBuckets[src] then
        SetPlayerRoutingBucket(src, playerBuckets[src])
        playerBuckets[src] = nil
        
        if Config.Debug then
            print(string.format('[ng-cargo] Player %d bucket reset', src))
        end
    end
end)

-- ============================================
-- バケットを0にリセット (死亡時)
-- ============================================
RegisterNetEvent('ng-cargo:server:resetBucketToDeath', function()
    local src = source
    
    if Config.RoutingBucket.enabled then
        SetPlayerRoutingBucket(src, 0)
        playerBuckets[src] = nil
        
        if Config.Debug then
            print(string.format('[ng-cargo] Player %d bucket reset to 0 (death)', src))
        end
    end
end)

-- ============================================
-- プレイヤー統計取得
-- ============================================
QBCore.Functions.CreateCallback('ng-cargo:server:getPlayerStats', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        cb({})
        return
    end
    
    GetPlayerStats(Player.PlayerData.citizenid, function(stats)
        cb(stats)
    end)
end)

-- ============================================
-- EMS人数チェック
-- ============================================
QBCore.Functions.CreateCallback('ng-cargo:server:checkEMSCount', function(source, cb)
    local emsCount = 0
    local Players = QBCore.Functions.GetQBPlayers()
    
    for _, Player in pairs(Players) do
        if Player and Player.PlayerData and Player.PlayerData.job then
            for _, emsJob in ipairs(Config.DeathSettings.emsJobs) do
                if Player.PlayerData.job.name == emsJob and Player.PlayerData.job.onduty then
                    emsCount = emsCount + 1
                    break
                end
            end
        end
    end
    
    if Config.Debug then
        print(string.format('[ng-cargo] EMS count check: %d online', emsCount))
    end
    
    cb(emsCount)
end)

-- ============================================
-- クリーンアップ
-- ============================================
function CleanupPlayerJob(src)
    ActiveJobs[src] = nil
    
    -- バケットリセット
    if Config.RoutingBucket.enabled and playerBuckets[src] then
        SetPlayerRoutingBucket(src, playerBuckets[src])
        playerBuckets[src] = nil
    end
    
    -- クライアントに通知
    TriggerClientEvent('ng-cargo:client:cancelJob', src)
end

-- ============================================
-- レベルボーナス取得
-- ============================================
function GetLevelBonusMultiplier(level)
    -- 【修正】レベルに応じた最大の倍率を返す
    local bonus = 1.0
    local levels = {}
    
    -- Config.Rewards.levelBonusのキーをテーブルに格納してソート
    for lvl, _ in pairs(Config.Rewards.levelBonus) do
        table.insert(levels, lvl)
    end
    table.sort(levels)
    
    -- プレイヤーレベル以下で最大のボーナスを取得
    for _, lvl in ipairs(levels) do
        if level >= lvl then
            bonus = Config.Rewards.levelBonus[lvl]
        else
            break
        end
    end
    
    if Config.Debug then
        print(string.format('[ng-cargo] Level %d bonus multiplier: %.1fx', level, bonus))
    end
    
    return bonus
end

-- ============================================
-- プレイヤー切断時のクリーンアップ
-- ============================================
AddEventHandler('playerDropped', function(reason)
    local src = source
    
    if ActiveJobs[src] then
        if Config.Debug then
            print(string.format('[ng-cargo] Player %d disconnected during job', src))
        end
        
        CleanupPlayerJob(src)
    end
end)

-- ============================================
-- リソース停止時のクリーンアップ
-- ============================================
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- 全プレイヤーのバケットをリセット
    for src, bucket in pairs(playerBuckets) do
        SetPlayerRoutingBucket(src, bucket)
    end
    
    -- 全プレイヤーのジョブをキャンセル
    for src, _ in pairs(ActiveJobs) do
        TriggerClientEvent('ng-cargo:client:cancelJob', src)
    end
    
    if Config.Debug then
        print('[ng-cargo] Resource stopped, cleaned up all jobs')
    end
end)

-- ============================================
-- ランキング表示
-- ============================================
RegisterNetEvent('ng-cargo:server:showRanking', function()
    local src = source
    
    GetRankings(function(rankings)
        TriggerClientEvent('ng-cargo:client:showRanking', src, rankings)
    end)
end)

-- ============================================
-- デバッグコマンド
-- ============================================
if Config.Debug then
    QBCore.Commands.Add('cargodebug', 'デバッグ情報表示', {}, false, function(source, args)
        local src = source
        print('=== ng-cargo Debug Info ===')
        print('Active Jobs:', json.encode(ActiveJobs, {indent = true}))
        print('Player Buckets:', json.encode(playerBuckets, {indent = true}))
    end)
    
    -- ランダムイベントテストコマンド
    QBCore.Commands.Add('cargotestevent', 'ランダムイベントテスト', {}, false, function(source, args)
        local src = source
        print('=== Random Event Test ===')
        
        -- 10回テスト
        local eventCount = {}
        for i = 1, 10 do
            local roll = math.random(100)
            local triggered = roll <= Config.RandomEvents.chance
            
            if triggered then
                local eventIndex = math.random(#Config.RandomEvents.events)
                local event = Config.RandomEvents.events[eventIndex]
                eventCount[event.name] = (eventCount[event.name] or 0) + 1
                print(string.format('Test %d: Roll=%d, Triggered=%s, Event=%s', i, roll, tostring(triggered), event.name))
            else
                print(string.format('Test %d: Roll=%d, Triggered=%s', i, roll, tostring(triggered)))
            end
        end
        
        print('Event counts:')
        for name, count in pairs(eventCount) do
            print(string.format('  %s: %d times', name, count))
        end
        
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'ランダムイベントテスト',
            description = 'サーバーコンソールを確認してください',
            type = 'info'
        })
    end)
end
