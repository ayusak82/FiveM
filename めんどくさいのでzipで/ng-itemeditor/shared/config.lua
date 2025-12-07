Config = {}

-- 基本設定
Config.Command = 'itemeditor' -- コマンド名
Config.AcePermission = 'ng.itemeditor' -- ACE権限名

-- アニメーション辞書のリスト
Config.AnimationDicts = {
    'mp_suicide',
    'mp_player_inteat@burger',
    'mp_player_intdrink',
    'amb@world_human_drinking@coffee@male@idle_a'
}

-- エフェクトタイプのリスト
Config.EffectTypes = {
    { value = 'none', label = 'なし' },
    { value = 'suicide', label = '即死' },
    { value = 'fire', label = '炎上' }
}

-- デフォルトの設定テンプレート
Config.DefaultTemplate = {
    sound = {
        url = '', -- サウンドファイルのURL
        volume = 0.3, -- 音量 (0.0 ~ 1.0)
        maxDistance = 10.0, -- 音声が聞こえる最大距離
        soundDelay = 0, -- 音声再生までの遅延時間（ミリ秒）
        loop = false -- ループ再生するかどうか
    },
    animation = {
        dict = 'mp_player_inteat@burger',
        anim = 'mp_player_int_eat_burger',
        flag = 49,
        duration = 2800
    },
    effect = {
        type = 'none',
        delay = 0,
        duration = 0
    },
    recovery = {
        health = 0,
        armour = 0,
        food = 0,
        water = 0,
        time = 0,
        isInstant = true,
        gradualTick = 500
    },
    removeAfterUse = true
}

-- UIのカラーテーマ
Config.Theme = {
    primary = '#3b82f6',
    secondary = '#1d4ed8',
    background = '#1f2937',
    text = '#ffffff'
}

-- データベースのテーブル名
Config.DatabaseTable = 'ng_itemeffects'