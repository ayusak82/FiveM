# ng-gacha

高度なガチャシステム - FiveM向けカスタムガチャ作成・実行スクリプト

## 概要

プレイヤーがゲーム内でオリジナルのガチャを作成し、他のプレイヤーに提供できるシステムです。
美しいサイバーパンク風UIと、レアリティ別の演出で臨場感のあるガチャ体験を提供します。

## 作者情報

- **作者**: NCCGr
- **問い合わせ**: Discord: ayusak

## 機能

### ガチャ作成
- ガチャチケットアイテムを使用してオリジナルガチャを作成
- ガチャ名、説明、料金を自由に設定
- 景品とその確率を細かく調整
- カラーテーマの選択（6種類）
- 天井システムの設定（オプション）

### ガチャ実行
- 1回引き / 10連ガチャ
- レアリティ別の演出
- レジェンダリー / ジャックポット時の特別エフェクト
- アイテム画像表示対応

### 管理機能
- 履歴表示
- 天井カウント
- 統計データ（総回数、総収益）

## 依存関係

- **qb-core** - QBCoreフレームワーク
- **ox_lib** - UIライブラリ
- **oxmysql** - データベース

## インストール

1. `ng-gacha` フォルダを `resources` ディレクトリに配置

2. **qb-core/shared/items.lua** に以下を追加:

```lua
-- ガチャチケット（ガチャを作成するためのアイテム）
['gacha_ticket'] = {
    ['name'] = 'gacha_ticket',
    ['label'] = 'ガチャチケット',
    ['weight'] = 10,
    ['type'] = 'item',
    ['image'] = 'gacha_ticket.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'オリジナルガチャを作成できるチケット'
},

-- ガチャマシン（作成されたガチャを開くアイテム）
['gacha_machine'] = {
    ['name'] = 'gacha_machine',
    ['label'] = 'ガチャマシン',
    ['weight'] = 500,
    ['type'] = 'item',
    ['image'] = 'gacha_machine.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'ガチャを開く'
},

-- ガチャコイン（ガチャを回すための通貨アイテム）
['gacha_coin'] = {
    ['name'] = 'gacha_coin',
    ['label'] = 'ガチャコイン',
    ['weight'] = 1,
    ['type'] = 'item',
    ['image'] = 'gacha_coin.png',
    ['unique'] = false,
    ['useable'] = false,
    ['shouldClose'] = false,
    ['combinable'] = nil,
    ['description'] = 'ガチャを回すためのコイン'
},
```

3. アイテム画像を `qb-inventory/html/images/` に配置:
   - `gacha_ticket.png`
   - `gacha_machine.png`
   - `gacha_coin.png`

4. `server.cfg` に以下を追加:
   ```
   ensure ng-gacha
   ```

5. サーバーを再起動（データベーステーブルは自動作成されます）

## 使用方法

### ガチャの作成
1. `gacha_ticket` アイテムを使用
2. UIで以下を設定:
   - ガチャ名
   - 説明
   - 1回あたりの料金
   - 支払い方法（現金/銀行/ガチャコイン）
   - 天井回数（0で無効）
   - カラーテーマ
   - 景品リスト（アイテム、個数、レアリティ、確率）
3. 確率の合計が100%になるように調整
4. 「ガチャを作成」をクリック
5. `gacha_machine` アイテムがインベントリに追加される

### ガチャの実行
1. `gacha_machine` アイテムを使用
2. 「1回引く」または「10連ガチャ」をクリック
3. 結果を確認

## 設定 (shared/config.lua)

### デバッグモード
```lua
Config.Debug = false
```

### レアリティ設定
```lua
Config.Rarities = {
    ['common'] = { label = 'Common', color = '#8a8a8a' },
    ['uncommon'] = { label = 'Uncommon', color = '#4ade80' },
    ['rare'] = { label = 'Rare', color = '#3b82f6' },
    ['epic'] = { label = 'Epic', color = '#a855f7' },
    ['legendary'] = { label = 'Legendary', color = '#f59e0b' }
}
```

### 10連ガチャ設定
```lua
Config.MultiPull = {
    enabled = true,
    count = 10,
    discount = 0  -- 割引率（%）
}
```

### 制限設定
```lua
Config.Limits = {
    maxGachaPerPlayer = 5,  -- プレイヤーあたりの最大作成数
    minPrice = 100,         -- 最低料金
    maxPrice = 100000,      -- 最高料金
}
```

### Discord Webhook
```lua
Config.Discord = {
    enabled = false,
    webhook = '',
    logCreation = true,  -- ガチャ作成をログ
    logJackpot = true    -- ジャックポット当選をログ
}
```

## 管理者コマンド

| コマンド | 説明 |
|---------|------|
| `/gachareload` | ガチャシステムをリロード |
| `/giveticket [id] [amount]` | ガチャチケットを付与 |
| `/givecoin [id] [amount]` | ガチャコインを付与 |

## データベーステーブル

以下のテーブルが自動作成されます:
- `ng_gacha` - ガチャ本体
- `ng_gacha_items` - 景品リスト
- `ng_gacha_history` - 抽選履歴
- `ng_gacha_pity` - 天井カウント

## アイテム画像について

景品のアイテム画像は `qb-inventory/html/images/` フォルダのものが自動的に使用されます。
画像形式: `{アイテム名}.png`

## ライセンス

このスクリプトは販売用です。無断での再配布・転売を禁止します。

## サポート

問題やご質問がありましたら、Discord (ayusak) までお問い合わせください。
