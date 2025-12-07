--[[
    ng-gacha - Client Side
    Author: NCCGr
    Contact: Discord: ayusak
]]

local QBCore = exports['qb-core']:GetCoreObject()

-- Local Variables
local isUIOpen = false
local currentGacha = nil
local playerData = nil

-- Debug Functions
local function DebugPrint(...)
    if not Config.Debug then return end
    local args = {...}
    local message = ''
    for i = 1, #args do
        message = message .. tostring(args[i]) .. ' '
    end
    print('^3[ng-gacha:DEBUG]^7 ' .. message)
end

local function ErrorPrint(...)
    local args = {...}
    local message = ''
    for i = 1, #args do
        message = message .. tostring(args[i]) .. ' '
    end
    print('^1[ng-gacha:ERROR]^7 ' .. message)
end

-- Notification Function
local function Notify(title, message, type, duration)
    duration = duration or 5000
    if Config.Notifications.useOkokNotify then
        exports['okokNotify']:Alert(title, message, duration, type, true)
    else
        QBCore.Functions.Notify(message, type, duration)
    end
end

-- Get Player Balance
local function GetPlayerBalance()
    local player = QBCore.Functions.GetPlayerData()
    if not player then return { money = 0, bank = 0 } end
    
    return {
        money = player.money and player.money.cash or 0,
        bank = player.money and player.money.bank or 0
    }
end

-- Get Gacha Coin Count
local function GetGachaCoinCount()
    local player = QBCore.Functions.GetPlayerData()
    if not player or not player.items then return 0 end
    
    for _, item in pairs(player.items) do
        if item and item.name == Config.GachaCoinItem then
            return item.amount or 0
        end
    end
    return 0
end

-- Open Gacha UI
local function OpenGachaUI(gachaData)
    if isUIOpen then return end
    
    DebugPrint('Opening Gacha UI for gacha:', gachaData.id)
    
    currentGacha = gachaData
    isUIOpen = true
    
    local balance = GetPlayerBalance()
    local coinCount = GetGachaCoinCount()
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openGacha',
        gacha = gachaData,
        balance = {
            money = balance.money,
            bank = balance.bank,
            coins = coinCount
        },
        config = {
            multiPull = Config.MultiPull,
            rarities = Config.Rarities
        }
    })
end

-- Open Create Gacha UI
local function OpenCreateGachaUI()
    if isUIOpen then return end
    
    DebugPrint('Opening Create Gacha UI')
    
    isUIOpen = true
    
    -- Get all available items from QBCore
    local itemList = {}
    local sharedItems = QBCore.Shared.Items
    
    for name, data in pairs(sharedItems) do
        table.insert(itemList, {
            name = name,
            label = data.label or name
        })
    end
    
    table.sort(itemList, function(a, b)
        return a.label < b.label
    end)
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openCreate',
        items = itemList,
        config = {
            colorThemes = Config.ColorThemes,
            rarities = Config.Rarities,
            defaults = Config.DefaultGachaSettings,
            limits = Config.Limits,
            paymentTypes = Config.PaymentTypes
        }
    })
end

-- Close UI
local function CloseUI()
    if not isUIOpen then return end
    
    DebugPrint('Closing UI')
    
    isUIOpen = false
    currentGacha = nil
    
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'close'
    })
end

-- NUI Callbacks
RegisterNUICallback('close', function(_, cb)
    CloseUI()
    cb('ok')
end)

