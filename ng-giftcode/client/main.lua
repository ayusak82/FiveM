local QBCore = exports['qb-core']:GetCoreObject()

-- 管理者権限チェック関数
local function isAdmin()
    return lib.callback.await('ng-giftcode:server:isAdmin', false)
end

-- 通知関数
local function notify(message, type)
    if Config.Notifications.Type == 'ox_lib' then
        lib.notify({
            title = 'ギフトコード',
            description = message,
            type = type or 'info',
            position = Config.Notifications.Position,
            duration = Config.Notifications.Duration
        })
    else
        QBCore.Functions.Notify(message, type or 'primary')
    end
end

-- アイテムリストのフィルタリング関数
local function filterItems(items, searchText)
    local filtered = {}
    searchText = string.lower(searchText or '')
    
    for k, v in pairs(items) do
        if k and (searchText == '' or 
            string.find(string.lower(k), searchText) or 
            (v.description and string.find(string.lower(v.description), searchText)) or
            (v.label and string.find(string.lower(v.label), searchText))) then
            filtered[k] = v
        end
    end
    return filtered
end

-- アイテムの画像パスを取得する関数
local function getItemImage(itemName, itemData)
    if itemData.client and itemData.client.image then
        local imagePath = itemData.client.image
        
        if string.match(imagePath, '^https?://') then
            return imagePath
        end
        
        if string.match(imagePath, '^nui://') then
            return imagePath
        end
        
        if not string.match(imagePath, '^/') then
            return string.format('nui://ox_inventory/web/images/%s', imagePath)
        end
        
        return string.format('nui://ox_inventory%s', imagePath)
    end
    
    return string.format('nui://ox_inventory/web/images/%s.png', itemName)
end

-- アイテム選択用の一時保存
local selectedItems = {}
local currentCallback = nil

-- アイテムリストを表示する関数
local function showItemSelector(searchText, callback, returnMenu)
    currentCallback = callback
    local allItems = exports.ox_inventory:Items()
    local filteredItems = filterItems(allItems, searchText)
    local options = {}

    -- 検索バー
    table.insert(options, {
        title = '🔍 アイテムを検索',
        description = '検索ワードを入力してください',
        icon = 'search',
        onSelect = function()
            local input = lib.inputDialog('アイテム検索', {
                { type = 'input', label = '検索ワード', description = 'アイテム名や説明で検索できます' }
            })
            if input and input[1] then
                showItemSelector(input[1], callback, returnMenu)
            end
        end
    })

    -- 選択済みアイテム表示
    if #selectedItems > 0 then
        table.insert(options, {
            title = '📦 選択済みアイテム (' .. #selectedItems .. '個)',
            description = 'クリックして確認・削除',
            icon = 'box',
            onSelect = function()
                showSelectedItems(callback, returnMenu)
            end
        })
    end

    -- 完了ボタン
    if #selectedItems > 0 then
        table.insert(options, {
            title = '✅ 選択完了',
            description = '選択したアイテムで確定',
            icon = 'check',
            onSelect = function()
                if callback then
                    callback(selectedItems)
                end
                selectedItems = {}
            end
        })
    end

    -- 区切り線
    table.insert(options, {
        title = '-------------------',
        disabled = true
    })

    -- アイテムリスト
    for k, v in pairs(filteredItems) do
        table.insert(options, {
            title = v.label or k,
            description = v.description or '説明なし',
            image = getItemImage(k, v),
            icon = 'plus',
            onSelect = function()
                -- 数量入力
                local input = lib.inputDialog(v.label or k, {
                    {
                        type = 'number',
                        label = '数量',
                        default = 1,
                        min = 1,
                        max = 999,
                        required = true
                    }
                })
                
                if input and input[1] then
                    table.insert(selectedItems, { name = k, amount = input[1], label = v.label or k })
                    notify(string.format('%s x%d を追加しました', v.label or k, input[1]), 'success')
                    showItemSelector(searchText, callback, returnMenu)
                end
            end
        })
    end

    -- 検索結果の表示
    if searchText and searchText ~= '' then
        local resultCount = #options - 3
        table.insert(options, 3, {
            title = string.format('検索結果: %d 件', resultCount),
            disabled = true
        })
    end

    lib.registerContext({
        id = 'giftcode_item_selector',
        title = 'アイテム選択',
        menu = returnMenu,
        options = options
    })

    lib.showContext('giftcode_item_selector')
end

