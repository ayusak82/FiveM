Config = {}

-- 速度制限設定 (km/h)
Config.SpeedLimit = {
    Normal = 200,      -- 一般車両の速度制限
    Emergency = 250    -- 緊急車両の速度制限
}

-- 緊急車両のクラス
Config.EmergencyVehicleClasses = {
    [18] = true  -- Emergency vehicles
}

-- 速度制限対象外の車両クラス
Config.ExemptVehicleClasses = {
    [14] = true,  -- Boats (ボート)
    [15] = true,  -- Helicopters (ヘリコプター)
    [16] = true   -- Planes (飛行機)
}

-- 通知設定
Config.Notification = {
    Enabled = true,           -- 通知を有効にするか
    Duration = 5000,          -- 通知の表示時間(ミリ秒)
    Position = 'top-right'    -- 通知の表示位置
}

-- デバッグモード
Config.Debug = false
