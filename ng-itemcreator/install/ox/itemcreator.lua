-- ox_inventory用のアイテム管理システム
-- ox_inventory/server/itemcreator.lua として配置

-- ox_inventory用のアイテムシリアル化
local function serializeOxItem(name, data)
    local itemStr = string.format('    ["%s"] = {\n', name)
    itemStr = itemStr .. string.format('        label = "%s",\n', data.label)
    itemStr = itemStr .. string.format('        weight = %s,\n', tostring(data.weight))
    
    if data.stack ~= nil then
        itemStr = itemStr .. string.format('        stack = %s,\n', tostring(data.stack))
    else
        itemStr = itemStr .. '        stack = true,\n'
    end
    
    itemStr = itemStr .. '        close = true,\n'
    
    if data.consume then
        itemStr = itemStr .. string.format('        consume = %s,\n', tostring(data.consume))
    end
    
    if data.description then
        itemStr = itemStr .. string.format('        description = "%s",\n', data.description)
    end
    
    -- クライアントデータの処理
    if data.client then
        itemStr = itemStr .. '        client = {\n'
        
        -- status項目がある場合のみ追加
        if data.client.status and next(data.client.status) then
            itemStr = itemStr .. '            status = {\n'
            for statusKey, statusValue in pairs(data.client.status) do
                if statusValue then  -- 値が存在する場合のみ追加
                    itemStr = itemStr .. string.format('                %s = %s,\n', statusKey, tostring(statusValue))
                end
            end
            itemStr = itemStr .. '            },\n'
        end

        if data.client.image then
            itemStr = itemStr .. string.format('            image = "%s",\n', data.client.image)
        end

        -- disable設定
        itemStr = itemStr .. '            disable = {\n'
        itemStr = itemStr .. '                move = false,\n'
        itemStr = itemStr .. '                car = false,\n'
        itemStr = itemStr .. '                combat = false\n'
        itemStr = itemStr .. '            },\n'

        -- usetime設定
        if data.client.usetime then
            itemStr = itemStr .. string.format('            usetime = %d,\n', data.client.usetime)
        end

        -- アニメーション設定
        if data.client.anim then
            itemStr = itemStr .. '            anim = {\n'
            itemStr = itemStr .. string.format('                dict = "%s",\n', data.client.anim.dict)
            itemStr = itemStr .. string.format('                clip = "%s",\n', data.client.anim.clip)
            itemStr = itemStr .. string.format('                flag = %d\n', data.client.anim.flag)
            itemStr = itemStr .. '            },\n'
        end

        -- プロップ設定
        if data.client.prop then
            itemStr = itemStr .. '            prop = {\n'
            itemStr = itemStr .. string.format('                model = `%s`,\n', data.client.prop.model)
            if data.client.prop.bone then
                itemStr = itemStr .. string.format('                bone = %d,\n', data.client.prop.bone)
            end
            if data.client.prop.pos then
                itemStr = itemStr .. string.format('                pos = vec3(%.2f, %.2f, %.2f),\n', 
                    data.client.prop.pos.x, data.client.prop.pos.y, data.client.prop.pos.z)
            end
            if data.client.prop.rot then
                itemStr = itemStr .. string.format('                rot = vec3(%.2f, %.2f, %.2f)\n', 
                    data.client.prop.rot.x, data.client.prop.rot.y, data.client.prop.rot.z)
            end
            itemStr = itemStr .. '            },\n'
        end
        
        itemStr = itemStr .. '        },\n'
    end
    
    itemStr = itemStr .. '    },\n'
    return itemStr
end

-- ox_inventoryのitems.luaを更新
local function updateOxInventoryItems(newItems)
    local content = LoadResourceFile('ox_inventory', 'data/items.lua') or ""
    if content == "" then
        return false, "ox_inventory/data/items.luaの読み込みに失敗しました"
    end

    -- バックアップを作成
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local backupSuccess = SaveResourceFile('ox_inventory', string.format('data/items_%s.lua.bak', timestamp), content, -1)
    if not backupSuccess then
        print("^3[OX-Inventory ItemCreator]^7 警告: バックアップの作成に失敗しました")
    end

    -- 末尾の "}" を見つける
    local endPos = content:find("}%s*$")
    if not endPos then
        return false, "ox_inventory items.luaの形式が無効です"
    end

    -- 新しいアイテムを追加
    local newContent = content:sub(1, endPos-1) -- 末尾の "}" を除去

    -- 新しいアイテムを追加
    for name, data in pairs(newItems) do
        newContent = newContent .. "\n" .. serializeOxItem(name, data)
    end

    -- ファイルを閉じる
    newContent = newContent .. "}\n"

    -- 新しいデータを書き込み
    local success = SaveResourceFile('ox_inventory', 'data/items.lua', newContent, -1)
    if not success then
        return false, "ox_inventory items.luaの書き込みに失敗しました"
    end

    -- ox_inventoryのアイテムテーブルを動的に更新（可能な場合）
    if exports.ox_inventory and exports.ox_inventory.Items then
        for name, data in pairs(newItems) do
            local items = exports.ox_inventory:Items()
            if items then
                items[name] = data
            end
        end
    end

    return true, "ox_inventoryアイテムデータを更新しました"
