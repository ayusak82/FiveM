Config = Config or {}

-- デバッグモード
Config.Debug = false

-- クールダウン設定
Config.Cooldown = {
    Enabled = true,  -- クールダウン機能の有効/無効
    Time = 3600,     -- クールダウン時間（秒）1時間
    ShowRemaining = true  -- 残り時間の表示有無
}

-- Discord Webhook設定
Config.LogsImage = false -- ロゴ画像URL（falseで無効）
Config.WebHook = false -- Webhook URL（falseで無効）

-- 警察設定
Config.RequiredPolice = 0 -- ミッション開始に必要な警察の人数
Config.PoliceJob = 'police' -- 警察のジョブ名

-- チーム設定
Config.MinTeamMembers = 2 -- ミッション開始に必要な最小人数
Config.MaxTeamMembers = 4 -- チームの最大人数
Config.TeamWaitTime = 60 -- チームメンバー参加待機時間（秒）

-- UI設定
Config.UseBlips = true -- マップにブリップを表示するか

-- 電話システム
Config.Phone = 'qb-phone' -- 使用する電話システム

-- 報酬設定
Config.RewardAmount = 40000000 -- ミッション報酬（現金）
Config.RewardItem = 'stacksofcash' -- 報酬アイテム名

-- 次回実行可能時間
Config.NextRob = 3600 -- 次回ミッション開始可能時間（秒）

-- ターゲットシステム
Config.TargetSystem = 'qb-target' -- 'qb-target' または 'ox_target'

-- ミッション開始NPC設定
Config.StartPeds = {
    [1] = {
        Scenario = "WORLD_HUMAN_CLIPBOARD", -- NPCのシナリオ
        Icon = "fas fa-users", -- アイコン
        Label = "テルミットミッション", -- ラベル
        JoinLabel = "チームに参加", -- チーム参加ラベル
        LeaveLabel = "チームから離脱", -- チーム離脱ラベル
        StartLabel = "ミッション開始", -- ミッション開始ラベル
        Ped = "csb_paige", -- NPCモデル
        Coords = {
            PedCoords = vector3(-604.0787, -773.9486, 24.403778), -- NPC座標
            Heading = 189.80155, -- 向き
            Distance = 2.0, -- インタラクション距離
        },
    },
}

-- マップブリップ設定
Config.BlipLocation = {
    {
        title = "テルミットミッション",
        colour = 0,
        id = 47,
        x = -604.0787,
        y = -773.9486,
        z = 25.403778
    },
}

