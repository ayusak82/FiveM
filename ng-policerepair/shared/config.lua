Config = {}

Config.Debug = false -- デバッグモード（true: 有効, false: 無効）

-- 修理設定
Config.RepairCost = 1000000 -- 修理費用（500,000円）
Config.AdminAccount = 'admin' -- 送金先のjobアカウント名（例：government, city, admin等）

-- 修理可能な職業
Config.AllowedJobs = {
    'police' -- ポリスのみ許可
}

-- 修理ポイントの設定
Config.RepairPoints = {
    {
        coords = vector3(463.4, -1019.37, 27.53), -- MRPD駐車場（例）
        radius = 2.0, -- サークルの半径
        label = '車両修理' -- ポイントのラベル
    },
    -- 必要に応じて他の場所も追加可能
    -- {
    --     coords = vector3(x, y, z),
    --     radius = 3.0,
    --     label = 'Police Vehicle Repair 2'
    -- }
}

-- UI設定
Config.Notifications = {
    success = '車両の修理が完了しました！',
    noVehicle = '修理する車両が見つかりません',
    noMoney = '警察の口座残高が不足しています（必要額: $%s）',
    noJob = 'この機能はポリス職員のみ使用できます',
    paymentSuccess = '$%sが警察口座から%sアカウントに送金されました'
}

-- キー設定
Config.InteractKey = 'E' -- インタラクトキー