-- 選択済みアイテム表示
function showSelectedItems(callback, returnMenu)
    local options = {}
    
    for i, item in ipairs(selectedItems) do
        table.insert(options, {
            title = item.label .. ' x' .. item.amount,
            description = 'アイテムID: ' .. item.name,
            icon = 'trash',
            onSelect = function()
                table.remove(selectedItems, i)
                notify('アイテムを削除しました', 'info')
                if #selectedItems > 0 then
                    showSelectedItems(callback, returnMenu)
                else
                    showItemSelector('', callback, returnMenu)
                end
            end
        })
    end
    
    table.insert(options, {
        title = '🔙 戻る',
        icon = 'arrow-left',
        onSelect = function()
            showItemSelector('', callback, returnMenu)
        end
    })
    
    lib.registerContext({
        id = 'giftcode_selected_items',
        title = '選択済みアイテム',
        menu = 'giftcode_item_selector',
        options = options
    })
    
    lib.showContext('giftcode_selected_items')
end

-- 管理者メニュー
local function openAdminMenu()
    local options = {
        {
            title = '📝 コード生成',
            description = '新しいギフトコードを生成',
            icon = 'plus',
            onSelect = function()
                openCreateCodeMenu()
            end
        },
        {
            title = '📦 一括コード生成',
            description = '複数のコードを一括生成',
            icon = 'copy',
            onSelect = function()
                openBulkCreateMenu()
            end
        },
        {
            title = '📋 コード一覧',
            description = 'すべてのコードを表示',
            icon = 'list',
            onSelect = function()
                openCodeListMenu()
            end
        },
        {
            title = '📊 統計',
            description = '使用統計を表示',
            icon = 'chart-bar',
            onSelect = function()
                openStatisticsMenu()
            end
        },
    }
    
    lib.registerContext({
        id = 'giftcode_admin_menu',
        title = 'ギフトコード管理',
        options = options
    })
    
    lib.showContext('giftcode_admin_menu')
end

-- コード生成メニュー
function openCreateCodeMenu()
    local input = lib.inputDialog('ギフトコード生成', {
        {
            type = 'input',
            label = 'カスタムコード (空欄でランダム)',
            placeholder = 'SUMMER2024',
            required = false
        },
        {
            type = 'select',
            label = '報酬タイプ',
            options = {
                { value = 'money', label = 'お金' },
                { value = 'items', label = 'アイテム' },
                { value = 'vehicle', label = '車両' },
                { value = 'mixed', label = '複合' }
            },
            required = true
        },
        {
            type = 'number',
            label = '最大使用回数',
            default = 1,
            min = 1,
            max = 9999,
            required = true
        },
        {
            type = 'number',
            label = '有効期限 (日数、0で無期限)',
            default = 0,
            min = 0,
            max = 365,
            required = false
        },
        {
            type = 'checkbox',
            label = '1人1回のみ使用可能',
            checked = true
        }
    })
    
    if not input then return end
    
    local rewardType = input[2]
    
    if rewardType == 'money' then
        openMoneyRewardInput(input)
    elseif rewardType == 'items' then
        selectedItems = {}
        showItemSelector('', function(items)
            local data = {
                customCode = input[1],
                maxUses = input[3],
                expireDays = input[4],
                onePerPlayer = input[5],
                items = items
            }
            createCode(data)
        end)
    elseif rewardType == 'vehicle' then
        openVehicleRewardInput(input)
    elseif rewardType == 'mixed' then
        openMixedRewardInput(input)
    end
end

-- お金報酬入力
function openMoneyRewardInput(baseInput)
    local input = lib.inputDialog('お金報酬設定', {
        {
            type = 'select',
            label = 'お金のタイプ',
            options = {
                { value = 'cash', label = '現金' },
                { value = 'bank', label = '銀行' },
                { value = 'crypto', label = '暗号通貨' }
            },
            required = true
        },
        {
            type = 'number',
            label = '金額',
            default = 1000,
            min = 1,
            required = true
        }
    })
    
    if not input then return end
    
    local data = {
        customCode = baseInput[1],
        maxUses = baseInput[3],
        expireDays = baseInput[4],
        onePerPlayer = baseInput[5],
        moneyType = input[1],
        moneyAmount = input[2]
    }
    
    createCode(data)
end

