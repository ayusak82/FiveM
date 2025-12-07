Config = {}

-- デバッグモード
Config.Debug = true

-- コマンド設定
Config.Command = 'dbstress' -- メニューを開くコマンド

-- テスト設定のデフォルト値
Config.DefaultSettings = {
    iterations = 100, -- デフォルト実行回数
    interval = 0, -- デフォルト実行間隔(ミリ秒) 0=間隔なし
    threads = 1 -- デフォルト同時実行数
}

-- テスト実行回数の選択肢
Config.IterationOptions = {
    { label = '10回', value = 10 },
    { label = '100回', value = 100 },
    { label = '1000回', value = 1000 },
    { label = '10000回', value = 10000 },
    { label = 'カスタム', value = 'custom' }
}

-- 実行間隔の選択肢
Config.IntervalOptions = {
    { label = '間隔なし', value = 0 },
    { label = '0.1秒', value = 100 },
    { label = '0.5秒', value = 500 },
    { label = '1秒', value = 1000 },
    { label = 'カスタム', value = 'custom' }
}

-- 同時実行数の選択肢
Config.ThreadOptions = {
    { label = '1スレッド', value = 1 },
    { label = '5スレッド', value = 5 },
    { label = '10スレッド', value = 10 },
    { label = '50スレッド', value = 50 },
    { label = '100スレッド', value = 100 },
    { label = 'カスタム', value = 'custom' }
}

-- テストの種類
Config.TestTypes = {
    {
        id = 'insert',
        label = '📝 連続INSERT テスト',
        description = '大量のデータを連続挿入します'
    },
    {
        id = 'select',
        label = '🔍 連続SELECT テスト',
        description = '大量のデータを連続取得します'
    },
    {
        id = 'update',
        label = '✏️ 連続UPDATE テスト',
        description = '既存データを連続更新します'
    },
    {
        id = 'delete',
        label = '🗑️ 連続DELETE テスト',
        description = 'データを連続削除します'
    },
    {
        id = 'join',
        label = '🔗 複雑なJOIN クエリテスト',
        description = '重いJOINクエリを実行します'
    },
    {
        id = 'transaction',
        label = '💳 トランザクション負荷テスト',
        description = '大量のトランザクション処理を実行します'
    },
    {
        id = 'concurrent',
        label = '⚡ 同時接続テスト',
        description = '複数の同時クエリを実行します'
    },
    {
        id = 'all',
        label = '🎯 全テスト実行',
        description = '上記すべてのテストを順番に実行します'
    }
}

-- 通知設定
Config.Notifications = {
    testStarted = {
        title = 'DBストレステスト',
        description = 'テストを開始しました',
        type = 'info'
    },
    testCompleted = {
        title = 'DBストレステスト',
        description = 'テストが完了しました',
        type = 'success'
    },
    testStopped = {
        title = 'DBストレステスト',
        description = 'テストを停止しました',
        type = 'warning'
    },
    testError = {
        title = 'DBストレステスト',
        description = 'エラーが発生しました',
        type = 'error'
    },
    noPermission = {
        title = 'エラー',
        description = '管理者権限が必要です',
        type = 'error'
    }
}

-- データベーステーブル名
Config.Tables = {
    test = 'ng_dbstress_test',
    logs = 'ng_dbstress_logs',
    results = 'ng_dbstress_results'
}

-- テストデータ生成設定
Config.TestData = {
    stringLength = 100, -- ランダム文字列の長さ
    jsonDepth = 3, -- JSONデータの深さ
    maxBlobSize = 1024 * 10 -- BLOB最大サイズ(10KB)
}
