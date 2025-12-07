Config = {}

-- デバッグモード
Config.Debug = false
Config.TestMode = true

-- キャンプアイテムの設定
Config.CampingItems = {
    tent = {
        item = 'camping_tent',
        label = 'テント',
        model = 'prop_gazebo_02',
        price = 500,
        health = 100
    },
    chair = {
        item = 'camping_chair',
        label = 'キャンプチェア',
        model = 'prop_skid_chair_01',
        price = 150,
        health = 100
    },
    campfire = {
        item = 'camping_fire',
        label = '焚火',
        model = 'prop_beach_fire',
        price = 200,
        health = 100
    }
}

-- 設置制限
Config.PlacementLimits = {
    maxDistance = 50.0,        -- 最大設置距離
    minPlayerDistance = 2.0,   -- プレイヤー間最小距離
    maxItemsPerPlayer = 10,    -- プレイヤー毎の最大設置数
    checkGround = true,        -- 地面チェック
    allowedZones = {},         -- 許可エリア（空の場合は全エリア許可）
    blockedZones = {           -- 禁止エリア
        vector3(-1037.77, -2738.41, 20.17), -- 空港
        vector3(461.0, -992.0, 30.69),      -- 病院
    }
}

-- ox_target設定
Config.TargetOptions = {
    tent = {
        {
            name = 'ng_camping_tent_enter',
            icon = 'fas fa-sign-in-alt',
            label = 'テントに入る',
            action = function(entity)
                TriggerEvent('ng-camping:client:enterTent', entity)
            end,
        },
        {
            name = 'ng_camping_tent_remove',
            icon = 'fas fa-trash',
            label = 'テントを撤去',
            action = function(entity)
                TriggerEvent('ng-camping:client:removeItem', entity, 'tent')
            end,
        },
    },
    chair = {
        {
            name = 'ng_camping_chair_sit',
            icon = 'fas fa-chair',
            label = '座る',
            action = function(entity)
                TriggerEvent('ng-camping:client:sitOnChair', entity)
            end,
        },
        {
            name = 'ng_camping_chair_remove',
            icon = 'fas fa-trash',
            label = '椅子を撤去',
            action = function(entity)
                TriggerEvent('ng-camping:client:removeItem', entity, 'chair')
            end,
        },
    },
    campfire = {
        {
            name = 'ng_camping_fire_cook',
            icon = 'fas fa-fire',
            label = '料理する',
            action = function(entity)
                TriggerEvent('ng-camping:client:cookFood', entity)
            end,
        },
        {
            name = 'ng_camping_fire_remove',
            icon = 'fas fa-trash',
            label = '焚火を消す',
            action = function(entity)
                TriggerEvent('ng-camping:client:removeItem', entity, 'campfire')
            end,
        },
    }
}

-- アニメーション設定
Config.Animations = {
    place = {
        dict = 'amb@world_human_hammering@male@base',
        anim = 'base',
        duration = 5000
    },
    remove = {
        dict = 'amb@world_human_hammering@male@base',
        anim = 'base',
        duration = 3000
    },
    sit = {
        dict = 'anim@heists@fleeca_bank@ig_7_jetski_owner',
        anim = 'owner_idle',
        flag = 1
    }
}

-- 通知設定
Config.Notifications = {
    success = {
        title = 'キャンプ',
        type = 'success',
        duration = 3000
    },
    error = {
        title = 'キャンプ',
        type = 'error',
        duration = 3000
    },
    info = {
        title = 'キャンプ',
        type = 'inform',
        duration = 3000
    }
}

-- データベーステーブル名
Config.Database = {
    table = 'ng_camping_items'
}