-- 車両報酬入力
function openVehicleRewardInput(baseInput)
    local input = lib.inputDialog('車両報酬設定', {
        {
            type = 'input',
            label = '車両モデル名',
            placeholder = 'adder',
            required = true
        }
    })
    
    if not input then return end
    
    local data = {
        customCode = baseInput[1],
        maxUses = baseInput[3],
        expireDays = baseInput[4],
        onePerPlayer = baseInput[5],
        vehicle = input[1]
    }
    
    createCode(data)
end

-- 複合報酬入力
function openMixedRewardInput(baseInput)
    local input = lib.inputDialog('複合報酬設定 (お金)', {
        {
            type = 'select',
            label = 'お金のタイプ (スキップする場合は選択しない)',
            options = {
                { value = 'none', label = 'なし' },
                { value = 'cash', label = '現金' },
                { value = 'bank', label = '銀行' },
                { value = 'crypto', label = '暗号通貨' }
            },
            required = false
        },
        {
            type = 'number',
            label = '金額',
            default = 0,
            min = 0,
            required = false
        }
    })
    
    if not input then return end
    
    local moneyType = input[1] ~= 'none' and input[1] or nil
    local moneyAmount = input[2] or 0
    
    -- アイテム設定
    local addItemPrompt = lib.alertDialog({
        header = 'アイテム追加',
        content = 'アイテムを追加しますか?',
        centered = true,
        cancel = true,
        labels = {
            confirm = 'はい',
            cancel = 'いいえ'
        }
    })
    
    if addItemPrompt == 'confirm' then
        selectedItems = {}
        showItemSelector('', function(items)
            -- 車両設定
            local vehiclePrompt = lib.alertDialog({
                header = '車両追加',
                content = '車両を追加しますか?',
                centered = true,
                cancel = true,
                labels = {
                    confirm = 'はい',
                    cancel = 'いいえ'
                }
            })
            
            local vehicle = nil
            
            if vehiclePrompt == 'confirm' then
                local vehicleInput = lib.inputDialog('車両設定', {
                    {
                        type = 'input',
                        label = '車両モデル名',
                        placeholder = 'adder',
                        required = true
                    }
                })
                
                if vehicleInput then
                    vehicle = vehicleInput[1]
                end
            end
            
            local data = {
                customCode = baseInput[1],
                maxUses = baseInput[3],
                expireDays = baseInput[4],
                onePerPlayer = baseInput[5],
                moneyType = moneyType,
                moneyAmount = moneyAmount,
                items = items,
                vehicle = vehicle
            }
            
            createCode(data)
        end)
    else
        -- 車両設定
        local vehiclePrompt = lib.alertDialog({
            header = '車両追加',
            content = '車両を追加しますか?',
            centered = true,
            cancel = true,
            labels = {
                confirm = 'はい',
                cancel = 'いいえ'
            }
        })
        
        local vehicle = nil
        
        if vehiclePrompt == 'confirm' then
            local vehicleInput = lib.inputDialog('車両設定', {
                {
                    type = 'input',
                    label = '車両モデル名',
                    placeholder = 'adder',
                    required = true
                }
            })
            
            if vehicleInput then
                vehicle = vehicleInput[1]
            end
        end
        
        local data = {
            customCode = baseInput[1],
            maxUses = baseInput[3],
            expireDays = baseInput[4],
            onePerPlayer = baseInput[5],
            moneyType = moneyType,
            moneyAmount = moneyAmount,
            items = nil,
            vehicle = vehicle
        }
        
        createCode(data)
    end
end

-- コード作成実行
function createCode(data)
    lib.callback('ng-giftcode:server:createCode', false, function(result)
        if result.success then
            notify(result.message, 'success')
            
            -- コードをクリップボードにコピー
            lib.setClipboard(result.code)
            notify('コードをクリップボードにコピーしました', 'info')
        else
            notify(result.message, 'error')
        end
    end, data)
end

