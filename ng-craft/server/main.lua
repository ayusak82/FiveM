local QBCore = exports['qb-core']:GetCoreObject()

-- データベーステーブル
local playerCraftingData = {}
local activeCrafts = {}
local craftIdCounter = 0

-- デバッグ用関数
local function Debug(msg)
    if Config.Debug then
        print("[ng-craft Server] " .. msg)
    end
end

-- データベース初期化
CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS ng_crafting_data (
            citizenid VARCHAR(50) PRIMARY KEY,
            level INT DEFAULT 1,
            xp INT DEFAULT 0,
            total_xp INT DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ]])
    
    Debug("Database initialized")
end)

-- プレイヤーデータの取得
local function GetPlayerCraftingData(citizenid)
    if not playerCraftingData[citizenid] then
        local result = MySQL.query.await('SELECT * FROM ng_crafting_data WHERE citizenid = ?', {citizenid})
        
        if result and result[1] then
            playerCraftingData[citizenid] = {
                level = result[1].level,
                xp = result[1].xp,
                total_xp = result[1].total_xp
            }
        else
            -- 新規プレイヤーの場合
            playerCraftingData[citizenid] = {
                level = 1,
                xp = 0,
                total_xp = 0
            }
            MySQL.insert('INSERT INTO ng_crafting_data (citizenid, level, xp, total_xp) VALUES (?, ?, ?, ?)', {
                citizenid, 1, 0, 0
            })
        end
    end
    
    return playerCraftingData[citizenid]
end

-- プレイヤーデータの保存
local function SavePlayerCraftingData(citizenid, data)
    playerCraftingData[citizenid] = data
    MySQL.update('UPDATE ng_crafting_data SET level = ?, xp = ?, total_xp = ? WHERE citizenid = ?', {
        data.level, data.xp, data.total_xp, citizenid
    })
end

-- レベル計算
local function CalculateLevel(totalXP)
    local level = 1
    local requiredXP = 0
    
    while requiredXP <= totalXP do
        level = level + 1
        requiredXP = requiredXP + (level * Config.Crafting.XPPerLevel)
    end
    
    return level - 1
end

-- 次のレベルまでの必要XP計算
local function GetXPForNextLevel(level)
    return (level + 1) * Config.Crafting.XPPerLevel
end

-- 経験値の追加
local function AddXP(src, xp)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local data = GetPlayerCraftingData(citizenid)
    
    local oldLevel = data.level
    data.total_xp = data.total_xp + xp
    data.level = CalculateLevel(data.total_xp)
    
    -- 現在のレベルでの経験値を計算
    local currentLevelXP = 0
    for i = 1, data.level - 1 do
        currentLevelXP = currentLevelXP + (i * Config.Crafting.XPPerLevel)
    end
    data.xp = data.total_xp - currentLevelXP
    
    SavePlayerCraftingData(citizenid, data)
    
    -- レベルアップ通知
    if data.level > oldLevel then
        TriggerClientEvent('ng-craft:client:LevelUp', src, data.level)
    end
    
    -- XP獲得通知
    TriggerClientEvent('ng-craft:client:XPGained', src, xp, data.total_xp, data.level)
    
    Debug(string.format("Player %s gained %d XP (Level: %d)", citizenid, xp, data.level))
end

-- クラフト速度の計算（レベルボーナス適用）
local function CalculateCraftTime(baseTime, level)
    local speedBonus = math.min(level * Config.LevelBenefits.SpeedBonus, Config.LevelBenefits.MaxSpeedBonus)
    local multiplier = (100 - speedBonus) / 100
    return baseTime * multiplier
end

-- アイテムの確認と消費
local function ConsumeItems(src, ingredients, quantity)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    -- アイテム確認
    for _, ingredient in ipairs(ingredients) do
        local requiredAmount = ingredient.amount * quantity
        local item = Player.Functions.GetItemByName(ingredient.item)
        
        if not item or item.amount < requiredAmount then
            return false
        end
    end
    
    -- アイテム消費
    for _, ingredient in ipairs(ingredients) do
        local requiredAmount = ingredient.amount * quantity
        Player.Functions.RemoveItem(ingredient.item, requiredAmount)
    end
    
    return true
end

-- アイテムの付与
local function GiveItems(src, item, amount)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    Player.Functions.AddItem(item, amount)
    return true
end

-- クラフトID生成
local function GenerateCraftId()
    craftIdCounter = craftIdCounter + 1
    return tostring(craftIdCounter)
end

