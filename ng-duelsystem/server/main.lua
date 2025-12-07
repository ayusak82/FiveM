local QBCore = exports['qb-core']:GetCoreObject()
local activeDuels = {}
local duelIdCounter = 0

-- ===================================
-- データベース初期化
-- ===================================
CreateThread(function()
    if Config.Statistics.saveToDatabase then
        MySQL.query([[
            CREATE TABLE IF NOT EXISTS ng_duel_stats (
                id INT AUTO_INCREMENT PRIMARY KEY,
                citizenid VARCHAR(50) NOT NULL UNIQUE,
                total_duels INT DEFAULT 0,
                wins INT DEFAULT 0,
                losses INT DEFAULT 0,
                kills INT DEFAULT 0,
                deaths INT DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                INDEX idx_citizenid (citizenid),
                INDEX idx_wins (wins DESC)
            )
        ]])
        
        if Config.Debug then print('[ng-duelsystem] データベーステーブル作成完了') end
    end
end)

-- ===================================
-- 近くのプレイヤー取得
-- ===================================
RegisterNetEvent('ng-duelsystem:server:getNearbyPlayers', function(arenaIndex)
    local src = source
    local Players = QBCore.Functions.GetQBPlayers()
    local playerPed = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(playerPed)
    local nearbyPlayers = {}
    
    for _, player in pairs(Players) do
        if player.PlayerData.source ~= src then
            local targetPed = GetPlayerPed(player.PlayerData.source)
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(playerCoords - targetCoords)
            
            if distance < 10.0 then
                -- プレイヤーがデュエル中かチェック
                local inDuel = false
                for _, duel in pairs(activeDuels) do
                    if duel.player1 == player.PlayerData.source or duel.player2 == player.PlayerData.source then
                        inDuel = true
                        break
                    end
                end
                
                if not inDuel then
                    table.insert(nearbyPlayers, {
                        id = player.PlayerData.source,
                        name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
                    })
                end
            end
        end
    end
    
    TriggerClientEvent('ng-duelsystem:client:showPlayerSelection', src, nearbyPlayers, arenaIndex)
end)

-- ===================================
-- デュエルリクエスト送信
-- ===================================
RegisterNetEvent('ng-duelsystem:server:sendDuelRequest', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local TargetPlayer = QBCore.Functions.GetPlayer(data.targetId)
    
    if not Player or not TargetPlayer then return end
    
    -- 送信者がデュエル中かチェック
    for _, duel in pairs(activeDuels) do
        if duel.player1 == src or duel.player2 == src then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'デュエルシステム',
                description = Config.Text.you_in_duel,
                type = 'error',
                position = Config.UI.notificationPosition
            })
            return
        end
    end
    
    -- ターゲットがデュエル中かチェック
    for _, duel in pairs(activeDuels) do
        if duel.player1 == data.targetId or duel.player2 == data.targetId then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'デュエルシステム',
                description = Config.Text.player_in_duel,
                type = 'error',
                position = Config.UI.notificationPosition
            })
            return
        end
    end
    
    -- アリーナが使用中かチェック
    for _, duel in pairs(activeDuels) do
        if duel.arenaIndex == data.arenaIndex then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'デュエルシステム',
                description = Config.Text.arena_occupied,
                type = 'error',
                position = Config.UI.notificationPosition
            })
            return
        end
    end
    
    -- デュエルIDを生成
    duelIdCounter = duelIdCounter + 1
    local duelId = 'duel_' .. duelIdCounter
    
    -- デュエルリクエストデータ
    local requestData = {
        duelId = duelId,
        sender = src,
        senderName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        target = data.targetId,
        arenaIndex = data.arenaIndex,
        arenaName = Config.Arenas[data.arenaIndex].name,
        rounds = data.rounds,
        weapon = data.weapon,
        weaponLabel = data.weapon.label
    }
    
    -- 一時的に保存
    activeDuels[duelId] = {
        status = 'pending',
        data = requestData
    }
    
    -- ターゲットにリクエスト送信
    TriggerClientEvent('ng-duelsystem:client:receiveDuelRequest', data.targetId, requestData)
    
    -- タイムアウト設定（30秒）
    SetTimeout(30000, function()
        if activeDuels[duelId] and activeDuels[duelId].status == 'pending' then
            activeDuels[duelId] = nil
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'デュエルシステム',
                description = 'リクエストがタイムアウトしました',
                type = 'error',
                position = Config.UI.notificationPosition
            })
        end
    end)
