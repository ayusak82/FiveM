# ng-backpack

ox_inventoryを使用した複数サイズのバックパック＆スーツケースシステム

## 機能

- **3サイズのバックパック**
  - 小型バックパック (backpack1)
  - 中型バックパック (backpack2)
  - 大型バックパック (backpack3)

- **スーツケース機能**
  - 4桁パスコード設定/変更/削除
  - パスコードロック機能

- **安全機能**
  - バッグ内にバッグを入れることを禁止
  - 各アイテムごとの固有識別子

- **カスタマイズ可能**
  - Config.luaで容量を自由に変更可能
  - 通知メッセージのカスタマイズ

## 依存関係

- qb-core
- ox_lib
- ox_inventory

## インストール方法

### 1. リソースのインストール

1. `ng-backpack` フォルダを `resources` ディレクトリに配置
2. `server.cfg` に以下を追加:

```cfg
ensure ng-backpack
```

**重要:** `ox_lib` の後、`ox_inventory` の前に読み込んでください

```cfg
ensure ox_lib
ensure ng-backpack
ensure ox_inventory
```

### 2. アイテムの追加

#### 2-1. ox_inventory/data/items.lua に追加

`ox_inventory/data/items.lua` を開き、以下のアイテムを追加:

```lua
['backpack1'] = {
    label = '小型バックパック',
    weight = 220,
    stack = false,
    close = true,
    description = '小さなバックパック',
    client = {
        export = 'ng-backpack.openBackpack1'
    }
},

['backpack2'] = {
    label = '中型バックパック',
    weight = 440,
    stack = false,
    close = true,
    description = '中くらいのバックパック',
    client = {
        export = 'ng-backpack.openBackpack2'
    }
},

['backpack3'] = {
    label = '大型バックパック',
    weight = 660,
    stack = false,
    close = true,
    description = '大きなバックパック',
    client = {
        export = 'ng-backpack.openBackpack3'
    }
},

['suitcase'] = {
    label = 'スーツケース',
    weight = 880,
    stack = false,
    close = true,
    description = 'パスコードで保護できるスーツケース',
    client = {
        export = 'ng-backpack.openSuitcase'
    },
    buttons = {
        {
            label = 'パスコード管理',
            action = function(slot)
                exports['ng-backpack']:manageSuitcasePasscode(slot)
            end
        }
    }
},
```

#### 2-2. qb-core/shared/items.lua に追加

`qb-core/shared/items.lua` を開き、以下のアイテムを追加:

```lua
['backpack1'] = {
    ['name'] = 'backpack1',
    ['label'] = '小型バックパック',
    ['weight'] = 220,
    ['type'] = 'item',
    ['image'] = 'backpack1.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = '小さなバックパック'
},

['backpack2'] = {
    ['name'] = 'backpack2',
    ['label'] = '中型バックパック',
    ['weight'] = 440,
    ['type'] = 'item',
    ['image'] = 'backpack2.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = '中くらいのバックパック'
},

['backpack3'] = {
    ['name'] = 'backpack3',
    ['label'] = '大型バックパック',
    ['weight'] = 660,
    ['type'] = 'item',
    ['image'] = 'backpack3.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = '大きなバックパック'
},

['suitcase'] = {
    ['name'] = 'suitcase',
    ['label'] = 'スーツケース',
    ['weight'] = 880,
    ['type'] = 'item',
    ['image'] = 'suitcase.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'パスコードで保護できるスーツケース'
},
```

**注意:** qb-core/shared/items.luaへの追加は、QBCoreのアイテムシステムとの互換性を保つために必要です。

### 3. アイテム画像の追加（任意）

アイテム画像を `ox_inventory/web/images/` に追加:
- `backpack1.png`
- `backpack2.png`
- `backpack3.png`
- `suitcase.png`

**画像サイズ推奨:** 100x100 PNG形式

### 4. サーバーの再起動

すべての設定が完了したら、サーバーを再起動してください。

```bash
restart qb-core
restart ox_inventory
restart ng-backpack
```

## 使用方法

### バックパック

1. インベントリ内のバックパックを右クリック
2. 「使用」を選択してバックパックを開く
3. アイテムの出し入れが可能

### スーツケース

#### スーツケースを開く
1. インベントリ内のスーツケースを右クリック
2. 「使用」を選択
3. パスコードが設定されている場合は入力

#### パスコード管理
1. インベントリ内のスーツケースを右クリック
2. 「パスコード管理」を選択
3. 以下のオプションから選択:
   - **パスコードを設定**: 4桁の数字でロック
   - **パスコードを変更**: 既存のパスコードを変更
   - **パスコードを削除**: ロックを解除

## 設定

`shared/config.lua` で以下の設定が可能:

```lua
Config.Storage = {
    backpack1 = {
        slots = 5,      -- スロット数
        weight = 5000,  -- 最大重量
        label = '小型バックパック'
    },
    backpack2 = {
        slots = 10,
        weight = 10000,
        label = '中型バックパック'
    },
    backpack3 = {
        slots = 15,
        weight = 15000,
        label = '大型バックパック'
    },
    suitcase = {
        slots = 20,
        weight = 20000,
        label = 'スーツケース'
    }
}
```

## アイテムの配布方法

ゲーム内でアイテムを配布するには、以下のコマンドを使用:

```lua
-- プレイヤーにアイテムを付与
/giveitem [プレイヤーID] backpack1 1
/giveitem [プレイヤーID] backpack2 1
/giveitem [プレイヤーID] backpack3 1
/giveitem [プレイヤーID] suitcase 1
```

または、ショップスクリプトに追加して販売することも可能です。

## トラブルシューティング

### バックパックが開けない
- ox_inventoryが正常に起動しているか確認
- ox_inventory/data/items.lua に正しくアイテムが追加されているか確認
- qb-core/shared/items.lua にも追加されているか確認
- F8コンソールでエラーを確認

### パスコードが設定できない
- 4桁の数字を入力しているか確認
- スーツケースを一度開いてから設定を試す

### バッグの中にバッグが入る
- ox_inventoryのhookが正常に動作しているか確認
- リソースの読み込み順序を確認

### アイテムが表示されない
- qb-core/shared/items.luaにアイテムが追加されているか確認
- サーバーを完全に再起動したか確認
- `/refreshitems` コマンドを実行（利用可能な場合）

## サポート

問題が発生した場合は、F8コンソールのエラーログを確認してください。

## ライセンス

このスクリプトは販売用リソースです。
再配布は禁止されています。

## バージョン

**v1.0.0** - 初回リリース
- 3サイズのバックパック
- スーツケース（パスコード機能付き）
- バッグ内バッグ禁止機能