-- 一括コード生成メニュー
function openBulkCreateMenu()
    local input = lib.inputDialog('一括ギフトコード生成', {
        {
            type = 'number',
            label = '生成数 (最大100)',
            default = 10,
            min = 1,
            max = 100,
            required = true
        },
        {
            type = 'select',
            label = '報酬タイプ',
            options = {
                { value = 'money', label = 'お金' },
                { value = 'items', label = 'アイテム' },
                { value = 'vehicle', label = '車両' }
            },
            required = true
        },
        {
            type = 'number',
            label = '最大使用回数',
            default = 1,
            min = 1,
            max = 9999,
            required = true
        },
        {
            type = 'number',
            label = '有効期限 (日数、0で無期限)',
            default = 0,
            min = 0,
            max = 365,
            required = false
        },
        {
            type = 'checkbox',
            label = '1人1回のみ使用可能',
            checked = true
        }
    })
    
    if not input then return end
    
    local amount = input[1]
    local rewardType = input[2]
    local baseInput = { nil, nil, input[3], input[4], input[5] }
    
    if rewardType == 'money' then
        openBulkMoneyRewardInput(amount, baseInput)
    elseif rewardType == 'items' then
        selectedItems = {}
        showItemSelector('', function(items)
            local data = {
                amount = amount,
                maxUses = baseInput[3],
                expireDays = baseInput[4],
                onePerPlayer = baseInput[5],
                items = items
            }
            createBulkCodes(data)
        end)
    elseif rewardType == 'vehicle' then
        openBulkVehicleRewardInput(amount, baseInput)
    end
end

-- 一括お金報酬
function openBulkMoneyRewardInput(amount, baseInput)
    local input = lib.inputDialog('お金報酬設定', {
        {
            type = 'select',
            label = 'お金のタイプ',
            options = {
                { value = 'cash', label = '現金' },
                { value = 'bank', label = '銀行' },
                { value = 'crypto', label = '暗号通貨' }
            },
            required = true
        },
        {
            type = 'number',
            label = '金額',
            default = 1000,
            min = 1,
            required = true
        }
    })
    
    if not input then return end
    
    local data = {
        amount = amount,
        maxUses = baseInput[3],
        expireDays = baseInput[4],
        onePerPlayer = baseInput[5],
        moneyType = input[1],
        moneyAmount = input[2]
    }
    
    createBulkCodes(data)
end

-- 一括車両報酬
function openBulkVehicleRewardInput(amount, baseInput)
    local input = lib.inputDialog('車両報酬設定', {
        {
            type = 'input',
            label = '車両モデル名',
            placeholder = 'adder',
            required = true
        }
    })
    
    if not input then return end
    
    local data = {
        amount = amount,
        maxUses = baseInput[3],
        expireDays = baseInput[4],
        onePerPlayer = baseInput[5],
        vehicle = input[1]
    }
    
    createBulkCodes(data)
end

-- 一括コード作成実行
function createBulkCodes(data)
    lib.callback('ng-giftcode:server:createBulkCodes', false, function(result)
        if result.success then
            notify(result.message, 'success')
            
            -- コードリストを表示
            if result.codes then
                local codesText = table.concat(result.codes, '\n')
                lib.setClipboard(codesText)
                notify('すべてのコードをクリップボードにコピーしました', 'info')
                
                -- コードリストを表示
                lib.alertDialog({
                    header = '生成されたコード',
                    content = codesText,
                    centered = true,
                    size = 'lg'
                })
            end
        else
            notify(result.message, 'error')
        end
    end, data)
end

