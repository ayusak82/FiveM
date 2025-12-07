Config = {}

-- デバッグモード（本番環境ではfalseに設定）
Config.Debug = false

-- 同期間隔（ミリ秒）
Config.SyncInterval = 300000 -- 5分（レート制限対策）

-- Discord APIリクエスト間の待機時間（ミリ秒）
Config.RequestDelay = 250 -- 250ms

-- バッチ処理の設定
Config.BatchSize = 15 -- 15人ごとに処理
Config.BatchDelay = 1000 -- 1秒待機

-- Discord Bot設定
Config.DiscordBotToken = 'YOUR_DISCORD_BOT_TOKEN_HERE'
Config.GuildId = 'YOUR_GUILD_ID_HERE'

-- ジョブとDiscordロールのマッピング
-- job名 = Discord Role ID
Config.JobRoles = {
    ['police'] = 'YOUR_POLICE_ROLE_ID',      -- 警察ロールID
    ['ambulance'] = 'YOUR_AMBULANCE_ROLE_ID',   -- 救急ロールID
    ['mechanic'] = 'YOUR_MECHANIC_ROLE_ID',    -- メカニックロールID
    ['unemployed'] = nil,                     -- 無職はロールなし
    -- 必要に応じて追加
}

-- グレード別ロール(オプション)
-- 特定のグレード以上のみロールを付与したい場合に使用
Config.MinGradeForRole = {
    ['police'] = 0,      -- 警察は全グレード
    ['ambulance'] = 0,   -- 救急は全グレード
    ['mechanic'] = 0,    -- メカニックは全グレード
}

-- Discord識別子の取得方法
-- このスクリプトはplayersテーブルのcharinfoカラムからdiscordフィールドを取得します
-- 例: charinfo = {"discord": "123456789012345678", ...}