## 概要

`ng-lootbox` は、CSGO風のケース開封UIを提供するFiveMスクリプトです。視覚的な演出とカスタマイズ可能なケース内容により、ゲーム内経済にランダム性のある報酬メカニズムを追加します。

## 特徴

- **カスタマイズ可能なケース:** 異なるレアリティレベル（Common, Uncommon, Rare, Epic, Legendary）でケースを定義可能
- **UI:** ケースを開ける際のワクワク感を演出するUI

## 必要条件

- ESX, QB, または ox_inventoryを使用したスタンドアローン

## インストール

1. `ng-lootbox`フォルダをサーバーのresourcesディレクトリにコピー
2. server.cfgに`ensure ng-lootbox`を追加

## 設定

ケースの設定は`server/data.lua`の`CASES`テーブルで行います。各レアリティレベルごとにアイテムや武器を設定できます。

各レアリティには最低1つのアイテムが必要です。設定がないとスクリプトが正しく動作しません。

設定例:

```lua
CASES = {
    ['gun_case'] = {
        common = {
            {
                name = 'WEAPON_PISTOL',
                amount = 1,
                additionalItems = { -- 追加アイテムの設定も可能
                    { name = 'ammo-9', amount = 3 }
                }
            },
            {
                name = 'WEAPON_SNSPISTOL',
                amount = 1,
            },
        },
        uncommon = {
            {
                name = 'WEAPON_HEAVYPISTOL',
                amount = 1,
            },
        },
        rare = {
            {
                name = 'WEAPON_APPISTOL',
                amount = 1,
            },
        },
        epic = {
            {
                name = 'WEAPON_COMBATPDW',
                amount = 1,
            },
        },
        legendary = {
            {
                name = 'WEAPON_RPG',
                amount = 1,
            },
        },
    }
}
```

## デバッグモード

init.luaでデバッグモードの設定が可能です：

```lua
Bridge = {
    Debug = true  -- デバッグ出力を有効化
}
```

## 確率設定

各レアリティの出現確率：

- Common: 80%
- Uncommon: 16%
- Rare: 3.10%
- Epic: 0.64%
- Legendary: 0.26%

## アイテムの設定

ox_inventoryのitems.luaに以下の設定を追加してください：

```lua
['gun_case'] = {
    label = 'Gun Case',
    weight = 1000,
    stack = true,
    close = true,
    description = "武器が出現するガチャケース",
    client = {
        image = 'gun_case.png',
        usable = true,
    }
},
```

## サポート

スクリプトに関する質問やフィードバックは、フォーラムまたはDiscordでお願いします。
不具合報告の際は、デバッグモードを有効にしたログを添付してください。