end)

-- ===================================
-- デュエル承認
-- ===================================
RegisterNetEvent('ng-duelsystem:server:acceptDuel', function(duelId)
    local src = source
    
    if not activeDuels[duelId] or activeDuels[duelId].status ~= 'pending' then return end
    
    local duelData = activeDuels[duelId].data
    
    -- デュエル開始
    activeDuels[duelId] = {
        status = 'active',
        duelId = duelId,
        player1 = duelData.sender,
        player2 = duelData.target,
        arenaIndex = duelData.arenaIndex,
        rounds = duelData.rounds,
        currentRound = 1,
        weapon = duelData.weapon,
        scores = {
            player1 = 0,
            player2 = 0
        },
        spectators = {},
        startTime = os.time()
    }
    
    -- 両プレイヤーに通知
    TriggerClientEvent('ox_lib:notify', duelData.sender, {
        title = 'デュエルシステム',
        description = Config.Text.duel_accepted,
        type = 'success',
        position = Config.UI.notificationPosition
    })
    
    TriggerClientEvent('ox_lib:notify', duelData.target, {
        title = 'デュエルシステム',
        description = Config.Text.duel_accepted,
        type = 'success',
        position = Config.UI.notificationPosition
    })
    
    -- デュエル開始
    Wait(1000)
    TriggerClientEvent('ng-duelsystem:client:startDuel', duelData.sender, activeDuels[duelId])
    TriggerClientEvent('ng-duelsystem:client:startDuel', duelData.target, activeDuels[duelId])
    
    if Config.Debug then
        print('[ng-duelsystem] デュエル開始:', duelId)
        print('Player1:', duelData.sender, 'Player2:', duelData.target)
    end
end)

-- ===================================
-- デュエル拒否
-- ===================================
RegisterNetEvent('ng-duelsystem:server:declineDuel', function(duelId)
    local src = source
    
    if not activeDuels[duelId] or activeDuels[duelId].status ~= 'pending' then return end
    
    local duelData = activeDuels[duelId].data
    
    TriggerClientEvent('ox_lib:notify', duelData.sender, {
        title = 'デュエルシステム',
        description = Config.Text.duel_declined,
        type = 'error',
        position = Config.UI.notificationPosition
    })
    
    activeDuels[duelId] = nil
end)

-- ===================================
-- プレイヤー死亡処理
-- ===================================
RegisterNetEvent('ng-duelsystem:server:playerDied', function(duelId)
    local src = source
    
    if not activeDuels[duelId] then return end
    
    local duel = activeDuels[duelId]
    local winner, loser
    
    -- 勝者と敗者を判定
    if src == duel.player1 then
        winner = duel.player2
        loser = duel.player1
        duel.scores.player2 = duel.scores.player2 + 1
    else
        winner = duel.player1
        loser = duel.player2
        duel.scores.player1 = duel.scores.player1 + 1
    end
    
    -- リスポーン処理
    TriggerClientEvent('ng-duelsystem:client:handleDeath', loser, false)
    TriggerClientEvent('ng-duelsystem:client:handleDeath', winner, true)
    
    -- ラウンド終了通知
    Wait(Config.DuelSettings.RespawnTime * 1000)
    TriggerClientEvent('ng-duelsystem:client:roundEnd', duel.player1, winner, duel.scores)
    TriggerClientEvent('ng-duelsystem:client:roundEnd', duel.player2, winner, duel.scores)
    
    -- 勝利条件チェック
    local roundsToWin = math.ceil(duel.rounds / 2)
    
    if duel.scores.player1 >= roundsToWin or duel.scores.player2 >= roundsToWin then
        -- デュエル終了
        Wait(2000)
        EndDuel(duelId)
    else
        -- 次のラウンド
        duel.currentRound = duel.currentRound + 1
        Wait(3000)
        TriggerClientEvent('ng-duelsystem:client:startDuel', duel.player1, duel)
        TriggerClientEvent('ng-duelsystem:client:startDuel', duel.player2, duel)
    end
    
    if Config.Debug then
        print('[ng-duelsystem] プレイヤー死亡:', src)
        print('スコア:', duel.scores.player1, '-', duel.scores.player2)
    end
end)

