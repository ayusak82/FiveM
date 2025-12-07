# ng-business - ビジネス管理システム

FiveM用の包括的なビジネス管理システムです。スタッシュ、トレイ、クラフト、個人ロッカー、ブリップをゲーム内で動的に作成・管理できます。

## 特徴

- **スタッシュ作成機能** - 保管庫をゲーム内で作成・管理
- **トレイ作成機能** - カウンタートレイを動的に配置
- **クラフト作成機能** - クラフトステーションとレシピを設定
- **個人ロッカー作成機能** - プレイヤー専用ロッカーを配置
- **ブリップ作成機能** - マップアイコンを自由に配置
- **レーザー座標設定** - ng-laser統合でレーザーを使って正確な座標を設定可能
- **インタラクションタイプ切り替え** - targetとmarkerを自由に切り替え可能
- **リアルタイム反映** - 作成後すぐに全プレイヤーに反映
- **データベース自動セットアップ** - サーバー起動時に自動でテーブル作成
- **権限管理** - 管理者のみが作成・編集・削除可能
- **ジョブ制限** - 特定のジョブとグレードに制限可能
- **デバッグモード** - 開発時のトラブルシューティングに対応
- **ox_target完全対応** - IDベースの堅牢なターゲット管理システム（Pug Business Creator参考）
- **エラーハンドリング強化** - ターゲット削除時の適切なクリーンアップ処理

## 作者情報

- **作者**: NCCGr
- **問い合わせ先**: Discord: ayusak
- **バージョン**: 1.0.0

## 依存関係

以下のリソースが必要です：