-- コード一覧メニュー
function openCodeListMenu()
    lib.callback('ng-giftcode:server:getCodes', false, function(codes)
        if not codes or #codes == 0 then
            notify('コードが見つかりません', 'error')
            return
        end
        
        local options = {}
        
        for _, code in ipairs(codes) do
            -- boolean型をnumber型に変換
            local isActive = code.is_active
            if type(isActive) == 'boolean' then
                isActive = isActive and 1 or 0
            end
            
            local status = isActive == 1 and '🟢' or '🔴'
            local usage = code.current_uses .. '/' .. code.max_uses
            
            local rewards = {}
            if code.money_amount and code.money_amount > 0 then
                table.insert(rewards, '$' .. code.money_amount)
            end
            if code.items then
                table.insert(rewards, #code.items .. '種類のアイテム')
            end
            if code.vehicle then
                table.insert(rewards, '車両: ' .. code.vehicle)
            end
            
            table.insert(options, {
                title = status .. ' ' .. code.code,
                description = '使用: ' .. usage .. ' | ' .. table.concat(rewards, ', '),
                icon = 'ticket',
                onSelect = function()
                    openCodeDetailMenu(code.code)
                end
            })
        end
        
        lib.registerContext({
            id = 'giftcode_list_menu',
            title = 'コード一覧',
            menu = 'giftcode_admin_menu',
            options = options
        })
        
        lib.showContext('giftcode_list_menu')
    end)
end

-- コード詳細メニュー
function openCodeDetailMenu(code)
    lib.callback('ng-giftcode:server:getCodeDetails', false, function(codeData)
        if not codeData then
            notify('コード情報の取得に失敗しました', 'error')
            return
        end
        
        -- boolean型をnumber型に変換
        local isActive = codeData.is_active
        if type(isActive) == 'boolean' then
            isActive = isActive and 1 or 0
        end
        
        local options = {
            {
                title = '📋 コード情報',
                description = 'コード: ' .. codeData.code .. ' (クリックでコピー)',
                icon = 'copy',
                onSelect = function()
                    lib.setClipboard(codeData.code)
                    notify('コードをクリップボードにコピーしました: ' .. codeData.code, 'success')
                end
            },
            {
                title = '使用状況',
                description = codeData.current_uses .. '/' .. codeData.max_uses .. ' 回使用',
                icon = 'chart-line',
                disabled = true
            },
            {
                title = isActive == 1 and '🔴 無効化' or '🟢 有効化',
                description = 'コードの状態を切り替え',
                icon = 'power-off',
                onSelect = function()
                    toggleCode(code)
                end
            },
            {
                title = '✏️ 編集',
                description = 'コード内容を編集',
                icon = 'edit',
                onSelect = function()
                    openEditCodeMenu(code, codeData)
                end
            },
            {
                title = '🗑️ 削除',
                description = 'コードを完全に削除',
                icon = 'trash',
                onSelect = function()
                    deleteCode(code)
                end
            },
            {
                title = '📜 使用ログ',
                description = '使用履歴を表示',
                icon = 'history',
                onSelect = function()
                    openCodeLogsMenu(codeData)
                end
            }
        }
        
        lib.registerContext({
            id = 'giftcode_detail_menu',
            title = 'コード詳細: ' .. code,
            menu = 'giftcode_list_menu',
            options = options
        })
        
        lib.showContext('giftcode_detail_menu')
    end, code)
end

-- コード有効/無効切り替え
function toggleCode(code)
    local confirm = lib.alertDialog({
        header = '確認',
        content = 'コードの状態を切り替えますか?',
        centered = true,
        cancel = true
    })
    
    if confirm == 'confirm' then
        lib.callback('ng-giftcode:server:toggleCode', false, function(result)
            if result.success then
                notify(result.message, 'success')
                openCodeDetailMenu(code)
            else
                notify(result.message, 'error')
            end
        end, code)
    end
end

-- コード編集メニュー
function openEditCodeMenu(code, codeData)
    local options = {
        {
            title = '⚙️ 基本設定',
            description = '最大使用回数、有効期限、制限設定',
            icon = 'cog',
            onSelect = function()
                openEditBasicSettings(code, codeData)
            end
        },
        {
            title = '💰 お金',
            description = codeData.money_type and string.format('%s: $%d', codeData.money_type == 'cash' and '現金' or codeData.money_type == 'bank' and '銀行' or '暗号通貨', codeData.money_amount) or '未設定',
            icon = 'dollar-sign',
            onSelect = function()
                openEditMoneyMenu(code, codeData)
            end
        },
        {
            title = '📦 アイテム',
            description = codeData.items and #codeData.items .. '種類のアイテム' or '未設定',
            icon = 'box',
            onSelect = function()
                openEditItemsMenu(code, codeData)
            end
        },
        {
            title = '🚗 車両',
            description = codeData.vehicle or '未設定',
            icon = 'car',
            onSelect = function()
                openEditVehicleMenu(code, codeData)
            end
        },
    }
    
    lib.registerContext({
        id = 'giftcode_edit_menu',
        title = 'コード編集: ' .. code,
        menu = 'giftcode_detail_menu',
        options = options
    })
    
    lib.showContext('giftcode_edit_menu')
end

-- 基本設定編集
function openEditBasicSettings(code, codeData)
    local input = lib.inputDialog('基本設定編集', {
        {
            type = 'number',
            label = '最大使用回数',
            default = codeData.max_uses,
            min = 1,
            max = 9999,
            required = true
        },
        {
            type = 'number',
            label = '有効期限 (日数、0で無期限)',
            default = 0,
            min = 0,
            max = 365,
            required = false
        },
        {
            type = 'checkbox',
            label = '1人1回のみ使用可能',
            checked = codeData.one_per_player == 1
        }
    })
    
    if not input then return end
    
    local data = {
        maxUses = input[1],
        expireDays = input[2],
        onePerPlayer = input[3],
        -- 既存の報酬を保持
        moneyType = codeData.money_type,
        moneyAmount = codeData.money_amount,
        items = codeData.items,
        vehicle = codeData.vehicle
    }
    
    editCode(code, data)
end

-- お金編集メニュー
function openEditMoneyMenu(code, codeData)
    local options = {
        {
            title = '✏️ お金を設定/変更',
            description = '報酬のお金を設定',
            icon = 'edit',
            onSelect = function()
                local input = lib.inputDialog('お金設定', {
                    {
                        type = 'select',
                        label = 'お金のタイプ',
                        options = {
                            { value = 'cash', label = '現金' },
                            { value = 'bank', label = '銀行' },
                            { value = 'crypto', label = '暗号通貨' }
                        },
                        default = codeData.money_type or 'cash',
                        required = true
                    },
                    {
                        type = 'number',
                        label = '金額',
                        default = codeData.money_amount or 1000,
                        min = 0,
                        required = true
                    }
                })
                
                if not input then return end
                
                local data = {
                    maxUses = codeData.max_uses,
                    expireDays = 0,
                    onePerPlayer = codeData.one_per_player == 1,
                    moneyType = input[1],
                    moneyAmount = input[2],
                    items = codeData.items,
                    vehicle = codeData.vehicle
                }
                
                editCode(code, data)
            end
        },
    }
    
    if codeData.money_type then
        table.insert(options, {
            title = '🗑️ お金を削除',
            description = '報酬からお金を削除',
            icon = 'trash',
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = '確認',
                    content = 'お金の報酬を削除しますか?',
                    centered = true,
                    cancel = true
                })
                
                if confirm == 'confirm' then
                    local data = {
                        maxUses = codeData.max_uses,
                        expireDays = 0,
                        onePerPlayer = codeData.one_per_player == 1,
                        moneyType = nil,
                        moneyAmount = 0,
                        items = codeData.items,
                        vehicle = codeData.vehicle
                    }
                    
                    editCode(code, data)
                end
            end
        })
    end
    
    lib.registerContext({
        id = 'giftcode_edit_money_menu',
        title = 'お金編集',
        menu = 'giftcode_edit_menu',
        options = options
    })
    
    lib.showContext('giftcode_edit_money_menu')
