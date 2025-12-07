Config = {}

-- 入力値の制限設定
Config.Limits = {
    weight = {
        min = 50,
        max = 300,
        step = 5,
        default = 100
    },
    hunger = {
        min = -100,
        max = 100,
        step = 1,
        default = 0
    },
    thirst = {
        min = -100,
        max = 100,
        step = 1,
        default = 0
    },
    stress = {
        min = -100,
        max = 100,
        step = 1,
        default = 0
    },
    usetime = {
        min = 0,
        max = 60,
        step = 1,
        default = 5
    }
}

-- アイテム作成の権限を持つジョブとグレード（QB-Core用）
Config.AllowedJobs = {
    --['police'] = 3, -- 階級3以上
    --['ambulance'] = 3,
    ['admin'] = 0, -- 運営
    ['sample_restaurant_1'] = 3,
    ['sample_restaurant_2'] = 3,
    ['sample_restaurant_3'] = 3,
    ['sample_restaurant_4'] = 3,
    ['sample_restaurant_5'] = 3,
    ['sample_restaurant_6'] = 3,
    ['sample_restaurant_7'] = 3,
    ['sample_restaurant_8'] = 3,
    ['sample_restaurant_9'] = 3,
    ['sample_restaurant_10'] = 3,
    ['sample_restaurant_11'] = 3,
    ['sample_restaurant_12'] = 3,
    ['sample_restaurant_13'] = 3,
    ['sample_restaurant_14'] = 3,
    ['sample_restaurant_15'] = 3,
    ['sample_restaurant_16'] = 3,
    ['sample_restaurant_17'] = 3,
    ['sample_restaurant_18'] = 3,
    ['sample_restaurant_19'] = 3,
    ['sample_restaurant_20'] = 3,
    ['sample_restaurant_21'] = 3,
    ['sample_restaurant_22'] = 3,
    ['sample_restaurant_23'] = 3,
    ['sample_restaurant_24'] = 3,
    ['sample_restaurant_25'] = 3,
    ['sample_restaurant_26'] = 3,
}

-- アイテムタイプの定義
Config.ItemTypes = {
    'normal',    -- 通常アイテム
    'food',      -- 食べ物
    'drink',      -- 飲み物
    'stress'      -- ストレス
}

-- 消費アイテムの効果設定
Config.ConsumableEffects = {
    food = {
        hunger = true
    },
    drink = {
        thirst = true
    },
    stress = {
        stress = true
    }
}

-- デフォルトのアイテム設定
Config.DefaultSettings = {
    weight = 100,         -- デフォルトの重量(グラム)
    description = "",     -- デフォルトの説明文
    client = {
        status = {},      -- ステータス効果
        export = "",      -- エクスポート関数
    }
}

-- アニメーション設定
Config.Animations = {
    ['なし'] = {
        label = 'なし',
        dict = nil,
        clip = nil,
        flag = nil
    },
    ['食べる（バーガー）'] = {
        label = '食べる（バーガー）',
        dict = 'mp_player_inteat@burger',
        clip = 'mp_player_int_eat_burger',
        flag = 49
    },
    ['食べる（サンドイッチ）'] = {
        label = '食べる（サンドイッチ）',
        dict = 'mp_player_inteat@burger',
        clip = 'mp_player_int_eat_burger_fp',
        flag = 49
    },
    ['飲む（ボトル）'] = {
        label = '飲む（ボトル）',
        dict = 'mp_player_intdrink',
        clip = 'loop_bottle',
        flag = 49
    },
    ['飲む（カップ）'] = {
        label = '飲む（カップ）',
        dict = 'amb@world_human_drinking@coffee@male@idle_a',
        clip = 'idle_c',
        flag = 49
    },
    ['喫煙'] = {
        label = '喫煙',
        dict = 'amb@world_human_aa_smoke@male@idle_a',
        clip = 'idle_c',
        flag = 49
    },
    ['薬を飲む'] = {
        label = '薬を飲む',
        dict = 'mp_suicide',
        clip = 'pill',
        flag = 49
    },
    ['注射'] = {
        label = '注射',
        dict = 'amb@code_human_in_bus_passenger_idles@female@tablet@idle_a',
        clip = 'idle_a',
        flag = 49
    }
}

