# ng-giftcode

FiveM用ギフトコードシステム - プレイヤーに報酬を配布できる包括的なギフトコード管理スクリプト

## 作者情報
- **作成者**: NCCGr
- **問い合わせ**: Discord: ayusak
- **バージョン**: 1.0.0

## 機能

### 🎁 コア機能
- ✅ ギフトコードの生成（カスタムコード・ランダム生成）
- ✅ 一括コード生成（最大100個まで同時生成）
- ✅ コードの有効化/無効化
- ✅ コードの編集機能
- ✅ コードの完全削除
- ✅ コード一覧表示
- ✅ 詳細な統計情報
- ✅ データベース自動セットアップ

### 💰 報酬タイプ
- **お金**: 現金/銀行/暗号通貨（QBCore対応）
- **アイテム**: 複数アイテムの同時配布
- **車両**: ガレージへの直接追加
- **複合報酬**: 上記の組み合わせ

### 🔒 使用制限機能
- 最大使用回数の設定
- 有効期限の設定（日数指定）
- 1人1回のみ使用制限
- 特定プレイヤーのみ使用可能設定

### 📊 管理機能
- リアルタイム統計表示
  - 総コード数
  - 有効/無効コード数
  - 期限切れコード数
  - 総使用回数
  - 今日/今週の使用回数
  - 最も使用されているコード
- 使用ログの表示
- Discord Webhook通知

## 必要な依存関係

```lua
- qb-core
- ox_lib
- oxmysql
- ox_inventory
```

## インストール方法

### 1. スクリプトのインストール
1. `ng-giftcode`フォルダを`resources`フォルダにコピー
2. `server.cfg`に以下を追加:

```cfg
ensure ng-giftcode
```

### 2. データベースのセットアップ
**データベースは自動的にセットアップされます！**

リソースを起動すると、必要なテーブルが自動的に作成されます。
手動でセットアップする必要はありません。

起動時のコンソールログで以下のメッセージを確認してください:
```
[ng-giftcode] データベースのセットアップを開始します...
[ng-giftcode] giftcodesテーブルのセットアップが完了しました
[ng-giftcode] giftcode_logsテーブルのセットアップが完了しました
[ng-giftcode] データベースのセットアップが完了しました！
```

### 3. 設定ファイルの編集
`shared/config.lua`を開いて以下を設定:

```lua
-- Discord Webhook設定
Config.Webhook = {
    Enable = true,
    URL = 'YOUR_WEBHOOK_URL_HERE',  -- ここにWebhook URLを入力
}
```

## 使用方法

### 管理者向け

#### コマンド
```
/giftadmin - 管理者メニューを開く
```

#### 管理者メニュー機能
1. **📝 コード生成**
   - カスタムコードまたはランダム生成
   - 報酬タイプの選択（お金/アイテム/車両/複合）
   - 最大使用回数の設定
   - 有効期限の設定
   - 1人1回制限の設定

2. **📦 一括コード生成**
   - 最大100個まで同時生成
   - 同じ設定で複数コード作成
   - 生成されたコードはクリップボードにコピー

3. **📋 コード一覧**
   - すべてのコードを表示
   - 各コードの詳細確認
   - コードの編集・削除
   - 使用ログの確認

4. **📊 統計**
   - リアルタイムの使用統計
   - コード使用率の確認
   - 人気コードの確認

### プレイヤー向け

#### コマンド
```
/giftcode [コード]        - ギフトコードを使用
/usegiftcode             - コード入力ダイアログを開く
```

#### 使用例
```
/giftcode SUMMER2024
/giftcode GIFT-ABC123XYZ456
```

## 設定オプション

### コマンド設定
```lua
Config.Commands = {
    AdminMenu = 'giftadmin',  -- 管理者メニューコマンド
    UseCode = 'giftcode',     -- コード使用コマンド
}
```

### Discord Webhook設定
```lua
Config.Webhook = {
    Enable = true,                              -- Webhook機能の有効化
    URL = '',                                   -- Webhook URL
    BotName = 'ギフトコードシステム',          -- Bot名
    BotAvatar = 'https://i.imgur.com/AfFp7pu.png',  -- Botアイコン
    Color = 3447003,                            -- 埋め込みカラー
}
```

