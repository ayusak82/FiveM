Config = {}

-- 基本設定
Config.Debug = false -- デバッグモード（true/false）
Config.UseTarget = true -- targetシステムを使用するかどうか
Config.TargetResource = 'qb-target' -- 使用するターゲットリソース: 'qb-target' または 'ox_target'
Config.UseBlips = true -- マップ上にブリップを表示するかどうか
Config.ShowMarkers = true -- マーカーを表示するかどうか

-- ジョブ設定
Config.RequireJob = false -- 特定のジョブが必要かどうか
Config.JobName = 'delivery' -- 必要なジョブ名（Config.RequireJob = trueの場合のみ使用）

-- 通知設定
Config.Notifications = {
    Success = 'success', -- 成功通知タイプ
    Error = 'error',     -- エラー通知タイプ
    Info = 'inform'      -- 情報通知タイプ
}

-- 配達報酬設定
Config.Rewards = {
    Money = {
        Min = 500,       -- 最小報酬額
        Max = 1500       -- 最大報酬額
    },
    Experience = {
        Min = 10,        -- 最小経験値
        Max = 30         -- 最大経験値
    },
    ItemChance = 25,     -- アイテム報酬を得る確率（%）
    Items = {            -- 報酬アイテムリスト
        {name = 'water', amount = {min = 1, max = 3}},
        {name = 'sandwich', amount = {min = 1, max = 2}},
        {name = 'phone', amount = {min = 1, max = 1}}
    }
}

-- 車両設定
Config.VehicleSettings = {
    SpawnVehicle = true, -- 配達車両をスポーンするかどうか
    VehicleModel = 'rumpo', -- 使用する車両モデル
    DeleteVehicle = false, -- ミッション終了時に車両を削除するかどうか（常にfalseに設定しておくこと）
    RequireReturn = true, -- 報酬を受け取るには拠点に戻る必要があるか（trueで固定 - 必ず拠点に戻る必要あり）
    ReturnRadius = 10.0, -- 拠点に戻ったとみなす距離（メートル）
    FuelLevel = 100,       -- 車両の燃料レベル（100%）
    SpawnOffset = vector3(0.0, 5.0, 0.0), -- 配達拠点からの車両スポーン位置オフセット
    VehicleKeys = 'qb', -- 使用する車両鍵システム: 'qb' (qb-vehiclekeys) または 'old' (vehiclekeys:client:SetOwner)
    UseVehicleProperties = false, -- qb-coreでSetVehiclePropertiesエクスポートが利用可能かどうか
    VehicleSpawnLocations = { -- 各拠点の車両スポーン位置（指定がない場合はSpawnOffsetが使用される）
        [1] = { -- 拠点のインデックス
            coords = vector3(87.54, 108.92, 80.17), -- 実際のスポーン座標
            heading = 159.02 -- 車両の向き
        },
        [2] = {
            coords = vector3(932.64, -1560.02, 30.38),
            heading = 172.53
        }
    }
}

-- 配達の難易度設定
Config.Difficulty = {
    Easy = {
        Multiplier = 1.0,   -- 報酬倍率
        TimeLimit = 900,    -- 制限時間（秒）
        PackageWeight = 1   -- パッケージの重さ（kg）
    },
    Medium = {
        Multiplier = 1.5,   -- 報酬倍率
        TimeLimit = 720,    -- 制限時間（秒）
        PackageWeight = 3   -- パッケージの重さ（kg）
    },
    Hard = {
        Multiplier = 2.0,   -- 報酬倍率
        TimeLimit = 600,    -- 制限時間（秒）
        PackageWeight = 5   -- パッケージの重さ（kg）
    }
}

-- 配達拠点の設定
Config.DeliveryDepots = {
    {
        name = "郵便局",
        coords = vector3(78.91, 112.61, 81.17),
        heading = 71.0,
        vehicleSpawn = {  -- 車両スポーン位置の追加
            coords = vector3(81.79, 106.23, 79.2),  -- 車両のスポーン座標
            heading = 62.62  -- 車両の向き
        },
        blip = {
            sprite = 478,
            color = 5,
            scale = 0.7,
            label = "配達拠点: 郵便局"
        }
    },
    {
        name = "物流センター",
        coords = vector3(926.65, -1560.19, 30.74),
        heading = 92.42,
        vehicleSpawn = {  -- 車両スポーン位置の追加
            coords = vector3(931.07, -1556.84, 30.01),  -- 車両のスポーン座標
            heading = 139.17  -- 車両の向き
        },
        blip = {
            sprite = 478,
            color = 5,
            scale = 0.7,
            label = "配達拠点: 物流センター"
        }
    }
}

-- 配達先の設定
Config.DeliveryLocations = {
    -- ロスサントス - 北部
    {coords = vector3(-773.5, 5938.34, 23.11), heading = 107.73},
    {coords = vector3(-188.85, 6409.68, 32.3), heading = 223.41},
    
    -- ロスサントス - 中心部
    {coords = vector3(-580.45, 491.6, 108.9), heading = 194.23},
    {coords = vector3(-386.73, 504.12, 120.41), heading = 151.82},
    {coords = vector3(269.64, -1712.85, 29.67), heading = 321.26},
    {coords = vector3(128.29, -1897.01, 23.67), heading = 243.09},
    {coords = vector3(94.94, -1809.9, 27.08), heading = 62.97},
    {coords = vector3(1915.78, 3909.23, 33.44), heading = 61.84},
}

-- パッケージタイプの設定
Config.PackageTypes = {
    ['small'] = {
        label = '小型パッケージ',
        weight = 1,
        model = 'prop_cs_cardbox_01',
        animation = {
            dict = 'anim@heists@box_carry@',
            anim = 'idle'
        }
    },
    ['medium'] = {
        label = '中型パッケージ',
        weight = 3,
        model = 'prop_cardbordbox_04a',
        animation = {
            dict = 'anim@heists@box_carry@',
            anim = 'idle'
        }
    },
    ['large'] = {
        label = '大型パッケージ',
        weight = 5,
        model = 'prop_box_wood05a',
        animation = {
            dict = 'anim@heists@box_carry@',
            anim = 'idle'
        }
    }
}