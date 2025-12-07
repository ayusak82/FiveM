Config = {}

-- 焚火のプロップと設定
Config.CampfireProp = 'prop_beach_fire' -- 焚火のプロップモデル
Config.HealingRadius = 8.0 -- 回復効果の範囲（メートル）
Config.DurationMinutes = 2 -- 焚火の持続時間（分）

-- 回復効果の設定
Config.HealInterval = 5000 -- 回復間隔（ミリ秒）
Config.HealthRegenAmount = 2 -- 一回あたりの体力回復量
Config.StressReductionAmount = 1 -- 一回あたりのストレス軽減量（qb-stressが有効な場合）

-- コマンド設定
Config.Command = 'campfire' -- 焚火を設置するコマンド

-- 通知設定
Config.Notifications = {
    placed = '焚火を設置しました',
    alreadyHave = '既に焚火を設置しています',
    removed = '焚火を片付けました',
    expired = '焚火が消えました',
    entering = '焚火の暖かさを感じます',
    leaving = '焚火から離れました'
}

-- 権限設定
Config.RequireItem = true -- アイテムが必要かどうか
Config.RequiredItem = 'campfire_kit' -- 必要なアイテム名（ox_inventoryに追加する必要があります）
Config.RemoveItemOnUse = true -- 使用時にアイテムを消費するかどうか

-- 注意: このスクリプト自体はアイテムを追加しません
-- ox_inventoryに以下のようなアイテムを追加する必要があります:
--[[
['campfire_kit'] = {
    label = '焚火キット',
    weight = 1000,
    stack = true,
    close = true,
    description = '焚火を設置するためのキット',
    client = {
        event = 'ng-campfire:client:placeFromItem'
    }
},
]]