- [qb-core](https://github.com/qbcore-framework/qb-core) - QBCoreフレームワーク
- [ox_lib](https://github.com/overextended/ox_lib) - UIライブラリ
- [ox_inventory](https://github.com/overextended/ox_inventory) - インベントリシステム
- [oxmysql](https://github.com/overextended/oxmysql) - MySQLライブラリ
- [okokNotify](https://okok.tebex.io/) - 通知システム

## インストール方法

1. `ng-business` フォルダをサーバーの `resources` ディレクトリに配置
2. `server.cfg` に以下を追加：
```cfg
ensure qb-core
ensure ox_lib
ensure ox_inventory
ensure oxmysql
ensure okokNotify
ensure ng-business
```
3. サーバーを起動（データベーステーブルが自動作成されます）
4. ゲーム内で `/businessadmin` コマンドを使用して、スタッシュ、トレイ、クラフト、ロッカー、ブリップを作成

**注意:** 初回起動時にデータベーステーブルが自動的に作成されます。手動でSQLを実行する必要はありません。

## 使用方法

### 管理者メニューを開く

ゲーム内で以下のコマンドを実行：
```
/businessadmin
```

管理者権限（`command.admin`）が必要です。

### 1. スタッシュ作成

1. `/businessadmin` でメニューを開く
2. 「Create Stash」を選択
3. 以下の情報を入力：
   - **Stash ID**: 一意の識別子（例: `police_storage`）
   - **Label**: 表示名（例: `警察署保管庫`）
   - **Slots**: スロット数（1-100）
   - **Weight**: 最大重量
   - **Jobs**: 使用可能なジョブ（カンマ区切り、例: `police,ambulance`）
   - **Min Grade**: 最低必要グレード
   - **Enable Blip**: ブリップを表示するか
   - **Blip Sprite**: ブリップアイコンID
   - **Blip Color**: ブリップカラーID
   - **Blip Scale**: ブリップサイズ
4. 現在地に作成されます

### 2. トレイ作成

1. `/businessadmin` でメニューを開く
2. 「Create Tray」を選択
3. スタッシュと同様の情報を入力
4. トレイは従業員がアイテムを置き、顧客が取り出す用途に使用

### 3. クラフトステーション作成

1. `/businessadmin` でメニューを開く
2. 「Create Crafting Station」を選択
3. 基本情報を入力後、レシピを追加：
   - **Item**: クラフトするアイテム名
   - **Label**: レシピの表示名
   - **Ingredients**: 必要な材料（アイテム名と数量）
   - **Craft Time**: クラフト時間（ミリ秒）
   - **Amount**: 作成される数量

### 4. 個人ロッカー作成

1. `/businessadmin` でメニューを開く
2. 「Create Locker」を選択
3. 基本情報を入力
4. 「Personal」を有効にすると、各プレイヤーが専用のロッカーを持ちます

### 5. ブリップ作成

1. `/businessadmin` でメニューを開く
2. 「Create Blip」を選択
3. 以下の情報を入力：
   - **Label**: ブリップ名
   - **Sprite**: アイコンID（[ブリップ一覧](https://docs.fivem.net/docs/game-references/blips/)）
   - **Color**: カラーID
   - **Scale**: サイズ

### 既存アイテムの管理

1. `/businessadmin` でメニューを開く
2. 「Manage Existing」を選択
3. 編集または削除したいアイテムを選択

## 設定

`shared/config.lua` で以下の設定をカスタマイズできます：

### デバッグモード
```lua
Config.Debug = false  -- trueにすると詳細ログが出力されます（英語）
```

### UI設定
```lua
Config.UI = {
    marker = {
        type = 1,           -- マーカータイプ
        size = {x = 1.0, y = 1.0, z = 1.0},
        color = {r = 0, g = 255, b = 0, a = 100},
    },
    interactionDistance = 2.0,  -- インタラクション距離
    notificationDuration = 5000, -- 通知表示時間
}
```

### インタラクションキー
```lua
Config.InteractionKey = 38  -- E キー
```

## データベース構造

サーバー起動時に以下のテーブルが自動作成されます：

### business_stashes
- スタッシュ情報を保存
- フィールド: id, stash_id, label, coords, slots, weight, jobs, min_grade, blip設定, created_by, created_at

### business_trays
- トレイ情報を保存
- フィールド: id, tray_id, label, coords, slots, weight, jobs, min_grade, blip設定, created_by, created_at

### business_crafting
- クラフトステーション情報を保存
- フィールド: id, crafting_id, label, coords, jobs, min_grade, recipes, blip設定, created_by, created_at

### business_lockers
- ロッカー情報を保存
- フィールド: id, locker_id, label, coords, slots, weight, jobs, min_grade, personal, blip設定, created_by, created_at

### business_blips
- カスタムブリップ情報を保存
- フィールド: id, label, coords, sprite, color, scale, created_by, created_at

## ファイル構造

```
ng-business/
├── fxmanifest.lua          # マニフェストファイル
├── README.md               # このファイル
├── client/
│   ├── main.lua            # クライアントメイン
│   ├── admin.lua           # 管理者メニュー
│   ├── stash.lua           # スタッシュ機能
│   ├── tray.lua            # トレイ機能
│   ├── crafting.lua        # クラフト機能
│   ├── locker.lua          # ロッカー機能
│   └── blip.lua            # ブリップ機能
├── server/
│   ├── main.lua            # サーバーメイン（DB自動セットアップ）
│   ├── stash.lua           # スタッシュ処理
│   ├── tray.lua            # トレイ処理
│   ├── crafting.lua        # クラフト処理
│   ├── locker.lua          # ロッカー処理
│   └── blip.lua            # ブリップ処理
└── shared/
    └── config.lua          # 共有設定ファイル
```

## 機能詳細

### スタッシュ（保管庫）
- 大容量の保管スペース
- ジョブとグレードで制限可能
- 共有保管庫として使用
- 例: 警察署の証拠品保管庫、メカニックの部品倉庫

### トレイ（カウンタートレイ）
- 小容量の受け渡しスペース
- 従業員が商品を置き、顧客が受け取る
- 例: レストランのカウンター、ショップのレジ

### クラフトステーション
- アイテムをクラフトする場所
- 複数のレシピを設定可能
- 材料チェックと自動消費
- 例: 警察の武器庫、メカニックの工房

### 個人ロッカー
- プレイヤー専用の保管スペース
- 各プレイヤーが独自のロッカーを持つ
- 例: 警察官のロッカールーム、病院のスタッフルーム

### カスタムブリップ
- マップに自由にアイコンを配置
- 重要な場所をマーク
- 例: 本部、集合場所、イベント会場

## 権限設定

### 管理者権限
`server.cfg` に以下を追加して管理者権限を付与：
```cfg
add_ace group.admin command.admin allow
add_principal identifier.license:YOUR_LICENSE_HERE group.admin
```

または、QBCoreの権限システムを使用。

## トラブルシューティング

### メニューが開かない
- 管理者権限（`command.admin`）があるか確認
- F8コンソールでエラーメッセージを確認

### スタッシュが開かない
- ジョブとグレードが正しいか確認
- ox_inventoryが正しく動作しているか確認
- サーバーコンソールでエラーを確認

### データベーステーブルが作成されない
- oxmysqlが正しくインストールされているか確認
- データベース接続情報が正しいか確認
- サーバーコンソールでエラーを確認

### ブリップが表示されない
- ブリップ設定で「Enable Blip」が有効か確認
- スプライトIDとカラーIDが正しいか確認

### 依存関係エラー
- すべての依存関係が `ng-business` より前に読み込まれているか確認
- 各リソースが最新バージョンか確認

## デバッグモード

`shared/config.lua` で `Config.Debug = true` に設定すると、詳細なログが英語で出力されます：

```lua
Config.Debug = true
```

ログの種類：
- `^3[DEBUG]^7` - デバッグ情報（黄色）
- `^1[ERROR]^7` - エラー情報（赤色）
- `^2[SUCCESS]^7` - 成功情報（緑色）
- `^5[WARNING]^7` - 警告情報（紫色）

## パフォーマンス

- 最適化されたスレッド管理
- 距離チェックによる負荷軽減
- データベースクエリの最小化
- リアルタイム同期

## セキュリティ

- 管理者権限チェック（サーバーサイド）
- SQLインジェクション対策（プレースホルダー使用）
- クライアント入力の検証
- 権限のないアクセスをブロック

## 今後の更新予定

- [ ] スタッシュのアクセスログ
- [ ] クラフトレシピのインポート/エクスポート
- [ ] ロッカーの容量アップグレード
- [ ] トレイの通知システム
- [ ] Webベースの管理パネル

## カスタマイズ

### 新しいブリップアイコンを追加
[FiveM Blips Reference](https://docs.fivem.net/docs/game-references/blips/) を参照してスプライトIDを確認。

### マーカーの色を変更
`shared/config.lua` の `Config.UI.marker.color` を編集：
```lua
color = {r = 255, g = 0, b = 0, a = 100}  -- 赤色
```

### インタラクション距離を変更
```lua
Config.UI.interactionDistance = 3.0  -- 3メートル
```

## ライセンス

このスクリプトは販売用です。無断での再配布や改変は禁止されています。

## サポート

問題や質問がある場合は、Discord: ayusak までお問い合わせください。

---

**© 2025 NCCGr. All rights reserved.**


## レーザーシステム

### レーザーで座標を設定

スタッシュ、トレイ、クラフトステーション、ロッカーを作成する際、レーザーを使用して正確な座標を設定できます：

1. 作成メニューで「レーザーを使用」を選択
2. レーザーが起動し、照準が表示されます
3. 設置したい場所にレーザーを向けます
4. **Eキー**を押して座標を確定
5. **ESCキー**でキャンセル

### レーザーコマンド（デバッグ用）

```
/laser
```

レーザー座標取得システムを単独で起動します。Eキーで座標をクリップボードにコピーできます。

## インタラクションタイプ

### Target vs Marker

設定メニューから、インタラクションタイプを切り替えられます：

- **Target（ターゲット）モード**
  - ox_targetまたはqb-targetを使用
  - 視線を向けるだけでインタラクション可能
  - パフォーマンスが良い
  - 推奨設定

- **Marker（マーカー）モード**
  - 地面にマーカーを表示
  - 近づいてEキーでインタラクション
  - 視覚的にわかりやすい
  - レガシー互換性

### 切り替え方法

1. `/businessadmin` でメニューを開く
2. 「設定」を選択
3. 「インタラクションタイプ」を選択
4. 確認ダイアログで変更を確定
5. 自動的にリロードされます

## 設定

### Config.lua

`shared/config.lua` で以下の設定が可能：

```lua
-- インタラクションタイプ
Config.InteractionType = "target"  -- "target" or "marker"

-- ターゲットシステム
Config.Target = "ox_target"  -- "ox_target" or "qb-target"

-- レーザーシステム
Config.Laser = {
    enabled = true,              -- レーザーを有効化
    color = {255, 0, 0, 255},   -- レーザーの色 (R, G, B, A)
    maxDistance = 100.0,         -- 最大距離
    updateInterval = 0,          -- 更新頻度（ミリ秒）
    toggleCommand = 'laser',     -- コマンド名
    setCoordKey = 'E',          -- 座標設定キー
}
```
