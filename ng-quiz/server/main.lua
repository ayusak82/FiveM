local QBCore = exports['qb-core']:GetCoreObject()

-- クイズ成功時のイベント
RegisterNetEvent('ng-quiz:onSuccess', function(quizId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- 報酬設定を取得
    local reward = Config.Rewards[quizId]
    if not reward then
        --print(string.format('[ng-quiz] エラー: クイズID "%s" の報酬設定が見つかりません', quizId))
        return
    end
    
    -- ログ出力
    --print(string.format('[ng-quiz] プレイヤー %s (ID: %d) がクイズ "%s" に全問正解しました', 
    --      Player.PlayerData.name, src, quizId))
    
    -- 報酬を付与
    if reward.money and reward.money > 0 then
        Player.Functions.AddMoney('cash', reward.money, 'Quiz Reward: ' .. quizId)
        --print(string.format('[ng-quiz] プレイヤー %s に $%d を付与しました', Player.PlayerData.name, reward.money))
    end
    
    if reward.item then
        Player.Functions.AddItem(reward.item.name, reward.item.count, false, reward.item.metadata)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[reward.item.name], 'add')
        --print(string.format('[ng-quiz] プレイヤー %s にアイテム "%s" を付与しました', Player.PlayerData.name, reward.item.name))
    end
    
    -- 必要に応じて追加の処理を実装
    -- 例: データベースへの記録、統計の更新など
end)

-- クイズ失敗時のイベント
RegisterNetEvent('ng-quiz:onFailure', function(quizId, correctAnswers, totalQuestions)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- ログ出力
    --print(string.format('[ng-quiz] プレイヤー %s (ID: %d) がクイズ "%s" に失敗しました (%d/%d 正解)', 
    --      Player.PlayerData.name, src, quizId, correctAnswers, totalQuestions))
    
    -- 必要に応じて追加の処理を実装
    -- 例: 失敗回数の記録、再挑戦の制限、参加賞の付与など
    
    -- 参加賞の例（コメントアウト）
    -- if correctAnswers > 0 then
    --     local participationReward = math.floor(correctAnswers * 50) -- 正解数 × 50ドル
    --     Player.Functions.AddMoney('cash', participationReward, 'Quiz Participation Reward')
    --     --print(string.format('[ng-quiz] プレイヤー %s に参加賞 $%d を付与しました', Player.PlayerData.name, participationReward))
    -- end
end)

-- プレイヤーのクイズ統計を取得するコマンド（管理者用）
QBCore.Commands.Add('quizstats', 'クイズ統計を表示', {}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- 管理者権限チェック（必要に応じて）
    -- if Player.PlayerData.job.name ~= 'admin' then
    --     TriggerClientEvent('QBCore:Notify', src, '権限がありません', 'error')
    --     return
    -- end
    
    -- 統計情報をクライアントに送信（実装例）
    TriggerClientEvent('QBCore:Notify', src, 'クイズ統計機能は開発中です', 'inform')
end)

-- クイズ情報を取得するコマンド（管理者用）
QBCore.Commands.Add('quizinfo', 'クイズ情報を表示', {}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- 管理者権限チェック（必要に応じて）
    -- if Player.PlayerData.job.name ~= 'admin' then
    --     TriggerClientEvent('QBCore:Notify', src, '権限がありません', 'error')
    --     return
    -- end
    
    -- クイズ情報を表示
    local quizCount = #Config.Quizzes
    local totalQuestions = 0
    
    for _, quiz in ipairs(Config.Quizzes) do
        totalQuestions = totalQuestions + #quiz.questions
    end
    
    --print(string.format('[ng-quiz] クイズ情報 - 総クイズ数: %d, 総問題数: %d', quizCount, totalQuestions))
    TriggerClientEvent('QBCore:Notify', src, string.format('クイズ数: %d, 総問題数: %d', quizCount, totalQuestions), 'inform')
end)

-- 特定のプレイヤーに報酬を手動で付与するコマンド（管理者用）
QBCore.Commands.Add('givequizreward', 'クイズ報酬を手動で付与', {{name='id', help='プレイヤーID'}, {name='quizId', help='クイズID'}}, true, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local targetId = tonumber(args[1])
    local quizId = args[2]
    
    if not Player then return end
    
    -- 管理者権限チェック（必要に応じて）
    -- if Player.PlayerData.job.name ~= 'admin' then
    --     TriggerClientEvent('QBCore:Notify', src, '権限がありません', 'error')
    --     return
    -- end
    
    if not targetId or not quizId then
        TriggerClientEvent('QBCore:Notify', src, '使用方法: /givequizreward [プレイヤーID] [クイズID]', 'error')
        return
    end
    
    local TargetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not TargetPlayer then
        TriggerClientEvent('QBCore:Notify', src, 'プレイヤーが見つかりません', 'error')
        return
    end
    
    local reward = Config.Rewards[quizId]
    if not reward then
        TriggerClientEvent('QBCore:Notify', src, '無効なクイズIDです', 'error')
        return
    end
    
    -- 報酬を付与
    if reward.money and reward.money > 0 then
        TargetPlayer.Functions.AddMoney('cash', reward.money, 'Admin Quiz Reward')
    end
    
    if reward.item then
        TargetPlayer.Functions.AddItem(reward.item.name, reward.item.count, false, reward.item.metadata)
        TriggerClientEvent('inventory:client:ItemBox', targetId, QBCore.Shared.Items[reward.item.name], 'add')
    end
    
    TriggerClientEvent('QBCore:Notify', src, string.format('プレイヤー %s に報酬を付与しました', TargetPlayer.PlayerData.name), 'success')
    TriggerClientEvent('QBCore:Notify', targetId, 'クイズ報酬を受け取りました！', 'success')
    
    --print(string.format('[ng-quiz] 管理者 %s がプレイヤー %s に報酬を付与しました (クイズ: %s)', 
    --      Player.PlayerData.name, TargetPlayer.PlayerData.name, quizId))
end)

-- リソース開始時のログ
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        --print('==================================================')
        --print('[ng-quiz] クイズスクリプトが正常に開始されました')
        --print('[ng-quiz] NPC座標: ' .. tostring(Config.NPC.coords))
        --print('[ng-quiz] 利用可能なクイズ:')
        
        for i, quiz in ipairs(Config.Quizzes) do
            --print(string.format('[ng-quiz]   %d. %s (%s) - %d問', i, quiz.name, quiz.difficulty, #quiz.questions))
        end
        
        --print('[ng-quiz] HTML UI が有効になりました')
        --print('==================================================')
    end
end)

-- リソース停止時のログ
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        --print('[ng-quiz] クイズスクリプトが停止されました')
    end
end)

-- プレイヤー接続時の処理（必要に応じて）
AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    -- プレイヤーがログインした時の処理
    -- 例: クイズ統計の初期化、ウェルカムメッセージなど
end)

-- プレイヤー切断時の処理（必要に応じて）
AddEventHandler('QBCore:Server:OnPlayerUnload', function(src)
    -- プレイヤーがログアウトした時の処理
    -- 例: 進行中のクイズの中断処理など
end)