end

-- アイテム編集メニュー
function openEditItemsMenu(code, codeData)
    local options = {}
    
    -- 既存アイテムを表示
    if codeData.items and #codeData.items > 0 then
        for i, item in ipairs(codeData.items) do
            table.insert(options, {
                title = (item.label or item.name) .. ' x' .. item.amount,
                description = 'クリックして編集または削除',
                icon = 'box',
                onSelect = function()
                    openEditSingleItem(code, codeData, i, item)
                end
            })
        end
        
        table.insert(options, {
            title = '---',
            disabled = true
        })
    end
    
    -- アイテム追加
    table.insert(options, {
        title = '➕ アイテムを追加',
        description = 'アイテムリストから選択',
        icon = 'plus',
        onSelect = function()
            selectedItems = {}
            showItemSelector('', function(items)
                -- 既存のアイテムに新しいアイテムを追加
                local newItems = codeData.items or {}
                for _, newItem in ipairs(items) do
                    table.insert(newItems, newItem)
                end
                
                local data = {
                    maxUses = codeData.max_uses,
                    expireDays = 0,
                    onePerPlayer = codeData.one_per_player == 1,
                    moneyType = codeData.money_type,
                    moneyAmount = codeData.money_amount,
                    items = newItems,
                    vehicle = codeData.vehicle
                }
                
                editCode(code, data)
            end)
        end
    })
    
    -- 全アイテム削除
    if codeData.items and #codeData.items > 0 then
        table.insert(options, {
            title = '🗑️ すべてのアイテムを削除',
            description = 'すべてのアイテムを削除',
            icon = 'trash',
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = '確認',
                    content = 'すべてのアイテムを削除しますか?',
                    centered = true,
                    cancel = true
                })
                
                if confirm == 'confirm' then
                    local data = {
                        maxUses = codeData.max_uses,
                        expireDays = 0,
                        onePerPlayer = codeData.one_per_player == 1,
                        moneyType = codeData.money_type,
                        moneyAmount = codeData.money_amount,
                        items = nil,
                        vehicle = codeData.vehicle
                    }
                    
                    editCode(code, data)
                end
            end
        })
    end
    
    lib.registerContext({
        id = 'giftcode_edit_items_menu',
        title = 'アイテム編集',
        menu = 'giftcode_edit_menu',
        options = options
    })
    
    lib.showContext('giftcode_edit_items_menu')
