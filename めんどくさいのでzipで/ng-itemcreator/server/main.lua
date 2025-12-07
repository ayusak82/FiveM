local debug = true

-- アイテムタイプの検証
local function validateItemType(itemType)
    for _, validType in ipairs(Config.ItemTypes) do
        if itemType == validType then
            return true
        end
    end
    return false
end

-- アイテムデータの標準化
local function normalizeItemData(itemData)
    -- 基本プロパティの設定
    itemData.weight = math.floor(tonumber(itemData.weight) or Config.DefaultSettings.weight)
    
    -- クライアント設定の準備
    local clientData = {
        status = {},
        export = Config.DefaultSettings.client.export or nil,
        image = itemData.imageUrl,
        usetime = nil,
        anim = nil
    }

    -- 消費アイテムの効果設定
    if Config.ConsumableEffects[itemData.type] then
        -- クライアントから送られてきたステータス値をそのまま使用
        if itemData.client and itemData.client.status then
            clientData.status = {
                hunger = itemData.client.status.hunger,  -- すでに10000が掛けられた値
                thirst = itemData.client.status.thirst,
                stress = itemData.client.status.stress
            }
        end

        -- アイテムタイプに応じた使用時間とアニメーションを設定
        if itemData.type == 'food' then
            clientData.usetime = 6000   -- 6秒
            clientData.anim = {
                dict = 'mp_player_inteat@burger',
                clip = 'mp_player_int_eat_burger',
                flag = 49
            }
        elseif itemData.type == 'drink' then
            clientData.usetime = 6000   -- 6秒
            clientData.anim = {
                dict = 'mp_player_intdrink',
                clip = 'loop_bottle',
                flag = 49
            }
        elseif itemData.type == 'stress' then
            clientData.usetime = 10000   -- 10秒
            clientData.anim = {
                dict = "amb@world_human_aa_smoke@male@idle_a",
                clip = "idle_c",
                flag = 49
            }
        end

        itemData.consume = 1
    end

    -- 最終的なアイテムデータ
    return {
        label = itemData.label,
        description = itemData.description,
        weight = itemData.weight,
        stack = true,
        close = true,
        consume = itemData.consume,
        client = clientData
    }
end

-- items.luaのバックアップを作成
local function createItemsBackup()
    local content = LoadResourceFile('ox_inventory', 'data/items.lua')
    if not content then
        return false
    end
    
    -- バックアップを保存
    local success = SaveResourceFile('ox_inventory', 'data/items.lua.bak', content, -1)
    if not success then
        return false
    end
    
    return true
end

-- テーブルをLua形式の文字列に変換
local function serializeTable(tbl, indent)
    indent = indent or "    "
    local result = "{\n"
    for k, v in pairs(tbl) do
        if type(k) == "string" then
            result = result .. indent .. string.format("['%s'] = ", k)
        else
            result = result .. indent .. string.format("[%s] = ", tostring(k))
        end
        
        if type(v) == "table" then
            result = result .. serializeTable(v, indent .. "    ") .. ",\n"
        elseif type(v) == "string" then
            result = result .. string.format("'%s',\n", v)
        else
            result = result .. tostring(v) .. ",\n"
        end
    end
    result = result .. indent:sub(1, -5) .. "}"
    return result
end

-- items.luaを更新
local function updateOxInventoryItems(newItems)
    return exports["ox_inventory"]:updateOxInventoryItems(newItems)
end

-- アイテムの存在チェック関数を追加
local function itemExists(itemName)
    -- ox_inventoryからアイテムデータを取得
    local items = exports.ox_inventory:Items()
    -- 指定された名前のアイテムが存在するかチェック
    return items[itemName] ~= nil
end

-- アイテムを登録する関数を修正
local function registerNewItem(itemData)

    -- アイテムの重複チェック
    if itemExists(itemData.name) then
        return false, "同じ名前のアイテムが既に存在します"
    end

    -- アイテムデータの標準化
    local normalizedData = normalizeItemData(itemData)
    
    -- ox_inventoryのitems.luaを更新
    local success, message = updateOxInventoryItems({
        [itemData.name] = normalizedData
    })
    
    if not success then
        return false, message
    end
    
    return true, "アイテムが作成されました"
end

-- アイテムリストの取得
lib.callback.register('ng-itemcreator:server:getItems', function(source)
    local items = exports.ox_inventory:Items()
    return items
end)

-- アイテムの削除
lib.callback.register('ng-itemcreator:server:deleteItem', function(source, itemName)
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then 
        return false, "プレイヤーが見つかりません" 
    end

    -- 権限チェック
    local job = Player.PlayerData.job
    if not Config.AllowedJobs[job.name] or job.grade.level < Config.AllowedJobs[job.name] then
        return false, "権限がありません"
    end

    -- 自分のジョブのアイテムかチェック
    if not string.match(itemName, "^" .. job.name .. "_") then
        return false, "このアイテムを削除する権限がありません"
    end

    -- アイテムの存在確認
    if not exports["ox_inventory"]:itemExists(itemName) then
        return false, "アイテムが見つかりません"
    end

    -- アイテムの削除
    local success, message = exports["ox_inventory"]:removeItem(itemName)
    return success, message
end)

-- コールバックの登録
lib.callback.register('ng-itemcreator:server:createItemWithImage', function(source, itemData)
    
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then 
        return false, "プレイヤーが見つかりません" 
    end

    -- 権限チェック
    local job = Player.PlayerData.job
    if not Config.AllowedJobs[job.name] or job.grade.level < Config.AllowedJobs[job.name] then
        return false, "権限がありません"
    end

    -- アイテム名の重複チェックを追加
    if itemExists(itemData.name) then
        return false, "同じ名前のアイテムが既に存在します"
    end

    -- データのバリデーション
    if type(itemData) ~= 'table' then
        return false, "無効なデータ形式です"
    end

    -- アイテム名の検証
    if not string.match(itemData.name, "^" .. job.name .. "_%w+$") then
        return false, string.format("アイテム名は '%s_' で始まる英数字である必要があります", job.name)
    end

    -- アイテムタイプの検証
    if not validateItemType(itemData.type) then
        return false, "無効なアイテムタイプです"
    end

    -- 必須フィールドのチェック
    local required = {
        name = 'string',
        label = 'string',
        description = 'string',
        weight = 'number',
        imageUrl = 'string',
        type = 'string'
    }

    for field, expectedType in pairs(required) do
        local value = itemData[field]
        if type(value) ~= expectedType then
            return false, string.format("フィールド '%s' が無効です", field)
        end
    end

    -- 重量の検証
    if itemData.weight <= 0 then
        return false, "重量は0より大きい値を指定してください"
    end

    -- URLの検証
    if not string.match(itemData.imageUrl, "^https://gazou1.dlup.by/") then
        return false, "許可されていないドメインです"
    end

    -- アイテムを登録
    return registerNewItem(itemData)
end)

-- 既存のコールバック
lib.callback.register('ng-itemcreator:server:checkPermission', function(source)
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return false end

    local job = Player.PlayerData.job
    if not Config.AllowedJobs[job.name] then return false end
    
    return job.grade.level >= Config.AllowedJobs[job.name]
end)

lib.callback.register('ng-itemcreator:server:getPlayerJob', function(source)
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return nil end
    return Player.PlayerData.job.name
end)

lib.callback.register('ng-itemcreator:server:checkAdminPermission', function(source)
    return IsPlayerAceAllowed(source, 'command.admin')
end)

-- リソース起動時の処理
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        
        -- ox_inventoryが利用可能か確認
        if not exports.ox_inventory then
            return
        end
        
    end
end)