-- アクティブクラフトの追加
local function AddActiveCraft(src, craftId, recipe, quantity, startTime, endTime)
    if not activeCrafts[src] then
        activeCrafts[src] = {}
    end
    
    activeCrafts[src][craftId] = {
        id = craftId,
        recipe = recipe,
        quantity = quantity,
        startTime = startTime,
        endTime = endTime,
        progress = 0
    }
end

-- アクティブクラフトの削除
local function RemoveActiveCraft(src, craftId)
    if activeCrafts[src] and activeCrafts[src][craftId] then
        activeCrafts[src][craftId] = nil
    end
end

-- クラフト進行状況の更新
CreateThread(function()
    while true do
        Wait(1000) -- 1秒ごとに更新
        
        local currentTime = GetGameTimer()
        
        for src, crafts in pairs(activeCrafts) do
            for craftId, craft in pairs(crafts) do
                local elapsed = currentTime - craft.startTime
                local total = craft.endTime - craft.startTime
                local progress = math.min(elapsed / total, 1.0)
                
                craft.progress = progress
                
                -- プログレス更新をクライアントに送信
                TriggerClientEvent('ng-craft:client:UpdateCraftProgress', src, craftId, progress)
                
                -- クラフト完了チェック
                if progress >= 1.0 then
                    CompleteCraft(src, craftId, craft)
                end
            end
        end
    end
end)

-- クラフト完了処理
function CompleteCraft(src, craftId, craft)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- アイテム付与
    local success = GiveItems(src, craft.recipe.result.item, craft.recipe.result.amount * craft.quantity)
    
    if success then
        -- 経験値付与
        AddXP(src, craft.recipe.xpReward * craft.quantity)
        
        -- 完了通知
        TriggerClientEvent('ng-craft:client:CraftCompleted', src, craft.recipe, true)
        
        Debug(string.format("Craft completed: %s x%d for player %s", craft.recipe.name, craft.quantity, Player.PlayerData.citizenid))
    else
        -- 失敗通知
        TriggerClientEvent('ng-craft:client:CraftCompleted', src, craft.recipe, false)
    end
    
    -- アクティブクラフトから削除
    RemoveActiveCraft(src, craftId)
    
    -- アクティブクラフト更新をクライアントに送信
    TriggerClientEvent('ng-craft:client:UpdateActiveCrafts', src, activeCrafts[src] or {})
end

-- コールバック：プレイヤーレベル取得
QBCore.Functions.CreateCallback('ng-craft:server:GetPlayerLevel', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then cb(1) return end
    
    local data = GetPlayerCraftingData(Player.PlayerData.citizenid)
    cb(data.level)
end)

-- コールバック：プレイヤーXP取得
QBCore.Functions.CreateCallback('ng-craft:server:GetPlayerXP', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then cb(0, 0, 1000) return end
    
    local data = GetPlayerCraftingData(Player.PlayerData.citizenid)
    local nextLevelXP = GetXPForNextLevel(data.level)
    cb(data.xp, data.total_xp, nextLevelXP)
end)

-- コールバック：プレイヤーアイテム取得
QBCore.Functions.CreateCallback('ng-craft:server:GetPlayerItems', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then cb({}) return end
    
    local items = {}
    for _, item in pairs(Player.PlayerData.items) do
        if item and item.amount and item.amount > 0 then
            table.insert(items, {
                name = item.name,
                amount = item.amount,
                label = item.label,
                info = item.info
            })
        end
    end
    
    cb(items)
end)

-- コールバック：アクティブクラフト取得
QBCore.Functions.CreateCallback('ng-craft:server:GetActiveCrafts', function(source, cb)
    cb(activeCrafts[source] or {})
end)

-- NEW: レシピ詳細取得のコールバック
QBCore.Functions.CreateCallback('ng-craft:server:GetRecipeDetails', function(source, cb, recipeName)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then 
        cb({error = 'Player not found'})
        return 
    end
    
    -- レシピを検索
    local recipe = nil
    for category, recipes in pairs(Config.Recipes) do
        for _, r in ipairs(recipes) do
            if r.name == recipeName then
                recipe = r
                break
            end
        end
        if recipe then break end
    end
    
    if not recipe then
        cb({error = 'Recipe not found'})
        return
    end
    
    -- プレイヤーの所持アイテムを取得
    local items = {}
    for _, item in pairs(Player.PlayerData.items) do
        if item and item.amount and item.amount > 0 then
            items[item.name] = item.amount
        end
    end
    
    -- 材料の確認
    local canCraft = true
    local ingredientStatus = {}
    
    for _, ingredient in ipairs(recipe.ingredients) do
        local playerAmount = items[ingredient.item] or 0
        
        ingredientStatus[ingredient.item] = {
            required = ingredient.amount,
            available = playerAmount,
            sufficient = playerAmount >= ingredient.amount
        }
        
        if playerAmount < ingredient.amount then
            canCraft = false
        end
    end
    
    cb({
        recipe = recipe,
        canCraft = canCraft,
        ingredients = ingredientStatus
    })
end)

