Config = {}

-- ============================================
-- 基本設定
-- ============================================
Config.Debug = false -- デバッグモード

-- 死亡時の設定
Config.DeathSettings = {
    teleportOnDeath = true, -- 死亡時に受注場所にテレポートするか
    skipIfEMSOnline = false, -- EMSがオンラインの場合はテレポートをスキップ
    emsJobs = {'ambulance', 'doctor'}, -- EMSジョブのリスト
    minEMSCount = 1, -- テレポートをスキップする最小EMS人数
    teleportDelay = 2000 -- リスポーン後のテレポート待機時間(ミリ秒)
}

-- NPC受注場所
Config.NPCLocation = {
    coords = vector4(-956.48, -2918.93, 13.96, 151.75), -- LSIA貨物エリア
    model = 's_m_m_pilot_02',
    scenario = 'WORLD_HUMAN_CLIPBOARD'
}

-- 車両スポーン位置
Config.VehicleSpawn = {
    coords = vector4(-975.74, -2977.44, 13.95, 58.21),
    model = 'titan'
}

-- 帰還場所
Config.ReturnLocation = vector3(-956.48, -2918.93, 13.96)
Config.ReturnRadius = 50.0 -- 帰還判定の半径

-- ============================================
-- 目的地設定
-- ============================================
Config.Destinations = {
    {
        name = '軍事基地',
        coords = vector3(-1828.03, 2974.82, 32.81),
        difficulty = 'hard',
        distance = 5800 -- メートル
    },
    {
        name = 'サンディ空港',
        coords = vector3(1707.94, 3251.94, 41.87),
        difficulty = 'normal',
        distance = 4200
    },
    {
        name = 'グレイプシード',
        coords = vector3(2070.91, 4779.16, 41.96),
        difficulty = 'hard',
        distance = 5200
    }
}

-- ============================================
-- 難易度設定
-- ============================================
Config.Difficulties = {
    easy = {
        label = '簡単 (1箇所配送)',
        destinations = 1,
        timeLimit = 600, -- 秒 (10分)
        baseReward = 50000,
        experience = 50,
        timeBonus = 10000, -- 早期完了ボーナス
        unloadCount = 3
    },
    normal = {
        label = '普通 (2箇所配送)',
        destinations = 2,
        timeLimit = 900, -- 秒 (15分)
        baseReward = 120000,
        experience = 120,
        timeBonus = 25000,
        unloadCount = 4
    },
    hard = {
        label = '難しい (3箇所配送)',
        destinations = 3,
        timeLimit = 1200, -- 秒 (20分)
        baseReward = 250000,
        experience = 250,
        timeBonus = 50000,
        unloadCount = 5
    }
}

-- ============================================
-- 報酬設定
-- ============================================
Config.Rewards = {
    -- 基本報酬アイテム (複数設定可能)
    items = {
        {name = 'money', amount = 100000, type = 'item'}, -- 金額は動的に設定
        {name = 'plastic', amount = 50, type = 'item'},
        {name = 'glass', amount = 50, type = 'item'},
        {name = 'aluminum', amount = 75, type = 'item'},
        {name = 'copper', amount = 75, type = 'item'},
        {name = 'rubber', amount = 50, type = 'item'},
        {name = 'steel', amount = 50, type = 'item'},
        {name = 'metalscrap', amount = 75, type = 'item'},
        {name = 'iron', amount = 75, type = 'item'},
        {name = 'titanium', amount = 50, type = 'item'},
    },
    
    -- レベルボーナス (レベルごとの報酬倍率)
    levelBonus = {
        [1] = 1.0,   -- レベル1: 100%
        [5] = 1.1,   -- レベル5: 110%
        [10] = 1.2,  -- レベル10: 120%
        [15] = 1.3,
        [20] = 1.5,
        [30] = 1.7,
        [50] = 2.0   -- レベル50: 200%
    }
}

