# ng-repairvehicle

車両の修理と返却を管理する高機能なスクリプトです。
一般ユーザーとAdmin用の機能を備え、柔軟な設定が可能です。

## 機能

### 一般ユーザー向け機能
- 目の前の車両またはプレート指定での車両返却
- 車両の損傷状態に応じた料金計算
- 最小損傷要件による返却制限
- 所有者確認による不正防止

### Admin向け機能
- 全プレイヤーの車両を返却可能
- 料金なしでの返却
- 損傷要件の制限なし
- 専用コマンドによる簡単操作

### その他の機能
- Discord Webhookによる詳細なログ記録
- 柔軟な設定オプション
- 他のスクリプトからの操作用Export関数

## 依存関係

- qb-core
- ox_lib
- oxmysql

## インストール方法

1. このリソースを`resources`フォルダに配置
2. `server.cfg`に以下を追加:
```cfg
ensure ng-repairvehicle
```
3. `config.lua`の設定を環境に合わせて調整

## 設定項目

### 基本設定
```lua
Config.Command = 'returnvehicle'       -- 一般ユーザー用コマンド
Config.AdminCommand = 'areturnvehicle' -- Admin用コマンド
Config.SearchDistance = 3.0            -- 車両検索距離
```

### 損傷要件設定
```lua
Config.DamageRequirement = {
    enabled = true,      -- 損傷要件を有効にするか
    minPercent = 30.0,   -- 最小損傷割合（%）
    checkEngine = true,  -- エンジン損傷をチェック
    checkBody = true,    -- ボディ損傷をチェック
}
```

### 料金設定
```lua
Config.Costs = {
    base = 500,          -- 基本料金
    engineDamage = 100,  -- エンジンダメージ1%あたりの追加料金
    bodyDamage = 100,    -- ボディダメージ1%あたりの追加料金
}
```

## コマンド

- `/returnvehicle` - 一般ユーザー用の車両返却コマンド
- `/areturnvehicle` - Admin用の車両返却コマンド

## サポート

不具合や質問がありましたら、以下の方法でお問い合わせください：
- Discord: ayusak

## ライセンス

このスクリプトは商用製品です。
無断での再配布、改変、販売は禁止されています。

NCCGr