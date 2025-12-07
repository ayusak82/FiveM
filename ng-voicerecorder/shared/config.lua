Config = {}

-- ========================
-- 音声録音設定
-- ========================

-- 録音時間（秒）
Config.RecordingTime = 10

-- 音声再生範囲（メートル）
Config.PlaybackRange = 10.0

-- 音声ファイル保存期間（日）
Config.FileRetentionDays = 30

-- 音声品質設定 (low, medium, high)
Config.AudioQuality = "medium"

-- ========================
-- アイテム設定
-- ========================

-- アイテム名
Config.Items = {
    VoiceRecorder = "voice_recorder",
    EmptyTape = "empty_tape",
    RecordedTape = "recorded_tape"
}

-- アイテム使用可能かのチェック間隔（ミリ秒）
Config.ItemCheckInterval = 500

-- ========================
-- UI設定
-- ========================

-- 録音UI表示時間（ミリ秒）
Config.RecordingUITimeout = Config.RecordingTime * 1000 + 2000

-- 通知表示時間（ミリ秒）
Config.NotificationDuration = 5000

-- ========================
-- サーバー設定
-- ========================

-- 録音ファイル保存フォルダ（相対パス、サーバー側で絶対パスに変換）
Config.RecordingsFolder = "recordings"

-- 最大同時録音数
Config.MaxConcurrentRecordings = 10

-- ファイル自動削除の実行間隔（時間）
Config.CleanupInterval = 24

-- ========================
-- デバッグ設定
-- ========================

-- デバッグモード（本番環境では false に設定）
Config.Debug = false

-- デバッグログの詳細度 (1-3)
Config.DebugLevel = 1

-- デバッグコマンド有効化（本番環境では false に設定）
Config.EnableDebugCommands = false

-- デバッグコマンド名
Config.DebugCommands = {
    TestRecorder = "testrecorder",     -- /testrecorder でボイスレコーダーテスト
    GiveItems = "givevoiceitems",      -- /givevoiceitems でアイテム付与
    ClearRecordings = "clearrec"       -- /clearrec で録音ファイル削除
}


-- ========================
-- メニュー設定
-- ========================

-- メニューのテキスト
Config.MenuTexts = {
    MainTitle = "ボイスレコーダー",
    RecordOption = "音声を録音する",
    PlayOption = "音声を再生する",
    SelectTapeTitle = "テープを選択",
    NameTapeTitle = "テープ名を入力",
    NameTapePlaceholder = "テープの名前を入力してください...",
    ConfirmButton = "確定",
    CancelButton = "キャンセル"
}

-- 通知メッセージ
Config.Notifications = {
    NoVoiceRecorder = "ボイスレコーダーを持っていません",
    NoEmptyTape = "空のテープを持っていません", 
    NoRecordedTape = "録音済みテープを持っていません",
    RecordingStarted = "録音を開始しました",
    RecordingCompleted = "録音が完了しました",
    PlayingAudio = "音声を再生中です",
    RecordingFailed = "録音に失敗しました",
    PlaybackFailed = "再生に失敗しました",
    InvalidTapeName = "無効なテープ名です"
}