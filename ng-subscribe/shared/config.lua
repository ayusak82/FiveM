Config = {}

-- インベントリシステムの選択
Config.InventoryType = 'ox'

Config.Inventory = {
    ['ox'] = {
        addItem = function(source, item, count)
            return exports.ox_inventory:AddItem(source, item, count)
        end,
        removeItem = function(source, item, count)
            return exports.ox_inventory:RemoveItem(source, item, count)
        end,
        hasItem = function(source, item, count)
            return exports.ox_inventory:GetItem(source, item, nil, true) >= (count or 1)
        end,
        canCarry = function(source, item, count)
            return exports.ox_inventory:CanCarryItem(source, item, count)
        end
    },
}

Config.Discord = {
    Webhooks = {
        rewards = 'YOUR_REWARDS_WEBHOOK_URL_HERE',
        vehicles = 'YOUR_VEHICLES_WEBHOOK_URL_HERE',
        subscriptions = 'YOUR_SUBSCRIPTIONS_WEBHOOK_URL_HERE'
    },
    Roles = {
        ['YOUR_PLAN1_ROLE_ID'] = 'plan1',
        ['YOUR_PLAN2_ROLE_ID'] = 'plan2',
        ['YOUR_PLAN3_ROLE_ID'] = 'plan3',
    },
    AdminRoles = {
        'YOUR_ADMIN_ROLE_ID'
    },
    BotToken = 'YOUR_DISCORD_BOT_TOKEN_HERE',
    GuildId = 'YOUR_GUILD_ID_HERE',
    CheckInterval = 30,
    LinkTimeout = 300,
    ManualUpdateCooldown = 5
}

Config.Vehicles = {
    BlacklistedVehicles = {
        'oppressor',
        'oppressor2',
        'lazer',
        'hydra'
    },
    PlanBlacklist = {
        ['bronze'] = {
            'adder',
            't20'
        },
        ['silver'] = {
            't20'
        }
    }
}

Config.VehicleCategories = {
    'sports',
    'super',
    'muscle',
    'sedans',
    'suvs',
    'coupes',
    'compacts'
}

Config.Plans = {
    ['bronze'] = {
        label = 'ブロンズプラン',
        level = 1,
        rewards = {
            cash = 1000000,
            items = {
                ['phone'] = 1,
                ['radio'] = 1,
                ['lockpick'] = 5
            },
            vehicle_categories = {'sports', 'muscle', 'sedans'}
        }
    },
    ['silver'] = {
        label = 'シルバープラン',
        level = 2,
        rewards = {
            cash = 2000000,
            items = {
                ['phone'] = 1,
                ['radio'] = 1,
                ['lockpick'] = 10,
                ['armor'] = 5
            },
            vehicle_categories = {'sports', 'muscle', 'sedans', 'suvs', 'coupes'}
        }
    },
    ['gold'] = {
        label = 'ゴールドプラン',
        level = 3,
        rewards = {
            cash = 3000000,
            items = {
                ['phone'] = 1,
                ['radio'] = 1,
                ['lockpick'] = 15,
                ['armor'] = 10,
                ['repairkit'] = 5
            },
            vehicle_categories = Config.VehicleCategories
        }
    }
}

Config.UI = {
    AdminCommand = 'subsadmin',
    PlayerCommand = 'subs'
}

Config.WebhookMessages = {
    rewards = {
        title = '🎁 サブスクリプション報酬受け取りログ',
        color = 5763719,
        format = [=[
            プレイヤー: %s
            CitizenID: %s
            プラン: %s
            受け取り内容:
            - 現金: $%s
            - アイテム: %s
        ]=]
    },
    vehicles = {
        title = '🚗 サブスクリプション車両受け取りログ',
        color = 5763719,
        format = [=[
            プレイヤー: %s
            CitizenID: %s
            プラン: %s
            受け取った車両: %s
            カテゴリー: %s
        ]=]
    },
    subscriptions = {
        title = '✨ サブスクリプション付与ログ',
        color = 5763719,
        format = [=[
            プレイヤー: %s
            CitizenID: %s
            付与されたプラン: %s
            付与方法: %s
        ]=]
    }
}

Config.Messages = {
    error = {
        no_subscription = '有効なサブスクリプションがありません',
        already_claimed = 'すでに受け取り済みです',
        vehicle_blacklisted = 'この車両は現在のプランでは選択できません',
        insufficient_permission = '権限がありません',
        update_failed = '更新に失敗しました'
    },
    success = {
        rewards_claimed = '報酬を受け取りました',
        vehicle_claimed = '車両を受け取りました',
        subscription_added = 'サブスクリプションを付与しました',
        subscription_updated = 'サブスクリプション情報を更新しました'
    }
}