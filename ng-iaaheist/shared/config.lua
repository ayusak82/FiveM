Config = {}

-- 基本設定
Config.Debug = true
Config.Framework = 'qb-core'

-- 強盗設定
Config.HeistCooldown = 60 -- 分（次の強盗まで）
Config.MinPlayers = 1 -- 最低必要プレイヤー数
Config.MaxPlayers = 4 -- 最大参加プレイヤー数

-- 強盗受注場所
Config.HeistStart = {
    coords = vector3(2057.2, 2957.12, 47.5), -- Elysian Island
    heading = 161.91,
    ped = 's_m_m_highsec_01',
    label = 'IAA強盗受注'
}

-- IAA基地入口
Config.IAA_Entrance = {
    coords = vector3(2049.07, 2949.93, 47.93), -- 基地入口
    heading = 0.0,
    label = 'IAA基地に侵入'
}

-- IAA基地内部（テレポート先）
Config.IAA_Interior = {
    coords = vector3(2155.02, 2921.02, -61.9), -- 基地内部
    heading = 0.0
}

-- データ回収ポイント
Config.DataPoints = {
    {
        coords = vector3(2017.09, 3021.3, -72.71),
        heading = 0.0,
        label = 'データ回収ポイント 1',
        hacked = false
    },
    {
        coords = vector3(2041.23, 3013.1, -72.7),
        heading = 0.0,
        label = 'データ回収ポイント 2',
        hacked = false
    },
    {
        coords = vector3(2064.34, 2990.74, -67.7),
        heading = 0.0,
        label = 'データ回収ポイント 3',
        hacked = false
    },
    {
        coords = vector3(2070.06, 2994.78, -63.5),
        heading = 0.0,
        label = 'データ回収ポイント 4',
        hacked = false
    }
}

-- 脱出ポイント
Config.ExitPoint = {
    coords = vector3(2155.02, 2921.02, -61.9),
    heading = 0.0,
    label = 'IAA基地から脱出'
}

