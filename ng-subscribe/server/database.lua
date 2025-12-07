-- server/database.lua

local QBCore = exports['qb-core']:GetCoreObject()

local function InitializeDatabase()
    -- player_subscriptions テーブルの作成
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `player_subscriptions` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `citizen_id` varchar(50) NOT NULL,
            `plan_name` varchar(50) NOT NULL,
            `activated` tinyint(1) DEFAULT 0,
            `rewards_claimed` tinyint(1) DEFAULT 0,
            `vehicle_claimed` tinyint(1) DEFAULT 0,
            `selected_vehicle` varchar(50) DEFAULT NULL,
            `expires_at` timestamp NULL DEFAULT NULL,
            `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
            `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
            PRIMARY KEY (`id`),
            KEY `citizen_id` (`citizen_id`)
        )
    ]])

    -- subscription_history テーブルの作成
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `subscription_history` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `citizen_id` varchar(50) NOT NULL,
            `plan_name` varchar(50) NOT NULL,
            `action` varchar(20) NOT NULL,
            `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
            `previous_plan` varchar(50) DEFAULT NULL,
            `changed_by` varchar(50) DEFAULT NULL,
            PRIMARY KEY (`id`),
            KEY `citizen_id` (`citizen_id`)
        )
    ]])
end

local function GetPlayerSubscription(citizenId)
    if not citizenId then return nil end

    local result = MySQL.query.await([[
        SELECT * FROM player_subscriptions 
        WHERE citizen_id = ? 
        AND activated = 1 
        AND (expires_at IS NULL OR expires_at > NOW())
        ORDER BY created_at DESC LIMIT 1
    ]], {
        citizenId
    })
    
    return result and result[1] or nil
end

local function LogSubscriptionHistory(citizenId, planName, action, previousPlan, changedBy)
    MySQL.insert.await([[
        INSERT INTO subscription_history 
            (citizen_id, plan_name, action, previous_plan, changed_by)
        VALUES
            (?, ?, ?, ?, ?)
    ]], {
        citizenId,
        planName,
        action,
        previousPlan,
        changedBy
    })
end

exports('GetPlayerSubscription', GetPlayerSubscription)
exports('LogSubscriptionHistory', LogSubscriptionHistory)

CreateThread(function()
    Wait(1000) -- サーバーの起動を待機
    InitializeDatabase()
end)