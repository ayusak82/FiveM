# NGSubscribe - QBCore サブスクリプション管理システム

## 概要
NGSubscribeは、FiveMサーバー向けのサブスクリプション管理システムです。Discord連携を利用して、プレイヤーに特典を自動付与することができます。

## 特徴
- Discord役職に基づく自動サブスクリプション付与
- 複数のサブスクリプションプラン管理
- プラン別の報酬システム（現金・アイテム）
- 車両付与システム（カテゴリー別選択可能）
- 管理者用コントロールパネル
- Webhook通知システム
- 月次自動更新機能
- プレイヤーによる手動更新機能

## 必要要件
- QBCore Framework
- ox_lib
- oxmysql
- ox_inventory

## インストール手順

1. データベースのインポート
- サーバーの起動時に自動的にテーブルが作成されます

2. server.cfgの設定
```cfg
ensure ox_lib
ensure oxmysql
ensure ox_inventory
ensure ng-subscribe
```

## 設定方法

### Discord Bot設定

1. Discord Developerポータルで新しいBotを作成
2. 以下の権限を付与:
   - Server Members Intent
   - Message Content Intent
   - 必要なBot権限

3. `config.lua`にBot情報を設定:
```lua
Config.Discord = {
    BotToken = 'YOUR_BOT_TOKEN',
    GuildId = 'YOUR_GUILD_ID',
    Roles = {
        ['ROLE_ID'] = 'plan_name',  -- 役職IDとプラン名をマッピング
    },
    AdminRoles = {
        'ADMIN_ROLE_ID'  -- 管理者権限を持つ役職ID
    }
}
```

### Webhook設定
サブスクリプション関連のイベントをDiscordに通知するためのWebhook設定：

```lua
Config.Discord.Webhooks = {
    rewards = 'WEBHOOK_URL',    -- 報酬受け取り通知用
    vehicles = 'WEBHOOK_URL',   -- 車両受け取り通知用
    subscriptions = 'WEBHOOK_URL'  -- サブスクリプション付与・変更通知用
}
```

### プラン設定
各サブスクリプションプランの詳細設定：

```lua
Config.Plans = {
    ['plan_name'] = {
        label = '表示名',
        level = 1,  -- 優先レベル（高いほど優先）
        rewards = {
            cash = 1000000,  -- 付与する現金
            items = {
                ['item_name'] = 1,  -- 付与するアイテムと数量
                ['item_name2'] = 2
            },
            vehicle_categories = {'sports', 'muscle'}  -- 選択可能な車両カテゴリー
        }
    }
}
```

### 車両設定
```lua
Config.Vehicles = {
    BlacklistedVehicles = {  -- グローバルでブラックリストに登録する車両
        'oppressor',
        'oppressor2'
    },
    PlanBlacklist = {  -- プラン別のブラックリスト車両
        ['bronze'] = {
            'adder',
            't20'
        }
    }
}
```

## コマンド一覧

### プレイヤーコマンド
- `/subs` - サブスクリプションメニューを開く
- `/updatesubs` - サブスクリプション情報を手動で更新する

### 管理者コマンド
- `/subsadmin` - 管理者メニューを開く
- `/forcesubs` - 全プレイヤーのサブスクリプションを強制更新
- `/forceplayersubs [id]` - 特定プレイヤーのサブスクリプションを強制更新

## 機能説明

### サブスクリプション自動付与
- プレイヤーがサーバーに参加時に自動チェック
- 毎月1日に自動更新
- Discord役職に基づく自動付与
- 複数のプランを持つ場合は最高レベルのプランが適用

### 報酬システム
- 現金報酬 - プラン設定に基づく自動付与
- アイテム報酬 - プラン別に設定可能
- 車両選択システム - カテゴリー別に選択可能

### 車両システム
- カテゴリー別の車両選択
- プラン別のブラックリスト設定
- グローバルブラックリスト設定
- ナンバープレート自動生成

### 管理者機能
- プレイヤー情報の検索と確認
- プランの手動変更
- 全プレイヤーの強制更新
- 特定プレイヤーの強制更新
- サブスクリプション失効処理

### Webhook通知
- 報酬受け取り時の通知
- 車両受け取り時の通知
- サブスクリプション付与・変更時の通知

### 手動更新機能
- プレイヤーによる手動更新（クールダウン設定可能）
- 管理者による強制更新

## データベース

システムは以下のテーブルを使用します：

### player_subscriptions
- プレイヤーのサブスクリプション情報を管理
- 有効期限、報酬受け取り状況などを記録

### subscription_history
- サブスクリプションの変更履歴を記録
- プラン変更、報酬受け取りなどのアクションを記録

## セキュリティ機能
- Discord連携による不正防止
- 管理者権限のロール管理
- 定期的なトークンキャッシュクリア

## トラブルシューティング

1. サブスクリプションが自動付与されない
- Discord Botのトークンと権限を確認
- プレイヤーのDiscord連携を確認
- サーバーコンソールのエラーログを確認
- 手動で `/updatesubs` コマンドを試す

2. アイテムが受け取れない
- インベントリシステムの設定を確認
- アイテム名がQBCore.Shared.Itemsに存在するか確認
- インベントリの容量を確認

3. 車両が受け取れない
- 車両名がQBCore.Shared.Vehiclesに存在するか確認
- カテゴリー設定を確認
- ブラックリスト設定を確認

## サポート
問題が発生した場合は、Discordにてお問い合わせください。