local QBCore = exports['qb-core']:GetCoreObject()
local jobItemsCache = {}
local itemTypeMapping = {}

-- アイテムとタイプのマッピング初期化
local function InitializeItemTypeMapping()
    -- デフォルト値の設定
    itemTypeMapping = table.clone(Config.DefaultItemTypeMapping)
    jobItemsCache = {} -- キャッシュをクリア
    
    --print('ng-crafting: ox_inventoryのitems.luaファイルを読み込み中...')
    
    -- ox_inventoryのitems.luaファイルを直接読み込む
    local rawItemsFile = LoadResourceFile('ox_inventory', 'data/items.lua')
    
    if not rawItemsFile then
        --print('エラー: ox_inventory/data/items.luaファイルが見つかりません')
        return
    end
    
    -- ファイルの内容を行ごとに処理
    local itemDefinitions = {}
    local currentItemName = nil
    local inItemDef = false
    local bracketCount = 0
    local currentItemDef = {}
    
    -- 行ごとに処理
    for line in string.gmatch(rawItemsFile, "[^\r\n]+") do
        -- アイテム定義の開始を検出 (例: ["itemname"] = {)
        local itemName = string.match(line, "%[\"([^\"]+)\"%]%s*=%s*{") or string.match(line, "%['([^']+)'%]%s*=%s*{")
        if itemName then
            currentItemName = itemName
            inItemDef = true
            bracketCount = 1
            currentItemDef = { line = line }
        elseif inItemDef then
            -- 行を現在のアイテム定義に追加
            currentItemDef[#currentItemDef + 1] = line
            
            -- 括弧のカウント
            bracketCount = bracketCount + select(2, string.gsub(line, "{", "")) - select(2, string.gsub(line, "}", ""))
            
            -- アイテム定義の終了を検出
            if bracketCount <= 0 then
                inItemDef = false
                itemDefinitions[currentItemName] = table.concat(currentItemDef, "\n")
            end
        end
    end
    
    --print('items.luaから' .. #itemDefinitions .. '個のアイテム定義を抽出しました')
    
    -- アイテム定義からジョブアイテムを抽出
    for itemName, itemDefStr in pairs(itemDefinitions) do
        -- ジョブプレフィックスの検出
        local jobName = nil
        
        -- パターン1: ジョブ名_から始まるアイテム
        for job, _ in pairs(QBCore.Shared.Jobs) do
            if string.find(itemName, "^" .. job .. "_") then
                jobName = job
                break
            end
        end
        
        -- パターン2: job_から始まるアイテム
        if not jobName and string.find(itemName, "^job_") then
            jobName = string.match(itemName, "^job_([^_]+)")
        end
        
        -- ジョブアイテムが見つかった場合の処理
        if jobName then
            -- ラベルを抽出
            local label = string.match(itemDefStr, "label%s*=%s*[\"']([^\"']+)[\"']") or itemName
            
            -- アイテムタイプの決定（デフォルトはnormal）
            local itemType = 'normal'
            
            -- アイテムの種類を推測
            if string.find(itemDefStr, "hunger") then
                itemType = 'food'
            elseif string.find(itemDefStr, "thirst") then
                itemType = 'drink'
            elseif string.find(itemDefStr, "stress") then
                itemType = 'stress'
            end
            
            -- キャッシュに保存
            if not jobItemsCache[jobName] then
                jobItemsCache[jobName] = {}
            end
            
            -- アイテム情報を保存
            table.insert(jobItemsCache[jobName], {
                name = itemName,
                label = label,
                type = itemType
            })
            
            -- アイテムタイプマッピングを保存
            itemTypeMapping[itemName] = itemType
            
            --print('ジョブアイテム検出: ' .. itemName .. ' (ジョブ: ' .. jobName .. ', タイプ: ' .. itemType .. ')')
        end
    end
    
    --print('ジョブアイテムキャッシュ初期化: ' .. json.encode(jobItemsCache))
    
    -- サーバー側で全プレイヤーにクラフトアイテムの更新を通知
    local players = QBCore.Functions.GetQBPlayers()
    for _, player in pairs(players) do
        if player and player.PlayerData and player.PlayerData.job then
            local jobName = player.PlayerData.job.name
            local playerId = player.PlayerData.source
            
            if jobName and playerId and jobItemsCache[jobName] then
                TriggerClientEvent('ng-crafting:client:ReceiveCraftableItems', playerId, jobItemsCache[jobName])
                --print('プレイヤー ' .. playerId .. ' のアイテムリストを更新: ' .. jobName)
            end
        end
    end
end

-- クライアントからのクラフト可能アイテムリクエスト
RegisterNetEvent('ng-crafting:server:RequestCraftableItems', function(jobName)
    local src = source
    
    -- キャッシュが空なら再初期化
    if next(jobItemsCache) == nil then
        InitializeItemTypeMapping()
    end
    
    -- 該当ジョブのアイテムリストを取得
    local craftableItems = jobItemsCache[jobName] or {}
    
    -- クライアントにアイテムリスト送信
    TriggerClientEvent('ng-crafting:client:ReceiveCraftableItems', src, craftableItems)
    
    --print('クラフト可能アイテムリスト送信: プレイヤー ' .. src .. ', ジョブ ' .. jobName .. ', アイテム数 ' .. #craftableItems)
end)

-- クライアントからのクラフト要求
RegisterNetEvent('ng-crafting:server:CraftItem', function(itemName, itemType, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- 数量の検証（デフォルトは1）
    amount = tonumber(amount) or 1
    if amount <= 0 then amount = 1 end
    
    -- アイテムタイプが指定されていない場合はデフォルトマッピングから取得
    itemType = itemType or itemTypeMapping[itemName] or 'normal'
    
    -- タイプが存在するか確認
    if not Config.ItemTypes[itemType] then
        --print('警告: 未定義のアイテムタイプ: ' .. itemType .. ' - デフォルトのnormalを使用します')
        itemType = 'normal' -- デフォルトにフォールバック
    end
    
    -- タイプに応じた必要素材と出力倍率を取得
    local requiredItems = Config.ItemTypes[itemType].requiredItems
    local outputMultiplier = Config.ItemTypes[itemType].outputMultiplier or 1
    
    --print('デバッグ: クラフト要求 - プレイヤー: ' .. GetPlayerName(src) .. ', アイテム: ' .. itemName .. ', タイプ: ' .. itemType .. ', 数量: ' .. amount)
    --print('デバッグ: 必要素材: ' .. json.encode(requiredItems))
    
    -- 素材チェック
    local hasAllItems = true
    local missingItems = {}
    
    for _, item in ipairs(requiredItems) do
        -- 数量に応じた必要素材数の計算
        local neededAmount = item.amount * amount
        
        -- ox_inventoryでアイテム所持数を確認
        local itemCount = 0
        
        -- 方法1: Search関数
        local success = pcall(function()
            itemCount = exports.ox_inventory:Search(src, 'count', item.name)
            --print('デバッグ: Search関数 - アイテム: ' .. item.name .. ', 数量: ' .. itemCount .. '/' .. neededAmount)
        end)
        
        -- 方法2: QBCoreのInventoryを使用
        if not success or itemCount == 0 then
            local qbItem = Player.Functions.GetItemByName(item.name)
            itemCount = qbItem and qbItem.amount or 0
            --print('デバッグ: QBCore関数 - アイテム: ' .. item.name .. ', 数量: ' .. itemCount .. '/' .. neededAmount)
        end
        
        if itemCount < neededAmount then
            hasAllItems = false
            table.insert(missingItems, item.name .. ' (' .. itemCount .. '/' .. neededAmount .. ')')
        end
    end
    
    if hasAllItems then
        -- 素材を消費
        for _, item in ipairs(requiredItems) do
            -- 数量に応じた必要素材数の計算
            local neededAmount = item.amount * amount
            
            local removeSuccess = false
            
            -- 方法1: ox_inventoryのRemoveItem
            pcall(function()
                removeSuccess = exports.ox_inventory:RemoveItem(src, item.name, neededAmount)
                --print('デバッグ: RemoveItem - アイテム: ' .. item.name .. ', 数量: ' .. neededAmount .. ', 結果: ' .. tostring(removeSuccess))
            end)
            
            -- 方法2: QBCoreのRemoveItem
            if not removeSuccess then
                removeSuccess = Player.Functions.RemoveItem(item.name, neededAmount)
                --print('デバッグ: QBCore RemoveItem - アイテム: ' .. item.name .. ', 数量: ' .. neededAmount .. ', 結果: ' .. tostring(removeSuccess))
            end
        end
        
        -- アイテム作成（倍率と数量を適用）
        local outputAmount = outputMultiplier * amount
        local addSuccess = false
        
        -- 方法1: QBCoreのAddItem
        addSuccess = Player.Functions.AddItem(itemName, outputAmount)
        --print('デバッグ: QBCore AddItem - アイテム: ' .. itemName .. ', 数量: ' .. outputAmount .. ', 結果: ' .. tostring(addSuccess))
            
        -- 方法2: ox_inventoryのAddItem
        if not addSuccess then
            pcall(function()
                addSuccess = exports.ox_inventory:AddItem(src, itemName, outputAmount)
                --print('デバッグ: ox_inventory AddItem - アイテム: ' .. itemName .. ', 数量: ' .. outputAmount .. ', 結果: ' .. tostring(addSuccess))
            end)
        end
        
        -- 成功通知
        TriggerClientEvent('ng-crafting:client:CraftComplete', src, true, itemName, outputAmount)
        
        -- ログ出力
        --print('クラフト成功: ' .. GetPlayerName(src) .. ' が ' .. itemName .. ' x' .. outputAmount .. ' を作成しました')
    else
        -- 失敗通知
        TriggerClientEvent('ng-crafting:client:CraftComplete', src, false, itemName, 0)
        
        -- ログ出力
        --print('クラフト失敗: ' .. GetPlayerName(src) .. ' - 必要素材不足: ' .. table.concat(missingItems, ', '))
    end
end)

-- サーバー起動時にアイテム情報を初期化
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    --print('ng-crafting: 初期化中...')
    Wait(2000) -- 他のリソースが初期化するのを待つ
    InitializeItemTypeMapping()
end)

-- ox_inventoryの再起動時にも更新
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= 'ox_inventory' then return end
    --print('ox_inventory再起動を検出: アイテムリストを更新します')
    Wait(3000) -- ox_inventoryが初期化するのを待つ
    InitializeItemTypeMapping()
end)

-- アイテムキャッシュの更新
AddEventHandler('ox_inventory:itemList', function()
    --print('ox_inventory:itemList イベント検出: アイテムリストを更新します')
    Wait(1000) -- ox_inventoryのロードを少し待つ
    InitializeItemTypeMapping()
end)

-- サーバー再起動時にキャッシュをクリア
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    --print('ng-crafting: キャッシュのクリア中...')
    jobItemsCache = {}
    itemTypeMapping = {}
end)

-- コマンド: データベースを再スキャン
RegisterCommand('refreshcrafting', function(source, args, rawCommand)
    local src = source
    
    -- サーバーコンソールまたは権限のあるプレイヤーのみ実行可能
    if src == 0 or QBCore.Functions.HasPermission(src, 'admin') then
        -- アイテム情報の再初期化
        jobItemsCache = {}
        itemTypeMapping = {}
        InitializeItemTypeMapping()
        
        -- 通知
        if src > 0 then
            TriggerClientEvent('QBCore:Notify', src, 'クラフトシステムのアイテム情報を更新しました', 'success')
        else
            --print('クラフトシステムのアイテム情報を更新しました')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, '権限がありません', 'error')
    end
end, true)

-- 強制的にアイテムリストを更新
RegisterCommand('craft_reload_items', function(source, args, rawCommand)
    local src = source
    
    -- アイテムリストを再ロード
    InitializeItemTypeMapping()
    
    -- 通知
    if src > 0 then
        TriggerClientEvent('QBCore:Notify', src, 'クラフトアイテムリストを再ロードしました', 'success')
    end
    
    --print('クラフトアイテムリストを再ロードしました')
end, true)

-- デバッグコマンド：現在のジョブでアイテムリストを強制リクエスト
RegisterCommand('craft_request', function(source, args, rawCommand)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    
    if player and player.PlayerData and player.PlayerData.job then
        local job = player.PlayerData.job.name
        local items = jobItemsCache[job] or {}
        
        -- 現在の状態を出力
        --print('プレイヤー ' .. src .. ' のジョブ: ' .. job)
        --print('使用可能なアイテム: ' .. json.encode(items))
        
        -- クライアントにアイテムリストを送信
        TriggerClientEvent('ng-crafting:client:ReceiveCraftableItems', src, items)
        
        -- 通知
        TriggerClientEvent('QBCore:Notify', src, 'クラフトアイテムリストを再要求しました: ' .. #items .. '個のアイテム', 'success')
    end
end, false)