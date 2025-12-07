Config = {}

-- ミニゲーム設定
Config.MiniGame = {
    enabled = true,      -- ミニゲーム機能の有効/無効
    difficulty = {'medium'}, -- 難易度設定（難しめに設定）
    explosionChance = 100 -- 失敗時に爆発する確率（%）
}

-- クラフト作業のアニメーション設定
Config.CraftAnimation = {
    dict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@",
    anim = "machinic_loop_mechandplayer",
    duration = 10000  -- アニメーション時間（ミリ秒）- 10秒
}

-- 爆発設定
Config.Explosion = {
    type = 34,           -- 爆発のタイプ
    damage = 1.0,        -- ダメージ量
    radius = 5.0,        -- 爆発の半径
    isAudible = true,    -- 音を出すか
    isInvisible = false, -- 見えないか
    cameraShake = 1.0    -- カメラの揺れ
}

-- 警察通報設定
Config.PoliceAlert = {
    enabled = true,                  -- 警察通報機能の有効/無効
    job = "police",                  -- 警察の職業コード
    requiredCops = 2,                -- 製造に必要な最低警察官数
    blipSprite = 161,                -- 通報時のブリップスプライト
    blipColor = 1,                   -- 通報時のブリップ色 (赤)
    blipScale = 1.0,                 -- ブリップのサイズ
    blipTime = 120,                  -- ブリップの表示時間(秒)
    soundName = "Lose_1st",          -- 通知音の名前
    soundRef = "GTAO_FM_Events_Soundset", -- 通知音のリファレンス
    notifyTitle = "違法薬物製造の通報",  -- 通知タイトル
    notifyDesc = "爆発音が聞こえました。薬物製造の疑いがあります。現場に向かってください。" -- 通知の説明
}

-- クラフトポイントの設定
Config.CraftPoints = {
    {
        coords = vector3(-469.07, 6284.91, 13.61), -- Trevors Trailer
        label = '薬物製造所1',
    },
    {
        coords = vector3(1250.15, -2576.12, 42.72), -- Farm House
        label = '薬物製造所2',
    },
    {
        coords = vector3(-457.82, -2266.09, 8.52), -- Mountain Lab
        label = '薬物製造所3',
    }
}

-- クラフトレシピの設定
Config.CraftRecipes = {
    ['drug1'] = {
        label = '怪しい薬物１',
        ingredients = {
            { item = 'dsmaterial1', amount = 10 },
            { item = 'dsmaterial4', amount = 10 }
        },
        time = 60000, -- 60秒
        minigameCount = 1, -- 必要なミニゲームの回数
        output = {
            item = 'drug1',
            amount = 1
        }
    },
    ['drug2'] = {
        label = '怪しい薬物２',
        ingredients = {
            { item = 'dsmaterial2', amount = 10 },
            { item = 'dsmaterial5', amount = 10 }
        },
        time = 60000, -- 60秒
        minigameCount = 2, -- 必要なミニゲームの回数
        output = {
            item = 'drug2',
            amount = 1
        }
    },
    ['drug3'] = {
        label = '怪しい薬物３',
        ingredients = {
            { item = 'dsmaterial3', amount = 10 },
            { item = 'dsmaterial6', amount = 10 },
        },
        time = 60000, -- 60秒
        minigameCount = 3, -- 必要なミニゲームの回数
        output = {
            item = 'drug3',
            amount = 1
        }
    }
}