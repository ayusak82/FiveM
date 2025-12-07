Config = {}

-- ポータルの設定
Config.Portals = {
    {
        id = 1,
        name = "緊急ポータル",
        -- ポータル位置
        portalPos = vector3(321.1, -584.17, 42.28),
        -- テレポート先
        teleportPos = vector4(309.5, -595.55, 43.28, 67.84),
        -- 制限するジョブ（このジョブのプレイヤーがいる場合は機能しない）
        restrictedJobs = {"ambulance"},
        -- マーカー設定
        marker = {
            type = 1,
            color = {r = 0, g = 255, b = 255, a = 150},
            size = vector3(2.0, 2.0, 1.0),
            bobUpAndDown = false,
            faceCamera = false,
            rotate = true
        },
        -- 有効範囲
        interactDistance = 3.0
    },
}

-- 一般設定
Config.Settings = {
    -- デバッグモード
    debug = false,
    -- テレポート時のフェード効果
    fadeScreen = true,
    -- フェード時間（ミリ秒）
    fadeTime = 1000,
    -- 通知の表示時間（ミリ秒）
    notificationTime = 3000,
    -- ポータル使用のクールダウン時間（秒）
    cooldownTime = 5
}

-- 言語設定
Config.Locale = {
    ["portal_restricted"] = "このポータルは現在使用できません（制限されたジョブのプレイヤーがオンラインです）",
    ["portal_cooldown"] = "ポータルのクールダウン中です。あと %s 秒お待ちください",
    ["portal_teleport"] = "%s を使用してテレポートしました",
    ["press_to_teleport"] = "[E] %s を使用",
    ["teleporting"] = "テレポート中..."
}