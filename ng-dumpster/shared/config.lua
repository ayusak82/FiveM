Config = {}

-- ゴミ箱を漁る設定
Config.SearchTime = 5000 -- 漁る時間（ミリ秒）
Config.Cooldown = 300000 -- クールダウン時間（ミリ秒）5分 = 300000

-- ゴミ箱のモデル
Config.DumpsterModels = {
    'prop_dumpster_01a',
    'prop_dumpster_02a',
    'prop_dumpster_02b',
    'prop_dumpster_3a',
    'prop_dumpster_4a',
    'prop_dumpster_4b',
    'prop_cs_dumpster_01a',
    'prop_snow_dumpster_01',
    'prop_cs_bin_03',
    'prop_cs_bin_02',
    'prop_bin_07b',
    'prop_bin_01a',
    'prop_recyclebin_04_a',
    'prop_bin_beach_01a',
    'prop_recyclebin_02_c',
    'zprop_bin_01a_old',
    'prop_recyclebin_03_a',
    'prop_bin_07c',
    'prop_bin_10b',
    'prop_bin_10a',
    'prop_bin_14a',
    'prop_bin_11a',
    'prop_bin_06a',
    'prop_bin_07d',
    'prop_bin_11b',
    'prop_bin_04a',
    'prop_recyclebin_02b',
    'prop_bin_09a',
    'prop_bin_08a',
    'prop_recyclebin_04_b',
    'prop_bin_02a',
    'prop_bin_03a',
    'prop_bin_05a',
    'prop_bin_07a',
    'prop_recyclebin_01a',
}

-- 報酬設定（修正版）
-- 注意: 確率は重み付けとして機能します
-- より高い値を持つアイテムほど当たりやすくなります
Config.Rewards = {
    -- アイテム報酬（重み付け抽選）
    items = {
        {name = 'plastic', min = 5, max = 10, chance = 30}, -- 最も高確率
        {name = 'glass', min = 5, max = 10, chance = 25},
        {name = 'aluminum', min = 4, max = 8, chance = 20},
        {name = 'copper', min = 3, max = 6, chance = 15},
        {name = 'rubber', min = 4, max = 8, chance = 15},
        {name = 'steel', min = 4, max = 8, chance = 10},
        {name = 'metalscrap', min = 4, max = 8, chance = 10},
        {name = 'iron', min = 4, max = 8, chance = 8},
        {name = 'titanium', min = 4, max = 8, chance = 5},
        {name = 'lockpick', min = 1, max = 3, chance = 3}, -- レアアイテム
    },
    
    -- 現金報酬（独立抽選）
    cash = {
        enabled = true, -- 現金報酬を有効にするか
        min = 10000, -- 最小金額
        max = 50000, -- 最大金額
        chance = 20 -- 20%の確率
    },
    
    -- 何も見つからない確率（最優先判定）
    nothingChance = 25 -- 25%の確率で何も見つからない
}

-- ox_target設定
Config.TargetDistance = 2.0 -- ターゲット可能距離

-- アニメーション設定
Config.Animation = {
    dict = 'amb@prop_human_bum_bin@idle_b',
    anim = 'idle_d',
    flags = 1
}

-- 通知メッセージ（購入者がカスタマイズ可能）
Config.Locale = {
    search_dumpster = 'ゴミ箱を漁る',
    searching = 'ゴミ箱を漁っています...',
    found_item = 'を見つけた！',
    found_cash = '円を見つけた！',
    found_nothing = '何も見つからなかった...',
    cooldown = 'このゴミ箱は最近漁ったばかりです',
    target_label = 'ゴミ箱を漁る'
}
