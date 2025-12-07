# ng-thermalvision

FiveM用のサーマルビジョンスクリプト - 特定アイテムを使用してサーマルビジョンのON/OFFが可能

## 📋 機能

- ✅ 特定アイテム使用でサーマルビジョンのON/OFF切り替え
- ✅ サーマル使用中のプレイヤーの頭上に「🔴 サーマル使用中」表示
- ✅ アイテムを所持していない場合の自動OFF機能
- ✅ デバッグモード搭載（コマンドで切り替え可能）
- ✅ ox_libの通知システム統合
- ✅ qb-core & ox_inventory完全対応
- ✅ escrow保護対応（販売用）

## 📦 必要なリソース

- **qb-core** - フレームワーク
- **ox_lib** - 通知システム
- **ox_inventory** または **qb-inventory** - インベントリシステム（どちらか一方）

### インベントリシステムについて

このスクリプトは以下のインベントリシステムに対応しています：

- ✅ **ox_inventory** - 自動検出して動作
- ✅ **qb-inventory** (qb-core標準) - 自動検出して動作

**exportは不要**: スクリプトが自動的にアイテム使用を処理します。

## 🔧 インストール方法

### 1. リソースの配置

`ng-thermalvision` フォルダを `resources` フォルダに配置します。

```
resources/
└── [your-resources]/
    └── ng-thermalvision/
        ├── fxmanifest.lua
        ├── shared/
        │   └── config.lua
        ├── client/
        │   └── main.lua
        └── server/
            └── main.lua
```

### 2. アイテムの追加

#### 方法A: ox_inventory を使用している場合

`ox_inventory/data/items.lua` に以下のアイテムを追加：

```lua
['thermal_goggles'] = {
    label = 'サーマルゴーグル',
    weight = 500,
    stack = false,
    close = true,
    description = 'サーマルビジョンを使用できるゴーグル'
},
```

**注意**: exportは不要です。スクリプトが自動的に処理します。

---

#### 方法B: qb-inventory (qb-core標準) を使用している場合

`qb-core/shared/items.lua` に以下のアイテムを追加：

```lua
['thermal_goggles'] = {
    name = 'thermal_goggles',
    label = 'サーマルゴーグル',
    weight = 500,
    type = 'item',
    image = 'thermal_goggles.png',
    unique = true,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'サーマルビジョンを使用できるゴーグル'
},
```

**画像ファイル**: `qb-inventory/html/images/thermal_goggles.png` に画像を配置してください。

### 3. server.cfgに追加

```cfg
ensure ng-thermalvision
```

### 4. サーバー再起動

サーバーを再起動してリソースを読み込みます。

## ⚙️ 設定（shared/config.lua）

```lua
Config = {}

-- デバッグモード（true = コマンドでON/OFF可能、false = アイテムのみ）
Config.DebugMode = false

-- サーマルビジョンを使用するアイテム名
Config.ThermalItem = 'thermal_goggles'

-- サーマルビジョン設定
Config.ThermalSettings = {
    visionType = 4, -- 4 = サーマル（1 = ナイトビジョン、0 = 通常）
    autoDisable = true -- アイテムを持っていない場合の自動OFF
}
```

### 設定項目の説明

| 項目 | 説明 | デフォルト値 |
|------|------|-------------|
| `DebugMode` | デバッグモード（コマンド使用可否） | `false` |
| `ThermalItem` | 使用するアイテム名 | `'thermal_goggles'` |
| `autoDisable` | アイテム非所持時の自動OFF | `true` |

## 🎮 使用方法

### 通常モード

1. インベントリから `thermal_goggles` を使用
2. サーマルビジョンがON/OFFで切り替わります
3. サーマル使用中のプレイヤーには頭上に「🔴 サーマル使用中」と表示されます

### デバッグモード（Config.DebugMode = true の場合）

```
/thermal - サーマルビジョンのON/OFF切り替え
/thermalstatus - 現在サーマル使用中のプレイヤー一覧を表示（管理者のみ）
```

## 🔒 Escrow保護

このスクリプトは販売用に設計されており、escrow保護に対応しています。

### 編集可能なファイル
- ✅ `shared/config.lua` のみ

### 保護されるファイル
- 🔒 `client/main.lua`
- 🔒 `server/main.lua`
- 🔒 `fxmanifest.lua`

## 🌟 特徴

### 自動インベントリ検出
- ox_inventory と qb-inventory の両方に対応
- 使用中のインベントリシステムを自動検出
- exportなしで動作（サーバー側で処理）

### 3D表示システム
- サーマル使用中のプレイヤーを視覚的に識別可能
- 100m以内のプレイヤーに表示
- 日本語フォント対応（SetTextFont(0)）

### 自動OFF機能
- アイテムを持っていない場合、2秒ごとにチェック
- 自動でサーマルビジョンをOFF
- サーバーとの同期を維持

### セキュリティ
- サーバー側でアイテム所持確認
- 不正使用の防止
- プレイヤー切断時の状態クリア

## 🐛 トラブルシューティング

### サーマルビジョンが動作しない

1. `qb-core`、`ox_lib`、`ox_inventory` が正しく起動しているか確認
2. アイテムが正しく追加されているか確認
3. F8コンソールでエラーを確認

### 3Dテキストが表示されない

1. 他のプレイヤーがサーマルを使用しているか確認
2. 距離が100m以内か確認
3. デバッグモードでログを確認

### アイテムが使用できない

**ox_inventory の場合:**
```lua
-- ox_inventory/data/items.lua を確認
['thermal_goggles'] = {
    label = 'サーマルゴーグル',
    weight = 500,
    stack = false,
    close = true,
    description = 'サーマルビジョンを使用できるゴーグル'
    -- export は不要です
},
```

**qb-inventory の場合:**
```lua
-- qb-core/shared/items.lua を確認
['thermal_goggles'] = {
    name = 'thermal_goggles',
    label = 'サーマルゴーグル',
    weight = 500,
    type = 'item',
    image = 'thermal_goggles.png',
    unique = true,
    useable = true,  -- ← これが true になっているか確認
    shouldClose = true,
    combinable = nil,
    description = 'サーマルビジョンを使用できるゴーグル'
},
```

**確認事項:**
1. アイテムが正しく追加されているか
2. qb-inventory の場合、`useable = true` になっているか
3. サーバーを再起動したか

## 📝 ライセンス

このスクリプトは販売用です。escrow保護により、`shared/config.lua` 以外の編集は制限されています。

## 👤 作者

**NCCGr**

## 📌 バージョン

**Version 1.0.0**

---

## 🆘 サポート

問題が発生した場合は、以下を確認してください：

1. ✅ すべての依存関係が正しくインストールされているか
2. ✅ アイテムが正しく追加されているか
3. ✅ server.cfgに `ensure ng-thermalvision` が追加されているか
4. ✅ F8コンソールでエラーメッセージを確認

---