# ng-lottery

FiveM用の宝くじスクリプト。美しいHTML UIで宝くじ体験を提供します。

## 特徴

- 🎰 シンプルで直感的な宝くじシステム
- 🎨 モダンなHTML/CSS/JSによるUI
- 💰 設定可能な報酬範囲
- 🎭 宝くじ抽選時のアニメーション
- 🔒 Escrow対応（config.luaのみ編集可能）
- 🛠️ ox_lib UIシステム使用

## 必要な依存関係

- [qb-core](https://github.com/qbcore-framework/qb-core)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [oxmysql](https://github.com/overextended/oxmysql)

## インストール方法

1. `ng-lottery`フォルダをあなたのリソースディレクトリに配置します
2. `server.cfg`に以下を追加します：
   ```cfg
   ensure ng-lottery
   ```
3. ox_inventoryに宝くじアイテムを追加します

### アイテム追加方法

#### qb-core (qb-inventory使用時)

`qb-core/shared/items.lua`に以下を追加：

```lua
['lottery_ticket'] = {
    name = 'lottery_ticket',
    label = '宝くじチケット',
    weight = 10,
    type = 'item',
    image = 'lottery_ticket.png',
    unique = false,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = '運試しの宝くじチケット'
},
```

#### ox_inventory使用時

`ox_inventory/data/items.lua`に以下を追加：

```lua
['lottery_ticket'] = {
    label = '宝くじチケット',
    weight = 10,
    stack = true,
    close = true,
    description = '運試しの宝くじチケット',
    client = {
        image = 'lottery_ticket.png',
    }
},
```

**注意**: アイテム画像（lottery_ticket.png）は適切なインベントリの画像フォルダに配置してください。
- qb-inventory: `qb-inventory/html/images/`
- ox_inventory: `ox_inventory/web/images/`

## 設定

`shared/config.lua`で以下の設定が可能です：

```lua
Config = {}

-- 宝くじアイテムの設定
Config.LotteryItem = 'lottery_ticket' -- 使用する宝くじアイテムの名前

-- 報酬設定
Config.Rewards = {
    minAmount = 100,    -- 最小報酬額（ドル）
    maxAmount = 10000   -- 最大報酬額（ドル）
}

-- アニメーション設定
Config.Animation = {
    dict = 'amb@world_human_stand_impatient@male@no_sign@idle_a',
    anim = 'idle_a',
    duration = 3000 -- アニメーション時間（ミリ秒）
}

-- UI設定
Config.UI = {
    showTime = 5000, -- 結果表示時間（ミリ秒）
    enableSound = true -- サウンド効果の有効/無効
}

-- デバッグモード
Config.Debug = false
```

## 使用方法

1. プレイヤーが`lottery_ticket`アイテムを使用
2. 宝くじUIが表示される
3. 「宝くじを引く」ボタンをクリック
4. アニメーションと共に抽選が実行
5. 当選金額が表示され、自動的に現金が付与される

## ファイル構造

```
ng-lottery/
├── fxmanifest.lua      # リソースマニフェスト
├── README.md           # このファイル
├── shared/
│   └── config.lua      # 設定ファイル（編集可能）
├── client/
│   └── main.lua        # クライアントサイドスクリプト
├── server/
│   └── main.lua        # サーバーサイドスクリプト
└── html/
    ├── index.html      # UI HTML
    ├── style.css       # UI スタイル
    └── script.js       # UI JavaScript
```

## トラブルシューティング

### UIが表示されない
- F8コンソールでエラーを確認してください
- 依存関係がすべて起動しているか確認してください

### アイテムが使用できない
- ox_inventoryにアイテムが正しく追加されているか確認してください
- アイテム名がconfig.luaと一致しているか確認してください

### 報酬が付与されない
- qb-coreが正しく動作しているか確認してください
- デバッグモードを有効にしてコンソールログを確認してください

## サポート

問題や質問がある場合は、GitHubのIssuesセクションで報告してください。

## ライセンス

このプロジェクトは商用利用可能です。

## クレジット

- 作者: NCCGr
- フレームワーク: QBCore
- UI ライブラリ: ox_lib

---

**注意**: このスクリプトはescrow保護されています。`shared/config.lua`のみ編集可能です。