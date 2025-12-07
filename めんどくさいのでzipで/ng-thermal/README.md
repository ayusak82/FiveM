# ng-thermal

## 概要
`ng-thermal`は、GTA5 FiveM用のスクリプトで、特定のアイテムを使用することでプレイヤーがサーマルビジョンから一時的に隠れることができるようになります。主にサーマルスコープを装備した警察ヘリコプターなどからの視認を防ぐために使用できます。

## 機能
- 特定のアイテム（デフォルト: `thermal_blocker`）を使用すると、プレイヤーは一定時間サーマルビジョンから見えなくなります
- 効果の持続時間は設定ファイルで変更可能（デフォルト: 300秒）
- 効果中はUI通知で確認可能
- アイテム使用時にカスタムアニメーション再生
- 管理者用のテストコマンドを提供
- 特定のジョブのみがアイテムを使用できるように制限可能

## 依存関係
- [qb-core](https://github.com/qbcore-framework/qb-core)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_inventory](https://github.com/overextended/ox_inventory)

## インストール方法
1. このリポジトリをダウンロードし、`ng-thermal`フォルダをサーバーの`resources`ディレクトリに配置します
2. `ox_inventory`のアイテム定義に`thermal_blocker`アイテムを追加します:
   - `ox_inventory/data/items`ディレクトリに`thermal_blocker.lua`を作成するか
   - 既存の`items.lua`に定義を追加
3. サーバーの`server.cfg`に以下の行を追加します:
   ```
   ensure ng-thermal
   ```
4. サーバーを再起動するか、`ng-thermal`リソースを起動します

## アイテム定義
以下は`ox_inventory`用のアイテム定義です：
```lua
return {
    ['thermal_blocker'] = {
        label = 'サーマル遮断薬',
        weight = 25,
        stack = true,
        close = true,
        description = 'サーマルカメラから一時的に姿を隠すことができる特殊な薬物。',
        client = {
            export = 'ng-thermal.thermal_blocker',
            anim = { dict = 'mp_suicide', clip = 'pill' },
            usetime = 2500,
            cancel = true,
        }
    }
}
```

## 設定オプション
`config.lua`ファイルで以下の設定を変更できます：

| 設定項目 | 説明 | デフォルト値 |
|---|---|---|
| `Config.EffectDuration` | 効果の持続時間（秒） | 300 |
| `Config.ItemName` | 使用するアイテムの名前 | 'thermal_blocker' |
| `Config.EmoteDictionary` | 使用時のアニメーション辞書 | 'mp_suicide' |
| `Config.EmoteName` | 使用時のアニメーション名 | 'pill' |
| `Config.AdminCommand` | 管理者用テストコマンド | 'thermal_test' |
| `Config.RestrictedJobs` | アイテム使用可能なジョブ（空で制限なし） | {} |
| `Config.Debug` | デバッグモード有効/無効 | false |

## 管理者用コマンド
管理者権限を持つプレイヤーは、以下のコマンドを使用してサーマル遮断機能をテストできます：
```
/thermal_test
```
このコマンドを実行すると、サーマル遮断効果のオン/オフが切り替わります。

## 注意事項
- スクリプトが機能するためには、プレイヤーが`thermal_blocker`アイテムを所持している必要があります
- サーマル遮断効果は、プレイヤーの周囲の物体や他のプレイヤーには影響しません
- 効果はリソースの再起動やプレイヤーの切断時にリセットされます

## バグ報告
バグや提案があれば、リポジトリのIssuesセクションに報告してください。

## ライセンス
このスクリプトは自由に使用・改変・再配布が可能です。商用利用の場合は作者に連絡してください。