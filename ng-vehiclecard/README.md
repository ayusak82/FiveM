# ng-vehiclecard

FiveM用の車両カードシステム - アイテムを使用して車両をスポーン/格納できるスクリプト

## 📋 機能

- ✅ 車両カードアイテムで車両をスポーン/格納
- ✅ 使用回数制限システム（耐久度）
- ✅ 使い切ったカードは「壊れた車両カード」に変化
- ✅ 放置車両の自動デスポーン（300m + 5分）
- ✅ スポーン位置の障害物チェック
- ✅ 自動車両キー付与
- ✅ 管理者コマンドでカード作成・配布
- ✅ ショップでカード購入
- ✅ 新規プレイヤーへのスターターパック配布

## 🔧 依存関係

- [qb-core](https://github.com/qbcore-framework/qb-core)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [oxmysql](https://github.com/overextended/oxmysql)

## 📦 インストール

### 1. リソースの配置
```
resources/[custom]/ng-vehiclecard/
```

### 2. アイテムの追加

**ox_inventory を使用している場合:**

`ox_inventory/data/items.lua` に以下を追加:

```lua
['vehicle_card'] = {
    label = '車両カード',
    weight = 100,
    stack = false,
    close = true,
    description = '車両をスポーンできるカード',
    client = {
        event = 'ng-vehiclecard:client:useVehicleCard',
        usetime = 2500
    }
},

['vehicle_card_broken'] = {
    label = '壊れた車両カード',
    weight = 50,
    stack = false,
    close = true,
    description = '使い切って壊れた車両カード'
},
```

**qb-inventory を使用している場合:**

`qb-core/shared/items.lua` に以下を追加:

```lua
['vehicle_card'] = {
    name = 'vehicle_card',
    label = '車両カード',
    weight = 100,
    type = 'item',
    image = 'vehicle_card.png',
    unique = true,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = '車両をスポーンできるカード'
},

['vehicle_card_broken'] = {
    name = 'vehicle_card_broken',
    label = '壊れた車両カード',
    weight = 50,
    type = 'item',
    image = 'vehicle_card_broken.png',
    unique = false,
    useable = false,
    shouldClose = true,
    combinable = nil,
    description = '使い切って壊れた車両カード'
},
```

そして `qb-core/server/player.lua` にアイテム使用イベントを追加:

```lua
-- vehicle_card の使用
QBCore.Functions.CreateUseableItem('vehicle_card', function(source, item)
    TriggerClientEvent('ng-vehiclecard:client:useVehicleCard', source, item.slot, item)
end)
```

### 3. server.cfg に追加
```cfg
ensure ng-vehiclecard
```

### 4. データベース
スターターパック用のテーブルは自動作成されます。

## ⚙️ 設定

`shared/config.lua` で各種設定が可能です。

### 基本設定
```lua
Config.DefaultUses = 10              -- デフォルト使用回数
Config.SpawnDistance = 5.0           -- 車両スポーン距離
Config.StoreDistance = 5.0           -- 車両格納最大距離
```

### 自動デスポーン設定
```lua
Config.AutoDespawn = {
    enabled = true,                  -- 自動デスポーンを有効化
    distance = 300.0,                -- プレイヤーからの距離 (メートル)
    time = 300,                      -- 放置時間 (秒) 300秒 = 5分
    checkInterval = 30               -- チェック間隔 (秒)
}
```

### スターターパック設定
```lua
Config.StarterPack = {
    enabled = true,                  -- スターターパックを有効化
    vehicles = {
        { model = 'blista', uses = 5 },
    }
}
```

### ショップ設定
```lua
Config.Shops = {
    {
        name = "車両カードショップ - ロスサントス",
        coords = vector3(-56.85, -1098.65, 26.42),
        blip = { enabled = true, sprite = 524, color = 3, scale = 0.8 },
        marker = {
            type = 1,
            size = vector3(1.5, 1.5, 1.0),
            color = {r = 0, g = 150, b = 255, a = 100},
            distance = 10.0
        },
        interactDistance = 2.5
    },
}
```

### 販売車両リスト
```lua
Config.ShopVehicles = {
    {
        category = "コンパクト",
        vehicles = {
            { model = 'blista', label = 'Blista', price = 50000, uses = 10 },
            -- 他の車両...
        }
    },
}
```

## 🎮 使い方

### プレイヤー

1. **車両カードを使用**
   - インベントリから車両カードを使用
   - 目の前に車両がスポーンされます
   - 自動的に車両キーが付与されます

2. **車両を格納**
   - 車両の近くで再度カードを使用
   - 車両がカードに戻ります

3. **ショップで購入**
   - ショップマーカー（青色）に近づく
   - `E` キーでメニューを開く
   - カテゴリーから車両を選択して購入

### 管理者コマンド

#### 車両カード作成
```
/createvehiclecard [プレイヤーID] [車両モデル] [使用回数(任意)]
```

例:
```
/createvehiclecard 1 adder 10
/createvehiclecard 2 t20 5
/createvehiclecard 3 blista
```

#### 車両カード付与（別名）
```
/givevehiclecard [プレイヤーID] [車両モデル] [使用回数(任意)]
```

#### スターターパックのリセット
```
/resetstarter [プレイヤーID]
```

#### デバッグコマンド
`server.cfg` に `setr ng_vehiclecard_debug true` を追加すると、以下のコマンドが使用可能:
```
/vcdebug
```

## 📊 メタデータ構造

車両カードのメタデータ:
```lua
metadata = {
    vehicle = "adder",                          -- 車両モデル名
    uses = 10,                                  -- 残り使用回数
    max_uses = 10,                              -- 最大使用回数
    label = "車両カード (Adder)",              -- 表示名
    description = "使用回数: 10/10",            -- 説明
    cardId = "ABC12345_1"                       -- カードID（自動生成）
}
```

## 🔒 権限設定

管理者コマンドを使用するには、`server.cfg` に以下を追加:

```cfg
add_ace group.admin command.admin allow
add_principal identifier.license:YOUR_LICENSE group.admin
```

または、QBCore の admin 権限を使用:
```lua
QBCore.Functions.AddPermission(source, 'admin')
```

## 🚨 トラブルシューティング

### 車両がスポーンしない
- 車両モデル名が正しいか確認
- スポーン位置に障害物がないか確認
- コンソールでエラーを確認

### アイテムが使用できない
- アイテムが正しく登録されているか確認
- ox_inventory/qb-inventory のアイテム設定を確認
- useable/client.event が正しく設定されているか確認

### スターターパックが配布されない
- Config.StarterPack.enabled が true か確認
- oxmysql が正しく動作しているか確認
- データベース接続を確認

### ショップが表示されない
- Config.Shops の座標が正しいか確認
- ブリップが有効になっているか確認
- クライアントスクリプトがロードされているか確認

## 📝 開発情報

### ファイル構造
```
ng-vehiclecard/
├── fxmanifest.lua          # リソース定義
├── locales/
│   └── ja.lua             # 日本語翻訳
├── shared/
│   └── config.lua         # 設定ファイル
├── client/
│   ├── main.lua           # クライアントメイン処理
│   └── shop.lua           # ショップシステム
└── server/
    ├── main.lua           # サーバーメイン処理
    ├── commands.lua       # 管理者コマンド
    └── starter.lua        # スターターパック配布
```

### Escrow 保護
以下のファイルは暗号化対象外（escrow_ignore）:
- `shared/config.lua`
- `locales/ja.lua`

## 🆘 サポート

問題が発生した場合:
1. コンソールでエラーログを確認
2. 設定ファイルを再確認
3. 依存リソースが最新版か確認
4. デバッグモードを有効にして詳細を確認

## 📄 ライセンス

このスクリプトは販売用として作成されています。
再配布や改変は制限されています。

## 🔄 更新履歴

### v1.0.0 (Initial Release)
- 車両カードシステムの実装
- 使用回数制限システム
- 自動デスポーン機能
- ショップシステム
- スターターパック配布
- 管理者コマンド

---

**Author:** NCCGr  
**Version:** 1.0.0  
**Framework:** QBCore  
**Dependencies:** qb-core, ox_lib, ox_inventory, oxmysql
