# ng-dailybonus

FiveMサーバー向けのデイリーボーナスシステム。Discord連携によるロール別報酬機能を搭載。

## 特徴

- **デイリーボーナス**: プレイヤーが1日1回受け取れる基本ボーナス
- **Discord連携**: Discordロールに基づく追加ボーナス
- **ox_lib UI**: 美しく直感的なユーザーインターフェース
- **重量チェック**: ox_inventory対応の重量確認システム
- **Export機能**: 外部スクリプトからの操作が可能
- **キャッシュシステム**: Discord API呼び出しを最適化

## 依存関係

### 必須
- [qb-core](https://github.com/qbcore-framework/qb-core)
- [ox_lib](https://github.com/overextended/ox_lib)
- [oxmysql](https://github.com/overextended/oxmysql)
- [ox_inventory](https://github.com/overextended/ox_inventory)

### オプション
- Discord Bot（ロール別ボーナス機能に必要）

## インストール

1. **リソースのダウンロード**
   ```bash
   cd resources
   git clone [your-repository-url] ng-dailybonus
   ```

2. **server.cfg に追加**
   ```
   ensure ng-dailybonus
   ```

3. **データベース**
   - 自動でテーブルが作成されます（手動設定不要）

## 設定

### Discord連携設定

1. **Discord Developer Portal**でBotを作成
2. Bot Tokenを取得
3. サーバーにBotを招待（権限: `Read Messages/View Channels`）
4. `shared/config.lua`を編集

```lua
-- Discord設定
Config.Discord = {
    enabled = true, -- Discord連携を有効にする
    guildId = '123456789012345678', -- あなたのDiscordサーバーID
    botToken = 'MTIzNDU2Nzg5MDEyMzQ1Njc4.G12345.abcdefghijklmnopqrstuvwxyz123456789' -- Botトークン
}
```

### ロール設定

```lua
Config.RoleBonuses = {
    {
        roleId = '987654321098765432', -- DiscordロールID
        name = 'VIPボーナス',
        description = 'VIPメンバー限定の特別ボーナス',
        cooldown = 24,
        rewards = {
            { item = 'money', amount = 10000, label = '現金' },
            { item = 'lockpick', amount = 3, label = 'ロックピック' }
        }
    }
}
```

### 基本ボーナス設定

```lua
Config.BasicBonus = {
    enabled = true,
    name = '基本デイリーボーナス',
    description = '毎日受け取れる基本ボーナス',
    cooldown = 24,
    rewards = {
        { item = 'money', amount = 5000, label = '現金' },
        { item = 'bread', amount = 5, label = 'パン' }
    }
}
```

## 使用方法

### プレイヤー
- `/dailybonus` - デイリーボーナスメニューを開く

### 管理者
- `/resetdailybonus` - 自分のデイリーボーナースをリセット
- `/cleardiscordcache` - Discordロールキャッシュをクリア

## API / Export機能

### サーバー側 Export

```lua
-- 利用可能なボーナス情報を取得
exports['ng-dailybonus']:GetAvailableBonuses(source, function(bonuses)
    -- bonuses: テーブル配列
end)

-- ボーナスを受け取らせる
exports['ng-dailybonus']:ClaimBonus(source, bonusId)

-- クールダウンをチェック
local canClaim = exports['ng-dailybonus']:CheckCooldown(source, bonusType)

-- 残り時間を取得（秒）
local seconds = exports['ng-dailybonus']:GetRemainingTime(source, bonusType)

-- Discordロールをチェック
local hasRole = exports['ng-dailybonus']:HasDiscordRole(source, roleId)

-- メニューを開く
exports['ng-dailybonus']:OpenDailyBonusMenu(source)
```

### クライアント側 Export

```lua
-- メニューを開く
exports['ng-dailybonus']:OpenDailyBonusMenu()

-- 利用可能なボーナス情報を取得
local bonuses = exports['ng-dailybonus']:GetAvailableBonuses()

-- メニューが開いているかチェック
local isOpen = exports['ng-dailybonus']:IsMenuOpen()
```

### Events

```lua
-- サーバー側
TriggerServerEvent('ng-dailybonus:server:openMenu')
TriggerServerEvent('ng-dailybonus:server:getBonusInfo', bonusId)

-- クライアント側
TriggerEvent('ng-dailybonus:client:openMenu')
TriggerEvent('ng-dailybonus:client:notify', title, description, type, duration)
```

## トラブルシューティング

### よくある問題

1. **メニューが表示されない**
   - ox_libが正しくインストールされているか確認
   - コンソールエラーをチェック

2. **Discordロールが認識されない**
   - Bot TokenとGuild IDが正しく設定されているか確認
   - BotがサーバーにあることとBotに適切な権限があるか確認
   - `/cleardiscordcache`でキャッシュをクリア

3. **アイテムが受け取れない**
   - ox_inventoryが正しく動作しているか確認
   - 重量制限に引っかかっていないか確認
   - アイテムが存在するか確認

4. **何度でも受け取れてしまう**
   - データベース接続を確認
   - デバッグモードでログを確認

### デバッグモード

```lua
Config.Debug = true -- shared/config.lua
```

デバッグモードを有効にすると、詳細なログがコンソールに表示されます。

### ログの確認

重要なログメッセージ：
- `[ng-dailybonus] データベーステーブルを初期化しました` - DB初期化成功
- `[ng-dailybonus] Discord APIからロール取得成功` - Discord連携成功
- `[ng-dailybonus] クールダウンチェック` - 受け取り可能性チェック

## ファイル構造

```
ng-dailybonus/
├── fxmanifest.lua          # リソース設定
├── shared/
│   └── config.lua          # 設定ファイル（編集可能）
├── server/
│   └── main.lua            # サーバー側処理（暗号化）
├── client/
│   └── main.lua            # クライアント側処理（暗号化）
└── README.md               # このファイル
```

## ライセンス

このスクリプトは販売用として作成されており、著作権は制作者に帰属します。
再配布、改変、リバースエンジニアリングは禁止されています。

## サポート

サポートが必要な場合は、購入先にお問い合わせください。

### 制作者情報
- 制作者: NCCGr
- バージョン: 1.0.0

---

## Changelog

### v1.0.0
- 初回リリース
- 基本デイリーボーナス機能
- Discord連携機能
- ox_inventory対応
- Export/Event機能