Config = {}

-- ミッションNPCの設定
Config.MissionNPC = {
    model = 'a_m_y_business_03',  -- NPCのモデル
    coords = vector4(707.24, -966.99, 30.41, 133.77),  -- NPCの位置と向き
    scenario = 'WORLD_HUMAN_CLIPBOARD',  -- NPCのアニメーション
    blip = {
        sprite = 521,  -- MissionのBlipスプライト
        color = 5,     -- MissionのBlipの色
        scale = 0.7,   -- MissionのBlipのサイズ
        label = 'データ強盗'  -- MissionのBlipのラベル
    },
    targetOptions = {
        label = 'ミッションを受ける',
        icon = 'fas fa-laptop-code'
    }
}

-- ハッキング可能なPCの設定
Config.HackableComputers = {
    {
        coords = vector3(713.23, -968.06, 30.4),
        heading = 298.48,
        blip = {
            sprite = 521,
            color = 1,
            scale = 0.6,
            label = 'ハッキング対象'
        }
    },
    {
        coords = vector3(713.9, -961.62, 30.4),
        heading = 174.33,
        blip = {
            sprite = 521,
            color = 1,
            scale = 0.6,
            label = 'ハッキング対象'
        }
    },
    {
        coords = vector3(705.85, -960.6, 30.4),
        heading = 181.42,
        blip = {
            sprite = 521,
            color = 1,
            scale = 0.6,
            label = 'ハッキング対象'
        }
    }
}

-- 納品場所の設定
Config.DeliveryLocation = {
    coords = vector3(720.89, -965.68, 30.4),
    heading = 89.19,
    blip = {
        sprite = 501,
        color = 2,
        scale = 0.7,
        label = '納品場所'
    }
}

-- ミッションの設定
Config.Mission = {
    hackingAttempts = 3,  -- ハッキングの試行回数
    hackingTimeout = 30,  -- ハッキングのタイムアウト（秒）
    difficulty = {
        easy = {
            wordCount = 3,
            wordLength = {min = 3, max = 5},
            timeLimit = 25
        },
        medium = {
            wordCount = 5,
            wordLength = {min = 3, max = 6},
            timeLimit = 30
        },
        hard = {
            wordCount = 7,
            wordLength = {min = 4, max = 8},
            timeLimit = 35
        }
    },
    hackingRewards = {
        harddrive = {
            name = 'harddrive',
            label = 'ハードドライブ',
            weight = 500,
            count = 1
        }
    },
    deliveryRewards = {
        money = {min = 500000, max = 1000000},
        items = {
            {
                name = 'cryptostick',
                label = '暗号通貨スティック',
                count = {min = 1, max = 3}
            }
        }
    }
}

-- デバッグモード
Config.Debug = false