Config = {}

-- デバッグ設定
Config.Debug = {
    enabled = false, -- デバッグモード全体のON/OFF
    cooldown = false, -- クールダウン詳細情報を表示するかどうか
    spawning = false, -- NPC/プロップ生成情報を表示するかどうか
    robbery = false, -- 強盗進行状況を表示するかどうか
}

-- 受注システム設定
Config.JobStartLocation = {
    coords = vector3(-952.88, -2631.2, 24.22), -- 受注場所の座標（空港近く）
    heading = 150.38,
    model = 'g_m_m_chemwork_01', -- 受注NPC
    scenario = 'WORLD_HUMAN_CLIPBOARD'
}

-- 強盗場所設定
Config.RobberyLocation = {
    center = vector3(-1652.37, -3142.85, 13.99), -- 格納庫中心座標
    spawnRadius = 100.0, -- NPCスポーン・侵入検知範囲（広範囲）
    combatRadius = 50.0, -- 戦闘開始範囲（中範囲）
    robberyRadius = 20.0 -- 強盗実行可能範囲（狭範囲）
}

-- クールダウン設定
Config.Cooldown = {
    duration = 90 * 60 * 1000, -- 60分（ミリ秒）
    checkInterval = 5000 -- 5秒間隔でチェック
}

-- NPC警備員設定
Config.Guards = {
    {coords = vector3(-1655.0, -3140.0, 13.99), heading = 180.0, weapon = 'WEAPON_CARBINERIFLE'},
    {coords = vector3(-1650.0, -3145.0, 13.99), heading = 90.0, weapon = 'WEAPON_MG'},
    {coords = vector3(-1645.0, -3140.0, 13.99), heading = 270.0, weapon = 'WEAPON_CARBINERIFLE'},
    {coords = vector3(-1660.0, -3148.0, 13.99), heading = 45.0, weapon = 'WEAPON_MG'},
    {coords = vector3(-1665.0, -3142.0, 13.99), heading = 225.0, weapon = 'WEAPON_CARBINERIFLE'},
    {coords = vector3(-1648.0, -3135.0, 13.99), heading = 135.0, weapon = 'WEAPON_MG'},
    {coords = vector3(-1670.0, -3150.0, 13.99), heading = 315.0, weapon = 'WEAPON_CARBINERIFLE'},
    {coords = vector3(-1640.0, -3148.0, 13.99), heading = 180.0, weapon = 'WEAPON_MG'},
    {coords = vector3(-1658.0, -3130.0, 13.99), heading = 0.0, weapon = 'WEAPON_CARBINERIFLE'},
    {coords = vector3(-1675.0, -3145.0, 13.99), heading = 90.0, weapon = 'WEAPON_MG'},
    {coords = vector3(-1642.0, -3152.0, 13.99), heading = 270.0, weapon = 'WEAPON_CARBINERIFLE'},
    {coords = vector3(-1668.0, -3155.0, 13.99), heading = 225.0, weapon = 'WEAPON_MG'},
    {coords = vector3(-1635.0, -3140.0, 13.99), heading = 45.0, weapon = 'WEAPON_CARBINERIFLE'},
    {coords = vector3(-1672.0, -3138.0, 13.99), heading = 135.0, weapon = 'WEAPON_MG'},
    {coords = vector3(-1645.0, -3160.0, 13.99), heading = 315.0, weapon = 'WEAPON_CARBINERIFLE'},
    {coords = vector3(-1682.34, -3123.36, 24.31), heading = 135.0, weapon = 'WEAPON_CARBINERIFLE'},
    {coords = vector3(-1637.52, -3178.76, 24.31), heading = 135.0, weapon = 'WEAPON_CARBINERIFLE'},
}

-- NPC設定
Config.GuardSettings = {
    model = 'mp_s_m_armoured_01', -- 警備員NPC
    health = 350,
    armor = 200,
    accuracy = 90,
    relationship = 5 -- HATE
}

