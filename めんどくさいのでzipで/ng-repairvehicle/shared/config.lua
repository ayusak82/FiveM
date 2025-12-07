Config = {}

-- 基本設定
Config.Command = 'returnvehicle' -- コマンド名
Config.AdminCommand = 'areturnvehicle' -- Admin用コマンド
Config.SearchDistance = 3.0 -- 車両検索距離（メートル）
-- 車両損傷要件
Config.DamageRequirement = {
    enabled = true,      -- ダメージ要件を有効にするか
    minPercent = 30.0,   -- 返却に必要な最小ダメージ割合（パーセント）
    checkEngine = true,  -- エンジンのダメージをチェックするか
    checkBody = true,    -- ボディのダメージをチェックするか
}

-- 料金設定
Config.Costs = {
    base = 500,          -- 基本料金
    engineDamage = 100,  -- エンジンダメージ1%あたりの追加料金
    bodyDamage = 100,    -- ボディダメージ1%あたりの追加料金
}

-- 通知メッセージ
Config.Messages = {
    noVehicleNearby = '近くに車両がありません',
    notYourVehicle = 'あなたの所有する車両ではありません',
    returnSuccess = '車両をガレージに返却しました',
    notEnoughMoney = '所持金が不足しています',
    costMessage = '修理費用: $%s',
    notEnoughDamage = '車両の損傷が%s%%未満のため返却できません',
    adminReturnSuccess = '%sの車両を返却しました'
}

-- Discord Webhook設定
Config.Webhook = {
    url = 'YOUR_DISCORD_WEBHOOK_URL_HERE',  -- Webhookのリンク
    name = 'Vehicle Return System',  -- Webhookの名前
    color = {
        normal = 65280,  -- 通常返却時の色 (緑色)
        admin = 15105570  -- Admin返却時の色 (オレンジ色)
    },
    title = {
        normal = "車両返却ログ",  -- 通常返却時のタイトル
        admin = "車両返却ログ [Admin]"  -- Admin返却時のタイトル
    },
    footer = 'Vehicle Return Logs',  -- フッターテキスト
    enabled = true  -- Webhook機能の有効/無効
}