### 通知設定
```lua
Config.Notifications = {
    Type = 'ox_lib',           -- 'ox_lib' または 'qbcore'
    Position = 'top-right',    -- ox_libの通知位置
    Duration = 5000,           -- 表示時間（ミリ秒）
}
```

### コード生成設定
```lua
Config.CodeGeneration = {
    DefaultLength = 12,                                  -- コード長
    AllowedCharacters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789',
    Prefix = 'GIFT-',                                   -- 接頭辞
}
```

### 報酬タイプ設定
```lua
Config.RewardTypes = {
    Money = {
        cash = true,    -- 現金
        bank = true,    -- 銀行
        crypto = false, -- 暗号通貨
    },
    Items = true,       -- アイテム
    Vehicle = true,     -- 車両
}
```

### 車両スポーン設定
```lua
Config.VehicleSpawn = {
    SpawnInGarage = true,      -- ガレージに追加
    DefaultPlate = 'GIFT',     -- デフォルトプレート
}
```

## Discord Webhook通知

以下のイベントでWebhook通知が送信されます:

- ✅ ギフトコード作成
- ✅ 一括ギフトコード作成
- 🎁 ギフトコード使用
- 📝 ギフトコード編集
- ❌/✅ ギフトコード無効化/有効化
- 🗑️ ギフトコード削除

### Webhook設定例
1. Discordサーバーの設定を開く
2. 統合 → ウェブフック → 新しいウェブフック
3. Webhook URLをコピー
4. `shared/config.lua`の`Config.Webhook.URL`に貼り付け

## 権限設定

管理者権限は以下のACE権限で管理されます:

```cfg
add_ace group.admin command.admin allow
```

または特定のプレイヤーに権限を付与:

```cfg
add_ace identifier.steam:110000xxxxxxxx command.admin allow
```

## ファイル構造

```
ng-giftcode/
├── fxmanifest.lua
├── shared/
│   └── config.lua
├── client/
│   └── main.lua
├── server/
│   ├── database.lua    -- 自動データベースセットアップ
│   └── main.lua
└── README.md
```

## トラブルシューティング

### データベーステーブルが作成されない
- oxmysqlが正常にインストールされているか確認
- データベース接続情報が正しいか確認
- コンソールログでエラーメッセージを確認
- サーバーを再起動してみる

### コードが使用できない
- コードが有効化されているか確認
- 有効期限が切れていないか確認
- 使用回数の上限に達していないか確認
- 1人1回制限で既に使用していないか確認

### 車両が受け取れない
- `player_vehicles`テーブルが存在するか確認
- 車両モデル名が正しいか確認
- ガレージシステムが正常に動作しているか確認

### アイテムが受け取れない
- ox_inventoryが正常に動作しているか確認
- アイテム名が正しいか確認
- インベントリに空きがあるか確認

### Webhook通知が届かない
- Webhook URLが正しく設定されているか確認
- `Config.Webhook.Enable`が`true`になっているか確認
- Discord側のWebhookが有効になっているか確認

## 使用例

### 新規プレイヤー歓迎パック
```lua
報酬タイプ: 複合
- お金: 銀行 $50,000
- アイテム: water x5, sandwich x5, phone x1
- 使用回数: 1回
- 有効期限: 30日
- 1人1回のみ: 有効
```

### イベント限定報酬
```lua
報酬タイプ: 車両
- 車両: adder
- 使用回数: 100回
- 有効期限: 7日
- 1人1回のみ: 有効
```

### VIP特典コード
```lua
報酬タイプ: お金
- お金: 現金 $100,000
- 使用回数: 1回
- 有効期限: 無期限
- 特定プレイヤーのみ: 有効
```

## 更新履歴

### Version 1.0.0
- 初回リリース
- コード生成・管理機能
- 一括コード生成機能
- Discord Webhook統合
- 統計機能
- 使用制限機能
- データベース自動セットアップ機能

## ライセンス

このスクリプトは販売用です。
無断での再配布、転売、改変販売を禁止します。

## サポート

問題や質問がある場合は、以下にお問い合わせください:
- **Discord**: ayusak

---

**© 2024 NCCGr - All Rights Reserved**
