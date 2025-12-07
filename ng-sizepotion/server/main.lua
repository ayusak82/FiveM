local QBCore = exports['qb-core']:GetCoreObject()

-- デバッグ関数
local function DebugPrint(...)
    if not Config.Debug then return end
    local args = {...}
    local message = ''
    for i = 1, #args do
        message = message .. tostring(args[i]) .. ' '
    end
    print('^3[ng-sizepotion DEBUG]^7 ' .. message)
end

local function ErrorPrint(...)
    local args = {...}
    local message = ''
    for i = 1, #args do
        message = message .. tostring(args[i]) .. ' '
    end
    print('^1[ng-sizepotion ERROR]^7 ' .. message)
end

local function SuccessPrint(...)
    if not Config.Debug then return end
    local args = {...}
    local message = ''
    for i = 1, #args do
        message = message .. tostring(args[i]) .. ' '
    end
    print('^2[ng-sizepotion SUCCESS]^7 ' .. message)
end

-- プレイヤーのスケール情報を保存
local playerScales = {}

-- アイテム使用登録
local function RegisterUsableItems()
    QBCore.Functions.CreateUseableItem(Config.Potions.shrink.item, function(source, item)
        DebugPrint('Player', source, 'using shrink potion')
        TriggerClientEvent('ng-sizepotion:client:usePotion', source, 'shrink')
    end)
    
    QBCore.Functions.CreateUseableItem(Config.Potions.grow.item, function(source, item)
        DebugPrint('Player', source, 'using grow potion')
        TriggerClientEvent('ng-sizepotion:client:usePotion', source, 'grow')
    end)
    
    if Config.Antidote.enabled then
        QBCore.Functions.CreateUseableItem(Config.Antidote.item, function(source, item)
            DebugPrint('Player', source, 'using antidote')
            TriggerClientEvent('ng-sizepotion:client:useAntidote', source)
        end)
    end
    
    SuccessPrint('Useable items registered')
end

-- 薬を使用（アイテム消費処理）
RegisterNetEvent('ng-sizepotion:server:usePotion', function(potionType)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    
    if not Player then
        ErrorPrint('Player not found:', source)
        return
    end
    
    local potionConfig = Config.Potions[potionType]
    if not potionConfig then
        ErrorPrint('Invalid potion type:', potionType, 'from player:', source)
        return
    end
    
    local itemName = potionConfig.item
    local item = Player.Functions.GetItemByName(itemName)
    
    if not item then
        ErrorPrint('Player', source, 'does not have item:', itemName)
        TriggerClientEvent('okokNotify:Alert', source, 'エラー', 'アイテムを所持していません', 5000, 'error', true)
        return
    end
    
    local success = Player.Functions.RemoveItem(itemName, 1)
    
    if success then
        TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[itemName], 'remove', 1)
        SuccessPrint('Player', source, 'used potion:', potionType)
        TriggerClientEvent('ng-sizepotion:client:applyEffect', source, potionType)
    else
        ErrorPrint('Failed to remove item:', itemName, 'from player:', source)
        TriggerClientEvent('okokNotify:Alert', source, 'エラー', 'アイテムの使用に失敗しました', 5000, 'error', true)
    end
end)

-- 解毒剤を使用
RegisterNetEvent('ng-sizepotion:server:useAntidote', function()
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    
    if not Player then
        ErrorPrint('Player not found:', source)
        return
    end
    
    if not Config.Antidote.enabled then
        ErrorPrint('Antidote is disabled, but player', source, 'tried to use it')
        return
    end
    
    local itemName = Config.Antidote.item
    local item = Player.Functions.GetItemByName(itemName)
    
    if not item then
        ErrorPrint('Player', source, 'does not have item:', itemName)
        TriggerClientEvent('okokNotify:Alert', source, 'エラー', 'アイテムを所持していません', 5000, 'error', true)
        return
    end
    
    local success = Player.Functions.RemoveItem(itemName, 1)
    
    if success then
        TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[itemName], 'remove', 1)
        SuccessPrint('Player', source, 'used antidote')
        TriggerClientEvent('ng-sizepotion:client:applyAntidote', source)
    else
        ErrorPrint('Failed to remove item:', itemName, 'from player:', source)
        TriggerClientEvent('okokNotify:Alert', source, 'エラー', 'アイテムの使用に失敗しました', 5000, 'error', true)
    end
end)

-- プレイヤーのスケールを同期
RegisterNetEvent('ng-sizepotion:server:syncScale', function(scale)
    local source = source
    
    if scale == 1.0 then
        playerScales[source] = nil
    else
        playerScales[source] = scale
    end
    
    -- 全クライアントに通知
    TriggerClientEvent('ng-sizepotion:client:updatePlayerScale', -1, source, scale)
    
    DebugPrint('Player', source, 'scale synced:', scale)
end)

-- スケール同期リクエスト（新規接続プレイヤー用）
RegisterNetEvent('ng-sizepotion:server:requestScaleSync', function()
    local source = source
    TriggerClientEvent('ng-sizepotion:client:syncAllScales', source, playerScales)
    DebugPrint('Scale sync sent to player:', source)
end)

-- プレイヤー切断時
AddEventHandler('playerDropped', function(reason)
    local source = source
    playerScales[source] = nil
    TriggerClientEvent('ng-sizepotion:client:playerDropped', -1, source)
    DebugPrint('Player', source, 'dropped, scale data removed')
end)

-- リソース開始時にアイテム登録
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    RegisterUsableItems()
end)

-- 初回登録
CreateThread(function()
    Wait(1000)
    RegisterUsableItems()
end)

-- アイテム登録確認用コマンド（デバッグ用）
if Config.Debug then
    RegisterCommand('checkpotionitems', function(source, args, rawCommand)
        if source ~= 0 then return end
        
        print('^3[ng-sizepotion]^7 Required items to add in qb-core/shared/items.lua:')
        print('  - Shrink Potion: ' .. Config.Potions.shrink.item)
        print('  - Grow Potion: ' .. Config.Potions.grow.item)
        if Config.Antidote.enabled then
            print('  - Antidote: ' .. Config.Antidote.item)
        end
    end, false)
    
    RegisterCommand('checkscales', function(source, args, rawCommand)
        if source ~= 0 then return end
        
        print('^3[ng-sizepotion]^7 Current player scales:')
        for playerId, scale in pairs(playerScales) do
            print('  Player ' .. playerId .. ': ' .. scale)
        end
    end, false)
end

DebugPrint('Server script loaded')
