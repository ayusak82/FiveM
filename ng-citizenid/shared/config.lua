Config = {}

-- コマンド設定
Config.Command = {
    name = 'copyid', -- コマンド名
    description = 'CitizenIDをクリップボードにコピー' -- コマンドの説明
}

-- 通知設定
Config.Notification = {
    title = 'システム', -- 通知のタイトル
    description = 'CitizenIDをクリップボードにコピーしました', -- 通知の説明
    type = 'success', -- 通知の種類 (success, error, inform)
    position = 'top', -- 通知の位置
    duration = 3000 -- 通知の表示時間（ミリ秒）
}