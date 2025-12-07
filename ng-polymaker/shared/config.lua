Config = {}

-- コマンド名の設定
Config.Command = {
    name = 'polymaker',  -- コマンド名
    description = 'PolyZone作成ツール', -- コマンドの説明
}

-- キー設定
Config.Keys = {
    addPoint = 'E',      -- ポイント追加
    removePoint = 'X',   -- 最後のポイント削除
    finish = 'ENTER',    -- 完了
    cancel = 'ESC',      -- キャンセル
}

-- 表示テキスト設定
Config.Text = {
    addPoint = '[E] ポイントを追加',
    removePoint = '[X] 前のポイントを削除',
    finish = '[ENTER] 完了',
    cancel = '[ESC] キャンセル',
    copied = 'ポイントをクリップボードにコピーしました',
    cancelled = 'ポイント設定をキャンセルしました',
    noPoints = 'ポイントが設定されていません'
}