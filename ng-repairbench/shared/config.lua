Config = {}

-- 基本設定
Config.Framework = 'qb-core' -- フレームワーク
Config.AdminJob = 'admin' -- 収益が入るジョブ名
Config.Currency = 'cash' -- 支払い方法 ('cash' または 'bank')

-- 修理ベンチ台の設置場所
Config.RepairBenches = {
    {
        coords = vector3(1174.81, 2640.89, 37.75), -- サンディ海岸のガレージ
        heading = 0.0,
        blip = {
            enabled = true,
            sprite = 446,
            color = 5,
            scale = 0.8,
            name = "車両修理ベンチ"
        }
    },
    {
        coords = vector3(-347.26, -132.23, 39.01), -- ロスサントス市内
        heading = 160.0,
        blip = {
            enabled = true,
            sprite = 446,
            color = 5,
            scale = 0.8,
            name = "車両修理ベンチ"
        }
    }
}

-- 修理料金設定
Config.RepairPrices = {
    engine = 500,      -- エンジン修理
    body = 300,        -- ボディ修理
    full = 800,        -- 完全修理
    petrol = 50        -- 燃料補給（1Lあたり）
}

-- 修理時間設定（秒）
Config.RepairTimes = {
    engine = 15,       -- エンジン修理時間
    body = 10,         -- ボディ修理時間
    full = 25,         -- 完全修理時間
    petrol = 5         -- 燃料補給時間
}

-- UIテキスト設定
Config.Texts = {
    targetLabel = "修理ベンチを使用",
    menuTitle = "車両修理サービス",
    menuSubtitle = "修理オプションを選択してください",
    
    -- メニューオプション
    engineRepair = "エンジン修理",
    engineRepairDesc = "エンジンの損傷を修理します ($%s)",
    
    bodyRepair = "ボディ修理",
    bodyRepairDesc = "車体の損傷を修理します ($%s)",
    
    fullRepair = "完全修理",
    fullRepairDesc = "すべての損傷を修理します ($%s)",
    
    refuel = "燃料補給",
    refuelDesc = "燃料を満タンにします ($%s)",
    
    -- 通知メッセージ
    noVehicle = "近くに車両がありません",
    notInVehicle = "車両から降りてください",
    vehicleTooFar = "車両が遠すぎます",
    notEnoughMoney = "お金が足りません",
    repairSuccess = "修理が完了しました",
    refuelSuccess = "燃料補給が完了しました",
    repairInProgress = "修理中です...",
    cancelled = "修理がキャンセルされました"
}

-- 詳細設定
Config.Settings = {
    maxDistance = 5.0,        -- ベンチと車両の最大距離
    playerMaxDistance = 3.0,  -- プレイヤーとベンチの最大距離
    checkVehicleEngine = true, -- エンジンをかけたままの修理を禁止
    showProgressBar = true,   -- プログレスバーを表示
    playAnimation = true,     -- 修理アニメーションを再生
    
    -- アニメーション設定
    animation = {
        dict = "mini@repair",
        anim = "fixing_a_player",
        flag = 1
    }
}