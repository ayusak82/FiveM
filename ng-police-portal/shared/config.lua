Config = {}

-- 基本設定
Config.Framework = 'qb-core' -- フレームワーク
Config.UseESX = false -- ESXを使用する場合true
Config.Debug = false -- デバッグモード

-- 権限設定
Config.PoliceJobs = {
    'police',
    'ambulance', 
}

-- マーカー設定
Config.Marker = {
    Type = 1, -- マーカータイプ (1 = 円柱, 2 = 矢印など)
    Size = vector3(2.0, 2.0, 1.0), -- マーカーサイズ
    Color = {r = 0, g = 100, b = 255, a = 100}, -- 青色半透明
    BobUpAndDown = false, -- 上下に動く
    FaceCamera = false,
    Rotate = true,
    DrawDistance = 50.0, -- 描画距離
    InteractDistance = 2.5 -- インタラクト距離
}

-- テキスト表示設定
Config.Text3D = {
    Color = {r = 255, g = 255, b = 255, a = 255}, -- 白色
    Font = 0,
    Scale = 0.35,
    DrawDistance = 10.0
}

-- 通知設定
Config.Notifications = {
    NoPermission = '警察のみが使用できます',
    TeleportSuccess = 'テレポートしました',
    TeleportFailed = 'テレポートに失敗しました',
    SelectDestination = '目的地を選択してください'
}

-- テレポートポータル設定
Config.Portals = {
    {
        id = 1,
        name = "本署",
        description = "本署",
        coords = vector3(441.09, -997.72, 34.97), -- ポータル位置
        destinations = {
            {
                name = "北署",
                coords = vector4(-435.08, 6007.22, 37.0, 131.38),
                description = "北署"
            },
            {
                name = "砂漠署",
                coords = vector4(1830.57, 3680.49, 38.86, 121.72),
                description = "砂漠署"
            },
        }
    },
    {
        id = 2,
        name = "北署",
        description = "北署",
        coords = vector3(-435.08, 6007.22, 37.0), -- ポータル位置
        destinations = {
            {
                name = "本署",
                coords = vector4(441.09, -997.72, 34.97, 131.38),
                description = "本署"
            },
            {
                name = "砂漠署",
                coords = vector4(1830.57, 3680.49, 38.86, 121.72),
                description = "砂漠署"
            },
        }
    },
    {
        id = 3,
        name = "砂漠署",
        description = "砂漠署",
        coords = vector3(1830.57, 3680.49, 38.86), -- ポータル位置
        destinations = {
            {
                name = "本署",
                coords = vector4(441.09, -997.72, 34.97, 131.38),
                description = "本署"
            },
            {
                name = "北署",
                coords = vector4(-435.08, 6007.22, 37.0, 131.38),
                description = "北署"
            },
        }
    },
    {
        id = 4,
        name = "中央病院",
        description = "中央病院",
        coords = vector3(327.06, -602.93, 43.28), -- ポータル位置
        destinations = {
            {
                name = "北病院",
                coords = vector4(-250.59, 6315.33, 32.43, 41.25),
                description = "北病院"
            },
            {
                name = "砂漠院",
                coords = vector3(1814.94, 3679.19, 33.97),
                description = "砂漠院"
            },
        }
    },
    {
        id = 5,
        name = "北病院",
        description = "北病院",
        coords = vector3(-250.59, 6315.33, 32.43), -- ポータル位置
        destinations = {
            {
                name = "中央病院",
                coords = vector4(327.06, -602.93, 43.28, 338.18),
                description = "中央病院"
            },
            {
                name = "砂漠院",
                coords = vector3(1814.94, 3679.19, 33.97),
                description = "砂漠院"
            },
        }
    },
        {
        id = 6,
        name = "EMS用砂漠院",
        description = "砂漠院",
        coords = vector3(1814.94, 3679.19, 33.97), -- ポータル位置
        destinations = {
            {
                name = "中央病院",
                coords = vector4(327.06, -602.93, 43.28, 338.18),
                description = "中央病院"
            },
            {
                name = "北病院",
                coords = vector4(-250.59, 6315.33, 32.43, 41.25),
                description = "北病院"
            },
        }
    },
}
-- キー設定
Config.Keys = {
    Interact = 'E' -- インタラクトキー
}