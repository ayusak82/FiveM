local QBCore = exports['qb-core']:GetCoreObject()

-- 権限チェック
local function HasPermission(source)
    return IsPlayerAceAllowed(source, Config.AcePermission)
end

-- キャッシュされたアイテム設定
local cachedItemConfigs = {}

-- キャッシュの更新
local function UpdateCache()
    cachedItemConfigs = Database.GetAllConfigs()
end

-- リソース起動時にキャッシュを更新
CreateThread(function()
    Wait(1000) -- データベース初期化を待つ
    UpdateCache()
end)

-- アイテム設定の取得
lib.callback.register('ng-itemeditor:getItemConfig', function(source, itemName)
    if not HasPermission(source) then
        return false, 'アクセス権限がありません'
    end
    
    local config = Database.GetItemConfig(itemName)
    if config then
        return true, config
    else
        return true, Utils.MergeConfig({}, Config.DefaultTemplate)
    end
end)

-- アイテム設定の保存
lib.callback.register('ng-itemeditor:saveItemConfig', function(source, itemName, config)
    if not HasPermission(source) then
        return false, 'アクセス権限がありません'
    end
    
    -- アイテムの存在確認
    local item = QBCore.Shared.Items[itemName]
    if not item then
        return false, 'アイテムが存在しません'
    end
    
    -- 設定を保存
    local success, error = Database.SaveItemConfig(itemName, config)
    if success then
        -- キャッシュを更新
        UpdateCache()
        return true, nil
    else
        return false, error
    end
end)

-- アイテム設定の削除
lib.callback.register('ng-itemeditor:deleteItemConfig', function(source, itemName)
    if not HasPermission(source) then
        return false, 'アクセス権限がありません'
    end
    
    local success, error = Database.DeleteItemConfig(itemName)
    if success then
        -- キャッシュを更新
        UpdateCache()
        return true, nil
    else
        return false, error
    end
end)

-- 全アイテムのリストを取得
lib.callback.register('ng-itemeditor:getItemList', function(source)
    if not HasPermission(source) then
        return false, 'アクセス権限がありません'
    end
    
    local items = {}
    for k, v in pairs(QBCore.Shared.Items) do
        table.insert(items, {
            name = k,
            label = v.label,
            hasConfig = cachedItemConfigs[k] ~= nil
        })
    end
    
    return true, items
end)

-- メタデータ更新
RegisterNetEvent('ng-itemeditor:server:updateMetadata', function(food, water)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    -- 現在のメタデータを取得
    local metadata = Player.PlayerData.metadata
    
    -- 食料の更新
    if food ~= 0 then
        metadata.hunger = math.min(100, math.max(0, metadata.hunger + food))
        Player.Functions.SetMetaData('hunger', metadata.hunger)
    end
    
    -- 水分の更新
    if water ~= 0 then
        metadata.thirst = math.min(100, math.max(0, metadata.thirst + water))
        Player.Functions.SetMetaData('thirst', metadata.thirst)
    end
end)

-- アイテム使用イベント
RegisterNetEvent('ng-itemeditor:server:useItem', function(itemName)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    -- アイテム設定の取得
    local config = cachedItemConfigs[itemName]
    if not config then return end
    
    -- クライアントに効果を適用
    TriggerClientEvent('ng-itemeditor:client:applyEffects', source, itemName, config)
    
    -- 他のプレイヤーに音声を同期
    if config.sound and config.sound.url then
        local coords = GetEntityCoords(GetPlayerPed(source))
        TriggerClientEvent('ng-itemeditor:client:playSoundFromCoord', -1, itemName, coords, config)
    end
    
    -- アイテムを削除
    if config.removeAfterUse then
        exports.ox_inventory:RemoveItem(source, itemName, 1)
    end
end)

-- コマンドの登録
lib.addCommand(Config.Command, {
    help = 'アイテムエディタを開く',
    restricted = Config.AcePermission
}, function(source, args, raw)
    TriggerClientEvent('ng-itemeditor:client:openEditor', source)
end)