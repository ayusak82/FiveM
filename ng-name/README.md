# ng-name

## 概要
このスクリプトは、FiveM用のプレイヤー名前表示カスタマイズスクリプトです。
プレイヤーの頭上に表示される名前をカスタマイズすることができ、ニックネーム、上部テキスト、配信者モード、初心者マーク、色設定などの豊富な機能を提供します。

⚠️ このスクリプトは有料スクリプトです。再配布や無許可での使用は禁止されています。

## 依存関係
- qb-core
- ox_lib
- oxmysql

## 機能一覧

### 基本機能
- **名前の表示/非表示切替**: 自分の名前を他プレイヤーから見えないようにできます
- **ニックネームシステム**: 本名とは別のニックネームを設定・表示できます
- **上部テキスト**: 名前の上に追加のテキストを表示できます
- **配信者モード**: 配信中であることを示すアイコンを表示できます
- **初心者マーク**: 初心者プレイヤーであることを示すマークを表示できます

### 色設定機能
- **名前の色カスタマイズ**: RGB値で名前の文字色を自由に変更できます
- **上部テキストの色カスタマイズ**: 上部テキストの文字色を個別に設定できます
- **色のリセット機能**: カスタム色をデフォルトに戻すことができます

### 特殊機能
- **マーク優先表示**: 名前を非表示にしても配信者マークと初心者マークは表示されます
- **プレイ時間自動判定**: 設定時間未満のプレイヤーを自動で初心者として判定します
- **リアルタイム同期**: 設定変更は即座に他のプレイヤーに反映されます

## 使用方法

### メニューの開き方
```
/name
```

### メニュー項目説明

#### 基本設定
- **表示設定**: 自分の名前の表示/非表示を切り替え
- **配信者モード**: 配信者アイコン（🛰）の表示/非表示を設定
- **初心者マーク**: 初心者マーク（🔰）の表示/非表示を設定

#### テキスト設定
- **ニックネーム設定**: ニックネームを入力（0-100文字）
- **ニックネーム表示切替**: ニックネームと本名の表示を切り替え
- **上部テキスト設定**: 名前の上に表示するテキストを入力（0-100文字）
- **上部テキスト表示切替**: 上部テキストの表示/非表示を切り替え

#### 色設定
- **名前の色設定**: カラーピッカーで名前の色をカスタマイズ
- **名前色リセット**: 名前の色をデフォルト（白）に戻す
- **上部テキストの色設定**: カラーピッカーで上部テキストの色をカスタマイズ
- **上部テキスト色リセット**: 上部テキストの色をデフォルト（白）に戻す

### 色設定の使い方
1. メニューから「名前の色設定」または「上部テキストの色設定」を選択
2. カラーピッカーが表示されるので、好みの色を選択
3. 色はHEX形式（#RRGGBB）で入力可能
4. 設定は自動保存され、他のプレイヤーにも即座に反映

### 表示の優先順位
1. **名前表示ON**: 名前 + マーク + 上部テキスト すべて表示
2. **名前表示OFF + マークON**: マークのみ表示（重要な情報は維持）
3. **名前表示OFF + マークOFF**: 何も表示されない

## 他のスクリプトからの利用方法

### メニューを開く
```lua
-- クライアントサイドでメニューを開く
TriggerEvent('ng-name:client:openMenu')
```

### コマンド例
```lua
-- スクリプト例
RegisterCommand('namemenu', function()
    TriggerEvent('ng-name:client:openMenu')
end)
```

## 設定項目（config.lua）

### 基本表示設定
- `Config.Display.distance`: 名前表示距離（デフォルト: 15.0）
- `Config.Display.scale`: 文字サイズ（デフォルト: 0.3）
- `Config.Display.height`: 表示高さ（デフォルト: 1.0）
- `Config.Display.font`: フォント番号（デフォルト: 0）

### 色設定
- `Config.Display.color`: 名前のデフォルト色（RGBA）
- `Config.TopText.color`: 上部テキストのデフォルト色（RGBA）

### 機能設定
- `Config.BeginnerMark.maxPlayTime`: 初心者判定の最大プレイ時間（分）
- `Config.BeginnerMark.icon`: 初心者マークのアイコン
- `Config.StreamerMode.icon`: 配信者モードのアイコン

### 文字数制限
- `Config.Nickname.maxLength`: ニックネームの最大文字数
- `Config.TopText.maxLength`: 上部テキストの最大文字数

### UI設定
- `Config.UI.position`: メニュー表示位置（デフォルト: 'left-center'）
- `Config.Command`: メニューを開くコマンド名（デフォルト: 'name'）

## データベーステーブル

スクリプトは以下のテーブルを自動作成します：
```sql
nameplate_settings (
    citizenid VARCHAR(50) PRIMARY KEY,
    visibility BOOLEAN,
    streamer_mode BOOLEAN,
    nickname VARCHAR(100),
    use_nickname BOOLEAN,
    top_text VARCHAR(100),
    use_top_text BOOLEAN,
    show_beginner_mark BOOLEAN,
    name_color_r INT,
    name_color_g INT,
    name_color_b INT,
    name_color_a INT,
    use_custom_name_color BOOLEAN,
    top_text_color_r INT,
    top_text_color_g INT,
    top_text_color_b INT,
    top_text_color_a INT,
    use_custom_top_text_color BOOLEAN,
    updated_at TIMESTAMP
)
```

## 注意事項
- 本スクリプトの無断転載・再配布は禁止されています
- ライセンスキーの共有は禁止されています
- 色設定はHEX形式（#RRGGBB）で入力してください
- 初心者マークは設定したプレイ時間を超えると自動で非表示になります
- すべての設定はデータベースに保存され、リログ後も維持されます
- サポートはDiscordでのみ提供されます

## サポート情報
- **Discord**: ayusak

## クレジット
作成者: NCCGr

© 2025 NCCGr All Rights Reserved.