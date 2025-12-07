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
    -- ox_inventoryのclient imageが存在する場合
    if itemData.client and itemData.client.image then
        local imagePath = itemData.client.image
        
        -- URLの場合(http:// または https:// で始まる)
        if string.match(imagePath, '^https?://') then
            return imagePath
        end
        
        -- nui:// で始まる場合(既に完全パス)
        if string.match(imagePath, '^nui://') then
            return imagePath
        end
        
        -- 相対パスの場合、ox_inventoryのベースパスを追加
        if not string.match(imagePath, '^/') then
            return string.format('nui://ox_inventory/web/images/%s', imagePath)
        end
        
        -- 絶対パス(/から始まる)の場合
        return string.format('nui://ox_inventory%s', imagePath)
    end
    
    -- デフォルトのox_inventory画像パス
    return string.format('nui://ox_inventory/web/images/%s.png', itemName)
end

-- アイテムリストを表示する関数
local function ShowInventoryItems(searchText)
    local allItems = exports.ox_inventory:Items()
    local filteredItems = filterItems(allItems, searchText)
    local options = {}

    -- 検索バーオプション
    table.insert(options, {
        title = '🔍 アイテムを検索',
        description = '検索ワードを入力してください',
        onSelect = function()
            local input = lib.inputDialog('アイテム検索', {
                { type = 'input', label = '検索ワード', description = 'アイテム名や説明、日本語名で検索できます' }
            })
            if input then
                ShowInventoryItems(input[1])
            end
        end
    })

    -- 区切り線
    table.insert(options, {
        title = '-------------------',
        disabled = true
    })

    -- アイテムリストの作成
    for k, v in pairs(filteredItems) do
        table.insert(options, {
            title = v.label or k,
            description = v.description or '説明なし',
            image = getItemImage(k, v),
            metadata = {
                { label = 'アイテムID', value = k },
                { label = '重量', value = v.weight or 0 },
                { label = 'スタック可能', value = v.stack and '可能' or '不可能' }
            },
            onSelect = function()
                -- アイテム名をクリップボードにコピー
                lib.setClipboard(k)
                
                -- 通知を表示
                lib.notify({
                    title = v.label or k,
                    description = 'アイテム名をコピーしました',
                    type = 'success'
                })
            end
        })
    end

    -- 検索結果の表示
    if searchText and searchText ~= '' then
        local resultCount = #options - 2
        table.insert(options, 2, {
            title = string.format('検索結果: %d 件', resultCount),
            disabled = true
        })
    end

    -- メニューの表示
    lib.registerContext({
        id = 'inventory_items',
        title = 'アイテム一覧',
        options = options,
        position = 'center-right'
    })

    lib.showContext('inventory_items')
end

-- コマンドの登録
RegisterCommand('items', function()
    ShowInventoryItems()
end, false)