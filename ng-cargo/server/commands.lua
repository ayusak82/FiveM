local QBCore = exports['qb-core']:GetCoreObject()

-- ============================================
-- 管理者権限チェック
-- ============================================
local function IsAdmin(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local playerGroup = QBCore.Functions.GetPermission(source)
    
    for _, group in ipairs(Config.AdminGroups) do
        if playerGroup == group then
            return true
        end
    end
    
    return false
end

-- ============================================
-- プレイヤー統計リセットコマンド
-- ============================================
QBCore.Commands.Add('cargoreset', 'プレイヤーの貨物輸送統計をリセット', {
    {name = 'id', help = 'プレイヤーのサーバーID'}
}, true, function(source, args)
    local src = source
    
    if not IsAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = '貨物輸送',
            description = '権限がありません',
            type = 'error'
        })
        return
    end
    
    local targetId = tonumber(args[1])
    if not targetId then
        TriggerClientEvent('ox_lib:notify', src, {
            title = '貨物輸送',
            description = '使用方法: /cargoreset [プレイヤーID]',
            type = 'error'
        })
        return
    end
    
    local TargetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not TargetPlayer then
        TriggerClientEvent('ox_lib:notify', src, {
            title = '貨物輸送',
            description = 'プレイヤーが見つかりません',
            type = 'error'
        })
        return
    end
    
    local citizenid = TargetPlayer.PlayerData.citizenid
    local targetName = TargetPlayer.PlayerData.charinfo.firstname .. ' ' .. TargetPlayer.PlayerData.charinfo.lastname
    
    ResetPlayerStats(citizenid, function(success)
        if success then
            TriggerClientEvent('ox_lib:notify', src, {
                title = '貨物輸送',
                description = string.format('%s の統計をリセットしました', targetName),
                type = 'success'
            })
            
            TriggerClientEvent('ox_lib:notify', targetId, {
                title = '貨物輸送',
                description = 'あなたの統計が管理者によってリセットされました',
                type = 'info'
            })
            
            if Config.Debug then
                print(string.format('[ng-cargo] Admin %d reset stats for %s (%s)', src, targetName, citizenid))
            end
        else
            TriggerClientEvent('ox_lib:notify', src, {
                title = '貨物輸送',
                description = 'リセットに失敗しました',
                type = 'error'
            })
        end
    end)
end)

-- ============================================
-- ランキング表示コマンド
-- ============================================
QBCore.Commands.Add('cargorank', '貨物輸送のランキングを表示', {}, false, function(source, args)
    local src = source
    
    GetRankings(function(rankings)
        TriggerClientEvent('ng-cargo:client:showRanking', src, rankings)
    end)
end)

-- ============================================
-- 自分の統計表示コマンド
-- ============================================
QBCore.Commands.Add('cargostats', '自分の貨物輸送統計を表示', {}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    GetPlayerStats(Player.PlayerData.citizenid, function(stats)
        local successRate = stats.total_deliveries > 0 and math.floor((stats.successful_deliveries / stats.total_deliveries) * 100) or 0
        local expToNext = Config.LevelSystem.experiencePerLevel - (stats.experience % Config.LevelSystem.experiencePerLevel)
        local bestTimeFormatted = stats.best_time > 0 and string.format('%d分%d秒', math.floor(stats.best_time / 60), stats.best_time % 60) or '記録なし'
        
        TriggerClientEvent('ox_lib:notify', src, {
            title = '📊 あなたの統計',
            description = string.format(
                'レベル: %d\n' ..
                '経験値: %d (次まで: %d)\n' ..
                '総配送: %d回\n' ..
                '成功: %d回 (成功率: %d%%)\n' ..
                '総収入: $%s\n' ..
                '最速記録: %s',
                stats.level,
                stats.experience,
                expToNext,
                stats.total_deliveries,
                stats.successful_deliveries,
                successRate,
                FormatNumber(stats.total_earned),
                bestTimeFormatted
            ),
            type = 'info',
            duration = 10000
        })
    end)
end)

-- ============================================
-- ジョブキャンセルコマンド
-- ============================================
QBCore.Commands.Add('cargocancel', '現在の貨物輸送をキャンセル', {}, false, function(source, args)
    local src = source
    
    -- ActiveJobsをチェック (グローバル変数)
    if not ActiveJobs or not ActiveJobs[src] then
        TriggerClientEvent('ox_lib:notify', src, {
            title = '貨物輸送',
            description = '現在ジョブを実行していません',
            type = 'error'
        })
        return
    end
    
    -- キャンセルイベントをトリガー
    TriggerEvent('ng-cargo:server:cancelJob', src, 'command')
    
    if Config.Debug then
        print(string.format('[ng-cargo] Player %d cancelled job via command', src))
    end
end)

-- ============================================
-- 管理者: 全体統計表示
-- ============================================
QBCore.Commands.Add('cargoadmin', '貨物輸送の全体統計を表示', {}, false, function(source, args)
    local src = source
    
    if not IsAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = '貨物輸送',
            description = '権限がありません',
            type = 'error'
        })
        return
    end
    
    GetGlobalStats(function(globalStats)
        TriggerClientEvent('ox_lib:notify', src, {
            title = '🌐 全体統計',
            description = string.format(
                'アクティブプレイヤー: %d人\n' ..
                '総配送数: %s回\n' ..
                '成功配送: %s回 (成功率: %d%%)\n' ..
                '総売上: $%s\n' ..
                '平均レベル: %d\n' ..
                '最高レベル: %d\n' ..
                '世界最速記録: %s',
                globalStats.total_players,
                FormatNumber(globalStats.total_deliveries),
                FormatNumber(globalStats.successful_deliveries),
                globalStats.success_rate,
                FormatNumber(globalStats.total_earned),
                globalStats.avg_level,
                globalStats.max_level,
                globalStats.global_best_time > 0 and string.format('%d分%d秒', math.floor(globalStats.global_best_time / 60), globalStats.global_best_time % 60) or '記録なし'
            ),
            type = 'info',
            duration = 15000
        })
    end)
