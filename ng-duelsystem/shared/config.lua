Config = {}

-- ===================================
-- デバッグモード
-- ===================================
Config.Debug = false -- trueにするとデバッグ情報をコンソールに表示

-- ===================================
-- 言語設定
-- ===================================
Config.Locale = 'ja'

-- ===================================
-- デュエル基本設定
-- ===================================
Config.DuelSettings = {
    MinPlayers = 2, -- 最低プレイヤー数
    MaxRounds = 5, -- 最大ラウンド数（先取制）
    RoundTime = 180, -- 1ラウンドの制限時間（秒）
    PrepTime = 15, -- 準備時間（秒）
    RespawnTime = 5, -- リスポーン待機時間（秒）
    AllowSpectators = true, -- 観客モードを許可
    MaxSpectators = 10, -- 最大観客数
}

-- ===================================
-- アリーナ設定
-- ===================================
Config.Arenas = {
    {
        name = 'アリーナ1 - 倉庫',
        enabled = true,
        location = vector3(941.23, -2110.01, 30.5), -- メニュー開始位置
        spawn1 = vector4(920.0, -2130.0, 31.47, 0.0), -- プレイヤー1スポーン
        spawn2 = vector4(950.0, -2110.0, 31.47, 180.0), -- プレイヤー2スポーン
        spectatorSpawn = vector4(935.0, -2120.0, 35.0, 90.0), -- 観客スポーン
        blip = {
            enabled = true,
            sprite = 437,
            color = 1,
            scale = 0.8,
            label = 'デュエルアリーナ'
        }
    },
    {
        name = 'アリーナ2 - 屋上',
        enabled = true,
        location = vector3(-72.0, -818.0, 326.0),
        spawn1 = vector4(-80.0, -818.0, 326.0, 90.0),
        spawn2 = vector4(-64.0, -818.0, 326.0, 270.0),
        spectatorSpawn = vector4(-72.0, -810.0, 326.0, 180.0),
        blip = {
            enabled = true,
            sprite = 437,
            color = 1,
            scale = 0.8,
            label = 'デュエルアリーナ'
        }
    },
}

-- ===================================
-- 武器設定
-- ===================================
Config.Weapons = {
    {
        label = 'ピストル',
        category = 'handgun',
        weapons = {
            { name = 'weapon_pistol', label = 'ピストル', ammo = 50 },
            { name = 'weapon_combatpistol', label = 'コンバットピストル', ammo = 50 },
            { name = 'weapon_pistol50', label = 'ピストル.50', ammo = 30 },
            { name = 'weapon_heavypistol', label = 'ヘビーピストル', ammo = 40 },
        }
    },
    {
        label = 'SMG',
        category = 'smg',
        weapons = {
            { name = 'weapon_microsmg', label = 'マイクロSMG', ammo = 100 },
            { name = 'weapon_smg', label = 'SMG', ammo = 100 },
            { name = 'weapon_assaultsmg', label = 'アサルトSMG', ammo = 100 },
        }
    },
    {
        label = 'アサルトライフル',
        category = 'rifle',
        weapons = {
            { name = 'weapon_assaultrifle', label = 'アサルトライフル', ammo = 120 },
            { name = 'weapon_carbinerifle', label = 'カービンライフル', ammo = 120 },
            { name = 'weapon_advancedrifle', label = 'アドバンスドライフル', ammo = 120 },
        }
    },
    {
        label = 'ショットガン',
        category = 'shotgun',
        weapons = {
            { name = 'weapon_pumpshotgun', label = 'ポンプショットガン', ammo = 40 },
            { name = 'weapon_sawnoffshotgun', label = 'ソードオフショットガン', ammo = 30 },
        }
    },
    {
        label = 'スナイパー',
        category = 'sniper',
        weapons = {
            { name = 'weapon_sniperrifle', label = 'スナイパーライフル', ammo = 30 },
            { name = 'weapon_marksmanrifle', label = 'マークスマンライフル', ammo = 40 },
        }
    },
}

-- ===================================
-- 報酬設定
-- ===================================
Config.Rewards = {
    enabled = true,
    winReward = {
        money = 5000, -- 勝利時の報酬金額
        type = 'cash' -- 'cash' or 'bank'
    },
    loseReward = {
        money = 1000, -- 敗北時の報酬金額
        type = 'cash'
    },
    -- アイテム報酬（オプション）
    itemRewards = {
        enabled = false,
        winItems = {
            -- { item = 'example_item', amount = 1, chance = 100 }
        }
    }
}

-- ===================================
-- 統計・ランキング設定
-- ===================================
Config.Statistics = {
    enabled = true, -- 統計機能を有効化
    saveToDatabase = true, -- データベースに保存
    showRanking = true, -- ランキング表示
    topPlayersCount = 10, -- 上位表示数
}

-- ===================================
-- UI設定
-- ===================================
Config.UI = {
    drawTextFont = 0, -- 日本語対応フォント
    drawTextScale = 0.4,
    notificationPosition = 'top', -- 'top', 'top-right', 'top-left', 'bottom', 'bottom-right', 'bottom-left', 'center-right', 'center-left'
}

-- ===================================
-- 言語テキスト
-- ===================================
Config.Text = {
    -- メニュー
    menu_title = 'デュエルシステム',
    menu_start_duel = 'デュエルを開始',
    menu_view_stats = '統計を見る',
    menu_view_ranking = 'ランキングを見る',
    menu_spectate = '観戦する',
    
    -- デュエルリクエスト
    select_player = 'プレイヤーを選択',
    select_arena = 'アリーナを選択',
    select_rounds = 'ラウンド数を選択',
    select_weapon = '武器を選択',
    
    -- 通知
    duel_request_sent = 'デュエルリクエストを送信しました',
    duel_request_received = '%s さんからデュエルリクエストが届きました',
    duel_accepted = 'デュエルが承認されました',
    duel_declined = 'デュエルが拒否されました',
    duel_started = 'デュエルが開始されました！',
    duel_ended = 'デュエルが終了しました',
    
    -- ゲーム中
    round_start = 'ラウンド %s 開始！',
    round_end = 'ラウンド %s 終了',
    prep_time = '準備時間: %s秒',
    you_won = 'あなたの勝利！',
    you_lost = '敗北しました',
    draw = '引き分け',
    
    -- エラー
    no_players_nearby = '近くにプレイヤーがいません',
    player_in_duel = 'このプレイヤーは既にデュエル中です',
    you_in_duel = 'あなたは既にデュエル中です',
    arena_occupied = 'このアリーナは使用中です',
    
    -- その他
    press_to_open = '[E] デュエルメニューを開く',
    spectator_mode = '観戦モード',
    reward_received = '報酬: $%s を受け取りました',
}

-- ===================================
-- 権限設定
-- ===================================
Config.Permissions = {
    adminCommands = {
        'admin',
        'god'
    }
}