-- 警備員設定
Config.Guards = {
    [1] = {
        Coords = vector4(-2147.055, 3247.2202, 32.810306, 130.6092),
        Ped = 's_m_y_blackops_01',
        Weapon = 'WEAPON_COMBATMG',
        Health = 5000,
        Accuracy = 80,
        Alertness = 3,
        Aggresiveness = 3,
    },
    [2] = {
        Coords = vector4(-2121.281, 3265.7536, 32.80957, 159.09059),
        Ped = 's_m_y_blackops_01',
        Weapon = 'WEAPON_COMBATMG',
        Health = 5000,
        Accuracy = 80,
        Alertness = 3,
        Aggresiveness = 3,
    },
    [3] = {
        Coords = vector4(-2099.775, 3267.1691, 32.812232, 133.71133),
        Ped = 's_m_y_blackops_01',
        Weapon = 'WEAPON_COMBATMG',
        Health = 5000,
        Accuracy = 80,
        Alertness = 3,
        Aggresiveness = 3,
    },
    [4] = {
        Coords = vector4(-2092.431, 3278.4438, 32.804031, 133.92941),
        Ped = 's_m_y_blackops_01',
        Weapon = 'WEAPON_COMBATMG',
        Health = 5000,
        Accuracy = 80,
        Alertness = 3,
        Aggresiveness = 3,
    },
    [5] = {
        Coords = vector4(-2109.844, 3277.0988, 38.732337, 149.50251),
        Ped = 's_m_y_blackops_01',
        Weapon = 'WEAPON_COMBATMG',
        Health = 5000,
        Accuracy = 80,
        Alertness = 3,
        Aggresiveness = 3,
    },
    [6] = {
        Coords = vector4(-2133.197, 3290.2985, 38.726982, 139.82868),
        Ped = 's_m_y_blackops_01',
        Weapon = 'WEAPON_COMBATMG',
        Health = 5000,
        Accuracy = 80,
        Alertness = 3,
        Aggresiveness = 3,
    },
    [7] = {
        Coords = vector4(-2140.512, 3244.9045, 32.81031, 120.5),
        Ped = 's_m_y_blackops_01',
        Weapon = 'WEAPON_COMBATMG',
        Health = 5000,
        Accuracy = 80,
        Alertness = 3,
        Aggresiveness = 3,
    },
    [8] = {
        Coords = vector4(-2105.233, 3283.4421, 32.809703, 145.2),
        Ped = 's_m_y_blackops_01',
        Weapon = 'WEAPON_COMBATMG',
        Health = 5000,
        Accuracy = 80,
        Alertness = 3,
        Aggresiveness = 3,
    },
    [9] = {
        Coords = vector4(-2125.663, 3270.8542, 38.726982, 155.8),
        Ped = 's_m_y_blackops_01',
        Weapon = 'WEAPON_COMBATMG',
        Health = 5000,
        Accuracy = 80,
        Alertness = 3,
        Aggresiveness = 3,
    },
    [10] = {
        Coords = vector4(-2115.445, 3256.3254, 32.810306, 110.3),
        Ped = 's_m_y_blackops_01',
        Weapon = 'WEAPON_COMBATMG',
        Health = 5000,
        Accuracy = 80,
        Alertness = 3,
        Aggresiveness = 3,
    },
    [11] = {
        Coords = vector4(-2169.31, 3253.6, 32.81, 180.27),
        Ped = 's_m_y_blackops_01',
        Weapon = 'WEAPON_COMBATMG',
        Health = 5000,
        Accuracy = 80,
        Alertness = 3,
        Aggresiveness = 3,
    },
    [12] = {
        Coords = vector4(-2164.81, 3251.21, 32.81, 244.39),
        Ped = 's_m_y_blackops_01',
        Weapon = 'WEAPON_COMBATMG',
        Health = 5000,
        Accuracy = 80,
        Alertness = 3,
        Aggresiveness = 3,
    },
    [13] = {
        Coords = vector4(-2161.79, 3256.82, 32.81, 342.68),
        Ped = 's_m_y_blackops_01',
        Weapon = 'WEAPON_COMBATMG',
        Health = 5000,
        Accuracy = 80,
        Alertness = 3,
        Aggresiveness = 3,
    },
    [14] = {
        Coords = vector4(-2126.88, 3229.16, 32.81, 194.42),
        Ped = 's_m_y_blackops_01',
        Weapon = 'WEAPON_COMBATMG',
        Health = 5000,
        Accuracy = 80,
        Alertness = 3,
        Aggresiveness = 3,
    },
    [15] = {
        Coords = vector4(-2131.41, 3230.8, 32.81, 66.5),
        Ped = 's_m_y_blackops_01',
        Weapon = 'WEAPON_COMBATMG',
        Health = 5000,
        Accuracy = 80,
        Alertness = 3,
        Aggresiveness = 3,
    },
    [16] = {
        Coords = vector4(-2126.45, 3234.3, 32.81, 309.02),
        Ped = 's_m_y_blackops_01',
        Weapon = 'WEAPON_COMBATMG',
        Health = 5000,
        Accuracy = 80,
        Alertness = 3,
        Aggresiveness = 3,
    },
    [17] = {
        Coords = vector4(-2122.28, 3242.14, 32.81, 323.26),
        Ped = 's_m_y_blackops_01',
        Weapon = 'WEAPON_COMBATMG',
        Health = 5000,
        Accuracy = 80,
        Alertness = 3,
        Aggresiveness = 3,
    },
    [18] = {
        Coords = vector4(-2131.26, 3248.93, 32.81, 63.39),
        Ped = 's_m_y_blackops_01',
        Weapon = 'WEAPON_COMBATMG',
        Health = 5000,
        Accuracy = 80,
        Alertness = 3,
        Aggresiveness = 3,
    },
    [19] = {
        Coords = vector4(-2140.16, 3253.47, 32.81, 62.38),
        Ped = 's_m_y_blackops_01',
        Weapon = 'WEAPON_COMBATMG',
        Health = 5000,
        Accuracy = 80,
        Alertness = 3,
        Aggresiveness = 3,
    },
    [20] = {
        Coords = vector4(-2149.47, 3258.34, 32.81, 62.36),
        Ped = 's_m_y_blackops_01',
        Weapon = 'WEAPON_COMBATMG',
        Health = 5000,
        Accuracy = 80,
        Alertness = 3,
        Aggresiveness = 3,
    },
    [21] = {
        Coords = vector4(-2146.79, 3267.06, 32.81, 335.9),
        Ped = 's_m_y_blackops_01',
        Weapon = 'WEAPON_COMBATMG',
        Health = 5000,
        Accuracy = 80,
        Alertness = 3,
        Aggresiveness = 3,
    },
    [22] = {
        Coords = vector4(-2138.75, 3263.75, 32.81, 244.34),
        Ped = 's_m_y_blackops_01',
        Weapon = 'WEAPON_COMBATMG',
        Health = 5000,
        Accuracy = 80,
        Alertness = 3,
        Aggresiveness = 3,
    },
    [23] = {
        Coords = vector4(-2129.86, 3259.36, 32.81, 243.01),
        Ped = 's_m_y_blackops_01',
        Weapon = 'WEAPON_COMBATMG',
        Health = 5000,
        Accuracy = 80,
        Alertness = 3,
        Aggresiveness = 3,
    },
    [24] = {
        Coords = vector4(-2118.77, 3253.16, 32.81, 239.4),
        Ped = 's_m_y_blackops_01',
        Weapon = 'WEAPON_COMBATMG',
        Health = 5000,
        Accuracy = 80,
        Alertness = 3,
        Aggresiveness = 3,
    },
    [25] = {
        Coords = vector4(-2122.45, 3267.8, 32.81, 24.82),
        Ped = 's_m_y_blackops_01',
        Weapon = 'WEAPON_COMBATMG',
        Health = 5000,
        Accuracy = 80,
        Alertness = 3,
        Aggresiveness = 3,
    },
}
