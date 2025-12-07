# ng-teleport

職業別テレポートシステム - FiveM Resource

## 機能

- 職業ごとに異なるテレポート先を設定可能
- HPチェック機能（設定可能な必要HP値）
- クールダウンシステム（Webhookでログ記録）
- ブラックリストゾーン（PolyZone形式で設定可能）
- カスタマイズ可能なエフェクトとサウンド
- ox_libを使用したモダンなUI

## 依存関係

- [qb-core](https://github.com/qbcore-framework/qb-core)
- [ox_lib](https://github.com/overextended/ox_lib)

## インストール

1. このリソースをサーバーの`resources`フォルダに配置
2. `server.cfg`に以下を追加:
```cfg
ensure ng-teleport
```

## 設定

### config.lua

```lua
-- クールダウン設定（分）
Config.Cooldown = 10

-- HP要件設定（%）
Config.RequiredHealth = 100

-- Discord Webhook設定
Config.DiscordWebhook = {
    url = '',  -- あなたのWebhook URLを入力
    botName = 'Teleport Logs',
    colors = {
        success = 3066993,  -- Green
        error = 15158332    -- Red
    }
}

-- ブラックリストゾーン設定
Config.BlacklistZones = {
    {
        name = "カジノ内部",
        points = {
            vector2(1100.0, 220.0),
            vector2(1100.0, 240.0),
            vector2(1120.0, 240.0),
            vector2(1120.0, 220.0)
        }
    }
}
```

### テレポート先の追加

`config.lua`の`Config.TeleportLocations`に以下の形式で追加:

```lua
['職業名'] = {
    label = '表示名',
    locations = {
        {
            label = '場所の名前',
            coords = vector4(x, y, z, heading)
        }
    }
}
```

## 使用方法

1. `/tpmenu`コマンドを使用してテレポートメニューを開く
2. テレポートしたい場所を選択
3. 各種チェック（HP、クールダウン、ブラックリストゾーン）が通過すればテレポート実行

## コマンド

- `/tpmenu` - テレポートメニューを開く

## 制限事項

- 車両に乗っているときはテレポート不可
- 指定されたHP値以下の場合はテレポート不可
- ブラックリストゾーン内からはテレポート不可
- クールダウン中はテレポート不可

## お問い合わせ

Discord: ayusak

## ライセンス

このスクリプトは商用製品です。無断での再配布・改変は禁止されています。