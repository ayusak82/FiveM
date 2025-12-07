local QBCore = exports['qb-core']:GetCoreObject()

-- メタデータ更新イベント
RegisterNetEvent('ng-sound:server:updateMetadata', function(food, water)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    -- 現在のメタデータを取得
    local metadata = Player.PlayerData.metadata
    
    -- 食料の更新（増加または減少）
    if food ~= 0 then
        metadata.hunger = math.min(100, math.max(0, metadata.hunger + food))
    end
    
    -- 水分の更新（増加または減少）
    if water ~= 0 then
        metadata.thirst = math.min(100, math.max(0, metadata.thirst + water))
    end
    
    -- メタデータの保存
    Player.Functions.SetMetaData('hunger', metadata.hunger)
    Player.Functions.SetMetaData('thirst', metadata.thirst)
end)

-- アイテム使用イベント
RegisterNetEvent('ng-sound:server:useItem', function(itemName)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    print('アイテム使用: ' .. itemName)
    
    -- プレイヤーの位置を取得
    local coords = GetEntityCoords(GetPlayerPed(source))
    print('プレイヤー座標: ' .. json.encode(coords))
    
    -- 自分のクライアントで音声を再生
    TriggerClientEvent('ng-sound:client:playSound', source, itemName)
    
    -- 他のプレイヤーに音声再生を同期
    TriggerClientEvent('ng-sound:client:playSoundFromCoord', -1, itemName, coords)
    
    -- アイテムを削除する設定がある場合は削除
    if Config.Items[itemName].removeAfterUse then
        exports.ox_inventory:RemoveItem(source, itemName, 1)
        print('アイテム削除: ' .. itemName)
    end
end)

-- サウンド再生イベント
RegisterNetEvent('ng-sound:server:playSound', function(soundId, soundData, coords)
    local source = source
    
    if not soundData or not soundData.url then return end
    
    -- サウンドファイルのURLを構築
    local soundUrl = Config.BaseUrl .. soundData.url
    
    -- 全プレイヤーに対して音声を再生
    exports.xsound:PlayUrlPos(source, soundId, soundUrl, soundData.volume, coords, soundData.loop)
end)