-- イベント：クラフト開始
RegisterNetEvent('ng-craft:server:StartCraft', function(recipe, quantity)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- 同時クラフト数チェック
    local currentCrafts = activeCrafts[src] and #activeCrafts[src] or 0
    if currentCrafts >= Config.Crafting.MaxConcurrentCrafts then
        TriggerClientEvent('ng-craft:client:Notify', src, {
            title = 'エラー',
            message = Config.Locales['max_concurrent_reached'],
            type = 'error'
        })
        return
    end
    
    -- レベルチェック
    local data = GetPlayerCraftingData(Player.PlayerData.citizenid)
    if data.level < recipe.requiredLevel then
        TriggerClientEvent('ng-craft:client:Notify', src, {
            title = 'エラー',
            message = string.format(Config.Locales['insufficient_level'], recipe.requiredLevel),
            type = 'error'
        })
        return
    end
    
    -- アイテム消費チェック
    if not ConsumeItems(src, recipe.ingredients, quantity) then
        TriggerClientEvent('ng-craft:client:Notify', src, {
            title = 'エラー',
            message = Config.Locales['insufficient_items'],
            type = 'error'
        })
        return
    end
    
    -- クラフト開始
    local craftId = GenerateCraftId()
    local startTime = GetGameTimer()
    local craftTime = CalculateCraftTime(recipe.craftTime * 1000, data.level) -- ミリ秒に変換
    local endTime = startTime + craftTime
    
    AddActiveCraft(src, craftId, recipe, quantity, startTime, endTime)
    
    -- 開始通知
    TriggerClientEvent('ng-craft:client:Notify', src, {
        title = 'クラフト開始',
        message = string.format('%s x%d のクラフトを開始しました', recipe.label, quantity),
        type = 'success'
    })
    
    -- アクティブクラフト更新
    TriggerClientEvent('ng-craft:client:UpdateActiveCrafts', src, activeCrafts[src])
    
    Debug(string.format("Craft started: %s x%d for player %s", recipe.name, quantity, Player.PlayerData.citizenid))
end)

-- イベント：クラフトキャンセル
RegisterNetEvent('ng-craft:server:CancelCraft', function(craftId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    if activeCrafts[src] and activeCrafts[src][craftId] then
        local craft = activeCrafts[src][craftId]
        
        -- アイテムを返却（50%の確率で）
        if math.random() < 0.5 then
            for _, ingredient in ipairs(craft.recipe.ingredients) do
                local returnAmount = math.floor(ingredient.amount * craft.quantity * 0.5)
                if returnAmount > 0 then
                    Player.Functions.AddItem(ingredient.item, returnAmount)
                end
            end
        end
        
        RemoveActiveCraft(src, craftId)
        
        TriggerClientEvent('ng-craft:client:Notify', src, {
            title = 'クラフトキャンセル',
            message = 'クラフトをキャンセルしました',
            type = 'inform'
        })
        
        -- アクティブクラフト更新
        TriggerClientEvent('ng-craft:client:UpdateActiveCrafts', src, activeCrafts[src] or {})
        
        Debug(string.format("Craft cancelled: %s for player %s", craftId, Player.PlayerData.citizenid))
    end
end)

-- プレイヤー切断時のクリーンアップ
RegisterNetEvent('QBCore:Server:OnPlayerUnload', function(src)
    if activeCrafts[src] then
        activeCrafts[src] = nil
    end
    
    local Player = QBCore.Functions.GetPlayer(src)
    if Player and playerCraftingData[Player.PlayerData.citizenid] then
        -- データを保存
        SavePlayerCraftingData(Player.PlayerData.citizenid, playerCraftingData[Player.PlayerData.citizenid])
    end
end)

-- リソース停止時の処理
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        -- 全てのプレイヤーデータを保存
        for citizenid, data in pairs(playerCraftingData) do
            SavePlayerCraftingData(citizenid, data)
        end
        Debug("All player data saved on resource stop")
    end
end)