RegisterNUICallback('pullGacha', function(data, cb)
    if not currentGacha then
        cb({ success = false, error = 'No gacha selected' })
        return
    end
    
    local count = data.count or 1
    DebugPrint('Pull gacha request:', currentGacha.id, 'count:', count)
    
    -- Request pull from server
    local result = lib.callback.await('ng-gacha:server:pullGacha', false, currentGacha.id, count)
    
    if result.success then
        DebugPrint('Pull successful, items:', #result.items)
        
        -- Update balance in UI
        local balance = GetPlayerBalance()
        local coinCount = GetGachaCoinCount()
        
        SendNUIMessage({
            action = 'updateBalance',
            balance = {
                money = balance.money,
                bank = balance.bank,
                coins = coinCount
            }
        })
        
        -- Update pity count
        if result.pityCount then
            SendNUIMessage({
                action = 'updatePity',
                pityCount = result.pityCount,
                pityMax = currentGacha.pity_count
            })
        end
        
        cb({ success = true, items = result.items })
    else
        Notify('エラー', result.error or 'ガチャを引けませんでした', 'error')
        cb({ success = false, error = result.error })
    end
end)

RegisterNUICallback('createGacha', function(data, cb)
    DebugPrint('Create gacha request:', data.name)
    
    -- Validate data
    if not data.name or data.name == '' then
        cb({ success = false, error = 'ガチャ名を入力してください' })
        return
    end
    
    if not data.prizes or #data.prizes == 0 then
        cb({ success = false, error = '景品を追加してください' })
        return
    end
    
    -- Check total probability
    local totalProb = 0
    for _, prize in ipairs(data.prizes) do
        totalProb = totalProb + (prize.probability or 0)
    end
    
    if math.abs(totalProb - 100) > 0.01 then
        cb({ success = false, error = '確率の合計が100%になるように調整してください' })
        return
    end
    
    -- Request creation from server
    local result = lib.callback.await('ng-gacha:server:createGacha', false, data)
    
    if result.success then
        DebugPrint('Gacha created successfully:', result.gachaId)
        Notify('成功', 'ガチャを作成しました！', 'success')
        CloseUI()
        cb({ success = true, gachaId = result.gachaId })
    else
        Notify('エラー', result.error or 'ガチャを作成できませんでした', 'error')
        cb({ success = false, error = result.error })
    end
end)

RegisterNUICallback('getHistory', function(data, cb)
    local gachaId = data.gachaId or (currentGacha and currentGacha.id)
    
    if not gachaId then
        cb({ success = false, history = {} })
        return
    end
    
    local result = lib.callback.await('ng-gacha:server:getHistory', false, gachaId)
    cb(result)
end)

-- Events
RegisterNetEvent('ng-gacha:client:openGacha', function(gachaData)
    OpenGachaUI(gachaData)
end)

RegisterNetEvent('ng-gacha:client:openCreate', function()
    OpenCreateGachaUI()
end)

RegisterNetEvent('ng-gacha:client:notify', function(title, message, type)
    Notify(title, message, type)
end)

-- QBCore Item Use Handler - Gacha Ticket
RegisterNetEvent('ng-gacha:client:useGachaTicket', function()
    DebugPrint('Gacha ticket used')
    
    -- Check if player can create more gacha
    local canCreate = lib.callback.await('ng-gacha:server:canCreateGacha', false)
    
    if not canCreate.success then
        Notify('エラー', canCreate.error or 'ガチャを作成できません', 'error')
        return
    end
    
    OpenCreateGachaUI()
end)

-- QBCore Item Use Handler - Gacha Machine
RegisterNetEvent('ng-gacha:client:useGachaMachine', function(itemData)
    DebugPrint('Gacha machine used')
    
    local metadata = itemData.info
    if not metadata or not metadata.gacha_id then
        Notify('エラー', '無効なガチャアイテムです', 'error')
        return
    end
    
    -- Get gacha data from server
    local gachaData = lib.callback.await('ng-gacha:server:getGachaData', false, metadata.gacha_id)
    
    if not gachaData or not gachaData.success then
        Notify('エラー', gachaData and gachaData.error or 'ガチャデータを取得できません', 'error')
        return
    end
    
    OpenGachaUI(gachaData.gacha)
end)

-- Commands (Debug)
if Config.Debug then
    RegisterCommand('testgacha', function()
        -- Test gacha data
        local testGacha = {
            id = 1,
            name = 'テストガチャ',
            description = 'テスト用のガチャです',
            price = 500,
            price_type = 'money',
            color_theme = 'cyan',
            pity_count = 100,
            current_pity = 25,
            prizes = {
                { item_name = 'water', item_label = 'ミネラルウォーター', item_count = 10, rarity = 'common', probability = 50 },
                { item_name = 'burger', item_label = 'バーガー', item_count = 5, rarity = 'uncommon', probability = 25 },
                { item_name = 'bandage', item_label = '包帯', item_count = 3, rarity = 'rare', probability = 15 },
                { item_name = 'radio', item_label = '無線機', item_count = 1, rarity = 'epic', probability = 8 },
                { item_name = 'goldbar', item_label = 'ゴールドバー', item_count = 1, rarity = 'legendary', probability = 2, is_jackpot = true }
            }
        }
        OpenGachaUI(testGacha)
    end)
    
    RegisterCommand('testcreate', function()
        OpenCreateGachaUI()
    end)
end

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        CloseUI()
    end
end)

-- Player loaded
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    playerData = QBCore.Functions.GetPlayerData()
    DebugPrint('Player loaded')
end)

-- Update player data
RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    playerData = val
end)
