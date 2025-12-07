Config = {}

-- 基本設定
Config.Framework = 'qb-core' -- qb-core or esx
Config.Debug = false

-- Job設定
Config.AllowedJobs = {
    'unemployed',
    'criminal',
    'citizen'
}

-- 地下基地入口設定
Config.EntranceLocation = {
    coords = vector3(715.23, 4165.17, 40.71), -- 例：Paleto Bay近くの山
    heading = 0.0,
    marker = {
        type = 1,
        size = {x = 1.5, y = 1.5, z = 1.0},
        color = {r = 255, g = 255, b = 0, a = 100},
        bobUpAndDown = true,
        faceCamera = false,
        rotate = false
    }
}

-- 地下基地内部設定
Config.UndergroundBase = {
    coords = vector3(899.5518, -3246.038, -98.04907), -- 実際の地下基地座標
    heading = 0.0,
    
    -- 化学物質精製作業エリア
    ChemicalStation = {
        coords = vector3(906.0, -3250.0, -98.04907),
        heading = 180.0
    },
    
    -- 機械部品組み立て作業エリア
    MechanicalStation = {
        coords = vector3(892.0, -3245.0, -98.04907),
        heading = 270.0
    },
    
    -- 出口
    ExitLocation = {
        coords = vector3(898.29, -3245.83, -98.14),
        heading = 0.0
    }
}

-- カメラ設定（入場ムービー用）
Config.CameraSettings = {
    EntrySequence = {
        -- 入場時のカメラポジション
        StartCam = {
            coords = vector3(715.23, 4165.17, 45.0),
            rot = vector3(-20.0, 0.0, 0.0)
        },
        -- フェード中のカメラ
        TransitionCam = {
            coords = vector3(1259.62, -1761.85, -35.0),
            rot = vector3(-10.0, 0.0, 140.0)
        },
        -- 最終カメラポジション
        EndCam = {
            coords = vector3(1259.62, -1761.85, -38.0),
            rot = vector3(0.0, 0.0, 140.0)
        }
    },
    TransitionTime = 3000 -- ミリ秒
}

-- 作業設定
Config.WorkSettings = {
    -- 疲労システム
    MaxStamina = 100,
    StaminaDecreasePerWork = 10,
    StaminaRegenRate = 2, -- 毎秒
    
    -- 作業時間
    ChemicalWorkTime = 15000, -- 15秒
    MechanicalWorkTime = 20000, -- 20秒
    
    -- クールダウン
    WorkCooldown = 5000 -- 5秒
}

-- 報酬設定
Config.Rewards = {
    Chemical = {
        Items = {
            {item = 'chemical_low', label = '低品質化学物質', chance = 60, amount = {1, 3}},
            {item = 'chemical_mid', label = '中品質化学物質', chance = 30, amount = {1, 2}},
            {item = 'chemical_high', label = '高品質化学物質', chance = 10, amount = {1, 1}}
        },
        Money = {min = 150, max = 300}
    },
    Mechanical = {
        Items = {
            {item = 'mechanical_low', label = '低品質機械部品', chance = 55, amount = {1, 2}},
            {item = 'mechanical_mid', label = '中品質機械部品', chance = 35, amount = {1, 2}},
            {item = 'mechanical_high', label = '高品質機械部品', chance = 10, amount = {1, 1}}
        },
        Money = {min = 200, max = 400}
    }
}

-- ミニゲーム設定
Config.Minigames = {
    Chemical = {
        type = 'mixing',
        difficulty = 'medium',
        timeLimit = 30 -- 秒
    },
    Mechanical = {
        type = 'assembly',
        difficulty = 'medium',
        timeLimit = 45 -- 秒
    }
}

-- メッセージ
Config.Messages = {
    NoJob = '必要な職業に就いていません',
    EnterBase = '地下基地に入る',
    ExitBase = '地上に戻る',
    StartChemical = '化学物質精製を開始',
    StartMechanical = '機械部品組み立てを開始',
    Working = '作業中...',
    WorkComplete = '作業完了！',
    NotEnoughStamina = 'スタミナが不足しています',
    OnCooldown = 'まだ次の作業はできません',
    Success = '作業成功！',
    Failed = '作業失敗...'
}