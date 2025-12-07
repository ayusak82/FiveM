Config = {}

-- Discord Webhook設定
Config.DiscordWebhook = "YOUR_DISCORD_WEBHOOK_URL_HERE"

-- コマンド設定
Config.Command = "veexp"

-- メッセージ設定
Config.Messages = {
    -- エラーメッセージ
    not_in_vehicle = "車両に乗車している必要があります",
    already_used = "あなたは既にこのコマンドを使用済みです",
    export_failed = "車両データのエクスポートに失敗しました",
    
    -- 成功メッセージ
    export_success = "車両データが正常にエクスポートされました",
    
    -- 確認メッセージ
    confirm_title = "車両エクスポート確認",
    confirm_description = "この車両をエクスポートしますか？\n\n車両: %s\nプレート: %s\n\n※この操作は一度のみ実行可能です",
    confirm_button = "エクスポート",
    cancel_button = "キャンセル"
}

-- データベーステーブル名
Config.TableName = "vehicle_transfers"

-- Discord Embed設定
Config.DiscordEmbed = {
    title = "🚗 車両エクスポート",
    color = 3447003, -- 青色
    footer = {
        text = "Vehicle Transfer System",
        icon_url = ""
    }
}