-- ===================================
-- デュエル終了
-- ===================================
function EndDuel(duelId)
    local duel = activeDuels[duelId]
    if not duel then return end
    
    local winner, loser
    local finalScores = duel.scores
    
    -- 勝者判定
    if duel.scores.player1 > duel.scores.player2 then
        winner = duel.player1
        loser = duel.player2
    elseif duel.scores.player2 > duel.scores.player1 then
        winner = duel.player2
        loser = duel.player1
    else
        -- 引き分け（通常は発生しない）
        winner = nil
        loser = nil
    end
    
    -- 報酬処理
    local winnerReward = 0
    local loserReward = 0
    
    if Config.Rewards.enabled and winner then
        local WinnerPlayer = QBCore.Functions.GetPlayer(winner)
        local LoserPlayer = QBCore.Functions.GetPlayer(loser)
        
        if WinnerPlayer then
            winnerReward = Config.Rewards.winReward.money
            if Config.Rewards.winReward.type == 'cash' then
                WinnerPlayer.Functions.AddMoney('cash', winnerReward, 'duel-win')
            else
                WinnerPlayer.Functions.AddMoney('bank', winnerReward, 'duel-win')
            end
        end
        
        if LoserPlayer then
            loserReward = Config.Rewards.loseReward.money
            if Config.Rewards.loseReward.type == 'cash' then
                LoserPlayer.Functions.AddMoney('cash', loserReward, 'duel-lose')
            else
                LoserPlayer.Functions.AddMoney('bank', loserReward, 'duel-lose')
            end
        end
    end
    
    -- 統計更新
    if Config.Statistics.saveToDatabase then
        UpdatePlayerStats(duel.player1, winner == duel.player1, duel.scores.player1, duel.scores.player2)
        UpdatePlayerStats(duel.player2, winner == duel.player2, duel.scores.player2, duel.scores.player1)
    end
    
    -- 終了通知
    TriggerClientEvent('ng-duelsystem:client:endDuel', duel.player1, winner, finalScores, winner == duel.player1 and winnerReward or loserReward)
    TriggerClientEvent('ng-duelsystem:client:endDuel', duel.player2, winner, finalScores, winner == duel.player2 and winnerReward or loserReward)
    
    -- 観客に通知
    for _, spectatorId in pairs(duel.spectators) do
        TriggerClientEvent('ox_lib:notify', spectatorId, {
            title = 'デュエルシステム',
            description = Config.Text.duel_ended,
            type = 'info',
            position = Config.UI.notificationPosition
        })
    end
    
    -- デュエルデータ削除
    activeDuels[duelId] = nil
    
    if Config.Debug then
        print('[ng-duelsystem] デュエル終了:', duelId)
        print('勝者:', winner, '最終スコア:', finalScores.player1, '-', finalScores.player2)
    end
end

-- ===================================
-- プレイヤー統計更新
-- ===================================
function UpdatePlayerStats(playerId, isWinner, kills, deaths)
    local Player = QBCore.Functions.GetPlayer(playerId)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    MySQL.insert('INSERT INTO ng_duel_stats (citizenid, total_duels, wins, losses, kills, deaths) VALUES (?, 1, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE total_duels = total_duels + 1, wins = wins + ?, losses = losses + ?, kills = kills + ?, deaths = deaths + ?', {
        citizenid,
        isWinner and 1 or 0,
        isWinner and 0 or 1,
        kills,
        deaths,
        isWinner and 1 or 0,
        isWinner and 0 or 1,
        kills,
        deaths
    })
end

-- ===================================
-- 元の場所に戻す
-- ===================================
RegisterNetEvent('ng-duelsystem:server:returnToSpawn', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- プレイヤーの最後の位置を取得（簡易版）
    local coords = GetEntityCoords(GetPlayerPed(src))
    TriggerClientEvent('ng-duelsystem:client:returnToSpawn', src, coords)
end)

