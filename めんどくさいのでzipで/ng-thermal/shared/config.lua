Config = {}

-- アイテム使用時のの効果持続時間（秒）
Config.EffectDuration = 30 -- 5分

-- 使用するアイテムの名前
Config.ItemName = 'thermal_blocker'

-- 使用時に表示されるエモート辞書と名前
Config.EmoteDictionary = 'mp_suicide'
Config.EmoteName = 'pill'

-- 使用時の通知設定
Config.Notifications = {
    ItemUsed = {
        title = 'アイテム使用',
        description = 'サーマル遮断薬を服用しました。効果は%s秒間続きます。',
        type = 'success'
    },
    ItemExpired = {
        title = 'アイテム効果終了',
        description = 'サーマル遮断薬の効果が切れました。',
        type = 'warning'
    }
}

-- 管理者用コマンド設定
Config.AdminCommand = 'thermal_test'

-- アイテム使用可能なジョブ（空の場合は全てのジョブで使用可能）
Config.RestrictedJobs = {}

-- デバッグモード
Config.Debug = false

-- デフォルトのサーマル設定（リセット用）
Config.DefaultThermalSettings = {
    MaxThickness = 10.0,
    FadeStart = 100.0,
    FadeEnd = 500.0
}