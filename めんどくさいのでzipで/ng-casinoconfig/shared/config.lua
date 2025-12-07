Config = {}

-- カジノ設定のターゲット名
Config.TargetResourceName = 'rcore_casino'

-- 使用可能な設定プリセット
Config.Presets = {
    ['low'] = '低設定',
    ['medium'] = '中設定',
    ['high'] = '高設定'
}

-- 設定を変更できる権限を持つジョブ
Config.AuthorizedJobs = {
    ['casino'] = 3,  -- 現在ランク3以上が変更可能
}

-- ox_lib通知の設定
Config.Notify = {
    Success = {
        title = 'カジノ設定',
        description = '設定が正常に更新されました',  -- プリセット名を表示するフォーマット文字列に変更
        type = 'success'
    },
    Error = {
        title = 'カジノ設定',
        description = '設定の更新に失敗しました',
        type = 'error'
    },
    NoPermission = {
        title = 'カジノ設定',
        description = 'この操作を行う権限がありません',
        type = 'error'
    }
}

-- メニューの設定
Config.MenuSettings = {
    id = 'ng_casino_config_menu',
    title = 'カジノ設定',
    position = 'bottom-right',
    icon = 'fas fa-dice'
}