Config = {}

-- NPCの基本設定
Config.NPCs = {
    {
        id = 'npc_1',                      -- NPCの一意の識別子
        name = 'おバカなザウルス',                 -- NPCの表示名
        model = 'a_m_y_business_03',       -- NPCのモデル名
        scenario = 'WORLD_HUMAN_STAND_IMPATIENT', -- NPCのアニメーション
        coords = vector4(-694.35, -789.06, 33.05, 91.38), -- NPCの座標(x, y, z, heading)
        blip = {                          -- マップのブリップ設定（任意）
            enabled = true,               -- ブリップを表示するかどうか
            sprite = 280,                 -- ブリップのスプライト
            color = 2,                    -- ブリップの色
            scale = 0.7,                  -- ブリップのサイズ
            label = 'www'         -- ブリップの名前
        },
        dialogues = {                     -- NPCとの会話内容
            greeting = 'こんにちは、何かお手伝いできることはありますか？',
            options = {                   -- 会話選択肢
                {
                    label = 'おバカについて聞く',
                    response = 'なんかブラックマーケットで買い物したら間違えて20個買ってしまった...'
                },
                {
                    label = '町について聞く',
                    response = 'ここはロスサントスの中心部です。飲食店や娯楽施設が多く、観光客に人気のエリアです。'
                },
                {
                    label = '噂について聞く',
                    response = '最近、北の方で怪しい動きがあるという噂を聞きました。気をつけた方がいいかもしれません。'
                },
            },
            farewell = 'またいつでも話しかけてください！'
        }
    },
    -- 必要に応じて他のNPCを追加できます
    {
        id = 'npc_2',
        name = '鈴木花子',
        model = 'a_f_y_business_04',
        scenario = 'WORLD_HUMAN_CLIPBOARD',
        coords = vector4(248.22, -768.78, 30.83, 250.52),
        blip = {
            enabled = true,
            sprite = 480,
            color = 5,
            scale = 0.7,
            label = '情報提供者'
        },
        dialogues = {
            greeting = 'いらっしゃいませ。何かご質問はありますか？',
            options = {
                {
                    label = 'この辺りの店について教えて',
                    response = '近くにはカフェやレストランがあります。特に角のイタリアンレストランはおすすめですよ。'
                },
                {
                    label = '安全な地域はどこですか？',
                    response = 'ビンウッドヒルズやロックフォードヒルズは比較的安全な地域です。夜間は気をつけてくださいね。'
                },
            },
            farewell = 'お気をつけて。良い一日を！'
        }
    }
}

-- 会話UIの設定
Config.UI = {
    dialogWidth = 400,      -- ダイアログの幅
    dialogColor = {r = 0, g = 128, b = 255}, -- ダイアログの色（RGB）
    dialogTimeout = 5000,   -- メッセージ表示時間（ミリ秒）
    interactionDistance = 2.5, -- NPCとの最大対話距離
    interactionKey = 'E',   -- 対話キー
    nameLabel = {
        font = 0,           -- 名前表示のフォント
        scale = 0.35,       -- 名前表示のサイズ
        color = {255, 255, 255, 215}, -- 名前表示の色（RGBA）
        showDistance = 10.0 -- 名前を表示する最大距離
    }
}

-- プレイヤーNPCの設定
Config.PlayerNPC = {
    defaultScenario = 'WORLD_HUMAN_STAND_IMPATIENT', -- デフォルトのシナリオ/アニメーション
    defaultDialogues = {
        greeting = 'こんにちは、何かお手伝いできることはありますか？',
        options = {
            {
                label = '調子はどう？',
                response = '元気にしてるよ、ありがとう！'
            },
            {
                label = 'この辺りについて教えて',
                response = 'この辺りはとても平和な場所だよ。特に何もないけど、穏やかに過ごせるよ。'
            }
        },
        farewell = 'またいつでも話しかけてね！'
    }
}

-- デバッグモード
Config.Debug = false        -- デバッグ情報の表示を有効/無効にする