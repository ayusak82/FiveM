Config = {}

-- URLのベース設定
Config.BaseUrl = 'https://sound1.dlup.by/uploads/' -- サウンドファイルが置かれているURLに変更してください

Config.Items = {
    ['sample_b'] = {
        url = '89a4b988.mp3', -- 音声ファイルのパス（Config.BaseUrlと組み合わされます）
        volume = 0.8, -- 音量 (0.0 ~ 1.0)
        maxDistance = 10.0, -- 音声が聞こえる最大距離
        soundDelay = 3000, -- 音声再生までの遅延時間（ミリ秒）
        loop = false, -- ループ再生するかどうか
        removeAfterUse = true, -- 使用後にアイテムを削除するかどうか
        animation = {
            dict = 'mp_suicide', -- アニメーション辞書
            anim = 'pill', -- アニメーション名
            flag = 49, -- アニメーションフラグ
            duration = 2800 -- アニメーション時間（ミリ秒）
        },
        effect = {
            type = 'suicide', -- 'suicide' または 'fire' または false
            delay = 3000, -- エフェクトが発動するまでの遅延時間（ミリ秒）
            duration = 10000 -- fireの場合の継続時間（ミリ秒）
        },
        recovery = {
            health = 0, -- 回復するHP量(マイナス可能)
            armour = 0, -- 回復するアーマー量(マイナス可能)
            food = 0, -- 回復する食料量(マイナス可能)
            water = 0, -- 回復する水分量(マイナス可能)
            time = 5000, -- 回復までの時間（ミリ秒）
            isInstant = true, -- true: 即時回復, false: 徐々に回復
            gradualTick = 500 -- 徐々に回復する場合の間隔（ミリ秒）
        }
    },
    -- 追加のアイテムはここに記述
    -- ['item_name'] = {
    --     url = 'sound.mp3',
    --     volume = 0.5,
    --     maxDistance = 10.0,
    --     loop = false,
    --     removeAfterUse = true
    -- }
}