-- トロリー設定（新形式）
Config.Trollys = {
    {
        model = "prop_cash_crate_01",
        coords = vector4(-1649.24, -3153.96, 12.99, 148.31),
        typ = "cash_crate",
        requiredItem = "bag",
        items = {
            {name = "stacksofcash", count = 25000000, sellPrice = 0},
        },
        label = "現金クレート"
    },
    {
        model = "prop_cash_crate_01",
        coords = vector4(-1651.56, -3152.67, 12.99, 245.17),
        typ = "cash_crate",
        requiredItem = "bag",
        items = {
            {name = "stacksofcash", count = 25000000, sellPrice = 0},
        },
        label = "現金クレート"
    },
    {
        model = "prop_cash_crate_01",
        coords = vector4(-1654.28, -3150.94, 12.99, 86.43),
        typ = "cash_crate",
        requiredItem = "bag",
        items = {
            {name = "stacksofcash", count = 25000000, sellPrice = 0},
        },
        label = "現金クレート"
    },
    {
        model = "prop_cash_crate_01",
        coords = vector4(-1657.55, -3148.94, 12.99, 258.77),
        typ = "cash_crate",
        requiredItem = "bag",
        items = {
            {name = "stacksofcash", count = 25000000, sellPrice = 0},
        },
        label = "現金クレート"
    },
    {
        model = "prop_cash_crate_01",
        coords = vector4(-1647.28, -3150.54, 12.99, 258.77),
        typ = "cash_crate",
        requiredItem = "bag",
        items = {
            {name = "stacksofcash", count = 25000000, sellPrice = 0},
        },
        label = "現金クレート"
    },
    {
        model = "prop_cash_crate_01",
        coords = vector4(-1649.56, -3149.19, 12.99, 355.66),
        typ = "cash_crate",
        requiredItem = "bag",
        items = {
            {name = "stacksofcash", count = 25000000, sellPrice = 0},
        },
        label = "現金クレート"
    },
    {
        model = "prop_cash_crate_01",
        coords = vector4(-1652.45, -3147.82, 12.99, 273.8),
        typ = "cash_crate",
        requiredItem = "bag",
        items = {
            {name = "stacksofcash", count = 25000000, sellPrice = 0},
        },
        label = "現金クレート"
    },
    {
        model = "prop_cash_crate_01",
        coords = vector4(-1656.1, -3146.11, 12.99, 89.45),
        typ = "cash_crate",
        requiredItem = "bag",
        items = {
            {name = "stacksofcash", count = 25000000, sellPrice = 0},
        },
        label = "現金クレート"
    }
}

-- 現金回収アニメーション設定
Config.CashCrateAnimation = {
    dict = 'anim@heists@narcotics@funding@gang_idle',
    anim = 'gang_chatting_idle01',
    duration = 12000, -- 12秒
    text = '現金クレートを回収しています...'
}

-- 電子セーフ（オーバーヒート）アニメーション設定
Config.OverheatAnimation = {
    dict = 'anim@gangops@facility@servers@bodysearch@',
    anim = 'player_search',
    duration = 12000, -- 12秒
    text = '電子セーフをハッキングしています...'
}

-- ps-dispatch設定
Config.Dispatch = {
    code = '10-90', -- 強盗コード
    message = '重武装格納庫強盗',
    priority = 1, -- 最高優先度
    radius = 100.0
}

-- 受注条件設定
Config.Requirements = {
    minCops = 10, -- 最低警察官数
    jobRestriction = false, -- 職業制限なし
    requiredItem = nil -- 必要アイテムなし
}

-- 通知設定
Config.Notifications = {
    jobStart = '格納庫強盗を開始しました。現場へ移動してください。',
    jobOnCooldown = 'まだ実行できません。クールダウン中です。',
    robberyComplete = '強盗が完了しました！',
    policeAlert = '格納庫で重武装強盗が発生中！',
    notEnoughCops = '警察官が足りません。（最低 %d 人必要）',
    abandonWarning = '現場から離れすぎています！30秒以内に戻らないと強盗は中止されます！',
    robberyAbandoned = '現場から離れすぎたため強盗が中止されました。クールダウンが開始されます。'
}