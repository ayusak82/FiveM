--[[
    ng-gacha - Advanced Gacha System
    Author: NCCGr
    Contact: Discord: ayusak
]]

Config = {}

-- Debug Mode
Config.Debug = false

-- Rarity Settings
Config.Rarities = {
    ['common'] = {
        label = 'Common',
        color = '#8a8a8a',
        sound = 'common'
    },
    ['uncommon'] = {
        label = 'Uncommon',
        color = '#4ade80',
        sound = 'uncommon'
    },
    ['rare'] = {
        label = 'Rare',
        color = '#3b82f6',
        sound = 'rare'
    },
    ['epic'] = {
        label = 'Epic',
        color = '#a855f7',
        sound = 'epic'
    },
    ['legendary'] = {
        label = 'Legendary',
        color = '#f59e0b',
        sound = 'legendary'
    }
}

-- Color Themes for Gacha Creation
Config.ColorThemes = {
    'cyan',
    'pink',
    'gold',
    'green',
    'purple',
    'red'
}

-- Payment Types
Config.PaymentTypes = {
    ['money'] = {
        label = '現金',
        account = 'cash'
    },
    ['bank'] = {
        label = '銀行',
        account = 'bank'
    },
    ['coin'] = {
        label = 'ガチャコイン',
        item = 'gacha_coin'
    }
}

-- Gacha Ticket Item Name (used to create new gacha)
Config.GachaTicketItem = 'gacha_ticket'

-- Gacha Coin Item Name (used as currency)
Config.GachaCoinItem = 'gacha_coin'

-- Default Settings for New Gacha
Config.DefaultGachaSettings = {
    price = 500,
    priceType = 'money',
    pityCount = 100,        -- 0 = disabled
    colorTheme = 'cyan',
    maxPrizesPerGacha = 20  -- Maximum items per gacha
}

-- Multi Pull Settings
Config.MultiPull = {
    enabled = true,
    count = 10,
    discount = 0            -- Discount percentage for multi pull (0-100)
}

-- Animation Durations (ms)
Config.Animations = {
    singlePull = 1500,
    multiPull = 2000,
    resultDisplay = 500
}

-- Limits
Config.Limits = {
    maxGachaPerPlayer = 5,      -- Maximum gacha machines a player can create
    minPrice = 100,              -- Minimum price per pull
    maxPrice = 100000,           -- Maximum price per pull
    minProbability = 0.01,       -- Minimum probability (%)
    maxProbability = 100         -- Maximum probability (%)
}

-- Notifications
Config.Notifications = {
    useOkokNotify = true         -- Use okokNotify for notifications
}

-- Discord Webhook (optional)
Config.Discord = {
    enabled = false,
    webhook = '',
    botName = 'ng-gacha',
    logCreation = true,          -- Log gacha creation
    logJackpot = true            -- Log jackpot wins
}
