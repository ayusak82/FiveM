Config = {}

-- スコアボードの設定
Config.OpenKey = 'HOME' -- スコアボードを開くキー
Config.PoliceJobName = 'police' -- 警察の職業名

-- サーバー再起動時間（複数設定可能、24時間形式）
Config.ServerRestartTimes = {
    "00:00",
    "03:00",
    "06:00",
    "09:00",
    "12:00",
    "15:00",
    "18:00",
    "21:00",
}

-- 表示するジョブ一覧
Config.Jobs = {
    {name = "運営", jobName = "admin"},
    {name = "警察", jobName = "police"},
    {name = "医者", jobName = "ambulance"},
    {name = "個人医", jobName = "doctor"},
    {name = "不動産", jobName = "realestate"},
    {name = "タクシー", jobName = "taxi"},
    {name = "カジノ", jobName = "casino"},
    {name = "印刷屋", jobName = "print"},
    {name = "メカニック (サンプル1)", jobName = "sample_mechanic_1"},
    {name = "メカニック (サンプル2)", jobName = "sample_mechanic_2"},
    {name = "メカニック (サンプル3)", jobName = "sample_mechanic_3"},
    {name = "メカニック (サンプル4)", jobName = "sample_mechanic_4"},
    {name = "メカニック (サンプル5)", jobName = "sample_mechanic_5"},
    {name = "メカニック (サンプル6)", jobName = "sample_mechanic_6"},
    {name = "メカニック (サンプル7)", jobName = "sample_mechanic_7"},
    {name = "メカニック (サンプル8)", jobName = "sample_mechanic_8"},
    {name = "メカニック (サンプル9)", jobName = "sample_mechanic_9"},
    {name = "メカニック (サンプル10)", jobName = "sample_mechanic_10"},
    {name = "メカニック (サンプル11)", jobName = "sample_mechanic_11"},
    {name = "メカニック (サンプル12)", jobName = "sample_mechanic_12"},
    {name = "メカニック (サンプル13)", jobName = "sample_mechanic_13"},
    {name = "メカニック (サンプル14)", jobName = "sample_mechanic_14"},
    {name = "メカニック (サンプル15)", jobName = "sample_mechanic_15"},
    {name = "メカニック (サンプル16)", jobName = "sample_mechanic_16"},
    {name = "飲食店 (サンプル1)", jobName = "sample_restaurant_1"},
    {name = "飲食店 (サンプル2)", jobName = "sample_restaurant_2"},
    {name = "飲食店 (サンプル3)", jobName = "sample_restaurant_3"},
    {name = "飲食店 (サンプル4)", jobName = "sample_restaurant_4"},
    {name = "飲食店 (サンプル5)", jobName = "sample_restaurant_5"},
    {name = "飲食店 (サンプル6)", jobName = "sample_restaurant_6"},
    {name = "飲食店 (サンプル7)", jobName = "sample_restaurant_7"},
    {name = "飲食店 (サンプル8)", jobName = "sample_restaurant_8"},
    {name = "飲食店 (サンプル9)", jobName = "sample_restaurant_9"},
    {name = "飲食店 (サンプル10)", jobName = "sample_restaurant_10"},
    {name = "飲食店 (サンプル11)", jobName = "sample_restaurant_11"},
    {name = "飲食店 (サンプル12)", jobName = "sample_restaurant_12"},
    {name = "飲食店 (サンプル13)", jobName = "sample_restaurant_13"},
    {name = "飲食店 (サンプル14)", jobName = "sample_restaurant_14"},
    {name = "飲食店 (サンプル15)", jobName = "sample_restaurant_15"},
    {name = "飲食店 (サンプル16)", jobName = "sample_restaurant_16"},
    {name = "飲食店 (サンプル17)", jobName = "sample_restaurant_17"},
    {name = "飲食店 (サンプル18)", jobName = "sample_restaurant_18"},
    {name = "飲食店 (サンプル19)", jobName = "sample_restaurant_19"},
    {name = "飲食店 (サンプル20)", jobName = "sample_restaurant_20"},
    {name = "飲食店 (サンプル21)", jobName = "sample_restaurant_21"},
    {name = "飲食店 (サンプル22)", jobName = "sample_restaurant_22"},
    {name = "飲食店 (サンプル23)", jobName = "sample_restaurant_23"},
    {name = "飲食店 (サンプル24)", jobName = "sample_restaurant_24"},
    {name = "飲食店 (サンプル25)", jobName = "sample_restaurant_25"},
    {name = "飲食店 (サンプル26)", jobName = "sample_restaurant_26"},
}

-- 強盗の設定（複数設定可能）
Config.Robberies = {
    {
        name = "テルミットミッション",
        requiredPolice = 0
    },
    {
        name = "オイルリグ強盗",
        requiredPolice = 0
    },
    {
        name = "住宅強盗",
        requiredPolice = 2
    },
    --[[]
    {
        name = "店舗強盗",
        requiredPolice = 2
    },
    {
        name = "ATM強盗",
        requiredPolice = 2
    },
    --]]
    {
        name = "列車強盗",
        requiredPolice = 4
    },
    {
        name = "フリーカ強盗",
        requiredPolice = 4
    },
    {
        name = "宝石強盗",
        requiredPolice = 6
    },
    {
        name = "ボブキャット強盗",
        requiredPolice = 6
    },
    {
        name = "豪華客船強盗",
        requiredPolice = 6
    },
    {
        name = "パレト強盗",
        requiredPolice = 6
    },
    {
        name = "ヒューメイン強盗",
        requiredPolice = 6
    },
    {
        name = "アーティファクト強盗",
        requiredPolice = 8
    },
    {
        name = "金庫強盗",
        requiredPolice = 8
    },
    {
        name = "メイズバンク強盗",
        requiredPolice = 8
    },
    {
        name = "飛行場襲撃強盗",
        requiredPolice = 10
    },
    {
        name = "パシフィック強盗",
        requiredPolice = 10
    },
    {
        name = "アンダーグラウンド強盗",
        requiredPolice = 10
    },
    {
        name = "ユニオン強盗",
        requiredPolice = 10
    },
    {
        name = "カジノ強盗",
        requiredPolice = 10
    },
}