# ng-refund - 管理者補填システム

QBCore フレームワーク対応の管理者用アイテム・車両補填システムです。管理者がプレイヤーに対してアイテムや車両を補填し、プレイヤーが後から受け取ることができる仕組みを提供します。

## 機能

### 🔧 管理者機能
- **アイテム補填**: プレイヤーにアイテムを補填
- **車両補填**: プレイヤーに車両を補填
- **補填履歴確認**: 過去の補填履歴を確認
- **プレイヤー検索**: CitizenIDや名前でプレイヤーを検索
- **アイテム検索**: アイテム名やラベルで検索
- **車両検索**: 車両名やブランドで検索

### 👥 プレイヤー機能
- **補填受取**: `/refunds` コマンドで補填されたアイテム・車両を受け取り

## 必要な依存関係

```lua
dependencies = {
    'qb-core',      -- QBCore フレームワーク
    'ox_lib',       -- ox_lib ライブラリ
    'oxmysql'       -- MySQL データベース接続
}
```

## インストール

1. **リソースの配置**
   ```
   resources/[local]/ng-refund/
   ├── fxmanifest.lua
   ├── shared/
   │   └── config.lua
   ├── client/
   │   └── main.lua
   └── server/
       └── main.lua
   ```

2. **server.cfg への追加**
   ```cfg
   ensure ng-refund
   ```

3. **権限設定**
   管理者権限 `command.admin` を持つプレイヤーのみ使用可能です。

## 使用方法

### 管理者向け

#### メインメニューを開く
```
/refund
```

#### アイテム補填の手順
1. `/refund` コマンドでメニューを開く
2. 「アイテム補填」を選択
3. プレイヤーを検索・選択
4. アイテムを検索・選択
5. 補填する個数を入力
6. 確認画面で実行

#### 車両補填の手順
1. `/refund` コマンドでメニューを開く
2. 「車両補填」を選択
3. プレイヤーを検索・選択
4. 車両を検索・選択
5. ナンバープレートを入力（空欄で自動生成）
6. 確認画面で実行

### プレイヤー向け

#### 補填されたアイテム・車両を受け取る
```
/refunds
```

## 設定

`shared/config.lua` で各種設定をカスタマイズできます。

### 基本設定
```lua
-- 管理者権限の設定
Config.RequiredAceGroup = "command.admin"

-- UIの設定
Config.UI = {
    position = 'right-center',
    header = {
        title = '補填管理システム',
        icon = 'boxes-stacked'
    }
}
```

### 検索設定
```lua
Config.Search = {
    maxPlayerResults = 20,    -- プレイヤー検索の最大件数
    maxItemResults = 50,      -- アイテム検索の最大件数
    maxVehicleResults = 30,   -- 車両検索の最大件数
    minSearchLength = 1       -- 検索時の最小文字数
}
```

### 通知設定
```lua
Config.Notifications = {
    success = {
        title = '補填完了',
        description = '%s に %s を補填しました',
        type = 'success',
        duration = 5000
    }
    -- その他の通知設定...
}
```

## データベース

インストール時に自動的に `refund_history` テーブルが作成されます。

### テーブル構造
```sql
CREATE TABLE refund_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    admin_identifier VARCHAR(50) NOT NULL,      -- 管理者のCitizenID
    admin_name VARCHAR(50) NOT NULL,            -- 管理者の名前
    target_identifier VARCHAR(50) NOT NULL,     -- 対象プレイヤーのCitizenID
    target_name VARCHAR(50) NOT NULL,           -- 対象プレイヤーの名前
    type VARCHAR(10) NOT NULL,                  -- 'item' または 'vehicle'
    item_name VARCHAR(50),                      -- アイテム名
    amount INT,                                 -- アイテムの個数
    vehicle_model VARCHAR(50),                  -- 車両モデル
    plate VARCHAR(8),                          -- ナンバープレート
    claimed BOOLEAN DEFAULT FALSE,              -- 受取済みフラグ
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- 作成日時
    deleted_at TIMESTAMP NULL                   -- 削除日時
);
```

## コマンド一覧

### 管理者用コマンド
| コマンド | 説明 | 権限 |
|---------|------|------|
| `/refund` | 管理者メニューを開く | `command.admin` |

### プレイヤー用コマンド
| コマンド | 説明 | 権限 |
|---------|------|------|
| `/refunds` | 補填されたアイテム・車両を受け取る | なし |

## 特徴

### 🔍 高度な検索機能
- **プレイヤー検索**: CitizenID、名前（部分一致対応）
- **アイテム検索**: アイテム名、ラベル（部分一致対応）
- **車両検索**: 車両名、ブランド（部分一致対応、空欄で全車両表示）

### 📊 履歴管理
- すべての補填履歴を記録
- 受取状況の確認
- 管理者と対象プレイヤーの情報を保存

### 🚗 車両補填機能
- カスタムナンバープレート対応
- 自動ナンバープレート生成
- 重複チェック機能

### 📱 直感的なUI
- ox_lib を使用したモダンなインターface
- 分かりやすいメニュー構造
- リアルタイム検索結果表示

### 🕐 日本時間対応
- 履歴表示時に日本時間（JST）で表示
- 分かりやすい日時フォーマット

## トラブルシューティング

### よくある問題

**Q: メニューが開かない**
A: 管理者権限（`command.admin`）を確認してください

**Q: アイテムが受け取れない**
A: インベントリに十分な空きがあるか確認してください

**Q: 車両が受け取れない**
A: ガレージの容量制限を確認してください

**Q: 検索結果が表示されない**
A: 検索キーワードが正確か確認してください（部分一致対応）

## サポート

### 動作環境
- QBCore フレームワーク
- ox_lib
- oxmysql
- MySQL/MariaDB

### 既知の制限事項
- インベントリ容量制限によりアイテムが受け取れない場合があります
- 車両は自動的に `pillboxgarage` に配置されます
- ナンバープレートは最大8文字（英数字のみ）

## 更新履歴

### v1.0.0
- 初回リリース
- アイテム・車両補填機能
- プレイヤー・アイテム・車両検索機能
- 履歴管理機能
- 日本語対応

## 作者

**NCCGr** - 管理者補填システム

---

**注意**: このスクリプトを使用する前に、必ずテスト環境で動作確認を行ってください。