Config = {}

-- 宝くじアイテムの設定
Config.LotteryItem = 'lottery_ticket' -- 使用する宝くじアイテムの名前

-- 報酬設定
Config.Rewards = {
    minAmount = 1000000,    -- 最小報酬額（ドル）
    maxAmount = 5000000   -- 最大報酬額（ドル）
}

-- アニメーション設定
Config.Animation = {
    dict = 'amb@world_human_stand_impatient@male@no_sign@idle_a',
    anim = 'idle_a',
    duration = 3000 -- アニメーション時間（ミリ秒）
}

-- UI設定
Config.UI = {
    showTime = 5000, -- 結果表示時間（ミリ秒）
    enableSound = true -- サウンド効果の有効/無効
}

-- デバッグモード
Config.Debug = false