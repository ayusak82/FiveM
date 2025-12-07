local QBCore = exports['qb-core']:GetCoreObject()

-- プレイヤーのサブスクリプション情報を取得
local function GetPlayerSubscription(citizenId)
    return exports['ng-subscribe']:GetPlayerSubscription(citizenId)
end

-- ナンバープレートの生成
local function GeneratePlate()
    local plate = string.format('VIP%05d', math.random(0, 99999))
    local result = MySQL.query.await('SELECT 1 FROM player_vehicles WHERE plate = ?', {plate})
    if result and #result > 0 then
        return GeneratePlate()
    end
    return plate
end

-- 車両が禁止リストに含まれているかチェック
local function IsVehicleBlacklisted(vehicleName, planName)
    for _, blacklistedVehicle in ipairs(Config.Vehicles.BlacklistedVehicles) do
        if vehicleName:lower() == blacklistedVehicle:lower() then
            return true
        end
    end

    if Config.Vehicles.PlanBlacklist[planName] then
        for _, blacklistedVehicle in ipairs(Config.Vehicles.PlanBlacklist[planName]) do
            if vehicleName:lower() == blacklistedVehicle:lower() then
                return true
            end
        end
    end

    return false
end

-- 報酬の付与
local function GiveRewards(source, planName)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end

    local plan = Config.Plans[planName]
    if not plan then return false end

    -- デバッグ出力
    --print(string.format('[ng-subscribe] Giving rewards to player %s (Plan: %s)', Player.PlayerData.citizenid, planName))

    -- 現金の付与
    Player.Functions.AddMoney('cash', plan.rewards.cash)
    --print(string.format('[ng-subscribe] Added cash: $%s', plan.rewards.cash))

    -- アイテムの付与（エラーハンドリング付き）
    local itemList = {}
    for itemName, amount in pairs(plan.rewards.items) do
        -- アイテムの存在確認
        if QBCore.Shared.Items[itemName] then
            -- インベントリの空き容量確認
            local canCarry = exports.ox_inventory:CanCarryItem(source, itemName, amount)
            if canCarry then
                -- アイテム付与
                exports.ox_inventory:AddItem(source, itemName, amount)
                table.insert(itemList, QBCore.Shared.Items[itemName].label .. ' x' .. amount)
                --print(string.format('[ng-subscribe] Added item: %s x%d', itemName, amount))
            else
                --print(string.format('[ng-subscribe] Cannot carry item: %s x%d', itemName, amount))
                TriggerClientEvent('QBCore:Notify', source, '一部のアイテムを持ち切れません: ' .. QBCore.Shared.Items[itemName].label, 'error')
            end
        else
            --print(string.format('[ng-subscribe] Invalid item: %s', itemName))
        end
    end

    -- Webhook送信
    exports['ng-subscribe']:SendLog('rewards', {
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        Player.PlayerData.citizenid,
        plan.label,
        plan.rewards.cash,
        table.concat(itemList, ', ')
    })

    -- 履歴記録
    exports['ng-subscribe']:LogSubscriptionHistory(
        Player.PlayerData.citizenid,
        planName,
        'rewards_claimed',
        nil,
        nil
    )

    return true
end

