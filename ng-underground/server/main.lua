local QBCore = exports['qb-core']:GetCoreObject()

-- 作業完了イベント
RegisterNetEvent('ng-underground:workComplete', function(workType, success)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Job制限チェック
    if not HasAllowedJob(Player.PlayerData.job.name) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'エラー',
            description = '権限がありません',
            type = 'error'
        })
        return
    end
    
    if success then
        -- 成功時の報酬処理
        ProcessWorkReward(src, Player, workType)
    else
        -- 失敗時の少額報酬
        ProcessFailureReward(src, Player, workType)
    end
end)

-- 作業報酬処理
function ProcessWorkReward(src, Player, workType)
    local rewardConfig = nil
    
    if workType == 'chemical' then
        rewardConfig = Config.Rewards.Chemical
    elseif workType == 'mechanical' then
        rewardConfig = Config.Rewards.Mechanical
    else
        return
    end
    
    -- アイテム報酬
    local itemReward = GetRandomReward(rewardConfig.Items)
    if itemReward then
        local amount = math.random(itemReward.amount[1], itemReward.amount[2])
        
        -- インベントリに追加
        if exports.ox_inventory:CanCarryItem(src, itemReward.item, amount) then
            exports.ox_inventory:AddItem(src, itemReward.item, amount)
            
            TriggerClientEvent('ox_lib:notify', src, {
                title = '報酬獲得',
                description = string.format('%s x%d を獲得しました', itemReward.label, amount),
                type = 'success'
            })
        else
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'インベントリ満杯',
                description = 'アイテムを受け取れませんでした',
                type = 'error'
            })
        end
    end
    
    -- 現金報酬
    local moneyAmount = math.random(rewardConfig.Money.min, rewardConfig.Money.max)
    Player.Functions.AddMoney('cash', moneyAmount)
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = '報酬獲得',
        description = string.format('$%d を獲得しました', moneyAmount),
        type = 'success'
    })
    
    -- ログ記録
    if Config.Debug then
        print(string.format('[ng-underground] Player %s completed %s work - Item: %s x%d, Money: $%d', 
            Player.PlayerData.name, workType, itemReward and itemReward.item or 'none', 
            itemReward and amount or 0, moneyAmount))
    end
end

-- 失敗時報酬処理
function ProcessFailureReward(src, Player, workType)
    local rewardConfig = nil
    
    if workType == 'chemical' then
        rewardConfig = Config.Rewards.Chemical
    elseif workType == 'mechanical' then
        rewardConfig = Config.Rewards.Mechanical
    else
        return
    end
    
    -- 失敗時は少額の現金のみ
    local moneyAmount = math.floor(rewardConfig.Money.min * 0.3) -- 30%の報酬
    Player.Functions.AddMoney('cash', moneyAmount)
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = '少額報酬',
        description = string.format('失敗したが$%d を獲得しました', moneyAmount),
        type = 'inform'
    })
    
    -- ログ記録
    if Config.Debug then
        print(string.format('[ng-underground] Player %s failed %s work - Money: $%d', 
            Player.PlayerData.name, workType, moneyAmount))
    end
end

-- ランダム報酬取得
function GetRandomReward(items)
    local totalChance = 0
    for _, item in pairs(items) do
        totalChance = totalChance + item.chance
    end
    
    local random = math.random(1, totalChance)
    local currentChance = 0
    
    for _, item in pairs(items) do
        currentChance = currentChance + item.chance
        if random <= currentChance then
            return item
        end
    end
    
    return items[1] -- フォールバック
end

-- Job制限チェック
function HasAllowedJob(jobName)
    for _, allowedJob in pairs(Config.AllowedJobs) do
        if jobName == allowedJob then
            return true
        end
    end
    return false
end

-- プレイヤー統計取得コマンド（管理者用）
QBCore.Commands.Add('ng-underground-stats', '地下基地作業統計を確認', {{name = 'id', help = 'プレイヤーID (オプション)'}}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- 管理者チェック
    if Player.PlayerData.job.name ~= 'admin' and not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'エラー',
            description = '権限がありません',
            type = 'error'
        })
        return
    end
    
    local targetId = args[1] and tonumber(args[1]) or src
    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    
    if not targetPlayer then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'エラー',
            description = 'プレイヤーが見つかりません',
            type = 'error'
        })
        return
    end
    
    -- 統計情報を送信（実装時はデータベースから取得）
    TriggerClientEvent('ox_lib:notify', src, {
        title = '統計情報',
        description = string.format('プレイヤー: %s\n現在のjob: %s', 
            targetPlayer.PlayerData.name, targetPlayer.PlayerData.job.name),
        type = 'inform'
    })
end, 'admin')

-- アイテム使用制限（必要に応じて）
QBCore.Functions.CreateUseableItem('chemical_low', function(source, item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'アイテム使用',
        description = '低品質化学物質を使用しました',
        type = 'inform'
    })
end)

QBCore.Functions.CreateUseableItem('chemical_mid', function(source, item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'アイテム使用',
        description = '中品質化学物質を使用しました',
        type = 'inform'
    })
end)

QBCore.Functions.CreateUseableItem('chemical_high', function(source, item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'アイテム使用',
        description = '高品質化学物質を使用しました',
        type = 'inform'
    })
end)

QBCore.Functions.CreateUseableItem('mechanical_low', function(source, item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'アイテム使用',
        description = '低品質機械部品を使用しました',
        type = 'inform'
    })
end)

QBCore.Functions.CreateUseableItem('mechanical_mid', function(source, item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'アイテム使用',
        description = '中品質機械部品を使用しました',
        type = 'inform'
    })
end)

QBCore.Functions.CreateUseableItem('mechanical_high', function(source, item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'アイテム使用',
        description = '高品質機械部品を使用しました',
        type = 'inform'
    })
end)

-- サーバー開始時の初期化
CreateThread(function()
    print('^2[ng-underground]^7 Underground Base Job System loaded successfully')
end)

-- デバッグ機能
if Config.Debug then
    -- 報酬テストコマンド
    QBCore.Commands.Add('ng-test-reward', 'テスト報酬', {{name = 'type', help = 'chemical または mechanical'}}, true, function(source, args)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        
        if not Player then return end
        
        local workType = args[1]
        if workType ~= 'chemical' and workType ~= 'mechanical' then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'エラー',
                description = 'chemical または mechanical を指定してください',
                type = 'error'
            })
            return
        end
        
        ProcessWorkReward(src, Player, workType)
    end, 'admin')
    
    -- アイテム追加コマンド
    QBCore.Commands.Add('ng-add-item', 'アイテム追加', {
        {name = 'item', help = 'アイテム名'}, 
        {name = 'amount', help = '数量'}
    }, true, function(source, args)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        
        if not Player then return end
        
        local item = args[1]
        local amount = tonumber(args[2]) or 1
        
        if exports.ox_inventory:CanCarryItem(src, item, amount) then
            exports.ox_inventory:AddItem(src, item, amount)
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'アイテム追加',
                description = string.format('%s x%d を追加しました', item, amount),
                type = 'success'
            })
        else
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'エラー',
                description = 'インベントリに空きがありません',
                type = 'error'
            })
        end
    end, 'admin')
end