end)

-- ============================================
-- 管理者: プレイヤー一覧表示
-- ============================================
QBCore.Commands.Add('cargolist', '貨物輸送プレイヤー一覧', {
    {name = 'limit', help = '表示数 (デフォルト: 20)'}
}, false, function(source, args)
    local src = source
    
    if not IsAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = '貨物輸送',
            description = '権限がありません',
            type = 'error'
        })
        return
    end
    
    GetAllPlayerStats(function(allStats)
        local limit = tonumber(args[1]) or 20
        local count = 0
        
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
        print('貨物輸送プレイヤー一覧')
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
        print(string.format('%-30s | Lv | 配送数 | 成功率 | 総収入', '名前'))
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
        
        for _, stat in ipairs(allStats) do
            if count >= limit then break end
            
            print(string.format(
                '%-30s | %2d | %6d | %5d%% | $%s',
                stat.name,
                stat.level,
                stat.total_deliveries,
                stat.success_rate,
                FormatNumber(stat.total_earned)
            ))
            
            count = count + 1
        end
        
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
        print(string.format('表示: %d / %d プレイヤー', count, #allStats))
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
        
        TriggerClientEvent('ox_lib:notify', src, {
            title = '貨物輸送',
            description = string.format('サーバーコンソールに%d人のプレイヤー情報を表示しました', count),
            type = 'success'
        })
    end)
end)

-- ============================================
-- 管理者: 経験値付与
-- ============================================
QBCore.Commands.Add('cargogiveexp', 'プレイヤーに経験値を付与', {
    {name = 'id', help = 'プレイヤーのサーバーID'},
    {name = 'amount', help = '経験値量'}
}, true, function(source, args)
    local src = source
    
    if not IsAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = '貨物輸送',
            description = '権限がありません',
            type = 'error'
        })
        return
    end
    
    local targetId = tonumber(args[1])
    local amount = tonumber(args[2])
    
    if not targetId or not amount then
        TriggerClientEvent('ox_lib:notify', src, {
            title = '貨物輸送',
            description = '使用方法: /cargogiveexp [プレイヤーID] [経験値]',
            type = 'error'
        })
        return
    end
    
    local TargetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not TargetPlayer then
        TriggerClientEvent('ox_lib:notify', src, {
            title = '貨物輸送',
            description = 'プレイヤーが見つかりません',
            type = 'error'
        })
        return
    end
    
    local citizenid = TargetPlayer.PlayerData.citizenid
    local targetName = TargetPlayer.PlayerData.charinfo.firstname .. ' ' .. TargetPlayer.PlayerData.charinfo.lastname
    
    AddExperience(citizenid, amount, function(result)
        TriggerClientEvent('ox_lib:notify', src, {
            title = '貨物輸送',
            description = string.format('%s に%d EXPを付与しました', targetName, amount),
            type = 'success'
        })
        
        TriggerClientEvent('ox_lib:notify', targetId, {
            title = '貨物輸送',
            description = string.format('管理者から%d EXPを受け取りました', amount),
            type = 'success'
        })
        
        if result.leveledUp then
            TriggerClientEvent('ox_lib:notify', targetId, {
                title = '🎊 レベルアップ!',
                description = string.format('レベル %d → %d', result.oldLevel, result.newLevel),
                type = 'success',
                duration = 7000
            })
        end
    end)
end)

-- ============================================
-- 管理者: レベル分布表示
-- ============================================
QBCore.Commands.Add('cargolevelstats', 'レベル分布を表示', {}, false, function(source, args)
    local src = source
    
    if not IsAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = '貨物輸送',
            description = '権限がありません',
            type = 'error'
        })
        return
    end
    
    GetLevelDistribution(function(distribution)
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
        print('レベル分布')
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
        
        for level = 1, Config.LevelSystem.maxLevel do
            local count = distribution[level] or 0
            if count > 0 then
                local bar = string.rep('█', math.min(count, 50))
                print(string.format('Lv.%2d: %s (%d人)', level, bar, count))
            end
        end
        
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
        
        TriggerClientEvent('ox_lib:notify', src, {
            title = '貨物輸送',
            description = 'サーバーコンソールにレベル分布を表示しました',
            type = 'success'
        })
    end)
end)

-- ============================================
-- ヘルパー関数: 数値フォーマット
-- ============================================
function FormatNumber(num)
    local formatted = tostring(num)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

-- ============================================
-- デバッグ: 利用可能なコマンド一覧
-- ============================================
if Config.Debug then
    RegisterCommand('cargohelp', function(source, args, rawCommand)
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
        print('ng-cargo コマンド一覧')
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
        print('一般プレイヤー用:')
        print('  /cargorank          - ランキング表示')
        print('  /cargostats         - 自分の統計表示')
        print('  /cargocancel        - ジョブキャンセル')
        print('')
        print('管理者用:')
        print('  /cargoreset [id]    - プレイヤー統計リセット')
        print('  /cargoadmin         - 全体統計表示')
        print('  /cargolist [limit]  - プレイヤー一覧')
        print('  /cargogiveexp [id] [amount] - 経験値付与')
        print('  /cargolevelstats    - レベル分布表示')
        print('')
        print('デバッグ用:')
        print('  /cargodebug         - デバッグ情報表示')
        print('  /cargogeneratedata [count] - テストデータ生成')
        print('  /cargohelp          - このヘルプ')
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
    end, false)
end