local ox_inventory = exports.ox_inventory

-- バックパックを開く（backpack1, backpack2, backpack3用）
local function openBackpack(data, slot, itemName)
    if not slot?.metadata?.identifier then
        local identifier = lib.callback.await('ng-backpack:getNewIdentifier', 100, data.slot, itemName)
        if identifier then
            ox_inventory:openInventory('stash', 'bag_'..identifier)
        end
    else
        TriggerServerEvent('ng-backpack:openBag', slot.metadata.identifier, itemName)
        ox_inventory:openInventory('stash', 'bag_'..slot.metadata.identifier)
    end
end

-- スーツケースを開く（パスコード処理付き）
local function openSuitcase(data, slot)
    local identifier = slot?.metadata?.identifier
    local hasPasscode = slot?.metadata?.passcode ~= nil
    
    -- 新規スーツケースの場合
    if not identifier then
        identifier = lib.callback.await('ng-backpack:getNewIdentifier', 100, data.slot, 'suitcase')
        if identifier then
            ox_inventory:openInventory('stash', 'bag_'..identifier)
        end
        return
    end
    
    -- パスコード設定済みの場合
    if hasPasscode then
        local input = lib.inputDialog(Config.Strings.enter_passcode, {
            {
                type = 'input',
                label = 'パスコード',
                description = '4桁の数字を入力してください',
                required = true,
                min = 4,
                max = 4
            }
        })
        
        if not input or not input[1] then
            return
        end
        
        local passcode = input[1]
        
        -- パスコード検証
        local verified = lib.callback.await('ng-backpack:verifyPasscode', 100, identifier, passcode)
        
        if verified then
            TriggerServerEvent('ng-backpack:openBag', identifier, 'suitcase')
            ox_inventory:openInventory('stash', 'bag_'..identifier)
        else
            lib.notify({
                type = 'error',
                title = Config.Strings.action_incomplete,
                description = Config.Strings.wrong_passcode
            })
        end
    else
        -- パスコード未設定の場合は通常通り開く
        TriggerServerEvent('ng-backpack:openBag', identifier, 'suitcase')
        ox_inventory:openInventory('stash', 'bag_'..identifier)
    end
end

