local debug = true
local QBCore = exports['qb-core']:GetCoreObject()

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
        anim = nil,
        prop = nil
    }

    -- 消費アイテムの効果設定
    if Config.ConsumableEffects[itemData.type] then
        -- クライアントから送られてきたステータス値をそのまま使用（nilのものは除外）
        if itemData.client and itemData.client.status then
            local status = {}
            if itemData.client.status.hunger then
                status.hunger = itemData.client.status.hunger
            end
            if itemData.client.status.thirst then
                status.thirst = itemData.client.status.thirst
            end
            if itemData.client.status.stress then
                status.stress = itemData.client.status.stress
            end
            clientData.status = status
        end

        -- アニメーションの設定
        if itemData.animation and itemData.animation ~= 'なし' then
            local animConfig = Config.Animations[itemData.animation]
            if animConfig and animConfig.dict then
                clientData.anim = {
                    dict = animConfig.dict,
                    clip = animConfig.clip,
                    flag = animConfig.flag
                }
            end
        else
            -- アニメーションが選択されていない場合、タイプに応じたデフォルトアニメーションを設定
            if itemData.type == 'food' then
                clientData.anim = {
                    dict = 'mp_player_inteat@burger',
                    clip = 'mp_player_int_eat_burger',
                    flag = 49
                }
            elseif itemData.type == 'drink' then
                clientData.anim = {
                    dict = 'mp_player_intdrink',
                    clip = 'loop_bottle',
                    flag = 49
                }
            elseif itemData.type == 'stress' then
                clientData.anim = {
                    dict = "amb@world_human_aa_smoke@male@idle_a",
                    clip = "idle_c",
                    flag = 49
                }
            end
        end

        -- プロップの設定
        if itemData.prop and itemData.prop ~= 'なし' then
            local propConfig = Config.Props[itemData.prop]
            if propConfig and propConfig.model then
                clientData.prop = {
                    model = propConfig.model,
                    bone = propConfig.bone,
                    pos = propConfig.pos,
                    rot = propConfig.rot
                }
            end
        end

        -- 使用時間の設定
        if itemData.useTime and itemData.useTime > 0 then
            clientData.usetime = itemData.useTime
        else
            -- デフォルトの使用時間
            if itemData.type == 'food' or itemData.type == 'drink' then
                clientData.usetime = 3000
            elseif itemData.type == 'stress' then
                clientData.usetime = 6000
            end
        end

        itemData.consume = 1
    end

    -- 最終的なアイテムデータ
    return {
        label = itemData.label,
        description = itemData.description,
        weight = itemData.weight,
        stack = itemData.stack and true or false,
        close = true,
        consume = itemData.consume,
        client = clientData
    }
end

-- アイテムの存在チェック関数
local function itemExists(itemName)
    -- qb-coreで確認
    local qbExists = exports['qb-core']:itemExists(itemName)
    
    -- ox_inventoryで確認
    local oxExists = exports['ox_inventory']:itemExists(itemName)
    
    return qbExists or oxExists
end

-- アイテムを両方のシステムに登録する関数
local function registerNewItem(itemData)
    -- アイテムの重複チェック
    if itemExists(itemData.name) then
        return false, "同じ名前のアイテムが既に存在します"
    end

    -- アイテムデータの標準化
    local normalizedData = normalizeItemData(itemData)
    
    local results = {}
    local errors = {}
    
    -- qb-coreに追加を試行
    local qbSuccess, qbMessage = exports['qb-core']:addItem({
        [itemData.name] = normalizedData
    })
    
    if qbSuccess then
        table.insert(results, "QB-Core: " .. qbMessage)
    else
        table.insert(errors, "QB-Core: " .. qbMessage)
    end
    
    -- ox_inventoryに追加を試行
    local oxSuccess, oxMessage = exports['ox_inventory']:addItem({
        [itemData.name] = normalizedData
    })
    
    if oxSuccess then
        table.insert(results, "OX-Inventory: " .. oxMessage)
    else
        table.insert(errors, "OX-Inventory: " .. oxMessage)
    end
    
    -- 結果の評価
    if #errors > 0 then
        local errorMsg = "以下のエラーが発生しました:\n" .. table.concat(errors, "\n")
        if #results > 0 then
            errorMsg = errorMsg .. "\n\n成功:\n" .. table.concat(results, "\n")
        end
        return false, errorMsg
    end
    
    return true, "アイテムが正常に作成されました:\n" .. table.concat(results, "\n")
