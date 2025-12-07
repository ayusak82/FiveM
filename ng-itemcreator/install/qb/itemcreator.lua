-- qb-core用のアイテム管理システム
-- qb-core/server/itemcreator.lua として配置

local QBCore = exports['qb-core']:GetCoreObject()

-- qb-core用のアイテムシリアル化
local function serializeQbItem(name, data)
    local itemStr = string.format('    ["%s"] = {\n', name)
    itemStr = itemStr .. string.format('        ["name"] = "%s",\n', name)
    itemStr = itemStr .. string.format('        ["label"] = "%s",\n', data.label)
    itemStr = itemStr .. string.format('        ["weight"] = %s,\n', tostring(data.weight))
    itemStr = itemStr .. '        ["type"] = "item",\n'
    itemStr = itemStr .. string.format('        ["image"] = "%s.png",\n', name)
    itemStr = itemStr .. '        ["unique"] = false,\n'
    itemStr = itemStr .. '        ["useable"] = true,\n'
    itemStr = itemStr .. '        ["shouldClose"] = true,\n'
    itemStr = itemStr .. '        ["combinable"] = nil,\n'
    
    if data.description then
        itemStr = itemStr .. string.format('        ["description"] = "%s",\n', data.description)
    end
    
    itemStr = itemStr .. '    },\n'
    return itemStr
end

-- qb-coreのitems.luaを更新
local function updateQbCoreItems(newItems)
    local content = LoadResourceFile('qb-core', 'shared/items.lua') or ""
    if content == "" then
        return false, "qb-core/shared/items.luaの読み込みに失敗しました"
    end

    -- バックアップを作成
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local backupSuccess = SaveResourceFile('qb-core', string.format('shared/items_%s.lua.bak', timestamp), content, -1)
    if not backupSuccess then
        print("^3[QB-Core ItemCreator]^7 警告: バックアップの作成に失敗しました")
    end

    -- QBShared.Items = { の後と最後の } を見つける
    local startPattern = "QBShared%.Items%s*=%s*{"
    local startPos = content:find(startPattern)
    if not startPos then
        return false, "qb-core items.luaでQBShared.Itemsが見つかりません"
    end

    -- QBShared.Items = { の終わりを見つける
    local afterStart = content:find("{", startPos) + 1
    
    -- 対応する閉じブレースを見つける
    local pos = afterStart
    local level = 1
    local endPos
    
    while pos <= #content and level > 0 do
        local char = content:sub(pos, pos)
        if char == "{" then
            level = level + 1
        elseif char == "}" then
            level = level - 1
        end
        pos = pos + 1
    end
    
    endPos = pos - 1
    
    if level ~= 0 then
        return false, "qb-core items.luaの形式が無効です"
    end

    -- 新しいアイテムを追加
    local preContent = content:sub(1, endPos-1)
    local postContent = content:sub(endPos)

    -- 新しいアイテムを追加
    for name, data in pairs(newItems) do
        preContent = preContent .. "\n" .. serializeQbItem(name, data)
    end

    -- 新しいコンテンツを結合
    local newContent = preContent .. postContent

    -- 新しいデータを書き込み
    local success = SaveResourceFile('qb-core', 'shared/items.lua', newContent, -1)
    if not success then
        return false, "qb-core items.luaの書き込みに失敗しました"
    end

    -- QBCoreのShared.Itemsテーブルを動的に更新
    for name, data in pairs(newItems) do
        QBCore.Shared.Items[name] = {
            name = name,
            label = data.label,
            weight = data.weight,
            type = "item",
            image = name .. ".png",
            unique = false,
            useable = true,
            shouldClose = true,
            combinable = nil,
            description = data.description
        }
    end

    return true, "qb-coreアイテムデータを更新しました"
end

-- アイテムをqb-coreから削除する関数
local function removeQbItem(itemName)
    local content = LoadResourceFile('qb-core', 'shared/items.lua') or ""
    if content == "" then
        return false, "qb-core items.luaの読み込みに失敗しました"
    end

    -- バックアップを作成
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local backupSuccess = SaveResourceFile('qb-core', string.format('shared/items_%s.lua.bak', timestamp), content, -1)
    if not backupSuccess then
        print("^3[QB-Core ItemCreator]^7 警告: バックアップの作成に失敗しました")
    end

    -- アイテム定義の開始パターンを作成
    local escapedName = itemName:gsub("[-%.%+%*%?%^%$%(%)%[%]%%]", "%%%1")
    local startPattern = '%["' .. escapedName .. '"%]%s*=%s*{'

    -- アイテムの開始位置を検索
    local startPos = content:find(startPattern)
    if not startPos then
        return false, "qb-coreで指定されたアイテムが見つかりません"
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
        return false, "qb-coreアイテム定義の終了位置が見つかりません"
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

    -- 新しいデータを書き込み
    local success = SaveResourceFile('qb-core', 'shared/items.lua', newContent, -1)
    if not success then
        return false, "qb-core items.luaの書き込みに失敗しました"
    end

    -- QBCoreのShared.Itemsテーブルからも削除
    if QBCore.Shared.Items[itemName] then
        QBCore.Shared.Items[itemName] = nil
    end

    return true, "qb-coreからアイテムを削除しました"
end

-- アイテムの存在確認関数
local function itemExists(itemName)
    return QBCore.Shared.Items[itemName] ~= nil
end

-- アイテム一覧の取得
local function getItems()
    return QBCore.Shared.Items
end

-- エクスポート関数の登録
exports('addItem', updateQbCoreItems)
exports('removeItem', removeQbItem)
exports('itemExists', itemExists)
exports('getItems', getItems)

print("^2[QB-Core ItemCreator]^7 QB-Core用アイテム管理システムが読み込まれました")