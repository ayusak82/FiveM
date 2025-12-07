# ng-recyclebuy - リサイクルセンター

リサイクル可能なアイテムを買い取るNPCシステム

## 作者情報
- **作者**: NCCGr
- **問い合わせ**: Discord - ayusak

## 機能
- ✅ リサイクルセンターNPCの配置
- ✅ マップにブリップ表示
- ✅ リサイクル可能なアイテムの買取
- ✅ 買取時のアニメーション演出
- ✅ ox_libを使用した直感的なUI
- ✅ 現金での支払い
- ✅ 複数の場所に設置可能
- ✅ 完全にカスタマイズ可能な設定

## 依存関係
以下のリソースが必要です：
- [qb-core](https://github.com/qbcore-framework/qb-core)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [okokNotify](https://okok.tebex.io/package/4724993)

## インストール方法

1. `ng-recyclebuy` フォルダをサーバーの `resources` フォルダに配置
2. `server.cfg` に以下を追加：
```cfg
ensure qb-core
ensure ox_lib
ensure ox_inventory
ensure okokNotify
ensure ng-recyclebuy
```
3. サーバーを再起動

## 設定方法

`shared/config.lua` で以下の設定が可能です：

### リサイクルセンターの場所
```lua
Config.RecycleLocations = {
    {
        coords = vector4(-470.75, -1718.14, 18.69, 287.91),
        blip = {
            enabled = true,
            sprite = 566,
            color = 2,
            scale = 0.8,
            label = 'リサイクルセンター'
        },
        ped = {
            model = 's_m_y_garbage',
            scenario = 'WORLD_HUMAN_CLIPBOARD'
        }
    },
}
```

### 買取アイテムと価格
```lua
Config.RecycleItems = {
    ['plastic'] = 5,
    ['metalscrap'] = 8,
    ['copper'] = 10,
    -- 追加のアイテムをここに設定
}
```

### インタラクション設定
```lua
Config.Interaction = {
    distance = 2.5,        -- NPCとの対話可能距離
    useTarget = false,     -- ox_targetを使用する場合はtrue
    key = 38,              -- Eキー
}
```

## 使用方法

1. マップ上のリサイクルセンターのブリップを確認
2. NPCに近づいて **[E]** キーを押す（またはox_targetで対話）
3. 売却したいアイテムを選択
4. 売却数量を入力
5. アニメーションが再生され、現金を受け取る

## カスタマイズ

### 新しい場所を追加
`Config.RecycleLocations` に新しいエントリを追加：
```lua
{
    coords = vector4(x, y, z, heading),
    blip = { ... },
    ped = { ... }
}
```

### 買取アイテムを追加
`Config.RecycleItems` に新しいアイテムを追加：
```lua
['item_name'] = price,
```

### NPCモデルを変更
`ped.model` を変更：
- `s_m_y_garbage` - ゴミ収集作業員
- `s_m_m_dockwork_01` - 港湾労働者
- `s_m_y_construct_01` - 建設作業員
- その他のPedモデル

### ブリップアイコンを変更
`blip.sprite` を変更（[ブリップ一覧](https://docs.fivem.net/docs/game-references/blips/)）

## トラブルシューティング

### NPCが表示されない
- サーバーコンソールでエラーを確認
- `Config.Debug = true` に設定してデバッグログを確認

### アイテムが売却できない
- アイテム名が `Config.RecycleItems` に正しく設定されているか確認
- ox_inventoryが正しく動作しているか確認

### ブリップが表示されない
- `blip.enabled = true` になっているか確認
- サーバーを再起動

## ライセンス
このスクリプトは販売用です。無断での再配布・転売を禁止します。

## サポート
問題が発生した場合は、Discord: **ayusak** までお問い合わせください。

---

**Version**: 1.0.0  
**Last Updated**: 2025
