Config = {}

-- 懲罰場所の座標
Config.PunishmentLocation = vector4(-261.53, 6553.72, 2.88, 137.84) -- x, y, z, heading

-- 爆発の設定
Config.Explosion = {
    type = 2, -- 爆発タイプ (2 = グレネード、29 = RPG など)
    damageScale = 1.0, -- ダメージ倍率
    isAudible = true, -- 音を鳴らすか
    isInvisible = false, -- 見えなくするか
    interval = 1 -- 爆発の間隔（ミリ秒）
}

-- 蘇生までの待機時間（ミリ秒）
Config.RespawnDelay = 3000 -- 3秒

-- 開始コマンド
Config.StartCommand = 'hellstart'

-- 終了コマンド
Config.StopCommand = 'hellstop'

-- デバッグモード
Config.Debug = true

-- 通知設定
Config.Notifications = {
    punishmentStarted = '懲罰が開始されました',
    punishmentStopped = '懲罰が終了しました',
    targetNotFound = 'プレイヤーが見つかりません',
    noPermission = 'この操作を実行する権限がありません',
    alreadyInPunishment = 'このプレイヤーは既に懲罰中です',
    notInPunishment = 'このプレイヤーは懲罰中ではありません'
}