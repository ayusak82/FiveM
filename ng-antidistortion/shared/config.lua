Config = {}

-- コマンド設定
Config.Command = 'fd' -- コマンド名

-- クールダウン設定
Config.Cooldown = 30 -- クールダウン時間（秒）

-- テレポート設定
Config.OceanCoords = vector4(4500.0, 8000.0, 0.0, 0.0) -- 海の座標（遠くの海）
Config.WaitTime = 3000 -- 海での待機時間（ミリ秒） 3秒 = 3000ms

-- 画面エフェクト設定
Config.UseFade = true -- フェードアウト/インを使用するか
Config.FadeTime = 1000 -- フェード時間（ミリ秒）

-- 無敵設定
Config.GodMode = true -- TP中に無敵状態にするか

-- 通知設定
Config.Notifications = {
    inVehicle = {
        title = 'ゆがみ対策',
        description = '車両に乗っている時は使用できません',
        type = 'error',
        duration = 3000
    },
    cooldown = {
        title = 'ゆがみ対策',
        description = 'クールダウン中です。あと %s 秒お待ちください',
        type = 'error',
        duration = 3000
    },
    executing = {
        title = 'ゆがみ対策',
        description = 'ゆがみ対策を実行中...',
        type = 'info',
        duration = 3000
    },
    complete = {
        title = 'ゆがみ対策',
        description = 'ゆがみ対策が完了しました',
        type = 'success',
        duration = 3000
    }
}