-- 車両の所有権付与
local function GiveVehicle(source, citizenId, vehicleName, category)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end

    local plate = GeneratePlate()
    
    -- デフォルトの車両プロップスを設定
    local props = {
        model = GetHashKey(vehicleName),
        plate = plate,
        fuel = 100,
        bodyHealth = 1000.0,
        engineHealth = 1000.0,
        tankHealth = 1000.0,
        dirtLevel = 0.0
    }

    -- トランザクション的な処理
    local success = MySQL.insert.await([[
        INSERT INTO player_vehicles 
            (license, citizenid, vehicle, plate, hash, mods, garage, fuel, engine, body, state) 
        VALUES 
            (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        Player.PlayerData.license,
        citizenId,
        vehicleName,
        plate,
        props.model,
        json.encode(props),
        'pillboxgarage',
        props.fuel,
        props.engineHealth,
        props.bodyHealth,
        1
    })

    if success then
        -- 現在のサブスクリプションを取得
        local currentSub = GetPlayerSubscription(Player.PlayerData.citizenid)
        if currentSub then
            -- Webhook送信
            exports['ng-subscribe']:SendLog('vehicles', {
                Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                Player.PlayerData.citizenid,
                Config.Plans[currentSub.plan_name].label,
                vehicleName,
                category
            })

            -- 履歴に記録
            exports['ng-subscribe']:LogSubscriptionHistory(
                Player.PlayerData.citizenid,
                currentSub.plan_name,
                'vehicle_claimed',
                nil,
                vehicleName
            )
        end

        TriggerClientEvent('QBCore:Notify', source, Config.Messages.success.vehicle_claimed, 'success')
        return true
    end

    return false
end

-- コールバック登録
lib.callback.register('ng-subscribe:server:getSubscription', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return nil end
    return GetPlayerSubscription(Player.PlayerData.citizenid)
end)

lib.callback.register('ng-subscribe:server:claimRewards', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end

    local subscription = GetPlayerSubscription(Player.PlayerData.citizenid)
    if not subscription or subscription.rewards_claimed then return false end

    if GiveRewards(source, subscription.plan_name) then
        MySQL.update.await('UPDATE player_subscriptions SET rewards_claimed = 1 WHERE id = ?', {
            subscription.id
        })
        return true
    end
    return false
end)

lib.callback.register('ng-subscribe:server:claimVehicle', function(source, vehicleName, category)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end

    local subscription = GetPlayerSubscription(Player.PlayerData.citizenid)
    if not subscription or subscription.vehicle_claimed then return false end

    if IsVehicleBlacklisted(vehicleName, subscription.plan_name) then
        TriggerClientEvent('QBCore:Notify', source, Config.Messages.error.vehicle_blacklisted, 'error')
        return false
    end

    -- カテゴリーチェック
    local plan = Config.Plans[subscription.plan_name]
    local categoryValid = false
    for _, allowedCategory in ipairs(plan.rewards.vehicle_categories) do
        if allowedCategory == category then
            categoryValid = true
            break
        end
    end
    if not categoryValid then return false end

    if GiveVehicle(source, Player.PlayerData.citizenid, vehicleName, category) then
        MySQL.update.await('UPDATE player_subscriptions SET vehicle_claimed = 1, selected_vehicle = ? WHERE id = ?', {
            vehicleName,
            subscription.id
        })
        return true
    end
    return false
end)

lib.callback.register('ng-subscribe:server:searchPlayer', function(source, citizenId)
    if not exports['ng-subscribe']:IsPlayerAdmin(source) then return nil end
    
    local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(citizenId)
    if not targetPlayer then return nil end

    local subscription = GetPlayerSubscription(citizenId)
    return {
        name = targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname,
        subscription = subscription
    }
end)

lib.callback.register('ng-subscribe:server:revokeSubscription', function(source, citizenId)
    if not exports['ng-subscribe']:IsPlayerAdmin(source) then return false end
    
    local success = MySQL.update.await([[
        UPDATE player_subscriptions 
        SET activated = 0, 
            expires_at = NOW()
        WHERE citizen_id = ? 
        AND activated = 1
    ]], {
        citizenId
    })

    if success then
        local Player = QBCore.Functions.GetPlayerByCitizenId(citizenId)
        if Player then
            TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, 'サブスクリプションが失効しました', 'error')
        end

        -- 履歴に記録
        local admin = QBCore.Functions.GetPlayer(source)
        exports['ng-subscribe']:LogSubscriptionHistory(
            citizenId,
            'revoked',
            'subscription_revoked',
            nil,
            admin.PlayerData.citizenid
        )

        -- Webhook送信
        exports['ng-subscribe']:SendLog('subscriptions', {
            Player and (Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname) or citizenId,
            citizenId,
            'なし',
            '管理者による失効 (' .. admin.PlayerData.charinfo.firstname .. ' ' .. admin.PlayerData.charinfo.lastname .. ')'
        })
    end

    return success
end)

RegisterNetEvent('ng-subscribe:server:changePlan', function(citizenId, newPlan)
    local source = source
    
    -- デバッグログを追加
    --print(string.format('[ng-subscribe] Change plan request - Source: %s, CitizenID: %s, NewPlan: %s', 
    --    tostring(source), tostring(citizenId), tostring(newPlan)))
    
    -- パラメータの検証
    if not citizenId or citizenId == '' then
        TriggerClientEvent('QBCore:Notify', source, 'プレイヤーIDが無効です', 'error')
        return
    end
    
    if not newPlan or not Config.Plans[newPlan] then
        TriggerClientEvent('QBCore:Notify', source, '無効なプランが選択されました', 'error')
        return
    end
    
    -- 管理者権限の確認
    if not exports['ng-subscribe']:IsPlayerAdmin(source) then 
        TriggerClientEvent('QBCore:Notify', source, '管理者権限がありません', 'error')
        return 
    end
    
    -- 現在のサブスクリプションを確認
    local currentSub = exports['ng-subscribe']:GetPlayerSubscription(citizenId)
    
    -- 前のプランを保存（履歴用）
    local previousPlan = currentSub and currentSub.plan_name or nil
    
    -- 管理者情報取得
    local admin = QBCore.Functions.GetPlayer(source)
    if not admin then 
        TriggerClientEvent('QBCore:Notify', source, 'プレイヤー情報取得エラー', 'error')
        return 
    end
    
    -- 以前のサブスクリプションを無効化
    MySQL.update.await('UPDATE player_subscriptions SET activated = 0 WHERE citizen_id = ?', {
        citizenId
    })
    
    -- 新しいサブスクリプションを追加
    local success = MySQL.insert.await([[
        INSERT INTO player_subscriptions 
            (citizen_id, plan_name, activated, rewards_claimed, vehicle_claimed, expires_at) 
        VALUES 
            (?, ?, 1, 0, 0, DATE_ADD(NOW(), INTERVAL 1 MONTH))
    ]], {
        citizenId,
        newPlan
    })
    
    if success then
        -- プレイヤーに通知
        local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(citizenId)
        if targetPlayer then
            TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, 
                'サブスクリプションプランが変更されました: ' .. Config.Plans[newPlan].label, 'success')
        end
        
        -- 管理者に通知
        TriggerClientEvent('QBCore:Notify', source, 'プランを変更しました: ' .. Config.Plans[newPlan].label, 'success')
        
        -- 履歴に記録
        exports['ng-subscribe']:LogSubscriptionHistory(
            citizenId,
            newPlan,
            'plan_changed',
            previousPlan,
            admin.PlayerData.citizenid
        )
        
        -- Webhook送信
        exports['ng-subscribe']:SendLog('subscriptions', {
            targetPlayer and (targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname) or citizenId,
            citizenId,
            Config.Plans[newPlan].label,
            '管理者によるプラン変更 (' .. admin.PlayerData.charinfo.firstname .. ' ' .. admin.PlayerData.charinfo.lastname .. ')'
        })
    else
        TriggerClientEvent('QBCore:Notify', source, 'プラン変更に失敗しました', 'error')
    end
end)

lib.callback.register('ng-subscribe:server:isAdmin', function(source)
    return exports['ng-subscribe']:IsPlayerAdmin(source)
end)

lib.callback.register('ng-subscribe:server:updateSubscription', function(source)
    return exports['ng-subscribe']:ManuallyUpdateSubscription(source)
end)

-- サブスクリプション期限チェック用のスレッド
CreateThread(function()
    while true do
        Wait(60 * 60 * 1000) -- 1時間ごとにチェック
        MySQL.query([[
            UPDATE player_subscriptions 
            SET activated = 0 
            WHERE expires_at IS NOT NULL 
            AND expires_at < NOW()
        ]])
    end
end)