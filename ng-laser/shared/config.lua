Config = {}

-- レーザー設定
Config.Laser = {
    -- レーザーの色 (R, G, B, A)
    color = {255, 0, 0, 255}, -- 赤色
    
    -- レーザーの太さ
    width = 0.02,
    
    -- レーザーの最大距離
    maxDistance = 100.0,
    
    -- レーザーの更新頻度（ミリ秒）
    updateInterval = 0,
    
    -- レーザーを表示するコマンド
    toggleCommand = 'laser',
    
    -- 座標をコピーするキー（レーザー表示中のみ）
    copyKey = 'E'
}

-- 権限設定
Config.Permission = {
    -- 使用可能なジョブ（空の場合は全員使用可能）
    allowedJobs = {}, -- 例: {'police', 'mechanic'}
    
    -- 使用可能なグレード（最小グレード）
    minGrade = 0,
    
    -- 管理者のみ使用可能かどうか
    adminOnly = false
}

-- UI設定
Config.UI = {
    -- 通知の表示時間（ミリ秒）
    notificationDuration = 3000,
    
    -- 座標表示の小数点桁数
    coordinateDecimals = 2,
    
    -- レーザー状態を表示するUI位置
    statusPosition = 'top-right'
}

-- デバッグ設定
Config.Debug = false