end

-- 個別アイテム編集
function openEditSingleItem(code, codeData, index, item)
    local options = {
        {
            title = '✏️ 数量を変更',
            description = '現在: ' .. item.amount,
            icon = 'edit',
            onSelect = function()
                local input = lib.inputDialog('数量変更', {
                    {
                        type = 'number',
                        label = '数量',
                        default = item.amount,
                        min = 1,
                        max = 999,
                        required = true
                    }
                })
                
                if input then
                    local newItems = {}
                    for i, v in ipairs(codeData.items) do
                        if i == index then
                            table.insert(newItems, { name = v.name, amount = input[1], label = v.label })
                        else
                            table.insert(newItems, v)
                        end
                    end
                    
                    local data = {
                        maxUses = codeData.max_uses,
                        expireDays = 0,
                        onePerPlayer = codeData.one_per_player == 1,
                        moneyType = codeData.money_type,
                        moneyAmount = codeData.money_amount,
                        items = newItems,
                        vehicle = codeData.vehicle
                    }
                    
                    editCode(code, data)
                end
            end
        },
        {
            title = '🗑️ 削除',
            description = 'このアイテムを削除',
            icon = 'trash',
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = '確認',
                    content = 'このアイテムを削除しますか?',
                    centered = true,
                    cancel = true
                })
                
                if confirm == 'confirm' then
                    local newItems = {}
                    for i, v in ipairs(codeData.items) do
                        if i ~= index then
                            table.insert(newItems, v)
                        end
                    end
                    
                    local data = {
                        maxUses = codeData.max_uses,
                        expireDays = 0,
                        onePerPlayer = codeData.one_per_player == 1,
                        moneyType = codeData.money_type,
                        moneyAmount = codeData.money_amount,
                        items = #newItems > 0 and newItems or nil,
                        vehicle = codeData.vehicle
                    }
                    
                    editCode(code, data)
                end
            end
        }
    }
    
    lib.registerContext({
        id = 'giftcode_edit_single_item',
        title = (item.label or item.name) .. ' x' .. item.amount,
        menu = 'giftcode_edit_items_menu',
        options = options
    })
    
    lib.showContext('giftcode_edit_single_item')
end

-- 車両編集メニュー
function openEditVehicleMenu(code, codeData)
    local options = {
        {
            title = '✏️ 車両を設定/変更',
            description = '報酬の車両を設定',
            icon = 'edit',
            onSelect = function()
                local input = lib.inputDialog('車両設定', {
                    {
                        type = 'input',
                        label = '車両モデル名',
                        placeholder = 'adder',
                        default = codeData.vehicle or '',
                        required = true
                    }
                })
                
                if not input then return end
                
                local data = {
                    maxUses = codeData.max_uses,
                    expireDays = 0,
                    onePerPlayer = codeData.one_per_player == 1,
                    moneyType = codeData.money_type,
                    moneyAmount = codeData.money_amount,
                    items = codeData.items,
                    vehicle = input[1]
                }
                
                editCode(code, data)
            end
        },
    }
    
    if codeData.vehicle then
        table.insert(options, {
            title = '🗑️ 車両を削除',
            description = '報酬から車両を削除',
            icon = 'trash',
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = '確認',
                    content = '車両の報酬を削除しますか?',
                    centered = true,
                    cancel = true
                })
                
                if confirm == 'confirm' then
                    local data = {
                        maxUses = codeData.max_uses,
                        expireDays = 0,
                        onePerPlayer = codeData.one_per_player == 1,
                        moneyType = codeData.money_type,
                        moneyAmount = codeData.money_amount,
                        items = codeData.items,
                        vehicle = nil
                    }
                    
                    editCode(code, data)
                end
            end
        })
    end
    
    lib.registerContext({
        id = 'giftcode_edit_vehicle_menu',
        title = '車両編集',
        menu = 'giftcode_edit_menu',
        options = options
    })
    
    lib.showContext('giftcode_edit_vehicle_menu')
end



-- コード編集実行
function editCode(code, data)
    lib.callback('ng-giftcode:server:editCode', false, function(result)
        if result.success then
            notify(result.message, 'success')
            openCodeDetailMenu(code)
        else
            notify(result.message, 'error')
        end
    end, code, data)
end

