Config = {}

-- ============================================
-- 基本設定
-- ============================================

-- デフォルト使用回数
Config.DefaultUses = 10

-- 車両スポーン距離 (プレイヤーの前方)
Config.SpawnDistance = 5.0

-- 車両格納最大距離
Config.StoreDistance = 5.0

-- ============================================
-- 自動デスポーン設定
-- ============================================

Config.AutoDespawn = {
    enabled = true,              -- 自動デスポーンを有効化
    distance = 300.0,            -- プレイヤーからの距離 (メートル)
    time = 300,                  -- 放置時間 (秒) 300秒 = 5分
    checkInterval = 30           -- チェック間隔 (秒)
}

-- ============================================
-- スターターパック設定
-- ============================================

Config.StarterPack = {
    enabled = true,              -- スターターパックを有効化
    vehicles = {
        { model = 'blista', uses = 5 },     -- 初期車両1
        -- { model = 'futo', uses = 3 },    -- 初期車両2 (コメントアウト例)
    }
}

-- ============================================
-- ショップ設定
-- ============================================

Config.Shops = {
    {
        name = "車両カードショップ - ロスサントス",
        coords = vector3(-56.85, -1098.65, 26.42),  -- PDM付近
        blip = {
            enabled = true,
            sprite = 524,
            color = 3,
            scale = 0.8,
            name = "車両カードショップ"
        },
        marker = {
            type = 1,               -- マーカータイプ
            size = vector3(1.5, 1.5, 1.0),
            color = {r = 0, g = 150, b = 255, a = 100},
            distance = 10.0         -- マーカー表示距離
        },
        interactDistance = 2.5      -- インタラクション距離
    },
    -- 追加のショップはここに追加
    -- {
    --     name = "車両カードショップ - サンディ",
    --     coords = vector3(1234.56, -5678.90, 12.34),
    --     blip = { enabled = true, sprite = 524, color = 3, scale = 0.8, name = "車両カードショップ" },
    --     marker = {
    --         type = 1,
    --         size = vector3(1.5, 1.5, 1.0),
    --         color = {r = 0, g = 150, b = 255, a = 100},
    --         distance = 10.0
    --     },
    --     interactDistance = 2.5
    -- },
}

-- ============================================
-- 販売車両リスト
-- ============================================

