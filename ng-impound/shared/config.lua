Config = {}

-- コマンド設定
Config.Command = {
    name = 'imd',                    -- コマンド名
    description = '目の前の車両をガレージに格納',
    adminOnly = false,               -- 管理者のみか（falseで全員使用可能）
    jobRestricted = true,            -- 職業制限するか
    allowedJobs = {                  -- 許可する職業（jobRestrictedがtrueの場合）
        'police'
    },
    impounded = {
        title = '車両インパウンド',
        description = '車両をインパウンドしました',
        type = 'inform',
        duration = 3000
    }
}

-- 車両検索設定
Config.Vehicle = {
    searchRadius = 10.0,             -- 車両検索半径（メートル）
    requirePlayerVehicle = false,    -- プレイヤーが所有する車両のみか（警察は他人の車も可能）
    allowOccupied = false,           -- 乗車中の車両も対象にするか
    excludeEmergency = false         -- 緊急車両を除外するか（警察車両もインパウンド可能）
}

-- 通知設定
Config.Notifications = {
    success = {
        title = '車両格納完了',
        description = '車両をガレージに格納しました',
        type = 'success',
        duration = 3000
    },
    noVehicle = {
        title = 'エラー',
        description = '近くに車両が見つかりません',
        type = 'error',
        duration = 3000
    },
    notOwner = {
        title = 'エラー',
        description = 'この車両はインパウンドできません',
        type = 'error',
        duration = 3000
    },
    occupied = {
        title = 'エラー',
        description = '車両に人が乗っています',
        type = 'error',
        duration = 3000
    },
    noPermission = {
        title = 'エラー',
        description = 'このコマンドを使用する権限がありません',
        type = 'error',
        duration = 3000
    },
    emergencyVehicle = {
        title = 'エラー',
        description = '緊急車両は格納できません',
        type = 'error',
        duration = 3000
    }
}

-- デバッグ設定
Config.Debug = false                 -- デバッグモード