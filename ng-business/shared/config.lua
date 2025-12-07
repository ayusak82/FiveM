Config = {}

-- Debug mode (outputs in English)
Config.Debug = false

-- ============================================
-- NOTE: All stashes, trays, crafting stations, lockers, and blips
-- are managed in-game using /businessadmin command.
-- Data is stored in the database and loaded automatically.
-- ============================================

-- ============================================
-- UI CONFIGURATION
-- ============================================
Config.UI = {
    -- Marker settings
    marker = {
        type = 1,           -- Marker type (1 = vertical cylinder)
        size = {x = 1.0, y = 1.0, z = 1.0},
        color = {r = 0, g = 255, b = 0, a = 100},
        bobUpAndDown = false,
        faceCamera = false,
        rotate = false,
        drawOnEnts = false
    },
    
    -- Interaction distance
    interactionDistance = 2.0,
    
    -- Notification duration
    notificationDuration = 5000,
}

-- ============================================
-- INTERACTION KEY
-- ============================================
Config.InteractionKey = 38  -- E key

-- ============================================
-- TARGET SYSTEM
-- ============================================
Config.Target = "ox_target"  -- "ox_target" or "qb-target"

-- ============================================
-- INTERACTION TYPE
-- ============================================
Config.InteractionType = "target"  -- "target" or "marker"

-- ============================================
-- LASER SYSTEM (ng-laser integration)
-- ============================================
Config.Laser = {
    -- レーザーの色 (R, G, B, A)
    color = {255, 0, 0, 255}, -- 赤色
    
    -- レーザーの最大距離
    maxDistance = 100.0,
    
    -- レーザーの更新頻度（ミリ秒）
    updateInterval = 0,
    
    -- レーザーを表示するコマンド
    toggleCommand = 'laser',
    
    -- 座標を設定するキー（レーザー表示中のみ）
    setCoordKey = 'E',
    
    -- レーザーを使用可能にする
    enabled = true
}
