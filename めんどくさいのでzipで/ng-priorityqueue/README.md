# ng-priorityqueue

**Discord統合型優先キューシステム for FiveM**

## 🌟 概要

ng-priorityquueueは、FiveMサーバー向けの高機能な優先キューシステムです。Discordロールに基づいた優先度管理により、スムーズなサーバー接続体験を提供します。

## ✨ 主な機能

### 🎯 優先度管理
- **Discord連携**: Discordロールに基づく自動優先度設定
- **8段階の優先度**: 管理者からプラン1まで細かく設定可能
- **自動ソート**: 優先度と参加時間に基づく公平なキューシステム

### 🎮 ユーザー体験
- **リアルタイム表示**: 現在の順番、推定待機時間、サーバー状況を表示
- **美しいUI**: 日本語対応の直感的なインターフェース
- **詳細情報**: プレイヤー情報、優先度、接続状況を一目で確認

### 🔧 サーバー管理
- **自動接続管理**: 最大接続数に基づく自動制御
- **デバッグ機能**: 詳細なログ出力でトラブルシューティングをサポート
- **整合性チェック**: 定期的な接続状況確認で安定動作

## 📋 システム要件

- **FiveM Server**
- **qb-core**: QBCoreフレームワーク
- **ox_lib**: OXライブラリ
- **oxmysql**: MySQLライブラリ
- **Discord Bot**: サーバー管理用Botアカウント

## 🚀 インストール方法

### 1. ファイル配置
```bash
# サーバーのresourcesフォルダに配置
[server]/resources/ng-priorityqueue/
├── fxmanifest.lua
├── server/
│   └── main.lua
└── shared/
    └── config.lua
```

### 2. Discord Bot設定

#### Discord Developer Portalでの設定
1. [Discord Developer Portal](https://discord.com/developers/applications)にアクセス
2. 「New Application」をクリックしてアプリケーションを作成
3. 「Bot」タブに移動し、「Add Bot」をクリック
4. Botトークンをコピー（後で使用）
5. 「OAuth2」→「URL Generator」で以下を設定：
   - **Scopes**: `bot`
   - **Bot Permissions**: `Read Messages/View Channels`
6. 生成されたURLでBotをサーバーに招待

#### サーバーID取得方法
1. Discordで開発者モードを有効化
2. サーバー名を右クリック → 「IDをコピー」

### 3. 設定ファイル編集

`shared/config.lua`を編集してください：

```lua
-- Discord Bot設定
Config.DiscordBot = {
    Token = "YOUR_DISCORD_BOT_TOKEN_HERE", -- 取得したBotトークン
    GuildId = "YOUR_DISCORD_SERVER_ID_HERE", -- DiscordサーバーID
}
```

#### ロールID取得方法
1. Discordで開発者モードを有効化
2. 対象ロールを右クリック → 「IDをコピー」
3. config.luaの該当箇所に貼り付け

### 4. server.cfg設定

server.configに以下を追加：

```cfg
# ng-priorityqueue
ensure ng-priorityqueue
```

## ⚙️ 設定項目

### 基本設定
```lua
Config.MaxPlayers = 128 -- 最大接続数
Config.Debug = false -- デバッグログの有効/無効
Config.ConnectionInterval = 5000 -- 接続チェック間隔（ミリ秒）
```

### 優先度設定例
```lua
Config.Priority = {
    [1] = {
        roles = {"ROLE_ID_1", "ROLE_ID_2"}, -- 管理者ロールID
        priority = 100,
        name = "管理者"
    },
    [2] = {
        roles = {"ROLE_ID_3"}, -- VIPロールID
        priority = 80,
        name = "VIPメンバー"
    },
    -- 必要に応じて追加
}
```

## 🎛️ コマンド・機能

### 自動機能
- **接続時認証**: Discord連携による自動優先度判定
- **キュー管理**: 優先度に基づく自動ソート
- **接続制御**: 最大接続数に基づく自動調整
- **切断処理**: プレイヤー切断時の自動クリーンアップ

### 表示情報
- プレイヤー名・Discord ID
- 現在のキュー順番
- 優先度レベル・ロール名
- 推定待機時間
- サーバー接続状況

## 🔍 トラブルシューティング

### よくある問題

#### 1. Discord認証エラー
**症状**: 「Discordアカウントで接続してください」エラー
**解決方法**:
- Discordアプリケーションを起動
- FiveMクライアントを再起動
- Discordアカウントでログイン状態を確認

#### 2. 優先度が反映されない  
**症状**: 正しいロールを持っているのに優先度が低い
**解決方法**:
- config.luaのロールIDを確認
- Discord Botがサーバーにいるかチェック
- Botの権限を確認（メンバー情報の読み取り権限）

#### 3. キューが進まない
**症状**: 1位なのに接続できない
**解決方法**:
- サーバーの最大接続数を確認
- `Config.Debug = true`でデバッグログを確認
- サーバーコンソールでエラーログをチェック

### ログの確認方法

デバッグモードを有効にして詳細ログを確認：
```lua
Config.Debug = true
```

## 🔐 セキュリティ注意事項

- **Botトークン**: 絶対に公開しないでください
- **権限設定**: Botには最小限の権限のみ付与
- **定期更新**: Discord APIの変更に対応するため定期的にアップデート

## 📝 更新履歴

### v1.0.0
- 初回リリース
- Discord統合優先キューシステム
- 8段階優先度管理
- 日本語UI対応
- 自動接続制御
- デバッグ機能

## 🎫 サポート

### 技術サポート
- 設定に関する質問
- トラブルシューティング
- カスタマイズ相談

### 利用規約
- 商用利用可能
- 再配布禁止
- 改変時は元作者クレジット記載

## 👨‍💻 開発者情報

- **作者**: NCCGr
- **バージョン**: 1.0.0
- **対応FiveM**: 最新版
- **言語**: Lua (FiveM Natives)

---

**⚠️ 重要**: 設定完了後は必ずテストサーバーで動作確認を行ってから本番環境に導入してください。