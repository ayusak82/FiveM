Config = {}

-- デバッグモード（true = コマンドでON/OFF可能、false = アイテムのみ）
Config.DebugMode = false

-- サーマルビジョンを使用するアイテム名
Config.ThermalItem = 'thermal_goggles'

-- 通知設定
Config.Notifications = {
    enabled = {
        title = 'サーマルビジョン',
        description = 'サーマルビジョンを有効にしました',
        type = 'success',
        position = 'top'
    },
    disabled = {
        title = 'サーマルビジョン',
        description = 'サーマルビジョンを無効にしました',
        type = 'inform',
        position = 'top'
    },
    noItem = {
        title = 'エラー',
        description = 'サーマルゴーグルを持っていません',
        type = 'error',
        position = 'top'
    },
    debugEnabled = {
        title = 'デバッグ',
        description = 'デバッグモードでサーマルビジョンを有効にしました',
        type = 'success',
        position = 'top'
    },
    debugDisabled = {
        title = 'デバッグ',
        description = 'デバッグモードでサーマルビジョンを無効にしました',
        type = 'inform',
        position = 'top'
    }
}

-- サーマルビジョン設定
Config.ThermalSettings = {
    -- サーマルビジョンのネイティブ設定
    visionType = 4, -- 4 = サーマル（1 = ナイトビジョン、0 = 通常）
    
    -- 自動オフ設定（アイテムを持っていない場合）
    autoDisable = true
}