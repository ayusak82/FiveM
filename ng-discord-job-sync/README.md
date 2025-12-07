# ng-discord-job-sync

FiveMのジョブシステムとDiscordロールを自動同期するスクリプトです。`ng_multijobs`テーブルからジョブ情報を取得し、対応するDiscordロールを自動的に付与・削除します。

## 作者情報
- **作者**: NCCGr
- **問い合わせ先**: Discord: ayusak

## 機能
- `ng_multijobs`テーブルからジョブ情報を自動取得
- **複数ジョブ対応**: 1人のプレイヤーが複数のジョブを持っている場合、すべてのジョブに対応するロールを付与
- データベースベースでDiscordロールを自動付与・削除（オンライン状態に依存しない）
- 1分ごとの自動同期
- プレイヤー接続時の自動同期
- 手動同期コマンド
- デバッグモード搭載

## 依存関係
- **qb-core**: FiveMフレームワーク
- **ox_lib**: UIライブラリ
- **oxmysql**: データベースライブラリ
- **Discord Bot**: Discord APIアクセス用

## インストール方法

### 1. スクリプトの配置
`ng-discord-job-sync`フォルダをサーバーの`resources`ディレクトリに配置します。

### 2. Discord Botの作成
1. [Discord Developer Portal](https://discord.com/developers/applications)にアクセス
2. 「New Application」をクリックして新しいアプリケーションを作成
3. 「Bot」タブに移動し、「Add Bot」をクリック
4. Bot Tokenをコピー（後で使用）
5. 「Privileged Gateway Intents」で以下を有効化：
   - SERVER MEMBERS INTENT
   - MESSAGE CONTENT INTENT
6. 「OAuth2」→「URL Generator」で以下を選択：
   - Scopes: `bot`
   - Bot Permissions: `Manage Roles`
7. 生成されたURLでBotをサーバーに招待

### 3. Discord Guild IDの取得
1. Discordの設定で「開発者モード」を有効化
2. サーバーを右クリックして「IDをコピー」

### 4. Discord Role IDの取得
1. サーバー設定→ロール
2. 各ロールを右クリックして「IDをコピー」

### 5. FiveMサーバーの設定
server.cfgに以下を追加して、Discord識別子を有効化：
```
set sv_enableDiscordLink true
```

### 6. 設定ファイルの編集
`shared/config.lua`を開き、以下を設定：

```lua
-- Discord Bot Token
Config.DiscordBotToken = 'YOUR_DISCORD_BOT_TOKEN_HERE'

-- Discord Guild ID
Config.GuildId = 'YOUR_DISCORD_GUILD_ID_HERE'

-- ジョブとロールのマッピング
Config.JobRoles = {
    ['police'] = '1234567890123456789',      -- 警察ロールID
    ['ambulance'] = '1234567890123456789',   -- 救急ロールID
    ['mechanic'] = '1234567890123456789',    -- メカニックロールID
    ['taxi'] = '1234567890123456789',        -- タクシーロールID
    ['unemployed'] = nil,                     -- 無職はロールなし
}
```

### 7. server.cfgに追加
```
ensure ng-discord-job-sync
```

### 8. サーバーの再起動
サーバーを再起動してスクリプトを読み込みます。

**注意**: スクリプトは起動時に自動的に`player_discord`テーブルを作成します。手動でSQLを実行する必要はありません。

## 使用方法

### 自動同期
- スクリプトは1分ごとに自動的に同期を実行します
- プレイヤーが接続すると自動的に同期されます
- ジョブが変更されると次の同期サイクルで反映されます
- 1人のプレイヤーが複数のジョブを持っている場合、すべてのジョブに対応するロールが付与されます

### 手動同期
管理者は以下のコマンドで手動同期を実行できます：
```
/syncjobroles
```

## データベーステーブル構造

このスクリプトは以下のテーブルを使用します：

### ng_multijobs テーブル
```sql
CREATE TABLE IF NOT EXISTS `ng_multijobs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `job` varchar(50) NOT NULL,
  `grade` int(11) NOT NULL DEFAULT 0,
  `is_duty` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

**複数ジョブの例**:
```sql
INSERT INTO `ng_multijobs` (`citizenid`, `job`, `grade`) VALUES
('ABC12345', 'police', 2),
('ABC12345', 'ambulance', 1),
('ABC12345', 'mechanic', 0);
```
この場合、citizenid `ABC12345` のプレイヤーには、警察、救急、メカニックの3つのロールが付与されます。

### player_discord テーブル
```sql
CREATE TABLE IF NOT EXISTS `player_discord` (
  `citizenid` varchar(50) NOT NULL,
  `discord_id` varchar(50) NOT NULL,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`citizenid`),
  UNIQUE KEY `discord_id` (`discord_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

このテーブルは、プレイヤーのcitizenidとDiscord IDを紐づけます。
プレイヤーが接続すると、識別子から自動的にDiscord IDが取得され、このテーブルに保存されます。

## 設定オプション

### Config.Debug
デバッグモードの有効/無効を切り替えます。
```lua
Config.Debug = true  -- デバッグメッセージを表示
Config.Debug = false -- 本番環境用
```

### Config.SyncInterval
同期間隔をミリ秒で設定します。
```lua
Config.SyncInterval = 60000  -- 1分（デフォルト）
Config.SyncInterval = 300000 -- 5分
```

### Config.MinGradeForRole
特定のグレード以上のみロールを付与したい場合に設定します。
```lua
Config.MinGradeForRole = {
    ['police'] = 2,  -- グレード2以上の警察官のみロール付与
}
```

## トラブルシューティング

### ロールが付与されない
1. Discord Botが正しく招待されているか確認
2. BotにManage Roles権限があるか確認
3. Botのロールがターゲットロールより上位にあるか確認
4. Discord IDが正しく取得できているか確認（デバッグモードで確認）
5. Config.JobRolesに正しいRole IDが設定されているか確認

### プレイヤーのDiscord IDが取得できない
1. server.cfgに`set sv_enableDiscordLink true`が設定されているか確認
2. プレイヤーがDiscordを起動してFiveMに接続しているか確認
3. `player_discord`テーブルにデータが保存されているか確認
4. デバッグモードで「Updated Discord mapping for X online players」の数値を確認
5. プレイヤーに一度再接続してもらう

### データベースエラー
1. `ng_multijobs`テーブルが存在するか確認
2. `player_discord`テーブルが自動作成されているか確認（起動ログを確認）
3. oxmysqlが正しくインストールされているか確認
4. データベース接続情報が正しいか確認
5. データベースユーザーにCREATE TABLE権限があるか確認

## デバッグモード

デバッグモードを有効にすると、詳細なログが出力されます：
```lua
Config.Debug = true
```

ログの種類：
- `[DEBUG]` - 一般的なデバッグ情報（黄色）
- `[SUCCESS]` - 成功メッセージ（緑色）
- `[ERROR]` - エラーメッセージ（赤色）
- `[WARNING]` - 警告メッセージ（紫色）

## 注意事項

1. **Discord Bot Token**: 絶対に公開しないでください
2. **ロールの階層**: BotのロールはターゲットロールよりDiscord上で上位に配置する必要があります
3. **API制限**: Discord APIには制限があるため、大量のプレイヤーがいる場合は同期間隔を調整してください
4. **権限**: Botには「Manage Roles」権限が必要です

## ライセンス

このスクリプトは販売用です。無断での再配布・改変は禁止されています。

## サポート

問題が発生した場合は、Discord: ayusak までお問い合わせください。