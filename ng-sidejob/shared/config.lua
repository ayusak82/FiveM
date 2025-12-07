Config = {}

-- 内職場所の座標
Config.JobLocations = {
    {
        coords = vector3(1274.5, -1710.5, 54.77), -- 例：工場エリア
        heading = 90.0,
        label = "内職受付"
    },
    -- 必要に応じて追加可能
}

-- ミニゲーム設定
Config.Minigames = {
    typing = {
        name = "データ入力作業",
        description = "表示された文字列を正確に入力してください",
        difficulty = "簡単",
        timeLimit = 30, -- 秒
        reward = {min = 100, max = 300}, -- 報酬範囲
        icon = "keyboard"
    },
    color = {
        name = "部品検品作業",
        description = "指定された色のボックスを順番にクリックしてください",
        difficulty = "普通",
        timeLimit = 25,
        reward = {min = 150, max = 350},
        icon = "palette"
    },
    memory = {
        name = "在庫確認作業",
        description = "表示されたアイテムを記憶してください",
        difficulty = "普通",
        timeLimit = 20,
        reward = {min = 200, max = 400},
        icon = "brain"
    },
    rhythm = {
        name = "組み立て作業",
        description = "タイミングに合わせてキーを押してください",
        difficulty = "普通",
        timeLimit = 30,
        reward = {min = 180, max = 380},
        icon = "music"
    },
    puzzle = {
        name = "梱包作業",
        description = "ブロックを配置してラインを消してください",
        difficulty = "難しい",
        timeLimit = 60,
        reward = {min = 250, max = 500},
        icon = "box"
    },
    racing = {
        name = "配達作業",
        description = "障害物を避けてゴールを目指してください",
        difficulty = "普通",
        timeLimit = 45,
        reward = {min = 200, max = 450},
        icon = "car"
    }
}

-- クールダウン設定（秒）
Config.Cooldown = 0 -- 0分

-- デバッグモード
Config.Debug = false

-- 通知設定
Config.Notifications = {
    success = {
        title = "内職完了",
        description = "報酬を受け取りました",
        type = "success"
    },
    failed = {
        title = "内職失敗",
        description = "もう一度挑戦してください",
        type = "error"
    },
    cooldown = {
        title = "クールダウン中",
        description = "しばらく待ってから再度お試しください",
        type = "info"
    }
}

-- マーカー設定
Config.Marker = {
    type = 20,
    scale = {x = 0.3, y = 0.3, z = 0.3},
    color = {r = 0, g = 255, b = 0, a = 100},
    bobUpAndDown = true,
    faceCamera = true,
    rotate = true
}

-- インタラクション距離
Config.InteractDistance = 2.0
