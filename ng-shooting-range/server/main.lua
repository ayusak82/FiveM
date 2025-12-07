-- デバッグ関数
local function DebugPrint(...)
    if not Config.Debug then return end
    local args = {...}
    local message = ''
    for i = 1, #args do
        message = message .. tostring(args[i]) .. ' '
    end
    print('^3[DEBUG]^7 ' .. message)
end

local function ErrorPrint(...)
    local args = {...}
    local message = ''
    for i = 1, #args do
        message = message .. tostring(args[i]) .. ' '
    end
    print('^1[ERROR]^7 ' .. message)
end

local function SuccessPrint(...)
    if not Config.Debug then return end
    local args = {...}
    local message = ''
    for i = 1, #args do
        message = message .. tostring(args[i]) .. ' '
    end
    print('^2[SUCCESS]^7 ' .. message)
end

-- リソース開始時
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    print('^2[ng-shooting-range]^7 Shooting Range script started successfully')
    DebugPrint('Server-side initialized')
end)

-- リソース停止時
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    print('^3[ng-shooting-range]^7 Shooting Range script stopped')
    DebugPrint('Server-side stopped')
end)

-- 将来的な拡張用: スコア保存機能
-- RegisterNetEvent('ng-shooting-range:server:saveScore', function(scoreData)
--     local source = source
--     local Player = QBCore.Functions.GetPlayer(source)
--     
--     if not Player then
--         ErrorPrint('Player not found:', source)
--         return
--     end
--     
--     DebugPrint('Saving score for player:', source, 'Score:', scoreData.score)
--     
--     -- データベースに保存する処理をここに実装
--     -- 例: MySQL.insert.await('INSERT INTO shooting_scores ...')
-- end)