-- ===================================
-- 統計取得
-- ===================================
RegisterNetEvent('ng-duelsystem:server:getStats', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    MySQL.query('SELECT * FROM ng_duel_stats WHERE citizenid = ?', {citizenid}, function(result)
        if result and result[1] then
            local stats = result[1]
            stats.win_rate = stats.total_duels > 0 and (stats.wins / stats.total_duels * 100) or 0
            stats.kd_ratio = stats.deaths > 0 and (stats.kills / stats.deaths) or stats.kills
            TriggerClientEvent('ng-duelsystem:client:showStats', src, stats)
        else
            -- 統計がない場合
            local emptyStats = {
                total_duels = 0,
                wins = 0,
                losses = 0,
                kills = 0,
                deaths = 0,
                win_rate = 0,
                kd_ratio = 0
            }
            TriggerClientEvent('ng-duelsystem:client:showStats', src, emptyStats)
        end
    end)
end)

-- ===================================
-- ランキング取得
-- ===================================
RegisterNetEvent('ng-duelsystem:server:getRanking', function()
    local src = source
    
    MySQL.query('SELECT citizenid, total_duels, wins, losses FROM ng_duel_stats ORDER BY wins DESC LIMIT ?', {Config.Statistics.topPlayersCount}, function(result)
        if result then
            local rankings = {}
            for _, row in ipairs(result) do
                local Player = QBCore.Functions.GetPlayerByCitizenId(row.citizenid)
                local name
                
                if Player then
                    name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
                else
                    -- オフラインプレイヤーの名前取得
                    local playerData = MySQL.query.await('SELECT charinfo FROM players WHERE citizenid = ?', {row.citizenid})
                    if playerData and playerData[1] then
                        local charinfo = json.decode(playerData[1].charinfo)
                        name = charinfo.firstname .. ' ' .. charinfo.lastname
                    else
                        name = '不明'
                    end
                end
                
                table.insert(rankings, {
                    name = name,
                    wins = row.wins,
                    total_duels = row.total_duels,
                    win_rate = row.total_duels > 0 and (row.wins / row.total_duels * 100) or 0
                })
            end
            
            TriggerClientEvent('ng-duelsystem:client:showRanking', src, rankings)
        end
    end)
end)

-- ===================================
-- アクティブなデュエル取得
-- ===================================
RegisterNetEvent('ng-duelsystem:server:getActiveDuels', function(arenaIndex)
    local src = source
    local duels = {}
    
    for duelId, duel in pairs(activeDuels) do
        if duel.status == 'active' and (not arenaIndex or duel.arenaIndex == arenaIndex) then
            local Player1 = QBCore.Functions.GetPlayer(duel.player1)
            local Player2 = QBCore.Functions.GetPlayer(duel.player2)
            
            if Player1 and Player2 then
                table.insert(duels, {
                    duelId = duelId,
                    player1Name = Player1.PlayerData.charinfo.firstname .. ' ' .. Player1.PlayerData.charinfo.lastname,
                    player2Name = Player2.PlayerData.charinfo.firstname .. ' ' .. Player2.PlayerData.charinfo.lastname,
                    scores = duel.scores,
                    arenaIndex = duel.arenaIndex
                })
            end
        end
    end
    
    TriggerClientEvent('ng-duelsystem:client:showActiveDuels', src, duels)
end)

-- ===================================
-- 観戦開始
-- ===================================
RegisterNetEvent('ng-duelsystem:server:startSpectating', function(duelId)
    local src = source
    
    if not activeDuels[duelId] or activeDuels[duelId].status ~= 'active' then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'デュエルシステム',
            description = 'このデュエルは終了しました',
            type = 'error',
            position = Config.UI.notificationPosition
        })
        return
    end
    
    local duel = activeDuels[duelId]
    
    -- 観客数チェック
    if #duel.spectators >= Config.DuelSettings.MaxSpectators then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'デュエルシステム',
            description = '観客数が上限に達しています',
            type = 'error',
            position = Config.UI.notificationPosition
        })
        return
    end
    
    -- 観客リストに追加
    table.insert(duel.spectators, src)
    
    TriggerClientEvent('ng-duelsystem:client:startSpectate', src, duel)
