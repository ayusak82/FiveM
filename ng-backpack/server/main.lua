local registeredStashes = {}
local ox_inventory = exports.ox_inventory

-- ランダムテキスト生成
local function GenerateText(num)
    local str
    repeat
        str = {}
        for i = 1, num do
            str[i] = string.char(math.random(65, 90))
        end
        str = table.concat(str)
    until str ~= 'POL' and str ~= 'EMS'
    return str
end

-- シリアル番号生成
local function GenerateSerial(text)
    if text and text:len() > 3 then
        return text
    end
    return ('%s%s%s'):format(math.random(100000, 999999), text == nil and GenerateText(3) or text, math.random(100000, 999999))
end

-- バックパック/スーツケースを開く
RegisterServerEvent('ng-backpack:openBag')
AddEventHandler('ng-backpack:openBag', function(identifier, itemName)
    local source = source
    if not registeredStashes[identifier] then
        local storageConfig = Config.Storage[itemName]
        if storageConfig then
            ox_inventory:RegisterStash('bag_'..identifier, storageConfig.label, storageConfig.slots, storageConfig.weight, false)
            registeredStashes[identifier] = true
        end
    end
end)

-- 新しいidentifierを取得
lib.callback.register('ng-backpack:getNewIdentifier', function(source, slot, itemName)
    local newId = GenerateSerial()
    ox_inventory:SetMetadata(source, slot, {identifier = newId})
    
    local storageConfig = Config.Storage[itemName]
    if storageConfig then
        ox_inventory:RegisterStash('bag_'..newId, storageConfig.label, storageConfig.slots, storageConfig.weight, false)
        registeredStashes[newId] = true
    end
    
    return newId
end)

-- パスコード検証
lib.callback.register('ng-backpack:verifyPasscode', function(source, identifier, passcode)
    local item = ox_inventory:GetSlotWithItem(source, 'suitcase', {identifier = identifier})
    if item and item.metadata and item.metadata.passcode then
        return item.metadata.passcode == passcode
    end
    return true -- パスコード未設定の場合は通過
end)

-- パスコード設定
lib.callback.register('ng-backpack:setPasscode', function(source, slot, identifier, passcode)
    if not passcode or passcode:len() ~= 4 or not tonumber(passcode) then
        return false
    end
    
    ox_inventory:SetMetadata(source, slot, {
        identifier = identifier,
        passcode = passcode,
        description = 'パスコード設定済み'
    })
    
    return true
end)

-- パスコード変更
lib.callback.register('ng-backpack:changePasscode', function(source, slot, identifier, oldPasscode, newPasscode)
    if not newPasscode or newPasscode:len() ~= 4 or not tonumber(newPasscode) then
        return false
    end
    
    local item = ox_inventory:GetSlotWithItem(source, 'suitcase', {identifier = identifier})
    if not item or not item.metadata or not item.metadata.passcode then
        return false
    end
    
    if item.metadata.passcode ~= oldPasscode then
        return false
    end
    
    ox_inventory:SetMetadata(source, slot, {
        identifier = identifier,
        passcode = newPasscode,
        description = 'パスコード設定済み'
    })
    
    return true
end)

-- パスコード削除
lib.callback.register('ng-backpack:removePasscode', function(source, slot, identifier, passcode)
    local item = ox_inventory:GetSlotWithItem(source, 'suitcase', {identifier = identifier})
    if not item or not item.metadata or not item.metadata.passcode then
        return false
    end
    
    if item.metadata.passcode ~= passcode then
        return false
    end
    
    ox_inventory:SetMetadata(source, slot, {
        identifier = identifier,
        description = nil
    })
    
    return true
end)

-- ox_inventoryのhook登録
CreateThread(function()
    while GetResourceState('ox_inventory') ~= 'started' do
        Wait(500)
    end
    
    -- swapItemsフック - バッグ内にバッグを入れることを禁止
    local swapHook = ox_inventory:registerHook('swapItems', function(payload)
        local destination = payload.toInventory
        local itemName = payload.fromSlot and payload.fromSlot.name or nil
        
        -- バッグ系アイテムかチェック
        local isBagItem = false
        for _, bagItem in ipairs(Config.BagItems) do
            if itemName == bagItem then
                isBagItem = true
                break
            end
        end
        
        -- バッグの中にバッグを入れようとしている場合は禁止
        if isBagItem and string.find(destination, 'bag_') then
            TriggerClientEvent('ox_lib:notify', payload.source, {
                type = 'error',
                title = Config.Strings.action_incomplete,
                description = Config.Strings.bag_in_bag
            })
            return false
        end
        
        return true
    end, {
        print = false
    })
    
    -- リソース停止時にフックを削除
    AddEventHandler('onResourceStop', function(resourceName)
        if GetCurrentResourceName() == resourceName then
            ox_inventory:removeHooks(swapHook)
        end
    end)
end)
