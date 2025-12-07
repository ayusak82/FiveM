Config = {}

-- 上部テキストの設定を追加
Config.TopText = {
    maxLength = 100, -- 上部テキストの最大長
    minLength = 0,  -- 上部テキストの最小長
    enabled = true, -- デフォルトで有効かどうか
    height = 0.07,   -- 名前との距離（上方向）
    -- テキストの色 (RGBA)
    color = {
        r = 255,
        g = 255,
        b = 255,
        a = 255
    },
}

-- 初心者マークの設定を追加
Config.BeginnerMark = {
    enabled = false,
    icon = '🔰',  -- 初心者マーク
    maxPlayTime = 720,  -- 初心者とみなす最大プレイ時間（分）12時間
    color = {
        r = 255,
        g = 215,
        b = 0,
        a = 255
    }
}

Config.StreamerMode = {
    enabled = false,
    icon = '🛰'
}

Config.Nickname = {
    maxLength = 100,
    minLength = 0,
}

Config.Display = {
    distance = 5.0,
    scale = 0.3,
    height = 1.0,
    font = 0,
    color = {
        r = 255,
        g = 255,
        b = 255,
        a = 255
    },
}

Config.Command = 'name'
Config.DefaultVisibility = true

Config.UI = {
    position = 'left-center'  -- 'right-center'から'left-center'に変更
}

Config.NameFormat = "{firstname} {lastname}"