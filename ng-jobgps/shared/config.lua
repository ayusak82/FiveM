Config = {}

-- ジョブ関連の設定
Config.Jobs = {
    police = {
        blipColor = 3,    -- 青色
        blipSprite = 1,   -- 通常の円形ブリップ
        blipScale = 0.8,  -- ブリップのサイズ
        blipAlpha = 255,  -- 不透明度 (完全に表示)
        blipName = "警察官",
        vehicleBlipSprite = 56,    -- 車両用のブリップスプライト
        heliBlipSprite = 43,       -- ヘリコプター用のブリップスプライト
        boatBlipSprite = 427,      -- ボート用のブリップスプライト
        planeBlipSprite = 307,     -- 飛行機用のブリップスプライト
        deadBlipSprite = 303,      -- 死亡時のブリップスプライト
    },
    ambulance = {
        blipColor = 5,    -- 黄色
        blipSprite = 1,   -- 通常の円形ブリップ
        blipScale = 0.8,  -- ブリップのサイズ
        blipAlpha = 255,  -- 不透明度 (完全に表示)
        blipName = "救急隊員",
        vehicleBlipSprite = 56,    -- 車両用のブリップスプライト
        heliBlipSprite = 43,       -- ヘリコプター用のブリップスプライト
        boatBlipSprite = 427,      -- ボート用のブリップスプライト
        planeBlipSprite = 307,     -- 飛行機用のブリップスプライト
        deadBlipSprite = 303,      -- 死亡時のブリップスプライト
    }
}

-- 表示設定
Config.DisplayOptions = {
    refreshRate = 500,   -- GPSの更新頻度（ミリ秒）
    showPlayerNames = true, -- プレイヤー名を表示するかどうか
    showOnMinimap = true,  -- ミニマップに表示するかどうか
    showOnBigmap = true    -- 大きなマップに表示するかどうか
}

-- UIメニュー設定
Config.UIMenu = {
    title = "Job GPS",
    position = 'middle', -- ox_libのメニュー位置
    toggleCommand = "jobtoggle", -- GPS表示切り替えコマンド
}

-- 権限設定（どのジョブがどのジョブを見られるか）
Config.Permissions = {
    police = {"police", "ambulance"}, -- 警察は警察と救急隊を見られる
    ambulance = {"police", "ambulance"} -- 救急隊は警察と救急隊を見られる
}