-- パスコード管理メニュー
local function managePasscode(slotNumber)
    -- ox_inventoryのbuttonsから呼ばれる場合、slotNumberが数字で渡される
    -- 実際のスロットデータを取得する必要がある
    
    if type(slotNumber) ~= 'number' then
        lib.notify({
            type = 'error',
            title = Config.Strings.action_incomplete,
            description = 'スロット番号が正しくありません'
        })
        return
    end
    
    -- プレイヤーのインベントリからスロットデータを取得
    local playerData = ox_inventory:GetPlayerItems()
    local slot = nil
    
    for _, item in pairs(playerData) do
        if item.slot == slotNumber and item.name == 'suitcase' then
            slot = item
            break
        end
    end
    
    if not slot then
        lib.notify({
            type = 'error',
            title = Config.Strings.action_incomplete,
            description = 'スーツケースが見つかりません'
        })
        return
    end
    
    local identifier = slot?.metadata?.identifier
    local hasPasscode = slot?.metadata?.passcode ~= nil
    
    if not identifier then
        lib.notify({
            type = 'error',
            title = Config.Strings.action_incomplete,
            description = '一度開いてからパスコードを設定してください'
        })
        return
    end
    
    local options = {}
    
    if hasPasscode then
        -- パスコード設定済みの場合
        table.insert(options, {
            title = 'パスコードを変更',
            description = '現在のパスコードを新しいものに変更します',
            icon = 'key',
            onSelect = function()
                local input = lib.inputDialog('パスコード変更', {
                    {
                        type = 'input',
                        label = '現在のパスコード',
                        description = '4桁の数字',
                        required = true,
                        min = 4,
                        max = 4
                    },
                    {
                        type = 'input',
                        label = '新しいパスコード',
                        description = '4桁の数字',
                        required = true,
                        min = 4,
                        max = 4
                    }
                })
                
                if not input or not input[1] or not input[2] then
                    return
                end
                
                local oldPasscode = input[1]
                local newPasscode = input[2]
                
                if newPasscode:len() ~= 4 or not tonumber(newPasscode) then
                    lib.notify({
                        type = 'error',
                        title = Config.Strings.action_incomplete,
                        description = Config.Strings.passcode_4digits
                    })
                    return
                end
                
                local success = lib.callback.await('ng-backpack:changePasscode', 100, slotNumber, identifier, oldPasscode, newPasscode)
                
                if success then
                    lib.notify({
                        type = 'success',
                        description = Config.Strings.passcode_changed
                    })
                else
                    lib.notify({
                        type = 'error',
                        title = Config.Strings.action_incomplete,
                        description = Config.Strings.wrong_passcode
                    })
                end
            end
        })
        
        table.insert(options, {
            title = 'パスコードを削除',
            description = 'パスコードを削除してロックを解除します',
            icon = 'lock-open',
            onSelect = function()
                local input = lib.inputDialog(Config.Strings.remove_passcode, {
                    {
                        type = 'input',
                        label = '現在のパスコード',
                        description = '4桁の数字',
                        required = true,
                        min = 4,
                        max = 4
                    }
                })
                
                if not input or not input[1] then
                    return
                end
                
                local passcode = input[1]
                local success = lib.callback.await('ng-backpack:removePasscode', 100, slotNumber, identifier, passcode)
                
                if success then
                    lib.notify({
                        type = 'success',
                        description = Config.Strings.passcode_removed
                    })
                else
                    lib.notify({
                        type = 'error',
                        title = Config.Strings.action_incomplete,
                        description = Config.Strings.wrong_passcode
                    })
                end
            end
        })
    else
        -- パスコード未設定の場合
        table.insert(options, {
            title = 'パスコードを設定',
            description = '4桁のパスコードを設定してロックします',
            icon = 'lock',
            onSelect = function()
                local input = lib.inputDialog(Config.Strings.set_passcode, {
                    {
                        type = 'input',
                        label = 'パスコード',
                        description = '4桁の数字を入力してください',
                        required = true,
                        min = 4,
                        max = 4
                    }
                })
                
                if not input or not input[1] then
                    return
                end
                
                local passcode = input[1]
                
                if passcode:len() ~= 4 or not tonumber(passcode) then
                    lib.notify({
                        type = 'error',
                        title = Config.Strings.action_incomplete,
                        description = Config.Strings.passcode_4digits
                    })
                    return
                end
                
                local success = lib.callback.await('ng-backpack:setPasscode', 100, slotNumber, identifier, passcode)
                
                if success then
                    lib.notify({
                        type = 'success',
                        description = Config.Strings.passcode_set
                    })
                else
                    lib.notify({
                        type = 'error',
                        title = Config.Strings.action_incomplete,
                        description = Config.Strings.passcode_4digits
                    })
                end
            end
        })
    end
    
    lib.registerContext({
        id = 'suitcase_passcode_menu',
        title = 'スーツケース管理',
        options = options
    })
    
    lib.showContext('suitcase_passcode_menu')
end

-- エクスポート: バックパック1を開く
exports('openBackpack1', function(data, slot)
    openBackpack(data, slot, 'backpack1')
end)

-- エクスポート: バックパック2を開く
exports('openBackpack2', function(data, slot)
    openBackpack(data, slot, 'backpack2')
end)

-- エクスポート: バックパック3を開く
exports('openBackpack3', function(data, slot)
    openBackpack(data, slot, 'backpack3')
end)

-- エクスポート: スーツケースを開く
exports('openSuitcase', function(data, slot)
    openSuitcase(data, slot)
end)

-- エクスポート: スーツケースのパスコード管理
exports('manageSuitcasePasscode', function(slotNumber)
    managePasscode(slotNumber)
end)
