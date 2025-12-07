local QBCore = exports['qb-core']:GetCoreObject()

-- 支払い可能かチェック
QBCore.Functions.CreateCallback('ng-repairbench:server:checkPayment', function(source, cb, cost)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then 
        cb(false)
        return 
    end
    
    local canAfford = false
    
    if Config.Currency == 'cash' then
        canAfford = Player.PlayerData.money.cash >= cost
    elseif Config.Currency == 'bank' then
        canAfford = Player.PlayerData.money.bank >= cost
    end
    
    cb(canAfford)
end)

-- 支払い処理とadmin jobへの収益分配
RegisterServerEvent('ng-repairbench:server:processPayment', function(cost, repairType)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- 支払い処理
    local paymentSuccess = false
    
    if Config.Currency == 'cash' then
        if Player.PlayerData.money.cash >= cost then
            Player.Functions.RemoveMoney('cash', cost, 'vehicle-repair-bench')
            paymentSuccess = true
        end
    elseif Config.Currency == 'bank' then
        if Player.PlayerData.money.bank >= cost then
            Player.Functions.RemoveMoney('bank', cost, 'vehicle-repair-bench')
            paymentSuccess = true
        end
    end
    
    if not paymentSuccess then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'エラー',
            description = 'お金が足りません',
            type = 'error'
        })
        return
    end
    
    -- admin jobのプレイヤーにお金を分配
    DistributeToAdminJob(cost, repairType)
    
    -- ログ記録
    LogRepairTransaction(Player, cost, repairType)
    
    -- 成功通知
    TriggerClientEvent('ox_lib:notify', src, {
        title = '支払い完了',
        description = string.format('$%s が支払われました', cost),
        type = 'success'
    })
end)