-- コード削除
function deleteCode(code)
    local confirm = lib.alertDialog({
        header = '確認',
        content = 'このコードを完全に削除しますか?\nこの操作は取り消せません。',
        centered = true,
        cancel = true,
        labels = {
            confirm = '削除',
            cancel = 'キャンセル'
        }
    })
    
    if confirm == 'confirm' then
        lib.callback('ng-giftcode:server:deleteCode', false, function(result)
            if result.success then
                notify(result.message, 'success')
                openCodeListMenu()
            else
                notify(result.message, 'error')
            end
        end, code)
    end
end

-- 使用ログメニュー
function openCodeLogsMenu(codeData)
    if not codeData.logs or #codeData.logs == 0 then
        notify('使用ログがありません', 'info')
        return
    end
    
    local options = {}
    
    for _, log in ipairs(codeData.logs) do
        local rewards = log.rewards and json.decode(log.rewards) or {}
        local rewardsText = table.concat(rewards, ', ')
        
        -- used_atをそのまま文字列として使用
        local timeStr = '不明'
        if log.used_at then
            if type(log.used_at) == 'string' then
                timeStr = log.used_at
            elseif type(log.used_at) == 'number' then
                timeStr = log.used_at
            end
        end
        
        table.insert(options, {
            title = log.player_name or 'Unknown',
            description = timeStr .. ' | ' .. rewardsText,
            icon = 'user',
            disabled = true
        })
    end
    
    lib.registerContext({
        id = 'giftcode_logs_menu',
        title = '使用ログ: ' .. codeData.code,
        menu = 'giftcode_detail_menu',
        options = options
    })
    
    lib.showContext('giftcode_logs_menu')
end

-- 統計メニュー
function openStatisticsMenu()
    lib.callback('ng-giftcode:server:getStatistics', false, function(stats)
        if not stats then
            notify('統計情報の取得に失敗しました', 'error')
            return
        end
        
        local options = {
            {
                title = '総コード数',
                description = tostring(stats.totalCodes) .. ' 個',
                icon = 'ticket',
                disabled = true
            },
            {
                title = '有効なコード',
                description = tostring(stats.activeCodes) .. ' 個',
                icon = 'check-circle',
                disabled = true
            },
            {
                title = '期限切れコード',
                description = tostring(stats.expiredCodes) .. ' 個',
                icon = 'clock',
                disabled = true
            },
            {
                title = '総使用回数',
                description = tostring(stats.totalUses) .. ' 回',
                icon = 'chart-line',
                disabled = true
            },
            {
                title = '今日の使用',
                description = tostring(stats.todayUses) .. ' 回',
                icon = 'calendar-day',
                disabled = true
            },
            {
                title = '今週の使用',
                description = tostring(stats.weekUses) .. ' 回',
                icon = 'calendar-week',
                disabled = true
            },
            {
                title = '最も使用されているコード',
                description = stats.topCode.code .. ' (' .. stats.topCode.uses .. '回)',
                icon = 'trophy',
                disabled = true
            }
        }
        
        lib.registerContext({
            id = 'giftcode_statistics_menu',
            title = 'ギフトコード統計',
            menu = 'giftcode_admin_menu',
            options = options
        })
        
        lib.showContext('giftcode_statistics_menu')
    end)
end

-- ギフトコード使用
local function useGiftCode(code)
    if not code or code == '' then
        notify('コードを入力してください', 'error')
        return
    end
    
    lib.callback('ng-giftcode:server:useCode', false, function(result)
        if result.success then
            notify(result.message, 'success')
            
            if result.rewards and #result.rewards > 0 then
                Wait(1000)
                notify('受け取った報酬: ' .. table.concat(result.rewards, ', '), 'success')
            end
        else
            notify(result.message, 'error')
        end
    end, code)
end

-- コード使用ダイアログ
local function openUseCodeDialog()
    local input = lib.inputDialog('ギフトコード使用', {
        {
            type = 'input',
            label = 'ギフトコード',
            placeholder = 'GIFT-XXXXXXXXXXXX',
            required = true
        }
    })
    
    if input and input[1] then
        useGiftCode(input[1])
    end
end

-- イベント登録
RegisterNetEvent('ng-giftcode:client:openAdminMenu', function()
    openAdminMenu()
end)

RegisterNetEvent('ng-giftcode:client:useCode', function(code)
    if code then
        useGiftCode(code)
    else
        openUseCodeDialog()
    end
end)

-- キーバインド登録
RegisterCommand('usegiftcode', function()
    openUseCodeDialog()
end, false)

print('^2[ng-giftcode]^7 Client initialized successfully')