end

-- アイテムをox_inventoryから削除する関数
local function removeOxItem(itemName)
    local content = LoadResourceFile('ox_inventory', 'data/items.lua') or ""
    if content == "" then
        return false, "ox_inventory items.luaの読み込みに失敗しました"
    end

    -- バックアップを作成
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local backupSuccess = SaveResourceFile('ox_inventory', string.format('data/items_%s.lua.bak', timestamp), content, -1)
    if not backupSuccess then
        print("^3[OX-Inventory ItemCreator]^7 警告: バックアップの作成に失敗しました")
    end

    -- アイテム定義の開始パターンを作成
    local escapedName = itemName:gsub("[-%.%+%*%?%^%$%(%)%[%]%%]", "%%%1")
    local startPattern = '%["' .. escapedName .. '"%]%s*=%s*{'

    -- アイテムの開始位置を検索
    local startPos = content:find(startPattern)
    if not startPos then
        return false, "ox_inventoryで指定されたアイテムが見つかりません"
    end

    -- アイテム定義の終了位置を見つける
    local pos = startPos
    local level = 0
    local foundEnd = false
    local endPos

    while pos <= #content do
        local char = content:sub(pos, pos)
        
        if char == "{" then
            level = level + 1
        elseif char == "}" then
            level = level - 1
            if level == 0 then
                -- 次のカンマまたは改行を探す
                local nextChar = content:match("^[,\n]%s*", pos + 1)
                endPos = pos + (nextChar and #nextChar or 0)
                foundEnd = true
                break
            end
        end
        pos = pos + 1
    end

    if not foundEnd then
        return false, "ox_inventoryアイテム定義の終了位置が見つかりません"
    end

    -- アイテム定義の前後のコンテンツを取得
    local preContent = content:sub(1, startPos - 1)
    local postContent = content:sub(endPos + 1)

    -- 前後の余分な空行を削除
    preContent = preContent:gsub("%s*$", "")
    postContent = postContent:gsub("^%s*", "\n")

    -- 新しいコンテンツを作成
    local newContent = preContent .. postContent

    -- 連続する空行を単一の空行に置換
    newContent = newContent:gsub("\n%s*\n%s*\n", "\n\n")

    -- ファイルの末尾が適切に閉じられていることを確認
    if not newContent:match("}%s*$") then
        newContent = newContent .. "}\n"
    end

    -- 新しいデータを書き込み
    local success = SaveResourceFile('ox_inventory', 'data/items.lua', newContent, -1)
    if not success then
        return false, "ox_inventory items.luaの書き込みに失敗しました"
    end

    -- ox_inventoryのアイテムテーブルからも削除（可能な場合）
    if exports.ox_inventory and exports.ox_inventory.Items then
        local items = exports.ox_inventory:Items()
        if items and items[itemName] then
            items[itemName] = nil
        end
    end

    return true, "ox_inventoryからアイテムを削除しました"
end

-- アイテムの存在確認関数
local function itemExists(itemName)
    if exports.ox_inventory and exports.ox_inventory.Items then
        local items = exports.ox_inventory:Items()
        return items and items[itemName] ~= nil
    else
        -- ファイルベースで確認
        local content = LoadResourceFile('ox_inventory', 'data/items.lua') or ""
        if content == "" then
            return false
        end
        
        local escapedName = itemName:gsub("[-%.%+%*%?%^%$%(%)%[%]%%]", "%%%1")
        return content:match('%["' .. escapedName .. '"%]%s*=%s*{') ~= nil
    end
end

-- アイテム一覧の取得
local function getItems()
    if exports.ox_inventory and exports.ox_inventory.Items then
        return exports.ox_inventory:Items()
    else
        return {}
    end
end

-- エクスポート関数の登録
exports('addItem', updateOxInventoryItems)
exports('removeItem', removeOxItem)
exports('itemExists', itemExists)
exports('getItems', getItems)

print("^2[OX-Inventory ItemCreator]^7 OX-Inventory用アイテム管理システムが読み込まれました")