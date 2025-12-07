# ng-laser - ビジュアルレーザー座標取得システム

FiveM用のビジュアルレーザー座標取得システムです。レーザーポインターを使用して、ゲーム内の任意の場所の座標を簡単に取得できます。

## 特徴

- 視覚的なレーザーポインター表示
- リアルタイムで座標を取得
- ワンキーで座標をクリップボードにコピー
- 権限管理機能（管理者専用 / ジョブ制限）
- カスタマイズ可能な設定

## 作者情報

- **作者**: NCCGr
- **問い合わせ先**: Discord: ayusak
- **バージョン**: 1.0.0

## 依存関係

以下のリソースが必要です：

- [qb-core](https://github.com/qbcore-framework/qb-core) - QBCoreフレームワーク
- [ox_lib](https://github.com/overextended/ox_lib) - UIライブラリ

## インストール方法

1. `ng-laser` フォルダをサーバーの `resources` ディレクトリに配置
2. `server.cfg` に以下を追加：
```cfg
ensure qb-core
ensure ox_lib
ensure ng-laser
```
3. サーバーを再起動

## 使用方法

### 基本操作

1. ゲーム内でコマンドを実行：`/laser`
2. レーザーが起動し、視点の先にレーザーが表示されます
3. 座標を取得したい場所にレーザーを向けます
4. `E` キーを押すと座標がクリップボードにコピーされます
5. 再度 `/laser` コマンドでレーザーを停止

### コピーされる座標形式

```lua
vector3(123.45, -456.78, 90.12)
```

この形式でクリップボードにコピーされるため、そのままLuaコードに貼り付けて使用できます。

## 設定

`shared/config.lua` で以下の設定をカスタマイズできます：

### 権限設定
```lua
Config.Permission = {
    adminOnly = false,           -- 管理者のみ使用可能にする
    allowedJobs = {},            -- 使用可能なジョブ（例: {'police', 'ambulance'}）
    minGrade = 0                 -- 最低必要なジョブグレード
}
```

### レーザー設定
```lua
Config.Laser = {
    toggleCommand = 'laser',     -- 切り替えコマンド
    copyKey = 'E',              -- 座標コピーキー
    maxDistance = 1000.0,       -- レーザーの最大距離
    updateInterval = 0,         -- 更新間隔（ミリ秒）
    color = {255, 0, 0, 255}   -- レーザーの色（RGBA）
}
```

### UI設定
```lua
Config.UI = {
    notificationDuration = 3000, -- 通知表示時間（ミリ秒）
    coordinateDecimals = 2       -- 座標の小数点以下桁数
}
```

## 権限設定例

### 管理者のみ使用可能
```lua
Config.Permission = {
    adminOnly = true,
    allowedJobs = {},
    minGrade = 0
}
```

### 警察とEMSのみ使用可能
```lua
Config.Permission = {
    adminOnly = false,
    allowedJobs = {'police', 'ambulance'},
    minGrade = 2  -- グレード2以上
}
```

### 全員使用可能
```lua
Config.Permission = {
    adminOnly = false,
    allowedJobs = {},
    minGrade = 0
}
```

## トラブルシューティング

### レーザーが表示されない
- 権限設定を確認してください
- F8コンソールでエラーメッセージを確認してください

### 座標がコピーされない
- `E` キーがレーザー起動中に押されているか確認してください
- 他のスクリプトとキーバインドが競合していないか確認してください

### 依存関係エラー
- `qb-core` と `ox_lib` が正しくインストールされているか確認してください
- `server.cfg` で依存関係が `ng-laser` より前に読み込まれているか確認してください

## デバッグモード

`shared/config.lua` で `Config.Debug = true` に設定すると、コンソールに詳細なログが出力されます。

## ライセンス

このスクリプトは販売用です。無断での再配布や改変は禁止されています。

## サポート

問題や質問がある場合は、Discord: ayusak までお問い合わせください。
