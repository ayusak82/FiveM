Config = {}

-- NPC Settings
Config.NPC = {
    model = 'a_m_m_business_01',
    coords = vector4(-1026.03, -3018.69, 13.95, 330.83), -- LS国際空港
    scenario = 'WORLD_HUMAN_CLIPBOARD'
}

-- Blip Settings
Config.Blip = {
    enabled = true,
    sprite = 43,
    color = 3,
    scale = 0.8,
    label = 'VIP輸送サービス'
}

-- Vehicle Settings
Config.Vehicles = {
    {
        spawn = 'volatus',
        label = 'Volatus (ヘリコプター)',
        price = 0 -- 無料でスポーン
    },
    {
        spawn = 'swift',
        label = 'Swift (ヘリコプター)',
        price = 0
    },
    {
        spawn = 'luxor',
        label = 'Luxor (プライベートジェット)',
        price = 0
    },
    {
        spawn = 'shamal',
        label = 'Shamal (ビジネスジェット)',
        price = 0
    }
}

-- Mission Locations
Config.Locations = {
    -- 出発地点（LS国際空港）
    start = {
        coords = vector3(-935.75, -3180.03, 13.94),
        heading = 330.0,
        spawnPoint = vector4(-935.75, -3180.03, 13.94, 57.44), -- 車両スポーン位置
        label = 'LS国際空港'
    },
    
    -- 目的地（サンディ飛行場）
    destination = {
        coords = vector3(1706.68, 3251.24, 41.01),
        heading = 105.0,
        landingZone = vector3(1706.68, 3251.24, 41.01), -- 着陸ポイント
        label = 'サンディ飛行場'
    }
}

-- VIP NPC Settings
Config.VIP = {
    model = 'a_m_m_prolhost_01', -- VIP要人のモデル
    pickupMessage = '要人が搭乗しました'
}

-- Reward Settings
Config.Rewards = {
    base = 300000, -- 基本報酬
    bonus = {
        {time = 600, amount = 300000}, -- 10分以内 +$300,000
        {time = 900, amount = 150000}  -- 15分以内 +$150,000
    }
}

-- Time Settings
Config.TimeLimit = 900 -- 制限時間（秒） 15分 = 900秒

-- Marker Settings
Config.Markers = {
    destination = {
        type = 1,
        scale = vector3(10.0, 10.0, 5.0),
        color = {r = 0, g = 255, b = 0, a = 100}
    },
    returnPoint = {
        type = 1,
        scale = vector3(10.0, 10.0, 5.0),
        color = {r = 255, g = 165, b = 0, a = 100}
    }
}

-- UI Settings
Config.UI = {
    position = 'right-center', -- ox_lib TextUI position
    icon = 'helicopter'
}

-- Notification Settings
Config.Notifications = {
    missionStart = {
        title = 'VIP輸送ミッション',
        description = '要人をサンディ飛行場まで迎えに行ってください',
        type = 'info'
    },
    vipPickedUp = {
        title = 'VIP搭乗完了',
        description = '要人をLS国際空港まで送り届けてください',
        type = 'success'
    },
    missionComplete = {
        title = 'ミッション完了',
        type = 'success'
    },
    missionFailed = {
        title = 'ミッション失敗',
        type = 'error'
    },
    vehicleDestroyed = {
        title = 'ミッション失敗',
        description = '車両が破壊されました',
        type = 'error'
    },
    timeUp = {
        title = 'ミッション失敗',
        description = '制限時間を超過しました',
        type = 'error'
    }
}