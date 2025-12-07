local QBCore = exports['qb-core']:GetCoreObject()
local activePlayers = {}

-- 管理者権限チェック用コールバック
lib.callback.register('ng-thermal:server:checkAdmin', function(source)
    return IsPlayerAceAllowed(source, 'command.admin')
end)

-- アイテムの定義をQBCoreに登録
QBCore.Functions.CreateUseableItem(Config.ItemName, function(source, item)
    local src = source
    TriggerClientEvent('ox_inventory:item', src, item)
end)

-- タイマーを開始するコールバック
lib.callback.register('ng-thermal:server:startTimer', function(source)
    local src = source
    local uniqueId = string.format('thermal_%s', src)
    
    -- 既存のタイマーがあれば削除
    if activePlayers[src] then
        if type(activePlayers[src]) == 'table' and activePlayers[src].destroy then
            activePlayers[src]:destroy()
        end
        activePlayers[src] = nil
    end
    
    -- タイマーを直接設定
    local timerId = SetTimeout(Config.EffectDuration * 1000, function()
        TriggerClientEvent('ng-thermal:client:endEffect', src)
        activePlayers[src] = nil
        
        if Config.Debug then
            print(string.format('プレイヤー %s のサーマル効果が終了しました', src))
        end
    end)
    
    -- タイマーIDを保存
    activePlayers[src] = {
        id = timerId,
        destroy = function()
            ClearTimeout(timerId)
        end
    }
    
    if Config.Debug then
        print(string.format('プレイヤー %s のサーマル効果タイマーを開始しました (%s秒)', src, Config.EffectDuration))
    end
    
    return true
end)

-- プレイヤー切断時にタイマーをクリア
AddEventHandler('playerDropped', function()
    local src = source
    if activePlayers[src] then
        activePlayers[src]:destroy()
        activePlayers[src] = nil
        if Config.Debug then
            print(string.format('プレイヤー %s が切断したため、タイマーをクリアしました', src))
        end
    end
end)

-- リソース停止時にすべてのタイマーをクリア
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for src, timer in pairs(activePlayers) do
            timer:destroy()
            activePlayers[src] = nil
        end
        if Config.Debug then
            print('リソース停止: すべてのタイマーをクリアしました')
        end
    end
end)