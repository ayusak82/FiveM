Config = {}

-- コマンド設定
Config.Commands = {
    AdminMenu = 'giftadmin',  -- 管理者メニューを開くコマンド
    UseCode = 'giftcode',     -- ギフトコードを使用するコマンド
}

-- Discord Webhook設定
Config.Webhook = {
    Enable = false,  -- Webhook機能を有効化
    URL = 'YOUR_DISCORD_WEBHOOK_URL_HERE',  -- DiscordのWebhook URLをここに入力
    BotName = 'ng-giftcode',
    BotAvatar = 'https://gazou1.dlup.by/uploads/d906d125.png',
    Color = 3447003,  -- 埋め込みの色(青色)
}

-- 通知設定
Config.Notifications = {
    Type = 'ox_lib',  -- 'ox_lib' または 'qbcore'
    Position = 'top-right',  -- ox_libの通知位置
    Duration = 5000,  -- 通知表示時間(ミリ秒)
}

-- コード生成設定
Config.CodeGeneration = {
    DefaultLength = 12,  -- デフォルトのコード文字数
    AllowedCharacters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789',  -- 使用可能な文字
    Prefix = 'GIFT-',  -- コードの接頭辞(空文字列で無効化)
}

-- 報酬タイプ設定
Config.RewardTypes = {
    Money = {
        cash = true,   -- 現金を有効化
        bank = true,   -- 銀行を有効化
        crypto = false, -- 暗号通貨を有効化(qb-cryptoが必要)
    },
    Items = true,  -- アイテム報酬を有効化
    Vehicle = true,  -- 車両報酬を有効化
}

-- 車両スポーン設定
Config.VehicleSpawn = {
    SpawnInGarage = true,  -- trueの場合ガレージに追加、falseの場合その場にスポーン
    DefaultPlate = 'GIFT',  -- デフォルトのプレート(ランダム生成される)
}

-- 使用制限設定
Config.Restrictions = {
    EnableOnePerPlayer = true,  -- 1人1回制限機能を有効化
    EnableIdentifierWhitelist = true,  -- 特定プレイヤー制限機能を有効化
}

-- 統計設定
Config.Statistics = {
    Enable = true,  -- 統計機能を有効化
    ShowInMenu = true,  -- 管理メニューに統計を表示
}

-- メッセージ設定
Config.Messages = {
    -- 成功メッセージ
    Success = {
        CodeCreated = 'ギフトコードを作成しました: %s',
        CodeUsed = 'ギフトコードを使用しました！',
        CodeDisabled = 'ギフトコードを無効化しました',
        CodeEdited = 'ギフトコードを編集しました',
        RewardReceived = '報酬を受け取りました！',
    },
    
    -- エラーメッセージ
    Error = {
        NoPermission = '権限がありません',
        InvalidCode = '無効なギフトコードです',
        ExpiredCode = 'このコードは期限切れです',
        MaxUsesReached = 'このコードは使用回数の上限に達しています',
        AlreadyUsed = 'このコードは既に使用済みです',
        NotAllowed = 'このコードを使用する権限がありません',
        InactiveCode = 'このコードは無効化されています',
        InventoryFull = 'インベントリに空きがありません',
        InvalidInput = '入力内容が正しくありません',
        DatabaseError = 'データベースエラーが発生しました',
    },
    
    -- 情報メッセージ
    Info = {
        CodeGenerated = 'コードを生成しました',
        SelectRewardType = '報酬タイプを選択してください',
        EnterAmount = '数量を入力してください',
        EnterExpireDate = '有効期限を入力してください(日数)',
    }
}

-- デバッグ設定
Config.Debug = false  -- trueにするとコンソールにデバッグ情報を出力