end

-- 両方のシステムからアイテムを削除する関数
local function deleteItemFromBothSystems(itemName)
    local results = {}
    local errors = {}
    
    -- qb-coreから削除を試行
    local qbSuccess, qbMessage = exports['qb-core']:removeItem(itemName)
    
    if qbSuccess then
        table.insert(results, "QB-Core: " .. qbMessage)
    else
        table.insert(errors, "QB-Core: " .. qbMessage)
    end
    
    -- ox_inventoryから削除を試行
    local oxSuccess, oxMessage = exports['ox_inventory']:removeItem(itemName)
    
    if oxSuccess then
        table.insert(results, "OX-Inventory: " .. oxMessage)
    else
        table.insert(errors, "OX-Inventory: " .. oxMessage)
    end
    
    -- 結果の評価
    if #errors > 0 then
        local errorMsg = "以下のエラーが発生しました:\n" .. table.concat(errors, "\n")
        if #results > 0 then
            errorMsg = errorMsg .. "\n\n成功:\n" .. table.concat(results, "\n")
        end
        return false, errorMsg
    end
    
    return true, "アイテムが正常に削除されました:\n" .. table.concat(results, "\n")
end

-- アイテムリストの取得（ox_inventoryを優先）
lib.callback.register('ng-itemcreator:server:getItems', function(source)
    -- まずox_inventoryから取得を試行
    local oxItems = exports['ox_inventory']:getItems()
    if oxItems and next(oxItems) then
        return oxItems
    end
    
    -- フォールバック: qb-coreから取得
    local qbItems = exports['qb-core']:getItems()
    if qbItems and next(qbItems) then
        return qbItems
    end
    
    -- 両方とも失敗した場合は空のテーブルを返す
    return {}
end)

-- アイテムの削除
lib.callback.register('ng-itemcreator:server:deleteItem', function(source, itemName)
    local Player = QBCore.Functions.GetPlayer(source)
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
    if not itemExists(itemName) then
        return false, "アイテムが見つかりません"
    end

    -- 両方のシステムからアイテムを削除
    return deleteItemFromBothSystems(itemName)
end)

-- アイテム作成のメインコールバック
lib.callback.register('ng-itemcreator:server:createItemWithImage', function(source, itemData)
    
    local Player = QBCore.Functions.GetPlayer(source)
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
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end

    local job = Player.PlayerData.job
    if not Config.AllowedJobs[job.name] then return false end
    
    return job.grade.level >= Config.AllowedJobs[job.name]
end)

lib.callback.register('ng-itemcreator:server:getPlayerJob', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return nil end
    return Player.PlayerData.job.name
end)

-- リソース起動時の処理
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        print('^2[NG-ItemCreator]^7 Export版として起動しました')
        
        -- qb-coreのexportが利用可能か確認
        local qbSuccess, qbError = pcall(function()
            return exports['qb-core']:getItems()
        end)
        
        if not qbSuccess then
            print('^1[NG-ItemCreator]^7 エラー: qb-coreのexportが利用できません')
            print('^1[NG-ItemCreator]^7 qb-core/server/itemcreator.luaが正しく配置されているか確認してください')
        else
            print('^2[NG-ItemCreator]^7 QB-Core export接続成功')
        end
        
        -- ox_inventoryのexportが利用可能か確認
        local oxSuccess, oxError = pcall(function()
            return exports['ox_inventory']:getItems()
        end)
        
        if not oxSuccess then
            print('^1[NG-ItemCreator]^7 エラー: ox_inventoryのexportが利用できません')
            print('^1[NG-ItemCreator]^7 ox_inventory/server/itemcreator.luaが正しく配置されているか確認してください')
        else
            print('^2[NG-ItemCreator]^7 OX-Inventory export接続成功')
        end
    end
end)