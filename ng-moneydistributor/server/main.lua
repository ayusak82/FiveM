local QBCore = exports['qb-core']:GetCoreObject()

-- CitizenID取得のイベント
RegisterNetEvent('ng-moneydistributor:server:getPlayerCitizenID', function(playerId)
    local src = source
    local targetPlayer = QBCore.Functions.GetPlayer(tonumber(playerId))
    
    if targetPlayer then
        local citizenId = targetPlayer.PlayerData.citizenid
        -- クライアントにCitizenIDを送信
        TriggerClientEvent('ng-moneydistributor:client:receiveCitizenID', src, playerId, citizenId)
    end
end)

-- お金の分配処理
RegisterNetEvent('ng-moneydistributor:server:distributeMoney', function(amount, paymentType, playerIds)
    local src = source
    local srcPlayer = QBCore.Functions.GetPlayer(src)
    
    if not srcPlayer then return end
    
    -- 選択したプレイヤー数を取得
    local playerCount = #playerIds
    
    -- 合計金額を計算（選択した人数 × 金額）
    local totalAmount = amount * playerCount
    
    -- 支払者の残高をチェック
    local balance = 0
    if paymentType == 'cash' then
        balance = srcPlayer.PlayerData.money.cash
    else
        balance = srcPlayer.PlayerData.money.bank
    end
    
    if balance < totalAmount then
        TriggerClientEvent('ox_lib:notify', src, {
            title = Config.UITitle,
            description = '残高が不足しています',
            type = 'error'
        })
        return
    end
    
    -- 支払者からお金を引く
    if paymentType == 'cash' then
        srcPlayer.Functions.RemoveMoney('cash', totalAmount, "money-distribution")
    else
        srcPlayer.Functions.RemoveMoney('bank', totalAmount, "money-distribution")
    end
    
    -- プレイヤーにお金を分配
    local successCount = 0
    
    for _, playerId in ipairs(playerIds) do
        local targetPlayer = QBCore.Functions.GetPlayer(tonumber(playerId))
        
        if targetPlayer then
            if paymentType == 'cash' then
                targetPlayer.Functions.AddMoney('cash', amount, "money-distribution-received")
            else
                targetPlayer.Functions.AddMoney('bank', amount, "money-distribution-received")
            end
            
            -- 受け取り通知
            TriggerClientEvent('ox_lib:notify', playerId, {
                title = Config.UITitle,
                description = string.format('%s からお金を受け取りました: $%s', GetPlayerName(src), amount),
                type = 'success'
            })
            
            successCount = successCount + 1
        end
    end
    
    -- 分配完了通知
    TriggerClientEvent('ox_lib:notify', src, {
        title = Config.UITitle,
        description = string.format('%d人のプレイヤーに$%sずつ、合計$%sを支払いました', 
            successCount, amount, totalAmount),
        type = 'success'
    })
    
    -- ログ
    print(string.format('[ng-moneydistributor] %s が %d人のプレイヤーに$%sずつ、合計$%sを支払いました（支払方法: %s）',
        GetPlayerName(src), successCount, amount, totalAmount, paymentType))
end)