Config.ShopVehicles = {
    -- コンパクトカー
    {
        category = "コンパクト",
        vehicles = {
            { model = 'blista', label = 'Blista', price = 50000, uses = 10 },
            { model = 'brioso', label = 'Brioso R/A', price = 55000, uses = 10 },
            { model = 'dilettante', label = 'Dilettante', price = 45000, uses = 10 },
            { model = 'issi2', label = 'Issi', price = 48000, uses = 10 },
            { model = 'panto', label = 'Panto', price = 40000, uses = 10 },
            { model = 'prairie', label = 'Prairie', price = 52000, uses = 10 },
            { model = 'rhapsody', label = 'Rhapsody', price = 58000, uses = 10 },
        }
    },
    -- セダン
    {
        category = "セダン",
        vehicles = {
            { model = 'asea', label = 'Asea', price = 60000, uses = 10 },
            { model = 'asterope', label = 'Asterope', price = 65000, uses = 10 },
            { model = 'cognoscenti', label = 'Cognoscenti', price = 150000, uses = 10 },
            { model = 'fugitive', label = 'Fugitive', price = 120000, uses = 10 },
            { model = 'ingot', label = 'Ingot', price = 55000, uses = 10 },
            { model = 'intruder', label = 'Intruder', price = 62000, uses = 10 },
            { model = 'premier', label = 'Premier', price = 68000, uses = 10 },
            { model = 'primo', label = 'Primo', price = 58000, uses = 10 },
            { model = 'primo2', label = 'Primo Custom', price = 85000, uses = 10 },
            { model = 'regina', label = 'Regina', price = 52000, uses = 10 },
            { model = 'stanier', label = 'Stanier', price = 60000, uses = 10 },
            { model = 'stratum', label = 'Stratum', price = 65000, uses = 10 },
            { model = 'surge', label = 'Surge', price = 72000, uses = 10 },
            { model = 'tailgater', label = 'Tailgater', price = 95000, uses = 10 },
            { model = 'warrener', label = 'Warrener', price = 78000, uses = 10 },
            { model = 'washington', label = 'Washington', price = 70000, uses = 10 },
        }
    },
    -- SUV
    {
        category = "SUV",
        vehicles = {
            { model = 'baller', label = 'Baller', price = 120000, uses = 10 },
            { model = 'cavalcade', label = 'Cavalcade', price = 115000, uses = 10 },
            { model = 'dubsta', label = 'Dubsta', price = 130000, uses = 10 },
            { model = 'fq2', label = 'FQ 2', price = 95000, uses = 10 },
            { model = 'granger', label = 'Granger', price = 105000, uses = 10 },
            { model = 'gresley', label = 'Gresley', price = 98000, uses = 10 },
            { model = 'habanero', label = 'Habanero', price = 92000, uses = 10 },
            { model = 'huntley', label = 'Huntley S', price = 145000, uses = 10 },
            { model = 'landstalker', label = 'Landstalker', price = 88000, uses = 10 },
            { model = 'mesa', label = 'Mesa', price = 75000, uses = 10 },
            { model = 'patriot', label = 'Patriot', price = 125000, uses = 10 },
            { model = 'radi', label = 'Radius', price = 110000, uses = 10 },
            { model = 'rocoto', label = 'Rocoto', price = 102000, uses = 10 },
            { model = 'seminole', label = 'Seminole', price = 85000, uses = 10 },
            { model = 'serrano', label = 'Serrano', price = 95000, uses = 10 },
            { model = 'xls', label = 'XLS', price = 135000, uses = 10 },
        }
    },
    -- スポーツ
    {
        category = "スポーツ",
        vehicles = {
            { model = 'alpha', label = 'Alpha', price = 250000, uses = 8 },
            { model = 'banshee', label = 'Banshee', price = 280000, uses = 8 },
            { model = 'bestiagts', label = 'Bestia GTS', price = 320000, uses = 8 },
            { model = 'blista2', label = 'Blista Compact', price = 180000, uses = 8 },
            { model = 'buffalo', label = 'Buffalo', price = 200000, uses = 8 },
            { model = 'buffalo2', label = 'Buffalo S', price = 240000, uses = 8 },
            { model = 'carbonizzare', label = 'Carbonizzare', price = 300000, uses = 8 },
            { model = 'comet2', label = 'Comet', price = 270000, uses = 8 },
            { model = 'coquette', label = 'Coquette', price = 290000, uses = 8 },
            { model = 'elegy', label = 'Elegy RH8', price = 0, uses = 10 },  -- 無料車両
            { model = 'elegy2', label = 'Elegy Retro Custom', price = 350000, uses = 8 },
            { model = 'feltzer2', label = 'Feltzer', price = 260000, uses = 8 },
            { model = 'furoregt', label = 'Furore GT', price = 285000, uses = 8 },
            { model = 'fusilade', label = 'Fusilade', price = 210000, uses = 8 },
            { model = 'futo', label = 'Futo', price = 90000, uses = 10 },
            { model = 'jester', label = 'Jester', price = 310000, uses = 8 },
            { model = 'khamelion', label = 'Khamelion', price = 295000, uses = 8 },
            { model = 'kuruma', label = 'Kuruma', price = 220000, uses = 8 },
            { model = 'lynx', label = 'Lynx', price = 340000, uses = 8 },
            { model = 'massacro', label = 'Massacro', price = 330000, uses = 8 },
            { model = 'ninef', label = '9F', price = 315000, uses = 8 },
            { model = 'ninef2', label = '9F Cabrio', price = 325000, uses = 8 },
            { model = 'penumbra', label = 'Penumbra', price = 195000, uses = 8 },
            { model = 'rapidgt', label = 'Rapid GT', price = 275000, uses = 8 },
            { model = 'rapidgt2', label = 'Rapid GT Cabrio', price = 280000, uses = 8 },
            { model = 'schafter3', label = 'Schafter V12', price = 305000, uses = 8 },
            { model = 'sultan', label = 'Sultan', price = 215000, uses = 8 },
            { model = 'surano', label = 'Surano', price = 265000, uses = 8 },
            { model = 'tampa', label = 'Tampa', price = 185000, uses = 8 },
            { model = 'tropos', label = 'Tropos Rallye', price = 295000, uses = 8 },
            { model = 'verlierer2', label = 'Verlierer', price = 345000, uses = 8 },
        }
    },
    -- スーパーカー
    {
        category = "スーパー",
        vehicles = {
            { model = 'adder', label = 'Adder', price = 1000000, uses = 5 },
            { model = 'banshee2', label = 'Banshee 900R', price = 700000, uses = 5 },
            { model = 'bullet', label = 'Bullet', price = 650000, uses = 5 },
            { model = 'cheetah', label = 'Cheetah', price = 680000, uses = 5 },
            { model = 'entityxf', label = 'Entity XF', price = 850000, uses = 5 },
            { model = 'fmj', label = 'FMJ', price = 920000, uses = 5 },
            { model = 'infernus', label = 'Infernus', price = 750000, uses = 5 },
            { model = 'osiris', label = 'Osiris', price = 900000, uses = 5 },
            { model = 'reaper', label = 'Reaper', price = 880000, uses = 5 },
            { model = 't20', label = 'T20', price = 950000, uses = 5 },
            { model = 'turismor', label = 'Turismo R', price = 820000, uses = 5 },
            { model = 'tyrus', label = 'Tyrus', price = 890000, uses = 5 },
            { model = 'vacca', label = 'Vacca', price = 720000, uses = 5 },
            { model = 'voltic', label = 'Voltic', price = 670000, uses = 5 },
            { model = 'zentorno', label = 'Zentorno', price = 870000, uses = 5 },
        }
    },
}

return Config
