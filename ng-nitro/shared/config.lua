Config = {}

-- ニトロシステム設定
Config.Nitro = {
    -- ブースト設定
    boostForce = 70.0,              -- ブースト力（値が大きいほど強力）
    boostDuration = 3000,           -- ブースト持続時間（ミリ秒）
    boostCooldown = 5000,           -- ブースト後のクールダウン時間（ミリ秒）
    
    -- キー設定
    activateKey = 'lshift',         -- ニトロ発動キー（左シフト）
    
    -- タンク設定
    maxTanks = 10,                   -- 最大タンク数
    tankUsagePerBoost = 1,          -- 1回のブーストで消費するタンク数
    tanksPerBottle = 1,             -- 1つのニトロボトルあたりのタンク数
}

-- アイテム設定
Config.Items = {
    installKit = 'nitrous_installkit',      -- ニトロインストールキット
    nitrousBottle = 'nitrous3',             -- ニトロボトル
}

-- 権限設定（Job制限）
Config.Permissions = {
    allowedJobs = {                 -- ニトロキット取り付けが可能な職業
        'sample_mechanic_1',
        'sample_mechanic_2',
        'sample_mechanic_3',
        'sample_mechanic_4',
        'sample_mechanic_5',
        'sample_mechanic_6',
        'sample_mechanic_7',
        'sample_mechanic_8',
        'sample_mechanic_9',
        'sample_mechanic_10',
        'sample_mechanic_11',
        'sample_mechanic_12',
        'sample_mechanic_13',
        'sample_mechanic_14',
        'sample_mechanic_15',
        'admin',                -- 運営
    }
}

-- UI設定
Config.UI = {
    showNotifications = true,       -- 通知を表示するか
    notificationCooldown = 2000,    -- 通知のクールダウン時間（ミリ秒）
    showHUD = true,                -- HUD表示するか
    hudPosition = {                -- HUD位置
        x = 0.02,
        y = 0.85
    }
}

-- デバッグ設定
Config.Debug = false                -- デバッグモード