-- ============================================
-- 経験値・レベルシステム
-- ============================================
Config.LevelSystem = {
    experiencePerLevel = 500, -- レベルアップに必要な経験値
    maxLevel = 50,
    
    -- レベルアップ報酬
    levelUpRewards = {
        [5] = {money = 100000, message = 'レベル5到達ボーナス!'},
        [10] = {money = 250000, message = 'レベル10到達ボーナス!'},
        [20] = {money = 500000, message = 'レベル20到達ボーナス!'},
        [30] = {money = 1000000, message = 'レベル30到達ボーナス!'},
        [50] = {money = 2500000, message = 'レベル50(最大)到達ボーナス!'}
    }
}

-- ============================================
-- ランダムイベント
-- ============================================
Config.RandomEvents = {
    enabled = true,
    chance = 25, -- 発生確率 (%)
    
    events = {
        {
            name = '追加荷物',
            description = '追加の貨物が見つかりました!',
            rewardMultiplier = 1.3,
            extraUnloads = 2
        },
        {
            name = '緊急配送',
            description = '緊急配送依頼です!',
            rewardMultiplier = 1.5,
            timeReduction = 120 -- 制限時間-2分
        },
        {
            name = 'VIP貨物',
            description = 'VIP貨物の配送です!',
            rewardMultiplier = 2.0,
            experienceMultiplier = 1.5
        }
    }
}

-- ============================================
-- 荷下ろし設定
-- ============================================
Config.UnloadSettings = {
    duration = 5000, -- ミリ秒
    animation = {
        dict = 'anim@heists@box_carry@',
        anim = 'idle',
        flags = 49
    },
    progressBar = {
        label = '荷物を降ろしています...',
        useWhileDead = false,
        canCancel = false
    }
}

-- ============================================
-- UI設定
-- ============================================
Config.UI = {
    -- 残り時間表示の更新間隔 (ミリ秒)
    timerUpdateInterval = 1000,
    
    -- 通知の表示時間
    notificationDuration = 5000,
    
    -- ブリップ設定
    blip = {
        sprite = 307, -- 貨物アイコン
        color = 5,    -- 黄色
        scale = 1.0,
        label = '配送先'
    },
    
    -- ルートGPS
    routeColor = 5 -- 黄色
}

-- ============================================
-- ルーティングバケット設定
-- ============================================
Config.RoutingBucket = {
    enabled = true,
    startBucket = 1000 -- 開始バケット番号 (プレイヤーIDを加算)
}

-- ============================================
-- 管理者設定
-- ============================================
Config.AdminGroups = {'god', 'admin'} -- 管理コマンドを使用できるグループ

-- ============================================
-- ランキング設定
-- ============================================
Config.Ranking = {
    topCount = 10, -- 表示するトップ配送者の数
    categories = {
        {id = 'deliveries', label = '総配送回数', column = 'total_deliveries'},
        {id = 'earnings', label = '総収入', column = 'total_earned'},
        {id = 'level', label = 'レベル', column = 'level'},
        {id = 'time', label = '最速記録', column = 'best_time'}
    }
}

-- ============================================
-- メッセージ
-- ============================================
Config.Messages = {
    npc_greeting = '貨物輸送の仕事に興味があるか?',
    job_started = '配送を開始しました。目的地に向かってください。',
    job_cancelled = '配送をキャンセルしました。',
    job_failed = '配送に失敗しました。',
    job_completed = '配送完了!報酬を受け取りました。',
    vehicle_destroyed = '車両が破壊されました。配送失敗です。',
    already_in_job = '既に配送中です。',
    arrive_destination = '目的地に到着しました。荷物を降ろしてください。',
    unload_complete = '荷下ろし完了!',
    return_to_base = '全ての配送が完了しました。空港に戻ってください。',
    time_bonus = '時間内に完了!ボーナスを獲得しました。',
    level_up = 'レベルアップ!現在レベル: %s',
    random_event = 'イベント発生: %s'
}