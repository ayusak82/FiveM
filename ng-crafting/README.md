# ng-crafting

ジョブに基づいたアイテムクラフトシステム for QBCore & ox_inventory

## 特徴

- ox_inventoryのアイテムから自動的にジョブアイテムを検出
- `ジョブ名_アイテム名`形式または`job_ジョブ名_アイテム名`形式のアイテムを自動的にクラフトに追加
- プレイヤーのジョブが一致している場合のみクラフトに表示＆作成可能
- アイテムの種類（食料、飲料、ストレス、通常）によって異なるクラフトレシピ
- Configで種類ごとのクラフト必要アイテム、完成した場合の個数を設定可能
- 複数の場所にクラフトテーブル（調理台など）を設置可能
- ox_libのUIを使用したモダンなインターフェース
- ox_targetによる直感的な操作
- **所持素材に基づいた最大作成可能数の計算機能**
- **クラフト時の個数選択機能**
- **必要素材が足りない場合のメニューの無効化**
- **作成個数に応じたプログレスバー時間の延長**

## 依存スクリプト

- qb-core
- ox_inventory
- ox_target
- ox_lib

## インストール

1. このリソースをサーバーの `resources` フォルダに配置します
2. `server.cfg` に `ensure ng-crafting` を追加します
3. 必要に応じて `shared/config.lua` を編集して、クラフト場所やアイテムレシピを設定します

## 設定

`shared/config.lua` で以下の設定が可能です：

### クラフト場所の設定

```lua
Config.CraftingLocations = {
    {
        coords = vector3(-1178.25, -896.36, 13.25), -- 変更が必要
        radius = 1.5,
        debug = false, -- trueの場合、デバッグスフィアが表示されます
        prop = {
            model = 'v_res_tre_cooker', -- ガスコンロ
            rotation = vector3(0.0, 0.0, 0.0), -- 回転角度
            offset = vector3(0.0, 0.0, -1.0), -- プロップ位置のオフセット
            frozen = true -- プロップを固定するかどうか
        }
    },
    -- 他の場所も必要に応じて追加可能
}
```

クラフト場所ごとに以下の設定が可能です：
- `coords`: クラフトポイントの座標（vector3形式）
- `radius`: インタラクション可能な半径
- `debug`: デバッグ表示の有無
- `prop`: クラフトテーブルとして表示するプロップの設定
  - `model`: プロップのモデル名（例: 'v_res_tre_cooker'）
  - `rotation`: プロップの回転角度（vector3形式）
  - `offset`: 座標からのオフセット位置（vector3形式）
  - `frozen`: プロップを固定するかどうか（true/false）

### アイテムタイプの設定

```lua
Config.ItemTypes = {
    food = {
        requiredItems = {
            { name = 'water', amount = 1 },
            { name = 'flour', amount = 1 },
        },
        outputMultiplier = 1, -- 完成品の数量の倍率
        progressBarDuration = 5000, -- ミリ秒
        animDict = 'anim@amb@business@weed@weed_inspecting_lo_med_hi@',
        anim = 'weed_crouch_checkingleaves_idle_01_inspector',
        flags = 1,
        label = '料理を作る'
    },
    -- 他のタイプ（drink, stress, normal）も同様に設定可能
}
```

各アイテムタイプには以下の設定が可能です：
- `requiredItems`: クラフトに必要なアイテムとその数量
- `outputMultiplier`: 完成品の数量倍率
- `progressBarDuration`: クラフト時のプログレスバーの長さ（ミリ秒）
- `animDict`: クラフト時のアニメーション辞書
- `anim`: クラフト時のアニメーション名
- `flags`: アニメーションのフラグ（1=ループ、8=上半身のみ、16=通常）
- `label`: プログレスバーに表示されるテキスト

## アイテム命名規則

このスクリプトは以下の2つの命名規則に対応しています：

1. `job_アイテム名` の形式（例: `job_police_badge`）
2. `ジョブ名_アイテム名` の形式（例: `catcafe_test`）

