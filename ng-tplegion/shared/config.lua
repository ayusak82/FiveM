Config = {}

-- テレポート先座標設定
Config.TeleportLocation = {
    x = 164.88,
    y = -1008.26,
    z = 29.45,
    w = 143.91  -- 向き（heading）
}

-- コマンド設定
Config.Command = {
    name = 'tplegion',
    description = '緊急時テレポートコマンド',
    restricted = false  -- trueにすると管理者のみ使用可能
}

-- 権限設定（restrictedがtrueの場合）
Config.AdminGroups = {
    'god',
    'admin',
    'mod'
}

-- 通知設定
Config.Notifications = {
    success = '緊急テレポートが実行されました',
    noPermission = 'このコマンドを使用する権限がありません',
    cooldown = 'クールダウン中です。しばらくお待ちください',
    error = 'テレポート中にエラーが発生しました',
    reasonRequired = 'テレポート理由を入力してください'
}

-- クールダウン設定（秒）
Config.Cooldown = 30

-- データベーステーブル名
Config.DatabaseTable = 'ng_tplegion_logs'

-- ログ設定
Config.Logging = {
    console = true,  -- コンソールにログ出力
    database = true  -- データベースにログ保存
}

-- スクリーンショット設定（lb-upload-standalone使用）
Config.Screenshot = {
    enabled = true,                                    -- スクリーンショット機能の有効/無効
    uploadUrl = 'https://fivem1.ngntm.jp/upload/',     -- lb-upload-standaloneのアップロードURL
    field = 'file',                                    -- アップロードフィールド名
    headers = {
        -- API認証が必要な場合は設定
        ['Authorization'] = 'x6J48*mHZT&f'
    }
}

-- Discord Webhook設定
Config.Discord = {
    enabled = true,
    webhook = 'YOUR_DISCORD_WEBHOOK_URL_HERE',  -- ここにWebhook URLを設定
    botName = 'テレポートログ',
    color = 3447003,  -- 青色
    footer = 'ng-tplegion Emergency Teleport System'
}