-- プロップ設定
Config.Props = {
    ['なし'] = {
        label = 'なし',
        model = nil,
        bone = nil,
        pos = nil,
        rot = nil
    },
    ['バーガー'] = {
        label = 'バーガー',
        model = 'prop_cs_burger_01',
        bone = 18905,
        pos = vector3(0.13, 0.05, 0.02),
        rot = vector3(-50.0, 16.0, 60.0)
    },
    ['サンドイッチ'] = {
        label = 'サンドイッチ',
        model = 'prop_sandwich_01',
        bone = 18905,
        pos = vector3(0.13, 0.05, 0.02),
        rot = vector3(-50.0, 16.0, 60.0)
    },
    ['ホットドッグ'] = {
        label = 'ホットドッグ',
        model = 'prop_cs_hotdog_01',
        bone = 18905,
        pos = vector3(0.13, 0.05, 0.02),
        rot = vector3(-50.0, 16.0, 60.0)
    },
    ['ドーナツ'] = {
        label = 'ドーナツ',
        model = 'prop_donut_02',
        bone = 18905,
        pos = vector3(0.13, 0.05, 0.02),
        rot = vector3(-50.0, 16.0, 60.0)
    },
    ['ピザ'] = {
        label = 'ピザ',
        model = 'v_res_tt_pizzaplate',
        bone = 18905,
        pos = vector3(0.13, 0.05, 0.02),
        rot = vector3(-50.0, 16.0, 60.0)
    },
    ['水のボトル'] = {
        label = '水のボトル',
        model = 'prop_ld_flow_bottle',
        bone = 18905,
        pos = vector3(0.12, 0.008, 0.03),
        rot = vector3(240.0, -60.0, 0.0)
    },
    ['ビール瓶'] = {
        label = 'ビール瓶',
        model = 'prop_amb_beer_bottle',
        bone = 18905,
        pos = vector3(0.12, 0.008, 0.03),
        rot = vector3(240.0, -60.0, 0.0)
    },
    ['ワイン瓶'] = {
        label = 'ワイン瓶',
        model = 'prop_wine_rose',
        bone = 18905,
        pos = vector3(0.12, 0.008, 0.03),
        rot = vector3(240.0, -60.0, 0.0)
    },
    ['コーヒーカップ'] = {
        label = 'コーヒーカップ',
        model = 'p_amb_coffeecup_01',
        bone = 28422,
        pos = vector3(0.0, 0.0, 0.0),
        rot = vector3(0.0, 0.0, 0.0)
    },
    ['紙コップ'] = {
        label = '紙コップ',
        model = 'prop_plastic_cup_02',
        bone = 28422,
        pos = vector3(0.0, 0.0, 0.0),
        rot = vector3(0.0, 0.0, 0.0)
    },
    ['タバコ'] = {
        label = 'タバコ',
        model = 'prop_cs_ciggy_01',
        bone = 47419,
        pos = vector3(0.015, -0.009, 0.003),
        rot = vector3(55.0, 0.0, 110.0)
    },
    ['葉巻'] = {
        label = '葉巻',
        model = 'prop_cigar_02',
        bone = 47419,
        pos = vector3(0.015, -0.009, 0.003),
        rot = vector3(55.0, 0.0, 110.0)
    },
    ['注射器'] = {
        label = '注射器',
        model = 'prop_syringe_01',
        bone = 18905,
        pos = vector3(0.13, 0.05, 0.02),
        rot = vector3(-50.0, 16.0, 60.0)
    },
    ['錠剤'] = {
        label = '錠剤',
        model = 'prop_pill_bottle_01',
        bone = 18905,
        pos = vector3(0.13, 0.05, 0.02),
        rot = vector3(-50.0, 16.0, 60.0)
    }
}

-- アイテム画像の保存パス
Config.ImagePath = "ox_inventory/web/images/"

-- QB-Core統合設定
Config.QBCore = {
    -- QB-Coreのitems.luaファイルパス
    itemsPath = "qb-core/shared/items.lua",
    -- 自動でQBCore.Shared.Itemsテーブルを更新するか
    autoUpdateSharedItems = true
}

-- OX-Inventory統合設定  
Config.OxInventory = {
    -- OX-Inventoryのitems.luaファイルパス
    itemsPath = "ox_inventory/data/items.lua",
    -- 自動でOX-Inventoryアイテムを更新するか
    autoUpdateItems = true
}