-- NPC敵設定
Config.NPCs = {
    {
        coords = vector3(2101.22, 2932.95, -61.9),
        heading = 180.0,
        model = 's_m_m_fibsec_01',
        weapon = 'WEAPON_CARBINERIFLE',
        health = 200,
        armor = 100
    },
    {
        coords = vector3(2080.44, 2933.43, -61.9),
        heading = 180.0,
        model = 's_m_m_fibsec_01',
        weapon = 'WEAPON_CARBINERIFLE',
        health = 200,
        armor = 100
    },
    {
        coords = vector3(2065.61, 2930.2, -61.9),
        heading = 270.0,
        model = 's_m_m_fibsec_01',
        weapon = 'WEAPON_CARBINERIFLE',
        health = 200,
        armor = 100
    },
    {
        coords = vector3(2054.09, 2939.05, -61.9),
        heading = 90.0,
        model = 's_m_m_fibsec_01',
        weapon = 'WEAPON_CARBINERIFLE',
        health = 200,
        armor = 100
    },
    {
        coords = vector3(2039.39, 2947.21, -61.9),
        heading = 45.0,
        model = 's_m_m_fibsec_01',
        weapon = 'WEAPON_CARBINERIFLE',
        health = 200,
        armor = 100
    },
    {
        coords = vector3(2033.04, 2969.05, -61.9),
        heading = 225.0,
        model = 's_m_m_fibsec_01',
        weapon = 'WEAPON_CARBINERIFLE',
        health = 200,
        armor = 100
    },
    {
        coords = vector3(2052.35, 2954.64, -61.9),
        heading = 0.0,
        model = 's_m_m_fibsec_01',
        weapon = 'WEAPON_CARBINERIFLE',
        health = 200,
        armor = 100
    },
    {
        coords = vector3(2052.34, 2973.31, -61.9),
        heading = 0.0,
        model = 's_m_m_fibsec_01',
        weapon = 'WEAPON_CARBINERIFLE',
        health = 200,
        armor = 100
    },
    {
        coords = vector3(2054.42, 2971.83, -61.9),
        heading = 0.0,
        model = 's_m_m_fibsec_01',
        weapon = 'WEAPON_CARBINERIFLE',
        health = 200,
        armor = 100
    },
    {
        coords = vector3(2066.27, 2995.65, -63.5),
        heading = 0.0,
        model = 's_m_m_fibsec_01',
        weapon = 'WEAPON_CARBINERIFLE',
        health = 200,
        armor = 100
    },
    {
        coords = vector3(2039.28, 2975.34, -67.3),
        heading = 0.0,
        model = 's_m_m_fibsec_01',
        weapon = 'WEAPON_CARBINERIFLE',
        health = 200,
        armor = 100
    },
    {
        coords = vector3(2056.39, 2964.65, -67.3),
        heading = 0.0,
        model = 's_m_m_fibsec_01',
        weapon = 'WEAPON_CARBINERIFLE',
        health = 200,
        armor = 100
    },
    {
        coords = vector3(2049.64, 2979.41, -67.3),
        heading = 0.0,
        model = 's_m_m_fibsec_01',
        weapon = 'WEAPON_CARBINERIFLE',
        health = 200,
        armor = 100
    },
    {
        coords = vector3(2051.85, 2984.34, -67.3),
        heading = 0.0,
        model = 's_m_m_fibsec_01',
        weapon = 'WEAPON_CARBINERIFLE',
        health = 200,
        armor = 100
    },
    {
        coords = vector3(2063.48, 2995.94, -67.7),
        heading = 0.0,
        model = 's_m_m_fibsec_01',
        weapon = 'WEAPON_CARBINERIFLE',
        health = 200,
        armor = 100
    },
    {
        coords = vector3(2072.42, 2990.32, -67.7),
        heading = 0.0,
        model = 's_m_m_fibsec_01',
        weapon = 'WEAPON_CARBINERIFLE',
        health = 200,
        armor = 100
    },
    {
        coords = vector3(2070.56, 2974.1, -72.7),
        heading = 0.0,
        model = 's_m_m_fibsec_01',
        weapon = 'WEAPON_CARBINERIFLE',
        health = 200,
        armor = 100
    },
    {
        coords = vector3(2057.27, 2986.85, -72.7),
        heading = 0.0,
        model = 's_m_m_fibsec_01',
        weapon = 'WEAPON_CARBINERIFLE',
        health = 200,
        armor = 100
    },
    {
        coords = vector3(2058.65, 2996.02, -72.7),
        heading = 0.0,
        model = 's_m_m_fibsec_01',
        weapon = 'WEAPON_CARBINERIFLE',
        health = 200,
        armor = 100
    },
    {
        coords = vector3(2035.5, 2993.89, -72.7),
        heading = 0.0,
        model = 's_m_m_fibsec_01',
        weapon = 'WEAPON_CARBINERIFLE',
        health = 200,
        armor = 100
    },
    {
        coords = vector3(2029.37, 3004.97, -72.7),
        heading = 0.0,
        model = 's_m_m_fibsec_01',
        weapon = 'WEAPON_CARBINERIFLE',
        health = 200,
        armor = 100
    },
    {
        coords = vector3(2037.05, 3009.51, -72.7),
        heading = 0.0,
        model = 's_m_m_fibsec_01',
        weapon = 'WEAPON_CARBINERIFLE',
        health = 200,
        armor = 100
    },
    {
        coords = vector3(2042.55, 3000.73, -72.7),
        heading = 0.0,
        model = 's_m_m_fibsec_01',
        weapon = 'WEAPON_CARBINERIFLE',
        health = 200,
        armor = 100
    },
    {
        coords = vector3(2023.83, 3022.35, -72.69),
        heading = 0.0,
        model = 's_m_m_fibsec_01',
        weapon = 'WEAPON_CARBINERIFLE',
        health = 200,
        armor = 100
    },
}

-- ハッキング設定
Config.Hacking = {
    difficulty = 'medium', -- easy, medium, hard
    time = 30, -- 秒
    blocks = 6, -- ハッキングブロック数
    repeats = 3 -- 繰り返し回数
}

-- アイテム設定
Config.Items = {
    requiredItem = 'laptop_green', -- 必要アイテム（ハッキング用）
    dataItem = 'harddrive', -- データアイテム
    minData = 2, -- 最低必要データ数
    maxData = 4 -- 最大データ数
}

-- 警報設定
Config.Alarm = {
    soundFile = 'alarm.mp3',
    volume = 0.1,
    range = 100.0 -- 警報音が聞こえる範囲
}