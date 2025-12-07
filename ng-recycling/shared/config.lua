Config = {}

-- リサイクルセンターの入口
Config.EntranceLocations = {
    {
        coords = vector3(-469.48, -1721.86, 18.69), -- 座標は仮です、実際の場所に変更してください
        heading = 270.0,
        label = "リサイクルセンター",
        blip = {
            sprite = 365,
            color = 2,
            scale = 0.8,
            label = "リサイクルセンター"
        }
    }
}

-- リサイクルセンター内の座標（内部IPLの座標）
Config.RecyclingInterior = {
    coords = vector3(1072.55, -3102.56, -39.0),
    heading = 176.32,
    ipl = "ex_exec_warehouse_placement_interior_2_int_warehouse_m_dlc_milo"
}

-- リサイクルセンタールーム設定
Config.Rooms = {
    {id = 1, label = "ルーム 1", maxPlayers = 8, routingBucket = 1001},
    {id = 2, label = "ルーム 2", maxPlayers = 8, routingBucket = 1002},
    {id = 3, label = "ルーム 3", maxPlayers = 4, routingBucket = 1003},
    {id = 4, label = "ルーム 4", maxPlayers = 4, routingBucket = 1004},
    {id = 5, label = "ルーム 5", maxPlayers = 2, routingBucket = 1005},
    {id = 6, label = "ルーム 6", maxPlayers = 2, routingBucket = 1006},
    {id = 7, label = "ルーム 7", maxPlayers = 2, routingBucket = 1007},
    {id = 8, label = "ルーム 8", maxPlayers = 2, routingBucket = 1008},
    {id = 9, label = "ルーム 9", maxPlayers = 1, routingBucket = 1009},
    {id = 10, label = "ルーム 10", maxPlayers = 1, routingBucket = 1010},
    {id = 11, label = "ルーム 11", maxPlayers = 1, routingBucket = 1011},
    {id = 12, label = "ルーム 12", maxPlayers = 1, routingBucket = 1012},
    {id = 13, label = "ルーム 13", maxPlayers = 1, routingBucket = 1013},
    {id = 14, label = "ルーム 14", maxPlayers = 1, routingBucket = 1014},
    {id = 15, label = "ルーム 15", maxPlayers = 1, routingBucket = 1015},
    {id = 16, label = "ルーム 16", maxPlayers = 1, routingBucket = 1016},
    {id = 17, label = "ルーム 17", maxPlayers = 1, routingBucket = 1017},
    {id = 18, label = "ルーム 18", maxPlayers = 1, routingBucket = 1018},
    {id = 19, label = "ルーム 19", maxPlayers = 1, routingBucket = 1019},
    {id = 20, label = "ルーム 20", maxPlayers = 1, routingBucket = 1020},
    {id = 21, label = "ルーム 21", maxPlayers = 1, routingBucket = 1021},
    {id = 22, label = "ルーム 22", maxPlayers = 1, routingBucket = 1022},
    {id = 23, label = "ルーム 23", maxPlayers = 1, routingBucket = 1023},
    {id = 24, label = "ルーム 24", maxPlayers = 1, routingBucket = 1024},
    {id = 25, label = "ルーム 25", maxPlayers = 1, routingBucket = 1025},
    {id = 26, label = "ルーム 26", maxPlayers = 1, routingBucket = 1026},
    {id = 27, label = "ルーム 27", maxPlayers = 1, routingBucket = 1027},
    {id = 28, label = "ルーム 28", maxPlayers = 1, routingBucket = 1028},
    {id = 29, label = "ルーム 29", maxPlayers = 1, routingBucket = 1029},
    {id = 30, label = "ルーム 30", maxPlayers = 1, routingBucket = 1030},
}

-- ジョブ受注場所
Config.JobStartLocation = {
    coords = vector3(1049.05, -3100.58, -39.0),
    heading = 0.0,
    label = "ジョブ受付"
}

-- 納品場所
Config.DeliveryLocation = {
    coords = vector3(1048.66, -3097.18, -39.0),
    heading = 176.32,
    label = "納品場所"
}

-- 収集場所の設定
Config.PickupLocations = {
    { coords = vector3(1065.16, -3108.0, -39.0), heading = 176.32 },
    { coords = vector3(1060.32, -3107.8, -39.0), heading = 176.32 },
    { coords = vector3(1055.31, -3107.95, -39.0), heading = 176.32 },
    { coords = vector3(1055.56, -3104.28, -39.0), heading = 176.32 },
    { coords = vector3(1060.27, -3104.56, -39.0), heading = 176.32 },
    { coords = vector3(1065.18, -3104.61, -39.0), heading = 176.32 },
    { coords = vector3(1065.1, -3097.14, -39.0), heading = 176.32 },
    { coords = vector3(1060.5, -3097.18, -39.0), heading = 176.32 },
    { coords = vector3(1055.24, -3097.47, -39.0), heading = 176.32 },
}

-- リサイクル報酬
Config.Rewards = {
    money = {
        min = 0,
        max = 0
    },
    
    --[[
    items = { -- 1.0倍
        {name = "plastic", min = 7, max = 17, chance = 80},
        {name = "glass", min = 7, max = 17, chance = 80},
        {name = "aluminum", min = 5, max = 12, chance = 70},
        {name = "copper", min = 4, max = 10, chance = 60},
        {name = "rubber", min = 5, max = 12, chance = 70},
        {name = "steel", min = 5, max = 10, chance = 70},
        {name = "metalscrap", min = 5, max = 10, chance = 70},
        {name = "iron", min = 5, max = 10, chance = 60},
        {name = "titanium", min = 5, max = 10, chance = 60},
    }
    ]]
    
    items = { -- 1.5倍
        {name = "plastic", min = 10, max = 20, chance = 50},
        {name = "glass", min = 10, max = 20, chance = 50},
        {name = "aluminum", min = 10, max = 20, chance = 50},
        {name = "copper", min = 10, max = 20, chance = 50},
        {name = "rubber", min = 10, max = 20, chance = 50},
        {name = "steel", min = 10, max = 20, chance = 50},
        {name = "metalscrap", min = 10, max = 20, chance = 50},
        {name = "iron", min = 10, max = 20, chance = 50},
        {name = "titanium", min = 10, max = 20, chance = 50},
    }
    
}

-- 荷物回収数（1回のジョブで回収する荷物の数）
Config.PickupsPerJob = 6

-- マーカーの色設定
Config.MarkerColors = {
    entrance = {r = 0, g = 120, b = 255, a = 100},
    exit = {r = 255, g = 0, b = 0, a = 100},
    job_start = {r = 0, g = 255, b = 0, a = 100},
    delivery = {r = 255, g = 255, b = 0, a = 100},
    pickup = {r = 255, g = 165, b = 0, a = 100}
}

-- デバッグモード
Config.Debug = false

-- 経験値システムの説明
-- レベル1～50まで成長できます
-- レベルアップによるボーナス:
--   - 採取量ボーナス: Lv.1 = 100%, Lv.50 = 200% (最大2倍)
--   - 取得速度向上: Lv.1 = 0%, Lv.50 = 50%短縮 (最大50%短縮)
-- 経験値取得:
--   - 荷物納品毎に15 XP
--   - 全納品完了でボーナス (1.5倍)
-- レベル情報表示:
--   - リサイクルセンター内の受付付近でGキーで確認可能