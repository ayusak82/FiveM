# 🎰 ng-vehiclegacha - 車両ガチャシステム

FiveM QBCore向けの高機能車両ガチャシステムです。美しいアニメーション、完全なデータベース管理、リアルタイム更新機能を搭載しています。

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)
![QBCore](https://img.shields.io/badge/QBCore-Compatible-orange.svg)

---

## ✨ 特徴

### 🎨 美しいUI/UX
- **HTMLベースのカスタムUI**: モダンで洗練されたデザイン
- **ガチャマシンアニメーション**: 臨場感あふれる演出
- **ルーレット演出**: 車の絵文字が高速スクロール
- **紙吹雪エフェクト**: レアリティに応じた祝福演出
- **レスポンシブデザイン**: あらゆる画面サイズに対応

### 🎮 プレイヤー機能
- NPCに話しかけてガチャメニューを開く
- 4種類のガチャタイプ(デフォルト: スポーツ/高級/オフロード/スーパー)
- 支払い方法: お金 または ガチャチケット
- 4段階のレアリティシステム
  - 🔘 **Common** (60%): グレー
  - 🔵 **Rare** (25%): 青
  - 🟣 **SuperRare** (12%): 紫
  - 🟡 **UltraRare** (3%): 金色(虹色エフェクト付き)
- 車両は自動でガレージに追加
- 個人ガチャ履歴の確認

### 🛠️ 管理者機能
- `/vgacha_admin` - 管理メニュー
- `/vgacha_ticket [ID] [枚数]` - プレイヤーへチケット付与
- `/vgacha_toggle [タイプ] [0/1]` - ガチャ有効/無効切り替え
- リアルタイムでデータベース編集
  - ガチャ設定の変更(価格、アイコン、有効化)
  - 車両の追加/削除/有効化
  - 新規ガチャタイプの作成
- 詳細統計情報
  - 総ガチャ回数
  - プレイヤー数
  - 人気車両TOP10
  - レアリティ別/ガチャタイプ別統計
- 全体履歴の閲覧

### 💾 データベース管理
- **自動テーブル作成**: スクリプト起動時に自動でテーブルを生成
- **初期データ投入**: サンプル車両とガチャタイプを自動登録
- **リアルタイム反映**: 変更が即座に反映
- 完全なトランザクション管理

---

## 📋 必要要件

- **FiveM Server**
- **QBCore Framework**
- **oxmysql** - データベース管理
- **ox_lib** - UI/通知システム
- **ox_target** (オプション) - NPCインタラクション

---

## 🚀 インストール

### 1. ファイルの配置

```
resources/
└── ng-vehiclegacha/
    ├── fxmanifest.lua
    ├── shared/
    │   └── config.lua
    ├── client/
    │   ├── npc.lua
    │   └── main.lua
    ├── server/
    │   ├── database.lua
    │   ├── main.lua
    │   └── admin.lua
    └── html/
        ├── index.html
        ├── style.css
        └── script.js
```

### 2. server.cfg に追加

```lua
ensure ng-vehiclegacha
```

### 3. データベース

スクリプトを起動すると、自動的に以下のテーブルが作成されます:
- `ng_vehiclegacha_settings` - ガチャ設定
- `ng_vehiclegacha_vehicles` - 車両リスト
- `ng_vehiclegacha_history` - ガチャ履歴
- `ng_vehiclegacha_tickets` - プレイヤーチケット数

### 4. サーバー起動

サーバーを起動すると、コンソールに以下のメッセージが表示されます:

```
[ng-vehiclegacha] データベーステーブルを確認/作成しました
[ng-vehiclegacha] ガチャタイプの初期データを投入しました
[ng-vehiclegacha] 車両の初期データを投入しました
```

---

## ⚙️ 設定

### NPC配置の変更

`shared/config.lua` を編集:

```lua
Config.NPCs = {
    {
        model = 's_m_m_autoshop_01',
        coords = vector4(-32.59, -1102.43, 26.42, 160.0), -- 座標を変更
        scenario = 'WORLD_HUMAN_CLIPBOARD',
        blipSettings = {
            enabled = true,
            sprite = 669,
            color = 5,
            scale = 0.8,
            label = '車両ガチャ'
        }
    },
    -- 複数のNPCを追加可能
}
```

### レアリティ確率の変更

`shared/config.lua`:

```lua
Config.Rarities = {
    {
        name = 'Common',
        label = 'コモン',
        color = '#B0B0B0',
        chance = 60, -- 確率を変更
    },
    -- ...
}
```

### ガチャ演出時間の変更

```lua
Config.GachaUI = {
    animationDuration = 3000, -- ミリ秒(3秒)
    showPreview = true,
}
```

---

## 🎯 使い方

### プレイヤー

1. **ガチャNPCに近づく**
   - マップ上の黄色いアイコンを目印に
   - Legion Square付近(デフォルト座標)

2. **NPCをクリック** (ox_target使用時)
   - または `[E]` キーで話しかける

3. **ガチャタイプを選択**
   - スポーツカー
   - 高級車
   - オフロード
   - スーパーカー

4. **支払い方法を選択**
   - 💵 お金で支払う
   - 🎫 チケットを使用

5. **ガチャを回す**
   - ガチャマシンアニメーション(3秒)
   - 結果表示(紙吹雪エフェクト付き)
   - 車両は自動でガレージに追加

### 管理者

#### チケット付与
```
/vgacha_ticket [プレイヤーID] [枚数]
```
例: `/vgacha_ticket 1 10` - ID:1のプレイヤーに10枚付与

#### ガチャ有効/無効
```
/vgacha_toggle [ガチャタイプ] [0/1]
```
例: `/vgacha_toggle sports 0` - スポーツカーガチャを無効化

#### 管理メニュー
```
/vgacha_admin
```

---

## 📊 データベース構造

### ng_vehiclegacha_settings
ガチャタイプの設定テーブル

| カラム | 型 | 説明 |
|--------|-----|------|
| id | INT | 主キー |
| gacha_type | VARCHAR(50) | ガチャタイプID |
| label | VARCHAR(100) | 表示名 |
| enabled | TINYINT(1) | 有効/無効 |
| price_money | INT | 価格(お金) |
| price_ticket | INT | 価格(チケット) |
| icon | VARCHAR(50) | アイコン |

### ng_vehiclegacha_vehicles
車両リストテーブル

| カラム | 型 | 説明 |
|--------|-----|------|
| id | INT | 主キー |
| gacha_type | VARCHAR(50) | ガチャタイプ |
| vehicle_model | VARCHAR(50) | 車両モデル名 |
| vehicle_label | VARCHAR(100) | 車両表示名 |
| rarity | VARCHAR(20) | レアリティ |
| enabled | TINYINT(1) | 有効/無効 |

### ng_vehiclegacha_history
ガチャ履歴テーブル

| カラム | 型 | 説明 |
|--------|-----|------|
| id | INT | 主キー |
| citizenid | VARCHAR(50) | プレイヤーID |
| player_name | VARCHAR(100) | プレイヤー名 |
| gacha_type | VARCHAR(50) | ガチャタイプ |
| vehicle_model | VARCHAR(50) | 車両モデル |
| vehicle_label | VARCHAR(100) | 車両名 |
| rarity | VARCHAR(20) | レアリティ |
| payment_type | VARCHAR(20) | 支払い方法 |
| created_at | TIMESTAMP | 実行日時 |

### ng_vehiclegacha_tickets
プレイヤーチケットテーブル

| カラム | 型 | 説明 |
|--------|-----|------|
| citizenid | VARCHAR(50) | プレイヤーID(主キー) |
| tickets | INT | チケット数 |
| updated_at | TIMESTAMP | 更新日時 |

---

## 🎨 カスタマイズ例

### 新しいガチャタイプの追加

1. 管理コマンドで追加:
```
/vgacha_admin
→ ガチャ設定管理
→ 新規ガチャタイプ追加
```

2. または直接データベースに:
```sql
INSERT INTO ng_vehiclegacha_settings 
(gacha_type, label, enabled, price_money, price_ticket, icon) 
VALUES ('custom', 'カスタム', 1, 50000, 1, 'fa-solid fa-star');
```

### 車両の追加

管理メニューから:
```
/vgacha_admin
→ 車両管理
→ ガチャタイプを選択
→ 車両を追加
```

入力項目:
- 車両モデル名: `adder` (スポーンコード)
- 車両表示名: `Truffade Adder`
- レアリティ: UltraRare

---

## 🐛 トラブルシューティング

### NPCが表示されない

1. **ox_targetの確認**
   ```
   ensure ox_target
   ```

2. **座標の確認**
   - `shared/config.lua`のNPC座標を確認
   - ゲーム内で `/coords` で現在地を確認

3. **コンソールエラーの確認**
   - F8キーでコンソールを開く
   - エラーメッセージを確認

### ガチャが回せない

1. **データベース接続の確認**
   - `oxmysql` が正常に動作しているか確認
   - コンソールでSQLエラーがないか確認

2. **車両データの確認**
   ```sql
   SELECT * FROM ng_vehiclegacha_vehicles WHERE enabled = 1;
   ```

3. **お金/チケットの確認**
   - プレイヤーの所持金を確認
   - チケット数を確認

### HTMLが表示されない

1. **ファイルの確認**
   ```
   ng-vehiclegacha/html/
   ├── index.html
   ├── style.css
   └── script.js
   ```

2. **fxmanifest.luaの確認**
   ```lua
   ui_page 'html/index.html'
   files {
       'html/index.html',
       'html/style.css',
       'html/script.js'
   }
   ```

3. **ブラウザコンソールの確認**
   - F8 → 「NUI」タブ
   - JavaScriptエラーを確認

---

## 📝 変更履歴

### v1.0.0 (2025-01-XX)
- 🎉 初回リリース
- ✨ ガチャマシンアニメーション実装
- ✨ HTMLベースのカスタムUI
- ✨ 4段階レアリティシステム
- ✨ 完全なデータベース管理
- ✨ リアルタイム設定変更
- ✨ 管理者用統計機能
- ✨ 紙吹雪エフェクト

---

## 🔒 販売・再配布について

このスクリプトは販売用です。

### Escrow設定
以下のファイルは保護対象外です:
- `shared/config.lua` - 設定ファイル
- `server/database.lua` - データベース構造
- `server/admin.lua` - 管理機能

---

## 🤝 サポート

問題が発生した場合:
1. このREADMEの「トラブルシューティング」を確認
2. コンソールログを確認
3. データベースの整合性を確認

---

## 📄 ライセンス

このスクリプトの著作権は NCCGr に帰属します。

---

## 🎬 機能一覧

### ガチャメニュー
- 4種類のガチャタイプから選択
- お金/チケット支払い対応

### ガチャ演出
- ガチャマシンアニメーション
- ルーレット高速スクロール
- 臨場感あふれる演出

### 結果表示
- レアリティ別カラー
- 紙吹雪エフェクト
- チェックマークアニメーション

### 管理メニュー
- ガチャ設定管理
- 車両管理
- 詳細統計
- 履歴閲覧

---

## 🌟 今後の予定

- [ ] より多くのガチャ演出パターン
- [ ] カスタムサウンドエフェクト
- [ ] 期間限定ガチャ機能
- [ ] ガチャ天井システム
- [ ] プレビュー機能の強化

---

**Enjoy! 🎰✨**
