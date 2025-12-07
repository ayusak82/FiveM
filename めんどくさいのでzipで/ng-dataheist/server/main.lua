local QBCore = exports['qb-core']:GetCoreObject()

-- ミッションの状態
local missionState = {
    started = false,
    hackingCompleted = false,
    deliveryCompleted = false
}

-- データベース設定
local function SetupDatabase()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `ng_dataheist` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `state` int(11) NOT NULL DEFAULT 0,
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        )
    ]])
    
    MySQL.query('SELECT * FROM ng_dataheist WHERE id = 1', {}, function(result)
        if not result or #result == 0 then
            MySQL.insert('INSERT INTO ng_dataheist (id, state) VALUES (?, ?)', {1, 0})
        else
            local state = result[1].state
            missionState.started = state > 0
            missionState.hackingCompleted = state > 1
            missionState.deliveryCompleted = state > 2
        end
    end)
end

-- ミッション状態の更新
local function UpdateMissionState()
    local state = 0
    if missionState.started then state = 1 end
    if missionState.hackingCompleted then state = 2 end
    if missionState.deliveryCompleted then state = 3 end
    
    MySQL.update('UPDATE ng_dataheist SET state = ? WHERE id = 1', {state})
    
    TriggerClientEvent('ng-dataheist:client:syncMissionState', -1, missionState.started, missionState.hackingCompleted, missionState.deliveryCompleted)
end

-- ミッション状態の取得
RegisterNetEvent('ng-dataheist:server:getMissionState', function()
    local src = source
    TriggerClientEvent('ng-dataheist:client:syncMissionState', src, missionState.started, missionState.hackingCompleted, missionState.deliveryCompleted)
end)

-- ミッション開始コールバック
lib.callback.register('ng-dataheist:server:startMission', function(source)
    if missionState.started then
        return false
    end
    
    missionState.started = true
    missionState.hackingCompleted = false
    missionState.deliveryCompleted = false
    
    UpdateMissionState()
    
    return true
end)

-- ハッキング完了コールバック
lib.callback.register('ng-dataheist:server:completeHacking', function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player or not missionState.started or missionState.hackingCompleted then
        return false
    end
    
    -- ハッキング完了状態を設定
    missionState.hackingCompleted = true
    UpdateMissionState()
    
    return true
end)

-- ハードドライブ所持確認コールバック
lib.callback.register('ng-dataheist:server:checkHarddrive', function(source)
    local src = source
    local hasItem = exports.ox_inventory:GetItemCount(src, 'harddrive') > 0
    return hasItem
end)

-- 納品完了コールバック
lib.callback.register('ng-dataheist:server:completeDelivery', function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player or not missionState.started or not missionState.hackingCompleted or missionState.deliveryCompleted then
        return false, 0
    end
    
    -- 報酬の計算
    local moneyReward = math.random(Config.Mission.deliveryRewards.money.min, Config.Mission.deliveryRewards.money.max)
    
    -- 報酬を付与
    Player.Functions.AddMoney('cash', moneyReward)
    
    -- アイテム報酬を付与
    for _, item in ipairs(Config.Mission.deliveryRewards.items) do
        local count = math.random(item.count.min, item.count.max)
        local canCarry = exports.ox_inventory:CanCarryItem(src, item.name, count)
        
        if canCarry then
            exports.ox_inventory:AddItem(src, item.name, count)
            TriggerClientEvent('QBCore:Notify', src, item.label .. 'を' .. count .. '個受け取りました!', 'success')
        else
            TriggerClientEvent('QBCore:Notify', src, 'インベントリがいっぱいで' .. item.label .. 'を受け取れませんでした!', 'error')
        end
    end
    
    missionState.deliveryCompleted = true
    UpdateMissionState()
    
    return true, moneyReward
end)

-- ミッションリセット
RegisterNetEvent('ng-dataheist:server:resetMission', function()
    missionState.started = false
    missionState.hackingCompleted = false
    missionState.deliveryCompleted = false
    
    UpdateMissionState()
end)

-- プレイヤー接続時
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    TriggerClientEvent('ng-dataheist:client:syncMissionState', src, missionState.started, missionState.hackingCompleted, missionState.deliveryCompleted)
end)

-- アイテム登録
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    -- スクリプト起動時にアイテムが存在しない場合は登録
    if not QBCore.Shared.Items['harddrive'] then
        QBCore.Functions.AddItem('harddrive', {
            name = 'harddrive',
            label = 'ハードドライブ',
            weight = 500,
            type = 'item',
            image = 'harddrive.png',
            unique = false,
            useable = false,
            shouldClose = false,
            combinable = nil,
            description = '機密データが入ったハードドライブ'
        })
    end
end)

-- リセットコマンドの登録
QBCore.Commands.Add('resetdataheist', 'データ強盗ミッションをリセットする(権限者専用)', {}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- 権限チェック (管理者または警察の場合)
    local hasPermission = false
    local PlayerJob = Player.PlayerData.job
    
    -- 管理者権限を持っているか
    if Player.PlayerData.permission == "admin" or Player.PlayerData.permission == "god" then
        hasPermission = true
    end
    
    -- 特定のジョブを持っているか (警察の場合はgradeも確認)
    if PlayerJob.name == "police" and PlayerJob.grade.level >= 3 then -- 警察の場合は階級3以上
        hasPermission = true
    end
    
    -- adminジョブを持っているか
    if PlayerJob.name == "admin" then
        hasPermission = true
    end
    
    if hasPermission then
        -- ミッション状態をリセット
        missionState.started = false
        missionState.hackingCompleted = false
        missionState.deliveryCompleted = false
        
        -- データベース更新
        UpdateMissionState()
        
        -- 通知
        TriggerClientEvent('QBCore:Notify', src, 'データ強盗ミッションがリセットされました。', 'success')
        TriggerClientEvent('ng-dataheist:client:missionReset', -1)
    else
        TriggerClientEvent('QBCore:Notify', src, '権限がありません。管理者または警察幹部の権限が必要です。', 'error')
    end
end)

-- リソース開始時の処理
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    SetupDatabase()
end)