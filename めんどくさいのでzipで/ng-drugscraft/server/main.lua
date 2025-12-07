local QBCore = exports['qb-core']:GetCoreObject()

-- 警察への通報イベント
local lastAlertTime = 0
local cooldown = 10000 -- 10秒のクールダウン

RegisterNetEvent('ng-drugscraft:server:alertPolice', function(coords, craftLabel)
    local src = source
    if not Config.PoliceAlert.enabled then return end
    
    -- クールダウンチェック（既存の通知が消えるまで次の通知を出さない）
    local currentTime = os.time() * 1000
    if currentTime - lastAlertTime < cooldown then
        return -- クールダウン中なら通報しない
    end
    
    -- プレイヤー名を取得
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local characterName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
    
    -- 警察官を探す
    local policePlayers = QBCore.Functions.GetQBPlayers()
    local policeCount = 0
    
    for _, v in pairs(policePlayers) do
        if v.PlayerData.job.name == Config.PoliceAlert.job then
            -- 警察に通知とブリップを送信
            TriggerClientEvent('ng-drugscraft:client:createPoliceBlip', v.PlayerData.source, coords, craftLabel)
            policeCount = policeCount + 1
        end
    end
    
    -- 警察官がいた場合、クールダウンを設定
    if policeCount > 0 then
        lastAlertTime = currentTime
    end
    
    -- 実装済みのdispatchシステムがある場合、それを使用することも可能
    -- 例: exports['ps-dispatch']:CustomAlert({...})
end)

-- 材料が十分にあるかチェックする関数
local function hasEnoughMaterials(src, recipe, amount)
    for _, ingredient in ipairs(recipe.ingredients) do
        local requiredAmount = ingredient.amount * amount
        -- ox_inventoryの正しい使い方に修正（count指定なしで直接数量を取得）
        local itemCount = exports.ox_inventory:GetItemCount(src, ingredient.item)
        
        if not itemCount or itemCount < requiredAmount then
            return false
        end
    end
    return true
end

-- 警察官の人数をカウントする関数
local function countPolice()
    local policeCount = 0
    local players = QBCore.Functions.GetQBPlayers()
    
    for _, v in pairs(players) do
        if v.PlayerData.job.name == Config.PoliceAlert.job then
            policeCount = policeCount + 1
        end
    end
    
    return policeCount
end

-- 警察官の人数をチェックするイベント
RegisterNetEvent('ng-drugscraft:server:checkPoliceCount', function()
    local src = source
    local requiredCops = Config.PoliceAlert.requiredCops or 0
    local currentCops = countPolice()
    
    TriggerClientEvent('ng-drugscraft:client:policeCountResult', src, currentCops, requiredCops)
end)

-- クラフト処理
RegisterNetEvent('ng-drugscraft:server:craftItem', function(recipeId, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- 数値変換を確実に行う
    amount = tonumber(amount) or 1
    
    -- 警察官の人数チェック
    local requiredCops = Config.PoliceAlert.requiredCops or 0
    local currentCops = countPolice()
    
    if currentCops < requiredCops then
        TriggerClientEvent('ox_lib:notify', src, {
            title = '製造不可',
            description = string.format('警察官が%d人以上いないと製造できません（現在%d人）', requiredCops, currentCops),
            type = 'error'
        })
        return
    end

    -- プレイヤーが死亡しているかチェック
    if Player.PlayerData.metadata['isdead'] then
        TriggerClientEvent('ox_lib:notify', src, {
            title = '製造不可',
            description = '意識がありません',
            type = 'error'
        })
        return
    end
    
    -- 警察ジョブのチェックを追加
    if Player.PlayerData.job.name == Config.PoliceAlert.job then
        TriggerClientEvent('ox_lib:notify', src, {
            title = '製造不可',
            description = '警察官は製造できません',
            type = 'error'
        })
        return
    end

    local recipe = Config.CraftRecipes[recipeId]
    if not recipe then return end

    -- 材料が十分あるかチェック
    if not hasEnoughMaterials(src, recipe, amount) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = '材料不足',
            description = '必要な材料が足りません',
            type = 'error'
        })
        return
    end

    -- 出力アイテムの数量を計算（修正箇所）
    local outputAmount = recipe.output.amount * amount
    
    -- デバッグ用ログ出力
    print(string.format("Crafting %s: amount=%d, outputAmount=%d", recipe.label, amount, outputAmount))
    
    -- 出力アイテムを保持できるかチェック
    if not exports.ox_inventory:CanCarryItem(src, recipe.output.item, outputAmount) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'インベントリ不足',
            description = '出力アイテムを持つスペースがありません',
            type = 'error'
        })
        return
    end

    -- 材料を消費（１つずつ処理）
    local allRemoved = true
    for _, ingredient in ipairs(recipe.ingredients) do
        local requiredAmount = ingredient.amount * amount
        local success = exports.ox_inventory:RemoveItem(src, ingredient.item, requiredAmount)
        if not success then
            allRemoved = false
            break
        end
    end

    -- 材料の消費に失敗した場合
    if not allRemoved then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'エラー',
            description = '材料の消費に失敗しました',
            type = 'error'
        })
        return
    end

    -- アイテムを付与（正確な数量を使用）
    exports.ox_inventory:AddItem(src, recipe.output.item, outputAmount)
    
    -- 通知
    TriggerClientEvent('ox_lib:notify', src, {
        title = '製造成功',
        description = string.format('%s を %d 個製造しました', recipe.label, outputAmount),
        type = 'success'
    })
end)