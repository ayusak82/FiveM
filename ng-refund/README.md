# ng-refund - 補填管理システム

FiveM QBCore向けの包括的な補填管理システムです。管理者がプレイヤーにアイテムや車両を補填し、プレイヤーが選択的に受け取ることができます。

## 📋 目次

- [機能](#-機能)
- [必要要件](#-必要要件)
- [インストール手順](#-インストール手順)
- [アップデート手順](#-アップデート手順)
- [使用方法](#-使用方法)
- [コマンド一覧](#-コマンド一覧)
- [設定](#-設定)
- [トラブルシューティング](#-トラブルシューティング)

---

## 🌟 機能

### 管理者機能
- ✅ **アイテム補填**: オンライン/オフラインプレイヤーにアイテムを補填
- ✅ **車両補填**: カスタムナンバープレート対応の車両補填
- ✅ **補填履歴管理**: 全ての補填履歴を確認
- ✅ **補填キャンセル**: 未受取の補填を削除可能
- ✅ **検索機能**: プレイヤー、アイテム、車両の高度な検索

### プレイヤー機能
- ✅ **選択的受け取り**: 未受取補填を個別に選択して受け取り
- ✅ **一括受け取り**: 全ての補填を一括で受け取り（従来機能）
- ✅ **詳細確認**: 補填内容と補填者を確認してから受け取り

### システム機能
- ✅ **ox_inventory 連携**: インベントリ容量チェック
- ✅ **論理削除**: データの完全性を保持
- ✅ **日本語完全対応**: UI・通知が全て日本語
- ✅ **タイムスタンプ管理**: 日本時間（JST）で表示

---

## 💻 必要要件

- **FiveM Server**: 最新版推奨
- **QBCore Framework**: 最新版
- **ox_lib**: 最新版
- **oxmysql**: 最新版
- **ox_inventory**: 最新版（アイテム管理用）

---

## 📥 インストール手順

### 1. ファイルの配置

```bash
# サーバーのリソースフォルダに解凍
cd /path/to/server/resources
unzip ng-refund.zip
```

### 2. データベースセットアップ

HeidiSQL、phpMyAdmin、または任意のSQLクライアントで以下のSQLを実行:

```sql
CREATE TABLE IF NOT EXISTS refund_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    admin_identifier VARCHAR(50) NOT NULL,
    admin_name VARCHAR(50) NOT NULL,
    target_identifier VARCHAR(50) NOT NULL,
    target_name VARCHAR(50) NOT NULL,
    type VARCHAR(10) NOT NULL,
    item_name VARCHAR(50),
    amount INT,
    vehicle_model VARCHAR(50),
    plate VARCHAR(8),
    claimed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    deleted_by VARCHAR(50)
);
```

### 3. server.cfg の設定

`server.cfg` にリソースを追加:

```cfg
ensure ox_lib
ensure oxmysql
ensure qb-core
ensure ox_inventory
ensure ng-refund
```

**重要**: `ng-refund` は必ず `qb-core`、`ox_lib`、`oxmysql`、`ox_inventory` の**後**に記載してください。

### 4. 権限設定

`server.cfg` に管理者権限を設定:

```cfg
# 管理者権限の付与例
add_ace group.admin command.admin allow
add_principal identifier.license:YOUR_LICENSE_HERE group.admin
```

### 5. サーバー起動

サーバーを再起動してリソースを読み込みます。

```bash
restart ng-refund
```

---

## 🔄 アップデート手順

既存の `ng-refund` からアップデートする場合:

### ステップ 1: バックアップ

```bash
# 現在のng-refundフォルダをバックアップ
cd /path/to/server/resources
cp -r ng-refund ng-refund_backup
```

### ステップ 2: データベースの更新

**重要**: 新バージョンでは `deleted_by` カラムが追加されています。

#### 方法A: GUIツール（HeidiSQL / phpMyAdmin）を使用

1. データベース管理ツールを開く
2. `refund_history` テーブルを選択
3. 以下のSQLを実行:

```sql
ALTER TABLE refund_history 
ADD COLUMN deleted_by VARCHAR(50) NULL DEFAULT NULL AFTER deleted_at;
```

#### 方法B: 自動移行スクリプト（推奨）

`server/main.lua` の冒頭部分を以下に置き換え:

```lua
-- データベーステーブルの作成
CreateThread(function()
    -- テーブル作成
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS refund_history (
            id INT AUTO_INCREMENT PRIMARY KEY,
            admin_identifier VARCHAR(50) NOT NULL,
            admin_name VARCHAR(50) NOT NULL,
            target_identifier VARCHAR(50) NOT NULL,
            target_name VARCHAR(50) NOT NULL,
            type VARCHAR(10) NOT NULL,
            item_name VARCHAR(50),
            amount INT,
            vehicle_model VARCHAR(50),
            plate VARCHAR(8),
            claimed BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            deleted_at TIMESTAMP NULL
        )
    ]])
    
    -- deleted_by カラムの追加（既に存在する場合はエラーを無視）
    local success, err = pcall(function()
        MySQL.query.await([[
            ALTER TABLE refund_history 
            ADD COLUMN deleted_by VARCHAR(50) NULL DEFAULT NULL AFTER deleted_at
        ]])
    end)
    
    if success then
        print('^2[ng-refund] deleted_by カラムを追加しました^0')
    else
        print('^3[ng-refund] deleted_by カラムは既に存在するか、追加に失敗しました^0')
    end
end)
```

### ステップ 3: ファイルの置き換え

```bash
# サーバーを停止
stop ng-refund

# 古いファイルを削除（バックアップ済み）
cd /path/to/server/resources
rm -rf ng-refund

# 新しいファイルを解凍
unzip ng-refund-modified.zip
mv ng-refund-modified ng-refund
```

### ステップ 4: 設定の確認

`shared/config.lua` をバックアップから必要に応じて設定を移行:

```bash
# 必要な設定を旧バックアップからコピー
# vim ng-refund/shared/config.lua
```

### ステップ 5: サーバー再起動

```bash
# サーバーを再起動
restart ng-refund

# またはサーバー全体を再起動
# restart
```

### ステップ 6: 動作確認

1. ゲームに接続
2. `/refund` コマンドで管理メニューが開くことを確認
3. `/myrefunds` コマンドで新機能が動作することを確認
4. 補填履歴で削除機能が表示されることを確認

---

## 📖 使用方法

### 管理者の使い方

#### アイテムを補填する

1. ゲーム内で `/refund` コマンドを実行
2. 「アイテム補填」を選択
3. プレイヤーを検索（CitizenID または 名前）
4. 補填するアイテムを検索
5. 個数を入力して確認

#### 車両を補填する

1. ゲーム内で `/refund` コマンドを実行
2. 「車両補填」を選択
3. プレイヤーを検索
4. 補填する車両を検索
5. ナンバープレートを入力（空欄で自動生成）
6. 確認して実行

#### 補填をキャンセルする

1. `/refund` コマンドを実行
2. 「補填履歴確認」を選択
3. **未受取** の補填を選択
4. 「補填をキャンセル」を選択
5. 確認して削除

### プレイヤーの使い方

#### 選択的に受け取る（新機能）

1. `/myrefunds` コマンドを実行
2. 未受取補填の一覧が表示される
3. 受け取りたい補填を選択
4. 内容を確認して「確認」
5. 個別に受け取り完了

#### 一括で受け取る（従来機能）

1. `/refunds` コマンドを実行
2. 全ての未受取補填が自動で付与される
3. 通知で受け取り結果を確認

---

## 🎮 コマンド一覧

| コマンド | 権限 | 説明 |
|---------|------|------|
| `/refund` | 管理者 | 補填管理メニューを開く |
| `/myrefunds` | プレイヤー | 未受取補填を選択的に受け取る |
| `/refunds` | プレイヤー | 全ての未受取補填を一括受け取り |

---

## ⚙️ 設定

`shared/config.lua` で以下の設定が可能です:

### 権限設定

```lua
Config.RequiredAceGroup = "command.admin"  -- 管理者権限
```

### 検索設定

```lua
Config.Search = {
    maxPlayerResults = 20,   -- プレイヤー検索の最大件数
    maxItemResults = 50,     -- アイテム検索の最大件数
    maxVehicleResults = 30,  -- 車両検索の最大件数
    minSearchLength = 1      -- 検索時の最小文字数
}
```

### 履歴設定

```lua
Config.History = {
    maxDisplayCount = 50,    -- 表示する履歴の最大数
    deletePermission = {     -- 削除権限を持つグループ
        ['admin'] = true,
        ['god'] = true,
        ['superadmin'] = true
    },
    retentionDays = 30       -- 履歴を保持する日数
}
```

### 通知設定

各種通知メッセージは `Config.Notifications` で変更可能です。

---

## 🔧 トラブルシューティング

### 問題: コマンドが動作しない

**解決策**:
- `server.cfg` でリソースが正しい順序で読み込まれているか確認
- サーバーコンソールでエラーメッセージを確認
- 依存関係（qb-core、ox_lib、oxmysql）が正しく起動しているか確認

```bash
# リソースの状態確認
ensure qb-core
ensure ox_lib
ensure oxmysql
ensure ng-refund
```

### 問題: 管理者メニューが開けない

**解決策**:
- 管理者権限が正しく設定されているか確認

```cfg
# server.cfg に以下を追加
add_ace group.admin command.admin allow
add_principal identifier.license:YOUR_LICENSE group.admin
```

### 問題: データベースエラー

**解決策**:
- `deleted_by` カラムが追加されているか確認

```sql
-- データベースで実行
SHOW COLUMNS FROM refund_history;
```

- カラムがない場合は追加:

```sql
ALTER TABLE refund_history 
ADD COLUMN deleted_by VARCHAR(50) NULL DEFAULT NULL AFTER deleted_at;
```

### 問題: アイテムが受け取れない

**解決策**:
- インベントリに空きがあるか確認
- ox_inventory が正しく動作しているか確認
- サーバーコンソールでエラーを確認

### 問題: 車両が受け取れない

**解決策**:
- ナンバープレートが重複していないか確認
- 車両モデルが `qb-core/shared/vehicles.lua` に存在するか確認
- `player_vehicles` テーブルが正しく存在するか確認

### 問題: 日本時間が表示されない

**解決策**:
- `client/main.lua` の `formatTimestamp` 関数で日本時間補正（+9時間）が正しく動作しているか確認
- システム時刻が正しいか確認

---

## 📝 更新履歴

### v1.1.0 (2025-10-11)
- ✨ 管理者による補填キャンセル機能を追加
- ✨ プレイヤーによる選択的受け取り機能を追加
- ✨ `/myrefunds` コマンドを追加
- 🔧 `deleted_by` カラムをデータベースに追加
- 📚 詳細なREADMEとアップデート手順を追加

### v1.0.0 (初回リリース)
- 🎉 アイテム補填機能
- 🎉 車両補填機能
- 🎉 補填履歴確認機能
- 🎉 一括受け取り機能

---

## 👥 サポート

問題が発生した場合:
1. このREADMEのトラブルシューティングセクションを確認
2. サーバーコンソールのエラーログを確認
3. データベースのテーブル構造を確認

---

## 🙏 クレジット

**開発者**: NCCGr  
**バージョン**: 1.1.0  
**最終更新**: 2025年10月11日