いずれの場合も、ジョブ名に一致するプレイヤーのみが、そのアイテムをクラフトできます。

例えば：
- `job_police_badge` または `police_badge` というアイテムは、`police` ジョブを持つプレイヤーのみがクラフト可能
- `catcafe_test` というアイテムは、`catcafe` ジョブを持つプレイヤーのみがクラフト可能

## アイテムタイプの自動検出

スクリプトはox_inventoryのアイテム情報から以下のルールに基づいてアイテムタイプを自動検出します：

- `client.status.hunger` が設定されている場合 → `food`
- `client.status.thirst` が設定されている場合 → `drink`
- `client.status.stress` が設定されている場合 → `stress`
- 上記のいずれにも該当しない場合 → `normal`

## コマンド

- `/refreshcrafting` - サーバー管理者用コマンド。ox_inventoryのアイテムリストを再スキャンして、クラフト可能アイテムリストを更新します。
- `/craft_reload_items` - アイテムリストを強制的に再ロードします。アイテムが表示されない場合に使用します。
- `/craft_request` - 現在のジョブに対してクラフト可能なアイテムを再要求します。アイテムが表示されない場合に使用します。
- `/recreate_props` - クラフトテーブルの3Dモデルを再生成します。プロップが見えない場合に使用します。
- `/reset_craft_zones` - ターゲットゾーンを再設定します。クラフトテーブルとのインタラクションができない場合に使用します。

## デバッグ

`Config.Debug = true` に設定することで、詳細なデバッグ情報がサーバーコンソールに出力されます。
また、クライアントサイドでは `/craftdebug` コマンドを使用して現在のジョブとクラフト可能アイテムを確認できます。

## 調理用プロップとアニメーション

### おすすめの調理用プロップ
```
v_res_tre_cooker      -- ガスコンロ
prop_griddle_01       -- 鉄板/グリドル
prop_foodprep1        -- 調理準備台
prop_coffee_mac_02    -- コーヒーマシン
v_res_fa_potrack      -- 調理器具ラック
v_res_cakedome        -- ケーキドーム
prop_bar_caddy        -- バーキャディ
v_res_m_woodbowl      -- 木製ボウル
prop_cs_plate_01      -- 皿
```

### おすすめの調理用アニメーション
```
anim@amb@business@weed@weed_inspecting_lo_med_hi@/weed_crouch_checkingleaves_idle_01_inspector
anim@amb@clubhouse@bar@drink@one/one_bartender
mini@drinking/shots_barman_b
misscarsteal4@aliens/rehearsal_base_idle_director
```

## トラブルシューティング

1. **アイテムが検出されない場合**
   - ox_inventoryのバージョンを確認
   - アイテム名が正しい形式（`ジョブ名_アイテム名`または`job_ジョブ名_アイテム名`）か確認
   - `/refreshcrafting`コマンドを実行してアイテムリストを更新
   - サーバーコンソールのログでエラーがないか確認

2. **クラフトができない場合**
   - 必要なアイテムをすべて所持しているか確認
   - プレイヤーのジョブがアイテム名プレフィックスと一致するか確認
   - `/craft_request`コマンドを実行してアイテムリストを再要求

3. **プロップが表示されない場合**
   - プロップモデル名が正しいか確認
   - offsetの値を調整（プロップが地面に埋まっている可能性）
   - プロップが地形や建物と衝突していないか確認
   - `/recreate_props`コマンドを実行してプロップを再生成

4. **クラフトテーブルとインタラクションできない場合**
   - サーバー参加直後はシステムの読み込みに少し時間がかかることがあります
   - `/reset_craft_zones`コマンドを実行してターゲットゾーンを再設定
   - ox_targetが正しく機能しているか確認
   - テーブル付近にいることを確認（半径内に入っているか）

5. **クラフト後にメニューが消えて再表示されない場合**
   - 仕様通りの動作です。再度クラフトするには再びクラフトテーブルとインタラクションしてください。

## 更新情報

### バージョン 1.0.0
- 初回リリース

## クレジット

- NCCGr: スクリプト開発