-- admin jobのプレイヤーに収益を分配
function DistributeToAdminJob(amount)
    local adminPlayers = {}
    
    -- オンラインのadmin jobプレイヤーを検索
    for _, playerId in pairs(QBCore.Functions.GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(playerId)
        if Player and Player.PlayerData.job.name == Config.AdminJob then
            table.insert(adminPlayers, Player)
        end
    end
    
    if #adminPlayers > 0 then
        -- admin jobプレイヤーがオンラインの場合、均等分配
        local sharePerPlayer = math.floor(amount / #adminPlayers)
        
        for _, adminPlayer in pairs(adminPlayers) do
            adminPlayer.Functions.AddMoney('bank', sharePerPlayer, 'repair-bench-revenue')
            
            -- 収益通知
            TriggerClientEvent('ox_lib:notify', adminPlayer.PlayerData.source, {
                title = '修理ベンチ収益',
                description = string.format('$%s の収益を受け取りました', sharePerPlayer),
                type = 'success'
            })
        end
        
        print(string.format('[ng-repairbench] $%s を %d 人のadminプレイヤーに分配しました', amount, #adminPlayers))
    else
        -- admin jobプレイヤーがオフラインの場合、社会基金に追加
        AddToSocietyFund(amount)
    end
end

-- 社会基金に追加（admin jobプレイヤーがオフラインの場合）
function AddToSocietyFund(amount)
    -- データベースに社会基金として保存
    MySQL.Async.execute('INSERT INTO ng_repairbench_fund (job_name, amount, date) VALUES (?, ?, NOW()) ON DUPLICATE KEY UPDATE amount = amount + ?', {
        Config.AdminJob,
        amount,
        amount
    })
    
    print(string.format('[ng-repairbench] $%s を%s社会基金に追加しました', amount, Config.AdminJob))
end

-- 取引ログを記録
function LogRepairTransaction(player, cost, repairType)
    local logData = {
        player_id = player.PlayerData.citizenid,
        player_name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
        repair_type = repairType,
        cost = cost,
        timestamp = os.date('%Y-%m-%d %H:%M:%S')
    }
    
    -- データベースにログを保存
    MySQL.Async.execute('INSERT INTO ng_repairbench_logs (citizenid, player_name, repair_type, cost, created_at) VALUES (?, ?, ?, ?, ?)', {
        logData.player_id,
        logData.player_name,
        logData.repair_type,
        logData.cost,
        logData.timestamp
    })
    
    print(string.format('[ng-repairbench] %s が %s 修理で $%s を支払いました', logData.player_name, repairType, cost))
end

-- admin jobの社会基金残高を取得
QBCore.Functions.CreateCallback('ng-repairbench:server:getSocietyBalance', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player or Player.PlayerData.job.name ~= Config.AdminJob then
        cb(0)
        return
    end
    
    MySQL.Async.fetchScalar('SELECT amount FROM ng_repairbench_fund WHERE job_name = ?', {
        Config.AdminJob
    }, function(balance)
        cb(balance or 0)
    end)
end)

-- admin jobの社会基金から引き出し
RegisterServerEvent('ng-repairbench:server:withdrawFromSociety', function(amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player or Player.PlayerData.job.name ~= Config.AdminJob then return end
    
    -- 管理職グレードチェック（グレード3以上）
    if Player.PlayerData.job.grade.level < 3 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'エラー',
            description = '権限が不足しています',
            type = 'error'
        })
        return
    end
    
    MySQL.Async.fetchScalar('SELECT amount FROM ng_repairbench_fund WHERE job_name = ?', {
        Config.AdminJob
    }, function(currentBalance)
        if not currentBalance or currentBalance < amount then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'エラー',
                description = '残高が不足しています',
                type = 'error'
            })
            return
        end
        
        -- 残高を更新
        MySQL.Async.execute('UPDATE ng_repairbench_fund SET amount = amount - ? WHERE job_name = ?', {
            amount,
            Config.AdminJob
        })
        
        -- プレイヤーにお金を追加
        Player.Functions.AddMoney('bank', amount, 'society-withdrawal')
        
        TriggerClientEvent('ox_lib:notify', src, {
            title = '引き出し完了',
            description = string.format('$%s を引き出しました', amount),
            type = 'success'
        })
        
        print(string.format('[ng-repairbench] %s が社会基金から $%s を引き出しました', Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname, amount))
    end)
end)

-- データベーステーブル作成
CreateThread(function()
    -- 社会基金テーブル
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `ng_repairbench_fund` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `job_name` varchar(50) NOT NULL,
            `amount` int(11) NOT NULL DEFAULT 0,
            `date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `job_name` (`job_name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    -- ログテーブル
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `ng_repairbench_logs` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `citizenid` varchar(50) NOT NULL,
            `player_name` varchar(100) NOT NULL,
            `repair_type` varchar(20) NOT NULL,
            `cost` int(11) NOT NULL,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `citizenid` (`citizenid`),
            KEY `created_at` (`created_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    print('[ng-repairbench] データベーステーブルが正常に作成されました')
end)

-- 統計情報を取得（admin job用）
QBCore.Functions.CreateCallback('ng-repairbench:server:getStats', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player or Player.PlayerData.job.name ~= Config.AdminJob then
        cb(nil)
        return
    end
    
    -- 今日の収益
    MySQL.Async.fetchScalar('SELECT SUM(cost) FROM ng_repairbench_logs WHERE DATE(created_at) = CURDATE()', {}, function(todayRevenue)
        -- 今週の収益
        MySQL.Async.fetchScalar('SELECT SUM(cost) FROM ng_repairbench_logs WHERE YEARWEEK(created_at) = YEARWEEK(NOW())', {}, function(weekRevenue)
            -- 今月の収益
            MySQL.Async.fetchScalar('SELECT SUM(cost) FROM ng_repairbench_logs WHERE MONTH(created_at) = MONTH(NOW()) AND YEAR(created_at) = YEAR(NOW())', {}, function(monthRevenue)
                -- 総修理回数
                MySQL.Async.fetchScalar('SELECT COUNT(*) FROM ng_repairbench_logs', {}, function(totalRepairs)
                    cb({
                        todayRevenue = todayRevenue or 0,
                        weekRevenue = weekRevenue or 0,
                        monthRevenue = monthRevenue or 0,
                        totalRepairs = totalRepairs or 0
                    })
                end)
            end)
        end)
    end)
end)

print('[ng-repairbench] サーバースクリプトが正常に読み込まれました')