end)

-- ===================================
-- 観戦終了
-- ===================================
RegisterNetEvent('ng-duelsystem:server:stopSpectating', function()
    local src = source
    
    -- すべてのデュエルから観客を削除
    for _, duel in pairs(activeDuels) do
        if duel.status == 'active' then
            for i, spectatorId in ipairs(duel.spectators) do
                if spectatorId == src then
                    table.remove(duel.spectators, i)
                    break
                end
            end
        end
    end
    
    TriggerClientEvent('ng-duelsystem:server:returnToSpawn', src)
end)

-- ===================================
-- プレイヤー切断処理
-- ===================================
RegisterNetEvent('playerDropped', function()
    local src = source
    
    -- デュエル中のプレイヤーが切断した場合
    for duelId, duel in pairs(activeDuels) do
        if duel.status == 'active' and (duel.player1 == src or duel.player2 == src) then
            local opponent = duel.player1 == src and duel.player2 or duel.player1
            
            TriggerClientEvent('ox_lib:notify', opponent, {
                title = 'デュエルシステム',
                description = '相手が切断したためデュエルが終了しました',
                type = 'error',
                position = Config.UI.notificationPosition
            })
            
            TriggerClientEvent('ng-duelsystem:client:endDuel', opponent, opponent, {player1 = 0, player2 = 0}, 0)
            
            activeDuels[duelId] = nil
            break
        end
    end
    
    -- 観客として参加していた場合
    for _, duel in pairs(activeDuels) do
        if duel.status == 'active' then
            for i, spectatorId in ipairs(duel.spectators) do
                if spectatorId == src then
                    table.remove(duel.spectators, i)
                    break
                end
            end
        end
    end
end)

-- ===================================
-- 管理者コマンド
-- ===================================
QBCore.Commands.Add('duelreset', 'すべてのデュエルをリセット（管理者専用）', {}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- 権限チェック
    local hasPermission = false
    for _, group in ipairs(Config.Permissions.adminCommands) do
        if QBCore.Functions.HasPermission(src, group) then
            hasPermission = true
            break
        end
    end
    
    if not hasPermission then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'デュエルシステム',
            description = '権限がありません',
            type = 'error',
            position = Config.UI.notificationPosition
        })
        return
    end
    
    -- すべてのデュエルを終了
    for duelId, duel in pairs(activeDuels) do
        if duel.status == 'active' then
            TriggerClientEvent('ng-duelsystem:client:endDuel', duel.player1, nil, {player1 = 0, player2 = 0}, 0)
            TriggerClientEvent('ng-duelsystem:client:endDuel', duel.player2, nil, {player1 = 0, player2 = 0}, 0)
        end
    end
    
    activeDuels = {}
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'デュエルシステム',
        description = 'すべてのデュエルをリセットしました',
        type = 'success',
        position = Config.UI.notificationPosition
    })
end, Config.Permissions.adminCommands[1])

-- ===================================
-- デバッグコマンド
-- ===================================
if Config.Debug then
    RegisterCommand('duelinfo', function(source, args)
        print('===== アクティブなデュエル =====')
        for duelId, duel in pairs(activeDuels) do
            print('ID:', duelId)
            print('Status:', duel.status)
            if duel.status == 'active' then
                print('Players:', duel.player1, 'vs', duel.player2)
                print('Scores:', duel.scores.player1, '-', duel.scores.player2)
                print('Round:', duel.currentRound, '/', duel.rounds)
            end
            print('---')
        end
    end, false)
end

-- ===================================
-- リソース停止時のクリーンアップ
-- ===================================
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        -- すべてのアクティブなデュエルを終了
        for duelId, duel in pairs(activeDuels) do
            if duel.status == 'active' then
                TriggerClientEvent('ng-duelsystem:client:endDuel', duel.player1, nil, {player1 = 0, player2 = 0}, 0)
                TriggerClientEvent('ng-duelsystem:client:endDuel', duel.player2, nil, {player1 = 0, player2 = 0}, 0)
            end
        end
        
        if Config.Debug then
            print('[ng-duelsystem] リソース停止 - クリーンアップ完了')
        end
    end
end)