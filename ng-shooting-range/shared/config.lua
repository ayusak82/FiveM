Config = {}

-- デバッグモード（本番環境ではfalseに設定）
Config.Debug = false

-- 射撃場の設定
Config.ShootingRanges = {
    {
        name = "LSPD射撃場",
        -- インタラクションポイント（3D座標）
        interactionPoint = vector3(482.47, -1015.39, 30.69),
        -- スポーンエリア（vector2で範囲指定 - 長方形の4つの角）
        spawnArea = {
            point1 = vector2(473.47, -1003.40),
            point2 = vector2(473.59, -1015.38),
            point3 = vector2(475.40, -1015.35),
            point4 = vector2(475.39, -1003.44),
            -- Z座標の範囲
            minZ = 30.09,
            maxZ = 30.09
        },
        heading = 0.0,
        blip = {
            enabled = true,
            sprite = 313,
            color = 1,
            scale = 0.8
        },
        marker = {
            type = 1,
            scale = vector3(1.5, 1.5, 1.0),
            color = { r = 0, g = 255, b = 0, a = 100 }
        }
    },
}

-- ゲーム設定
Config.GameSettings = {
    npcModel = "a_m_y_skater_01",
    npcLifetime = 2000, -- ミリ秒
    minTargets = 5,
    maxTargets = 50,
    defaultTargets = 10,
    -- NPC設定
    npcHealth = 100,
    npcArmor = 0,
    npcInvincible = false,
    npcFrozen = true, -- NPCを動かないようにする
    -- インタラクション距離
    interactionDistance = 2.0,
    markerDrawDistance = 10.0
}

-- スコア設定
Config.Scoring = {
    bodyParts = {
        head = 100,      -- ヘッドショット
        torso = 50,      -- 胴体
        other = 25       -- その他の部位
    },
    timeBonus = {
        { time = 0.5, bonus = 50 },
        { time = 1.0, bonus = 30 },
        { time = 1.5, bonus = 10 },
        { time = 2.0, bonus = 0 }
    }
}

-- 言語設定
Config.Locale = {
    ['start_practice'] = '射撃練習を開始',
    ['target_count'] = 'ターゲット数',
    ['target_count_desc'] = '5〜50の範囲で指定',
    ['practice_started'] = '射撃練習を開始しました',
    ['practice_finished'] = '射撃練習が終了しました',
    ['results'] = '射撃練習 - 結果',
    ['total_score'] = '合計スコア',
    ['hit_rate'] = '命中率',
    ['avg_time'] = '平均反応時間',
    ['best_score'] = '最高得点',
    ['current_score'] = '現在のスコア',
    ['targets_hit'] = 'ターゲット',
    ['press_e'] = '[E] 射撃練習を開始',
    ['invalid_input'] = '無効な入力値です',
    ['session_active'] = '既に練習セッションが進行中です'
}
