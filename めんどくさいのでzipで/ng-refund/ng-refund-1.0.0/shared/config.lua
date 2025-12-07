Config = {}

-- 管理者権限の設定
Config.RequiredAceGroup = "command.admin"

-- UIの設定
Config.UI = {
    position = 'right-center',
    header = {
        title = '補填管理システム',
        icon = 'boxes-stacked'
    }
}

-- メニューアイテムの設定
Config.MenuItems = {
    {
        label = 'アイテム補填',
        description = '指定したプレイヤーにアイテムを補填します',
        icon = 'box'
    },
    {
        label = '車両補填',
        description = '指定したプレイヤーに車両を補填します',
        icon = 'car'
    },
    {
        label = '補填履歴確認',
        description = '補填履歴を確認・管理します',
        icon = 'history'
    }
}

-- 検索設定
Config.Search = {
    -- プレイヤー検索の最大件数
    maxPlayerResults = 20,
    -- アイテム検索の最大件数
    maxItemResults = 50,
    -- 車両検索の最大件数
    maxVehicleResults = 30,
    -- 検索時の最小文字数
    minSearchLength = 1
}

-- 通知メッセージの設定
Config.Notifications = {
    success = {
        title = '補填完了',
        description = '%s に %s を補填しました',
        type = 'success',
        position = 'top',
        duration = 5000
    },
    error = {
        title = 'エラー',
        description = '補填に失敗しました: %s',
        type = 'error',
        position = 'top',
        duration = 5000
    },
    noPermission = {
        title = '権限エラー',
        description = 'この操作を実行する権限がありません',
        type = 'error',
        position = 'top',
        duration = 5000
    },
    received = {
        title = '補填受取通知',
        description = '管理者から %s を受け取りました',
        type = 'info',
        position = 'top',
        duration = 5000
    },
    deleted = {
        title = '補填削除完了',
        description = '指定された補填を削除しました',
        type = 'success',
        position = 'top',
        duration = 5000
    },
    confirmReceived = {
        title = '補填受取確認',
        description = '補填されたアイテム/車両を受け取りましたか？',
        type = 'info',
        position = 'top',
        duration = 10000
    },
    searchNoResults = {
        title = '検索結果なし',
        description = '指定された条件に一致する結果が見つかりませんでした',
        type = 'info',
        position = 'top',
        duration = 3000
    },
    itemNotFound = {
        title = 'アイテムエラー',
        description = '指定されたアイテムが存在しません',
        type = 'error',
        position = 'top',
        duration = 5000
    }
}

-- 補填履歴の設定
Config.History = {
    maxDisplayCount = 50,  -- 表示する履歴の最大数
    deletePermission = {   -- 削除権限を持つグループ
        ['admin'] = true,
        ['god'] = true,
        ['superadmin'] = true
    },
    retentionDays = 30    -- 履歴を保持する日数
}