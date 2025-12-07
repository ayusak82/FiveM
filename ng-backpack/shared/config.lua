Config = {}

-- ストレージ設定
Config.Storage = {
    -- 小サイズバックパック
    backpack1 = {
        slots = 10,
        weight = 100000,
        label = '小型バックパック'
    },
    -- 中サイズバックパック
    backpack2 = {
        slots = 20,
        weight = 200000,
        label = '中型バックパック'
    },
    -- 大サイズバックパック
    backpack3 = {
        slots = 30,
        weight = 300000,
        label = '大型バックパック'
    },
    -- スーツケース
    suitcase = {
        slots = 50,
        weight = 500000,
        label = 'スーツケース'
    }
}

-- バッグ系アイテムのリスト（禁止処理用）
Config.BagItems = {
    'backpack1',
    'backpack2',
    'backpack3',
    'suitcase'
}

-- 通知メッセージ
Config.Strings = {
    action_incomplete = 'アクションが完了していません',
    bag_in_bag = 'バッグの中にバッグを入れることはできません！',
    enter_passcode = 'パスコードを入力してください',
    set_passcode = '新しいパスコードを設定してください',
    change_passcode = '新しいパスコードを変更してください',
    remove_passcode = 'パスコードを削除しますか？',
    passcode_set = 'パスコードが設定されました',
    passcode_changed = 'パスコードが変更されました',
    passcode_removed = 'パスコードが削除されました',
    wrong_passcode = 'パスコードが間違っています',
    passcode_4digits = 'パスコードは4桁の数字で入力してください',
    passcode_required = 'このスーツケースはロックされています',
}
